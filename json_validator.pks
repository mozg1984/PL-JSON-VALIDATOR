create or replace package json_validator is

  /******************************************************************************
   name:       json_validator
   purpose:    JSON validate of given text source.
               based on Douglas Crockford JSON parse model
               https://github.com/douglascrockford/JSON-js/blob/master/json_parse.js 

   revisions:
   Ver        Date        Author
   ---------  ----------  -------------------
   1.1        25/04/2017  Khisamutdinov Radik
  ******************************************************************************/
  
  /******************************************************************************
          This program is published under the MIT License
  *******************************************************************************/

  -- public exception type
  parse_error exception;
  pragma exception_init(parse_error, -20000);

  -- unsafety validate JSON string (throw exception ora-20000)
  function unsafety_validate(source in varchar2) return boolean;
  function unsafety_validate(source in clob) return boolean;
  
  -- safety validate JSON string (catch all exceptions)
  function safety_validate(source in varchar2) return boolean;
  function safety_validate(source in clob) return boolean;
  
  -- safety validate JSON string (catch all exceptions with error message) 
  function safety_validate(source in varchar2, errmsg in out varchar2) return boolean;
  function safety_validate(source in clob, errmsg in out varchar2) return boolean;
  
end json_validator;
