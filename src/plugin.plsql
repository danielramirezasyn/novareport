-- novaReport: código PL/SQL del plugin (render + ajax)
c_max_rows constant pls_integer := 250000;

function nr_is_item(p_name in varchar2) return boolean is
    l_n pls_integer;
begin
    if p_name like 'APP\_%' escape '\' or p_name in ('DEBUG', 'REQUEST', 'SESSION', 'USER', 'WORKSPACE_ID') then
        return true;
    end if;
    select count(*)
      into l_n
      from (select item_name from apex_application_page_items
             where application_id = v('APP_ID') and page_id in (v('APP_PAGE_ID'), 0) and item_name = p_name
            union all
            select item_name from apex_application_items
             where application_id = v('APP_ID') and item_name = p_name);
    return l_n > 0;
end nr_is_item;

-- Origen "Resolver": llama a la función configurada; el navegador solo envía ID + parámetros.
-- Contrato: function f(p_id in varchar2, p_params in clob) return clob
--   -> { "sources": "--@X ...", "layout": {..} | "..", "params": {"P": valor}, "types": {"P": "text|number|date"}, "templateUrl": ".." }
function nr_resolve(p_fn in varchar2, p_id in varchar2, p_params in clob) return json_object_t is
    l_fn  varchar2(400) := trim(p_fn);
    l_res clob;
begin
    if l_fn is null or not regexp_like(l_fn, '^[A-Za-z][A-Za-z0-9_$#]*(\.[A-Za-z][A-Za-z0-9_$#]*){0,2}$') then
        raise_application_error(-20003, 'Configure la función resolver del plugin (p. ej. nrd_catalogo_pkg.resolver).');
    end if;
    if trim(p_id) is null then
        raise_application_error(-20004, 'Indique el reporte a generar (data-report).');
    end if;
    execute immediate 'begin :r := ' || dbms_assert.qualified_sql_name(l_fn) || '(p_id => :i, p_params => :p); end;'
        using out l_res, in trim(p_id), in p_params;
    if l_res is null then
        raise_application_error(-20005, 'La función resolver no devolvió el reporte.');
    end if;
    return json_object_t.parse(l_res);
end nr_resolve;

-- Origen "Consulta" (1.17): una consulta devuelve UNA fila con el diseño y/o las fuentes SQL, desde la tabla que sea.
-- Columnas reconocidas por su alias: LAYOUT (JSON), SOURCES (fuentes "--@X ..."), TEMPLATE_URL.
-- Binds: ítems de APEX (automático) y data-* del elemento, como en las fuentes SQL.
procedure nr_query(p_sql in varchar2, p_params in clob,
                   p_layout out clob, p_sources out clob, p_tpl out varchar2) is
    l_sql   varchar2(32767) := regexp_replace(rtrim(trim(p_sql), ' ' || chr(9) || chr(10) || chr(13)), '[;/]+$', '');
    l_vals  apex_json.t_values;
    l_parms apex_exec.t_parameters;
    l_ctx   apex_exec.t_context;
    l_scan  varchar2(32767);
    l_bind  varchar2(128);
    l_seen  varchar2(4000) := ',';
    l_name  varchar2(128);
    l_found boolean := false;
    l_known boolean := false;
    l_chk   json_object_t;
    function val(c in pls_integer) return clob is
    begin
        if apex_exec.get_column(l_ctx, c).data_type = apex_exec.c_data_type_clob then
            return apex_exec.get_clob(l_ctx, c);
        end if;
        return apex_exec.get_varchar2(l_ctx, c);
    end val;
begin
    if l_sql is null then
        raise_application_error(-20007, 'Configure la consulta del reporte (origen Consulta).');
    end if;
    if p_params is not null then
        apex_json.parse(l_vals, p_params);
    end if;
    l_scan := regexp_replace(l_sql, '''[^'']*''', ' ');
    l_scan := regexp_replace(l_scan, '--[^' || chr(10) || ']*', ' ');
    for b in 1 .. regexp_count(l_scan, ':[A-Za-z][A-Za-z0-9_$#]*') loop
        l_bind := upper(substr(regexp_substr(l_scan, ':[A-Za-z][A-Za-z0-9_$#]*', 1, b), 2));
        if instr(l_seen, ',' || l_bind || ',') = 0 then
            l_seen := l_seen || l_bind || ',';
            if not nr_is_item(l_bind) then
                apex_exec.add_parameter(l_parms, l_bind,
                    case when p_params is not null then apex_json.get_varchar2(p_path => l_bind, p_values => l_vals) end);
            end if;
        end if;
    end loop;
    l_ctx := apex_exec.open_query_context(
                 p_location        => apex_exec.c_location_local_db,
                 p_sql_query       => l_sql,
                 p_sql_parameters  => l_parms,
                 p_auto_bind_items => true);
    while apex_exec.next_row(l_ctx) loop
        if l_found then
            raise_application_error(-20008, 'La consulta del reporte devolvió más de una fila.');
        end if;
        l_found := true;
        for c in 1 .. apex_exec.get_column_count(l_ctx) loop
            l_name := upper(apex_exec.get_column(l_ctx, c).name);
            if l_name = 'LAYOUT' then
                p_layout := val(c); l_known := true;
            elsif l_name = 'SOURCES' then
                p_sources := val(c); l_known := true;
            elsif l_name = 'TEMPLATE_URL' then
                p_tpl := dbms_lob.substr(val(c), 4000, 1); l_known := true;
            end if;
        end loop;
    end loop;
    apex_exec.close(l_ctx);
    l_ctx := null;
    if not l_found then
        raise_application_error(-20009, 'La consulta del reporte no devolvió filas.');
    end if;
    if not l_known then
        raise_application_error(-20010, 'La consulta del reporte debe devolver las columnas LAYOUT y/o SOURCES.');
    end if;
    if p_layout is not null and dbms_lob.getlength(p_layout) > 0 then
        begin
            l_chk := json_object_t.parse(p_layout);
        exception
            when others then
                raise_application_error(-20011, 'La columna LAYOUT no es un JSON válido: ' || regexp_replace(sqlerrm, '^ORA-\d+: ', ''));
        end;
    end if;
exception
    when others then
        if l_ctx is not null then
            apex_exec.close(l_ctx);
        end if;
        raise;
end nr_query;

procedure nr_write_json(p_sources in clob, p_params in varchar2, p_summary in boolean,
                        p_res in json_object_t default null, p_layout in clob default null, p_tpl in varchar2 default null) is
    type t_src is record (name varchar2(128), flags varchar2(400), sql_text varchar2(32767));
    type t_srcs is table of t_src index by pls_integer;
    l_srcs   t_srcs;
    l_n      pls_integer := 0;
    l_lines  apex_t_varchar2;
    l_vals   apex_json.t_values;
    l_ctx    apex_exec.t_context;
    l_parms  apex_exec.t_parameters;
    l_cols   pls_integer;
    l_types  apex_t_varchar2 := apex_t_varchar2();
    l_scan   varchar2(32767);
    l_bind   varchar2(128);
    l_seen   varchar2(4000);
    l_rows   pls_integer := 0;
    l_dt     varchar2(64);
    l_blob   blob;
    l_rp     json_object_t;   -- resolver: parámetros validados
    l_rt     json_object_t;   -- resolver: tipos
    l_ty     varchar2(30);
    l_el     json_element_t;
    l_keys   json_key_list;
begin
    if p_res is not null then
        l_rp := case when p_res.has('params') then p_res.get_object('params') else json_object_t() end;
        l_rt := case when p_res.has('types') then p_res.get_object('types') else json_object_t() end;
    elsif p_params is not null then
        apex_json.parse(l_vals, p_params);
    end if;
    l_lines := apex_string.split(p_sources, chr(10));
    for i in 1 .. l_lines.count loop
        if regexp_like(l_lines(i), '^\s*--@') then
            l_n := l_n + 1;
            l_srcs(l_n).name  := upper(regexp_substr(l_lines(i), '--@\s*([A-Za-z0-9_]+)', 1, 1, null, 1));
            l_srcs(l_n).flags := lower(regexp_replace(l_lines(i), '^\s*--@\s*[A-Za-z0-9_]+', ''));
        elsif l_n > 0 then
            l_srcs(l_n).sql_text := l_srcs(l_n).sql_text || rtrim(l_lines(i), chr(13)) || chr(10);
        end if;
    end loop;
    if l_n = 0 then
        raise_application_error(-20001, 'Defina al menos una fuente con una línea "--@NOMBRE" antes del SELECT.');
    end if;

    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.open_object('data');
    for s in 1 .. l_n loop
        continue when instr(l_srcs(s).flags, 'summary') > 0 and not p_summary;
        l_srcs(s).sql_text := regexp_replace(rtrim(l_srcs(s).sql_text, ' ' || chr(9) || chr(10) || chr(13)), '[;/]+$', '');

        -- Binds que no son ítems de APEX: se toman de los parámetros (data-* del elemento) o NULL
        l_parms.delete;
        l_seen := ',';
        l_scan := regexp_replace(l_srcs(s).sql_text, '''[^'']*''', ' ');
        l_scan := regexp_replace(l_scan, '--[^' || chr(10) || ']*', ' ');
        for b in 1 .. regexp_count(l_scan, ':[A-Za-z][A-Za-z0-9_$#]*') loop
            l_bind := upper(substr(regexp_substr(l_scan, ':[A-Za-z][A-Za-z0-9_$#]*', 1, b), 2));
            if instr(l_seen, ',' || l_bind || ',') = 0 then
                l_seen := l_seen || l_bind || ',';
                if p_res is not null then
                    -- Resolver: solo APP_* (sesión) y los parámetros validados por la función; el resto NULL
                    l_ty := case when l_rt.has(l_bind) then l_rt.get_string(l_bind) end;
                    if l_bind like 'APP\_%' escape '\' then
                        apex_exec.add_parameter(l_parms, l_bind, v(l_bind));
                    elsif not l_rp.has(l_bind) or l_rp.get(l_bind).is_null then
                        apex_exec.add_parameter(l_parms, l_bind, to_char(null));
                    elsif l_ty = 'number' then
                        apex_exec.add_parameter(l_parms, l_bind, l_rp.get_number(l_bind));
                    elsif l_ty = 'date' then
                        apex_exec.add_parameter(l_parms, l_bind, to_date(l_rp.get_string(l_bind), 'YYYY-MM-DD'));
                    else
                        apex_exec.add_parameter(l_parms, l_bind, l_rp.get_string(l_bind));
                    end if;
                elsif not nr_is_item(l_bind) then
                    apex_exec.add_parameter(l_parms, l_bind,
                        case when p_params is not null then apex_json.get_varchar2(p_path => l_bind, p_values => l_vals) end);
                end if;
            end if;
        end loop;

        l_ctx := apex_exec.open_query_context(
                     p_location        => apex_exec.c_location_local_db,
                     p_sql_query       => l_srcs(s).sql_text,
                     p_sql_parameters  => l_parms,
                     p_auto_bind_items => p_res is null);
        l_cols := apex_exec.get_column_count(l_ctx);
        l_types := apex_t_varchar2();
        apex_json.open_object(l_srcs(s).name);
        apex_json.open_array('cols');
        for c in 1 .. l_cols loop
            l_dt := apex_exec.get_column(l_ctx, c).data_type;
            l_types.extend;
            l_types(c) := case
                              when l_dt = apex_exec.c_data_type_number then 'NUMBER'
                              when l_dt = apex_exec.c_data_type_date then 'DATE'
                              when l_dt = apex_exec.c_data_type_blob then 'BLOB'
                              when l_dt = apex_exec.c_data_type_clob then 'CLOB'
                              else 'VARCHAR2'
                          end;
            apex_json.open_object;
            apex_json.write('name', apex_exec.get_column(l_ctx, c).name);
            apex_json.write('type', l_types(c));
            apex_json.close_object;
        end loop;
        apex_json.close_array;
        apex_json.open_array('rows');
        while apex_exec.next_row(l_ctx) loop
            l_rows := l_rows + 1;
            if l_rows > c_max_rows then
                raise_application_error(-20002, 'El reporte supera el máximo de ' || c_max_rows || ' filas.');
            end if;
            apex_json.open_array;
            for c in 1 .. l_cols loop
                if l_types(c) = 'NUMBER' then
                    apex_json.write(apex_exec.get_number(l_ctx, c));
                elsif l_types(c) = 'DATE' then
                    apex_json.write(to_char(apex_exec.get_date(l_ctx, c), 'DD/MM/YYYY'));
                elsif l_types(c) = 'BLOB' then
                    -- Imágenes u otros binarios: viajan en base64 (sin saltos de línea)
                    l_blob := apex_exec.get_blob(l_ctx, c);
                    if l_blob is null or dbms_lob.getlength(l_blob) = 0 then
                        apex_json.write(to_char(null));
                    else
                        apex_json.write(apex_web_service.blob2clobbase64(p_blob => l_blob, p_newlines => 'N', p_padding => 'Y'));
                    end if;
                elsif l_types(c) = 'CLOB' then
                    apex_json.write(apex_exec.get_clob(l_ctx, c));
                else
                    apex_json.write(apex_exec.get_varchar2(l_ctx, c));
                end if;
            end loop;
            apex_json.close_array;
        end loop;
        apex_json.close_array;
        apex_json.close_object;
        apex_exec.close(l_ctx);
    end loop;
    apex_json.close_object;
    if p_res is not null then
        -- Diseño y parámetros (para {PARAM.X}); las fuentes SQL nunca viajan al navegador
        l_el := p_res.get('layout');
        if l_el is null then
            raise_application_error(-20006, 'La función resolver no devolvió el diseño.');
        end if;
        apex_json.write('layout', case when l_el.is_object then treat(l_el as json_object_t).to_clob else p_res.get_clob('layout') end);
        if p_res.has('templateUrl') then
            apex_json.write('templateUrl', p_res.get_string('templateUrl'));
        end if;
        apex_json.open_object('params');
        l_keys := l_rp.get_keys;
        if l_keys is not null then
            for k in 1 .. l_keys.count loop
                apex_json.write(l_keys(k), case when not l_rp.get(l_keys(k)).is_null then l_rp.get_string(l_keys(k)) end, p_write_null => true);
            end loop;
        end if;
        apex_json.close_object;
    elsif p_layout is not null and dbms_lob.getlength(p_layout) > 0 then
        -- Origen "Consulta": el diseño leído de la tabla (las fuentes SQL tampoco viajan al navegador)
        apex_json.write('layout', p_layout);
    end if;
    if p_res is null and p_tpl is not null then
        apex_json.write('templateUrl', p_tpl);
    end if;
    apex_json.close_object;
exception
    when others then
        if l_ctx is not null then
            apex_exec.close(l_ctx);
        end if;
        raise;
end nr_write_json;

function render(p_dynamic_action in apex_plugin.t_dynamic_action,
                p_plugin         in apex_plugin.t_plugin)
    return apex_plugin.t_dynamic_action_render_result is
    l_r    apex_plugin.t_dynamic_action_render_result;
    l_init varchar2(32767) := trim(p_dynamic_action.init_javascript_code);
begin
    apex_javascript.add_library(p_name => 'novareport', p_directory => p_plugin.file_prefix,
                                p_check_to_add_minified => false);
    l_r.ajax_identifier := apex_plugin.get_ajax_identifier;
    l_r.function_name   := 'novaReport.da';
    l_r.function_param.open_object;
    l_r.function_param.put('ajaxIdentifier', l_r.ajax_identifier);
    l_r.function_param.put('layout',      p_dynamic_action.attributes.get_varchar2('layout'));
    l_r.function_param.put('format',      p_dynamic_action.attributes.get_varchar2('format'));
    l_r.function_param.put('output',      p_dynamic_action.attributes.get_varchar2('output'));
    l_r.function_param.put('items',       p_dynamic_action.attributes.get_varchar2('items'));
    l_r.function_param.put('pdfAction',   p_dynamic_action.attributes.get_varchar2('pdf_action'));
    l_r.function_param.put('templateUrl', p_dynamic_action.attributes.get_varchar2('template_url'));
    l_r.function_param.put('message',     p_dynamic_action.attributes.get_varchar2('message'));
    l_r.function_param.put('origin',      nvl(p_dynamic_action.attributes.get_varchar2('origin'), 'attributes'));
    if l_init is not null then
        l_r.function_param.put_function(p_key => 'init', p_code => l_init, p_type => apex_javascript.c_type_function);
    end if;
    l_r.function_param.close_object;
    return l_r;
end render;

function ajax(p_dynamic_action in apex_plugin.t_dynamic_action,
              p_plugin         in apex_plugin.t_plugin)
    return apex_plugin.t_dynamic_action_ajax_result is
    l_r   apex_plugin.t_dynamic_action_ajax_result;
    l_out clob;
    l_res json_object_t;
    l_lay clob;
    l_src clob;
    l_tpl varchar2(4000);
begin
    begin
        if nvl(p_dynamic_action.attributes.get_varchar2('origin'), 'attributes') = 'resolver' then
            -- Nunca se acepta SQL ni diseño del navegador: solo ID (x03) + parámetros (x01)
            l_res := nr_resolve(p_fn     => p_dynamic_action.attributes.get_varchar2('resolver'),
                                p_id     => apex_application.g_x03,
                                p_params => apex_application.g_x01);
            apex_json.initialize_clob_output;
            nr_write_json(p_sources => l_res.get_clob('sources'),
                          p_params  => null,
                          p_summary => apex_application.g_x02 = 'Y',
                          p_res     => l_res);
        elsif p_dynamic_action.attributes.get_varchar2('origin') = 'query' then
            -- Diseño y/o fuentes desde una consulta; lo que no devuelva se toma de los atributos
            nr_query(p_sql     => p_dynamic_action.attributes.get_varchar2('report_query'),
                     p_params  => apex_application.g_x01,
                     p_layout  => l_lay,
                     p_sources => l_src,
                     p_tpl     => l_tpl);
            apex_json.initialize_clob_output;
            nr_write_json(p_sources => case when l_src is not null and dbms_lob.getlength(l_src) > 0 then l_src
                                            else to_clob(p_dynamic_action.attributes.get_varchar2('sources')) end,
                          p_params  => apex_application.g_x01,
                          p_summary => apex_application.g_x02 = 'Y',
                          p_layout  => l_lay,
                          p_tpl     => l_tpl);
        else
            apex_json.initialize_clob_output;
            nr_write_json(p_sources => p_dynamic_action.attributes.get_varchar2('sources'),
                          p_params  => apex_application.g_x01,
                          p_summary => apex_application.g_x02 = 'Y');
        end if;
        l_out := apex_json.get_clob_output;
        apex_json.free_output;
    exception
        when others then
            apex_json.free_output;
            apex_json.initialize_clob_output;
            apex_json.open_object;
            apex_json.write('ok', false);
            -- sin el prefijo ORA-nnnnn ni la pila (ORA-06512) de la función resolver
            apex_json.write('msg', regexp_replace(regexp_replace(sqlerrm, '^ORA-\d+: ', ''), '\s*ORA-06512:.*$', '', 1, 1, 'n'));
            apex_json.close_object;
            l_out := apex_json.get_clob_output;
            apex_json.free_output;
    end;
    apex_util.prn(l_out, false);
    return l_r;
end ajax;
