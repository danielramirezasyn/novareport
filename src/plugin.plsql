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

procedure nr_write_json(p_sources in varchar2, p_params in varchar2, p_summary in boolean) is
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
begin
    if p_params is not null then
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
                if not nr_is_item(l_bind) then
                    apex_exec.add_parameter(l_parms, l_bind,
                        case when p_params is not null then apex_json.get_varchar2(p_path => l_bind, p_values => l_vals) end);
                end if;
            end if;
        end loop;

        l_ctx := apex_exec.open_query_context(
                     p_location        => apex_exec.c_location_local_db,
                     p_sql_query       => l_srcs(s).sql_text,
                     p_sql_parameters  => l_parms,
                     p_auto_bind_items => true);
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
begin
    apex_json.initialize_clob_output;
    begin
        nr_write_json(p_sources => p_dynamic_action.attributes.get_varchar2('sources'),
                      p_params  => apex_application.g_x01,
                      p_summary => apex_application.g_x02 = 'Y');
        l_out := apex_json.get_clob_output;
        apex_json.free_output;
    exception
        when others then
            apex_json.free_output;
            apex_json.initialize_clob_output;
            apex_json.open_object;
            apex_json.write('ok', false);
            apex_json.write('msg', regexp_replace(sqlerrm, '^ORA-\d+: ', ''));
            apex_json.close_object;
            l_out := apex_json.get_clob_output;
            apex_json.free_output;
    end;
    apex_util.prn(l_out, false);
    return l_r;
end ajax;
