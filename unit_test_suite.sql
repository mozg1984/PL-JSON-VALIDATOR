declare
  /*
  Note: for execute this unit test you should use next package:
        https://github.com/mozg1984/dbunit 
  */

  json_string varchar2(32767);
begin
  json_string := '';
  dbunit.assert(not json_validator.safety_validate(json_string), 'JSON IS EMPTY');
  dbunit.assert(not json_validator.safety_validate(to_clob(json_string)), 'JSON IS EMPTY');

  declare
    parse_result boolean;
  begin
    parse_result := json_validator.unsafety_validate(json_string);
    parse_result := json_validator.unsafety_validate(to_clob(json_string)); 
  exception
    when json_validator.parse_error then null;
    when others then raise_application_error(-20000, 'Unknown parse error exception'); 
  end;
 
  json_string := '"some test string"';
  dbunit.assert(json_validator.safety_validate(json_string), 'JSON IS NOT VALID');
  dbunit.assert(json_validator.safety_validate(to_clob(json_string)), 'JSON IS NOT VALID');
  
  json_string := 'some test string';
  dbunit.assert(not json_validator.safety_validate(json_string), 'JSON IS NOT VALID');
  dbunit.assert(not json_validator.safety_validate(to_clob(json_string)), 'JSON IS NOT VALID');
  
  json_string := '123456';
  dbunit.assert(json_validator.safety_validate(json_string), 'JSON IS NOT VALID');
  dbunit.assert(json_validator.safety_validate(to_clob(json_string)), 'JSON IS NOT VALID');
  
  json_string := '{"key1":"value1","key2":123456,"key3":[1,2,3,4,5],"key4":{"key5":"value5"}}';
  dbunit.assert(json_validator.safety_validate(json_string), 'JSON IS NOT VALID');
  dbunit.assert(json_validator.safety_validate(to_clob(json_string)), 'JSON IS NOT VALID');
  
  json_string := '{"key1:"value1","key2":123456,"key3":[1,2,3,4,5],"key4":{"key5":"value5"}}';
  dbunit.assert(not json_validator.safety_validate(json_string), 'JSON IS NOT VALID');
  dbunit.assert(not json_validator.safety_validate(to_clob(json_string)), 'JSON IS NOT VALID');
  
  json_string := '{"key1" : "value1", "key2" : 123456, "key3" : [1, 2, 3, 4, 5], "key4" : {"key5" : "value5"}}';
  dbunit.assert(json_validator.safety_validate(json_string), 'JSON IS NOT VALID');
  dbunit.assert(json_validator.safety_validate(to_clob(json_string)), 'JSON IS NOT VALID');
end;
