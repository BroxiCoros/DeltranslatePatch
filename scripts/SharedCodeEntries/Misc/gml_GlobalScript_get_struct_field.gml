function get_struct_field(argument0, argument1, argument2)
{
    var val = variable_struct_get(argument0, argument1)
    if (is_undefined(val))
        return argument2
    return val
}

