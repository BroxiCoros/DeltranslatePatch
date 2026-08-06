function scr_asterskip() //gml_Script_scr_asterskip
{
    if (aster == 1 && autoaster == 1)
    {
        length += 2
        mystring = string_insert("||", mystring, i)
        // `cur_string_width` es contabilidad del MOD: la crea el
        // `obj_writer_Create_0` reescrito y la lleva su `Other_15`. Con un
        // idioma nativo el `obj_writer` corre su gemelo vanilla, que no la
        // tiene, y esta linea reventaba el juego (Cap.5 hablando con Flowery,
        // solo en ingles; en japones no salta porque no usa los asteriscos).
        // Si el objeto no lleva esa cuenta, no hay nada que actualizar.
        if (variable_instance_exists(id, "cur_string_width"))
            cur_string_width += hspace * 2
        i += 1
        charpos++
    }
    if (aster == 2)
        aster = 1
}

