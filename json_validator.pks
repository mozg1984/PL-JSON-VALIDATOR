create or replace package json_validator is

  /******************************************************************************
   name:       json_validator
   purpose:    JSON validate of given text source.
               based on Douglas Crockford JSON parse model
               https://github.com/douglascrockford/JSON-js/blob/master/json_parse.js 

   revisions:
   Ver        Date        Author
   ---------  ----------  -------------------
   1.0        20/10/2015  Khisamutdinov Radik
  ******************************************************************************/
  
  /******************************************************************************
          This program is published under the GNU LGPL License 
                  http://www.gnu.org/licenses/lgpl.html
  *******************************************************************************
   This program is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.

      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.

      You should have received a copy of the GNU General Public License
      along with this program.  If not, see <http://www.gnu.org/licenses/>.
  ********************************************************************************/

  -- public exception type
  parse_error exception;
  pragma exception_init(parse_error, -20000);

  -- unsafety validate JSON string (throw exception ora-20000)
  function unsafety_validate(source in varchar2) return boolean;
  
  -- safety validate JSON string (catch all exceptions)
  function safety_validate(source in varchar2) return boolean;
  
  -- safety validate JSON string (catch all exceptions with error message) 
  function safety_validate(source in varchar2,
                           errmsg in out varchar2) return boolean;
  
end json_validator;
