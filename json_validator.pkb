create or replace package body json_validator is

  /******************************************************************************
   name:       json_validator
   purpose:    JSON validate of given text source.
               based on Douglas Crockford JSON parse model
               https://github.com/douglascrockford/JSON-js/blob/master/json_parse.js 

   revisions:
   Ver        Date        Author
   ---------  ----------  ------------------------------
   1.1        25/04/2017  Khisamutdinov Radik Damirovich
  ******************************************************************************/
  
  /******************************************************************************
          This program is published under the MIT License
  *******************************************************************************/

  /* @private
   * type for instantiate keys storages
   */
  type array_t is table of varchar2(1000);

  atCh integer; -- the index of the current character
  ch char;      -- the current character
  text clob;

  /* @private
   * call error when something is wrong
   */
  procedure error(m in varchar2 default '')
  is
    errmsg varchar2(32767);
    len integer := 1400;
    halfLen integer := len / 2;
    pos integer;
  begin
    pos := case when atCh > halfLen then atCh - halfLen else 1 end;
    
    errmsg := 'name: SyntaxError, ';
    errmsg := errmsg || 'message: ' || m || ', ';
    errmsg := errmsg || 'at: ' || atCh || ', ';
    errmsg := errmsg || 'text: ' || 
                           (case when pos > 1 then '...' else '' end) || 
                             substr(text, pos, len) || 
                               (case when atCh + halfLen < dbms_lob.getlength(text) then '...' else '' end);
    
    raise_application_error(-20000, errmsg);
  end;

  /* @private
   * escape sequence
   */
  function escapee(ch in char default '') return varchar2
  is
  begin
    case ch
      when '"' then return '"';
      when '\' then return '\';
      when '/' then return '/';
      when 'b' then return '\b';
      when 'f' then return '\f';
      when 'n' then return '\n';
      when 'r' then return '\r';
      when 't' then return '\t';
      else return null;
    end case;
  end;

  /* @private
   * add key to keys storage
   */
  procedure add_key(p_array in out nocopy array_t, p_key in varchar2)
  is
  begin
    p_array.extend();
    p_array(p_array.count()) := p_key;
    exception
      when collection_is_null then 
        p_array := array_t(p_key);
  end;
  
  /* @private
   * check duplicate keys in keys storage
   */
  function has_key(p_array in out nocopy array_t, p_key in varchar2) return boolean
  is
    is_equal boolean := false;
  begin
    for i in p_array.first..p_array.last loop
      if p_array(i) = p_key then
        is_equal := true;
      end if; 
    end loop;
    
    return is_equal;
    exception
      when collection_is_null then 
        return is_equal;
  end;

  /* @private
   *  get char from string by index position
   */
  function charAt(str in varchar2, pos in integer) return char
  is
  begin
    return substr(str, pos, 1);
  end;

  /* @private
   * check if given number
   */
  function isNumber(num in varchar2) return boolean
  is
  begin
    case regexp_like(num, '^\d*\.?\d+$')
      when true then 
        return true;
      else 
        return false; 
    end case;
  end;
  
  /* @private
   * check if given character
   */
  function exist(ch in varchar2 default '') return boolean
  is
  begin
    return ch is not null; 
  end;

  /* @private
   * convert hex number (character) to decimal number
   */
  function hex2dec(ch in char) return number
  is
  begin
    return to_number(ch, 'x');
    exception
      when value_error then
        return null;
  end;
  
  /* @private
   * convert hex code to unicode character
   */
  function getUnicodeChar(hexcode in varchar2) return varchar2
  is
  begin
    return trim(unistr('\' || hexcode || ' '));
    exception
      when others then
        return ''; 
  end;

  /* @private
   * get the next character
   */
  function nextChar(c in char default '') return char
  is
  begin
    -- if a c parameter is provided, verify that it matches the current character
    if (exist(c) and c != ch) then
      error('Expected ''' || c || ''' instead of ''' || ch || '''');
    end if;

    -- when there are no more characters, return the empty string
    ch := charAt(text, atCh);
    atCh := atCh + 1;
    return ch;
  end;
  
  /* @private
   * move current char to next
   */
  procedure nextChar(c in char default '')
  is
  begin
    -- if a c parameter is provided, verify that it matches the current character
    if (exist(c) and c != ch) then
      error('Expected ''' || c || ''' instead of ''' || ch || '''');
    end if;

    ch := charAt(text, atCh);
    atCh := atCh + 1;
  end;

  /* @private
   * forward declaration of common validate function 
   */
  function validate return boolean;

  /* @private
   * validate a number value
   */
  function validateNumber return boolean
  is
    l_number varchar2(32767) := '';
  begin
    if (ch = '-') then
      l_number := '-';
      nextChar('-');
    end if;

    while (ch >= '0' and ch <= '9') loop
      l_number := l_number || ch;
      nextChar();
    end loop;

    if (ch = '.') then
      l_number := l_number || '.';
      while (exist(nextChar()) and ch >= '0' and ch <= '9') loop
        l_number := l_number || ch;
      end loop;
    end if;

    if (ch = 'e' or ch = 'E') then
      l_number := l_number || ch;
      nextChar();

      if (ch = '-' or ch = '+') then
        l_number := l_number || ch;
        nextChar();
      end if;

      while (ch >= '0' and ch <= '9') loop
        l_number := l_number || ch;
        nextChar();
      end loop;
    end if;

    if (not(isNumber(l_number))) then
      error('Bad number');
    else
      return true;
    end if;
  end;

  /* @private
   * validate a string value
   */
  function validateString return boolean
  is
    decnum number;
  begin
    -- when parsing for string values, we must look for " and \ characters
    if (ch = '"') then
      while (exist(nextChar())) loop
        if (ch = '"') then
          nextChar();
          return true;
        end if;

        if (ch = '\') then
          nextChar();
          if (ch = 'u') then
            for i in 1..4 loop
              decnum := hex2dec(nextChar());              
              if (not isNumber(decnum)) then
                error('Malformed Unicode character escape sequence');
              end if;
            end loop;
          elsif (escapee(ch) is not null) then
            null;
          else
            exit;
          end if;
        end if;
      end loop;
    end if;
    error('Bad string');
  end;
  
  /* @private
   * get string key value (for checking duplicate keys in object value)
   */
  function stringKey return varchar2
  is
    l_string varchar2(32767) := '';
    decnum number;
    uffff varchar2(32767);
  begin
    -- when parsing for string values, we must look for " and \ characters
    if (ch = '"') then
      while (exist(nextChar())) loop
        if (ch = '"') then
          nextChar();
          return l_string;
        end if;

        if (ch = '\') then
          nextChar();
          if (ch = 'u') then
            uffff := '';
            for i in 1..4 loop
              decnum := hex2dec(nextChar());
              if (not isNumber(decnum)) then
                error('Malformed Unicode character escape sequence');
              end if;
              uffff := uffff || ch;
            end loop;
            l_string := l_string || getUnicodeChar(uffff);
          elsif (escapee(ch) is not null) then
            l_string := l_string || escapee(ch);
          else
            exit;
          end if;
        else
          l_string := l_string || ch;
        end if;
      end loop;
    end if;
    error('Bad string');
  end;
  
  /* @private
   * skip whitespace
   */
  procedure white 
  is
  begin
    while (exist(ch) and ch <= ' ') loop
      nextChar();
    end loop;
  end;

  /* @private
   * validate a word (true, false or null)
   */
  function validateWord return boolean
  is
  begin
    case ch
      when 't' then
        nextChar('t');
        nextChar('r');
        nextChar('u');
        nextChar('e');
        return true;
      when 'f' then
        nextChar('f');
        nextChar('a');
        nextChar('l');
        nextChar('s');
        nextChar('e');
        return true;
      when 'n' then
        nextChar('n');
        nextChar('u');
        nextChar('l');
        nextChar('l');
        return true;
      else
        error('Unexpected ''' || ch || '''');
    end case; 
  end;
  
  /* @private
   * validate an array value
   */
  function validateArray return boolean
  is
    l_result boolean := true;
  begin
    if (ch = '[') then
      nextChar('[');
      white();
      if (ch = ']') then
        nextChar(']');
        return l_result; -- empty array
      end if;
      
      while (exist(ch)) loop
        l_result := validate();
        white();
        if (ch = ']') then
          nextChar(']');
          return l_result;
        end if;
        nextChar(',');
        white();
      end loop;
    end if;
    error('Bad array');
  end;

  /* @private
   * validate an object value
   */
  function validateObject return boolean
  is
    l_result boolean := true;
    l_key varchar2(1000);
    l_keys array_t;
  begin
    if (ch = '{') then
      nextChar('{');
      white();
      if (ch = '}') then
        nextChar('}');
        return l_result; -- empty object
      end if;
      
      while (exist(ch)) loop
        l_key := stringKey();
        white();
        nextChar(':');
        
        if (has_key(l_keys, l_key)) then
          error('Duplicate key "' || l_key || '"');
        end if;
        
        add_key(l_keys, l_key);
        l_result := validate();
        white();
        
        if (ch = '}') then
          nextChar('}');
          return l_result;
        end if;
        
        nextChar(',');
        white();
      end loop;
    end if;
    error('Bad object');
  end;
 
  /* @public
   * validate a JSON value. 
   * It could be an object, an array, a string, a number, or a word.
   */
  function validate return boolean
  is
  begin
    white();
    case ch
      when '{' then
        return validateObject();
      when '[' then
        return validateArray();
      when '"' then
        return validateString();
      when '-' then
        return validateNumber();
      else
        return case
          when (ch >= '0' and ch <= '9') then validateNumber() else validateWord() end; 
    end case;
  end;
  
  /* @public
   * unsafety validate JSON string (throw exception ora-20000)
   */
  function unsafety_validate(source in varchar2) return boolean
  is
  begin
    return unsafety_validate(to_clob(source));
  end;           
             
  /* @public
   * unsafety validate JSON string (throw exception ora-20000)
   */
  function unsafety_validate(source in clob) return boolean
  is
    l_result boolean;
  begin
    text := source;
    atCh := 1;
    ch := ' ';
    
    l_result := validate();
    white();
    
    if (exist(ch)) then
      error('Syntax error');
    end if;
    
    return l_result; 
  end;
  
  /* @public
   * safety validate JSON string (catch all exceptions)
   */
  function safety_validate(source in varchar2) return boolean
  is
  begin
    return safety_validate(to_clob(source));
  end;           
             
  /* @public
   * safety validate JSON string (catch all exceptions)
   */
  function safety_validate(source in clob) return boolean
  is
    l_result boolean;
  begin
    text := source;
    atCh := 1;
    ch := ' ';
    
    l_result := validate();
    white();
    
    if (exist(ch)) then
      error('Syntax error');
    end if;
    
    return l_result;
    
    exception
      when others then
        return false;
  end;
  
  /* @public
   * safety validate JSON string (catch all exceptions with error message) 
   */
  function safety_validate(source in varchar2,
                           errmsg in out varchar2) return boolean
  is
  begin
    return safety_validate(to_clob(source), errmsg);
  end;           
             
  /* @public
   * safety validate JSON string (catch all exceptions with error message) 
   */
  function safety_validate(source in clob,
                           errmsg in out varchar2) return boolean
  is
    l_result boolean;
  begin
    text := source;
    atCh := 1;
    ch := ' ';
    
    l_result := validate();
    white();
    
    if (exist(ch)) then
      error('Syntax error');
    end if;
    
    return l_result;
    
    exception
      when others then
        errmsg := sqlerrm;
        return false;
  end;

begin
  -- init
  null;
end json_validator;
