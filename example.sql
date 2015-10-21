declare
  json_string varchar2(1000);
  errmsg varchar2(32767);
begin
  
  json_string := '{"number": 123456, "text": "active", "array": [], "object": {}}';
  
  if json_validator.safety_validate(json_string, errmsg) then
    dbms_output.put_line('JSON is valid');
  else
    dbms_output.put_line('JSON is not valid');
    dbms_output.put_line(errmsg);
  end if;
  
end;
