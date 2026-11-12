prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.5'
,p_default_workspace_id=>9121565152053401
,p_default_application_id=>118
,p_default_id_offset=>0
,p_default_owner=>'WKSP_AQS'
);
end;
/
 
prompt APPLICATION 118 - novaReport Designer
--
-- Application Export:
--   Application:     118
--   Name:            novaReport Designer
--   Date and Time:   17:37 Wednesday October 28, 2026
--   Exported By:     ADMIN
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 71250679706175467
--   Manifest End
--   Version:         26.1.5
--   Instance ID:     8407602466908909
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/dynamic_action/com_novacode_novareport
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(71250679706175467)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'COM.NOVACODE.NOVAREPORT'
,p_display_name=>'NovaCode Report (PDF / Excel / Word)'
,p_apexlang_name=>'novacodeReportPdfExcelWord'
,p_category=>'EXECUTE'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('-- novaReport: c\00F3digo PL/SQL del plugin (render + ajax)'),
'c_max_rows constant pls_integer := 250000;',
'-- 1.24: idioma de los mensajes del servidor (''es'' | ''en''); lo fija ajax',
'g_nr_lang varchar2(2) := ''en'';',
'',
'function nr_t(p_es in varchar2, p_en in varchar2) return varchar2 is',
'begin',
'    return case when g_nr_lang = ''es'' then p_es else p_en end;',
'end nr_t;',
'',
unistr('-- Idioma: el que resolvi\00F3 el navegador (x04) > atributo Language > idioma de la sesi\00F3n; espa\00F1ol -> ''es'', el resto -> ''en'''),
'function nr_lang(p_attr in varchar2) return varchar2 is',
'    l_x varchar2(10) := lower(substr(apex_application.g_x04, 1, 2));',
'    l_a varchar2(10) := lower(substr(p_attr, 1, 2));',
'begin',
'    if l_x in (''es'', ''en'') then',
'        return l_x;',
'    elsif l_a in (''es'', ''en'') then',
'        return l_a;',
'    end if;',
'    return case when lower(nvl(apex_util.get_session_lang, apex_application.g_browser_language)) like ''es%'' then ''es'' else ''en'' end;',
'end nr_lang;',
'',
'function nr_is_item(p_name in varchar2) return boolean is',
'    l_n pls_integer;',
'begin',
'    if p_name like ''APP\_%'' escape ''\'' or p_name in (''DEBUG'', ''REQUEST'', ''SESSION'', ''USER'', ''WORKSPACE_ID'') then',
'        return true;',
'    end if;',
'    select count(*)',
'      into l_n',
'      from (select item_name from apex_application_page_items',
'             where application_id = v(''APP_ID'') and page_id in (v(''APP_PAGE_ID''), 0) and item_name = p_name',
'            union all',
'            select item_name from apex_application_items',
'             where application_id = v(''APP_ID'') and item_name = p_name);',
'    return l_n > 0;',
'end nr_is_item;',
'',
unistr('-- Origen "Resolver": llama a la funci\00F3n configurada; el navegador solo env\00EDa ID + par\00E1metros.'),
'-- Contrato: function f(p_id in varchar2, p_params in clob) return clob',
'--   -> { "sources": "--@X ...", "layout": {..} | "..", "params": {"P": valor}, "types": {"P": "text|number|date"}, "templateUrl": ".." }',
'function nr_resolve(p_fn in varchar2, p_id in varchar2, p_params in clob) return json_object_t is',
'    l_fn  varchar2(400) := trim(p_fn);',
'    l_res clob;',
'begin',
'    if l_fn is null or not regexp_like(l_fn, ''^[A-Za-z][A-Za-z0-9_$#]*(\.[A-Za-z][A-Za-z0-9_$#]*){0,2}$'') then',
unistr('        raise_application_error(-20003, nr_t(''Configure la funci\00F3n resolver del plugin (p. ej. nrd_catalogo_pkg.resolver).'', ''Configure the plugin resolver function (e.g. nrd_catalogo_pkg.resolver).''));'),
'    end if;',
'    if trim(p_id) is null then',
'        raise_application_error(-20004, nr_t(''Indique el reporte a generar (data-report).'', ''Specify the report to generate (data-report).''));',
'    end if;',
'    execute immediate ''begin :r := '' || dbms_assert.qualified_sql_name(l_fn) || ''(p_id => :i, p_params => :p); end;''',
'        using out l_res, in trim(p_id), in p_params;',
'    if l_res is null then',
unistr('        raise_application_error(-20005, nr_t(''La funci\00F3n resolver no devolvi\00F3 el reporte.'', ''The resolver function did not return the report.''));'),
'    end if;',
'    return json_object_t.parse(l_res);',
'end nr_resolve;',
'',
unistr('-- Origen "Consulta" (1.17): una consulta devuelve UNA fila con el dise\00F1o y/o las fuentes SQL, desde la tabla que sea.'),
'-- Columnas reconocidas por su alias: LAYOUT (JSON), SOURCES (fuentes "--@X ..."), TEMPLATE_URL.',
unistr('-- Binds: \00EDtems de APEX (autom\00E1tico) y data-* del elemento, como en las fuentes SQL.'),
'procedure nr_query(p_sql in varchar2, p_params in clob,',
'                   p_layout out clob, p_sources out clob, p_tpl out varchar2) is',
'    l_sql   varchar2(32767) := regexp_replace(rtrim(trim(p_sql), '' '' || chr(9) || chr(10) || chr(13)), ''[;/]+$'', '''');',
'    l_vals  apex_json.t_values;',
'    l_parms apex_exec.t_parameters;',
'    l_ctx   apex_exec.t_context;',
'    l_scan  varchar2(32767);',
'    l_bind  varchar2(128);',
'    l_seen  varchar2(4000) := '','';',
'    l_name  varchar2(128);',
'    l_found boolean := false;',
'    l_known boolean := false;',
'    l_chk   json_object_t;',
'    function val(c in pls_integer) return clob is',
'    begin',
'        if apex_exec.get_column(l_ctx, c).data_type = apex_exec.c_data_type_clob then',
'            return apex_exec.get_clob(l_ctx, c);',
'        end if;',
'        return apex_exec.get_varchar2(l_ctx, c);',
'    end val;',
'begin',
'    if l_sql is null then',
'        raise_application_error(-20007, nr_t(''Configure la consulta del reporte (origen Consulta).'', ''Configure the report query (Query origin).''));',
'    end if;',
'    if p_params is not null then',
'        apex_json.parse(l_vals, p_params);',
'    end if;',
'    l_scan := regexp_replace(l_sql, ''''''[^'''']*'''''', '' '');',
'    l_scan := regexp_replace(l_scan, ''--[^'' || chr(10) || '']*'', '' '');',
'    for b in 1 .. regexp_count(l_scan, '':[A-Za-z][A-Za-z0-9_$#]*'') loop',
'        l_bind := upper(substr(regexp_substr(l_scan, '':[A-Za-z][A-Za-z0-9_$#]*'', 1, b), 2));',
'        if instr(l_seen, '','' || l_bind || '','') = 0 then',
'            l_seen := l_seen || l_bind || '','';',
'            if not nr_is_item(l_bind) then',
'                apex_exec.add_parameter(l_parms, l_bind,',
'                    case when p_params is not null then apex_json.get_varchar2(p_path => l_bind, p_values => l_vals) end);',
'            end if;',
'        end if;',
'    end loop;',
'    l_ctx := apex_exec.open_query_context(',
'                 p_location        => apex_exec.c_location_local_db,',
'                 p_sql_query       => l_sql,',
'                 p_sql_parameters  => l_parms,',
'                 p_auto_bind_items => true);',
'    while apex_exec.next_row(l_ctx) loop',
'        if l_found then',
unistr('            raise_application_error(-20008, nr_t(''La consulta del reporte devolvi\00F3 m\00E1s de una fila.'', ''The report query returned more than one row.''));'),
'        end if;',
'        l_found := true;',
'        for c in 1 .. apex_exec.get_column_count(l_ctx) loop',
'            l_name := upper(apex_exec.get_column(l_ctx, c).name);',
'            if l_name = ''LAYOUT'' then',
'                p_layout := val(c); l_known := true;',
'            elsif l_name = ''SOURCES'' then',
'                p_sources := val(c); l_known := true;',
'            elsif l_name = ''TEMPLATE_URL'' then',
'                p_tpl := dbms_lob.substr(val(c), 4000, 1); l_known := true;',
'            end if;',
'        end loop;',
'    end loop;',
'    apex_exec.close(l_ctx);',
'    l_ctx := null;',
'    if not l_found then',
unistr('        raise_application_error(-20009, nr_t(''La consulta del reporte no devolvi\00F3 filas.'', ''The report query returned no rows.''));'),
'    end if;',
'    if not l_known then',
'        raise_application_error(-20010, nr_t(''La consulta del reporte debe devolver las columnas LAYOUT y/o SOURCES.'', ''The report query must return the LAYOUT and/or SOURCES columns.''));',
'    end if;',
'    if p_layout is not null and dbms_lob.getlength(p_layout) > 0 then',
'        begin',
'            l_chk := json_object_t.parse(p_layout);',
'        exception',
'            when others then',
unistr('                raise_application_error(-20011, nr_t(''La columna LAYOUT no es un JSON v\00E1lido: '', ''The LAYOUT column is not valid JSON: '') || regexp_replace(sqlerrm, ''^ORA-\005Cd+: '', ''''));'),
'        end;',
'    end if;',
'exception',
'    when others then',
'        if l_ctx is not null then',
'            apex_exec.close(l_ctx);',
'        end if;',
'        raise;',
'end nr_query;',
'',
'procedure nr_write_json(p_sources in clob, p_params in varchar2, p_summary in boolean,',
'                        p_res in json_object_t default null, p_layout in clob default null, p_tpl in varchar2 default null) is',
'    type t_src is record (name varchar2(128), flags varchar2(400), sql_text varchar2(32767));',
'    type t_srcs is table of t_src index by pls_integer;',
'    l_srcs   t_srcs;',
'    l_n      pls_integer := 0;',
'    l_lines  apex_t_varchar2;',
'    l_vals   apex_json.t_values;',
'    l_ctx    apex_exec.t_context;',
'    l_parms  apex_exec.t_parameters;',
'    l_cols   pls_integer;',
'    l_types  apex_t_varchar2 := apex_t_varchar2();',
'    l_scan   varchar2(32767);',
'    l_bind   varchar2(128);',
'    l_seen   varchar2(4000);',
'    l_rows   pls_integer := 0;',
'    l_dt     varchar2(64);',
'    l_blob   blob;',
unistr('    l_rp     json_object_t;   -- resolver: par\00E1metros validados'),
'    l_rt     json_object_t;   -- resolver: tipos',
'    l_ty     varchar2(30);',
'    l_el     json_element_t;',
'    l_keys   json_key_list;',
'begin',
'    if p_res is not null then',
'        l_rp := case when p_res.has(''params'') then p_res.get_object(''params'') else json_object_t() end;',
'        l_rt := case when p_res.has(''types'') then p_res.get_object(''types'') else json_object_t() end;',
'    elsif p_params is not null then',
'        apex_json.parse(l_vals, p_params);',
'    end if;',
'    l_lines := apex_string.split(p_sources, chr(10));',
'    for i in 1 .. l_lines.count loop',
'        if regexp_like(l_lines(i), ''^\s*--@'') then',
'            l_n := l_n + 1;',
'            l_srcs(l_n).name  := upper(regexp_substr(l_lines(i), ''--@\s*([A-Za-z0-9_]+)'', 1, 1, null, 1));',
'            l_srcs(l_n).flags := lower(regexp_replace(l_lines(i), ''^\s*--@\s*[A-Za-z0-9_]+'', ''''));',
'        elsif l_n > 0 then',
'            l_srcs(l_n).sql_text := l_srcs(l_n).sql_text || rtrim(l_lines(i), chr(13)) || chr(10);',
'        end if;',
'    end loop;',
'    if l_n = 0 then',
unistr('        raise_application_error(-20001, nr_t(''Defina al menos una fuente con una l\00EDnea "--@NOMBRE" antes del SELECT.'', ''Define at least one source with a "--@NAME" line before the SELECT.''));'),
'    end if;',
'',
'    apex_json.open_object;',
'    apex_json.write(''ok'', true);',
'    apex_json.open_object(''data'');',
'    for s in 1 .. l_n loop',
'        continue when instr(l_srcs(s).flags, ''summary'') > 0 and not p_summary;',
'        l_srcs(s).sql_text := regexp_replace(rtrim(l_srcs(s).sql_text, '' '' || chr(9) || chr(10) || chr(13)), ''[;/]+$'', '''');',
'',
unistr('        -- Binds que no son \00EDtems de APEX: se toman de los par\00E1metros (data-* del elemento) o NULL'),
'        l_parms.delete;',
'        l_seen := '','';',
'        l_scan := regexp_replace(l_srcs(s).sql_text, ''''''[^'''']*'''''', '' '');',
'        l_scan := regexp_replace(l_scan, ''--[^'' || chr(10) || '']*'', '' '');',
'        for b in 1 .. regexp_count(l_scan, '':[A-Za-z][A-Za-z0-9_$#]*'') loop',
'            l_bind := upper(substr(regexp_substr(l_scan, '':[A-Za-z][A-Za-z0-9_$#]*'', 1, b), 2));',
'            if instr(l_seen, '','' || l_bind || '','') = 0 then',
'                l_seen := l_seen || l_bind || '','';',
'                if p_res is not null then',
unistr('                    -- Resolver: solo APP_* (sesi\00F3n) y los par\00E1metros validados por la funci\00F3n; el resto NULL'),
'                    l_ty := case when l_rt.has(l_bind) then l_rt.get_string(l_bind) end;',
'                    if l_bind like ''APP\_%'' escape ''\'' then',
'                        apex_exec.add_parameter(l_parms, l_bind, v(l_bind));',
'                    elsif not l_rp.has(l_bind) or l_rp.get(l_bind).is_null then',
'                        apex_exec.add_parameter(l_parms, l_bind, to_char(null));',
'                    elsif l_ty = ''number'' then',
'                        apex_exec.add_parameter(l_parms, l_bind, l_rp.get_number(l_bind));',
'                    elsif l_ty = ''date'' then',
'                        apex_exec.add_parameter(l_parms, l_bind, to_date(l_rp.get_string(l_bind), ''YYYY-MM-DD''));',
'                    else',
'                        apex_exec.add_parameter(l_parms, l_bind, l_rp.get_string(l_bind));',
'                    end if;',
'                elsif not nr_is_item(l_bind) then',
'                    apex_exec.add_parameter(l_parms, l_bind,',
'                        case when p_params is not null then apex_json.get_varchar2(p_path => l_bind, p_values => l_vals) end);',
'                end if;',
'            end if;',
'        end loop;',
'',
'        l_ctx := apex_exec.open_query_context(',
'                     p_location        => apex_exec.c_location_local_db,',
'                     p_sql_query       => l_srcs(s).sql_text,',
'                     p_sql_parameters  => l_parms,',
'                     p_auto_bind_items => p_res is null);',
'        l_cols := apex_exec.get_column_count(l_ctx);',
'        l_types := apex_t_varchar2();',
'        apex_json.open_object(l_srcs(s).name);',
'        apex_json.open_array(''cols'');',
'        for c in 1 .. l_cols loop',
'            l_dt := apex_exec.get_column(l_ctx, c).data_type;',
'            l_types.extend;',
'            l_types(c) := case',
'                              when l_dt = apex_exec.c_data_type_number then ''NUMBER''',
'                              when l_dt = apex_exec.c_data_type_date then ''DATE''',
'                              when l_dt = apex_exec.c_data_type_blob then ''BLOB''',
'                              when l_dt = apex_exec.c_data_type_clob then ''CLOB''',
'                              else ''VARCHAR2''',
'                          end;',
'            apex_json.open_object;',
'            apex_json.write(''name'', apex_exec.get_column(l_ctx, c).name);',
'            apex_json.write(''type'', l_types(c));',
'            apex_json.close_object;',
'        end loop;',
'        apex_json.close_array;',
'        apex_json.open_array(''rows'');',
'        while apex_exec.next_row(l_ctx) loop',
'            l_rows := l_rows + 1;',
'            if l_rows > c_max_rows then',
unistr('                raise_application_error(-20002, nr_t(''El reporte supera el m\00E1ximo de '' || c_max_rows || '' filas.'', ''The report exceeds the maximum of '' || c_max_rows || '' rows.''));'),
'            end if;',
'            apex_json.open_array;',
'            for c in 1 .. l_cols loop',
'                if l_types(c) = ''NUMBER'' then',
'                    apex_json.write(apex_exec.get_number(l_ctx, c));',
'                elsif l_types(c) = ''DATE'' then',
'                    apex_json.write(to_char(apex_exec.get_date(l_ctx, c), ''DD/MM/YYYY''));',
'                elsif l_types(c) = ''BLOB'' then',
unistr('                    -- Im\00E1genes u otros binarios: viajan en base64 (sin saltos de l\00EDnea)'),
'                    l_blob := apex_exec.get_blob(l_ctx, c);',
'                    if l_blob is null or dbms_lob.getlength(l_blob) = 0 then',
'                        apex_json.write(to_char(null));',
'                    else',
'                        apex_json.write(apex_web_service.blob2clobbase64(p_blob => l_blob, p_newlines => ''N'', p_padding => ''Y''));',
'                    end if;',
'                elsif l_types(c) = ''CLOB'' then',
'                    apex_json.write(apex_exec.get_clob(l_ctx, c));',
'                else',
'                    apex_json.write(apex_exec.get_varchar2(l_ctx, c));',
'                end if;',
'            end loop;',
'            apex_json.close_array;',
'        end loop;',
'        apex_json.close_array;',
'        apex_json.close_object;',
'        apex_exec.close(l_ctx);',
'    end loop;',
'    apex_json.close_object;',
'    if p_res is not null then',
unistr('        -- Dise\00F1o y par\00E1metros (para {PARAM.X}); las fuentes SQL nunca viajan al navegador'),
'        l_el := p_res.get(''layout'');',
'        if l_el is null then',
unistr('            raise_application_error(-20006, nr_t(''La funci\00F3n resolver no devolvi\00F3 el dise\00F1o.'', ''The resolver function did not return the layout.''));'),
'        end if;',
'        apex_json.write(''layout'', case when l_el.is_object then treat(l_el as json_object_t).to_clob else p_res.get_clob(''layout'') end);',
'        if p_res.has(''templateUrl'') then',
'            apex_json.write(''templateUrl'', p_res.get_string(''templateUrl''));',
'        end if;',
'        apex_json.open_object(''params'');',
'        l_keys := l_rp.get_keys;',
'        if l_keys is not null then',
'            for k in 1 .. l_keys.count loop',
'                apex_json.write(l_keys(k), case when not l_rp.get(l_keys(k)).is_null then l_rp.get_string(l_keys(k)) end, p_write_null => true);',
'            end loop;',
'        end if;',
'        apex_json.close_object;',
'    elsif p_layout is not null and dbms_lob.getlength(p_layout) > 0 then',
unistr('        -- Origen "Consulta": el dise\00F1o le\00EDdo de la tabla (las fuentes SQL tampoco viajan al navegador)'),
'        apex_json.write(''layout'', p_layout);',
'    end if;',
'    if p_res is null and p_tpl is not null then',
'        apex_json.write(''templateUrl'', p_tpl);',
'    end if;',
'    apex_json.close_object;',
'exception',
'    when others then',
'        if l_ctx is not null then',
'            apex_exec.close(l_ctx);',
'        end if;',
'        raise;',
'end nr_write_json;',
'',
'function render(p_dynamic_action in apex_plugin.t_dynamic_action,',
'                p_plugin         in apex_plugin.t_plugin)',
'    return apex_plugin.t_dynamic_action_render_result is',
'    l_r    apex_plugin.t_dynamic_action_render_result;',
'    l_init varchar2(32767) := trim(p_dynamic_action.init_javascript_code);',
'begin',
'    apex_javascript.add_library(p_name => ''novareport'', p_directory => p_plugin.file_prefix,',
'                                p_check_to_add_minified => false);',
'    l_r.ajax_identifier := apex_plugin.get_ajax_identifier;',
'    l_r.function_name   := ''novaReport.da'';',
'    l_r.function_param.open_object;',
'    l_r.function_param.put(''ajaxIdentifier'', l_r.ajax_identifier);',
'    l_r.function_param.put(''layout'',      p_dynamic_action.attributes.get_varchar2(''layout''));',
'    l_r.function_param.put(''format'',      p_dynamic_action.attributes.get_varchar2(''format''));',
'    l_r.function_param.put(''output'',      p_dynamic_action.attributes.get_varchar2(''output''));',
'    l_r.function_param.put(''items'',       p_dynamic_action.attributes.get_varchar2(''items''));',
'    l_r.function_param.put(''pdfAction'',   p_dynamic_action.attributes.get_varchar2(''pdf_action''));',
'    l_r.function_param.put(''templateUrl'', p_dynamic_action.attributes.get_varchar2(''template_url''));',
'    l_r.function_param.put(''message'',     p_dynamic_action.attributes.get_varchar2(''message''));',
'    l_r.function_param.put(''origin'',      nvl(p_dynamic_action.attributes.get_varchar2(''origin''), ''attributes''));',
'    l_r.function_param.put(''lang'',        nvl(p_dynamic_action.attributes.get_varchar2(''language''), ''auto''));',
'    if l_init is not null then',
'        l_r.function_param.put_function(p_key => ''init'', p_code => l_init, p_type => apex_javascript.c_type_function);',
'    end if;',
'    l_r.function_param.close_object;',
'    return l_r;',
'end render;',
'',
'function ajax(p_dynamic_action in apex_plugin.t_dynamic_action,',
'              p_plugin         in apex_plugin.t_plugin)',
'    return apex_plugin.t_dynamic_action_ajax_result is',
'    l_r   apex_plugin.t_dynamic_action_ajax_result;',
'    l_out clob;',
'    l_res json_object_t;',
'    l_lay clob;',
'    l_src clob;',
'    l_tpl varchar2(4000);',
'begin',
'    g_nr_lang := nr_lang(p_dynamic_action.attributes.get_varchar2(''language''));',
'    begin',
'        if nvl(p_dynamic_action.attributes.get_varchar2(''origin''), ''attributes'') = ''resolver'' then',
unistr('            -- Nunca se acepta SQL ni dise\00F1o del navegador: solo ID (x03) + par\00E1metros (x01)'),
'            l_res := nr_resolve(p_fn     => p_dynamic_action.attributes.get_varchar2(''resolver''),',
'                                p_id     => apex_application.g_x03,',
'                                p_params => apex_application.g_x01);',
'            apex_json.initialize_clob_output;',
'            nr_write_json(p_sources => l_res.get_clob(''sources''),',
'                          p_params  => null,',
'                          p_summary => apex_application.g_x02 = ''Y'',',
'                          p_res     => l_res);',
'        elsif p_dynamic_action.attributes.get_varchar2(''origin'') = ''query'' then',
unistr('            -- Dise\00F1o y/o fuentes desde una consulta; lo que no devuelva se toma de los atributos'),
'            nr_query(p_sql     => p_dynamic_action.attributes.get_varchar2(''report_query''),',
'                     p_params  => apex_application.g_x01,',
'                     p_layout  => l_lay,',
'                     p_sources => l_src,',
'                     p_tpl     => l_tpl);',
'            apex_json.initialize_clob_output;',
'            nr_write_json(p_sources => case when l_src is not null and dbms_lob.getlength(l_src) > 0 then l_src',
'                                            else to_clob(p_dynamic_action.attributes.get_varchar2(''sources'')) end,',
'                          p_params  => apex_application.g_x01,',
'                          p_summary => apex_application.g_x02 = ''Y'',',
'                          p_layout  => l_lay,',
'                          p_tpl     => l_tpl);',
'        else',
'            apex_json.initialize_clob_output;',
'            nr_write_json(p_sources => p_dynamic_action.attributes.get_varchar2(''sources''),',
'                          p_params  => apex_application.g_x01,',
'                          p_summary => apex_application.g_x02 = ''Y'');',
'        end if;',
'        l_out := apex_json.get_clob_output;',
'        apex_json.free_output;',
'    exception',
'        when others then',
'            apex_json.free_output;',
'            apex_json.initialize_clob_output;',
'            apex_json.open_object;',
'            apex_json.write(''ok'', false);',
unistr('            -- sin el prefijo ORA-nnnnn ni la pila (ORA-06512) de la funci\00F3n resolver'),
'            apex_json.write(''msg'', regexp_replace(regexp_replace(sqlerrm, ''^ORA-\d+: '', ''''), ''\s*ORA-06512:.*$'', '''', 1, 1, ''n''));',
'            apex_json.close_object;',
'            l_out := apex_json.get_clob_output;',
'            apex_json.free_output;',
'    end;',
'    apex_util.prn(l_out, false);',
'    return l_r;',
'end ajax;',
''))
,p_api_version=>2
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'INIT_JAVASCRIPT_CODE'
,p_substitute_attributes=>true
,p_help_text=>'<p>Generates PDF, styled Excel and Word reports from SQL sources and a JSON layout. Batch mode: one file per document inside a ZIP, with an optional summary. Built-in texts in English or Spanish (Language attribute, <code>lang</code> in the layout or the APEX session language). Libraries load on demand.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('<p>Genera reportes PDF, Excel con estilos y Word desde fuentes SQL y un dise\00F1o JSON. Modo lote: un archivo por documento dentro de un ZIP, con resumen opcional. Librer\00EDas (jsPDF, autotable, ExcelJS, docx, docxtemplater, JSZip) se cargan bajo demanda.')
||'</p>'
,p_version_identifier=>'1.24.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>37
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175479)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'format'
,p_prompt=>'Format'
,p_apexlang_name=>'formato'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'pdf'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Format to generate. Can be overridden with <code>data-format</code> on the triggering element.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('Formato a generar. Puede sobrescribirse con <code>data-format</code> en el elemento que dispara la acci\00F3n.')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175498)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>20
,p_display_value=>'Excel (styled .xlsx)'
,p_return_value=>'xlsx'
,p_apexlang_name=>'excelXlsxConEstilos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175497)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>10
,p_display_value=>'PDF'
,p_return_value=>'pdf'
,p_apexlang_name=>'pdf'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175501)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>50
,p_display_value=>'All (PDF + Excel + Word)'
,p_return_value=>'all'
,p_apexlang_name=>'todosPdfExcelWord'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175500)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>40
,p_display_value=>'Word from template'
,p_return_value=>'docx-template'
,p_apexlang_name=>'wordDesdePlantilla'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175499)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>30
,p_display_value=>'Word (.docx)'
,p_return_value=>'docx'
,p_apexlang_name=>'wordDocx'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175481)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'items'
,p_prompt=>'Items to Submit'
,p_apexlang_name=>'temsAEnviar'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'<p>Items whose current on-screen value is submitted before the queries run.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('\00CDtems cuyo valor actual de pantalla se env\00EDa antes de ejecutar las consultas.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175478)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'layout'
,p_prompt=>'Layout (JSON)'
,p_apexlang_name=>'diseoJson'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>'<p>Layout as JSON (or the name of a global JavaScript variable holding it). Section types accept the original names (tabla, ficha, texto...) or their English aliases (table, details, text...). See docs/DISENO.md.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('Dise\00F1o en JSON (o el nombre de una variable JavaScript global con el dise\00F1o). Secciones: header, ficha, tabla, alerta, texto, salto. Plantillas {COL}, {FUENTE.COL}, {DOC.COL}, {ITEM.P1_X}, {NOW}, {PAGE}/{PAGES}; formatos {COL|money}, |int, |num:3, |p')
||'ct, |date, |upper. Reutilice bloques con "defs" y "@NOMBRE". Para Excel use "xlsx.sheets"; para lotes "batch" (zipName, summary, chunkSize, maxDocs).'
||unistr(' Con origen Consulta es opcional: se usa si la consulta no devuelve LAYOUT.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175484)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'message'
,p_prompt=>'Wait Message'
,p_apexlang_name=>'mensajeDeEspera'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_max_length=>200
,p_is_translatable=>false
,p_help_text=>'Text shown while the data is fetched. Empty: "Fetching data..." / "Consultando datos..." according to the language.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175485)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>5
,p_static_id=>'origin'
,p_prompt=>'Origin'
,p_apexlang_name=>'origen'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'attributes'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p><b>Attributes</b>: SQL sources and layout are set on this action. <b>Query</b>: a query returns one row with the layout and/or sources stored in your own table. <b>Resolver</b>: the browser only sends the report ID (<code>data-report</code>) and a PL/SQL function returns sources and layout.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('<p><b>Atributos</b>: las fuentes SQL y el dise\00F1o se configuran en esta acci\00F3n.</p><p><b>Resolver</b>: el navegador solo env\00EDa el ID del reporte (<code>data-report</code> u <code>o.report</code> en Initialization Code) y los par\00E1metros; una funci\00F3n PL')
||unistr('/SQL valida el acceso y devuelve fuentes y dise\00F1o. Nunca se acepta SQL desde el navegador.</p><p><b>Consulta</b>: una consulta (sobre la tabla que usted elija) devuelve una fila con las columnas <code>LAYOUT</code> y/o <code>SOURCES</code> (y opcional <code>TEMP')
||unistr('LATE_URL</code>). Lo que no devuelva se toma de los atributos de esta acci\00F3n.</p>')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175527)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_display_sequence=>10
,p_display_value=>'Attributes (sources and layout here)'
,p_return_value=>'attributes'
,p_apexlang_name=>'atributos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175530)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_display_sequence=>15
,p_display_value=>'Query (layout and/or SQL from a table)'
,p_return_value=>'query'
,p_apexlang_name=>'consulta'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175528)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_display_sequence=>20
,p_display_value=>'Resolver (PL/SQL function by report ID)'
,p_return_value=>'resolver'
,p_apexlang_name=>'resolver'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175480)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'output'
,p_prompt=>'Output'
,p_apexlang_name=>'salida'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'file'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Can be overridden with <code>data-output</code> on the element (e.g. a button with data-output="zip").</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('Puede sobrescribirse con <code>data-output</code> en el elemento (p. ej. un bot\00F3n con data-output="zip").')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175507)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175480)
,p_display_sequence=>10
,p_display_value=>'File (ZIP when there are several documents)'
,p_return_value=>'file'
,p_apexlang_name=>'archivoZipSiHayVariosDocumentos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175509)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175480)
,p_display_sequence=>30
,p_display_value=>'One file with all documents'
,p_return_value=>'merge'
,p_apexlang_name=>'unSoloArchivoConTodosLosDocumentos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175508)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175480)
,p_display_sequence=>20
,p_display_value=>'ZIP: one file per document + summary'
,p_return_value=>'zip'
,p_apexlang_name=>'zipUnArchivoPorDocumentoResumen'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175482)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_static_id=>'pdf_action'
,p_prompt=>'Single-Document PDF'
,p_apexlang_name=>'pdfDeUnDocumento'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'open'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175517)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175482)
,p_display_sequence=>10
,p_display_value=>'Open in a new tab (with wait screen)'
,p_return_value=>'open'
,p_apexlang_name=>'abrirEnUnaPestaaNuevaConPantallaDeEspera'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175518)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175482)
,p_display_sequence=>20
,p_display_value=>'Download'
,p_return_value=>'download'
,p_apexlang_name=>'descargar'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(67617776389830689)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>90
,p_static_id=>'language'
,p_prompt=>'Language'
,p_apexlang_name=>'language'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'auto'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Language of the plugin''s own texts (messages, <i>Totals</i>, <i>Subtotal</i>, <i>Yes/No</i>, <i>Page X of Y</i>...). <b>Automatic</b>: Spanish when the APEX session language is Spanish, English otherwise. <code>"lang": "en" | "es"</code> in the layout overrides this attribute.</p><p><i>Espa'||unistr('\00F1')||'ol:</i> idioma de los textos propios del plugin. <b>Autom'||unistr('\00E1')||'tico</b>: espa'||unistr('\00F1')||'ol si la sesi'||unistr('\00F3')||'n de APEX est'||unistr('\00E1')||' en espa'||unistr('\00F1')||'ol; ingl'||unistr('\00E9')||'s en los dem'||unistr('\00E1')||'s casos.</p>'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(67617876609830689)
,p_plugin_attribute_id=>wwv_flow_imp.id(67617776389830689)
,p_display_sequence=>10
,p_display_value=>'Automatic (APEX session language)'
,p_return_value=>'auto'
,p_apexlang_name=>'automatic'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(67617914710830689)
,p_plugin_attribute_id=>wwv_flow_imp.id(67617776389830689)
,p_display_sequence=>20
,p_display_value=>'English'
,p_return_value=>'en'
,p_apexlang_name=>'english'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(67618067864830689)
,p_plugin_attribute_id=>wwv_flow_imp.id(67617776389830689)
,p_display_sequence=>30
,p_display_value=>unistr('Espa\00F1ol')
,p_return_value=>'es'
,p_apexlang_name=>'espanol'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175486)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>6
,p_static_id=>'resolver'
,p_prompt=>'Resolver Function'
,p_apexlang_name=>'funcionResolver'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_default_value=>'nrd_catalogo_pkg.resolver'
,p_display_length=>60
,p_max_length=>400
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>'<p>Function <code>f(p_id in varchar2, p_params in clob) return clob</code> returning <code>{ "sources", "layout", "params", "types" }</code>. It must validate role and parameters. See docs/API.md.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||unistr('Funci\00F3n <code>f(p_id in varchar2, p_params in clob) return clob</code> que devuelve <code>{ "sources": "--@X ...", "layout": {...}, "params": {...}, "types": {"P": "text|number|date"} }</code>. Debe validar rol y par\00E1metros. Ver docs/API.md.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175529)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>7
,p_static_id=>'report_query'
,p_prompt=>'Report Query'
,p_apexlang_name=>'consultaDelReporte'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>true
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'query'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select layout, fuentes as sources',
'  from mis_reportes',
' where codigo = :P5_REPORTE'))
,p_help_text=>'<p>Query returning <b>one row</b> with the layout and/or SQL sources stored in a table. Recognized column aliases: <code>LAYOUT</code> (JSON, CLOB), <code>SOURCES</code> (SQL sources with <code>--@NAME</code> lines) and <code>TEMPLATE_URL</code> (optional). Anything not returned is taken from the Layout and SQL Sources attributes. The saved SQL runs with the schema privileges: restrict who can change that table.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('<p>Consulta que devuelve <b>una fila</b> con el dise\00F1o y/o las fuentes SQL guardados en una tabla. Columnas reconocidas por su alias:</p>'),
unistr('<ul><li><code>LAYOUT</code>: dise\00F1o JSON (CLOB).</li><li><code>SOURCES</code>: fuentes SQL con l\00EDneas <code>--@NOMBRE</code> (CLOB).</li><li><code>TEMPLATE_URL</code>: plantilla Word (opcional).</li></ul>'),
unistr('<p>Lo que no devuelva se toma de los atributos Dise\00F1o y Fuentes SQL. Admite \00EDtems de APEX (:P5_X) y binds desde <code>data-*</code>. Las fuentes SQL no viajan al navegador.</p>'),
unistr('<p><b>Seguridad</b>: el SQL guardado se ejecuta con los privilegios del schema; restrinja INSERT/UPDATE sobre esa tabla a los desarrolladores.</p>')))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175477)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'sources'
,p_prompt=>'SQL Sources'
,p_apexlang_name=>'fuentesSql'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>'<p>One or more queries. Each starts with a <code>--@NAME</code> line (add <code>summary</code> to run it only for ZIP downloads with a summary). <b>DOCS</b> (optional): one row per document, <code>DOC_KEY</code> column required. Other sources with a <code>DOC_KEY</code> column are split per document. APEX items bind automatically (:P1_X); other binds (:DET) take their value from <code>data-*</code> attributes of the triggering element.</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('Una o varias consultas. Cada una inicia con una l\00EDnea <code>--@NOMBRE</code> (agregue <code>summary</code> para que solo se ejecute en descargas ZIP con resumen).'),
'<ul><li><b>DOCS</b> (opcional): una fila por documento; columna <code>DOC_KEY</code> obligatoria.</li>',
unistr('<li>Las dem\00E1s fuentes con columna <code>DOC_KEY</code> se reparten por documento; sin ella, se comparten.</li>'),
unistr('<li>Los \00EDtems de APEX se enlazan solos (:P1_X). Otros binds (:DET) toman su valor de los atributos <code>data-*</code> del elemento que dispara la acci\00F3n (data-det) o quedan en NULL.</li></ul>'),
'<p>Con origen Consulta es opcional: se usa si la consulta no devuelve SOURCES.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175483)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'template_url'
,p_prompt=>'Word Template (URL)'
,p_apexlang_name=>'plantillaWordUrl'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'docx-template'
,p_help_text=>'<p>URL of the .docx with placeholders {FIELD}, {SOURCE.FIELD}, loops {#SOURCE}...{/SOURCE} and formats {FIELD|money}. E.g.: #APP_FILES#templates/letter.docx</p><p><i>Espa'||unistr('\00F1')||'ol:</i></p>'||'URL del .docx con marcadores {CAMPO}, {FUENTE.CAMPO}, bucles {#FUENTE}...{/FUENTE} y formatos {CAMPO|money}. Ej.: #APP_FILES#plantillas/carta.docx'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E32342E30202D20504446202F20457863656C202F20576F7264207265706F72747320666F72204F7261636C6520415045582028454E202F204553290A202A2068747470733A2F2F6769746875622E636F';
wwv_flow_imp.g_varchar2_table(2) := '6D2F64616E69656C72616D6972657A6173796E2F6E6F76617265706F7274202D204C6963656E636961204D49540A202A204E6F7661436F6465202D20706C7567696E2064652041636369C3B36E2044696EC3A16D69636120434F4D2E4E4F5641434F4445';
wwv_flow_imp.g_varchar2_table(3) := '2E4E4F56415245504F52540A202A0A202A204D6F746F72206465206C61796F75743A20756E206D69736D6F2064697365C3B16F20284A534F4E29207920756E6173206D69736D6173206675656E7465732053514C2067656E6572616E0A202A2050444620';
wwv_flow_imp.g_varchar2_table(4) := '286A73504446202B206175746F7461626C65292C20457863656C20636F6E20657374696C6F732028457863656C4A53292C20576F72642028646F637829206F20576F72642064657364650A202A20706C616E74696C6C612028646F637874656D706C6174';
wwv_flow_imp.g_varchar2_table(5) := '6572292E204D6F646F206C6F74653A20756E206172636869766F20706F7220646F63756D656E746F20656E20756E205A495020284A535A6970292E0A202A2F0A77696E646F772E6E6F76615265706F72743D66756E6374696F6E28297B22757365207374';
wwv_flow_imp.g_varchar2_table(6) := '72696374223B76617220653D7B6A737064663A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737064662F342E322E312F6A737064662E756D642E6D696E2E6A73222C6F6B3A66756E';
wwv_flow_imp.g_varchar2_table(7) := '6374696F6E28297B72657475726E21282177696E646F772E6A737064667C7C2177696E646F772E6A737064662E6A73504446297D7D2C6175746F7461626C653A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F61';
wwv_flow_imp.g_varchar2_table(8) := '6A61782F6C6962732F6A737064662D6175746F7461626C652F332E382E342F6A737064662E706C7567696E2E6175746F7461626C652E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E6A73706466262677';
wwv_flow_imp.g_varchar2_table(9) := '696E646F772E6A737064662E6A73504446262677696E646F772E6A737064662E6A735044462E4150492E6175746F5461626C65297D7D2C657863656C6A733A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A';
wwv_flow_imp.g_varchar2_table(10) := '61782F6C6962732F657863656C6A732F342E342E302F657863656C6A732E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E457863656C4A537D7D2C6A737A69703A7B75726C3A2268747470733A2F2F63646E';
wwv_flow_imp.g_varchar2_table(11) := '6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737A69702F332E31302E312F6A737A69702E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E4A535A69707D7D2C646F63783A7B7572';
wwv_flow_imp.g_varchar2_table(12) := '6C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637840392E352E312F646973742F696E6465782E696966652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21282177696E646F772E646F63787C7C21';
wwv_flow_imp.g_varchar2_table(13) := '77696E646F772E646F63782E446F63756D656E74297D7D2C70697A7A69703A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F70697A7A697040332E312E382F646973742F70697A7A69702E6D696E2E6A73222C6F';
wwv_flow_imp.g_varchar2_table(14) := '6B3A66756E6374696F6E28297B72657475726E212177696E646F772E50697A5A69707D7D2C646F637874656D706C617465723A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637874656D706C6174657240';
wwv_flow_imp.g_varchar2_table(15) := '332E36302E302F6275696C642F646F637874656D706C617465722E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E646F637874656D706C617465727D7D2C7172636F64653A7B75726C3A2268747470733A2F';
wwv_flow_imp.g_varchar2_table(16) := '2F63646E2E6A7364656C6976722E6E65742F6E706D2F7172636F64652D67656E657261746F7240312E342E342F7172636F64652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E2266756E6374696F6E223D3D747970656F662077696E646F';
wwv_flow_imp.g_varchar2_table(17) := '772E7172636F64657D7D2C63686172746A733A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F63686172742E6A7340342E342E392F646973742F63686172742E756D642E6A73222C6F6B3A66756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(18) := '297B72657475726E21282177696E646F772E43686172747C7C2177696E646F772E43686172742E7265676973746572297D7D2C7064666C69623A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C69';
wwv_flow_imp.g_varchar2_table(19) := '62732F7064662D6C69622F312E31372E312F7064662D6C69622E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21282177696E646F772E5044464C69627C7C2177696E646F772E5044464C69622E504446446F63756D656E74297D';
wwv_flow_imp.g_varchar2_table(20) := '7D7D2C743D7B7064663A5B226A73706466222C226175746F7461626C65225D2C786C73783A5B22657863656C6A73225D2C646F63783A5B22646F6378225D2C22646F63782D74656D706C617465223A5B2270697A7A6970222C22646F637874656D706C61';
wwv_flow_imp.g_varchar2_table(21) := '746572225D2C7A69703A5B226A737A6970225D7D3B66756E6374696F6E20722874297B72657475726E20742E7265647563652866756E6374696F6E28742C72297B72657475726E20742E7468656E2866756E6374696F6E28297B72657475726E20655B72';
wwv_flow_imp.g_varchar2_table(22) := '5D2E6F6B28293F6E756C6C3A28743D4D7428655B725D2E75726C292C6E65772050726F6D6973652866756E6374696F6E28652C72297B766172206E3D77696E646F772E646566696E653B77696E646F772E646566696E653D766F696420303B766172206F';
wwv_flow_imp.g_varchar2_table(23) := '3D646F63756D656E742E637265617465456C656D656E74282273637269707422293B6F2E7372633D742C6F2E6F6E6C6F61643D66756E6374696F6E28297B77696E646F772E646566696E653D6E2C6528297D2C6F2E6F6E6572726F723D66756E6374696F';
wwv_flow_imp.g_varchar2_table(24) := '6E28297B77696E646F772E646566696E653D6E2C72286E6577204572726F72286128226C69624C6F6164222C742929297D2C646F63756D656E742E686561642E617070656E644368696C64286F297D29293B76617220747D297D2C50726F6D6973652E72';
wwv_flow_imp.g_varchar2_table(25) := '65736F6C76652829297D766172206E3D22656E222C6F3D7B65733A7B6C69624C6F61643A224E6F207365207075646F20636172676172206C61206C6962726572C3AD613A207B307D222C7965733A2253C3AD222C6E6F3A224E6F222C696D674261643A22';
wwv_flow_imp.g_varchar2_table(26) := '6E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E207B307D222C6167674176673A2250726F6D2E222C6167674D696E3A224DC3AD6E2E222C6167674D61783A224DC3A1782E222C616767436F756E743A2243616E742E222C74';
wwv_flow_imp.g_varchar2_table(27) := '6F74616C733A22546F74616C6573222C746F74616C3A22546F74616C222C737562746F74616C3A22537562746F74616C222C63617272793A2256616E222C636172727946726F6D3A225669656E656E222C6669656C644261643A274E6F6D627265206465';
wwv_flow_imp.g_varchar2_table(28) := '2063616D706F20696E76C3A16C69646F3A20227B307D222E20557365206C65747261732C206EC3BA6D65726F732079205F202868617374612034302C2073696E206573706163696F73206E692070756E746F7329207920717565206E6F20706172657A63';
wwv_flow_imp.g_varchar2_table(29) := '6120756E612063656C646120646520457863656C202841312C2052314331292E272C6669656C644475703A274E6F6D6272652064652063616D706F20726570657469646F20656E20656C20646F63756D656E746F3A20227B307D222E272C6669656C6454';
wwv_flow_imp.g_varchar2_table(30) := '7970653A275469706F2064652063616D706F206E6F20736F706F727461646F3A20227B307D222028746578742C206D756C74696C696E652C206C6973742C20636865636B626F78292E272C6C697374456D7074793A27456C2063616D706F20227B307D22';
wwv_flow_imp.g_varchar2_table(31) := '20657320756E61206C697374612073696E206F7063696F6E657320286F7074696F6E732075206F7074696F6E7346726F6D292E272C776F726450773A224C6120636F6E7472617365C3B1612064652070726F7465636369C3B36E20646520576F72642061';
wwv_flow_imp.g_varchar2_table(32) := '646D697465206465203120612031352063617261637465726573204153434949202873696E2074696C646573206E6920C3B1292E222C7064664C6F61643A224E6F207365207075646F2063617267617220656C20504446207B307D20287B317D29222C70';
wwv_flow_imp.g_varchar2_table(33) := '6466417070656E643A224E6F207365207075646F20616E6578617220656C205044463A207B307D222C696D674C6F61643A224E6F207365207075646F20636172676172206C6120696D6167656E207B307D20287B317D29222C696D67466D743A22466F72';
wwv_flow_imp.g_varchar2_table(34) := '6D61746F20646520696D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E222C63616E7661733A22536520726571756965726520756E206E6176656761646F72202863616E7661732920706172612067656E65726172';
wwv_flow_imp.g_varchar2_table(35) := '206772C3A16669636F732E222C71724C69623A224E6F2073652063617267C3B3206C61206C6962726572C3AD612064652063C3B36469676F732051522E222C636F64654B696E643A225469706F2064652063C3B36469676F206E6F20736F706F72746164';
wwv_flow_imp.g_varchar2_table(36) := '6F3A207B307D2028757365207172206F20636F6465313238292E222C63686172744C69623A224E6F2073652063617267C3B3206C61206C6962726572C3AD61206465206772C3A16669636F73202843686172742E6A73292E222C617070656E6450773A22';
wwv_flow_imp.g_varchar2_table(37) := '4E6F20736520707565646520616E657861722050444673206120756E2050444620636F6E20636F6E7472617365C3B1612E222C7069636B4C6973743A22456C696A6120756E2076616C6F72206465206C61206C697374612E222C6D61784C656E3A224DC3';
wwv_flow_imp.g_varchar2_table(38) := 'A178696D6F207B307D20636172616374657265732E222C786C506167653A2250C3A167696E6120265020646520264E222C776F72644669656C64733A22576F72643A206E6F207365207075646965726F6E20636F6C6F63617220746F646F73206C6F7320';
wwv_flow_imp.g_varchar2_table(39) := '63616D706F732064656C20666F726D756C6172696F20287B307D206465207B317D292E222C74706C55726C3A27446566696E61206C612055524C206465206C6120706C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C61';
wwv_flow_imp.g_varchar2_table(40) := '20576F726422292E272C74706C446C3A224E6F207365207075646F20646573636172676172206C6120706C616E74696C6C6120287B307D29222C67656E65726174696E673A2247656E6572616E646F207265706F727465222C7265616446696C653A224E';
wwv_flow_imp.g_varchar2_table(41) := '6F207365207075646F206C65657220656C206172636869766F2067656E657261646F2E222C736176654572723A224E6F207365207075646F206775617264617220656E20656C207365727669646F723A207B307D222C6E6F7453617665643A22456C2073';
wwv_flow_imp.g_varchar2_table(42) := '65727669646F72206E6F206775617264C3B320656C20646F63756D656E746F2E222C666D744261643A22466F726D61746F206E6F20736F706F727461646F3A207B307D222C6E6F446174613A224E6F20686179206461746F7320706172612067656E6572';
wwv_flow_imp.g_varchar2_table(43) := '617220656C207265706F7274652E222C62617463684D61783A22456C206C6F74652073757065726120656C206DC3A178696D6F206465207B307D20646F63756D656E746F732E222C6C61796F75744E463A224E6F20736520656E636F6E7472C3B320656C';
wwv_flow_imp.g_varchar2_table(44) := '2064697365C3B16F3A207B307D222C7175657279696E673A22436F6E73756C74616E646F206461746F73E280A6222C6C61796F75744261643A2244697365C3B16F20696E76C3A16C69646F3A207B307D222C7265706F72745265713A22496E6469717565';
wwv_flow_imp.g_varchar2_table(45) := '20656C207265706F72746520612067656E657261722028646174612D7265706F7274292E222C646174614572723A224572726F7220616C206F6274656E6572206C6F73206461746F732E222C636F6D6D4572723A224572726F7220646520636F6D756E69';
wwv_flow_imp.g_varchar2_table(46) := '63616369C3B36E3A207B307D222C6C61796F75744D697373696E673A2246616C746120656C2064697365C3B16F3A206C6120636F6E73756C74612064656C207265706F727465206E6F206465766F6C7669C3B3204C41594F5554207920656C2061747269';
wwv_flow_imp.g_varchar2_table(47) := '6275746F2044697365C3B16F20657374C3A120766163C3AD6F2E222C6275696C64696E673A2241726D616E646F20656C20646F63756D656E746FE280A6222C7A697070696E673A22436F6D7072696D69656E646F207B307D206172636869766F73E280A6';
wwv_flow_imp.g_varchar2_table(48) := '222C67656E4E3A2247656E6572616E646F207B307D206465207B317DE280A6222C6E656564417065783A224775617264617220656E20656C207365727669646F7220726571756965726520415045582E222C736176696E673A224775617264616E646F20';
wwv_flow_imp.g_varchar2_table(49) := '656E20656C207365727669646F72E280A6222C73617665643A22446F63756D656E746F20677561726461646F3A207B307D222C7A6970446F6E653A225A49502067656E657261646F3A207B307D206172636869766F73206465207B317D20646F63756D65';
wwv_flow_imp.g_varchar2_table(50) := '6E746F732E222C6661696C65643A224E6F207365207075646F2067656E6572617220656C207265706F7274652E222C66696C654E616D653A227265706F727465222C7A69704E616D653A227265706F727465732E7A6970222C73686565743A225265706F';
wwv_flow_imp.g_varchar2_table(51) := '727465222C73686565744E3A22486F6A61222C66696C653A226172636869766F222C6D6F6E7468733A22656E652C6665622C6D61722C6162722C6D61792C6A756E2C6A756C2C61676F2C7365702C6F63742C6E6F762C646963227D2C656E3A7B6C69624C';
wwv_flow_imp.g_varchar2_table(52) := '6F61643A22436F756C64206E6F74206C6F6164206C6962726172793A207B307D222C7965733A22596573222C6E6F3A224E6F222C696D674261643A226E6F76615265706F72743A20696E76616C696420696D61676520696E207B307D222C616767417667';
wwv_flow_imp.g_varchar2_table(53) := '3A224176672E222C6167674D696E3A224D696E2E222C6167674D61783A224D61782E222C616767436F756E743A22436F756E74222C746F74616C733A22546F74616C73222C746F74616C3A22546F74616C222C737562746F74616C3A22537562746F7461';
wwv_flow_imp.g_varchar2_table(54) := '6C222C63617272793A224361727269656420666F7277617264222C636172727946726F6D3A2242726F7567687420666F7277617264222C6669656C644261643A27496E76616C6964206669656C64206E616D653A20227B307D222E20557365206C657474';
wwv_flow_imp.g_varchar2_table(55) := '6572732C206E756D6265727320616E64205F2028757020746F2034302C206E6F20737061636573206F7220646F74732920616E642061766F6964206E616D65732074686174206C6F6F6B206C696B6520616E20457863656C2063656C6C202841312C2052';
wwv_flow_imp.g_varchar2_table(56) := '314331292E272C6669656C644475703A274475706C6963617465206669656C64206E616D6520696E2074686520646F63756D656E743A20227B307D222E272C6669656C64547970653A27556E737570706F72746564206669656C6420747970653A20227B';
wwv_flow_imp.g_varchar2_table(57) := '307D222028746578742C206D756C74696C696E652C206C6973742C20636865636B626F78292E272C6C697374456D7074793A274669656C6420227B307D222069732061206C6973742077697468206E6F206F7074696F6E7320286F7074696F6E73206F72';
wwv_flow_imp.g_varchar2_table(58) := '206F7074696F6E7346726F6D292E272C776F726450773A2254686520576F72642070726F74656374696F6E2070617373776F7264206D757374206265203120746F203135204153434949206368617261637465727320286E6F20616363656E746564206C';
wwv_flow_imp.g_varchar2_table(59) := '657474657273292E222C7064664C6F61643A22436F756C64206E6F74206C6F616420504446207B307D20287B317D29222C706466417070656E643A22436F756C64206E6F7420617070656E6420746865205044463A207B307D222C696D674C6F61643A22';
wwv_flow_imp.g_varchar2_table(60) := '436F756C64206E6F74206C6F616420696D616765207B307D20287B317D29222C696D67466D743A22556E737570706F7274656420696D61676520666F726D6174202875736520504E47206F72204A5047292E222C63616E7661733A22412062726F777365';
wwv_flow_imp.g_varchar2_table(61) := '72202863616E7661732920697320726571756972656420746F2072656E646572206368617274732E222C71724C69623A2254686520515220636F6465206C69627261727920776173206E6F74206C6F616465642E222C636F64654B696E643A22556E7375';
wwv_flow_imp.g_varchar2_table(62) := '70706F7274656420636F646520747970653A207B307D2028757365207172206F7220636F6465313238292E222C63686172744C69623A22546865206368617274206C696272617279202843686172742E6A732920776173206E6F74206C6F616465642E22';
wwv_flow_imp.g_varchar2_table(63) := '2C617070656E6450773A22504446732063616E6E6F7420626520617070656E64656420746F20612070617373776F72642D70726F746563746564205044462E222C7069636B4C6973743A2243686F6F736520612076616C75652066726F6D20746865206C';
wwv_flow_imp.g_varchar2_table(64) := '6973742E222C6D61784C656E3A224D6178696D756D207B307D20636861726163746572732E222C786C506167653A2250616765202650206F6620264E222C776F72644669656C64733A22576F72643A206E6F7420616C6C20666F726D206669656C647320';
wwv_flow_imp.g_varchar2_table(65) := '636F756C6420626520706C6163656420287B307D206F66207B317D292E222C74706C55726C3A275365742074686520576F72642074656D706C6174652055524C202822576F72642054656D706C6174652220617474726962757465292E272C74706C446C';
wwv_flow_imp.g_varchar2_table(66) := '3A22436F756C64206E6F7420646F776E6C6F6164207468652074656D706C61746520287B307D29222C67656E65726174696E673A2247656E65726174696E67207265706F7274222C7265616446696C653A22436F756C64206E6F74207265616420746865';
wwv_flow_imp.g_varchar2_table(67) := '2067656E6572617465642066696C652E222C736176654572723A22436F756C64206E6F742073617665206F6E20746865207365727665723A207B307D222C6E6F7453617665643A225468652073657276657220646964206E6F7420736176652074686520';
wwv_flow_imp.g_varchar2_table(68) := '646F63756D656E742E222C666D744261643A22556E737570706F7274656420666F726D61743A207B307D222C6E6F446174613A225468657265206973206E6F206461746120746F2067656E657261746520746865207265706F72742E222C62617463684D';
wwv_flow_imp.g_varchar2_table(69) := '61783A22546865206261746368206578636565647320746865206D6178696D756D206F66207B307D20646F63756D656E74732E222C6C61796F75744E463A224C61796F7574206E6F7420666F756E643A207B307D222C7175657279696E673A2246657463';
wwv_flow_imp.g_varchar2_table(70) := '68696E672064617461E280A6222C6C61796F75744261643A22496E76616C6964206C61796F75743A207B307D222C7265706F72745265713A225370656369667920746865207265706F727420746F2067656E65726174652028646174612D7265706F7274';
wwv_flow_imp.g_varchar2_table(71) := '292E222C646174614572723A224572726F72206665746368696E672074686520646174612E222C636F6D6D4572723A22436F6D6D756E69636174696F6E206572726F723A207B307D222C6C61796F75744D697373696E673A224D697373696E67206C6179';
wwv_flow_imp.g_varchar2_table(72) := '6F75743A20746865207265706F72742071756572792072657475726E6564206E6F204C41594F555420616E6420746865204C61796F75742061747472696275746520697320656D7074792E222C6275696C64696E673A224275696C64696E672074686520';
wwv_flow_imp.g_varchar2_table(73) := '646F63756D656E74E280A6222C7A697070696E673A22436F6D7072657373696E67207B307D2066696C6573E280A6222C67656E4E3A2247656E65726174696E67207B307D206F66207B317DE280A6222C6E656564417065783A22536176696E67206F6E20';
wwv_flow_imp.g_varchar2_table(74) := '7468652073657276657220726571756972657320415045582E222C736176696E673A22536176696E67206F6E2074686520736572766572E280A6222C73617665643A22446F63756D656E742073617665643A207B307D222C7A6970446F6E653A225A4950';
wwv_flow_imp.g_varchar2_table(75) := '2067656E6572617465643A207B307D2066696C65732066726F6D207B317D20646F63756D656E74732E222C6661696C65643A22546865207265706F727420636F756C64206E6F742062652067656E6572617465642E222C66696C654E616D653A22726570';
wwv_flow_imp.g_varchar2_table(76) := '6F7274222C7A69704E616D653A227265706F7274732E7A6970222C73686565743A225265706F7274222C73686565744E3A225368656574222C66696C653A2266696C65222C6D6F6E7468733A224A616E2C4665622C4D61722C4170722C4D61792C4A756E';
wwv_flow_imp.g_varchar2_table(77) := '2C4A756C2C4175672C5365702C4F63742C4E6F762C446563227D7D3B66756E6374696F6E20612865297B76617220743D286F5B6E5D7C7C6F2E656E295B655D2C723D617267756D656E74733B72657475726E20766F696420303D3D3D74262628743D6F2E';
wwv_flow_imp.g_varchar2_table(78) := '656E5B655D292C537472696E672874292E7265706C616365282F5C7B285C64295C7D2F672C66756E6374696F6E28652C74297B766172206E3D725B2B742B315D3B72657475726E206E756C6C3D3D6E3F22223A537472696E67286E297D297D66756E6374';
wwv_flow_imp.g_varchar2_table(79) := '696F6E206C2865297B72657475726E20653D537472696E6728657C7C2222292E746F4C6F7765724361736528292C2F5E65732F2E746573742865293F226573223A2F5E656E2F2E746573742865293F22656E223A6E756C6C7D66756E6374696F6E206928';
wwv_flow_imp.g_varchar2_table(80) := '297B76617220653D22223B7472797B77696E646F772E617065782626617065782E6C6F63616C652626617065782E6C6F63616C652E6765744C616E6775616765262628653D617065782E6C6F63616C652E6765744C616E677561676528297C7C2222297D';
wwv_flow_imp.g_varchar2_table(81) := '63617463682865297B7D7472797B2165262622756E646566696E656422213D747970656F6620646F63756D656E742626646F63756D656E742E646F63756D656E74456C656D656E74262628653D646F63756D656E742E646F63756D656E74456C656D656E';
wwv_flow_imp.g_varchar2_table(82) := '742E6C616E677C7C2222297D63617463682865297B7D72657475726E2F5E65732F692E7465737428537472696E67286529293F226573223A22656E227D76617220733D7B6465633A222E222C6772703A222C222C646174653A6E756C6C2C786C3A226464';
wwv_flow_imp.g_varchar2_table(83) := '2F6D6D2F79797979227D3B66756E6374696F6E207528652C74297B6E3D6C28652626652E6C616E67297C7C6C28742626742E6C616E67297C7C6928293B76617220722C6F3D65262628652E6C6F63616C657C7C652E706167652626652E706167652E6C6F';
wwv_flow_imp.g_varchar2_table(84) := '63616C65292C613D222E222C753D222C222C633D6E756C6C3B69662822737472696E67223D3D747970656F66206F26266F262622756E646566696E656422213D747970656F6620496E746C297472797B6E657720496E746C2E4E756D626572466F726D61';
wwv_flow_imp.g_varchar2_table(85) := '74286F292E666F726D6174546F506172747328313233343536372E35292E666F72456163682866756E6374696F6E2865297B22646563696D616C223D3D3D652E747970653F613D652E76616C75653A2267726F7570223D3D3D652E74797065262628753D';
wwv_flow_imp.g_varchar2_table(86) := '2F5C732F2E7465737428652E76616C7565293F2220223A652E76616C7565297D292C633D6E657720496E746C2E4461746554696D65466F726D6174286F2C7B6461793A22322D6469676974222C6D6F6E74683A22322D6469676974222C796561723A226E';
wwv_flow_imp.g_varchar2_table(87) := '756D65726963222C74696D655A6F6E653A22555443227D292E666F726D6174546F5061727473286E6577204461746528446174652E55544328323030312C31302C32322929292E6D61702866756E6374696F6E2865297B72657475726E22646179223D3D';
wwv_flow_imp.g_varchar2_table(88) := '3D652E747970653F226464223A226D6F6E7468223D3D3D652E747970653F226D6D223A2279656172223D3D3D652E747970653F2279797979223A226C69746572616C223D3D3D652E747970653F652E76616C75653A22227D292E6A6F696E282222297D63';
wwv_flow_imp.g_varchar2_table(89) := '617463682865297B613D222E222C753D222C222C633D6E756C6C7D656C7365206F2626226F626A656374223D3D747970656F66206F2626286F2E646563696D616C262628613D537472696E67286F2E646563696D616C292E636861724174283029292C76';
wwv_flow_imp.g_varchar2_table(90) := '6F69642030213D3D6F2E74686F7573616E647326266E756C6C213D3D6F2E74686F7573616E64733F753D537472696E67286F2E74686F7573616E6473292E6368617241742830293A222C223D3D3D61262628753D222E22292C6F2E64617465262628633D';
wwv_flow_imp.g_varchar2_table(91) := '537472696E67286F2E646174652929293B632626212F64642F692E74657374286329262628633D6E756C6C292C723D633F632E7265706C616365282F797979797C79797C6D6D6D7C6D6F6E7C6D6D7C64642F67692C66756E6374696F6E2865297B726574';
wwv_flow_imp.g_varchar2_table(92) := '75726E226D6F6E223D3D3D28653D652E746F4C6F776572436173652829293F226D6D6D223A657D293A2264642F6D6D2F79797979222C733D7B6465633A612C6772703A752C646174653A6326262264642F6D6D2F7979797922213D3D632E746F4C6F7765';
wwv_flow_imp.g_varchar2_table(93) := '724361736528293F633A6E756C6C2C786C3A727D7D66756E6374696F6E20632865297B72657475726E222E223D3D3D732E6465632626222C223D3D3D732E6772703F653A537472696E672865292E7265706C616365282F5B2C2E5D2F672C66756E637469';
wwv_flow_imp.g_varchar2_table(94) := '6F6E2865297B72657475726E222C223D3D3D653F732E6772703A732E6465637D297D66756E6374696F6E20662865297B69662821732E646174652972657475726E20653B76617220743D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D';
wwv_flow_imp.g_varchar2_table(95) := '29242F2E6578656328537472696E67286529293B72657475726E20743F732E646174652E7265706C616365282F797979797C79797C6D6D6D7C6D6F6E7C6D6D7C64642F67692C66756E6374696F6E2865297B72657475726E2279797979223D3D3D28653D';
wwv_flow_imp.g_varchar2_table(96) := '652E746F4C6F776572436173652829293F745B335D3A227979223D3D3D653F745B335D2E7375627374722832293A226464223D3D3D653F745B315D3A226D6D223D3D3D653F745B325D3A6128226D6F6E74687322292E73706C697428222C22295B2B745B';
wwv_flow_imp.g_varchar2_table(97) := '325D2D315D7D293A657D76617220643D7B7072696D6172793A2223314634453739222C68656164546578743A2223464646464646222C7A656272613A2223463546374641222C746F74616C733A2223453645434632222C746578743A2223303030303030';
wwv_flow_imp.g_varchar2_table(98) := '222C6D757465643A2223373837383738222C666F6E7453697A653A372C67726F75703A2223444345364630222C6C696E6B3A2223303536334331227D3B66756E6374696F6E20682865297B72657475726E226E756D626572223D3D747970656F66206526';
wwv_flow_imp.g_varchar2_table(99) := '262169734E614E2865297D66756E6374696F6E20702865297B72657475726E20333D3D3D28653D537472696E6728657C7C222330303030303022292E7265706C616365282223222C222229292E6C656E677468262628653D652E7265706C616365282F28';
wwv_flow_imp.g_varchar2_table(100) := '2E292F672C22243124312229292C5B7061727365496E7428652E73756273747228302C32292C3136292C7061727365496E7428652E73756273747228322C32292C3136292C7061727365496E7428652E73756273747228342C32292C3136295D7D66756E';
wwv_flow_imp.g_varchar2_table(101) := '6374696F6E20672865297B72657475726E224646222B537472696E6728657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E6374696F6E206D2865297B72657475726E20537472696E67';
wwv_flow_imp.g_varchar2_table(102) := '28657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E6374696F6E20762865297B72657475726E28653C31303F2230223A2222292B657D66756E6374696F6E206228297B76617220653D';
wwv_flow_imp.g_varchar2_table(103) := '6E657720446174653B72657475726E2066287628652E676574446174652829292B222F222B7628652E6765744D6F6E746828292B31292B222F222B652E67657446756C6C596561722829292B2220222B7628652E676574486F7572732829292B223A222B';
wwv_flow_imp.g_varchar2_table(104) := '7628652E6765744D696E757465732829297D66756E6374696F6E207728297B76617220653D6228293B72657475726E20652E73756273747228302C652E6C617374496E6465784F662822202229297D66756E6374696F6E20792865297B76617220743D53';
wwv_flow_imp.g_varchar2_table(105) := '7472696E672865292E746F4C6F7765724361736528292E7265706C616365282F5F2F672C222022293B72657475726E20742E6368617241742830292E746F55707065724361736528292B742E736C6963652831297D66756E6374696F6E20782865297B76';
wwv_flow_imp.g_varchar2_table(106) := '617220743D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D29242F2E6578656328537472696E6728657C7C222229293B72657475726E20743F6E6577204461746528446174652E555443282B745B335D2C2B745B325D2D312C2B745B31';
wwv_flow_imp.g_varchar2_table(107) := '5D29293A6E756C6C7D66756E6374696F6E20452865297B72657475726E20537472696E6728657C7C61282266696C652229292E7265706C616365282F5B5C5C5C2F3A2A3F223C3E7C5D2B2F672C225F22292E7472696D28297D66756E6374696F6E205328';
wwv_flow_imp.g_varchar2_table(108) := '652C74297B6966286E756C6C3D3D657C7C22223D3D3D652972657475726E22223B69662821742972657475726E20732E646174653F6628537472696E67286529293A537472696E672865293B6966284D2874292972657475726E2066756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(109) := '652C74297B76617220723D4E756D6265722865293B6966286E756C6C3D3D657C7C22223D3D3D657C7C69734E614E2872292972657475726E206E756C6C3D3D653F22223A537472696E672865293B766172206E3D502874292C6F3D6E5B305D2C613D2131';
wwv_flow_imp.g_varchar2_table(110) := '3B723C3026266E2E6C656E6774683E3126266E5B315D2E746F6B732E6C656E6774683F286F3D6E5B315D2C723D2D72293A723C30262628613D21302C723D2D72293B303D3D3D7226266E2E6C656E6774683E322626286F3D6E5B325D2C613D2131293B6F';
wwv_flow_imp.g_varchar2_table(111) := '2E706374262628722A3D313030293B722F3D6F2E7363616C653B766172206C3D4E756D62657228722E746F4669786564286F2E6D617844656329293B303D3D3D6C262628613D2131293B76617220693D6C2E746F4C6F63616C65537472696E672822656E';
wwv_flow_imp.g_varchar2_table(112) := '2D5553222C7B75736547726F7570696E673A6F2E67726F75702C6D696E696D756D496E74656765724469676974733A4D6174682E6D617828312C4D6174682E6D696E2832312C6F2E6D696E496E7429292C6D696E696D756D4672616374696F6E44696769';
wwv_flow_imp.g_varchar2_table(113) := '74733A6F2E6D696E4465632C6D6178696D756D4672616374696F6E4469676974733A6F2E6D61784465637D293B216F2E6D696E496E7426262F5E30285C2E7C24292F2E74657374286929262628693D692E736C696365283129293B222E223D3D3D6F2E64';
wwv_flow_imp.g_varchar2_table(114) := '65632626222C223D3D3D6F2E6772707C7C28693D692E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E2865297B72657475726E222E223D3D3D653F6F2E6465633A6F2E6772707D29293B76617220733D6F2E746F6B732E6D61702866756E63';
wwv_flow_imp.g_varchar2_table(115) := '74696F6E2865297B72657475726E226E223D3D3D652E743F693A2278223D3D3D652E743F22223A652E767D292E6A6F696E282222293B72657475726E20613F222D222B733A737D28652C74293B76617220723D742E73706C697428223A22292C6E3D725B';
wwv_flow_imp.g_varchar2_table(116) := '305D3B696628226D6F6E6579223D3D3D6E7C7C226E756D223D3D3D6E297B766172206F3D766F69642030213D3D725B315D3F2B725B315D3A322C6C3D4E756D6265722865293B72657475726E2069734E614E286C293F537472696E672865293A63286C2E';
wwv_flow_imp.g_varchar2_table(117) := '746F4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A6F2C6D6178696D756D4672616374696F6E4469676974733A6F7D29297D72657475726E22696E74223D3D3D6E3F69734E614E284E756D';
wwv_flow_imp.g_varchar2_table(118) := '626572286529293F537472696E672865293A63284D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D55532229293A2264617465223D3D3D6E3F6628537472696E67286529293A22706374223D3D3D6E';
wwv_flow_imp.g_varchar2_table(119) := '3F5328652C226E756D3A222B28725B315D7C7C3229292B2225223A227570706572223D3D3D6E3F537472696E672865292E746F55707065724361736528293A226C6F776572223D3D3D6E3F537472696E672865292E746F4C6F7765724361736528293A22';
wwv_flow_imp.g_varchar2_table(120) := '796E223D3D3D6E3F2259223D3D3D657C7C2253223D3D3D653F61282279657322293A224E223D3D3D653F6128226E6F22293A537472696E672865293A226C6574726173223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A';
wwv_flow_imp.g_varchar2_table(121) := '66756E6374696F6E28652C74297B76617220723D653C302C6E3D4D6174682E726F756E64283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C613D6E253130302C6C3D6A286F293B69662874297B2F284D494C';
wwv_flow_imp.g_varchar2_table(122) := '4CC3934E7C4D494C4C4F4E45537C42494C4CC3934E7C42494C4C4F4E455329242F2E74657374286C292626286C2B3D2220444522293B76617220693D537472696E672874292E746F55707065724361736528292E73706C697428222F22293B6C2B3D2220';
wwv_flow_imp.g_varchar2_table(123) := '222B28313D3D3D6F2626692E6C656E6774683E313F695B305D3A695B692E6C656E6774682D315D297D656C7365206C3D6C2E7265706C616365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(124) := '2865297B72657475726E20652B224F227D293B72657475726E28723F224D454E4F5320223A2222292B6C2B2220434F4E20222B28613C31303F2230223A2222292B612B222F313030227D284E756D6265722865292C722E736C6963652831292E6A6F696E';
wwv_flow_imp.g_varchar2_table(125) := '28223A2229293A22776F726473223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A42284E756D6265722865292C722E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E6374696F6E2054';
wwv_flow_imp.g_varchar2_table(126) := '2865297B72657475726E2F5E2875707065727C6C6F7765727C796E7C6C65747261737C776F72647329283A7C24292F2E7465737428657C7C2222297D76617220433D7B7D3B66756E6374696F6E20412865297B666F722876617220743D5B5D2C723D2222';
wwv_flow_imp.g_varchar2_table(127) := '2C6E3D21312C6F3D303B6F3C652E6C656E6774683B6F2B2B297B76617220613D652E636861724174286F293B225C5C22213D3D617C7C6E3F282722273D3D3D612626286E3D216E292C223B22213D3D617C7C6E3F722B3D613A28742E707573682872292C';
wwv_flow_imp.g_varchar2_table(128) := '723D222229293A28722B3D612B28652E636861724174286F2B31297C7C2222292C6F2B2B297D72657475726E20742E707573682872292C747D66756E6374696F6E204E2865297B76617220742C722C6E3D5B5D2C6F3D6E756C6C2C613D21312C6C3D2222';
wwv_flow_imp.g_varchar2_table(129) := '2C693D21312C733D66756E6374696F6E28297B6C2626286E2E70757368287B743A226C222C763A6C7D292C6C3D2222297D3B666F7228743D303B743C652E6C656E6774683B742B2B29696628272227213D3D28723D652E63686172417428742929296966';
wwv_flow_imp.g_varchar2_table(130) := '28225C5C22213D3D72297B696628225B223D3D3D72297B76617220753D652E696E6465784F6628225D222C74293B696628753E30297B7328292C6E2E70757368287B743A2278222C763A652E736C69636528742C752B31297D292C743D753B636F6E7469';
wwv_flow_imp.g_varchar2_table(131) := '6E75657D7D225F22213D3D723F222A22213D3D723F216126262F5B23303F2C2E5D2F2E746573742872292626286E756C6C213D3D6F7C7C2F5B23303F5D2F2E746573742872297C7C222E223D3D3D7226262F5B23303F5D2F2E7465737428652E63686172';
wwv_flow_imp.g_varchar2_table(132) := '417428742B312929293F286E756C6C3D3D3D6F2626287328292C6F3D22222C6E2E70757368287B743A226E227D29292C6F2B3D72293A286E756C6C213D3D6F262628613D2130292C2225223D3D3D72262628693D2130292C6C2B3D72293A742B2B3A286C';
wwv_flow_imp.g_varchar2_table(133) := '2B3D2220222C742B2B297D656C7365206C2B3D652E63686172417428742B31292C742B2B3B656C73657B76617220633D652E696E6465784F66282722272C742B31293B633C30262628633D652E6C656E677468292C6C2B3D652E736C69636528742B312C';
wwv_flow_imp.g_varchar2_table(134) := '63292C743D637D7328293B76617220663D286F3D6F7C7C2222292E6C617374496E6465784F6628222C22292C643D21313B663E3D3026262F5E5B23303F5D2B242F2E74657374286F2E736C69636528662B312929262628643D6F2E696E6465784F662822';
wwv_flow_imp.g_varchar2_table(135) := '2E22293E3D303F6F2E6C617374496E6465784F6628222E22293C663A6F2E6C656E6774682D662D31213D33292C642626286F3D6F2E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E2865297B72657475726E222E223D3D3D653F222C223A22';
wwv_flow_imp.g_varchar2_table(136) := '2E227D29293B76617220683D282F2C2B242F2E65786563286F297C7C5B22225D295B305D2E6C656E6774682C703D6F2E736C69636528302C6F2E6C656E6774682D68292C673D702E696E6465784F6628222E22292C6D3D673C303F703A702E736C696365';
wwv_flow_imp.g_varchar2_table(137) := '28302C67292C763D673C303F22223A702E736C69636528672B31292C623D282F2C2B242F2E65786563286D297C7C5B22225D295B305D2E6C656E6774682B683B72657475726E206D3D6D2E736C69636528302C6D2E6C656E6774682D62292C7B746F6B73';
wwv_flow_imp.g_varchar2_table(138) := '3A6E2C7261773A6F2C6861734E756D3A21216F2C7063743A692C7363616C653A4D6174682E706F77283165332C62292C67726F75703A6D2E696E6465784F6628222C22293E3D302C6D696E496E743A286D2E6D61746368282F302F67297C7C5B5D292E6C';
wwv_flow_imp.g_varchar2_table(139) := '656E6774682C6D61784465633A28762E6D61746368282F5B23303F5D2F67297C7C5B5D292E6C656E6774682C6D696E4465633A28762E6D61746368282F302F67297C7C5B5D292E6C656E6774682C6465633A643F222C223A222E222C6772703A643F222E';
wwv_flow_imp.g_varchar2_table(140) := '223A222C227D7D66756E6374696F6E20502865297B696628653D537472696E672865292C21435B655D296966282F5E6F72613A2F2E74657374286529297B76617220743D66756E6374696F6E2865297B76617220742C722C6E3D5B5D2C6F3D22222C613D';
wwv_flow_imp.g_varchar2_table(141) := '22223B666F7228743D303B743C652E6C656E6774683B742B2B29723D652E6368617241742874292C613F723D3D3D613F613D22223A6F2B3D723A222722213D3D722626272227213D3D723F223B22213D3D723F6F2B3D723A286E2E70757368286F292C6F';
wwv_flow_imp.g_varchar2_table(142) := '3D2222293A613D723B6E2E70757368286F293B766172206C3D6E2E736869667428292E7472696D28292E746F55707065724361736528292C693D2F5E464D2F2E74657374286C292C733D7B6E6C733A222E2C222C6375723A2224222C69736F3A22555344';
wwv_flow_imp.g_varchar2_table(143) := '227D3B6E2E666F72456163682866756E6374696F6E2865297B76617220743D652E696E6465784F6628223D22293B743E30262628735B652E736C69636528302C74292E7472696D28292E746F4C6F7765724361736528295D3D652E736C69636528742B31';
wwv_flow_imp.g_varchar2_table(144) := '29297D292C6C3D6C2E7265706C616365282F5E464D2F2C2222293B76617220753D2F5052242F2E74657374286C292C633D217526262F4D49242F2E74657374286C293B28757C7C63292626286C3D6C2E736C69636528302C2D3229293B76617220663D2F';
wwv_flow_imp.g_varchar2_table(145) := '5E532F2E74657374286C292C643D2166262621752626216326262F53242F2E74657374286C293B663F6C3D6C2E736C6963652831293A642626286C3D6C2E736C69636528302C2D3129293B76617220683D6C2E696E6465784F6628224222293E3D302C70';
wwv_flow_imp.g_varchar2_table(146) := '3D22222C673D22222C6D3D22222C763D22222C623D21312C773D21313B666F72286C3D6C2E7265706C616365282F422F672C2222292C743D303B743C6C2E6C656E6774683B742B2B296966282239223D3D3D28723D6C2E636861724174287429297C7C22';
wwv_flow_imp.g_varchar2_table(147) := '30223D3D3D7229773D21302C623F762B3D2239223D3D3D722626693F2223223A2230223A6D2B3D723B656C7365206966282247223D3D3D727C7C222C223D3D3D7229627C7C286D2B3D222C22293B656C7365206966282244223D3D3D727C7C222E223D3D';
wwv_flow_imp.g_varchar2_table(148) := '3D7229623D21303B656C736520696628224C223D3D3D727C7C2255223D3D3D727C7C2243223D3D3D727C7C2224223D3D3D72297B76617220793D2243223D3D3D723F732E69736F3A2224223D3D3D723F2224223A732E6375723B773F672B3D793A702B3D';
wwv_flow_imp.g_varchar2_table(149) := '797D76617220783D6D2E696E6465784F6628223022292C453D286D3D6D2E7265706C616365282F5B39305D2F672C66756E6374696F6E28652C74297B72657475726E20783E3D302626743E3D783F2230223A2223227D292E7265706C616365282F5E2C2B';
wwv_flow_imp.g_varchar2_table(150) := '2F2C222229292B28763F222E222B763A2222297C7C2223222C533D66756E6374696F6E2865297B72657475726E20653F2722272B537472696E672865292E7265706C616365282F222F672C2222292B2722273A22227D2C543D532870292B452B53286729';
wwv_flow_imp.g_varchar2_table(151) := '2C433D543B753F433D542B223B222B5328223C222B70292B452B5328672B223E22293A633F433D542B223B222B532870292B452B5328672B222D22293A663F433D5328222B222B70292B452B532867292B223B222B5328222D222B70292B452B53286729';
wwv_flow_imp.g_varchar2_table(152) := '3A64262628433D532870292B452B5328672B222B22292B223B222B532870292B452B5328672B222D2229292C68262628433D3D3D54262628432B3D223B222B5328222D222B70292B452B53286729292C432B3D273B222227293B76617220413D53747269';
wwv_flow_imp.g_varchar2_table(153) := '6E6728732E6E6C737C7C222E2C22293B72657475726E7B7372633A432C6465633A412E6368617241742830297C7C222E222C6772703A412E6368617241742831297C7C222C227D7D28652E736C696365283429293B435B655D3D4128742E737263292E6D';
wwv_flow_imp.g_varchar2_table(154) := '61702866756E6374696F6E2865297B76617220723D4E2865293B72657475726E20722E6465633D742E6465632C722E6772703D742E6772702C727D297D656C736520435B655D3D412866756E6374696F6E2865297B72657475726E20653D537472696E67';
wwv_flow_imp.g_varchar2_table(155) := '2865292C2F5E6D61736B3A2F2E746573742865293F652E736C6963652835293A657D286529292E6D6170284E293B72657475726E20435B655D7D66756E6374696F6E20462865297B72657475726E20502865292E6D61702866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(156) := '72657475726E20652E746F6B732E6D61702866756E6374696F6E2874297B72657475726E226E223D3D3D742E743F652E7261773A2278223D3D3D742E743F742E763A742E762E73706C697428222522292E6D61702866756E6374696F6E2865297B726574';
wwv_flow_imp.g_varchar2_table(157) := '75726E20653F2722272B652E7265706C616365282F222F672C2222292B2722273A22227D292E6A6F696E28222522297D292E6A6F696E282222297C7C272222277D292E6A6F696E28223B22297D766172207A3D2F5E286D6F6E65797C6E756D7C696E747C';
wwv_flow_imp.g_varchar2_table(158) := '7063747C646174657C75707065727C6C6F7765727C796E7C6C65747261737C776F72647329283A7C24292F3B66756E6374696F6E204D2865297B72657475726E2F5E286D61736B7C6F7261293A2F2E7465737428653D657C7C2222297C7C217A2E746573';
wwv_flow_imp.g_varchar2_table(159) := '7428652926262F5B23305D2F2E746573742865297D766172206B3D5B22222C22554E222C22444F53222C2254524553222C2243554154524F222C2243494E434F222C2253454953222C225349455445222C224F43484F222C224E55455645222C22444945';
wwv_flow_imp.g_varchar2_table(160) := '5A222C224F4E4345222C22444F4345222C225452454345222C224341544F524345222C225155494E4345222C22444945434953C3894953222C2244494543495349455445222C2244494543494F43484F222C2244494543494E55455645222C225645494E';
wwv_flow_imp.g_varchar2_table(161) := '5445222C225645494E5449C39A4E222C225645494E544944C39353222C225645494E54495452C38953222C225645494E544943554154524F222C225645494E544943494E434F222C225645494E544953C3894953222C225645494E54495349455445222C';
wwv_flow_imp.g_varchar2_table(162) := '225645494E54494F43484F222C225645494E54494E55455645225D2C4F3D5B22222C22222C22222C22545245494E5441222C2243554152454E5441222C2243494E4355454E5441222C22534553454E5441222C22534554454E5441222C224F4348454E54';
wwv_flow_imp.g_varchar2_table(163) := '41222C224E4F56454E5441225D2C4C3D5B22222C224349454E544F222C22444F534349454E544F53222C22545245534349454E544F53222C2243554154524F4349454E544F53222C225155494E49454E544F53222C22534549534349454E544F53222C22';
wwv_flow_imp.g_varchar2_table(164) := '534554454349454E544F53222C224F43484F4349454E544F53222C224E4F56454349454E544F53225D3B66756E6374696F6E20442865297B6966283130303D3D3D652972657475726E224349454E223B76617220743D4D6174682E666C6F6F7228652F31';
wwv_flow_imp.g_varchar2_table(165) := '3030292C723D65253130302C6E3D5B5D3B72657475726E207426266E2E70757368284C5B745D292C7226266E2E7075736828723C33303F6B5B725D3A4F5B4D6174682E666C6F6F7228722F3130295D2B28722531303F22205920222B6B5B722531305D3A';
wwv_flow_imp.g_varchar2_table(166) := '222229292C6E2E6A6F696E28222022297D66756E6374696F6E206A2865297B696628303D3D3D652972657475726E224345524F223B76617220743D5B5D3B5B5B316531322C2242494C4CC3934E222C2242494C4C4F4E4553225D2C5B3165362C224D494C';
wwv_flow_imp.g_varchar2_table(167) := '4CC3934E222C224D494C4C4F4E4553225D5D2E666F72456163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E7075736828313D3D3D6E3F22554E20222B725B315D3A6A286E292B222022';
wwv_flow_imp.g_varchar2_table(168) := '2B725B325D292C652D3D6E2A725B305D297D293B76617220723D4D6174682E666C6F6F7228652F316533292C6E3D65253165333B72657475726E20722626742E7075736828313D3D3D723F224D494C223A442872292B22204D494C22292C6E2626742E70';
wwv_flow_imp.g_varchar2_table(169) := '7573682844286E29292C742E6A6F696E28222022297D76617220493D5B22222C224F4E45222C2254574F222C225448524545222C22464F5552222C2246495645222C22534958222C22534556454E222C224549474854222C224E494E45222C2254454E22';
wwv_flow_imp.g_varchar2_table(170) := '2C22454C4556454E222C225457454C5645222C22544849525445454E222C22464F55525445454E222C224649465445454E222C225349585445454E222C22534556454E5445454E222C22454947485445454E222C224E494E455445454E225D2C523D5B22';
wwv_flow_imp.g_varchar2_table(171) := '222C22222C225457454E5459222C22544849525459222C22464F525459222C224649465459222C225349585459222C22534556454E5459222C22454947485459222C224E494E455459225D3B66756E6374696F6E20552865297B696628303D3D3D652972';
wwv_flow_imp.g_varchar2_table(172) := '657475726E225A45524F223B76617220743D5B5D3B72657475726E5B5B316531322C225452494C4C494F4E225D2C5B3165392C2242494C4C494F4E225D2C5B3165362C224D494C4C494F4E225D2C5B3165332C2254484F5553414E44225D5D2E666F7245';
wwv_flow_imp.g_varchar2_table(173) := '6163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E707573682855286E292B2220222B725B315D292C652D3D6E2A725B305D297D292C652626742E707573682866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(174) := '297B76617220743D4D6174682E666C6F6F7228652F313030292C723D65253130302C6E3D5B5D3B72657475726E207426266E2E7075736828495B745D2B222048554E4452454422292C7226266E2E7075736828723C32303F495B725D3A525B4D6174682E';
wwv_flow_imp.g_varchar2_table(175) := '666C6F6F7228722F3130295D2B28722531303F222D222B495B722531305D3A222229292C6E2E6A6F696E28222022297D286529292C742E6A6F696E28222022297D66756E6374696F6E204228652C74297B76617220723D653C302C6E3D4D6174682E726F';
wwv_flow_imp.g_varchar2_table(176) := '756E64283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C613D6E253130302C6C3D55286F293B69662874297B76617220693D537472696E672874292E746F55707065724361736528292E73706C697428222F';
wwv_flow_imp.g_varchar2_table(177) := '22293B6C2B3D2220222B28313D3D3D6F2626692E6C656E6774683E313F695B305D3A695B692E6C656E6774682D315D297D72657475726E28723F224D494E555320223A2222292B6C2B2220414E4420222B28613C31303F2230223A2222292B612B222F31';
wwv_flow_imp.g_varchar2_table(178) := '3030227D66756E6374696F6E205F28652C742C72297B766172206E3D537472696E672874292E746F55707065724361736528292C6F3D6E2E696E6465784F6628222E22293B6966286F3E30297B76617220613D6E2E73756273747228302C6F292C6C3D6E';
wwv_flow_imp.g_varchar2_table(179) := '2E737562737472286F2B31293B69662822444F43223D3D3D612972657475726E20652E646F633F652E646F635B6C5D3A766F696420303B69662822504152414D223D3D3D612972657475726E20652E706172616D733F652E706172616D735B6C5D3A766F';
wwv_flow_imp.g_varchar2_table(180) := '696420303B696628224954454D223D3D3D612972657475726E2066756E6374696F6E2865297B7472797B72657475726E2077696E646F772E617065782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D63';
wwv_flow_imp.g_varchar2_table(181) := '617463682865297B72657475726E22227D7D286C293B76617220693D28652E535B615D7C7C5B5D295B305D3B72657475726E20693F695B6C5D3A766F696420307D72657475726E224E4F57223D3D3D6E3F6228293A22544F444159223D3D3D6E3F772829';
wwv_flow_imp.g_varchar2_table(182) := '3A2250414745223D3D3D6E7C7C225041474553223D3D3D6E7C7C22444F4350414745223D3D3D6E7C7C22444F435041474553223D3D3D6E3F227B222B6E2B227D223A7226264F626A6563742E70726F746F747970652E6861734F776E50726F7065727479';
wwv_flow_imp.g_varchar2_table(183) := '2E63616C6C28722C6E293F725B6E5D3A652E646F6326264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F652E646F635B6E5D3A652E706172616D733F652E706172616D735B6E5D3A76';
wwv_flow_imp.g_varchar2_table(184) := '6F696420307D66756E6374696F6E204728652C742C72297B72657475726E206E756C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C28283F3A6D61736B7C6F7261293A';
wwv_flow_imp.g_varchar2_table(185) := '5B5E7D5D2B7C5B412D5A612D7A302D393A2FC381C389C38DC393C39AC391C39CC3A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B7C5B5E7D5D2A5B23305D5B5E7D5D2A29293F5C7D2F672C66756E6374696F6E28652C6E2C6F297B76617220613D5F28742C6E2C72';
wwv_flow_imp.g_varchar2_table(186) := '293B72657475726E206E756C6C3D3D613F22223A5328612C6F297D297D66756E6374696F6E204828652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E';
wwv_flow_imp.g_varchar2_table(187) := '7C3C293F5C732A282E2A29242F2E657865632865293B696628216E2972657475726E21313B766172206F3D5F28742C6E5B325D2C72293B696628216E5B335D297B76617220613D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E22';
wwv_flow_imp.g_varchar2_table(188) := '3D3D3D6F293B72657475726E206E5B315D3F21613A617D766172206C2C693D286C3D286C3D6E5B345D292E7472696D28292C2F5E272E2A27242F2E74657374286C297C7C2F5E222E2A22242F2E74657374286C293F6C2E736C69636528312C2D31293A22';
wwv_flow_imp.g_varchar2_table(189) := '6E756C6C223D3D3D6C3F6E756C6C3A22223D3D3D6C7C7C69734E614E284E756D626572286C29293F766F696420303A4E756D626572286C29293B766F696420303D3D3D69262628693D5F28742C6E5B345D2E7472696D28292C7229293B76617220733D6E';
wwv_flow_imp.g_varchar2_table(190) := '756C6C3D3D6F7C7C22223D3D3D6F3F6E756C6C3D3D3D697C7C22223D3D3D693A537472696E67286F293D3D3D537472696E672869293B737769746368286E5B335D297B63617365223D3D223A72657475726E20733B6361736522213D223A72657475726E';
wwv_flow_imp.g_varchar2_table(191) := '21733B63617365223E223A72657475726E204E756D626572286F293E4E756D6265722869293B63617365223C223A72657475726E204E756D626572286F293C4E756D6265722869293B63617365223E3D223A72657475726E204E756D626572286F293E3D';
wwv_flow_imp.g_varchar2_table(192) := '4E756D6265722869293B63617365223C3D223A72657475726E204E756D626572286F293C3D4E756D6265722869297D72657475726E21317D66756E6374696F6E205728652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C2822';
wwv_flow_imp.g_varchar2_table(193) := '66756E6374696F6E223D3D747970656F6620653F21216528722C74293A537472696E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E65766572792866756E6374';
wwv_flow_imp.g_varchar2_table(194) := '696F6E2865297B72657475726E204828652C742C72297D297D29297D66756E6374696F6E205628652C74297B696628652E5F726F77732972657475726E20652E5F726F77733B76617220723D742E535B537472696E6728652E736F757263657C7C222229';
wwv_flow_imp.g_varchar2_table(195) := '2E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C7465722866756E6374696F6E2872297B72657475726E205728652E66696C7465722C742C72297D293A727D66756E6374696F6E202428652C742C72';
wwv_flow_imp.g_varchar2_table(196) := '297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F6620652972657475726E20653B766172206E3D5F28742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C65';
wwv_flow_imp.g_varchar2_table(197) := '2E64656661756C747C7C6E756C6C7D66756E6374696F6E205928652C742C72297B766172206E3D6E756C6C3B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E21215728652E7768656E2C742C72292626286E';
wwv_flow_imp.g_varchar2_table(198) := '3D652C2130297D292C6E7D76617220713D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D2C617269616C3A5B2268656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D657320';
wwv_flow_imp.g_varchar2_table(199) := '4E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75726965723A5B22636F7572696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F75';
wwv_flow_imp.g_varchar2_table(200) := '72696572204E6577225D7D3B66756E6374696F6E20582865297B6966282128653D537472696E67286E756C6C3D3D653F22223A65292E7472696D2829292972657475726E206E756C6C3B6966282F5E7777775C2E2F692E74657374286529262628653D22';
wwv_flow_imp.g_varchar2_table(201) := '68747470733A2F2F222B65292C2F5E2868747470733F3A7C6D61696C746F3A7C74656C3A7C6674703A292F692E746573742865292972657475726E20652E7265706C616365282F202F672C2225323022293B6966282F5E5B412D5A612D7A5D5B412D5A61';
wwv_flow_imp.g_varchar2_table(202) := '2D7A302D392B2E2D5D2A3A2F2E746573742865292972657475726E206E756C6C3B7472797B69662877696E646F772E6C6F636174696F6E26262F5E68747470733F3A2F2E746573742877696E646F772E6C6F636174696F6E2E6872656629297265747572';
wwv_flow_imp.g_varchar2_table(203) := '6E206E65772055524C28652C77696E646F772E6C6F636174696F6E2E68726566292E687265667D63617463682865297B7D72657475726E206E756C6C7D66756E6374696F6E205A28652C742C72297B72657475726E20652626652E687265663F58284728';
wwv_flow_imp.g_varchar2_table(204) := '652E687265662C742C7229293A6E756C6C7D66756E6374696F6E204A28652C742C722C6E297B69662872297B652E6C696E6B28742E782C742E792C742E77696474682C742E6865696768742C7B75726C3A727D293B766172206F3D41727261792E697341';
wwv_flow_imp.g_varchar2_table(205) := '7272617928742E74657874293F742E746578743A5B742E746578745D3B6966282131213D3D6E26266F2E6A6F696E28222229297B76617220613D652E696E7465726E616C2E676574466F6E7453697A6528292F652E696E7465726E616C2E7363616C6546';
wwv_flow_imp.g_varchar2_table(206) := '6163746F722C6C3D612A28652E6765744C696E65486569676874466163746F723F652E6765744C696E65486569676874466163746F7228293A312E3135292C693D742E67657454657874506F7328292C733D742E7374796C65732E76616C69676E2C753D';
wwv_flow_imp.g_varchar2_table(207) := '742E7374796C65732E68616C69676E2C633D692E792B612A28322D312E3135293B226D6964646C65223D3D3D733F632D3D6F2E6C656E6774682F322A6C3A22626F74746F6D223D3D3D73262628632D3D6F2E6C656E6774682A6C293B76617220663D742E';
wwv_flow_imp.g_varchar2_table(208) := '7374796C65732E74657874436F6C6F723B69662841727261792E6973417272617928662929652E73657444726177436F6C6F7228665B305D2C665B315D2C665B325D293B656C73652069662822737472696E67223D3D747970656F66206626262F5E232F';
wwv_flow_imp.g_varchar2_table(209) := '2E74657374286629297B76617220643D702866293B652E73657444726177436F6C6F7228645B305D2C645B315D2C645B325D297D656C736520652E73657444726177436F6C6F7228667C7C30293B652E7365744C696E655769647468282E3033352A6129';
wwv_flow_imp.g_varchar2_table(210) := '2C6F2E666F72456163682866756E6374696F6E28742C72297B766172206E3D652E676574537472696E67556E6974576964746828537472696E67287429292A612C6F3D227269676874223D3D3D753F692E782D6E3A2263656E746572223D3D3D753F692E';
wwv_flow_imp.g_varchar2_table(211) := '782D6E2F323A692E782C733D632B722A6C2B2E31372A613B6E3E302626652E6C696E65286F2C732C6F2B6E2C73297D297D7D7D66756E6374696F6E204B2865297B72657475726E20653D537472696E6728657C7C2268656C76657469636122292E746F4C';
wwv_flow_imp.g_varchar2_table(212) := '6F7765724361736528292C715B655D3F653A2268656C766574696361227D66756E6374696F6E205128652C74297B76617220722C6E3D5B5D2C6F3D7B623A21312C693A21312C753A21312C733A21317D2C613D5B28743D747C7C7B7D292E666F6E747C7C';
wwv_flow_imp.g_varchar2_table(213) := '2268656C766574696361225D2C6C3D5B742E636F6C6F727C7C6E756C6C5D2C693D5B5D2C733D22222C753D303B66756E6374696F6E206328297B69662873297B76617220653D695B692E6C656E6774682D315D2C723D6C5B6C2E6C656E6774682D315D3B';
wwv_flow_imp.g_varchar2_table(214) := '652626652E75726C26266C2E6C656E6774683C3D652E6364262628723D742E6C696E6B7C7C642E6C696E6B292C6E2E70757368287B743A732C623A6F2E622C693A6F2E692C753A6F2E757C7C212821657C7C21652E75726C292C733A6F2E732C663A4B28';
wwv_flow_imp.g_varchar2_table(215) := '615B612E6C656E6774682D315D292C633A722C683A653F652E75726C3A6E756C6C7D292C733D22227D7D666F7228653D537472696E67286E756C6C3D3D653F22223A65293B753C652E6C656E6774683B297B76617220663D652E7375627374722875293B';
wwv_flow_imp.g_varchar2_table(216) := '225C5C223D3D3D662E6368617241742830292626662E6C656E6774683E313F28732B3D662E6368617241742831292C752B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286629293F286328292C612E7075736828725B';
wwv_flow_imp.g_varchar2_table(217) := '315D292C752B3D725B305D2E6C656E677468293A225B2F665D22213D3D662E73756273747228302C34293F28723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286629293F286328292C6C2E7075736828725B315D';
wwv_flow_imp.g_varchar2_table(218) := '292C752B3D725B305D2E6C656E677468293A225B2F635D22213D3D662E73756273747228302C34293F28723D2F5E5C5B613D285B5E5C5D5C735D2A295C5D2F2E65786563286629293F286328292C692E70757368287B75726C3A5828725B315D292C6364';
wwv_flow_imp.g_varchar2_table(219) := '3A6C2E6C656E6774687D292C752B3D725B305D2E6C656E677468293A225B2F615D22213D3D662E73756273747228302C34293F222A2A2A22213D3D662E73756273747228302C33293F222A2A22213D3D662E73756273747228302C32293F227E7E22213D';
wwv_flow_imp.g_varchar2_table(220) := '3D662E73756273747228302C32293F222B2B22213D3D662E73756273747228302C32293F222A22213D3D662E6368617241742830293F28732B3D662E6368617241742830292C752B2B293A286328292C6F2E693D216F2E692C752B3D31293A286328292C';
wwv_flow_imp.g_varchar2_table(221) := '6F2E753D216F2E752C752B3D32293A286328292C6F2E733D216F2E732C752B3D32293A286328292C6F2E623D216F2E622C752B3D32293A286328292C6F2E623D216F2E622C6F2E693D216F2E692C752B3D33293A286328292C692E706F7028292C752B3D';
wwv_flow_imp.g_varchar2_table(222) := '34293A286328292C6C2E6C656E6774683E3126266C2E706F7028292C752B3D34293A286328292C612E6C656E6774683E312626612E706F7028292C752B3D34297D72657475726E206328292C6E7D66756E6374696F6E20656528652C74297B7661722072';
wwv_flow_imp.g_varchar2_table(223) := '3D652E736F757263653F5628652C74295B305D3A6E756C6C3B72657475726E2841727261792E6973417272617928652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C6974';
wwv_flow_imp.g_varchar2_table(224) := '28225C6E2229292E6D61702866756E6374696F6E2865297B72657475726E204728652C742C72297D297D66756E6374696F6E20746528652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528';
wwv_flow_imp.g_varchar2_table(225) := '292C6F3D652E5F74797065737C7C742E545B6E5D7C7C7B7D2C613D652E636F6C756D6E733B72657475726E20612626612E6C656E6774687C7C28613D4F626A6563742E6B657973286F292E66696C7465722866756E6374696F6E2865297B72657475726E';
wwv_flow_imp.g_varchar2_table(226) := '22444F435F4B455922213D3D657D292E6D61702866756E6374696F6E2865297B72657475726E7B636F6C3A657D7D29292C28613D612E66696C7465722866756E6374696F6E2865297B72657475726E22737472696E67223D3D747970656F6620657C7C21';
wwv_flow_imp.g_varchar2_table(227) := '652E7768656E7C7C5728652E7768656E2C742C6E756C6C297D29292E6D61702866756E6374696F6E2865297B76617220743D28653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C29';
wwv_flow_imp.g_varchar2_table(228) := '2E746F55707065724361736528293A6E756C6C2C6E3D743F6F5B745D3A6E756C6C2C613D652E666D743B617C7C224E554D42455222213D3D6E7C7C652E76616C75657C7C28613D722E736F6D652866756E6374696F6E2865297B72657475726E20682865';
wwv_flow_imp.g_varchar2_table(229) := '5B745D2926264D6174682E726F756E6428655B745D29213D3D655B745D7D293F226D6F6E6579223A6E756C6C293B766172206C3D652E63656C6C262661655B652E63656C6C2E747970655D3F652E63656C6C3A6E756C6C3B72657475726E7B636F6C3A74';
wwv_flow_imp.g_varchar2_table(230) := '2C76616C75653A766F69642030213D3D652E76616C75653F652E76616C75653A652E63656C6C262622746578746F223D3D3D652E63656C6C2E747970653F652E63656C6C2E746578743A766F696420302C6C6162656C3A766F69642030213D3D652E6C61';
wwv_flow_imp.g_varchar2_table(231) := '62656C3F652E6C6162656C3A7928747C7C2222292C63656C6C3A6C2C76616C69676E3A2F5E28746F707C6D6964646C657C626F74746F6D29242F2E7465737428537472696E6728652E76616C69676E7C7C2222292E746F4C6F776572436173652829293F';
wwv_flow_imp.g_varchar2_table(232) := '537472696E6728652E76616C69676E292E746F4C6F7765724361736528293A6E756C6C2C666D743A612C6D61703A652E6D61702C626F6C643A2121652E626F6C642C77696474683A652E77696474682C616C69676E3A652E616C69676E7C7C286C3F2263';
wwv_flow_imp.g_varchar2_table(233) := '656E746572223A6E756C6C297C7C28542861293F226C656674223A224E554D424552223D3D3D6E7C7C226D6F6E6579223D3D3D617C7C22696E74223D3D3D617C7C226E756D223D3D3D617C7C4D2861293F227269676874223A2244415445223D3D3D6E7C';
wwv_flow_imp.g_varchar2_table(234) := '7C2264617465223D3D3D613F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63656C6C5374796C652C636F6C6F723A652E636F6C6F722C68656164416C69676E3A652E68656164416C69676E2C687265663A652E687265667C7C';
wwv_flow_imp.g_varchar2_table(235) := '652E63656C6C2626652E63656C6C2E687265667C7C6E756C6C2C69734E756D3A216C26262154286129262628224E554D424552223D3D3D6E262621652E6D6170262621652E76616C75657C7C226D6F6E6579223D3D3D617C7C22696E74223D3D3D617C7C';
wwv_flow_imp.g_varchar2_table(236) := '2F5E6E756D2F2E7465737428617C7C2222297C7C4D286129297D7D297D66756E6374696F6E20726528652C74297B76617220723D5B5D2C6E3D303B72657475726E28652E67726F7570737C7C5B5D292E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(237) := '766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E677468262628722E70757368287B6C6162656C3A652E6C6162656C7C7C22222C636F6C733A6F2C66726F6D3A';
wwv_flow_imp.g_varchar2_table(238) := '6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C733A742E6C656E6774682D6E2C66726F6D3A6E2C6761703A21307D292C727D66756E6374696F6E206E6528';
wwv_flow_imp.g_varchar2_table(239) := '652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E204728652E76616C75652C722C74293B766172206E3D745B652E636F6C5D3B72657475726E20652E6D617026266E756C6C213D6E2626766F69642030213D3D652E6D61';
wwv_flow_imp.g_varchar2_table(240) := '705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E206F6528652C742C72297B766172206E3D6E6528652C742C72293B72657475726E20652E6D61702626766F69642030213D3D652E6D61705B745B652E636F6C5D5D3F537472696E67286E293A';
wwv_flow_imp.g_varchar2_table(241) := '53286E2C652E666D74297D7661722061653D7B636F6469676F3A312C696D6167656E3A312C6772616669636F3A317D3B66756E6374696F6E206C652865297B76617220742C723D7B7D3B666F72287420696E2065294F626A6563742E70726F746F747970';
wwv_flow_imp.g_varchar2_table(242) := '652E6861734F776E50726F70657274792E63616C6C28652C7429262628725B745D3D655B745D293B72657475726E20727D66756E6374696F6E20696528652C74297B76617220723D537472696E6728652E76616C69676E7C7C2222292E746F4C6F776572';
wwv_flow_imp.g_varchar2_table(243) := '4361736528293B72657475726E22746F70223D3D3D727C7C226D6964646C65223D3D3D727C7C22626F74746F6D223D3D3D723F723A742E736F6D652866756E6374696F6E2865297B72657475726E20652E63656C6C7D293F226D6964646C65223A6E756C';
wwv_flow_imp.g_varchar2_table(244) := '6C7D66756E6374696F6E20736528652C742C722C6E297B766172206F3D652E63656C6C3B696628216F2972657475726E206E756C6C3B69662822636F6469676F223D3D3D6F2E74797065297B766172206C3D6C65286F293B6C2E73697A657C7C286C2E73';
wwv_flow_imp.g_varchar2_table(245) := '697A653D3134292C6C2E77696474687C7C286C2E77696474683D3330292C6C2E6865696768747C7C286C2E6865696768743D38293B76617220693D5974286C2C722C74293B69662821692972657475726E206E756C6C3B76617220733D71742869293B72';
wwv_flow_imp.g_varchar2_table(246) := '657475726E7B696D3A732C773A732E776D6D2C683A732E686D6D7D7D69662822696D6167656E223D3D3D6F2E74797065297B76617220753D6F2E6669656C643F745B537472696E67286F2E6669656C64292E746F55707065724361736528295D3A6E756C';
wwv_flow_imp.g_varchar2_table(247) := '6C2C633D6E756C6C3B7472797B633D753F44742875293A6F2E75726C2626216F2E6669656C643F4E745B4D742847286F2E75726C2C722C7429295D3A6E756C6C7D63617463682865297B77696E646F772E636F6E736F6C652626636F6E736F6C652E7761';
wwv_flow_imp.g_varchar2_table(248) := '726E28612822696D67426164222C6F2E6669656C64292C65297D69662821632972657475726E206E756C6C3B76617220663D4974287B77696474683A6F2E77696474687C7C286F2E6865696768743F766F696420303A3135292C6865696768743A6F2E68';
wwv_flow_imp.g_varchar2_table(249) := '65696768747D2C63293B72657475726E7B696D3A632C773A662E772C683A662E687D7D76617220643D6C65286F293B64656C65746520642E66696C7465722C64656C65746520642E6C696E6B2C642E77696474687C7C28642E77696474683D3430292C64';
wwv_flow_imp.g_varchar2_table(250) := '2E6865696768747C7C28642E6865696768743D3135293B76617220683D5A7428642C66756E6374696F6E28652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6F3D652E6C696E6B7C';
wwv_flow_imp.g_varchar2_table(251) := '7C7B7D2C613D652E66696C7465723F4728652E66696C7465722C742C72293A6E756C6C2C6C3D28742E535B6E5D7C7C5B5D292E66696C7465722866756E6374696F6E2865297B666F7228766172206E20696E206F296966284F626A6563742E70726F746F';
wwv_flow_imp.g_varchar2_table(252) := '747970652E6861734F776E50726F70657274792E63616C6C286F2C6E292626537472696E6728655B6E2E746F55707065724361736528295D29213D3D537472696E6728725B537472696E67286F5B6E5D292E746F55707065724361736528295D29297265';
wwv_flow_imp.g_varchar2_table(253) := '7475726E21313B72657475726E21617C7C5728612C742C65297D292C693D6C652874293B72657475726E20692E533D6C6528742E53292C692E535B6E5D3D6C2C697D286F2C722C74292C6E293B72657475726E20683F7B696D3A682C773A682E776D6D2C';
wwv_flow_imp.g_varchar2_table(254) := '683A682E686D6D7D3A6E756C6C7D7661722075653D7B666F726D756C6172696F3A312C66696368613A312C7461726A657461733A317D3B66756E6374696F6E2063652865297B76617220743D5B5D3B72657475726E28657C7C5B5D292E666F7245616368';
wwv_flow_imp.g_varchar2_table(255) := '2866756E6374696F6E2865297B69662865262675655B652E747970655D262628652E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29297B76617220723D6E756C6C2C6E3D302C6F';
wwv_flow_imp.g_varchar2_table(256) := '3D66756E6374696F6E28297B722626722E6669656C64732E6C656E6774682626742E707573682872292C723D6E756C6C7D3B652E6669656C64732E666F72456163682866756E6374696F6E2861297B696628612626612E626C6F636B297B766172206C3D';
wwv_flow_imp.g_varchar2_table(257) := '612E626C6F636B3B696628216C7C7C2179745B6C2E747970655D7C7C22666F726D756C6172696F223D3D3D6C2E747970652972657475726E3B72657475726E206F28292C21286C3D6C65286C29292E736F757263652626652E736F757263652626226C69';
wwv_flow_imp.g_varchar2_table(258) := '6E656122213D3D6C2E747970652626226573706163696F22213D3D6C2E747970652626286C2E736F757263653D652E736F75726365292C612E7768656E2626216C2E7768656E2626286C2E7768656E3D612E7768656E292C6E7C7C21652E7469746C657C';
wwv_flow_imp.g_varchar2_table(259) := '7C227461626C6122213D3D6C2E747970657C7C6C2E7469746C657C7C286C2E7469746C653D652E7469746C65292C742E70757368286C292C766F6964206E2B2B7D727C7C2828723D6C65286529292E6669656C64733D5B5D2C6E262664656C6574652072';
wwv_flow_imp.g_varchar2_table(260) := '2E7469746C652C6E2B2B292C722E6669656C64732E707573682861297D292C6F28297D656C736520742E707573682865297D292C747D7661722066653D7B6C65747465723A312C7461626C6F69643A332C6C6567616C3A352C6578656375746976653A37';
wwv_flow_imp.g_varchar2_table(261) := '2C61333A382C61343A392C61353A31312C62353A31337D2C64653D7B73756D3A392C6176673A312C6D696E3A352C6D61783A342C636F756E743A337D2C68653D7B73756D3A2253554D222C6176673A2241564552414745222C6D696E3A224D494E222C6D';
wwv_flow_imp.g_varchar2_table(262) := '61783A224D4158222C636F756E743A22434F554E5441227D2C70653D7B6176673A22616767417667222C6D696E3A226167674D696E222C6D61783A226167674D6178222C636F756E743A22616767436F756E74227D3B66756E6374696F6E206765286529';
wwv_flow_imp.g_varchar2_table(263) := '7B72657475726E2070655B655D3F612870655B655D293A22227D66756E6374696F6E206D652865297B72657475726E2841727261792E697341727261792865293F653A5B5D292E6D61702866756E6374696F6E2865297B76617220743D652626226F626A';
wwv_flow_imp.g_varchar2_table(264) := '656374223D3D747970656F6620653F653A7B636F6C3A657D2C723D537472696E6728742E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475726E7B636F6C3A537472696E6728742E636F6C7C7C2222292E746F5570706572436173';
wwv_flow_imp.g_varchar2_table(265) := '6528292C666E3A64655B725D3F723A2273756D227D7D292E66696C7465722866756E6374696F6E2865297B72657475726E20652E636F6C7D297D66756E6374696F6E20766528652C74297B666F722876617220723D303B723C652E6C656E6774683B722B';
wwv_flow_imp.g_varchar2_table(266) := '2B29696628655B725D2E636F6C3D3D3D742972657475726E20655B725D3B72657475726E206E756C6C7D66756E6374696F6E2062652865297B72657475726E20652E736F6D652866756E6374696F6E2865297B72657475726E2273756D22213D3D652E66';
wwv_flow_imp.g_varchar2_table(267) := '6E7D297D66756E6374696F6E2077652865297B72657475726E20682865297C7C22737472696E67223D3D747970656F66206526262222213D3D652E7472696D282926262169734E614E284E756D626572286529297D66756E6374696F6E20796528652C74';
wwv_flow_imp.g_varchar2_table(268) := '2C72297B766172206E3D652E6D61702866756E6374696F6E2865297B72657475726E20655B745D7D292E66696C7465722866756E6374696F6E2865297B72657475726E206E756C6C213D6526262222213D3D657D293B69662822636F756E74223D3D3D72';
wwv_flow_imp.g_varchar2_table(269) := '2972657475726E206E2E6C656E6774683B6966282273756D223D3D3D727C7C22617667223D3D3D72297B766172206F3D6E2E66696C746572287765292E6D6170284E756D626572292C613D6F2E7265647563652866756E6374696F6E28652C74297B7265';
wwv_flow_imp.g_varchar2_table(270) := '7475726E20652B747D2C30293B72657475726E2273756D223D3D3D723F613A6F2E6C656E6774683F612F6F2E6C656E6774683A6E756C6C7D766172206C3D6E756C6C2C693D6E756C6C3B72657475726E206E2E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(271) := '65297B76617220743D77652865293F6E756C6C3A782865292C6E3D77652865293F4E756D6265722865293A743F742E67657454696D6528293A537472696E672865293B286E756C6C3D3D3D697C7C28226D696E223D3D3D723F6E3C693A6E3E6929292626';
wwv_flow_imp.g_varchar2_table(272) := '286C3D652C693D6E297D292C6C7D66756E6374696F6E20786528652C742C722C6E297B766172206F3D62652874292C613D2D312C6C3D652E6D61702866756E6374696F6E28652C6E297B766172206C3D652E636F6C3F766528742C652E636F6C293A6E75';
wwv_flow_imp.g_varchar2_table(273) := '6C6C3B72657475726E206C2626613C30262628613D6E292C6C3F66756E6374696F6E28652C742C722C6E297B766172206F2C613D796528722C742E636F6C2C742E666E293B72657475726E286F3D6E756C6C3D3D613F22223A22636F756E74223D3D3D74';
wwv_flow_imp.g_varchar2_table(274) := '2E666E3F5328612C22696E7422293A226D696E223D3D3D742E666E7C7C226D6178223D3D3D742E666E3F77652861293F5328612C652E666D747C7C226D6F6E657922293A5328612C652E666D74293A22617667223D3D3D742E666E3F5328612C652E666D';
wwv_flow_imp.g_varchar2_table(275) := '74262622696E7422213D3D652E666D743F652E666D743A226D6F6E657922293A5328612C652E666D747C7C226D6F6E657922292926266E2626676528742E666E293F676528742E666E292B2220222B6F3A6F7D28652C6C2C722C6F293A22227D293B7265';
wwv_flow_imp.g_varchar2_table(276) := '7475726E7B61743A613C303F652E6C656E6774683A612C63656C6C733A6C2C746578743A6E7D7D66756E6374696F6E20456528652C742C72297B72657475726E204728652E746F74616C734C6162656C7C7C612822746F74616C7322292C742C7B434F55';
wwv_flow_imp.g_varchar2_table(277) := '4E543A722E6C656E6774687D297D66756E6374696F6E20536528652C74297B76617220723D7B636F6E74656E743A652E746578742C636F6C5370616E3A652E61747C7C742C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E20';
wwv_flow_imp.g_varchar2_table(278) := '303D3D3D652E61743F5B5B725D2C652E63656C6C732E736C69636528295D3A5B5B725D2E636F6E63617428652E63656C6C732E736C69636528652E617429295D7D66756E6374696F6E2054652865297B72657475726E21313D3D3D652E627265616B546F';
wwv_flow_imp.g_varchar2_table(279) := '74616C733F5B5D3A6D652841727261792E6973417272617928652E627265616B546F74616C73293F652E627265616B546F74616C733A652E746F74616C73297D66756E6374696F6E2043652865297B76617220743D652E627265616B42793B7265747572';
wwv_flow_imp.g_varchar2_table(280) := '6E20743F2841727261792E697341727261792874293F743A5B745D292E6D61702866756E6374696F6E2865297B72657475726E20537472696E6728657C7C2222292E746F55707065724361736528297D292E66696C74657228426F6F6C65616E293A5B5D';
wwv_flow_imp.g_varchar2_table(281) := '7D66756E6374696F6E20416528652C74297B72657475726E2041727261792E697341727261792865293F655B745D3A657D66756E6374696F6E204E6528652C74297B76617220723D43652865293B69662821722E6C656E6774687C7C21742E6C656E6774';
wwv_flow_imp.g_varchar2_table(282) := '682972657475726E20742E6D61702866756E6374696F6E28652C74297B72657475726E7B6B3A22726F77222C723A652C693A747D7D293B766172206E3D5B5D2C6F3D5B5D2C613D302C6C3D54652865292E6C656E6774683E303B66756E6374696F6E2069';
wwv_flow_imp.g_varchar2_table(283) := '2874297B666F72283B6F2E6C656E6774683E743B297B76617220723D6F2E706F7028293B6C26262131213D3D416528652E627265616B4C6162656C2C6F2E6C656E6774682926266E2E70757368287B6B3A22737562222C6C766C3A6F2E6C656E6774682C';
wwv_flow_imp.g_varchar2_table(284) := '636F6C3A722E636F6C2C723A722E722C726F77733A722E726F77737D297D7D72657475726E20742E666F72456163682866756E6374696F6E2874297B666F7228766172206C3D722E6D61702866756E6374696F6E2865297B72657475726E20537472696E';
wwv_flow_imp.g_varchar2_table(285) := '67286E756C6C3D3D3D745B655D7C7C766F696420303D3D3D745B655D3F22223A745B655D297D292C733D303B733C6F2E6C656E67746826266F5B735D2E6B65793D3D3D6C5B735D3B29732B2B3B666F7228692873293B733C722E6C656E6774683B732B2B';
wwv_flow_imp.g_varchar2_table(286) := '297B76617220753D7B6B65793A6C5B735D2C636F6C3A725B735D2C723A742C726F77733A5B5D7D3B6F2E707573682875292C2131213D3D416528652E627265616B5469746C652C732926266E2E70757368287B6B3A2268656164222C6C766C3A732C636F';
wwv_flow_imp.g_varchar2_table(287) := '6C3A725B735D2C723A742C726F77733A752E726F77737D297D6F2E666F72456163682866756E6374696F6E2865297B652E726F77732E707573682874297D292C6E2E70757368287B6B3A22726F77222C723A742C693A612B2B7D297D292C692830292C6E';
wwv_flow_imp.g_varchar2_table(288) := '7D66756E6374696F6E20506528652C74297B76617220723D43652865295B305D3B69662821652E627265616B506167657C7C21727C7C652E5F706172747C7C742E6C656E6774683C322972657475726E206E756C6C3B766172206E3D5B5D2C6F3D6E756C';
wwv_flow_imp.g_varchar2_table(289) := '6C3B72657475726E20742E666F72456163682866756E6374696F6E2865297B76617220743D537472696E67286E756C6C3D3D3D655B725D7C7C766F696420303D3D3D655B725D3F22223A655B725D293B6E2E6C656E6774682626743D3D3D6F7C7C286E2E';
wwv_flow_imp.g_varchar2_table(290) := '70757368285B5D292C6F3D74292C6E5B6E2E6C656E6774682D315D2E707573682865297D292C6E2E6C656E6774683C323F6E756C6C3A6E2E6D61702866756E6374696F6E28722C6F297B76617220613D6C652865292C6C3D6F3D3D3D6E2E6C656E677468';
wwv_flow_imp.g_varchar2_table(291) := '2D313B72657475726E20612E5F726F77733D722C612E5F706172743D21302C612E5F616C6C526F77733D742C766F696420303D3D3D612E627265616B546F74616C73262628612E627265616B546F74616C733D652E746F74616C73292C6C7C7C28612E74';
wwv_flow_imp.g_varchar2_table(292) := '6F74616C733D6E756C6C292C6F3E302626652E7469746C654F6E6365262664656C65746520612E7469746C652C617D297D66756E6374696F6E20466528652C74297B69662821742972657475726E20652E67726F75703B76617220723D7028652E67726F';
wwv_flow_imp.g_varchar2_table(293) := '7570292C6E3D4D6174682E6D696E282E37352C2E342A74293B72657475726E2223222B722E6D61702866756E6374696F6E2865297B76617220743D4D6174682E726F756E6428652B283235352D65292A6E292E746F537472696E67283136293B72657475';
wwv_flow_imp.g_varchar2_table(294) := '726E20742E6C656E6774683C323F2230222B743A747D292E6A6F696E282222292E746F55707065724361736528297D66756E6374696F6E207A6528652C742C72297B766172206E2C6F3D7B7D2C6C3D742E636F6C7C7C43652865295B305D3B666F72286E';
wwv_flow_imp.g_varchar2_table(295) := '20696E20742E72296F5B6E5D3D742E725B6E5D3B6F2E434F554E543D742E726F77732E6C656E6774683B76617220693D4165282268656164223D3D3D742E6B3F652E627265616B5469746C653A652E627265616B4C6162656C2C742E6C766C7C7C30293B';
wwv_flow_imp.g_varchar2_table(296) := '72657475726E206E756C6C213D6926262130213D3D697C7C28693D2268656164223D3D3D742E6B3F227B222B6C2B227D223A612822737562746F74616C22292B22207B222B6C2B227D22292C4728692C722C6F297D66756E6374696F6E204D6528652C74';
wwv_flow_imp.g_varchar2_table(297) := '2C72297B696628652E6D6170297B766172206E3D5F28742C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C2222292E73706C697428227C22295B305D2C72293B72657475726E20766F69642030213D3D652E6D61705B6E';
wwv_flow_imp.g_varchar2_table(298) := '5D3F652E6D61705B6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E7D7C5D2B5C7D242F2E74657374286F7C7C2222293F53285F28742C6F2E736C69636528312C2D31292C';
wwv_flow_imp.g_varchar2_table(299) := '72292C652E666D74293A47286F2C742C72297D766172206B653D7B746578743A312C6D756C74696C696E653A312C6C6973743A312C636865636B626F783A317D2C4F653D2223463246364641222C4C653D2223424643394434222C44653D22E29892222C';
wwv_flow_imp.g_varchar2_table(300) := '6A653D22E29890223B66756E6374696F6E2049652865297B76617220743D537472696E67286E756C6C3D3D653F22223A65293B696628212F5E5B412D5A612D7A5F5D5B412D5A612D7A302D395F5D7B302C33397D242F2E746573742874297C7C2F5E5B41';
wwv_flow_imp.g_varchar2_table(301) := '2D5A612D7A5D7B312C337D5B302D395D2B242F2E746573742874297C7C2F5E5B527243635D242F2E746573742874297C7C2F5E5B52725D5B302D395D2A5B43635D5B302D395D2A242F2E74657374287429297468726F77206E6577204572726F72286128';
wwv_flow_imp.g_varchar2_table(302) := '226669656C64426164222C7429293B72657475726E20747D66756E6374696F6E20526528297B76617220653D7B7D3B72657475726E2066756E6374696F6E2874297B76617220723D742E746F4C6F7765724361736528293B696628655B725D297468726F';
wwv_flow_imp.g_varchar2_table(303) := '77206E6577204572726F72286128226669656C64447570222C7429293B72657475726E20655B725D3D312C747D7D66756E6374696F6E20556528652C742C72297B766172206E3D5628652C74295B305D7C7C7B7D3B72657475726E28652E6669656C6473';
wwv_flow_imp.g_varchar2_table(304) := '7C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E7768656E7C7C5728652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E286F297B6966286F2E656D7074792972657475726E7B656D7074';
wwv_flow_imp.g_varchar2_table(305) := '793A21302C7370616E3A6F2E7370616E7D3B766172206C3D537472696E67286F2E696E7075747C7C227465787422292E746F4C6F7765724361736528293B696628216B655B6C5D297468726F77206E6577204572726F72286128226669656C6454797065';
wwv_flow_imp.g_varchar2_table(306) := '222C6F2E696E70757429293B76617220693D4965286F2E6E616D65292B28727C7C2222292C733D766F696420303D3D3D6F2E76616C75657C7C6E756C6C3D3D3D6F2E76616C75653F22223A537472696E67284D65286F2C742C6E29292C753D226C697374';
wwv_flow_imp.g_varchar2_table(307) := '223D3D3D6C3F66756E6374696F6E28652C74297B76617220723D5B5D3B66756E6374696F6E206E2865297B2222213D3D28653D537472696E67286E756C6C3D3D653F22223A6529292626722E696E6465784F662865293C302626722E707573682865297D';
wwv_flow_imp.g_varchar2_table(308) := '6966282841727261792E6973417272617928652E6F7074696F6E73293F652E6F7074696F6E733A5B5D292E666F7245616368286E292C652E6F7074696F6E7346726F6D297B766172206F3D537472696E6728652E6F7074696F6E7346726F6D292E73706C';
wwv_flow_imp.g_varchar2_table(309) := '697428222E22292C613D6F5B315D3F6F5B315D2E746F55707065724361736528293A6E756C6C3B56287B736F757263653A6F5B305D7D2C74292E666F72456163682866756E6374696F6E2865297B6E28613F655B615D3A655B4F626A6563742E6B657973';
wwv_flow_imp.g_varchar2_table(310) := '2865295B305D5D297D297D72657475726E20727D286F2C74293A5B5D3B696628226C697374223D3D3D6C262621752E6C656E677468297468726F77206E6577204572726F72286128226C697374456D707479222C6929293B76617220632C663D28227465';
wwv_flow_imp.g_varchar2_table(311) := '7874223D3D3D6C7C7C226D756C74696C696E65223D3D3D6C2926264E756D626572286F2E6D61784C656E677468293E303F4D6174682E666C6F6F72284E756D626572286F2E6D61784C656E67746829293A303B72657475726E226D756C74696C696E6522';
wwv_flow_imp.g_varchar2_table(312) := '213D3D6C262628733D732E7265706C616365282F5C723F5C6E2F672C22202229292C226C697374223D3D3D6C2626752E696E6465784F662873293C30262628733D2222292C66262628733D732E73756273747228302C6629292C7B6C6162656C3A47286F';
wwv_flow_imp.g_varchar2_table(313) := '2E6C6162656C2C742C6E292C6E616D653A692C696E7075743A6C2C6F7074696F6E733A752C76616C75653A22636865636B626F78223D3D3D6C3F22223A732C636865636B65643A22636865636B626F78223D3D3D6C262628633D732C21303D3D3D637C7C';
wwv_flow_imp.g_varchar2_table(314) := '2F5E28737C73697C73C3AD7C797C7965737C317C787C747275657C6F6E29242F692E7465737428537472696E67286E756C6C3D3D633F22223A63292E7472696D282929292C6D61784C656E6774683A662C726561644F6E6C793A21303D3D3D6F2E726561';
wwv_flow_imp.g_varchar2_table(315) := '644F6E6C792C6C696E65733A226D756C74696C696E65223D3D3D6C3F4D6174682E6D617828322C4D6174682E6D696E2832302C4E756D626572286F2E6C696E6573297C7C3329293A312C706C616365686F6C6465723A6F2E706C616365686F6C6465723F';
wwv_flow_imp.g_varchar2_table(316) := '47286F2E706C616365686F6C6465722C742C6E293A22222C7370616E3A6F2E7370616E2C6C61623A6E74286F2C65297D7D297D66756E6374696F6E20426528652C74297B76617220723D652E666F726D7C7C7B7D2C6E3D742626766F69642030213D3D74';
wwv_flow_imp.g_varchar2_table(317) := '2E666F726D50617373776F726426266E756C6C213D3D742E666F726D50617373776F72643F742E666F726D50617373776F72643A722E70617373776F72643B72657475726E7B70726F746563743A2131213D3D722E70726F746563742C70617373776F72';
wwv_flow_imp.g_varchar2_table(318) := '643A6E3F537472696E67286E293A22227D7D66756E6374696F6E205F652865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E206526262822666F726D756C6172696F223D3D3D652E747970657C7C2263';
wwv_flow_imp.g_varchar2_table(319) := '6F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E736F6D65285F65297C7C22677275706F223D3D3D652E7479706526265F6528652E73656374696F6E7329297D297D66756E6374696F6E2047652865297B76617220743D65';
wwv_flow_imp.g_varchar2_table(320) := '2626652E62617463682626652E62617463682E73756D6D6172793B72657475726E205F6528652626652E73656374696F6E73297C7C212821747C7C21285F6528742E73656374696F6E73297C7C742E6C61796F757426265F6528742E6C61796F75742E73';
wwv_flow_imp.g_varchar2_table(321) := '656374696F6E732929297D7661722048653D5B313131363335323430382C333630393736373435382C313839393434373434312C3630323839313732352C333034393332333437312C333936343438343339392C333932313030393537332C3231373332';
wwv_flow_imp.g_varchar2_table(322) := '39353534382C3936313938373136332C343038313632383437322C313530383937303939332C333035333833343236352C323435333633353734382C323933373637313537392C323837303736333232312C333636343630393536302C33363234333831';
wwv_flow_imp.g_varchar2_table(323) := '3038302C323733343838333339342C3331303539383430312C313136343939363534322C3630373232353237382C313332333631303736342C313432363838313938372C333539303330343939342C313932353037383338382C34303638313832333833';
wwv_flow_imp.g_varchar2_table(324) := '2C323136323037383230362C3939313333363131332C323631343838383130332C3633333830333331372C333234383232323538302C333437393737343836382C333833353339303430312C323636363631333435382C343032323232343737342C3934';
wwv_flow_imp.g_varchar2_table(325) := '343731313133392C3236343334373037382C323334313236323737332C3630343830373632382C323030373830303933332C3737303235353938332C313439353939303930312C313234393135303132322C313835363433313233352C31353535303831';
wwv_flow_imp.g_varchar2_table(326) := '3639322C333137353231383133322C313939363036343938362C323139383935303833372C323535343232303838322C333939393731393333392C323832313833343334392C3736363738343031362C323935323939363830382C323536363539343837';
wwv_flow_imp.g_varchar2_table(327) := '392C333231303331333637312C333230333333373935362C333333363537313839312C313033343435373032362C333538343532383731312C323436363934383930312C3131333932363939332C333735383332363338332C3333383234313839352C31';
wwv_flow_imp.g_varchar2_table(328) := '36383731373933362C3636363330373230352C313138383137393936342C3737333532393931322C313534363034353733342C313239343735373337322C313532323830353438352C313339363138323239312C323634333833333832332C3136393531';
wwv_flow_imp.g_varchar2_table(329) := '38333730302C323334333532373339302C313938363636313035312C313031343437373438302C323137373032363335302C313230363735393134322C323435363935363033372C3334343037373632372C323733303438353932312C31323930383633';
wwv_flow_imp.g_varchar2_table(330) := '3436302C323832303330323431312C333135383435343237332C333235393733303830302C333530353935323635372C333334353736343737312C3130363231373030382C333531363036353831372C333630363030383334342C333630303335323830';
wwv_flow_imp.g_varchar2_table(331) := '342C313433323732353737362C343039343537313930392C313436373033313539342C3237353432333334342C3835313136393732302C3433303232373733342C333130303832333735322C3530363934383631362C313336333235383139352C363539';
wwv_flow_imp.g_varchar2_table(332) := '3036303535362C333735303638353539332C3838333939373837372C333738353035303238302C3935383133393537312C333331383330373432372C313332323832323231382C333831323732333430332C313533373030323036332C32303033303334';
wwv_flow_imp.g_varchar2_table(333) := '3939352C313734373837333737392C333630323033363839392C313935353536323232322C313537353939303031322C323032343130343831352C313132353539323932382C323232373733303435322C323731363930343330362C3233363138353234';
wwv_flow_imp.g_varchar2_table(334) := '32342C3434323737363034342C323432383433363437342C3539333639383334342C323735363733343138372C333733333131303234392C333230343033313437392C323939393335313537332C333332393332353239382C333831353932303432372C';
wwv_flow_imp.g_varchar2_table(335) := '333339313536393631342C333932383338333930302C333531353236373237312C3536363238303731312C333934303138373630362C333435343036393533342C343131383633303237312C343030303233393939322C3131363431383437342C313931';
wwv_flow_imp.g_varchar2_table(336) := '343133383535342C3137343239323432312C323733313035353237302C3238393338303335362C333230333939333030362C3436303339333236392C3332303632303331352C3638353437313733332C3538373439363833362C3835323134323937312C';
wwv_flow_imp.g_varchar2_table(337) := '313038363739323835312C313031373033363239382C3336353534333130302C313132363030303538302C323631383239373637362C313238383033333437302C333430393835353135382C313530313530353934382C343233343530393836362C3136';
wwv_flow_imp.g_varchar2_table(338) := '30373136373931352C3938373136373436382C313831363430323331362C313234363138393539315D3B66756E6374696F6E2057652865297B76617220742C722C6E3D5B313737393033333730332C343038393233353732302C33313434313334323737';
wwv_flow_imp.g_varchar2_table(339) := '2C323232373837333539352C313031333930343234322C343237313137353732332C323737333438303736322C313539353735303132392C313335393839333131392C323931373536353133372C323630303832323932342C3732353531313139392C35';
wwv_flow_imp.g_varchar2_table(340) := '32383733343633352C343231353338393534372C313534313435393232352C3332373033333230395D2C6F3D652E6C656E6774682C613D6F2B31372B3132373E3E373C3C372C6C3D6E65772055696E743841727261792861292C693D6E657720496E7433';
wwv_flow_imp.g_varchar2_table(341) := '32417272617928313630293B6C2E7365742865292C6C5B6F5D3D3132383B76617220733D382A6F3B6C5B612D315D3D32353526732C6C5B612D325D3D733E3E3E38263235352C6C5B612D335D3D733E3E3E3136263235352C6C5B612D345D3D733E3E3E32';
wwv_flow_imp.g_varchar2_table(342) := '34263235352C6C5B612D355D3D323535264D6174682E666C6F6F7228732F34323934393637323936293B666F722876617220753D343239343936373239362C633D303B633C613B632B3D313238297B666F7228743D303B743C33323B742B2B29723D632B';
wwv_flow_imp.g_varchar2_table(343) := '342A742C695B745D3D6C5B725D3C3C32347C6C5B722B315D3C3C31367C6C5B722B325D3C3C387C6C5B722B335D3B666F7228743D33323B743C3136303B742B3D32297B76617220663D695B742D33305D2C643D695B742D32395D2C683D695B742D345D2C';
wwv_flow_imp.g_varchar2_table(344) := '703D695B742D335D2C673D28663E3E3E317C643C3C3331295E28663E3E3E387C643C3C3234295E663E3E3E372C6D3D28683E3E3E31397C703C3C3133295E28703E3E3E32397C683C3C33295E683E3E3E362C763D28703E3E3E31397C683C3C3133295E28';
wwv_flow_imp.g_varchar2_table(345) := '683E3E3E32397C703C3C33295E28703E3E3E367C683C3C3236292C623D282828643E3E3E317C663C3C3331295E28643E3E3E387C663C3C3234295E28643E3E3E377C663C3C323529293E3E3E30292B28695B742D31335D3E3E3E30292B28763E3E3E3029';
wwv_flow_imp.g_varchar2_table(346) := '2B28695B742D33315D3E3E3E30292C773D672B695B742D31345D2B6D2B695B742D33325D2B4D6174682E666C6F6F7228622F75297C303B695B745D3D772C695B742B315D3D307C627D76617220793D6E5B305D2C783D6E5B315D2C453D6E5B325D2C533D';
wwv_flow_imp.g_varchar2_table(347) := '6E5B335D2C543D6E5B345D2C433D6E5B355D2C413D6E5B365D2C4E3D6E5B375D2C503D6E5B385D2C463D6E5B395D2C7A3D6E5B31305D2C4D3D6E5B31315D2C6B3D6E5B31325D2C4F3D6E5B31335D2C4C3D6E5B31345D2C443D6E5B31355D3B666F722874';
wwv_flow_imp.g_varchar2_table(348) := '3D303B743C3136303B742B3D32297B766172206A3D28503E3E3E31347C463C3C3138295E28503E3E3E31387C463C3C3134295E28463E3E3E397C503C3C3233292C493D50267A5E7E50266B2C523D28443E3E3E30292B282828463E3E3E31347C503C3C31';
wwv_flow_imp.g_varchar2_table(349) := '38295E28463E3E3E31387C503C3C3134295E28503E3E3E397C463C3C323329293E3E3E30292B282846264D5E7E46264F293E3E3E30292B2848655B742B315D3E3E3E30292B28695B742B315D3E3E3E30292C553D4C2B6A2B492B48655B745D2B695B745D';
wwv_flow_imp.g_varchar2_table(350) := '2B4D6174682E666C6F6F7228522F75297C303B527C3D303B76617220423D282828783E3E3E32387C793C3C34295E28793E3E3E327C783C3C3330295E28793E3E3E377C783C3C323529293E3E3E30292B28287826535E7826435E532643293E3E3E30292C';
wwv_flow_imp.g_varchar2_table(351) := '5F3D2828793E3E3E32387C783C3C34295E28783E3E3E327C793C3C3330295E28783E3E3E377C793C3C323529292B287926455E7926545E452654292B4D6174682E666C6F6F7228422F75297C303B427C3D302C4C3D6B2C443D4F2C6B3D7A2C4F3D4D2C7A';
wwv_flow_imp.g_varchar2_table(352) := '3D502C4D3D463B76617220473D284E3E3E3E30292B28523E3E3E30293B503D412B552B4D6174682E666C6F6F7228472F75297C302C463D307C472C413D542C4E3D432C543D452C433D532C453D792C533D782C473D28523E3E3E30292B28423E3E3E3029';
wwv_flow_imp.g_varchar2_table(353) := '2C793D552B5F2B4D6174682E666C6F6F7228472F75297C302C783D307C477D76617220483D5B792C782C452C532C542C432C412C4E2C502C462C7A2C4D2C6B2C4F2C4C2C445D3B666F7228743D303B743C31363B742B3D32297B76617220573D286E5B74';
wwv_flow_imp.g_varchar2_table(354) := '2B315D3E3E3E30292B28485B742B315D3E3E3E30293B6E5B745D3D6E5B745D2B485B745D2B4D6174682E666C6F6F7228572F75297C302C6E5B742B315D3D307C577D7D76617220563D6E65772055696E74384172726179283634293B666F7228743D303B';
wwv_flow_imp.g_varchar2_table(355) := '743C31363B742B2B29565B342A745D3D6E5B745D3E3E3E32342C565B342A742B315D3D6E5B745D3E3E3E3136263235352C565B342A742B325D3D6E5B745D3E3E3E38263235352C565B342A742B335D3D323535266E5B745D3B72657475726E20567D7661';
wwv_flow_imp.g_varchar2_table(356) := '722056653D5B35373834302C373433392C35323338302C33333938342C343336342C333630302C36313930322C31323630362C363235382C35373635372C35343238372C33343034312C31303235322C34333337302C32303136335D2C24653D5B5B3434';
wwv_flow_imp.g_varchar2_table(357) := '3739362C31393932392C33393835382C31303035332C32303130362C34303231322C31303736315D2C5B33313538352C36333137302C36343933332C36303236372C35303933352C34303339392C31313139395D2C5B31373736332C33353532362C3134';
wwv_flow_imp.g_varchar2_table(358) := '35332C323930362C353831322C31313632342C32333234385D2C5B3838352C313737302C333534302C373038302C31343136302C32383332302C35363634305D2C5B35353336392C34313133392C32303830372C34313631342C32313832312C34333634';
wwv_flow_imp.g_varchar2_table(359) := '322C31373632315D2C5B32383438352C35363937302C34343334312C31393031392C33383033382C31343630352C32393231305D2C5B36303139352C35303739312C34303137352C31303735312C32313530322C34333030342C32343533375D2C5B3138';
wwv_flow_imp.g_varchar2_table(360) := '3338372C33363737342C333934392C373839382C31353739362C33313539322C36333138345D2C5B34373230312C32343830332C34393630362C33373830352C31343230332C32383430362C35363831325D2C5B31373832342C33353634382C31363937';
wwv_flow_imp.g_varchar2_table(361) := '2C333339342C363738382C31333537362C32373135325D2C5B34333630312C31373533392C33353037382C3535372C313131342C323232382C343435365D2C5B33303338382C36303737362C35313935332C33343234332C373037392C31343135382C32';
wwv_flow_imp.g_varchar2_table(362) := '383331365D2C5B31343132382C32383235362C35363531322C34333432352C31373235312C33343530322C373539375D2C5B31333130352C32363231302C35323432302C33353234312C3838332C313736362C333533325D2C5B343132392C383235382C';
wwv_flow_imp.g_varchar2_table(363) := '31363531362C33333033322C343635372C393331342C31383632385D5D3B66756E6374696F6E2059652865297B76617220742C722C6E3D5B5D2C6F3D66756E6374696F6E2865297B72657475726E28653C31363F2230223A2222292B652E746F53747269';
wwv_flow_imp.g_varchar2_table(364) := '6E67283136292E746F55707065724361736528297D3B666F7228743D303B743C652E6C656E6774683B742B2B297B76617220613D652E63686172436F646541742874293B6E2E707573682832353526617C7C613E3E3826323535297D766172206C3D5665';
wwv_flow_imp.g_varchar2_table(365) := '5B6E2E6C656E6774682D315D2C693D31352D6E2E6C656E6774682C733D303B666F7228743D303B743C6E2E6C656E6774683B742B2B297B76617220753D6E5B745D2C633D24655B692B2B5D3B666F7228723D303B723C373B722B2B293126752626286C5E';
wwv_flow_imp.g_varchar2_table(366) := '3D635B725D292C753E3E3D317D66756E6374696F6E20662865297B72657475726E20653E3E313426317C653C3C312633323736377D666F7228743D6E2E6C656E6774682D313B743E3D303B742D2D29733D662873295E6E5B745D3B72657475726E206F28';
wwv_flow_imp.g_varchar2_table(367) := '3235352628733D662873295E6E2E6C656E6774685E353238313129292B6F28733E3E3826323535292B6F28323535266C292B6F286C3E3E3826323535297D66756E6374696F6E20716528652C742C72297B696628212F5E5B5C7832302D5C7837455D7B31';
wwv_flow_imp.g_varchar2_table(368) := '2C31357D242F2E74657374286529297468726F77206E6577204572726F7228612822776F726450772229293B766172206E2C6F3D59652865292C6C3D6E65772055696E7438417272617928742E6C656E6774682B322A6F2E6C656E677468293B666F7228';
wwv_flow_imp.g_varchar2_table(369) := '6C2E7365742874292C6E3D303B6E3C6F2E6C656E6774683B6E2B2B296C5B742E6C656E6774682B322A6E5D3D6F2E63686172436F64654174286E293B76617220693D5765286C292C733D6E65772055696E74384172726179283638293B666F72286E3D30';
wwv_flow_imp.g_varchar2_table(370) := '3B6E3C723B6E2B2B29732E7365742869292C735B36345D3D323535266E2C735B36355D3D6E3E3E3E38263235352C735B36365D3D6E3E3E3E3136263235352C735B36375D3D6E3E3E3E3234263235352C693D57652873293B72657475726E20697D766172';
wwv_flow_imp.g_varchar2_table(371) := '2058653D2223443544434533223B66756E6374696F6E205A6528652C74297B76617220723D652E6C6162656C5769647468733B72657475726E2041727261792E6973417272617928722926264E756D62657228725B745D293E303F4E756D62657228725B';
wwv_flow_imp.g_varchar2_table(372) := '745D293A652E6C6162656C57696474687C7C33327D66756E6374696F6E204A6528652C74297B76617220723D652E68656164416C69676E7C7C742E68656164416C69676E7C7C2263656E746572223B72657475726E226175746F223D3D3D723F652E616C';
wwv_flow_imp.g_varchar2_table(373) := '69676E3A727D66756E6374696F6E204B6528652C74297B76617220723D5B5D2C6E3D5B5D2C6F3D303B72657475726E20652E666F72456163682866756E6374696F6E2865297B76617220613D65262622726F77223D3D3D652E7370616E3F742D6F3A4D61';
wwv_flow_imp.g_varchar2_table(374) := '74682E6D617828312C4D6174682E6D696E28742C4D6174682E666C6F6F72284E756D62657228652626652E7370616E29297C7C3129293B6F2B613E74262628722E70757368286E292C6E3D5B5D2C6F3D30292C6E2E70757368287B663A652C636F6C3A6F';
wwv_flow_imp.g_varchar2_table(375) := '2C7370616E3A612C656D7074793A212821657C7C21652E656D707479297D292C286F2B3D61293D3D3D74262628722E70757368286E292C6E3D5B5D2C6F3D30297D292C6E2E6C656E6774682626722E70757368286E292C727D66756E6374696F6E205165';
wwv_flow_imp.g_varchar2_table(376) := '2865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E2065262628652E656D7074797C7C652E7370616E262631213D3D652E7370616E297D297D66756E6374696F6E2065742865297B72657475726E2065';
wwv_flow_imp.g_varchar2_table(377) := '2E7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E7370616E7D2C30297D66756E6374696F6E20747428652C742C72297B72657475726E2065262628652E616C69676E7C7C652E626F6C647C7C652E636F6C6F727C7C652E';
wwv_flow_imp.g_varchar2_table(378) := '66696C6C293F7B616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E7465737428652E616C69676E7C7C2222293F652E616C69676E3A6E756C6C2C626F6C643A2121652E626F6C642C636F6C6F723A652E636F6C6F723F2428652E';
wwv_flow_imp.g_varchar2_table(379) := '636F6C6F722C742C72293A6E756C6C2C66696C6C3A652E66696C6C7C7C6E756C6C7D3A6E756C6C7D7661722072743D7B6C6566743A312C746F703A312C6E6F6E653A317D3B66756E6374696F6E206E7428652C74297B66756E6374696F6E20722872297B';
wwv_flow_imp.g_varchar2_table(380) := '72657475726E20652626766F69642030213D3D655B725D26266E756C6C213D3D655B725D26262222213D3D655B725D3F655B725D3A745B725D7D766172206E3D537472696E67287228226C6162656C506F736974696F6E22297C7C226C65667422292E74';
wwv_flow_imp.g_varchar2_table(381) := '6F4C6F7765724361736528292C6F3D7228226C6162656C416C69676E22292C613D7228226C6162656C426F6C6422292C6C3D7B706F733A72745B6E5D3F6E3A226C656674222C73697A653A4E756D626572287228226C6162656C53697A652229293E303F';
wwv_flow_imp.g_varchar2_table(382) := '4E756D626572287228226C6162656C53697A652229293A302C636F6C6F723A7228226C6162656C436F6C6F7222297C7C6E756C6C2C626F6C643A6E756C6C3D3D617C7C2131213D3D6126262266616C736522213D3D612C75707065723A22757070657222';
wwv_flow_imp.g_varchar2_table(383) := '3D3D3D537472696E67287228226C6162656C4361736522297C7C2222292E746F4C6F7765724361736528292C616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E74657374286F7C7C2222293F6F3A6E756C6C2C66696C6C3A7228';
wwv_flow_imp.g_varchar2_table(384) := '226C6162656C46696C6C22297C7C6E756C6C7D3B72657475726E206C2E7374796C65643D212821657C7C2128652E6C6162656C53697A657C7C652E6C6162656C436F6C6F727C7C766F69642030213D3D652E6C6162656C426F6C6426266E756C6C213D3D';
wwv_flow_imp.g_varchar2_table(385) := '652E6C6162656C426F6C647C7C652E6C6162656C436173657C7C652E6C6162656C416C69676E7C7C652E6C6162656C46696C6C29297C7C212128742E6C6162656C53697A657C7C766F69642030213D3D742E6C6162656C426F6C6426266E756C6C213D3D';
wwv_flow_imp.g_varchar2_table(386) := '742E6C6162656C426F6C647C7C742E6C6162656C436173657C7C742E6C6162656C416C69676E292C6C7D66756E6374696F6E206F7428652C742C722C6E297B766172206F3D7B626F6C643A742E626F6C647D3B28742E73697A657C7C72292626286F2E73';
wwv_flow_imp.g_varchar2_table(387) := '697A653D742E73697A657C7C39292C742E636F6C6F722626286F2E636F6C6F723D7B617267623A6728742E636F6C6F72297D292C652E666F6E743D6F3B76617220613D742E616C69676E7C7C28723F6E3A6E756C6C293B696628617C7C72297B76617220';
wwv_flow_imp.g_varchar2_table(388) := '6C3D7B7D3B4F626A6563742E6B65797328652E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2874297B6C5B745D3D652E616C69676E6D656E745B745D7D292C612626286C2E686F72697A6F6E74616C3D61292C72262628';
wwv_flow_imp.g_varchar2_table(389) := '6C2E766572746963616C3D22626F74746F6D22292C652E616C69676E6D656E743D6C7D742E66696C6C262628652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A672874';
wwv_flow_imp.g_varchar2_table(390) := '2E66696C6C297D7D297D66756E6374696F6E20617428652C74297B72657475726E20742E75707065723F537472696E672865292E746F55707065724361736528293A657D66756E6374696F6E206C742865297B72657475726E28652E6669656C64737C7C';
wwv_flow_imp.g_varchar2_table(391) := '5B5D292E736F6D652866756E6374696F6E2874297B72657475726E2074262621742E656D7074792626226C65667422213D3D6E7428742C65292E706F737D297D66756E6374696F6E20697428652C74297B72657475726E20652E73697A657C7C4D617468';
wwv_flow_imp.g_varchar2_table(392) := '2E6D617828352C4D6174682E726F756E6428312E372A74292F32297D66756E6374696F6E20737428652C74297B72657475726E2E333532382A697428652C74292A312E322B2E347D66756E6374696F6E2075742865297B76617220743D7B666F6E745374';
wwv_flow_imp.g_varchar2_table(393) := '796C653A652E626F6C643F22626F6C64223A226E6F726D616C227D3B72657475726E20652E73697A65262628742E666F6E7453697A653D652E73697A65292C652E636F6C6F72262628742E74657874436F6C6F723D7028652E636F6C6F7229292C652E66';
wwv_flow_imp.g_varchar2_table(394) := '696C6C262628742E66696C6C436F6C6F723D7028652E66696C6C29292C652E616C69676E262628742E68616C69676E3D652E616C69676E292C747D66756E6374696F6E20637428652C742C722C6E2C6F297B76617220613D722E6C622C6C3D697428612C';
wwv_flow_imp.g_varchar2_table(395) := '6E292C693D2E333532382A6C3B696628612E66696C6C297B76617220733D7028612E66696C6C293B652E73657446696C6C436F6C6F7228735B305D2C735B315D2C735B325D292C652E7265637428742E782B2E312C742E792B2E312C742E77696474682D';
wwv_flow_imp.g_varchar2_table(396) := '2E322C6F2B312E322A692B2E312C224622297D76617220753D7028612E636F6C6F727C7C222330303030303022292C633D4D6174682E6D617828352C742E77696474682D322A6F293B652E736574466F6E74282268656C766574696361222C612E626F6C';
wwv_flow_imp.g_varchar2_table(397) := '643F22626F6C64223A226E6F726D616C22292C652E736574466F6E7453697A65286C292C652E73657454657874436F6C6F7228755B305D2C755B315D2C755B325D293B76617220663D227269676874223D3D3D722E616C69676E3F742E782B742E776964';
wwv_flow_imp.g_varchar2_table(398) := '74682D6F3A2263656E746572223D3D3D722E616C69676E3F742E782B742E77696474682F323A742E782B6F3B652E7465787428652E73706C697454657874546F53697A6528537472696E6728722E74657874292C63295B305D7C7C22222C662C742E792B';
wwv_flow_imp.g_varchar2_table(399) := '6F2B2E39352A692C7B616C69676E3A227269676874223D3D3D722E616C69676E7C7C2263656E746572223D3D3D722E616C69676E3F722E616C69676E3A226C656674227D292C652E736574466F6E74282268656C766574696361222C226E6F726D616C22';
wwv_flow_imp.g_varchar2_table(400) := '292C652E73657454657874436F6C6F7228302C302C30297D66756E6374696F6E20667428652C74297B72657475726E7B73697A653A652E73697A657C7C31342C73756253697A653A652E7375627469746C6553697A657C7C392C726967687453697A653A';
wwv_flow_imp.g_varchar2_table(401) := '652E726967687453697A657C7C392C666F6E743A715B4B28652E666F6E74295D2C66696C6C3A652E66696C6C7C7C742E7072696D6172792C636F6C6F723A652E636F6C6F727C7C742E68656164546578747D7D66756E6374696F6E20647428652C742C72';
wwv_flow_imp.g_varchar2_table(402) := '297B766172206E3D5628652C74295B305D7C7C7B7D2C6F3D28652E6669656C64737C7C652E6974656D737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E2065262621652E656D70747926262821652E7768656E7C7C572865';
wwv_flow_imp.g_varchar2_table(403) := '2E7768656E2C742C6E29297D292E6D61702866756E6374696F6E2865297B72657475726E7B6C6162656C3A4728652E6C6162656C2C742C6E292C76616C75653A4D6528652C742C6E292C636F6C6F723A652E636F6C6F723F2428652E636F6C6F722C742C';
wwv_flow_imp.g_varchar2_table(404) := '6E293A6E756C6C7D7D293B72657475726E7B6974656D733A6F2C6E3A4D6174682E6D617828312C4D6174682E6D696E28362C4E756D62657228652E636F6C756D6E73297C7C4D6174682E6D696E286F2E6C656E6774682C36297C7C3129292C66696C6C3A';
wwv_flow_imp.g_varchar2_table(405) := '652E66696C6C7C7C2223463146344632222C616363656E743A766F696420303D3D3D652E616363656E743F722E7072696D6172793A652E616363656E742C6C6162656C436F6C6F723A652E6C6162656C436F6C6F727C7C2223373837383738222C76616C';
wwv_flow_imp.g_varchar2_table(406) := '7565436F6C6F723A652E76616C7565436F6C6F727C7C722E7072696D6172792C6C6162656C53697A653A652E6C6162656C53697A657C7C372C73697A653A652E73697A657C7C31312C636172644761703A766F69642030213D3D652E636172644761703F';
wwv_flow_imp.g_varchar2_table(407) := '4E756D62657228652E63617264476170293A337D7D66756E6374696F6E2068742865297B76617220743D7B7D3B72657475726E5B226C656674222C2263656E746572222C227269676874225D2E666F72456163682866756E6374696F6E2872297B766172';
wwv_flow_imp.g_varchar2_table(408) := '206E3D655B725D3B6966286E756C6C213D6E26262222213D3D6E297B766172206F3D226F626A65637422213D747970656F66206E7C7C41727261792E69734172726179286E293F7B746578743A6E7D3A6E2C613D41727261792E69734172726179286F2E';
wwv_flow_imp.g_varchar2_table(409) := '74657874293F6F2E746578742E6A6F696E28225C6E22293A6F2E746578743B6E756C6C213D6126262222213D3D61262628745B725D3D7B746578743A537472696E672861292C73697A653A4E756D626572286F2E73697A657C7C652E73697A65297C7C38';
wwv_flow_imp.g_varchar2_table(410) := '2C626F6C643A766F69642030213D3D6F2E626F6C643F21216F2E626F6C643A2121652E626F6C642C636F6C6F723A6F2E636F6C6F727C7C652E636F6C6F727C7C2223303030303030227D297D7D292C747D66756E6374696F6E2070742865297B76617220';
wwv_flow_imp.g_varchar2_table(411) := '743D537472696E6728652E696D6167652626652E696D6167652E616C69676E7C7C2222292E746F4C6F7765724361736528293B72657475726E227269676874223D3D3D747C7C2263656E746572223D3D3D743F743A226C656674227D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(412) := '20677428652C74297B69662821652E696D6167652972657475726E206E756C6C3B76617220723D6C6528652E696D616765292C6E3D6A7428722C74293B696628216E2972657475726E206E756C6C3B722E77696474687C7C722E6865696768747C7C2872';
wwv_flow_imp.g_varchar2_table(413) := '2E6865696768743D4D6174682E6D617828342C284E756D62657228652E686569676874297C7C3132292D3229293B766172206F3D497428722C6E293B72657475726E7B696D3A6E2C773A6F2E772C683A6F2E687D7D766172206D743D7B73756D3A312C61';
wwv_flow_imp.g_varchar2_table(414) := '76673A312C6D696E3A312C6D61783A312C636F756E743A317D3B66756E6374696F6E20767428652C74297B76617220723D4E756D6265722865292C6E3D4E756D6265722874293B72657475726E22223D3D3D657C7C22223D3D3D747C7C69734E614E2872';
wwv_flow_imp.g_varchar2_table(415) := '297C7C69734E614E286E293F653C743F2D313A653E743F313A303A722D6E7D66756E6374696F6E20627428652C74297B72657475726E28657C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626227069766F74223D3D3D652E';
wwv_flow_imp.g_varchar2_table(416) := '747970653F66756E6374696F6E28652C74297B76617220723D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6E3D5628652C74292C6F3D742E545B725D7C7C7B7D2C6C3D2841727261792E697341727261792865';
wwv_flow_imp.g_varchar2_table(417) := '2E726F7773293F652E726F77733A5B652E726F77735D292E66696C74657228426F6F6C65616E292E6D61702866756E6374696F6E2865297B72657475726E20537472696E672865292E746F55707065724361736528297D292C693D537472696E6728652E';
wwv_flow_imp.g_varchar2_table(418) := '636F6C737C7C2222292E746F55707065724361736528292C733D537472696E6728652E76616C75657C7C2222292E746F55707065724361736528292C753D537472696E6728652E666E7C7C2273756D22292E746F4C6F7765724361736528293B6D745B75';
wwv_flow_imp.g_varchar2_table(419) := '5D7C7C28753D2273756D22293B76617220633D5B5D2C663D7B7D2C643D5B5D2C683D7B7D2C703D66756E6374696F6E2865297B72657475726E22636F756E7422213D3D757C7C733F796528652C732C75293A652E6C656E6774687D3B6966286E2E666F72';
wwv_flow_imp.g_varchar2_table(420) := '456163682866756E6374696F6E2865297B76617220743D537472696E67286E756C6C3D3D3D655B695D7C7C766F696420303D3D3D655B695D3F22223A655B695D293B4F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E6361';
wwv_flow_imp.g_varchar2_table(421) := '6C6C28662C74297C7C28665B745D3D652C632E70757368287429293B76617220723D6C2E6D61702866756E6374696F6E2874297B72657475726E20537472696E67286E756C6C3D3D3D655B745D7C7C766F696420303D3D3D655B745D3F22223A655B745D';
wwv_flow_imp.g_varchar2_table(422) := '297D292E6A6F696E28220122292C6E3D685B725D3B6E7C7C286E3D685B725D3D7B723A652C62793A7B7D2C616C6C3A5B5D7D2C642E70757368286E29292C286E2E62795B745D3D6E2E62795B745D7C7C5B5D292E707573682865292C6E2E616C6C2E7075';
wwv_flow_imp.g_varchar2_table(423) := '73682865297D292C41727261792E6973417272617928652E636F6C4F7264657229297B76617220673D652E636F6C4F726465722E6D617028537472696E67292E66696C7465722866756E6374696F6E2865297B72657475726E204F626A6563742E70726F';
wwv_flow_imp.g_varchar2_table(424) := '746F747970652E6861734F776E50726F70657274792E63616C6C28662C65297D293B633D672E636F6E63617428632E66696C7465722866756E6374696F6E2865297B72657475726E20672E696E6465784F662865293C307D29297D656C736520652E736F';
wwv_flow_imp.g_varchar2_table(425) := '7274436F6C732626632E736F7274287674293B4E756D62657228652E6D6178436F6C73293E30262628633D632E736C69636528302C4E756D62657228652E6D6178436F6C732929293B766172206D3D6C652865292C763D7B7D2C623D5B5D2C773D213121';
wwv_flow_imp.g_varchar2_table(426) := '3D3D652E726F77546F74616C732626632E6C656E6774683E313B5B22726F7773222C22636F6C73222C2276616C7565222C22666E222C22636F6C4F72646572222C22736F7274436F6C73222C22636F6C4C6162656C222C22726F774C6162656C73222C22';
wwv_flow_imp.g_varchar2_table(427) := '726F77546F74616C73222C22636F6C546F74616C73222C22746F74616C4C6162656C222C22656D707479222C226D6178436F6C73222C2266696C746572225D2E666F72456163682866756E6374696F6E2865297B64656C657465206D5B655D7D292C6D2E';
wwv_flow_imp.g_varchar2_table(428) := '747970653D227461626C61222C6C2E666F72456163682866756E6374696F6E28742C72297B765B745D3D6F5B745D7C7C225641524348415232223B766172206E3D28652E726F774C6162656C737C7C5B5D295B725D3B622E7075736828766F6964203021';
wwv_flow_imp.g_varchar2_table(429) := '3D3D6E3F7B636F6C3A742C6C6162656C3A6E7D3A7B636F6C3A747D297D293B76617220793D652E666D747C7C2822636F756E74223D3D3D753F22696E74223A766F69642030293B696628632E666F72456163682866756E6374696F6E28722C6E297B7661';
wwv_flow_imp.g_varchar2_table(430) := '72206F3D224E52505F222B286E2B31293B765B6F5D3D224E554D424552222C622E70757368287B636F6C3A6F2C6C6162656C3A4728652E636F6C4C6162656C7C7C227B222B692B227D222C742C665B725D292C666D743A792C616C69676E3A2272696768';
wwv_flow_imp.g_varchar2_table(431) := '74227D297D292C77262628762E4E52505F544F54414C3D224E554D424552222C622E70757368287B636F6C3A224E52505F544F54414C222C6C6162656C3A652E746F74616C4C6162656C7C7C612822746F74616C22292C666D743A792C626F6C643A2130';
wwv_flow_imp.g_varchar2_table(432) := '2C616C69676E3A227269676874227D29292C6D2E636F6C756D6E733D622C6D2E5F74797065733D762C6D2E5F726F77733D642E6D61702866756E6374696F6E2874297B76617220723D7B7D3B72657475726E206C2E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(433) := '6E2865297B725B655D3D742E725B655D7D292C632E666F72456163682866756E6374696F6E286E2C6F297B725B224E52505F222B286F2B31295D3D742E62795B6E5D3F7028742E62795B6E5D293A766F69642030213D3D652E656D7074793F652E656D70';
wwv_flow_imp.g_varchar2_table(434) := '74793A6E756C6C7D292C77262628722E4E52505F544F54414C3D7028742E616C6C29292C727D292C2131213D3D652E636F6C546F74616C732626216D2E746F74616C73297B76617220783D22636F756E74223D3D3D753F2273756D223A753B6D2E746F74';
wwv_flow_imp.g_varchar2_table(435) := '616C733D622E736C696365286C2E6C656E677468292E6D61702866756E6374696F6E2865297B72657475726E7B636F6C3A652E636F6C2C666E3A787D7D297D72657475726E20766F696420303D3D3D6D2E746F74616C734C6162656C2626652E746F7461';
wwv_flow_imp.g_varchar2_table(436) := '6C4C6162656C2626286D2E746F74616C734C6162656C3D652E746F74616C4C6162656C292C6D7D28652C74293A657D297D66756E6374696F6E20777428652C742C72297B766172206E3D66756E6374696F6E2865297B72657475726E2821652E666F726D';
wwv_flow_imp.g_varchar2_table(437) := '6174737C7C652E666F726D6174732E696E6465784F662874293E3D302926262821727C7C437428652C7229297D2C6F3D28652E73656374696F6E737C7C5B5D292E66696C746572286E293B72657475726E20723F6274286365286F292E66696C74657228';
wwv_flow_imp.g_varchar2_table(438) := '6E292C72293A6F7D7661722079743D7B66696368613A312C666F726D756C6172696F3A312C7461726A657461733A312C746578746F3A312C696D6167656E3A312C636F6469676F3A312C616C657274613A312C6C696E65613A312C7461626C613A312C67';
wwv_flow_imp.g_varchar2_table(439) := '72616669636F3A312C6573706163696F3A312C7069766F743A312C636F6C756D6E61733A312C677275706F3A317D2C78743D7B6C696E65613A312C6573706163696F3A312C636F6C756D6E61733A312C677275706F3A317D3B66756E6374696F6E204574';
wwv_flow_imp.g_varchar2_table(440) := '28652C742C72297B766172206E3D66756E6374696F6E2865297B72657475726E2065262679745B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30292626437428652C72297D3B72657475';
wwv_flow_imp.g_varchar2_table(441) := '726E206274286365282841727261792E6973417272617928652E73656374696F6E73293F652E73656374696F6E733A5B5D292E66696C746572286E292E6D61702866756E6374696F6E2874297B696628742E736F757263657C7C21652E736F757263657C';
wwv_flow_imp.g_varchar2_table(442) := '7C78745B742E747970655D2972657475726E20743B76617220723D6C652874293B72657475726E20722E736F757263653D652E736F757263652C727D29292E66696C746572286E292C72297D66756E6374696F6E20537428652C74297B69662821652E65';
wwv_flow_imp.g_varchar2_table(443) := '6163687C7C21652E736F757263652972657475726E5B7B6374783A742C7375663A22227D5D3B76617220723D537472696E6728652E736F75726365292E746F55707065724361736528292C6E3D5628652C74292C6F3D652E6C696E6B7C7C7B7D3B726574';
wwv_flow_imp.g_varchar2_table(444) := '75726E204E756D62657228652E6D6178293E302626286E3D6E2E736C69636528302C4E756D62657228652E6D61782929292C6E2E6D61702866756E6374696F6E28652C6E297B76617220612C6C3D6C652874292C693D6C6528742E646F637C7C7B7D293B';
wwv_flow_imp.g_varchar2_table(445) := '666F72286120696E206C2E533D6C6528742E53292C6C2E535B725D3D5B655D2C4F626A6563742E6B657973286F292E666F72456163682866756E6374696F6E2872297B766172206E3D6F5B725D7C7C7B7D2C613D537472696E672872292E746F55707065';
wwv_flow_imp.g_varchar2_table(446) := '724361736528293B6C2E535B615D3D28742E535B615D7C7C5B5D292E66696C7465722866756E6374696F6E2874297B72657475726E204F626A6563742E6B657973286E292E65766572792866756E6374696F6E2872297B72657475726E20537472696E67';
wwv_flow_imp.g_varchar2_table(447) := '28745B722E746F55707065724361736528295D293D3D3D537472696E6728655B537472696E67286E5B725D292E746F55707065724361736528295D297D297D297D292C65294F626A6563742E70726F746F747970652E6861734F776E50726F7065727479';
wwv_flow_imp.g_varchar2_table(448) := '2E63616C6C28652C6129262628695B615D3D655B615D293B72657475726E206C2E646F633D692C7B6374783A6C2C7375663A225F222B286E2B31297D7D297D66756E6374696F6E20547428652C742C722C6E297B766172206F3D2841727261792E697341';
wwv_flow_imp.g_varchar2_table(449) := '7272617928652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33292C613D6F2E6C656E6774683B69662821612972657475726E5B5D3B766172206C3D6F2E6D61702866756E6374696F6E28742C72297B766172206E3D4E756D62657228';
wwv_flow_imp.g_varchar2_table(450) := '28652E7769647468737C7C5B5D295B725D293B72657475726E206E3E303F6E3A3130302F617D292C693D6C2E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C733D766F69642030213D3D652E636F6C4761703F';
wwv_flow_imp.g_varchar2_table(451) := '4E756D62657228652E636F6C476170293A342C753D6E2D732A28612D31292C633D303B72657475726E206F2E6D61702866756E6374696F6E28652C6E297B766172206F3D752A6C5B6E5D2F692C613D6365282841727261792E697341727261792865293F';
wwv_flow_imp.g_varchar2_table(452) := '653A5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30297D29292E66696C7465722866756E6374696F6E2865297B7265747572';
wwv_flow_imp.g_varchar2_table(453) := '6E2065262679745B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30292626437428652C72297D292E6D61702866756E6374696F6E2865297B72657475726E2066756E6374696F6E28652C';
wwv_flow_imp.g_varchar2_table(454) := '74297B76617220722C6E3D7B7D3B666F72287220696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C72292626286E5B725D3D655B725D293B6966285B2278222C2279222C227831222C227931';
wwv_flow_imp.g_varchar2_table(455) := '222C227832222C227932225D2E666F72456163682866756E6374696F6E2865297B64656C657465206E5B655D7D292C22696D6167656E223D3D3D6E2E747970652626286E2E5F6D6178573D74292C226772616669636F223D3D3D6E2E74797065297B7661';
wwv_flow_imp.g_varchar2_table(456) := '72206F3D6E2E77696474687C7C3132302C613D6E2E6865696768747C7C37303B6F3E742626286E2E77696474683D742C6E2E6865696768743D612A742F6F297D72657475726E22636F6469676F223D3D3D6E2E74797065262628227172223D3D3D537472';
wwv_flow_imp.g_varchar2_table(457) := '696E67286E2E6B696E647C7C22717222292E746F4C6F7765724361736528292626286E2E73697A657C7C3330293E742626286E2E73697A653D74292C6E2E776964746826266E2E77696474683E742626286E2E77696474683D7429292C28226C696E6561';
wwv_flow_imp.g_varchar2_table(458) := '223D3D3D6E2E747970657C7C22746578746F223D3D3D6E2E747970652926266E2E776964746826266E2E77696474683E742626286E2E77696474683D74292C6E7D28652C6F297D293B613D627428612C72293B76617220663D7B783A632C773A6F2C7365';
wwv_flow_imp.g_varchar2_table(459) := '63733A617D3B72657475726E20632B3D6F2B732C667D297D66756E6374696F6E20437428652C74297B72657475726E22616C65727461223D3D3D652E747970657C7C21652E7768656E7C7C5728652E7768656E2C742C6E756C6C297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(460) := '2041742865297B76617220742C723D7B7D3B666F72287420696E206429725B745D3D645B745D3B766172206E3D652E706167652626652E706167652E7468656D657C7C7B7D3B666F72287420696E206E29725B745D3D6E5B745D3B72657475726E20727D';
wwv_flow_imp.g_varchar2_table(461) := '766172204E743D7B7D2C50743D7B7D2C46743D7B7D3B766172207A743D7B7072696E743A312C6D6F646966793A312C636F70793A312C22616E6E6F742D666F726D73223A317D3B66756E6374696F6E204D742865297B76617220743D77696E646F772E61';
wwv_flow_imp.g_varchar2_table(462) := '7065782626617065782E656E767C7C7B7D3B72657475726E20537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C2222292E7265706C6163652822234150505F494D414745532322';
wwv_flow_imp.g_varchar2_table(463) := '2C742E4150505F46494C45537C7C2222292E7265706C616365282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C616365282223494D4147455F50524546495823222C742E41504558';
wwv_flow_imp.g_varchar2_table(464) := '5F46494C45537C7C2222297D66756E6374696F6E206B742865297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B315D2972657475726E7B773A28745B31365D3C3C32347C745B3137';
wwv_flow_imp.g_varchar2_table(465) := '5D3C3C31367C745B31385D3C3C387C745B31395D293E3E3E302C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22706E67227D3B6966283235353D3D3D745B305D26263231363D3D';
wwv_flow_imp.g_varchar2_table(466) := '3D745B315D29666F722876617220723D323B723C742E6C656E6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B335D3B6966286E3E3D31393226266E3C3D323037262631393621';
wwv_flow_imp.g_varchar2_table(467) := '3D3D6E2626323030213D3D6E2626323034213D3D6E2972657475726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A7067227D3B722B3D322B6F7D656C736520722B2B3B7468726F7720';
wwv_flow_imp.g_varchar2_table(468) := '6E6577204572726F7228612822696D67466D742229297D66756E6374696F6E204F742865297B666F722876617220743D6E65772055696E743841727261792865292C723D22222C6E3D303B6E3C742E6C656E6774683B6E2B3D333237363829722B3D5374';
wwv_flow_imp.g_varchar2_table(469) := '72696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E7375626172726179286E2C6E2B333237363829293B72657475726E2062746F612872297D66756E6374696F6E204C742865297B72657475726E2050726F6D6973652E616C6C';
wwv_flow_imp.g_varchar2_table(470) := '2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B65262622696D6167656E223D3D3D652E747970652626652E75726C262621652E6669656C';
wwv_flow_imp.g_varchar2_table(471) := '642626742E7075736828652E75726C292C65262622636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F72456163682872292C65262675655B652E747970655D2626722828652E6669656C64737C7C5B5D292E6D6170';
wwv_flow_imp.g_varchar2_table(472) := '2866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C65262622677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C652626227461626C61223D3D3D652E74797065262628652E636F6C756D6E73';
wwv_flow_imp.g_varchar2_table(473) := '7C7C5B5D292E666F72456163682866756E6374696F6E2865297B652626652E63656C6C262622696D6167656E223D3D3D652E63656C6C2E747970652626652E63656C6C2E75726C262621652E63656C6C2E6669656C642626537472696E6728652E63656C';
wwv_flow_imp.g_varchar2_table(474) := '6C2E75726C292E696E6465784F6628227B22293C302626742E7075736828652E63656C6C2E75726C297D297D297D7228652E73656374696F6E73292C652E62617463682626652E62617463682E73756D6D6172792626287228652E62617463682E73756D';
wwv_flow_imp.g_varchar2_table(475) := '6D6172792E73656374696F6E73292C652E62617463682E73756D6D6172792E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F75742E73656374696F6E7329293B766172206E3D652E706167654865616465722626652E706167';
wwv_flow_imp.g_varchar2_table(476) := '654865616465722E696D6167653B72657475726E206E26266E2E75726C2626216E2E6669656C642626742E70757368286E2E75726C292C747D2865292E6D61702866756E6374696F6E2865297B76617220743D4D742865293B72657475726E204E745B74';
wwv_flow_imp.g_varchar2_table(477) := '5D3F6E756C6C3A666574636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228612822696D674C6F6164222C742C';
wwv_flow_imp.g_varchar2_table(478) := '652E73746174757329293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B76617220723D6B742865293B4E745B745D3D7B6275663A652C773A722E772C683A722E682C6578743A722E6578742C';
wwv_flow_imp.g_varchar2_table(479) := '646174613A22646174613A696D6167652F222B28226A7067223D3D3D722E6578743F226A706567223A22706E6722292B223B6261736536342C222B4F742865297D7D297D29297D66756E6374696F6E2044742865297B76617220743D537472696E672865';
wwv_flow_imp.g_varchar2_table(480) := '292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C2222293B69662821742972657475726E206E756C6C3B76617220723D226236343A222B742E6C656E6774682B223A222B742E737562737472';
wwv_flow_imp.g_varchar2_table(481) := '28302C3634292B742E737562737472282D3634293B6966284E745B725D2972657475726E204E745B725D3B666F7228766172206E3D61746F622874292C6F3D6E65772055696E74384172726179286E2E6C656E677468292C613D303B613C6E2E6C656E67';
wwv_flow_imp.g_varchar2_table(482) := '74683B612B2B296F5B615D3D6E2E63686172436F646541742861293B766172206C3D6B74286F2E627566666572293B72657475726E204E745B725D3D7B6275663A6F2E6275666665722C773A6C2E772C683A6C2E682C6578743A6C2E6578742C64617461';
wwv_flow_imp.g_varchar2_table(483) := '3A22646174613A696D6167652F222B28226A7067223D3D3D6C2E6578743F226A706567223A22706E6722292B223B6261736536342C222B747D2C4E745B725D7D66756E6374696F6E206A7428652C74297B696628652E6669656C64297B76617220723D28';
wwv_flow_imp.g_varchar2_table(484) := '28652E736F757263653F5628652C74295B305D3A742E646F63297C7C7B7D295B537472696E6728652E6669656C64292E746F55707065724361736528295D3B7472797B72657475726E20723F44742872293A6E756C6C7D63617463682874297B72657475';
wwv_flow_imp.g_varchar2_table(485) := '726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28612822696D67426164222C652E6669656C64292C74292C6E756C6C7D7D72657475726E204E745B4D7428652E75726C295D7C7C6E756C6C7D66756E6374696F6E20497428';
wwv_flow_imp.g_varchar2_table(486) := '652C74297B76617220723D652E77696474687C7C34302C6E3D652E6865696768747C7C722A742E682F742E773B72657475726E21652E77696474682626652E686569676874262628723D6E2A742E772F742E68292C652E5F6D6178572626723E652E5F6D';
wwv_flow_imp.g_varchar2_table(487) := '6178572626286E3D6E2A652E5F6D6178572F722C723D652E5F6D617857292C7B773A722C683A6E7D7D66756E6374696F6E2052742865297B666F722876617220743D61746F622865292C723D6E65772055696E7438417272617928742E6C656E67746829';
wwv_flow_imp.g_varchar2_table(488) := '2C6E3D303B6E3C742E6C656E6774683B6E2B2B29725B6E5D3D742E63686172436F64654174286E293B72657475726E20722E6275666665727D66756E6374696F6E20557428652C742C72297B72657475726E7B6275663A527428652E7265706C61636528';
wwv_flow_imp.g_varchar2_table(489) := '2F5E646174613A5B5E2C5D2A2C2F2C222229292C646174613A652C773A742C683A722C6578743A22706E67227D7D66756E6374696F6E20427428652C74297B69662822756E646566696E6564223D3D747970656F6620646F63756D656E747C7C21646F63';
wwv_flow_imp.g_varchar2_table(490) := '756D656E742E637265617465456C656D656E74297468726F77206E6577204572726F722861282263616E7661732229293B76617220723D646F63756D656E742E637265617465456C656D656E74282263616E76617322293B72657475726E20722E776964';
wwv_flow_imp.g_varchar2_table(491) := '74683D652C722E6865696768743D742C727D766172205F743D6E756C6C3B66756E6374696F6E2047742865297B72657475726E5B653E3E3E3234263235352C653E3E3E3136263235352C653E3E3E38263235352C32353526655D7D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(492) := '487428652C74297B76617220723D5B652E63686172436F646541742830292C652E63686172436F646541742831292C652E63686172436F646541742832292C652E63686172436F646541742833295D2C6E3D6E65772055696E7438417272617928342B74';
wwv_flow_imp.g_varchar2_table(493) := '2E6C656E677468293B6E2E73657428722C30292C6E2E73657428742C34293B766172206F3D6E65772055696E743841727261792831322B742E6C656E677468293B72657475726E206F2E73657428477428742E6C656E677468292C30292C6F2E73657428';
wwv_flow_imp.g_varchar2_table(494) := '6E2C34292C6F2E7365742847742866756E6374696F6E2865297B696628215F74297B5F743D5B5D3B666F722876617220743D303B743C3235363B742B2B297B666F722876617220723D742C6E3D303B6E3C383B6E2B2B29723D3126723F33393838323932';
wwv_flow_imp.g_varchar2_table(495) := '3338345E723E3E3E313A723E3E3E313B5F745B745D3D723E3E3E307D7D666F7228766172206F3D343239343936373239352C613D303B613C652E6C656E6774683B612B2B296F3D5F745B32353526286F5E655B615D295D5E6F3E3E3E383B72657475726E';
wwv_flow_imp.g_varchar2_table(496) := '28343239343936373239355E6F293E3E3E307D286E29292C382B742E6C656E677468292C6F7D66756E6374696F6E20577428652C742C722C6E297B766172206F2C612C6C3D4D6174682E6365696C28652F38292B312C693D6E65772055696E7438417272';
wwv_flow_imp.g_varchar2_table(497) := '6179286C2A74293B666F7228613D303B613C743B612B2B29666F72286F3D303B6F3C653B6F2B2B2972286F2C6129262628695B612A6C2B312B286F3E3E33295D7C3D3132383E3E2837266F29293B76617220732C753D4D6174682E6365696C28692E6C65';
wwv_flow_imp.g_varchar2_table(498) := '6E6774682F3635353335292C633D6E65772055696E7438417272617928322B692E6C656E6774682B352A752B34292C663D322C643D312C683D303B666F7228635B305D3D3132302C635B315D3D312C733D303B733C753B732B2B297B76617220673D3635';
wwv_flow_imp.g_varchar2_table(499) := '3533352A732C6D3D4D6174682E6D696E2836353533352C692E6C656E6774682D67293B635B662B2B5D3D733D3D3D752D313F313A302C635B662B2B5D3D323535266D2C635B662B2B5D3D6D3E3E382C635B662B2B5D3D323535267E6D2C635B662B2B5D3D';
wwv_flow_imp.g_varchar2_table(500) := '7E6D3E3E38263235352C632E73657428692E737562617272617928672C672B6D292C66292C662B3D6D7D666F7228733D303B733C692E6C656E6774683B732B2B29683D28682B28643D28642B695B735D2925363535323129292536353532313B632E7365';
wwv_flow_imp.g_varchar2_table(501) := '742847742828683C3C31367C64293E3E3E30292C66293B76617220763D6E65772055696E74384172726179283133292C623D70286E7C7C222330303030303022293B762E7365742847742865292C30292C762E7365742847742874292C34292C765B385D';
wwv_flow_imp.g_varchar2_table(502) := '3D312C765B395D3D333B76617220773D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31332C31302C32362C31305D292C4874282249484452222C76292C48742822504C5445222C6E65772055696E74384172726179285B32';
wwv_flow_imp.g_varchar2_table(503) := '35352C3235352C3235352C625B305D2C625B315D2C625B325D5D29292C4874282249444154222C63292C4874282249454E44222C6E65772055696E74384172726179283029295D2C793D772E7265647563652866756E6374696F6E28652C74297B726574';
wwv_flow_imp.g_varchar2_table(504) := '75726E20652B742E6C656E6774687D2C30292C783D6E65772055696E743841727261792879292C453D303B72657475726E20772E666F72456163682866756E6374696F6E2865297B782E73657428652C45292C452B3D652E6C656E6774687D292C7B6275';
wwv_flow_imp.g_varchar2_table(505) := '663A782E6275666665722C646174613A22646174613A696D6167652F706E673B6261736536342C222B4F7428782E627566666572292C773A652C683A742C6578743A22706E67227D7D7661722056743D2232313232323220323232313232203232323232';
wwv_flow_imp.g_varchar2_table(506) := '31203132313232332031323133323220313331323232203132323231332031323233313220313332323132203232313231332032323133313220323331323132203131323233322031323231333220313232323331203131333232322031323331323220';
wwv_flow_imp.g_varchar2_table(507) := '31323332323120323233323131203232313133322032323132333120323133323132203232333131322033313231333120333131323232203332313132322033323132323120333132323132203332323131322033323232313120323132313233203231';
wwv_flow_imp.g_varchar2_table(508) := '32333231203233323132312031313133323320313331313233203133313332312031313233313320313332313133203133323331312032313133313320323331313133203233313331312031313231333320313132333331203133323133312031313331';
wwv_flow_imp.g_varchar2_table(509) := '32332031313333323120313333313231203331333132312032313133333120323331313331203231333131332032313333313120323133313331203331313132332033313133323120333331313231203331323131332033313233313120333332313131';
wwv_flow_imp.g_varchar2_table(510) := '20333134313131203232313431312034333131313120313131323234203131313432322031323131323420313231343231203134313132322031343132323120313132323134203131323431322031323231313420313232343131203134323131322031';
wwv_flow_imp.g_varchar2_table(511) := '34323231312032343132313120323231313134203431333131312032343131313220313334313131203131313234322031323131343220313231323431203131343231322031323431313220313234323131203431313231322034323131313220343231';
wwv_flow_imp.g_varchar2_table(512) := '32313120323132313431203231343132312034313231323120313131313433203131313334312031333131343120313134313133203131343331312034313131313320343131333131203131333134312031313431333120333131313431203431313133';
wwv_flow_imp.g_varchar2_table(513) := '312032313134313220323131323134203231313233322032333331313132222E73706C697428222022293B66756E6374696F6E2024742865297B653D537472696E672865292E7265706C616365282F5B5E5C7832302D5C7837455D2F672C223F22293B66';
wwv_flow_imp.g_varchar2_table(514) := '6F722876617220742C723D5B5D2C6E3D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B743D6E2E657865632865293B29696628745B315D7C7C2F5E5C642B242F2E746573742865292626652E6C656E67746825323D3D30297B76';
wwv_flow_imp.g_varchar2_table(515) := '6172206F3D745B305D2C613D6F2E6C656E6774682D6F2E6C656E67746825323B722E70757368287B7365743A2243222C743A6F2E73756273747228302C61297D292C613C6F2E6C656E6774682626722E70757368287B7365743A2242222C743A6F2E7375';
wwv_flow_imp.g_varchar2_table(516) := '627374722861297D297D656C736520722E70757368287B7365743A2242222C743A745B305D7D293B766172206C3D5B5D2C693D6E756C6C3B722E666F72456163682866756E6374696F6E2865297B6966286E756C6C3D3D3D693F6C2E7075736828224322';
wwv_flow_imp.g_varchar2_table(517) := '3D3D3D652E7365743F3130353A313034293A69213D3D652E73657426266C2E70757368282243223D3D3D652E7365743F39393A313030292C693D652E7365742C2243223D3D3D652E73657429666F722876617220743D303B743C652E742E6C656E677468';
wwv_flow_imp.g_varchar2_table(518) := '3B742B3D32296C2E70757368282B652E742E73756273747228742C3229293B656C736520666F722876617220723D303B723C652E742E6C656E6774683B722B2B296C2E7075736828652E742E63686172436F646541742872292D3332297D293B666F7228';
wwv_flow_imp.g_varchar2_table(519) := '76617220733D6C5B305D2C753D313B753C6C2E6C656E6774683B752B2B29732B3D752A6C5B755D3B6C2E707573682873253130332C313036293B76617220633D5B5D3B72657475726E206C2E666F72456163682866756E6374696F6E2865297B56745B65';
wwv_flow_imp.g_varchar2_table(520) := '5D2E73706C6974282222292E666F72456163682866756E6374696F6E28652C74297B666F722876617220723D303B723C2B653B722B2B29632E70757368287425323D3D30297D297D292C637D66756E6374696F6E20597428652C742C72297B766172206E';
wwv_flow_imp.g_varchar2_table(521) := '3D727C7C28652E736F757263653F5628652C74295B305D3A6E756C6C293B69662821722626652E736F757263652626216E2972657475726E206E756C6C3B766172206F3D4728652E76616C75652C742C6E293B696628216F2972657475726E206E756C6C';
wwv_flow_imp.g_varchar2_table(522) := '3B766172206C3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292C693D652E636F6C6F727C7C2223303030303030223B696628227172223D3D3D6C297B76617220733D66756E6374696F6E28652C74297B76617220';
wwv_flow_imp.g_varchar2_table(523) := '723D77696E646F772E7172636F64653B6966282172297468726F77206E6577204572726F722861282271724C69622229293B722E737472696E67546F427974657346756E63732626722E737472696E67546F427974657346756E63735B225554462D3822';
wwv_flow_imp.g_varchar2_table(524) := '5D262628722E737472696E67546F42797465733D722E737472696E67546F427974657346756E63735B225554462D38225D293B766172206E3D7228302C537472696E6728747C7C224D22292E746F5570706572436173652829293B72657475726E206E2E';
wwv_flow_imp.g_varchar2_table(525) := '6164644461746128537472696E67286529292C6E2E6D616B6528292C7B6E3A6E2E6765744D6F64756C65436F756E7428292C6461726B3A66756E6374696F6E28652C74297B72657475726E206E2E69734461726B28742C65297D7D7D286F2C652E656363';
wwv_flow_imp.g_varchar2_table(526) := '292C753D652E73697A657C7C33303B72657475726E7B6B696E643A227172222C746578743A6F2C636F6C733A732E6E2C726F77733A732E6E2C6461726B3A732E6461726B2C773A752C683A752C636F6C6F723A692C71756965743A327D7D69662822636F';
wwv_flow_imp.g_varchar2_table(527) := '6465313238223D3D3D6C297B76617220633D2474286F292C663D652E77696474687C7C4D6174682E6D696E2839302C2E33332A632E6C656E677468293B72657475726E7B6B696E643A22626172222C746578743A6F2C636F6C733A632E6C656E6774682C';
wwv_flow_imp.g_varchar2_table(528) := '726F77733A312C6461726B3A66756E6374696F6E2865297B72657475726E20635B655D7D2C773A662C683A652E6865696768747C7C31322C636F6C6F723A692C71756965743A382C6C6162656C3A2131213D3D652E73686F77546578742C746578745369';
wwv_flow_imp.g_varchar2_table(529) := '7A653A652E7465787453697A657C7C387D7D7468726F77206E6577204572726F7228612822636F64654B696E64222C6C29297D66756E6374696F6E2071742865297B76617220743D652E71756965742C723D227172223D3D3D652E6B696E643F383A332C';
wwv_flow_imp.g_varchar2_table(530) := '6E3D28652E636F6C732B322A74292A722C6F3D5774286E2C227172223D3D3D652E6B696E643F6E3A4D6174682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E636F6C732A7229292C66756E6374696F6E286E2C6F297B7661722061';
wwv_flow_imp.g_varchar2_table(531) := '3D4D6174682E666C6F6F72286E2F72292D742C6C3D227172223D3D3D652E6B696E643F4D6174682E666C6F6F72286F2F72292D743A303B72657475726E20613E3D3026266C3E3D302626613C652E636F6C7326266C3C652E726F77732626652E6461726B';
wwv_flow_imp.g_varchar2_table(532) := '28612C6C297D2C652E636F6C6F72293B72657475726E206F2E776D6D3D652E772A28652E636F6C732B322A74292F652E636F6C732C6F2E686D6D3D227172223D3D3D652E6B696E643F6F2E776D6D3A652E682C6F7D7661722058743D5B22233146344537';
wwv_flow_imp.g_varchar2_table(533) := '39222C2223453037423339222C2223324538423537222C2223433033393242222C2223374433433938222C2223313641303835222C2223443441433044222C2223354436443745222C2223413034303030222C2223323837344136225D3B66756E637469';
wwv_flow_imp.g_varchar2_table(534) := '6F6E205A7428652C742C72297B766172206E3D77696E646F772E43686172743B696628216E297468726F77206E6577204572726F722861282263686172744C69622229293B766172206F3D5628652C74293B696628216F2E6C656E677468297265747572';
wwv_flow_imp.g_varchar2_table(535) := '6E206E756C6C3B766172206C3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C693D742E545B6C5D7C7C7B7D2C733D4F626A6563742E6B6579732869292C753D652E63617465676F72793F537472696E6728652E';
wwv_flow_imp.g_varchar2_table(536) := '63617465676F7279292E746F55707065724361736528293A732E66696C7465722866756E6374696F6E2865297B72657475726E224E554D42455222213D3D695B655D262622444F435F4B455922213D3D657D295B305D7C7C735B305D2C633D28652E7365';
wwv_flow_imp.g_varchar2_table(537) := '726965732626652E7365726965732E6C656E6774683F652E7365726965733A732E66696C7465722866756E6374696F6E2865297B72657475726E224E554D424552223D3D3D695B655D262665213D3D75262622444F435F4B455922213D3D657D29292E6D';
wwv_flow_imp.g_varchar2_table(538) := '61702866756E6374696F6E2865297B72657475726E20653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A652C7B636F6C3A537472696E6728652E636F6C292E746F55707065724361736528292C6C6162656C3A766F69642030213D';
wwv_flow_imp.g_varchar2_table(539) := '3D652E6C6162656C3F652E6C6162656C3A7928652E636F6C292C636F6C6F723A652E636F6C6F727D7D292C663D652E63686172747C7C22626172222C643D22706965223D3D3D667C7C22646F7567686E7574223D3D3D662C683D31312E33343B64262628';
wwv_flow_imp.g_varchar2_table(540) := '633D632E736C69636528302C3129293B76617220673D652E77696474687C7C3132302C6D3D652E6865696768747C7C37302C763D4274284D6174682E726F756E6428672A68292C4D6174682E726F756E64286D2A6829292C623D66756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(541) := '297B72657475726E2E333532382A652A687D2C773D652E73697A657C7C382C783D2248656C7665746963612C20417269616C2C2073616E732D7365726966222C453D7B66616D696C793A782C73697A653A622877297D2C543D652E636F6C6F7273262665';
wwv_flow_imp.g_varchar2_table(542) := '2E636F6C6F72732E6C656E6774683F652E636F6C6F72733A5B722E7072696D6172795D2E636F6E6361742858742E736C696365283129292C433D66756E6374696F6E2874297B72657475726E205328742C652E666D747C7C284D6174682E726F756E6428';
wwv_flow_imp.g_varchar2_table(543) := '74293D3D3D743F22696E74223A226E756D3A322229297D2C413D6F2E6D61702866756E6374696F6E2874297B76617220723D745B755D3B72657475726E206E756C6C3D3D723F22223A652E63617465676F7279466D743F5328722C652E63617465676F72';
wwv_flow_imp.g_varchar2_table(544) := '79466D74293A537472696E672872297D292C4E3D632E6D61702866756E6374696F6E28722C6E297B76617220613D722E636F6C6F727C7C545B6E25542E6C656E6774685D2C6C3D7B6C6162656C3A4728722E6C6162656C2C74292C646174613A6F2E6D61';
wwv_flow_imp.g_varchar2_table(545) := '702866756E6374696F6E2865297B76617220743D655B722E636F6C5D3B72657475726E206E756C6C3D3D747C7C22223D3D3D743F6E756C6C3A4E756D6265722874297D297D3B72657475726E20643F286C2E6261636B67726F756E64436F6C6F723D6F2E';
wwv_flow_imp.g_varchar2_table(546) := '6D61702866756E6374696F6E28652C74297B72657475726E20545B7425542E6C656E6774685D7D292C6C2E626F72646572436F6C6F723D2223464646464646222C6C2E626F7264657257696474683D62282E3829293A226C696E65223D3D3D667C7C2261';
wwv_flow_imp.g_varchar2_table(547) := '726561223D3D3D663F286C2E626F72646572436F6C6F723D612C6C2E6261636B67726F756E64436F6C6F723D2261726561223D3D3D663F66756E6374696F6E28652C74297B76617220723D702865293B72657475726E227267626128222B725B305D2B22';
wwv_flow_imp.g_varchar2_table(548) := '2C222B725B315D2B222C222B725B325D2B222C222B742B2229227D28612C2E3235293A612C6C2E66696C6C3D2261726561223D3D3D662C6C2E626F7264657257696474683D6228312E34292C6C2E706F696E745261646975733D6228312E35292C6C2E70';
wwv_flow_imp.g_varchar2_table(549) := '6F696E744261636B67726F756E64436F6C6F723D612C6C2E74656E73696F6E3D652E736D6F6F74683F2E33353A30293A286C2E6261636B67726F756E64436F6C6F723D612C6C2E626F7264657257696474683D30292C6C7D292C503D7B666F6E743A452C';
wwv_flow_imp.g_varchar2_table(550) := '636F6C6F723A2223343434343434227D2C463D7B7D3B6966282164297B766172207A3D7B626567696E41745A65726F3A2131213D3D652E626567696E41745A65726F2C737461636B65643A2121652E737461636B65642C67726163653A652E76616C7565';
wwv_flow_imp.g_varchar2_table(551) := '733F2268626172223D3D3D663F22323525223A22313225223A302C677269643A7B636F6C6F723A2223453345374543222C6C696E6557696474683A62282E34297D2C626F726465723A7B646973706C61793A21317D2C7469636B733A7B666F6E743A452C';
wwv_flow_imp.g_varchar2_table(552) := '636F6C6F723A2223343434343434222C63616C6C6261636B3A66756E6374696F6E2865297B72657475726E20432865297D7D7D2C4D3D7B737461636B65643A2121652E737461636B65642C677269643A7B646973706C61793A21317D2C7469636B733A50';
wwv_flow_imp.g_varchar2_table(553) := '7D3B463D2268626172223D3D3D663F7B783A7A2C793A4D7D3A7B783A4D2C793A7A7D7D766172206B3D766F69642030213D3D652E6C6567656E643F2121652E6C6567656E643A647C7C632E6C656E6774683E312C4F3D6E6577206E28762E676574436F6E';
wwv_flow_imp.g_varchar2_table(554) := '746578742822326422292C7B747970653A643F663A2268626172223D3D3D663F22626172223A2261726561223D3D3D663F226C696E65223A662C646174613A7B6C6162656C733A412C64617461736574733A4E7D2C706C6174666F726D3A6E2E42617369';
wwv_flow_imp.g_varchar2_table(555) := '63506C6174666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C616E696D6174696F6E3A21312C646576696365506978656C526174696F3A312C696E646578417869733A2268626172223D3D3D663F2279223A2278222C6C61796F7574';
wwv_flow_imp.g_varchar2_table(556) := '3A7B70616464696E673A622834297D2C7363616C65733A462C706C7567696E733A7B6C6567656E643A7B646973706C61793A6B2C706F736974696F6E3A652E6C6567656E64506F736974696F6E7C7C28643F227269676874223A22626F74746F6D22292C';
wwv_flow_imp.g_varchar2_table(557) := '6C6162656C733A7B666F6E743A452C636F6C6F723A2223333333333333222C626F7857696474683A622837292C626F784865696768743A622837297D7D2C7469746C653A7B646973706C61793A2121652E7469746C652C746578743A4728652E7469746C';
wwv_flow_imp.g_varchar2_table(558) := '652C74292C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C793A782C73697A653A6228772B32292C7765696768743A22626F6C64227D2C70616464696E673A7B626F74746F6D3A622834297D7D2C746F6F6C7469703A7B656E61626C';
wwv_flow_imp.g_varchar2_table(559) := '65643A21317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C6265666F7265447261773A66756E6374696F6E2865297B76617220743D652E6374783B742E7361766528292C742E66696C6C5374796C653D2223464646464646222C742E';
wwv_flow_imp.g_varchar2_table(560) := '66696C6C5265637428302C302C652E77696474682C652E686569676874292C742E726573746F726528297D7D2C7B69643A226E7256616C6F726573222C61667465724461746173657473447261773A66756E6374696F6E2874297B696628652E76616C75';
wwv_flow_imp.g_varchar2_table(561) := '6573297B76617220723D742E6374783B722E7361766528292C722E666F6E743D22626F6C6420222B6228772D2E35292B22707820222B782C742E646174612E64617461736574732E666F72456163682866756E6374696F6E286E2C6F297B696628742E69';
wwv_flow_imp.g_varchar2_table(562) := '734461746173657456697369626C65286F29297B76617220613D6E2E646174612E7265647563652866756E6374696F6E28652C74297B72657475726E20652B28747C7C30297D2C30293B742E676574446174617365744D657461286F292E646174612E66';
wwv_flow_imp.g_varchar2_table(563) := '6F72456163682866756E6374696F6E28742C6F297B766172206C3D6E2E646174615B6F5D3B6966286E756C6C213D6C297B76617220693D22706374223D3D3D652E76616C7565733F5328613F3130302A6C2F613A302C226E756D3A3122292B2225223A43';
wwv_flow_imp.g_varchar2_table(564) := '286C293B69662864297B76617220733D742E746F6F6C746970506F736974696F6E28293B722E66696C6C5374796C653D2223464646464646222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D226D6964646C';
wwv_flow_imp.g_varchar2_table(565) := '65222C722E66696C6C5465787428692C732E782C732E79297D656C73652268626172223D3D3D663F28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D226C656674222C722E74657874426173656C696E653D226D69';
wwv_flow_imp.g_varchar2_table(566) := '64646C65222C722E66696C6C5465787428692C742E782B6228312E35292C742E7929293A28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D22626F7474';
wwv_flow_imp.g_varchar2_table(567) := '6F6D222C722E66696C6C5465787428692C742E782C742E792D6228312E352929297D7D297D7D292C722E726573746F726528297D7D7D5D7D292C4C3D762E746F4461746155524C2822696D6167652F706E6722293B4F2E64657374726F7928293B766172';
wwv_flow_imp.g_varchar2_table(568) := '20443D5574284C2C762E77696474682C762E686569676874293B72657475726E20442E776D6D3D672C442E686D6D3D6D2C447D66756E6374696F6E204A7428652C74297B76617220723D652E77617465726D61726B3B69662821727C7C226F626A656374';
wwv_flow_imp.g_varchar2_table(569) := '223D3D747970656F6620722626215728722E7768656E2C742C742E646F63292972657475726E206E756C6C3B22737472696E67223D3D747970656F662072262628723D7B746578743A727D293B766172206E3D4728722E746578742C742C742E646F6329';
wwv_flow_imp.g_varchar2_table(570) := '3B72657475726E206E3F7B746578743A6E2C636F6C6F723A722E636F6C6F727C7C2223433030303030222C6F7061636974793A766F69642030213D3D722E6F7061636974793F722E6F7061636974793A2E31322C616E676C653A766F69642030213D3D72';
wwv_flow_imp.g_varchar2_table(571) := '2E616E676C653F722E616E676C653A34352C73697A653A722E73697A657D3A6E756C6C7D66756E6374696F6E204B7428652C742C722C6E297B696628652E73697A652972657475726E20652E73697A653B766172206F3D652E616E676C65253138303D3D';
wwv_flow_imp.g_varchar2_table(572) := '303F2E382A723A2E362A4D6174682E7371727428722A722B6E2A6E293B72657475726E204D6174682E6D61782832302C4D6174682E6D696E283136302C3130302A6F2F7429297D66756E6374696F6E20517428652C742C722C6E297B766172206F2C613D';
wwv_flow_imp.g_varchar2_table(573) := '77696E646F772E6A737064662C6C3D722E782B2E362C693D722E792B2E362C733D722E77696474682D312E322C753D722E6865696768742D312E322C633D70284F65292C663D70284C65293B69662822636865636B626F78223D3D3D742E696E70757429';
wwv_flow_imp.g_varchar2_table(574) := '7B76617220643D4D6174682E6D696E28752C342E35293B692B3D28752D64292F322C733D642C753D647D652E73657444726177436F6C6F7228665B305D2C665B315D2C665B325D292C652E73657446696C6C436F6C6F7228635B305D2C635B315D2C635B';
wwv_flow_imp.g_varchar2_table(575) := '325D292C652E7365744C696E655769647468282E32292C652E72656374286C2C692C732C752C22464422292C652E73657444726177436F6C6F7228302C302C30292C22636865636B626F78223D3D3D742E696E7075743F28286F3D6E657720612E416372';
wwv_flow_imp.g_varchar2_table(576) := '6F466F726D436865636B426F78292E617070656172616E636553746174653D742E636865636B65643F224F6E223A224F6666222C6F2E76616C75653D742E636865636B65643F224F6E223A224F666622293A226C697374223D3D3D742E696E7075743F28';
wwv_flow_imp.g_varchar2_table(577) := '286F3D6E657720612E4163726F466F726D436F6D626F426F78292E7365744F7074696F6E7328742E6F7074696F6E73292C6F2E656469743D21312C742E76616C75652626286F2E76616C75653D742E76616C756529293A28286F3D6E657720612E416372';
wwv_flow_imp.g_varchar2_table(578) := '6F466F726D546578744669656C64292E6D756C74696C696E653D226D756C74696C696E65223D3D3D742E696E7075742C742E6D61784C656E6774682626286F2E6D61784C656E6774683D742E6D61784C656E677468292C742E76616C75652626286F2E76';
wwv_flow_imp.g_varchar2_table(579) := '616C75653D742E76616C756529292C6F2E6669656C644E616D653D742E6E616D652C6F2E526563743D5B6C2C692C732C755D2C22636865636B626F7822213D3D742E696E7075742626286F2E666F6E7453697A653D6E2C652E5F5F6E72466F726D53697A';
wwv_flow_imp.g_varchar2_table(580) := '657C7C28652E5F5F6E72466F726D53697A653D6E29292C742E726561644F6E6C792626286F2E726561644F6E6C793D2130292C652E6164644669656C64286F297D66756E6374696F6E20657228652C742C722C6E297B766172206F3D652E706167657C7C';
wwv_flow_imp.g_varchar2_table(581) := '7B7D2C6C3D41742865292C693D6C2E666F6E7453697A652C733D66756E6374696F6E28652C742C72297B766172206E3D652E7064667C7C7B7D2C6F3D722626766F69642030213D3D722E70646650617373776F726426266E756C6C213D3D722E70646650';
wwv_flow_imp.g_varchar2_table(582) := '617373776F726426262222213D3D722E70646650617373776F72643F537472696E6728722E70646650617373776F7264293A6E2E70617373776F72643F47286E2E70617373776F72642C74293A22222C613D6E2E6F776E657250617373776F72643F4728';
wwv_flow_imp.g_varchar2_table(583) := '6E2E6F776E657250617373776F72642C74293A22223B72657475726E206F7C7C613F7B7573657250617373776F72643A6F2C6F776E657250617373776F72643A617C7C6F2C757365725065726D697373696F6E733A2841727261792E6973417272617928';
wwv_flow_imp.g_varchar2_table(584) := '6E2E7065726D697373696F6E73293F6E2E7065726D697373696F6E733A5B227072696E74225D292E66696C7465722866756E6374696F6E2865297B72657475726E207A745B655D7D297D3A6E756C6C7D28652C745B305D7C7C7B533A7B7D2C543A7B7D7D';
wwv_flow_imp.g_varchar2_table(585) := '2C6E293B69662873262641727261792E6973417272617928652E617070656E64292626652E617070656E642E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228612822617070656E645077222929293B76';
wwv_flow_imp.g_varchar2_table(586) := '617220753D7B6F7269656E746174696F6E3A6F2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6F2E73697A657C7C226C6574746572222C636F6D70726573733A2147652865297D3B7326262875';
wwv_flow_imp.g_varchar2_table(587) := '2E656E6372797074696F6E3D73293B76617220633D6E65772077696E646F772E6A737064662E6A735044462875292C663D632E696E7465726E616C2E7061676553697A652E676574576964746828292C643D632E696E7465726E616C2E7061676553697A';
wwv_flow_imp.g_varchar2_table(588) := '652E67657448656967687428292C683D6F2E6D617267696E7C7C382C673D70286C2E7072696D617279292C6D3D70286C2E6865616454657874292C763D70286C2E7A65627261292C623D70286C2E746F74616C73292C773D682C793D21302C783D682C45';
wwv_flow_imp.g_varchar2_table(589) := '3D682C543D652E706167654865616465722626226F626A656374223D3D747970656F6620652E706167654865616465723F652E706167654865616465723A6E756C6C2C433D543F766F69642030213D3D542E746F703F4E756D62657228542E746F70293A';
wwv_flow_imp.g_varchar2_table(590) := '4D6174682E6D696E28682C35293A302C413D543F4E756D62657228542E686569676874297C7C31323A302C4E3D543F432B412B28766F69642030213D3D542E6761703F4E756D62657228542E676170293A33293A683B66756E6374696F6E205028297B76';
wwv_flow_imp.g_varchar2_table(591) := '617220653D7B6C6566743A782C72696768743A457D3B72657475726E2054262628652E746F703D4E292C657D66756E6374696F6E204628297B72657475726E20632E6C6173744175746F5461626C653F632E6C6173744175746F5461626C652E66696E61';
wwv_flow_imp.g_varchar2_table(592) := '6C593A777D66756E6374696F6E207A2865297B773D4628292B28657C7C32297D66756E6374696F6E204D28652C742C722C6E297B766172206F3D766F69642030213D3D652E783F652E783A227269676874223D3D3D652E616C69676E3F662D452D743A22';
wwv_flow_imp.g_varchar2_table(593) := '63656E746572223D3D3D652E616C69676E3F782B28662D782D452D74292F323A783B766F696420303D3D3D652E793F2828773D4D6174682E6D617828772C46282929292B723E642D682D3130262628632E6164645061676528292C773D4E292C6E286F2C';
wwv_flow_imp.g_varchar2_table(594) := '77292C772B3D722B28766F69642030213D3D652E6761703F652E6761703A33292C632E6C6173744175746F5461626C653D7B66696E616C593A777D293A6E286F2C652E79297D766172206B3D5B5D3B742E666F72456163682866756E6374696F6E286E2C';
wwv_flow_imp.g_varchar2_table(595) := '73297B76617220753D742E6C656E6774683E313F225F222B28732B31293A22223B797C7C632E6164645061676528292C793D21312C773D682C632E6C6173744175746F5461626C653D6E756C6C3B76617220433D7B6374783A6E2C66726F6D3A632E696E';
wwv_flow_imp.g_varchar2_table(596) := '7465726E616C2E6765744E756D6265724F66506167657328297D3B6B2E707573682843292C5426262131213D3D542E666972737450616765262628773D4E292C777428652C22706466222C6E292E666F72456163682866756E6374696F6E20742873297B';
wwv_flow_imp.g_varchar2_table(597) := '76617220793D732E747970653B69662822686561646572223D3D3D79297B76617220413D667428732C6C292C6B3D732E66696C6C3F7028412E66696C6C293A672C4F3D732E636F6C6F723F7028412E636F6C6F72293A6D2C4C3D4D6174682E6D61782831';
wwv_flow_imp.g_varchar2_table(598) := '302E352C332E352B2E333532382A412E73697A65292C443D4C2B4D6174682E6D617828362C312E352B2E333532382A412E73756253697A652A312E31292C6A3D4D6174682E6D6178284E756D62657228732E686569676874297C7C302C732E7375627469';
wwv_flow_imp.g_varchar2_table(599) := '746C653F4D6174682E6D61782832302C442B332E35293A4D6174682E6D61782831362C4C2B352E3529292C493D542626282131213D3D542E6669727374506167657C7C632E696E7465726E616C2E67657443757272656E7450616765496E666F28292E70';
wwv_flow_imp.g_varchar2_table(600) := '6167654E756D6265723E432E66726F6D293F4E2D323A303B72657475726E204C2B3D492C442B3D492C632E73657446696C6C436F6C6F72286B5B305D2C6B5B315D2C6B5B325D292C632E7265637428302C492C662C6A2C224622292C632E736574546578';
wwv_flow_imp.g_varchar2_table(601) := '74436F6C6F72284F5B305D2C4F5B315D2C4F5B325D292C632E736574466F6E7428412E666F6E745B305D2C22626F6C6422292C632E736574466F6E7453697A6528412E73697A65292C632E74657874284728732E7469746C652C6E292C682C4C2C7B6D61';
wwv_flow_imp.g_varchar2_table(602) := '7857696474683A2E372A667D292C632E736574466F6E7428412E666F6E745B305D2C226E6F726D616C22292C632E736574466F6E7453697A6528412E726967687453697A65292C732E72696768742626632E74657874284728732E72696768742C6E292C';
wwv_flow_imp.g_varchar2_table(603) := '662D682C4C2C7B616C69676E3A227269676874227D292C732E7375627469746C65262628632E736574466F6E7453697A6528412E73756253697A65292C632E74657874284728732E7375627469746C652C6E292C682C4429292C632E736574466F6E7428';
wwv_flow_imp.g_varchar2_table(604) := '2268656C766574696361222C226E6F726D616C22292C632E73657454657874436F6C6F7228302C302C30292C773D492B6A2B342C766F696428632E6C6173744175746F5461626C653D6E756C6C297D69662822746578746F223D3D3D79297B7661722052';
wwv_flow_imp.g_varchar2_table(605) := '3D766F69642030213D3D732E792C553D772C423D632E6C6173744175746F5461626C652C5F3D732E73697A657C7C31302C483D2E333532382A5F2A28732E6C696E654865696768747C7C312E3335292C583D28766F69642030213D3D732E783F732E783A';
wwv_flow_imp.g_varchar2_table(606) := '78292B28732E696E64656E747C7C30292C4B3D732E77696474687C7C662D452D582C6E653D732E616C69676E7C7C226C656674222C61653D7028732E636F6C6F727C7C222330303030303022292C6C653D66756E6374696F6E2865297B72657475726E28';
wwv_flow_imp.g_varchar2_table(607) := '652E627C7C732E626F6C6429262628652E697C7C732E6974616C6963293F22626F6C646974616C6963223A652E627C7C732E626F6C643F22626F6C64223A652E697C7C732E6974616C69633F226974616C6963223A226E6F726D616C227D2C75653D732E';
wwv_flow_imp.g_varchar2_table(608) := '666F6E747C7C652E706167652626652E706167652E666F6E747C7C2268656C766574696361223B72657475726E20632E736574466F6E7453697A65285F292C632E73657454657874436F6C6F722861655B305D2C61655B315D2C61655B325D292C773D52';
wwv_flow_imp.g_varchar2_table(609) := '3F732E793A4D6174682E6D617828772C632E6C6173744175746F5461626C653F632E6C6173744175746F5461626C652E66696E616C593A77292C656528732C6E292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B5128652C7B';
wwv_flow_imp.g_varchar2_table(610) := '666F6E743A75652C636F6C6F723A732E636F6C6F722C6C696E6B3A6C2E6C696E6B7D292E666F72456163682866756E6374696F6E2865297B652E742E73706C6974282F28202B292F292E666F72456163682866756E6374696F6E2872297B2222213D3D72';
wwv_flow_imp.g_varchar2_table(611) := '2626742E70757368287B743A722C66616D3A715B652E665D5B305D2C663A6C652865292C73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E633F7028652E63293A61652C683A652E687D297D297D293B76617220723D';
wwv_flow_imp.g_varchar2_table(612) := '5B5D2C6E3D5B5D2C6F3D303B666F7228742E666F72456163682866756E6374696F6E2865297B76617220743D66756E6374696F6E2865297B632E736574466F6E7428652E66616D2C652E66293B666F722876617220743D302C723D652E66616D2B652E66';
wwv_flow_imp.g_varchar2_table(613) := '2B5F2C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B766172206F3D722B652E742E636861724174286E293B766F696420303D3D3D50745B6F5D26262850745B6F5D3D632E67657454657874576964746828652E742E636861724174286E292929';
wwv_flow_imp.g_varchar2_table(614) := '2C742B3D50745B6F5D7D72657475726E20747D2865293B69662821652E737026266F2B743E4B26266E2E6C656E677468297B666F72283B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E7075';
wwv_flow_imp.g_varchar2_table(615) := '7368287B77733A6E2C773A6F7D292C6E3D5B5D2C6F3D307D652E73702626216E2E6C656E6774687C7C28652E773D742C6E2E707573682865292C6F2B3D74297D293B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E70';
wwv_flow_imp.g_varchar2_table(616) := '6F7028292E773B722E70757368287B77733A6E2C773A6F2C6C6173743A21307D292C652E7472696D28293F28722E666F72456163682866756E6374696F6E2865297B21522626772B483E642D682D3130262628632E6164645061676528292C773D4E293B';
wwv_flow_imp.g_varchar2_table(617) := '76617220743D652E77732E66696C7465722866756E6374696F6E2865297B72657475726E20652E73707D292E6C656E6774682C723D226A757374696679223D3D3D6E65262621652E6C6173742626743F284B2D652E77292F743A302C6E3D227269676874';
wwv_flow_imp.g_varchar2_table(618) := '223D3D3D6E653F582B4B2D652E773A2263656E746572223D3D3D6E653F582B284B2D652E77292F323A582C6F3D772B2E37352A483B652E77732E666F72456163682866756E6374696F6E2865297B76617220743D652E772B28652E73703F723A30293B63';
wwv_flow_imp.g_varchar2_table(619) := '2E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C632E73657444726177436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C632E7365744C696E655769647468282E3031322A5F292C652E7370';
wwv_flow_imp.g_varchar2_table(620) := '7C7C28632E736574466F6E7428652E66616D2C652E66292C632E7465787428652E742C6E2C6F29292C652E752626632E6C696E65286E2C6F2B2E30362A5F2C6E2B742C6F2B2E30362A5F292C652E732626632E6C696E65286E2C6F2D2E31312A5F2C6E2B';
wwv_flow_imp.g_varchar2_table(621) := '742C6F2D2E31312A5F292C652E682626632E6C696E6B286E2C772C742C482C7B75726C3A652E687D292C6E2B3D747D292C772B3D487D292C772B3D766F69642030213D3D732E7061726167726170684761703F732E7061726167726170684761703A2E35';
wwv_flow_imp.g_varchar2_table(622) := '2A48293A772B3D487D292C632E73657454657874436F6C6F7228302C302C30292C766F696428523F28773D552C632E6C6173744175746F5461626C653D42293A632E6C6173744175746F5461626C653D7B66696E616C593A777D297D696628226C696E65';
wwv_flow_imp.g_varchar2_table(623) := '61223D3D3D79297B7661722063653D7028732E636F6C6F727C7C222330303030303022293B696628632E73657444726177436F6C6F722863655B305D2C63655B315D2C63655B325D292C632E7365744C696E65576964746828732E746869636B6E657373';
wwv_flow_imp.g_varchar2_table(624) := '7C7C2E33292C766F69642030213D3D732E78312972657475726E20766F696420632E6C696E6528732E78312C732E79312C766F69642030213D3D732E78323F732E78323A732E78312C766F69642030213D3D732E79323F732E79323A732E7931293B773D';
wwv_flow_imp.g_varchar2_table(625) := '4D6174682E6D617828772C632E6C6173744175746F5461626C653F632E6C6173744175746F5461626C652E66696E616C593A77292B28732E6761704265666F72657C7C30293B7661722066653D732E77696474687C7C662D782D452C64653D2263656E74';
wwv_flow_imp.g_varchar2_table(626) := '6572223D3D3D732E616C69676E3F782B28662D782D452D6665292F323A227269676874223D3D3D732E616C69676E3F662D452D66653A783B72657475726E20632E6C696E652864652C772C64652B66652C77292C772B3D766F69642030213D3D732E6761';
wwv_flow_imp.g_varchar2_table(627) := '703F732E6761703A322C766F696428632E6C6173744175746F5461626C653D7B66696E616C593A777D297D696628226573706163696F223D3D3D792972657475726E20773D4D6174682E6D617828772C632E6C6173744175746F5461626C653F632E6C61';
wwv_flow_imp.g_varchar2_table(628) := '73744175746F5461626C652E66696E616C593A77292B28732E6865696768747C7C36292C766F696428632E6C6173744175746F5461626C653D7B66696E616C593A777D293B69662822696D6167656E22213D3D7929696628226772616669636F22213D3D';
wwv_flow_imp.g_varchar2_table(629) := '792969662822636F6469676F22213D3D79297B6966282273616C746F223D3D3D792972657475726E20632E6164645061676528292C773D4E2C766F696428632E6C6173744175746F5461626C653D7B66696E616C593A4E7D293B69662822636F6C756D6E';
wwv_flow_imp.g_varchar2_table(630) := '6173223D3D3D79297B7661722068653D782C70653D453B696628212856653D547428732C22706466222C6E2C662D782D4529292E6C656E6774682972657475726E3B7661722067653D66756E6374696F6E2865297B783D68652B652E782C453D662D2868';
wwv_flow_imp.g_varchar2_table(631) := '652B652E782B652E77297D2C62653D632C77653D302C43653D21302C41653D4D6174682E6D617828772C462829293B69662856652E666F72456163682866756E6374696F6E2865297B633D6E65772077696E646F772E6A737064662E6A73504446287B6F';
wwv_flow_imp.g_varchar2_table(632) := '7269656E746174696F6E3A6F2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6F2E73697A657C7C226C6574746572227D292C67652865292C773D682C632E6C6173744175746F5461626C653D6E';
wwv_flow_imp.g_varchar2_table(633) := '756C6C2C652E736563732E666F72456163682874292C632E696E7465726E616C2E6765744E756D6265724F66506167657328293E3126262843653D2131292C77653D4D6174682E6D61782877652C4D6174682E6D617828772C462829292D68297D292C78';
wwv_flow_imp.g_varchar2_table(634) := '3D68652C453D70652C773D41652C28633D6265292E6C6173744175746F5461626C653D7B66696E616C593A41657D2C2143652972657475726E20766F69642056652E666F72456163682866756E6374696F6E2865297B652E736563732E666F7245616368';
wwv_flow_imp.g_varchar2_table(635) := '2874297D293B772B77653E642D682D3130262628632E6164645061676528292C773D4E293B766172206B653D772C4F653D773B72657475726E2056652E666F72456163682866756E6374696F6E2865297B67652865292C773D6B652C632E6C6173744175';
wwv_flow_imp.g_varchar2_table(636) := '746F5461626C653D7B66696E616C593A6B657D2C652E736563732E666F72456163682874292C4F653D4D6174682E6D6178284F652C772C462829297D292C783D68652C453D70652C773D4F652B28766F69642030213D3D732E6761703F732E6761703A31';
wwv_flow_imp.g_varchar2_table(637) := '292C766F696428632E6C6173744175746F5461626C653D7B66696E616C593A777D297D69662822677275706F223D3D3D79297B766172204C653D6E2C44653D752C6A653D782C49653D452C42653D766F69642030213D3D732E70616464696E673F4E756D';
wwv_flow_imp.g_varchar2_table(638) := '62657228732E70616464696E67293A732E626F726465727C7C732E66696C6C3F333A302C5F653D66756E6374696F6E2865297B76617220722C6F3D4D6174682E6D617828772C462829293B783D6A652C453D49652C773D6F2C732E7469746C6526262872';
wwv_flow_imp.g_varchar2_table(639) := '3D4728732E7469746C652C6E292C632E6175746F5461626C65287B7374617274593A4D6174682E6D617828772C462829292C7468656D653A22706C61696E222C6D617267696E3A5028292C626F64793A5B5B725D5D2C7374796C65733A7B666F6E745369';
wwv_flow_imp.g_varchar2_table(640) := '7A653A732E7469746C6553697A657C7C692B322C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E362C66696C6C436F6C6F723A7028732E7469746C6546696C6C7C7C6C2E7072696D617279292C74657874436F6C6F723A70';
wwv_flow_imp.g_varchar2_table(641) := '28732E7469746C65436F6C6F727C7C6C2E6865616454657874297D7D292C773D462829292C773D4D6174682E6D617828772C462829292B42652C632E6C6173744175746F5461626C653D7B66696E616C593A777D2C783D6A652B42652C453D49652B4265';
wwv_flow_imp.g_varchar2_table(642) := '2C652E666F72456163682874293B76617220613D4D6174682E6D617828772C462829292B42653B72657475726E20783D6A652C453D49652C612D6F7D3B72657475726E20537428732C6E292E666F72456163682866756E6374696F6E2865297B6E3D652E';
wwv_flow_imp.g_varchar2_table(643) := '6374782C753D44652B652E7375663B76617220743D457428732C22706466222C6E293B696628742E6C656E6774687C7C732E7469746C65297B76617220723D632C613D4D6174682E6D617828772C462829293B633D6E65772077696E646F772E6A737064';
wwv_flow_imp.g_varchar2_table(644) := '662E6A73504446287B6F7269656E746174696F6E3A6F2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6F2E73697A657C7C226C6574746572227D292C773D682C632E6C6173744175746F546162';
wwv_flow_imp.g_varchar2_table(645) := '6C653D6E756C6C3B766172206C3D5F652874292C693D313D3D3D632E696E7465726E616C2E6765744E756D6265724F66506167657328293B773D612C28633D72292E6C6173744175746F5461626C653D7B66696E616C593A617D2C6926262131213D3D73';
wwv_flow_imp.g_varchar2_table(646) := '2E6B656570546F6765746865722626772B6C3E642D682D3130262628632E6164645061676528292C773D4E2C632E6C6173744175746F5461626C653D7B66696E616C593A777D293B76617220673D772C6D3D632E696E7465726E616C2E67657443757272';
wwv_flow_imp.g_varchar2_table(647) := '656E7450616765496E666F28292E706167654E756D6265722C763D662D6A652D49653B696628692626732E66696C6C297B76617220623D7028732E66696C6C293B632E73657446696C6C436F6C6F7228625B305D2C625B315D2C625B325D292C632E7265';
wwv_flow_imp.g_varchar2_table(648) := '6374286A652C672C762C6C2C224622297D76617220793D5F652874293B696628732E626F726465722626632E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265723D3D3D6D297B76617220783D7028732E';
wwv_flow_imp.g_varchar2_table(649) := '626F72646572436F6C6F727C7C5865293B632E73657444726177436F6C6F7228785B305D2C785B315D2C785B325D292C632E7365744C696E65576964746828732E626F7264657257696474687C7C2E33292C632E72656374286A652C672C762C792C2253';
wwv_flow_imp.g_varchar2_table(650) := '22292C632E73657444726177436F6C6F7228302C302C30297D773D672B792C632E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D626572213D3D6D262628773D4D6174682E6D617828772C46282929292C77';
wwv_flow_imp.g_varchar2_table(651) := '2B3D766F69642030213D3D732E6761703F4E756D62657228732E676170293A332C632E6C6173744175746F5461626C653D7B66696E616C593A777D7D7D292C6E3D4C652C753D44652C783D6A652C766F696428453D4965297D696628226669636861223D';
wwv_flow_imp.g_varchar2_table(652) := '3D3D79297B7661722047653D5628732C6E295B305D7C7C7B7D2C48653D732E636F6C756D6E737C7C332C57653D5B5D2C56653D7B7D2C24653D21313B4B652828732E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B726574';
wwv_flow_imp.g_varchar2_table(653) := '75726E21652E7768656E7C7C5728652E7768656E2C6E2C4765297D292C4865292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E65';
wwv_flow_imp.g_varchar2_table(654) := '6D70747929742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B6C696E6557696474683A302C66696C6C436F6C6F723A21317D7D293B656C73657B766172206F3D6E7428722C73292C613D7474';
wwv_flow_imp.g_varchar2_table(655) := '28722C6E2C4765292C693D4D6528722C6E2C4765292C753D5A28722C6E2C4765293B696628226C65667422213D3D6F2E706F73297B76617220633D7B666F6E745374796C653A612626612E626F6C643F22626F6C64223A226E6F726D616C222C66696C6C';
wwv_flow_imp.g_varchar2_table(656) := '436F6C6F723A212821617C7C21612E66696C6C2926267028612E66696C6C292C74657874436F6C6F723A7028612626612E636F6C6F727C7C732E76616C7565436F6C6F727C7C222330303030303022292C68616C69676E3A612626612E616C69676E7C7C';
wwv_flow_imp.g_varchar2_table(657) := '226C656674227D3B75262628612626612E636F6C6F727C7C28632E74657874436F6C6F723D70286C2E6C696E6B29292C24653D2130293B76617220663D7B636F6E74656E743A692C636F6C5370616E3A322A652E7370616E2C7374796C65733A632C5F6E';
wwv_flow_imp.g_varchar2_table(658) := '72487265663A757D3B72657475726E22746F70223D3D3D6F2E706F73262628662E5F6E724C61623D7B746578743A6174284728722E6C6162656C2C6E2C4765292C6F292C6C623A6F2C616C69676E3A6F2E616C69676E7C7C632E68616C69676E7D292C76';
wwv_flow_imp.g_varchar2_table(659) := '6F696420742E707573682866297D696628617C7C652E7370616E3E317C7C75297B76617220643D7B7D3B75262628642E74657874436F6C6F723D70286C2E6C696E6B292C24653D2130292C612626612E616C69676E262628642E68616C69676E3D612E61';
wwv_flow_imp.g_varchar2_table(660) := '6C69676E292C612626612E626F6C64262628642E666F6E745374796C653D22626F6C6422292C612626612E636F6C6F72262628642E74657874436F6C6F723D7028612E636F6C6F7229292C612626612E66696C6C262628642E66696C6C436F6C6F723D70';
wwv_flow_imp.g_varchar2_table(661) := '28612E66696C6C29292C693D7B636F6E74656E743A692C7374796C65733A642C5F6E72487265663A757D2C652E7370616E3E31262628692E636F6C5370616E3D322A652E7370616E2D31297D76617220683D4728722E6C6162656C2C6E2C4765293B742E';
wwv_flow_imp.g_varchar2_table(662) := '70757368286F2E7374796C65643F7B636F6E74656E743A617428682C6F292C7374796C65733A7574286F297D3A682C69297D7D293B666F722876617220723D322A65742865293B723C322A48653B722B2B29742E70757368282222293B57652E70757368';
wwv_flow_imp.g_varchar2_table(663) := '2874297D293B7661722059653D302C71653D6C742873293B696628516528732E6669656C6473297C7C7165297B666F72287661722072743D302C6F743D303B6F743C48653B6F742B2B2972742B3D5A6528732C6F74293B59653D4D6174682E6D61782831';
wwv_flow_imp.g_varchar2_table(664) := '302C28662D782D452D7274292F4865297D666F72287661722069743D303B69743C322A48653B69742B3D322956655B69745D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A5A6528732C69742F32297D2C596526262856655B69';
wwv_flow_imp.g_varchar2_table(665) := '742B315D3D7B63656C6C57696474683A59657D292C732E6C6162656C46696C6C26262856655B69745D2E66696C6C436F6C6F723D7028732E6C6162656C46696C6C29292C732E6C6162656C436F6C6F7226262856655B69745D2E74657874436F6C6F723D';
wwv_flow_imp.g_varchar2_table(666) := '7028732E6C6162656C436F6C6F7229292C732E76616C7565436F6C6F7226262856655B69742B315D3D56655B69742B315D7C7C7B7D2C56655B69742B315D2E74657874436F6C6F723D7028732E76616C7565436F6C6F7229293B7661722068743D7B666F';
wwv_flow_imp.g_varchar2_table(667) := '6E7453697A653A732E73697A657C7C382E352C63656C6C50616464696E673A2E397D3B732E6772696426262868742E63656C6C50616464696E673D312E362C68742E76616C69676E3D226D6964646C65222C68742E6C696E6557696474683D2E31352C68';
wwv_flow_imp.g_varchar2_table(668) := '742E6C696E65436F6C6F723D7028732E626F72646572436F6C6F727C7C586529293B7661722070743D7B7374617274593A772C626F64793A57652C7468656D653A22706C61696E222C6D617267696E3A5028292C7374796C65733A68742C636F6C756D6E';
wwv_flow_imp.g_varchar2_table(669) := '5374796C65733A56657D3B6966287165297B7661722067743D68742E666F6E7453697A652C6D743D68742E63656C6C50616464696E673B70742E646964506172736543656C6C3D66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E';
wwv_flow_imp.g_varchar2_table(670) := '73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B74262628652E63656C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A6D742B737428742E6C622C6774292C72696768743A6D742C626F';
wwv_flow_imp.g_varchar2_table(671) := '74746F6D3A6D742C6C6566743A6D747D297D2C70742E6469644472617743656C6C3D66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61';
wwv_flow_imp.g_varchar2_table(672) := '623B742626637428632C652E63656C6C2C742C67742C6D74297D7D6966282465297B7661722076743D70742E6469644472617743656C6C3B70742E6469644472617743656C6C3D66756E6374696F6E2865297B22626F6479223D3D3D652E73656374696F';
wwv_flow_imp.g_varchar2_table(673) := '6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724872656626264A28632C652E63656C6C2C652E63656C6C2E7261772E5F6E7248726566292C7674262676742865297D7D72657475726E20632E6175746F5461626C65287074292C';
wwv_flow_imp.g_varchar2_table(674) := '766F6964207A2832297D696628227461726A65746173223D3D3D79297B7661722062743D647428732C6E2C6C293B6966282162742E6974656D732E6C656E6774682972657475726E3B7661722077743D28662D782D452D62742E636172644761702A2862';
wwv_flow_imp.g_varchar2_table(675) := '742E6E2D3129292F62742E6E2C79743D2E333532382A62742E6C6162656C53697A652C78743D2E333532382A62742E73697A652C43743D702862742E66696C6C292C41743D62742E616363656E743F702862742E616363656E74293A6E756C6C2C4E743D';
wwv_flow_imp.g_varchar2_table(676) := '41743F343A332C46743D77742D4E742D323B773D4D6174682E6D617828772C462829293B666F7228766172207A743D303B7A743C62742E6974656D732E6C656E6774683B7A742B3D62742E6E297B766172204D743D62742E6974656D732E736C69636528';
wwv_flow_imp.g_varchar2_table(677) := '7A742C7A742B62742E6E293B632E736574466F6E74282268656C766574696361222C22626F6C6422292C632E736574466F6E7453697A652862742E73697A65293B766172206B743D4D742E6D61702866756E6374696F6E2865297B72657475726E20632E';
wwv_flow_imp.g_varchar2_table(678) := '73706C697454657874546F53697A6528537472696E6728652E76616C7565292C4674297D292C4F743D4D6174682E6D61782E6170706C79286E756C6C2C6B742E6D61702866756E6374696F6E2865297B72657475726E204D6174682E6D617828312C652E';
wwv_flow_imp.g_varchar2_table(679) := '6C656E677468297D29292C4C743D312E322A79742B312E352B312E322A78742A4F742C44743D4D6174682E6D617828732E6865696768747C7C302C332B4C742B33293B772B44743E642D682D3130262628632E6164645061676528292C773D4E292C4D74';
wwv_flow_imp.g_varchar2_table(680) := '2E666F72456163682866756E6374696F6E28652C74297B76617220723D782B742A2877742B62742E63617264476170292C6E3D702862742E6C6162656C436F6C6F72292C6F3D7028652E636F6C6F727C7C62742E76616C7565436F6C6F72293B632E7365';
wwv_flow_imp.g_varchar2_table(681) := '7446696C6C436F6C6F722843745B305D2C43745B315D2C43745B325D292C632E7265637428722C772C77742C44742C224622292C4174262628632E73657446696C6C436F6C6F722841745B305D2C41745B315D2C41745B325D292C632E7265637428722C';
wwv_flow_imp.g_varchar2_table(682) := '772C312E322C44742C22462229293B76617220613D772B2844742D4C74292F322B79743B632E736574466F6E74282268656C766574696361222C226E6F726D616C22292C632E736574466F6E7453697A652862742E6C6162656C53697A65292C632E7365';
wwv_flow_imp.g_varchar2_table(683) := '7454657874436F6C6F72286E5B305D2C6E5B315D2C6E5B325D292C632E7465787428632E73706C697454657874546F53697A6528537472696E6728652E6C6162656C292C4674295B305D7C7C22222C722B4E742C61292C632E736574466F6E7428226865';
wwv_flow_imp.g_varchar2_table(684) := '6C766574696361222C22626F6C6422292C632E736574466F6E7453697A652862742E73697A65292C632E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C6B745B745D2E666F72456163682866756E6374696F6E28652C74297B63';
wwv_flow_imp.g_varchar2_table(685) := '2E7465787428652C722B4E742C612B312E352B312E30352A78742B742A78742A312E32297D297D292C772B3D44742B287A742B62742E6E3C62742E6974656D732E6C656E6774683F62742E636172644761703A30297D72657475726E20632E736574466F';
wwv_flow_imp.g_varchar2_table(686) := '6E74282268656C766574696361222C226E6F726D616C22292C632E73657454657874436F6C6F7228302C302C30292C772B3D766F69642030213D3D732E6761703F732E6761703A332C766F696428632E6C6173744175746F5461626C653D7B66696E616C';
wwv_flow_imp.g_varchar2_table(687) := '593A777D297D69662822666F726D756C6172696F223D3D3D79297B632E5F5F6E72466F726D7C7C28632E5F5F6E72466F726D3D52652829293B7661722052743D556528732C6E2C75292C55743D732E636F6C756D6E737C7C322C42743D5B5D2C5F743D7B';
wwv_flow_imp.g_varchar2_table(688) := '7D2C47743D7B7D2C48743D732E73697A657C7C382E353B6966284B652852742C5574292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628';
wwv_flow_imp.g_varchar2_table(689) := '652E656D70747929742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E7D293B656C73657B696628632E5F5F6E72466F726D28722E6E616D65292C226C65667422213D3D722E6C61622E706F73297B5F745B42742E6C';
wwv_flow_imp.g_varchar2_table(690) := '656E6774682B223A222B322A652E636F6C5D3D723B766172206E3D7B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B666F6E745374796C653A226E6F726D616C227D7D3B72657475726E22746F70223D3D3D72';
wwv_flow_imp.g_varchar2_table(691) := '2E6C61622E706F732626286E2E5F6E724C61623D7B746578743A617428722E6C6162656C2C722E6C6162292C6C623A722E6C61622C616C69676E3A722E6C61622E616C69676E7C7C226C656674227D292C766F696420742E70757368286E297D5F745B42';
wwv_flow_imp.g_varchar2_table(692) := '742E6C656E6774682B223A222B28322A652E636F6C2B31295D3D722C742E7075736828722E6C61622E7374796C65643F7B636F6E74656E743A617428722E6C6162656C2C722E6C6162292C7374796C65733A757428722E6C6162297D3A722E6C6162656C';
wwv_flow_imp.g_varchar2_table(693) := '2C652E7370616E3E313F7B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2D317D3A2222297D7D293B666F722876617220723D322A65742865293B723C322A55743B722B2B29742E70757368282222293B42742E707573682874297D';
wwv_flow_imp.g_varchar2_table(694) := '292C2142742E6C656E6774682972657475726E3B666F72287661722057743D516528732E6669656C6473297C7C6C742873293F4D6174682E6D61782831302C28662D782D452D28732E6C6162656C57696474687C7C3332292A5574292F5574293A302C56';
wwv_flow_imp.g_varchar2_table(695) := '743D303B56743C322A55743B56742B3D322947745B56745D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A732E6C6162656C57696474687C7C33327D2C577426262847745B56742B315D3D7B63656C6C57696474683A57747D29';
wwv_flow_imp.g_varchar2_table(696) := '3B7661722024743D2E333532382A48742A312E333B72657475726E20632E6175746F5461626C65287B7374617274593A772C626F64793A42742C7468656D653A22706C61696E222C6D617267696E3A5028292C726F7750616765427265616B3A2261766F';
wwv_flow_imp.g_varchar2_table(697) := '6964222C7374796C65733A7B666F6E7453697A653A48742C63656C6C50616464696E673A312E322C76616C69676E3A226D6964646C65227D2C636F6C756D6E5374796C65733A47742C646964506172736543656C6C3A66756E6374696F6E2865297B7661';
wwv_flow_imp.g_varchar2_table(698) := '7220743D22626F6479223D3D3D652E73656374696F6E26265F745B652E726F772E696E6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C6162';
wwv_flow_imp.g_varchar2_table(699) := '2C6E3D723F737428722E6C622C4874293A303B72262628652E63656C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A312E322B6E2C72696768743A312E322C626F74746F6D3A312E322C6C6566743A312E327D292C652E63656C6C2E73';
wwv_flow_imp.g_varchar2_table(700) := '74796C65732E6D696E43656C6C4865696768743D742E6C696E65732A24742B332B6E7D7D2C6469644472617743656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E26265F745B652E726F772E696E6465';
wwv_flow_imp.g_varchar2_table(701) := '782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B69662872297B766172206E3D737428722E6C622C4874292B312E323B637428632C652E63';
wwv_flow_imp.g_varchar2_table(702) := '656C6C2C722C48742C312E32292C517428632C742C7B783A652E63656C6C2E782C793A652E63656C6C2E792B6E2D2E362C77696474683A652E63656C6C2E77696474682C6865696768743A652E63656C6C2E6865696768742D6E2B2E367D2C4874297D65';
wwv_flow_imp.g_varchar2_table(703) := '6C736520517428632C742C652E63656C6C2C4874297D7D7D292C766F6964207A2832297D69662822616C6572746122213D3D79297B696628227461626C61223D3D3D79297B7661722071743D5628732C6E293B6966282171742E6C656E67746826262131';
wwv_flow_imp.g_varchar2_table(704) := '213D3D732E68696465456D707479262621732E656D707479546578742972657475726E3B7661722058743D506528732C7174293B69662858742972657475726E20766F69642058742E666F72456163682866756E6374696F6E28652C72297B7226262863';
wwv_flow_imp.g_varchar2_table(705) := '2E6164645061676528292C773D4E2C632E6C6173744175746F5461626C653D7B66696E616C593A4E7D292C742865297D293B766172204A743D746528732C6E2C7174292C4B743D5B5D2C65723D7B7D3B696628732E7469746C6526264B742E7075736828';
wwv_flow_imp.g_varchar2_table(706) := '5B7B636F6E74656E743A4728732E7469746C652C6E292C636F6C5370616E3A4A742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E7453697A653A692B317D7D5D292C732E67726F757073297B7661722074723D5B5D2C';
wwv_flow_imp.g_varchar2_table(707) := '72723D5B5D2C6E723D7B68616C69676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B726528732C4A74292E666F72456163682866756E6374696F6E2865297B666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E';
wwv_flow_imp.g_varchar2_table(708) := '636F6C733B742B2B29652E6761703F74722E70757368287B636F6E74656E743A4A745B745D2E6C6162656C2C726F775370616E3A322C7374796C65733A7B68616C69676E3A4A65284A745B745D2C73292C76616C69676E3A226D6964646C65227D7D293A';
wwv_flow_imp.g_varchar2_table(709) := '72722E70757368287B636F6E74656E743A4A745B745D2E6C6162656C2C7374796C65733A7B68616C69676E3A4A65284A745B745D2C73297D7D293B652E6761707C7C74722E70757368287B636F6E74656E743A652E6C6162656C2C636F6C5370616E3A65';
wwv_flow_imp.g_varchar2_table(710) := '2E636F6C732C7374796C65733A6E727D297D292C4B742E707573682874722C7272297D656C7365204B742E70757368284A742E6D61702866756E6374696F6E2865297B72657475726E7B636F6E74656E743A652E6C6162656C2C7374796C65733A7B6861';
wwv_flow_imp.g_varchar2_table(711) := '6C69676E3A4A6528652C73297D7D7D29293B4A742E666F72456163682866756E6374696F6E28652C74297B65725B745D3D7B68616C69676E3A652E616C69676E7D2C652E636F6C6F7226262865725B745D2E74657874436F6C6F723D7028652E636F6C6F';
wwv_flow_imp.g_varchar2_table(712) := '7229292C652E626F6C6426262865725B745D2E666F6E745374796C653D22626F6C6422292C652E776964746826262865725B745D2E63656C6C57696474683D652E7769647468297D293B766172206F723D4E6528732C7174292C61723D54652873292C6C';
wwv_flow_imp.g_varchar2_table(713) := '723D70286C2E67726F7570292C69723D5B5D2C73723D5B5D2C75723D5B5D2C63723D7B7D3B57653D71742E6C656E6774683F5B5D3A5B5B7B636F6E74656E743A4728732E656D707479546578742C6E292C636F6C5370616E3A4A742E6C656E6774682C73';
wwv_flow_imp.g_varchar2_table(714) := '74796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A226974616C6963227D7D5D5D3B71742E6C656E6774682626286F722E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B297265747572';
wwv_flow_imp.g_varchar2_table(715) := '6E2057652E70757368285B7B636F6E74656E743A7A6528732C652C6E292C636F6C5370616E3A4A742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A652E6C';
wwv_flow_imp.g_varchar2_table(716) := '766C3F70284665286C2C652E6C766C29293A6C727D7D5D292C69722E707573682865292C73722E70757368286E756C6C292C766F69642075722E70757368286E756C6C293B6966282273756222213D3D652E6B297B76617220743D6E756C6C2C723D6E75';
wwv_flow_imp.g_varchar2_table(717) := '6C6C3B4A742E666F72456163682866756E6374696F6E28742C6F297B76617220613D5A28742C6E2C652E72293B6126262828723D727C7C7B7D295B6F5D3D61297D292C57652E70757368284A742E6D61702866756E6374696F6E28722C6F297B69662821';
wwv_flow_imp.g_varchar2_table(718) := '722E63656C6C2972657475726E206F6528722C652E722C6E293B76617220613D736528722C652E722C6E2C6C293B72657475726E206126262828743D747C7C7B7D295B6F5D3D612C63725B6F5D3D4D6174682E6D61782863725B6F5D7C7C302C612E7729';
wwv_flow_imp.g_varchar2_table(719) := '292C22227D29292C69722E707573682865292C73722E707573682874292C75722E707573682872297D656C7365205365287865284A742C61722C652E726F77732C7A6528732C652C6E29292C4A742E6C656E677468292E666F72456163682866756E6374';
wwv_flow_imp.g_varchar2_table(720) := '696F6E2874297B57652E707573682874292C69722E707573682865292C73722E70757368286E756C6C292C75722E70757368286E756C6C297D297D292C4F626A6563742E6B657973286372292E666F72456163682866756E6374696F6E2865297B65725B';
wwv_flow_imp.g_varchar2_table(721) := '655D2E63656C6C57696474683D4D6174682E6D6178284A745B655D2E77696474687C7C302C63725B655D2B33297D29293B7661722066723D6E756C6C2C64723D6D6528732E746F74616C73293B69662864722E6C656E677468262671742E6C656E677468';
wwv_flow_imp.g_varchar2_table(722) := '297B7661722068723D732E5F616C6C526F77737C7C71743B66723D5365287865284A742C64722C68722C456528732C6E2C687229292C4A742E6C656E677468297D7661722070723D71742E6C656E6774683F66756E6374696F6E2865297B76617220743D';
wwv_flow_imp.g_varchar2_table(723) := '652E63617272793B69662821742972657475726E206E756C6C3B76617220723D21303D3D3D743F7B7D3A41727261792E697341727261792874293F7B636F6C733A747D3A742C6E3D6D6528722E636F6C737C7C652E746F74616C73292E66696C74657228';
wwv_flow_imp.g_varchar2_table(724) := '66756E6374696F6E2865297B72657475726E2273756D223D3D3D652E666E7D293B72657475726E206E2E6C656E6774683F7B636F6C733A6E2C6C6162656C3A722E6C6162656C7C7C612822636172727922292C6C6162656C46726F6D3A722E6C6162656C';
wwv_flow_imp.g_varchar2_table(725) := '46726F6D7C7C612822636172727946726F6D22297D3A6E756C6C7D2873293A6E756C6C2C67723D2E333532382A28732E73697A657C7C69292B322E342C6D723D7B7D2C76723D5B5D2C62723D5B5D2C77723D5028293B707226262877722E746F703D2876';
wwv_flow_imp.g_varchar2_table(726) := '6F69642030213D3D77722E746F703F77722E746F703A34302F632E696E7465726E616C2E7363616C65466163746F72292B67722C77722E626F74746F6D3D34302F632E696E7465726E616C2E7363616C65466163746F722B6772293B7661722079723D7B';
wwv_flow_imp.g_varchar2_table(727) := '666F6E7453697A653A732E73697A657C7C692C63656C6C50616464696E673A732E677269643F312E323A2E387D2C78723D696528732C4A74293B696628787226262879722E76616C69676E3D7872292C4A742E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(728) := '652C74297B652E76616C69676E26262865725B745D2E76616C69676E3D652E76616C69676E297D292C732E6772696426262879722E6C696E6557696474683D2E31352C79722E6C696E65436F6C6F723D7028732E626F72646572436F6C6F727C7C586529';
wwv_flow_imp.g_varchar2_table(729) := '292C632E6175746F5461626C65287B7374617274593A772C6D617267696E3A77722C686561643A4B742C626F64793A57652C666F6F743A66727C7C766F696420302C726F7750616765427265616B3A70723F2261766F6964223A766F696420302C646964';
wwv_flow_imp.g_varchar2_table(730) := '44726177506167653A70723F66756E6374696F6E2865297B62722E70757368287B706167653A652E706167654E756D6265722C793A652E637572736F722E792C6E3A76722E6C656E6774687D297D3A766F696420302C73686F77486561643A21313D3D3D';
wwv_flow_imp.g_varchar2_table(731) := '732E7265706561744865616465723F22666972737450616765223A22657665727950616765222C73686F77466F6F743A226C61737450616765222C7374796C65733A79722C686561645374796C65733A7B66696C6C436F6C6F723A672C74657874436F6C';
wwv_flow_imp.g_varchar2_table(732) := '6F723A6D2C68616C69676E3A2263656E746572222C666F6E7453697A653A732E73697A657C7C697D2C666F6F745374796C65733A7B66696C6C436F6C6F723A622C74657874436F6C6F723A732E746F74616C73436F6C6F723F7028732E746F74616C7343';
wwv_flow_imp.g_varchar2_table(733) := '6F6C6F72293A302C666F6E745374796C653A22626F6C64222C68616C69676E3A227269676874227D2C616C7465726E617465526F775374796C65733A732E627265616B42793F7B7D3A7B66696C6C436F6C6F723A767D2C636F6C756D6E5374796C65733A';
wwv_flow_imp.g_varchar2_table(734) := '65722C646964506172736543656C6C3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F6E262671742E6C656E677468297B76617220743D69725B652E726F772E696E6465785D3B696628742626226865616422213D3D74';
wwv_flow_imp.g_varchar2_table(735) := '2E6B297B69662822737562223D3D3D742E6B2972657475726E20652E63656C6C2E7374796C65732E66696C6C436F6C6F723D622C766F696428652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C6422293B766172206F3D742E722C61';
wwv_flow_imp.g_varchar2_table(736) := '3D4A745B652E636F6C756D6E2E696E6465785D3B732E627265616B4279262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D742E6925323D3D3126262131213D3D732E7A656272613F763A5B3235352C3235352C3235355D292C75725B65';
wwv_flow_imp.g_varchar2_table(737) := '2E726F772E696E6465785D262675725B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D262621612E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D70286C2E6C696E6B29293B76617220693D5928';
wwv_flow_imp.g_varchar2_table(738) := '732E726F775374796C652C6E2C6F293B69262628692E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D7028692E66696C6C29292C692E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D7028';
wwv_flow_imp.g_varchar2_table(739) := '692E636F6C6F7229292C692E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B76617220753D6126265928612E63656C6C5374796C652C6E2C6F293B75262628752E66696C6C262628652E63656C6C2E';
wwv_flow_imp.g_varchar2_table(740) := '7374796C65732E66696C6C436F6C6F723D7028752E66696C6C29292C752E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D7028752E636F6C6F7229292C752E626F6C64262628652E63656C6C2E7374796C65732E666F6E';
wwv_flow_imp.g_varchar2_table(741) := '745374796C653D22626F6C642229293B76617220633D73725B652E726F772E696E6465785D262673725B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B63262628652E63656C6C2E7374796C65732E6D696E43656C6C48656967';
wwv_flow_imp.g_varchar2_table(742) := '68743D4D6174682E6D617828652E63656C6C2E7374796C65732E6D696E43656C6C4865696768747C7C302C632E682B3229292C722626722E70646643656C6C2626722E70646643656C6C28652C6F2C612C732C6E297D7D7D2C6469644472617743656C6C';
wwv_flow_imp.g_varchar2_table(743) := '3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F6E297B70722626216D725B652E726F772E696E6465785D2626286D725B652E726F772E696E6465785D3D312C69725B652E726F772E696E6465785D262622726F77223D';
wwv_flow_imp.g_varchar2_table(744) := '3D3D69725B652E726F772E696E6465785D2E6B262676722E707573682869725B652E726F772E696E6465785D2E7229293B76617220743D73725B652E726F772E696E6465785D262673725B652E726F772E696E6465785D5B652E636F6C756D6E2E696E64';
wwv_flow_imp.g_varchar2_table(745) := '65785D3B6966284A28632C652E63656C6C2C75725B652E726F772E696E6465785D262675725B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D2C214A745B652E636F6C756D6E2E696E6465785D2E63656C6C292C74297B76617220';
wwv_flow_imp.g_varchar2_table(746) := '723D4A745B652E636F6C756D6E2E696E6465785D2E616C69676E2C6E3D226C656674223D3D3D723F652E63656C6C2E782B313A227269676874223D3D3D723F652E63656C6C2E782B652E63656C6C2E77696474682D742E772D313A652E63656C6C2E782B';
wwv_flow_imp.g_varchar2_table(747) := '28652E63656C6C2E77696474682D742E77292F322C6F3D4A745B652E636F6C756D6E2E696E6465785D2E76616C69676E7C7C78722C613D22746F70223D3D3D6F3F652E63656C6C2E792B313A22626F74746F6D223D3D3D6F3F652E63656C6C2E792B652E';
wwv_flow_imp.g_varchar2_table(748) := '63656C6C2E6865696768742D742E682D313A652E63656C6C2E792B28652E63656C6C2E6865696768742D742E68292F323B632E616464496D61676528742E696D2E646174612C226A7067223D3D3D742E696D2E6578743F224A504547223A22504E47222C';
wwv_flow_imp.g_varchar2_table(749) := '6E2C612C742E772C742E682C766F696420302C224641535422297D7D7D7D292C7072262662722E6C656E6774683E31297B666F72287661722045723D632E6C6173744175746F5461626C652C53723D632E696E7465726E616C2E67657443757272656E74';
wwv_flow_imp.g_varchar2_table(750) := '50616765496E666F28292E706167654E756D6265722C54723D45722E73657474696E67732E6D617267696E2E6C6566742C43723D45722E636F6C756D6E732E6D61702866756E6374696F6E2865297B72657475726E20652E77696474687D292C41723D43';
wwv_flow_imp.g_varchar2_table(751) := '722E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C4E723D732E73697A657C7C692C50723D732E746F74616C73436F6C6F723F7028732E746F74616C73436F6C6F72293A5B302C302C305D2C46723D66756E63';
wwv_flow_imp.g_varchar2_table(752) := '74696F6E28652C742C722C6F297B632E736574506167652865292C632E73657446696C6C436F6C6F7228625B305D2C625B315D2C625B325D292C632E726563742854722C742C41722C67722C224622292C632E736574466F6E74282268656C7665746963';
wwv_flow_imp.g_varchar2_table(753) := '61222C22626F6C6422292C632E736574466F6E7453697A65284E72292C632E73657454657874436F6C6F722850725B305D2C50725B315D2C50725B325D293B76617220613D742B67722F322B2E333532382A4E722A2E33352C6C3D54723B632E74657874';
wwv_flow_imp.g_varchar2_table(754) := '284728722C6E2C7B434F554E543A6F2E6C656E6774687D292C54722B312C61292C4A742E666F72456163682866756E6374696F6E28652C74297B652E636F6C262676652870722E636F6C732C652E636F6C292626632E746578742853287965286F2C652E';
wwv_flow_imp.g_varchar2_table(755) := '636F6C2C2273756D22292C652E666D747C7C226D6F6E657922292C6C2B43725B745D2D312C612C7B616C69676E3A227269676874227D292C6C2B3D43725B745D7D297D2C7A723D303B7A723C62722E6C656E6774682D313B7A722B2B297B766172204D72';
wwv_flow_imp.g_varchar2_table(756) := '3D76722E736C69636528302C62725B7A725D2E6E293B46722862725B7A725D2E706167652C62725B7A725D2E792C70722E6C6162656C2C4D72292C46722862725B7A722B315D2E706167652C77722E746F702D67722C70722E6C6162656C46726F6D2C4D';
wwv_flow_imp.g_varchar2_table(757) := '72297D632E73657450616765285372292C632E736574466F6E74282268656C766574696361222C226E6F726D616C22292C632E73657454657874436F6C6F7228302C302C30297D7A28732E6761707C7C33297D7D656C7365205628732C6E292E66696C74';
wwv_flow_imp.g_varchar2_table(758) := '65722866756E6374696F6E2865297B72657475726E205728732E7768656E2C6E2C65297D292E736C69636528302C732E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B632E6175746F5461626C65287B7374617274593A';
wwv_flow_imp.g_varchar2_table(759) := '772C7468656D653A22706C61696E222C6D617267696E3A5028292C626F64793A5B5B4728732E746578742C6E2C65295D5D2C7374796C65733A7B666F6E7453697A653A732E73697A657C7C382C666F6E745374796C653A22626F6C64222C63656C6C5061';
wwv_flow_imp.g_varchar2_table(760) := '6464696E673A312E342C66696C6C436F6C6F723A70282428732E636F6C6F722C6E2C65297C7C222345364543463222297D7D292C7A2831297D297D656C73657B766172206B723D597428732C6E293B696628216B722972657475726E3B766172204F723D';
wwv_flow_imp.g_varchar2_table(761) := '6B722E6C6162656C3F2E333532382A6B722E7465787453697A652A312E343A303B4D28732C6B722E772C6B722E682B4F722C66756E6374696F6E28652C74297B76617220723D6B722E772F6B722E636F6C732C6E3D6B722E682F6B722E726F77732C6F3D';
wwv_flow_imp.g_varchar2_table(762) := '70286B722E636F6C6F72293B632E73657446696C6C436F6C6F72286F5B305D2C6F5B315D2C6F5B325D293B666F722876617220613D303B613C6B722E726F77733B612B2B29666F7228766172206C3D303B6C3C6B722E636F6C733B6C2B2B296966286B72';
wwv_flow_imp.g_varchar2_table(763) := '2E6461726B286C2C6129297B666F722876617220693D6C3B6C2B313C6B722E636F6C7326266B722E6461726B286C2B312C61293B296C2B2B3B632E7265637428652B692A722C742B612A6E2C286C2D692B31292A722C6E2B28613C6B722E726F77732D31';
wwv_flow_imp.g_varchar2_table(764) := '3F2E30323A30292C224622297D6B722E6C6162656C262628632E736574466F6E742822636F7572696572222C226E6F726D616C22292C632E736574466F6E7453697A65286B722E7465787453697A65292C632E73657454657874436F6C6F72286F5B305D';
wwv_flow_imp.g_varchar2_table(765) := '2C6F5B315D2C6F5B325D292C632E74657874286B722E746578742C652B6B722E772F322C742B6B722E682B2E333532382A6B722E7465787453697A652A312E312C7B616C69676E3A2263656E746572227D292C632E73657454657874436F6C6F7228302C';
wwv_flow_imp.g_varchar2_table(766) := '302C3029297D297D656C73657B766172204C723D5A7428732C6E2C6C293B696628214C722972657475726E3B4D28732C4C722E776D6D2C4C722E686D6D2C66756E6374696F6E28652C74297B632E616464496D616765284C722E646174612C22504E4722';
wwv_flow_imp.g_varchar2_table(767) := '2C652C742C4C722E776D6D2C4C722E686D6D2C766F696420302C224641535422297D297D656C73657B7661722044723D6A7428732C6E293B6966282144722972657475726E3B766172206A723D497428732C4472292C49723D226A7067223D3D3D44722E';
wwv_flow_imp.g_varchar2_table(768) := '6578743F224A504547223A22504E47222C52723D5A28732C6E2C732E736F757263653F5628732C6E295B305D3A6E756C6C293B4D28732C6A722E772C6A722E682C66756E6374696F6E28652C74297B632E616464496D6167652844722E646174612C4972';
wwv_flow_imp.g_varchar2_table(769) := '2C652C742C6A722E772C6A722E68292C52722626632E6C696E6B28652C742C6A722E772C6A722E682C7B75726C3A52727D297D297D7D292C432E746F3D632E696E7465726E616C2E6765744E756D6265724F66506167657328297D292C6B2E666F724561';
wwv_flow_imp.g_varchar2_table(770) := '63682866756E6374696F6E2874297B76617220723D4A7428652C742E637478293B69662872297B632E736574466F6E74282268656C766574696361222C22626F6C6422292C632E736574466F6E7453697A6528313030293B766172206E3D4B7428722C63';
wwv_flow_imp.g_varchar2_table(771) := '2E67657454657874576964746828722E74657874292C662C64292C6F3D722E616E676C652A4D6174682E50492F3138302C613D7028722E636F6C6F72293B632E736574466F6E7453697A65286E293B666F7228766172206C3D632E676574546578745769';
wwv_flow_imp.g_varchar2_table(772) := '64746828722E74657874292C693D2E333532382A6E2A2E372C733D662F322D6C2F322A4D6174682E636F73286F292B692F322A4D6174682E73696E286F292C753D642F322B6C2F322A4D6174682E73696E286F292B692F322A4D6174682E636F73286F29';
wwv_flow_imp.g_varchar2_table(773) := '2C683D742E66726F6D3B683C3D742E746F3B682B2B29632E736574506167652868292C632E736176654772617068696373537461746528292C632E736574475374617465286E657720632E475374617465287B6F7061636974793A722E6F706163697479';
wwv_flow_imp.g_varchar2_table(774) := '7D29292C632E73657454657874436F6C6F7228615B305D2C615B315D2C615B325D292C632E7465787428722E746578742C732C752C7B616E676C653A722E616E676C657D292C632E726573746F72654772617068696373537461746528293B632E736574';
wwv_flow_imp.g_varchar2_table(775) := '54657874436F6C6F7228302C302C30297D7D293B766172204F3D652E666F6F7465722C4C3D632E696E7465726E616C2E6765744E756D6265724F66506167657328292C443D745B305D7C7C7B533A7B7D2C543A7B7D7D2C6A3D66756E6374696F6E28652C';
wwv_flow_imp.g_varchar2_table(776) := '74297B76617220723D6B2E66696C7465722866756E6374696F6E2865297B72657475726E20743E3D652E66726F6D2626743C3D652E746F7D295B305D7C7C7B66726F6D3A312C746F3A4C7D3B72657475726E20537472696E672865292E7265706C616365';
wwv_flow_imp.g_varchar2_table(777) := '282F5C7B444F4350414745535C7D2F672C722E746F2D722E66726F6D2B31292E7265706C616365282F5C7B444F43504147455C7D2F672C742D722E66726F6D2B31297D3B69662854297B76617220493D68742854292C523D2131213D3D542E6C696E653B';
wwv_flow_imp.g_varchar2_table(778) := '6B2E666F72456163682866756E6374696F6E2865297B666F722876617220743D677428542C652E637478292C723D652E66726F6D3B723C3D652E746F3B722B2B296966282131213D3D542E6669727374506167657C7C72213D3D652E66726F6D297B6966';
wwv_flow_imp.g_varchar2_table(779) := '28632E736574506167652872292C542E66696C6C297B766172206E3D7028542E66696C6C293B632E73657446696C6C436F6C6F72286E5B305D2C6E5B315D2C6E5B325D292C632E7265637428302C432C662C412C224622297D766172206F3D682C613D66';
wwv_flow_imp.g_varchar2_table(780) := '2D682C693D743F70742854293A22223B69662874262628632E616464496D61676528742E696D2E646174612C226A7067223D3D3D742E696D2E6578743F224A504547223A22504E47222C227269676874223D3D3D693F662D682D742E773A2263656E7465';
wwv_flow_imp.g_varchar2_table(781) := '72223D3D3D693F28662D742E77292F323A682C432B28412D742E68292F322C742E772C742E68292C227269676874223D3D3D693F613D662D682D742E772D333A226C656674223D3D3D692626286F3D682B742E772B3329292C5B226C656674222C226365';
wwv_flow_imp.g_varchar2_table(782) := '6E746572222C227269676874225D2E666F72456163682866756E6374696F6E2874297B766172206E3D495B745D3B6966286E2626282263656E74657222213D3D747C7C2263656E74657222213D3D6929297B766172206C3D6A2847286E2E746578742C65';
wwv_flow_imp.g_varchar2_table(783) := '2E637478292E7265706C616365282F5C7B50414745535C7D2F672C4C292E7265706C616365282F5C7B504147455C7D2F672C72292C72292E73706C697428225C6E22292C733D2E333532382A6E2E73697A652A312E322C753D432B28412D732A6C2E6C65';
wwv_flow_imp.g_varchar2_table(784) := '6E677468292F322B2E333532382A6E2E73697A652A2E392C643D70286E2E636F6C6F72293B632E736574466F6E74282268656C766574696361222C6E2E626F6C643F22626F6C64223A226E6F726D616C22292C632E736574466F6E7453697A65286E2E73';
wwv_flow_imp.g_varchar2_table(785) := '697A65292C632E73657454657874436F6C6F7228645B305D2C645B315D2C645B325D292C6C2E666F72456163682866756E6374696F6E28652C72297B632E7465787428652C226C656674223D3D3D743F6F3A2263656E746572223D3D3D743F662F323A61';
wwv_flow_imp.g_varchar2_table(786) := '2C752B722A732C7B616C69676E3A747D297D297D7D292C52297B76617220733D7028542E6C696E65436F6C6F727C7C6C2E7072696D617279293B632E73657444726177436F6C6F7228735B305D2C735B315D2C735B325D292C632E7365744C696E655769';
wwv_flow_imp.g_varchar2_table(787) := '64746828542E6C696E6557696474687C7C2E33292C632E6C696E6528682C432B412C662D682C432B41297D7D7D292C632E736574466F6E74282268656C766574696361222C226E6F726D616C22292C632E73657454657874436F6C6F7228302C302C3029';
wwv_flow_imp.g_varchar2_table(788) := '2C632E73657444726177436F6C6F7228302C302C30297D6966284F297B666F722876617220553D313B553C3D4C3B552B2B297B632E736574506167652855292C632E736574466F6E74282268656C766574696361222C226E6F726D616C22292C632E7365';
wwv_flow_imp.g_varchar2_table(789) := '74466F6E7453697A65284F2E73697A657C7C37293B76617220423D70286C2E6D75746564293B632E73657454657874436F6C6F7228425B305D2C425B315D2C425B325D293B766172205F3D66756E6374696F6E2865297B72657475726E206A284728652C';
wwv_flow_imp.g_varchar2_table(790) := '44292E7265706C61636528227B504147457D222C55292E7265706C61636528227B50414745537D222C4C292C55297D3B6966284F2E6C656674297B76617220483D632E73706C697454657874546F53697A65285F284F2E6C656674292C2E37382A66293B';
wwv_flow_imp.g_varchar2_table(791) := '632E7465787428482C682C642D342D28482E6C656E6774682D31292A284F2E73697A657C7C37292A2E34297D4F2E72696768742626632E74657874285F284F2E7269676874292C662D682C642D352C7B616C69676E3A227269676874227D297D632E7365';
wwv_flow_imp.g_varchar2_table(792) := '7454657874436F6C6F7228302C302C30297D652E7469746C652626632E73657450726F70657274696573287B7469746C653A4728652E7469746C652C44297D292C66756E6374696F6E2865297B76617220743D652E696E7465726E616C2E6163726F666F';
wwv_flow_imp.g_varchar2_table(793) := '726D506C7567696E2C723D742626742E6163726F466F726D44696374696F6E617279526F6F743B696628722626722E4669656C64732626722E4669656C64732E6C656E677468262621722E5F5F6E72297B766172206E3D223C3C202F54797065202F466F';
wwv_flow_imp.g_varchar2_table(794) := '6E74202F53756274797065202F5479706531202F42617365466F6E74202F48656C766574696361202F456E636F64696E67202F57696E416E7369456E636F64696E67203E3E222C6F3D652E696E7465726E616C2E676574466F6E74282268656C76657469';
wwv_flow_imp.g_varchar2_table(795) := '6361222C226E6F726D616C22292E69643B722E44413D222F48656C7620222B28652E5F5F6E72466F726D53697A657C7C39292B2220546620302067222C4F626A6563742E646566696E6550726F706572747928722C224452222C7B656E756D657261626C';
wwv_flow_imp.g_varchar2_table(796) := '653A21302C636F6E666967757261626C653A21312C76616C75653A223C3C202F466F6E74203C3C202F48656C7620222B6E2B286F26262248656C7622213D3D6F3F22202F222B6F2B2220222B6E3A2222292B22202F5A614462203C3C202F54797065202F';
wwv_flow_imp.g_varchar2_table(797) := '466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F5A61706644696E6762617473203E3E203E3E203E3E227D292C4F626A6563742E646566696E6550726F706572747928722C224E656564417070656172616E636573222C7B';
wwv_flow_imp.g_varchar2_table(798) := '656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A2274727565227D292C722E5F5F6E723D21307D7D2863293B76617220582C4B2C6E652C61652C6C653D66756E6374696F6E28652C74297B76617220723D417272';
wwv_flow_imp.g_varchar2_table(799) := '61792E6973417272617928652E617070656E64293F652E617070656E643A5B5D3B72657475726E20722E6C656E6774683F742E6D61702866756E6374696F6E2865297B76617220743D5B5D3B72657475726E20722E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(800) := '6E2872297B6966287226265728722E7768656E2C652E6374782C6E756C6C2929696628722E75726C297B766172206E3D46745B4D7428722E75726C295D3B6E2626742E70757368286E297D656C736520696628722E6669656C64297B766172206F3D722E';
wwv_flow_imp.g_varchar2_table(801) := '736F757263653F5628722C652E637478293A5B652E6374782E646F637C7C7B7D5D2C613D537472696E6728722E6669656C64292E746F55707065724361736528293B6F2E666F72456163682866756E6374696F6E2865297B76617220723D652626655B61';
wwv_flow_imp.g_varchar2_table(802) := '5D3B722626742E7075736828527428537472696E672872292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C22222929297D297D7D292C7B61667465723A652E746F2C6974656D733A747D7D29';
wwv_flow_imp.g_varchar2_table(803) := '2E66696C7465722866756E6374696F6E2865297B72657475726E20652E6974656D732E6C656E6774687D293A5B5D7D28652C6B293B72657475726E206C652E6C656E6774683F77696E646F772E5044464C6962262677696E646F772E5044464C69622E50';
wwv_flow_imp.g_varchar2_table(804) := '4446446F63756D656E743F28583D632E6F75747075742822617272617962756666657222292C4B3D6C652C6E653D77696E646F772E5044464C69622C61653D302C6E652E504446446F63756D656E742E6C6F61642858292E7468656E2866756E6374696F';
wwv_flow_imp.g_varchar2_table(805) := '6E2865297B76617220743D50726F6D6973652E7265736F6C766528293B72657475726E204B2E666F72456163682866756E6374696F6E2872297B722E6974656D732E666F72456163682866756E6374696F6E286E297B743D742E7468656E2866756E6374';
wwv_flow_imp.g_varchar2_table(806) := '696F6E28297B72657475726E206E652E504446446F63756D656E742E6C6F6164286E2C7B69676E6F7265456E6372797074696F6E3A21307D297D292E7468656E2866756E6374696F6E2874297B72657475726E20652E636F7079506167657328742C742E';
wwv_flow_imp.g_varchar2_table(807) := '67657450616765496E64696365732829297D292E7468656E2866756E6374696F6E2874297B742E666F72456163682866756E6374696F6E2874297B652E696E736572745061676528722E61667465722B61652C74292C61652B2B7D297D292E6361746368';
wwv_flow_imp.g_varchar2_table(808) := '2866756E6374696F6E2865297B7468726F77206E6577204572726F7228612822706466417070656E64222C652626652E6D6573736167657C7C6529297D297D297D292C742E7468656E2866756E6374696F6E28297B72657475726E20652E736176652829';
wwv_flow_imp.g_varchar2_table(809) := '7D297D292E7468656E2866756E6374696F6E2865297B72657475726E20652E6275666665722E736C69636528652E627974654F66667365742C652E627974654F66667365742B652E627974654C656E677468297D29293A50726F6D6973652E72656A6563';
wwv_flow_imp.g_varchar2_table(810) := '74286E6577204572726F72286128226C69624C6F6164222C227064662D6C6962222929293A50726F6D6973652E7265736F6C766528632E6F7574707574282261727261796275666665722229297D66756E6374696F6E2074722865297B72657475726E20';
wwv_flow_imp.g_varchar2_table(811) := '537472696E6728652E6C6162656C7C7C652E6E616D65292E7265706C616365282F5C732B2F672C222022292E73756273747228302C3332297D66756E6374696F6E20727228652C742C72297B766172206E3D7B7374796C653A227468696E222C636F6C6F';
wwv_flow_imp.g_varchar2_table(812) := '723A7B617267623A67284C65297D7D3B652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A67284F65297D7D2C652E626F726465723D7B746F703A6E2C6C6566743A6E2C';
wwv_flow_imp.g_varchar2_table(813) := '626F74746F6D3A6E2C72696768743A6E7D2C652E70726F74656374696F6E3D7B6C6F636B65643A2121742E726561644F6E6C797D2C652E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65222C';
wwv_flow_imp.g_varchar2_table(814) := '686F72697A6F6E74616C3A22636865636B626F78223D3D3D742E696E7075743F2263656E746572223A226C656674222C77726170546578743A226D756C74696C696E65223D3D3D742E696E7075747D2C22636865636B626F78223D3D3D742E696E707574';
wwv_flow_imp.g_varchar2_table(815) := '3F28652E76616C75653D742E636865636B65643F44653A6A652C652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21312C666F726D756C61653A5B2722E298902CE2989222275D2C73686F77457272';
wwv_flow_imp.g_varchar2_table(816) := '6F724D6573736167653A21302C6572726F725469746C653A74722874292C6572726F723A22456C696A6120E29890206F20E298922E227D293A28652E76616C75653D22223D3D3D742E76616C75653F6E756C6C3A742E76616C75652C652E6E756D466D74';
wwv_flow_imp.g_varchar2_table(817) := '3D2240222C226C697374223D3D3D742E696E7075743F652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B7228742E6F7074696F6E73295D2C73686F774572726F724D';
wwv_flow_imp.g_varchar2_table(818) := '6573736167653A21302C6572726F725469746C653A74722874292C6572726F723A6128227069636B4C69737422297D3A742E6D61784C656E677468262628652E6461746156616C69646174696F6E3D7B747970653A22746578744C656E677468222C6F70';
wwv_flow_imp.g_varchar2_table(819) := '657261746F723A226C6573735468616E4F72457175616C222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B742E6D61784C656E6774685D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A74722874292C65';
wwv_flow_imp.g_varchar2_table(820) := '72726F723A6128226D61784C656E222C742E6D61784C656E677468297D29292C652E6E616D653D742E6E616D657D66756E6374696F6E206E7228652C742C722C6E297B766172206F3D6E65772077696E646F772E457863656C4A532E576F726B626F6F6B';
wwv_flow_imp.g_varchar2_table(821) := '2C6C3D41742865292C693D7B7D2C753D426528652C6E292C633D526528292C663D5B5D2C643D7B77733A6E756C6C2C6E3A302C7265663A7B7D7D3B6F2E63726561746F723D226E6F76615265706F7274223B76617220703D652E786C73782626652E786C';
wwv_flow_imp.g_varchar2_table(822) := '73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C73782E73686565744E616D657C7C612822736865657422297D5D2C763D777428652C22786C737822292C623D652E706167657C7C7B7D2C773D7B747970653A22706174746572';
wwv_flow_imp.g_varchar2_table(823) := '6E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A67286C2E7072696D617279297D7D3B66756E6374696F6E20792865297B666F722876617220743D452865292E7265706C616365282F5B5C5B5C5D5D2F672C2222292E73';
wwv_flow_imp.g_varchar2_table(824) := '756273747228302C3331297C7C61282273686565744E22292C723D742C6E3D323B695B722E746F4C6F7765724361736528295D3B29723D742E73756273747228302C33312D537472696E67286E292E6C656E6774682D31292B225F222B6E2C6E2B2B3B72';
wwv_flow_imp.g_varchar2_table(825) := '657475726E20695B722E746F4C6F7765724361736528295D3D21302C727D66756E6374696F6E20432865297B72657475726E7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A67286529';
wwv_flow_imp.g_varchar2_table(826) := '7D7D7D66756E6374696F6E20412865297B76617220743D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6728657C7C5865297D7D3B72657475726E7B746F703A742C6C6566743A742C626F74746F6D3A742C72696768743A747D7D6675';
wwv_flow_imp.g_varchar2_table(827) := '6E6374696F6E204E2865297B76617220743D652E6A6F696E28222C22293B696628742E6C656E6774683C3D3235302626212F5B2C225D2F2E7465737428652E6A6F696E28222229292972657475726E2722272B742B2722273B696628642E7265665B745D';
wwv_flow_imp.g_varchar2_table(828) := '2972657475726E20642E7265665B745D3B642E77737C7C28642E77733D6F2E616464576F726B7368656574287928226E725F6C697374617322292C7B73746174653A2268696464656E227D29293B76617220723D2B2B642E6E3B652E666F724561636828';
wwv_flow_imp.g_varchar2_table(829) := '66756E6374696F6E28652C74297B642E77732E67657443656C6C28742B312C72292E76616C75653D657D293B766172206E3D642E77732E676574436F6C756D6E2872292E6C65747465723B72657475726E20642E7265665B745D3D2227222B642E77732E';
wwv_flow_imp.g_varchar2_table(830) := '6E616D652B22272124222B6E2B2224313A24222B6E2B2224222B652E6C656E6774682C642E7265665B745D7D72657475726E20742E666F72456163682866756E6374696F6E28722C6E297B76617220693D742E6C656E6774683E313F225F222B286E2B31';
wwv_flow_imp.g_varchar2_table(831) := '293A22223B702E666F72456163682866756E6374696F6E286E297B76617220643D47286E2E6E616D652C72293B4A2626742E6C656E6774683E31262628643D47286E2E6D657267654E616D657C7C28702E6C656E6774683E313F227B444F432E444F435F';
wwv_flow_imp.g_varchar2_table(832) := '4B45597D20222B6E2E6E616D653A227B444F432E444F435F4B45597D22292C7229293B76617220453D6F2E616464576F726B736865657428792864292C7B7061676553657475703A7B6F7269656E746174696F6E3A622E6F7269656E746174696F6E7C7C';
wwv_flow_imp.g_varchar2_table(833) := '22706F727472616974222C706170657253697A653A66655B537472696E6728622E73697A657C7C226C657474657222292E746F4C6F7765724361736528295D7C7C312C666974546F506167653A21302C666974546F57696474683A312C666974546F4865';
wwv_flow_imp.g_varchar2_table(834) := '696768743A307D7D292C503D6E2E73656374696F6E733F6E2E73656374696F6E732E6D61702866756E6374696F6E2865297B72657475726E226E756D626572223D3D747970656F6620653F765B655D3A762E66696C7465722866756E6374696F6E287429';
wwv_flow_imp.g_varchar2_table(835) := '7B72657475726E20742E69643D3D3D657D295B305D7D292E66696C74657228426F6F6C65616E293A763B503D627428636528502E66696C7465722866756E6374696F6E2865297B72657475726E20437428652C72297D29292E66696C7465722866756E63';
wwv_flow_imp.g_varchar2_table(836) := '74696F6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662822786C737822293E3D30292626437428652C72297D292C72293B766172207A3D342C6B3D312C4F3D7B7D2C4C3D302C443D6E756C6C2C6A';
wwv_flow_imp.g_varchar2_table(837) := '3D6E756C6C2C493D21312C523D66756E6374696F6E2865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E22636F6C756D6E6173223D3D3D742E747970653F4D6174682E6D617828652C547428742C22786C';
wwv_flow_imp.g_varchar2_table(838) := '7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B5228742E73656373292B317D2C2D3129293A22677275706F223D3D3D742E747970653F4D6174682E6D617828652C5228457428742C22786C737822';
wwv_flow_imp.g_varchar2_table(839) := '2C722929293A4D6174682E6D617828652C227461626C61223D3D3D742E747970653F746528742C722C5628742C7229292E6C656E6774683A226669636861223D3D3D742E747970653F322A28742E636F6C756D6E737C7C33293A22666F726D756C617269';
wwv_flow_imp.g_varchar2_table(840) := '6F223D3D3D742E747970653F322A28742E636F6C756D6E737C7C32293A227461726A65746173223D3D3D742E747970653F647428742C722C6C292E6E3A22746578746F223D3D3D742E747970657C7C22616C65727461223D3D3D742E747970653F343A32';
wwv_flow_imp.g_varchar2_table(841) := '297D2C32297D3B66756E6374696F6E205528652C74297B76617220723D537472696E67286E756C6C3D3D743F22223A74292E6C656E6774683B4F5B652B3D425D3D4D6174682E6D696E2836302C4D6174682E6D6178284F5B655D7C7C382C722B3229297D';
wwv_flow_imp.g_varchar2_table(842) := '502E666F72456163682866756E6374696F6E2865297B22636F6C756D6E6173223D3D3D652E747970652626287A3D4D6174682E6D6178287A2C547428652C22786C7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B726574';
wwv_flow_imp.g_varchar2_table(843) := '75726E20652B5228742E73656373292B317D2C2D312929292C227461626C61223D3D3D652E747970652626284C2B2B2C7A3D4D6174682E6D6178287A2C746528652C722C5628652C7229292E6C656E67746829292C226669636861223D3D3D652E747970';
wwv_flow_imp.g_varchar2_table(844) := '652626287A3D4D6174682E6D6178287A2C322A28652E636F6C756D6E737C7C332929292C22666F726D756C6172696F223D3D3D652E747970652626287A3D4D6174682E6D6178287A2C322A28652E636F6C756D6E737C7C322929292C227461726A657461';
wwv_flow_imp.g_varchar2_table(845) := '73223D3D3D652E747970652626287A3D4D6174682E6D6178287A2C647428652C722C6C292E6E29292C22677275706F223D3D3D652E747970652626287A3D4D6174682E6D6178287A2C5228457428652C22786C7378222C72292929297D293B7661722042';
wwv_flow_imp.g_varchar2_table(846) := '3D302C483D21313B66756E6374696F6E205828652C74297B72657475726E20452E67657443656C6C28652C742B42297D66756E6374696F6E204A28652C742C722C6E297B452E6D6572676543656C6C7328652C742B422C722C6E2B42297D66756E637469';
wwv_flow_imp.g_varchar2_table(847) := '6F6E204B28652C74297B76617220723D452E676574526F772865293B722E6865696768743D4D6174682E6D617828722E6865696768747C7C302C74297D66756E6374696F6E20616528652C742C722C6E2C61297B766172206C3D6F2E616464496D616765';
wwv_flow_imp.g_varchar2_table(848) := '287B6261736536343A652E646174612C657874656E73696F6E3A226A7067223D3D3D652E6578743F226A706567223A22706E67227D293B452E616464496D616765286C2C7B746C3A7B636F6C3A422C726F773A6B2D317D2C6578743A7B77696474683A33';
wwv_flow_imp.g_varchar2_table(849) := '2E37382A742C6865696768743A332E37382A727D2C68797065726C696E6B733A613F7B68797065726C696E6B3A612C746F6F6C7469703A617D3A766F696420307D292C6B2B3D4D6174682E6365696C28332E37382A722F3230292B286E3F303A31297D66';
wwv_flow_imp.g_varchar2_table(850) := '756E6374696F6E20756528652C742C722C6E297B4A286B2C312C6B2C7A293B766172206F3D58286B2C31293B6F2E76616C75653D652C6F2E66696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C';
wwv_flow_imp.g_varchar2_table(851) := '65222C77726170546578743A21307D2C6E26264B286B2C483F4D6174682E6D6178286E2C31352A4D6174682E6365696C28537472696E6728657C7C2222292E6C656E6774682F4D6174682E6D61782831362C392A7A2929293A6E292C6B2B2B7D69662850';
wwv_flow_imp.g_varchar2_table(852) := '2E666F72456163682866756E6374696F6E2074286E297B76617220613D6E2E747970653B69662822636F6C756D6E6173223D3D3D61297B76617220753D6B2C663D6B2C643D422C703D7A2C6D3D302C763D483B72657475726E20483D21302C5474286E2C';
wwv_flow_imp.g_varchar2_table(853) := '22786C7378222C722C313030292E666F72456163682866756E6374696F6E2865297B76617220723D5228652E73656373293B423D642B6D2C7A3D722C6B3D752C652E736563732E666F72456163682874292C663D4D6174682E6D617828662C6B292C6D2B';
wwv_flow_imp.g_varchar2_table(854) := '3D722B317D292C423D642C7A3D702C483D762C766F6964286B3D66297D69662822677275706F223D3D3D61297B76617220623D722C793D693B72657475726E205374286E2C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C';
wwv_flow_imp.g_varchar2_table(855) := '693D792B652E7375663B766172206F3D4574286E2C22786C7378222C72292C613D6B3B6966286F2E6C656E6774687C7C6E2E7469746C65297B6E2E7469746C65262675652847286E2E7469746C652C72292C43286E2E7469746C6546696C6C7C7C6C2E70';
wwv_flow_imp.g_varchar2_table(856) := '72696D617279292C7B626F6C643A21302C636F6C6F723A7B617267623A67286E2E7469746C65436F6C6F727C7C6C2E6865616454657874297D7D2C3230292C6F2E666F72456163682874293B76617220733D4D6174682E6D617828612C6B2D31293B6966';
wwv_flow_imp.g_varchar2_table(857) := '286E2E66696C6C29666F722876617220753D613B753C3D733B752B2B29666F722876617220633D313B633C3D7A3B632B2B297B76617220663D5828752C63293B662E66696C6C2626227061747465726E223D3D3D662E66696C6C2E747970657C7C28662E';
wwv_flow_imp.g_varchar2_table(858) := '66696C6C3D43286E2E66696C6C29297D6966286E2E626F7264657229666F722876617220643D7B7374796C653A227468696E222C636F6C6F723A7B617267623A67286E2E626F72646572436F6C6F727C7C5865297D7D2C683D613B683C3D733B682B2B29';
wwv_flow_imp.g_varchar2_table(859) := '666F722876617220703D313B703C3D7A3B702B2B29696628683D3D3D617C7C683D3D3D737C7C313D3D3D707C7C703D3D3D7A297B766172206D3D5828682C70292C763D6C65286D2E626F726465727C7C7B7D293B683D3D3D61262628762E746F703D6429';
wwv_flow_imp.g_varchar2_table(860) := '2C683D3D3D73262628762E626F74746F6D3D64292C313D3D3D70262628762E6C6566743D64292C703D3D3D7A262628762E72696768743D64292C6D2E626F726465723D767D6B3D732B312B28303D3D3D6E2E6761703F303A31297D7D292C723D622C766F';
wwv_flow_imp.g_varchar2_table(861) := '696428693D79297D69662822686561646572223D3D3D61297B7661722063653D6674286E2C6C292C66653D6E2E66696C6C3F432863652E66696C6C293A772C70653D7B617267623A672863652E636F6C6F72297D2C53653D7B626F6C643A21302C73697A';
wwv_flow_imp.g_varchar2_table(862) := '653A63652E73697A652C636F6C6F723A70657D2C41653D7B73697A653A6E2E7375627469746C653F63652E73756253697A653A63652E726967687453697A652C636F6C6F723A70657D3B6E2E666F6E7426262853652E6E616D653D41652E6E616D653D63';
wwv_flow_imp.g_varchar2_table(863) := '652E666F6E745B315D292C75652847286E2E7469746C652C72292C66652C53652C4D6174682E6D61782832362C4D6174682E726F756E6428312E382A63652E73697A652929292C286E2E72696768747C7C6E2E7375627469746C652926267565285B4728';
wwv_flow_imp.g_varchar2_table(864) := '6E2E7375627469746C652C72292C47286E2E72696768742C72295D2E66696C74657228426F6F6C65616E292E6A6F696E28222020207C20202022292C66652C41652C4D6174682E6D61782831362C4D6174682E726F756E6428312E382A41652E73697A65';
wwv_flow_imp.g_varchar2_table(865) := '2929292C6B2B2B7D656C73652069662822746578746F223D3D3D61296565286E2C72292E666F72456163682866756E6374696F6E2874297B4A286B2C312C6B2C7A293B76617220723D58286B2C31292C6F3D5128742C7B666F6E743A6E2E666F6E747C7C';
wwv_flow_imp.g_varchar2_table(866) := '652E706167652626652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F722C6C696E6B3A6C2E6C696E6B7D293B722E76616C75653D7B72696368546578743A6F2E6D61702866756E6374696F6E2865297B72657475726E7B746578743A652E742C';
wwv_flow_imp.g_varchar2_table(867) := '666F6E743A7B626F6C643A212821652E622626216E2E626F6C64292C6974616C69633A212821652E692626216E2E6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F696420302C6E616D653A';
wwv_flow_imp.g_varchar2_table(868) := '715B652E665D5B315D2C636F6C6F723A652E633F7B617267623A6728652E63297D3A766F696420302C73697A653A6E2E73697A657C7C31307D7D7D297D3B76617220613D6F2E66696C7465722866756E6374696F6E2865297B72657475726E20652E687D';
wwv_flow_imp.g_varchar2_table(869) := '295B305D3B61262628722E76616C75653D7B746578743A722E76616C75652C68797065726C696E6B3A612E687D292C722E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22746F70222C686F72697A6F6E74616C3A226A';
wwv_flow_imp.g_varchar2_table(870) := '757374696679223D3D3D6E2E616C69676E3F226A757374696679223A6E2E616C69676E7C7C226C656674227D2C4B286B2C4D6174682E6D61782831352C31352A4D6174682E6365696C28742E6C656E6774682F28483F4D6174682E6D61782831362C392A';
wwv_flow_imp.g_varchar2_table(871) := '7A293A313430292929292C6B2B2B7D293B656C736520696628226573706163696F223D3D3D61296B2B2B3B656C73652069662822696D6167656E223D3D3D61297B7661722050653D6A74286E2C72293B6966285065297B766172206B653D4974286E2C50';
wwv_flow_imp.g_varchar2_table(872) := '65293B61652850652C6B652E772C6B652E682C21312C5A286E2C722C6E2E736F757263653F56286E2C72295B305D3A6E756C6C29297D7D656C736520696628226772616669636F223D3D3D61297B766172204F653D5A74286E2C722C6C293B4F65262661';
wwv_flow_imp.g_varchar2_table(873) := '65284F652C4F652E776D6D2C4F652E686D6D297D656C73652069662822636F6469676F223D3D3D61297B766172204C653D5974286E2C72293B6966284C65297B7661722044653D7174284C65293B69662861652844652C44652E776D6D2C44652E686D6D';
wwv_flow_imp.g_varchar2_table(874) := '2C4C652E6C6162656C292C4C652E6C6162656C297B766172206A653D58286B2C31293B6A652E76616C75653D4C652E746578742C6A652E666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A4C652E7465787453697A657D2C6B2B';
wwv_flow_imp.g_varchar2_table(875) := '3D327D7D7D656C7365206966282273616C746F223D3D3D61296B2B2B3B656C736520696628226669636861223D3D3D61297B7661722049653D56286E2C72295B305D7C7C7B7D2C52653D6E2E636F6C756D6E737C7C332C42653D313B4B6528286E2E6669';
wwv_flow_imp.g_varchar2_table(876) := '656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5728652E7768656E2C722C4965297D292C5265292E666F72456163682866756E6374696F6E28652C74297B743E3026266B2B2B3B76617220';
wwv_flow_imp.g_varchar2_table(877) := '6F3D652E736F6D652866756E6374696F6E2865297B72657475726E21652E656D707479262622746F70223D3D3D6E7428652E662C6E292E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220';
wwv_flow_imp.g_varchar2_table(878) := '743D652E663B42653D312B322A652E636F6C3B76617220612C693D6E7428742C6E292C753D42652B322A652E7370616E2D312C633D6E756C6C2C663D4728742E6C6162656C2C722C4965293B696628226C656674223D3D3D692E706F73297B696628633D';
wwv_flow_imp.g_varchar2_table(879) := '58286B2C4265292C613D58286B2C42652B31292C632E76616C75653D617428662C69292C632E666F6E743D6E2E6C6162656C436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A67286E2E6C6162656C436F6C6F72297D7D3A7B626F6C64';
wwv_flow_imp.g_varchar2_table(880) := '3A21307D2C6E2E6C6162656C46696C6C262628632E66696C6C3D43286E2E6C6162656C46696C6C29292C6E2E76616C7565436F6C6F72262628612E666F6E743D7B636F6C6F723A7B617267623A67286E2E76616C7565436F6C6F72297D7D292C6E2E6772';
wwv_flow_imp.g_varchar2_table(881) := '6964262628632E626F726465723D612E626F726465723D41286E2E626F72646572436F6C6F72292C632E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C28652E7370616E3E317C7C6F292626';
wwv_flow_imp.g_varchar2_table(882) := '284A286B2C42652B312C6F3F6B2B313A6B2C75292C6E2E677269642929666F722876617220643D42652B323B643C3D753B642B2B2958286B2C64292E626F726465723D41286E2E626F72646572436F6C6F72293B6F2626284A286B2C42652C6B2B312C42';
wwv_flow_imp.g_varchar2_table(883) := '65292C632E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C692E7374796C656426266F7428632C692C2131297D656C73657B76617220703D22746F70223D3D3D692E706F7326266F3F6B2B31';
wwv_flow_imp.g_varchar2_table(884) := '3A6B2C6D3D226E6F6E65223D3D3D692E706F7326266F3F6B2B313A703B69662822746F70223D3D3D692E706F73297B28633D58286B2C426529292E76616C75653D617428662C69292C753E426526264A286B2C42652C6B2C75292C6E2E67726964262628';
wwv_flow_imp.g_varchar2_table(885) := '632E626F726465723D41286E2E626F72646572436F6C6F7229293B76617220763D747428742C722C4965293B6F7428632C692C21302C762626762E616C69676E297D613D5828702C4265292C28753E42657C7C6D3E702926264A28702C42652C6D2C7529';
wwv_flow_imp.g_varchar2_table(886) := '2C6E2E76616C7565436F6C6F72262628612E666F6E743D7B636F6C6F723A7B617267623A67286E2E76616C7565436F6C6F72297D7D292C6E2E67726964262628612E626F726465723D41286E2E626F72646572436F6C6F7229297D76617220623D2F5E5C';
wwv_flow_imp.g_varchar2_table(887) := '7B5B5E7D7C5D2B5C7D242F2E7465737428742E76616C75657C7C222229262621742E6D61703F5F28722C742E76616C75652E736C69636528312C2D31292C4965293A6E756C6C3B682862292626215428742E666D74293F28612E76616C75653D622C226D';
wwv_flow_imp.g_varchar2_table(888) := '6F6E6579223D3D3D742E666D743F612E6E756D466D743D22232C2323302E3030223A4D28742E666D7429262628612E6E756D466D743D4628742E666D7429292C612E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A226461';
wwv_flow_imp.g_varchar2_table(889) := '7465223D3D3D742E666D742626782862293F28612E76616C75653D782862292C612E6E756D466D743D732E786C2C612E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A612E76616C75653D4D6528742C722C4965293B7661';
wwv_flow_imp.g_varchar2_table(890) := '7220773D5A28742C722C4965293B77262628612E76616C75653D7B746578743A537472696E67284D6528742C722C496529292C68797065726C696E6B3A777D2C612E666F6E743D7B756E6465726C696E653A21302C636F6C6F723A7B617267623A67286C';
wwv_flow_imp.g_varchar2_table(891) := '2E6C696E6B297D7D292C6E2E67726964262628612E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674222C766572746963616C3A226D6964646C65222C77726170546578743A21307D293B76617220793D747428742C722C4965293B69';
wwv_flow_imp.g_varchar2_table(892) := '662879297B696628792E626F6C647C7C792E636F6C6F72297B76617220453D7B7D3B4F626A6563742E6B65797328612E666F6E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B455B655D3D612E666F6E745B655D7D292C792E626F6C';
wwv_flow_imp.g_varchar2_table(893) := '64262628452E626F6C643D2130292C792E636F6C6F72262628452E636F6C6F723D7B617267623A6728792E636F6C6F72297D292C612E666F6E743D457D696628792E616C69676E297B76617220533D7B7D3B4F626A6563742E6B65797328612E616C6967';
wwv_flow_imp.g_varchar2_table(894) := '6E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B535B655D3D612E616C69676E6D656E745B655D7D292C532E686F72697A6F6E74616C3D792E616C69676E2C612E616C69676E6D656E743D537D792E66696C6C262628612E66';
wwv_flow_imp.g_varchar2_table(895) := '696C6C3D4328792E66696C6C29297D226C656674223D3D3D692E706F733F28552842652C66292C313D3D3D652E7370616E2626552842652B312C4D6528742C722C49652929293A313D3D3D652E7370616E2626552842652B312C537472696E67284D6528';
wwv_flow_imp.g_varchar2_table(896) := '742C722C496529292E73756273747228302C343029297D7D292C6F26266B2B2B7D292C6B2B3D327D656C736520696628227461726A65746173223D3D3D6129666F7228766172205F653D6474286E2C722C6C292C47653D303B47653C5F652E6974656D73';
wwv_flow_imp.g_varchar2_table(897) := '2E6C656E6774683B47652B3D5F652E6E297B7661722048653D313B5F652E6974656D732E736C6963652847652C47652B5F652E6E292E666F72456163682866756E6374696F6E28652C74297B76617220723D58286B2C742B31292C6E3D58286B2B312C74';
wwv_flow_imp.g_varchar2_table(898) := '2B31292C6F3D5F652E616363656E743F7B6C6566743A7B7374796C653A22746869636B222C636F6C6F723A7B617267623A67285F652E616363656E74297D7D7D3A7B7D3B722E76616C75653D652E6C6162656C2C722E666F6E743D7B73697A653A5F652E';
wwv_flow_imp.g_varchar2_table(899) := '6C6162656C53697A652B312C636F6C6F723A7B617267623A67285F652E6C6162656C436F6C6F72297D7D2C6E2E76616C75653D652E76616C75652C6E2E666F6E743D7B626F6C643A21302C73697A653A5F652E73697A652C636F6C6F723A7B617267623A';
wwv_flow_imp.g_varchar2_table(900) := '6728652E636F6C6F727C7C5F652E76616C7565436F6C6F72297D7D2C5B722C6E5D2E666F72456163682866756E6374696F6E2865297B652E66696C6C3D43285F652E66696C6C292C652E626F726465723D6F2C652E616C69676E6D656E743D7B76657274';
wwv_flow_imp.g_varchar2_table(901) := '6963616C3A226D6964646C65222C696E64656E743A312C77726170546578743A21307D7D292C5528742B312C652E6C6162656C292C5528742B312C537472696E6728652E76616C7565292E73756273747228302C3430292B2220202020202022292C4865';
wwv_flow_imp.g_varchar2_table(902) := '3D4D6174682E6D61782848652C4D6174682E6365696C28537472696E6728652E76616C7565292E6C656E6774682F343029297D292C4B286B2C3136292C4B286B2B312C4D6174682E726F756E6428312E372A5F652E73697A65292A4865292C6B2B3D337D';
wwv_flow_imp.g_varchar2_table(903) := '656C73652069662822666F726D756C6172696F223D3D3D61297B7661722057653D6E2E636F6C756D6E737C7C322C56653D312C24653D5565286E2C722C69293B4B652824652C5765292E666F72456163682866756E6374696F6E28652C74297B743E3026';
wwv_flow_imp.g_varchar2_table(904) := '266B2B2B3B76617220723D652E736F6D652866756E6374696F6E2865297B72657475726E21652E656D707479262622746F70223D3D3D652E662E6C61622E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D7074';
wwv_flow_imp.g_varchar2_table(905) := '79297B76617220743D652E662C6E3D742E6C61623B56653D312B322A652E636F6C2C6328742E6E616D65293B766172206F3D56652B322A652E7370616E2D312C613D22636865636B626F78223D3D3D742E696E7075743F22223A742E76616C75652E6C65';
wwv_flow_imp.g_varchar2_table(906) := '6E6774683E32303F742E76616C75653A6E6577204172726179283231292E6A6F696E28227822293B696628226C656674223D3D3D6E2E706F73297B766172206C3D58286B2C5665292C693D58286B2C56652B31293B72657475726E206C2E76616C75653D';
wwv_flow_imp.g_varchar2_table(907) := '617428742E6C6162656C2C6E292C6C2E666F6E743D7B626F6C643A21307D2C6C2E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65227D2C28652E7370616E3E317C7C722926264A286B2C5665';
wwv_flow_imp.g_varchar2_table(908) := '2B312C723F6B2B313A6B2C6F292C7226264A286B2C56652C6B2B312C5665292C6E2E7374796C656426266F74286C2C6E2C2131292C727228692C742C4E292C742E6C696E65733E3126264B28723F6B2B313A6B2C31352A742E6C696E6573292C55285665';
wwv_flow_imp.g_varchar2_table(909) := '2C742E6C6162656C292C766F696428313D3D3D652E7370616E2626552856652B312C6129297D76617220733D22746F70223D3D3D6E2E706F732626723F6B2B313A6B2C753D226E6F6E65223D3D3D6E2E706F732626723F6B2B313A733B69662822746F70';
wwv_flow_imp.g_varchar2_table(910) := '223D3D3D6E2E706F73297B76617220663D58286B2C5665293B662E76616C75653D617428742E6C6162656C2C6E292C6F3E566526264A286B2C56652C6B2C6F292C6F7428662C6E2C2130297D286F3E56657C7C753E732926264A28732C56652C752C6F29';
wwv_flow_imp.g_varchar2_table(911) := '2C7272285828732C5665292C742C4E292C742E6C696E65733E3126264B28752C31352A742E6C696E6573292C313D3D3D652E7370616E2626552856652B312C61297D7D292C7226266B2B2B7D292C24652E6C656E677468262628493D21302C6B2B3D3229';
wwv_flow_imp.g_varchar2_table(912) := '7D656C73652069662822616C65727461223D3D3D612956286E2C72292E66696C7465722866756E6374696F6E2865297B72657475726E2057286E2E7768656E2C722C65297D292E736C69636528302C6E2E656163683F3939393A31292E666F7245616368';
wwv_flow_imp.g_varchar2_table(913) := '2866756E6374696F6E2865297B75652847286E2E746578742C722C65292C432824286E2E636F6C6F722C722C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C6B2B2B3B656C736520696628227461626C61223D3D3D61297B';
wwv_flow_imp.g_varchar2_table(914) := '7661722059653D56286E2C72293B6966282159652E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B7661722071653D7465286E2C722C5965293B6966286E2E7469746C65297B4A286B';
wwv_flow_imp.g_varchar2_table(915) := '2C312C6B2C71652E6C656E677468293B766172205A653D58286B2C31293B5A652E76616C75653D47286E2E7469746C652C72292C5A652E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A67286C2E6865616454657874297D7D2C5A652E';
wwv_flow_imp.g_varchar2_table(916) := '66696C6C3D772C6B2B2B7D7661722051653D6B3B6966286E2E67726F757073297B7661722065743D313B7265286E2C7165292E666F72456163682866756E6374696F6E2865297B652E636F6C733E31262621652E67617026264A286B2C65742C6B2C6574';
wwv_flow_imp.g_varchar2_table(917) := '2B652E636F6C732D31293B76617220743D58286B2C6574293B696628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B4A286B2C65742B722C6B2B312C65742B72293B766172206F3D58286B2C65742B72293B6F2E7661';
wwv_flow_imp.g_varchar2_table(918) := '6C75653D71655B652E66726F6D2B725D2E6C6162656C2C6F2E66696C6C3D772C6F2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A67286C2E6865616454657874297D7D2C6F2E616C69676E6D656E743D7B686F72697A6F6E74616C3A';
wwv_flow_imp.g_varchar2_table(919) := '4A652871655B652E66726F6D2B725D2C6E292C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C552865742B722C71655B652E66726F6D2B725D2E6C6162656C297D65742B3D652E636F6C737D656C736520742E76616C7565';
wwv_flow_imp.g_varchar2_table(920) := '3D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D772C742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A67286C2E6865616454657874297D7D2C742E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E74657222';
wwv_flow_imp.g_varchar2_table(921) := '2C766572746963616C3A226D6964646C65227D2C65742B3D652E636F6C737D292C6B2B2B7D7661722072743D6B2C6C743D7B7D3B6966286E2E67726F75707326267265286E2C7165292E666F72456163682866756E6374696F6E2865297B696628652E67';
wwv_flow_imp.g_varchar2_table(922) := '617029666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B296C745B745D3D317D292C71652E666F72456163682866756E6374696F6E28652C74297B696628216C745B745D297B76617220723D58286B2C742B3129';
wwv_flow_imp.g_varchar2_table(923) := '3B722E76616C75653D652E6C6162656C2C722E66696C6C3D772C722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A67286C2E6865616454657874297D7D2C722E616C69676E6D656E743D7B686F72697A6F6E74616C3A4A6528652C6E';
wwv_flow_imp.g_varchar2_table(924) := '292C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C5528742B312C652E6C6162656C297D7D292C6B2B2B2C2159652E6C656E6774682972657475726E204A286B2C312C6B2C71652E6C656E677468292C58286B2C31292E76';
wwv_flow_imp.g_varchar2_table(925) := '616C75653D47286E2E656D707479546578742C72292C58286B2C31292E666F6E743D7B6974616C69633A21307D2C766F6964286B2B3D32293B7661722069743D6B2C73743D4E65286E2C5965292C75743D5465286E292C63743D5B5D2C68743D4D617468';
wwv_flow_imp.g_varchar2_table(926) := '2E6D617828312C4365286E292E6C656E677468292C70743D21312C67743D66756E6374696F6E28652C742C722C6F2C612C692C75297B76617220633D78652871652C742C722C6F292C663D62652874292C643D66756E6374696F6E2865297B7265747572';
wwv_flow_imp.g_varchar2_table(927) := '6E20652E66696C6C3D43286C2E746F74616C73292C652E666F6E743D6E2E746F74616C73436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A67286E2E746F74616C73436F6C6F72297D7D3A7B626F6C643A21307D2C657D3B28632E6174';
wwv_flow_imp.g_varchar2_table(928) := '3E317C7C303D3D3D632E61742926264A28652C312C652C632E61747C7C71652E6C656E677468293B76617220683D64285828652C3129293B72657475726E20682E76616C75653D6F2C682E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C65';
wwv_flow_imp.g_varchar2_table(929) := '6674227D2C303D3D3D632E61742626652B2B2C71652E666F72456163682866756E6374696F6E286E2C6F297B69662821286F3C632E617429297B766172206C3D64285828652C6F2B3129292C683D6E2E636F6C3F766528742C6E2E636F6C293A6E756C6C';
wwv_flow_imp.g_varchar2_table(930) := '3B69662868297B76617220703D452E676574436F6C756D6E286F2B312B42292E6C65747465722C673D702B612B223A222B702B692C6D3D796528722C682E636F6C2C682E666E292C763D226D696E22213D3D682E666E2626226D617822213D3D682E666E';
wwv_flow_imp.g_varchar2_table(931) := '7C7C6E756C6C3D3D3D6D7C7C7765286D293F6E756C6C3A78286D292C623D6E756C6C3D3D6D3F6E756C6C3A767C7C287765286D293F4D6174682E726F756E64283130302A4E756D626572286D29292F3130303A537472696E67286D29293B6C2E76616C75';
wwv_flow_imp.g_varchar2_table(932) := '653D7B666F726D756C613A28753F22535542544F54414C28222B64655B682E666E5D2B222C223A68655B682E666E5D2B222822292B672B2229222C726573756C743A627D3B76617220773D22636F756E74223D3D3D682E666E3F22232C232330223A763F';
wwv_flow_imp.g_varchar2_table(933) := '732E786C3A4D286E2E666D74293F46286E2E666D74293A22232C2323302E3030223B6C2E6E756D466D743D662626676528682E666E293F2722272B676528682E666E292B272022272B773A772C6C2E616C69676E6D656E743D7B686F72697A6F6E74616C';
wwv_flow_imp.g_varchar2_table(934) := '3A227269676874227D2C6E756C6C3D3D3D627C7C767C7C55286F2B312C77652862293F5328622C4D286E2E666D7429262622636F756E7422213D3D682E666E3F6E2E666D743A226D6F6E657922293A62297D7D7D292C652B317D3B73742E666F72456163';
wwv_flow_imp.g_varchar2_table(935) := '682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B297B6E2E627265616B50616765262621652E6C766C26262870742626452E676574526F77286B2D31292E61646450616765427265616B28292C70743D2130292C4A286B2C312C6B';
wwv_flow_imp.g_varchar2_table(936) := '2C71652E6C656E677468293B76617220743D58286B2C31293B72657475726E20742E76616C75653D7A65286E2C652C72292C742E666F6E743D7B626F6C643A21307D2C742E66696C6C3D43284665286C2C652E6C766C29292C766F6964206B2B2B7D6966';
wwv_flow_imp.g_varchar2_table(937) := '2822737562223D3D3D652E6B2972657475726E206B3D6774286B2C75742C652E726F77732C7A65286E2C652C72292C63745B652E6C766C7C7C305D2C6B2D312C2130292C766F69642863745B652E6C766C7C7C305D3D6E756C6C293B666F722876617220';
wwv_flow_imp.g_varchar2_table(938) := '613D303B613C68743B612B2B296E756C6C213D3D63745B615D2626766F69642030213D3D63745B615D7C7C2863745B615D3D6B293B76617220693D652E722C753D652E692C633D6965286E2C7165292C663D59286E2E726F775374796C652C722C69293B';
wwv_flow_imp.g_varchar2_table(939) := '71652E666F72456163682866756E6374696F6E28652C74297B76617220613D58286B2C742B31292C643D6E6528652C692C72293B696628652E63656C6C297B76617220703D736528652C692C722C6C292C6D3D742B312B423B696628612E76616C75653D';
wwv_flow_imp.g_varchar2_table(940) := '6E756C6C2C28652E76616C69676E7C7C6329262628612E616C69676E6D656E743D7B686F72697A6F6E74616C3A652E616C69676E2C766572746963616C3A652E76616C69676E7C7C637D292C7525323D3D3126262131213D3D6E2E7A6562726126262861';
wwv_flow_imp.g_varchar2_table(941) := '2E66696C6C3D43286C2E7A6562726129292C70297B76617220763D6F2E616464496D616765287B6261736536343A702E696D2E646174612C657874656E73696F6E3A226A7067223D3D3D702E696D2E6578743F226A706567223A22706E67227D292C623D';
wwv_flow_imp.g_varchar2_table(942) := '5A28652C722C69293B452E616464496D61676528762C7B746C3A7B636F6C3A6D2D312B2E30382C726F773A6B2D312B2E30387D2C6578743A7B77696474683A332E37382A702E772C6865696768743A332E37382A702E687D2C68797065726C696E6B733A';
wwv_flow_imp.g_varchar2_table(943) := '623F7B68797065726C696E6B3A622C746F6F6C7469703A627D3A766F696420307D292C4B286B2C322E3833352A702E682B34292C4F5B6D5D3D4D6174682E6D696E2836302C4D6174682E6D6178284F5B6D5D7C7C382C4D6174682E6365696C28332E3738';
wwv_flow_imp.g_varchar2_table(944) := '2A702E772F37292B3229297D7D656C73657B76617220773B652E69734E756D2626682864293F28612E76616C75653D642C612E6E756D466D743D4D28773D652E666D74293F462877293A22696E74223D3D3D773F22232C232330223A226D6F6E6579223D';
wwv_flow_imp.g_varchar2_table(945) := '3D3D777C7C2F5E6E756D2F2E7465737428777C7C2222293F22232C2323302E222B6E657720417272617928312A2828777C7C2222292E73706C697428223A22295B315D7C7C32292B31292E6A6F696E28223022293A2247656E6572616C22293A22646174';
wwv_flow_imp.g_varchar2_table(946) := '6522213D3D652E666D742626224441544522213D3D286E2E5F74797065737C7C722E545B537472696E67286E2E736F75726365292E746F55707065724361736528295D7C7C7B7D295B652E636F6C5D7C7C21782864293F612E76616C75653D6E756C6C3D';
wwv_flow_imp.g_varchar2_table(947) := '3D643F6E756C6C3A5428652E666D7429262621652E6D61703F5328642C652E666D74293A537472696E672864293A28612E76616C75653D782864292C612E6E756D466D743D732E786C292C612E616C69676E6D656E743D652E76616C69676E7C7C633F7B';
wwv_flow_imp.g_varchar2_table(948) := '686F72697A6F6E74616C3A652E616C69676E2C766572746963616C3A652E76616C69676E7C7C637D3A7B686F72697A6F6E74616C3A652E616C69676E7D3B76617220793D5928652E63656C6C5374796C652C722C69297C7C663B792626792E66696C6C3F';
wwv_flow_imp.g_varchar2_table(949) := '612E66696C6C3D4328792E66696C6C293A7525323D3D3126262131213D3D6E2E7A65627261262628612E66696C6C3D43286C2E7A6562726129293B76617220413D7B7D3B28652E626F6C647C7C792626792E626F6C6429262628412E626F6C643D213029';
wwv_flow_imp.g_varchar2_table(950) := '2C28792626792E636F6C6F727C7C652E636F6C6F7229262628412E636F6C6F723D7B617267623A6728792626792E636F6C6F727C7C652E636F6C6F72297D292C28412E626F6C647C7C412E636F6C6F7229262628612E666F6E743D41293B766172204E3D';
wwv_flow_imp.g_varchar2_table(951) := '5A28652C722C69293B4E26266E756C6C213D6426262222213D3D64262628612E76616C75653D7B746578743A537472696E67286F6528652C692C7229292C68797065726C696E6B3A4E7D2C612E666F6E743D7B626F6C643A412E626F6C642C756E646572';
wwv_flow_imp.g_varchar2_table(952) := '6C696E653A21302C636F6C6F723A412E636F6C6F727C7C7B617267623A67286C2E6C696E6B297D7D292C5528742B312C652E69734E756D3F5328642C652E666D74293A64297D7D292C6B2B2B7D293B766172206D743D6B2D312C76743D6D65286E2E746F';
wwv_flow_imp.g_varchar2_table(953) := '74616C73293B69662876742E6C656E6774682626286B3D6774286B2C76742C59652C4565286E2C722C5965292C69742C6B2D312C21216E2E627265616B427929292C6E2E6772696429666F72287661722062743D41286E2E626F72646572436F6C6F7229';
wwv_flow_imp.g_varchar2_table(954) := '2C77743D51653B77743C6B3B77742B2B29666F72287661722079743D313B79743C3D71652E6C656E6774683B79742B2B29582877742C7974292E626F726465723D62743B31213D3D4C7C7C6E2E627265616B42797C7C487C7C286A3D7B66726F6D3A7B72';
wwv_flow_imp.g_varchar2_table(955) := '6F773A72742C636F6C756D6E3A317D2C746F3A7B726F773A6D742C636F6C756D6E3A71652E6C656E6774687D7D2C502E696E6465784F66286E293C3D31262628443D727429292C6B2B2B7D7D292C4F626A6563742E6B657973284F292E666F7245616368';
wwv_flow_imp.g_varchar2_table(956) := '2866756E6374696F6E2865297B452E676574436F6C756D6E282B65292E77696474683D4F5B655D7D292C6A262628452E6175746F46696C7465723D6A292C44262628452E76696577733D5B7B73746174653A2266726F7A656E222C7953706C69743A447D';
wwv_flow_imp.g_varchar2_table(957) := '5D292C492626752E70726F746563742626662E7075736828452E70726F7465637428752E70617373776F72642C7B73656C6563744C6F636B656443656C6C733A21302C73656C656374556E6C6F636B656443656C6C733A21302C666F726D6174436F6C75';
wwv_flow_imp.g_varchar2_table(958) := '6D6E733A21302C666F726D6174526F77733A21307D29292C652E666F6F746572262628452E686561646572466F6F7465722E6F6464466F6F7465723D22264C2638222B4728652E666F6F7465722E6C6566742C72292E7265706C616365282F262F672C22';
wwv_flow_imp.g_varchar2_table(959) := '262622292E73756273747228302C323030292B2226522638222B612822786C506167652229292C652E706167654865616465722626226F626A656374223D3D747970656F6620652E70616765486561646572297B7661722070653D687428652E70616765';
wwv_flow_imp.g_varchar2_table(960) := '486561646572292C53653D22223B5B5B226C656674222C22264C225D2C5B2263656E746572222C222643225D2C5B227269676874222C222652225D5D2E666F72456163682866756E6374696F6E2865297B76617220743D70655B655B305D5D3B69662874';
wwv_flow_imp.g_varchar2_table(961) := '297B766172206E3D4728742E746578742C72292E7265706C616365282F262F672C22262622292E7265706C616365282F5C7B28444F43293F50414745535C7D2F672C22264E22292E7265706C616365282F5C7B28444F43293F504147455C7D2F672C2226';
wwv_flow_imp.g_varchar2_table(962) := '5022292E73756273747228302C3830293B53652B3D655B315D2B2226222B4D6174682E726F756E6428742E73697A65292B28742E636F6C6F722626222330303030303022213D3D742E636F6C6F723F22264B222B6D28742E636F6C6F72293A2222292B28';
wwv_flow_imp.g_varchar2_table(963) := '742E626F6C643F222642222B6E2B222642223A6E297D7D292C5365262628452E686561646572466F6F7465722E6F64644865616465723D5365292C21313D3D3D652E706167654865616465722E666972737450616765262628452E686561646572466F6F';
wwv_flow_imp.g_varchar2_table(964) := '7465722E646966666572656E7446697273743D21302C452E686561646572466F6F7465722E6F6464466F6F746572262628452E686561646572466F6F7465722E6669727374466F6F7465723D452E686561646572466F6F7465722E6F6464466F6F746572';
wwv_flow_imp.g_varchar2_table(965) := '29297D7D297D292C4765286529262666756E6374696F6E2865297B76617220743D652E646566696E65644E616D65732C723D7426264F626A6563742E6765744F776E50726F706572747944657363726970746F72284F626A6563742E67657450726F746F';
wwv_flow_imp.g_varchar2_table(966) := '747970654F662874292C226D6F64656C22293B722626722E676574262621742E5F5F6E722626284F626A6563742E646566696E6550726F706572747928742C226D6F64656C222C7B636F6E666967757261626C653A21302C6765743A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(967) := '28297B72657475726E20722E6765742E63616C6C2874686973292E6D61702866756E6374696F6E2865297B72657475726E7B6E616D653A652E6E616D652C72616E6765733A652E72616E6765732E6D61702866756E6374696F6E2865297B76617220743D';
wwv_flow_imp.g_varchar2_table(968) := '2F5E285B5E27215D2B2921282E2B29242F2E657865632865293B72657475726E20743F2227222B745B315D2B222721222B745B325D3A657D297D7D297D2C7365743A66756E6374696F6E2865297B722E7365742E63616C6C28746869732C65297D7D292C';
wwv_flow_imp.g_varchar2_table(969) := '742E5F5F6E723D2130297D286F292C662E6C656E6774683F50726F6D6973652E616C6C2866292E7468656E2866756E6374696F6E28297B72657475726E206F2E786C73782E777269746542756666657228297D293A6F2E786C73782E7772697465427566';
wwv_flow_imp.g_varchar2_table(970) := '66657228297D766172206F723D7B6C65747465723A5B31323234302C31353834305D2C6C6567616C3A5B31323234302C32303136305D2C61343A5B31313930362C31363833385D2C61333A5B31363833382C32333831315D2C61353A5B383339312C3131';
wwv_flow_imp.g_varchar2_table(971) := '3930365D2C62353A5B393937392C31343137355D2C7461626C6F69643A5B31353834302C32343438305D2C6578656375746976653A5B31303434302C31353132305D7D3B7661722061723D7B227B504147457D223A2243555252454E54222C227B504147';
wwv_flow_imp.g_varchar2_table(972) := '45537D223A22544F54414C5F5041474553222C227B444F43504147457D223A2243555252454E54222C227B444F4350414745537D223A22544F54414C5F50414745535F494E5F53454354494F4E227D3B66756E6374696F6E206C7228652C742C72297B76';
wwv_flow_imp.g_varchar2_table(973) := '6172206E3D77696E646F772E646F63782C6F3D5B5D3B72657475726E204728652C74292E73706C6974282F285C7B283F3A444F43293F50414745533F5C7D292F292E666F72456163682866756E6374696F6E2865297B61725B655D3F6F2E70757368286E';
wwv_flow_imp.g_varchar2_table(974) := '6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265725B61725B655D5D5D2C73697A653A722E73697A652C636F6C6F723A722E636F6C6F722C626F6C643A722E626F6C647C7C766F696420307D29293A6526266F2E70';
wwv_flow_imp.g_varchar2_table(975) := '757368286E6577206E2E5465787452756E287B746578743A652C73697A653A722E73697A652C636F6C6F723A722E636F6C6F722C626F6C643A722E626F6C647C7C766F696420307D29297D292C6F7D66756E6374696F6E20697228652C742C72297B7661';
wwv_flow_imp.g_varchar2_table(976) := '72206E3D77696E646F772E646F63782C6F3D5B5D2C613D4D6174682E726F756E6428322A28652E73697A657C7C3729292C6C3D6D28722E6D75746564293B66756E6374696F6E20692865297B72657475726E206C7228652C742C7B73697A653A612C636F';
wwv_flow_imp.g_varchar2_table(977) := '6C6F723A6C7D297D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A6928652E6C656674297D29292C652E726967687426266F2E70757368286E6577206E2E506172616772617068';
wwv_flow_imp.g_varchar2_table(978) := '287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E3A6928652E7269676874297D29292C6F2E6C656E6774683F6F3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D';
wwv_flow_imp.g_varchar2_table(979) := '7D7661722073723D22E29FA64E52463A223B66756E6374696F6E2075722865297B72657475726E20537472696E672865292E7265706C616365282F262F672C2226616D703B22292E7265706C616365282F3C2F672C22266C743B22292E7265706C616365';
wwv_flow_imp.g_varchar2_table(980) := '282F3E2F672C222667743B22292E7265706C616365282F222F672C222671756F743B22297D66756E6374696F6E20637228652C74297B696628653D652E7265706C616365282F3C773A646F63756D656E7450726F74656374696F6E5B5E3E5D2A5C2F3E2F';
wwv_flow_imp.g_varchar2_table(981) := '672C2222292C21742E70726F746563742972657475726E20653B76617220723D273C773A646F63756D656E7450726F74656374696F6E20773A656469743D22666F726D732220773A656E666F7263656D656E743D223122273B696628742E70617373776F';
wwv_flow_imp.g_varchar2_table(982) := '7264297B766172206E3D66756E6374696F6E2865297B76617220743D6E65772055696E743841727261792865292C723D22756E646566696E656422213D747970656F662077696E646F7726262877696E646F772E63727970746F7C7C77696E646F772E6D';
wwv_flow_imp.g_varchar2_table(983) := '7343727970746F293B696628722626722E67657452616E646F6D56616C75657329722E67657452616E646F6D56616C7565732874293B656C736520666F7228766172206E3D303B6E3C653B6E2B2B29745B6E5D3D4D6174682E666C6F6F72283235362A4D';
wwv_flow_imp.g_varchar2_table(984) := '6174682E72616E646F6D2829293B72657475726E20747D283136292C6F3D3165353B722B3D2720773A637279707450726F7669646572547970653D227273614145532220773A6372797074416C676F726974686D436C6173733D22686173682220773A63';
wwv_flow_imp.g_varchar2_table(985) := '72797074416C676F726974686D547970653D2274797065416E792220773A6372797074416C676F726974686D5369643D2231342220773A63727970745370696E436F756E743D22272B6F2B272220773A686173683D22272B4F7428716528742E70617373';
wwv_flow_imp.g_varchar2_table(986) := '776F72642C6E2C6F29292B272220773A73616C743D22272B4F74286E292B2722277D722B3D222F3E223B76617220613D5B223C773A6576656E416E644F646448656164657273222C223C773A636F6D706174222C223C2F773A73657474696E67733E225D';
wwv_flow_imp.g_varchar2_table(987) := '2E6D61702866756E6374696F6E2874297B72657475726E20652E696E6465784F662874297D292E66696C7465722866756E6374696F6E2865297B72657475726E20653E3D307D295B305D3B72657475726E20652E73756273747228302C61292B722B652E';
wwv_flow_imp.g_varchar2_table(988) := '7375627374722861297D66756E6374696F6E20667228652C742C72297B72657475726E20722E70726F746563742626722E70617373776F72642626716528722E70617373776F72642C6E65772055696E74384172726179283136292C30292C77696E646F';
wwv_flow_imp.g_varchar2_table(989) := '772E4A535A69702E6C6F61644173796E632865292E7468656E2866756E6374696F6E2865297B72657475726E2050726F6D6973652E616C6C285B652E66696C652822776F72642F646F63756D656E742E786D6C22292E6173796E632822737472696E6722';
wwv_flow_imp.g_varchar2_table(990) := '292C652E66696C652822776F72642F73657474696E67732E786D6C22292E6173796E632822737472696E6722295D292E7468656E2866756E6374696F6E286E297B766172206F3D302C6C3D6E65772052656745787028273C773A723E283C773A7250723E';
wwv_flow_imp.g_varchar2_table(991) := '283F3A283F213C2F773A7250723E295B5C5C735C5C535D292A3C2F773A7250723E293F3C773A7420786D6C3A73706163653D227072657365727665223EE29FA64E52463A285C5C642B29E29FA73C2F773A743E3C2F773A723E272C226722292C693D6E5B';
wwv_flow_imp.g_varchar2_table(992) := '305D2E7265706C616365286C2C66756E6374696F6E28652C722C6E297B72657475726E206F2B2B2C66756E6374696F6E28652C742C72297B766172206E3D273C773A616C69617320773A76616C3D22272B757228652E6C6162656C7C7C652E6E616D6529';
wwv_flow_imp.g_varchar2_table(993) := '2B27222F3E3C773A74616720773A76616C3D22272B757228652E6E616D65292B27222F3E3C773A696420773A76616C3D22272B742B27222F3E272B28652E726561644F6E6C793F273C773A6C6F636B20773A76616C3D22736474436F6E74656E744C6F63';
wwv_flow_imp.g_varchar2_table(994) := '6B6564222F3E273A2222293B69662822636865636B626F78223D3D3D652E696E707574297B766172206F3D722E7265706C616365282F3C773A72466F6E74735B5E3E5D2A5C2F3E2F2C2222292E7265706C61636528223C773A7250723E222C273C773A72';
wwv_flow_imp.g_varchar2_table(995) := '50723E3C773A72466F6E747320773A61736369693D224D5320476F746869632220773A65617374417369613D224D5320476F746869632220773A68416E73693D224D5320476F746869632220773A63733D224D5320476F74686963222F3E27293B726574';
wwv_flow_imp.g_varchar2_table(996) := '75726E223C773A7364743E3C773A73647450723E222B6F2B6E2B273C7731343A636865636B626F783E3C7731343A636865636B6564207731343A76616C3D22272B28652E636865636B65643F313A30292B27222F3E3C7731343A636865636B6564537461';
wwv_flow_imp.g_varchar2_table(997) := '7465207731343A76616C3D223236313222207731343A666F6E743D224D5320476F74686963222F3E3C7731343A756E636865636B65645374617465207731343A76616C3D223236313022207731343A666F6E743D224D5320476F74686963222F3E3C2F77';
wwv_flow_imp.g_varchar2_table(998) := '31343A636865636B626F783E3C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E272B6F2B223C773A743E222B28652E636865636B65643F44653A6A65292B223C2F773A743E3C2F773A723E3C2F773A736474436F6E74656E743E3C';
wwv_flow_imp.g_varchar2_table(999) := '2F773A7364743E227D76617220613D21652E76616C75652C6C3D652E76616C75657C7C652E706C616365686F6C6465727C7C28226C697374223D3D3D652E696E7075743F22456C696A6120756E20656C656D656E746F2E223A6E65772041727261792839';
wwv_flow_imp.g_varchar2_table(1000) := '292E6A6F696E2822E280822229293B72657475726E223C773A7364743E3C773A73647450723E222B722B6E2B28613F223C773A73686F77696E67506C634864722F3E223A2222292B28226C697374223D3D3D652E696E7075743F223C773A64726F70446F';
wwv_flow_imp.g_varchar2_table(1001) := '776E4C6973743E222B652E6F7074696F6E732E6D61702866756E6374696F6E2865297B72657475726E273C773A6C6973744974656D20773A646973706C6179546578743D22272B75722865292B272220773A76616C75653D22272B75722865292B27222F';
wwv_flow_imp.g_varchar2_table(1002) := '3E277D292E6A6F696E282222292B223C2F773A64726F70446F776E4C6973743E223A223C773A74657874222B28226D756C74696C696E65223D3D3D652E696E7075743F2720773A6D756C74694C696E653D223122273A2222292B222F3E22292B223C2F77';
wwv_flow_imp.g_varchar2_table(1003) := '3A73647450723E3C773A736474436F6E74656E743E3C773A723E222B722B537472696E67286C292E73706C6974282F5C723F5C6E2F292E6D61702866756E6374696F6E2865297B72657475726E273C773A7420786D6C3A73706163653D22707265736572';
wwv_flow_imp.g_varchar2_table(1004) := '7665223E272B75722865292B223C2F773A743E227D292E6A6F696E28223C773A62722F3E22292B223C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D28745B2B6E5D2C3165332B4E756D626572286E292C727C7C223C773A72';
wwv_flow_imp.g_varchar2_table(1005) := '50723E3C2F773A7250723E22297D293B6966286F213D3D742E6C656E677468297468726F77206E6577204572726F7228612822776F72644669656C6473222C6F2C742E6C656E67746829293B72657475726E20652E66696C652822776F72642F646F6375';
wwv_flow_imp.g_varchar2_table(1006) := '6D656E742E786D6C222C69292C652E66696C652822776F72642F73657474696E67732E786D6C222C6372286E5B315D2C7229292C652E67656E65726174654173796E63287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A';
wwv_flow_imp.g_varchar2_table(1007) := '224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D297D297D297D66756E6374696F6E20647228652C742C72297B766172206E2C6F3D77696E646F772E646F63782C613D41742865292C6C3D652E70616765';
wwv_flow_imp.g_varchar2_table(1008) := '7C7C7B7D2C693D5B5D2C733D526528292C753D286E3D6C2E73697A652C41727261792E69734172726179286E292626323D3D3D6E2E6C656E67746826266E5B305D3E3026266E5B315D3E303F5B4D6174682E726F756E642835362E363932392A4D617468';
wwv_flow_imp.g_varchar2_table(1009) := '2E6D696E286E5B305D2C6E5B315D29292C4D6174682E726F756E642835362E363932392A4D6174682E6D6178286E5B305D2C6E5B315D29295D3A6F725B537472696E67286E7C7C226C657474657222292E746F4C6F7765724361736528295D7C7C6F722E';
wwv_flow_imp.g_varchar2_table(1010) := '6C6574746572292C633D226C616E647363617065223D3D3D6C2E6F7269656E746174696F6E2C663D4D6174682E726F756E642835362E372A286C2E6D617267696E7C7C31322E3729292C643D28633F755B315D3A755B305D292D322A662C683D7B737479';
wwv_flow_imp.g_varchar2_table(1011) := '6C653A6F2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C703D7B746F703A682C626F74746F6D3A682C6C6566743A682C72696768743A682C696E73696465486F72697A6F6E74616C3A682C696E73';
wwv_flow_imp.g_varchar2_table(1012) := '696465566572746963616C3A687D2C673D7B7374796C653A6F2E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A22424643394434227D2C763D7B746F703A672C626F74746F6D3A672C6C6566743A672C72696768743A67';
wwv_flow_imp.g_varchar2_table(1013) := '2C696E73696465486F72697A6F6E74616C3A672C696E73696465566572746963616C3A677D3B66756E6374696F6E20622865297B69662821652972657475726E20763B76617220743D7B7374796C653A6F2E426F726465725374796C652E53494E474C45';
wwv_flow_imp.g_varchar2_table(1014) := '2C73697A653A322C636F6C6F723A6D2865297D3B72657475726E7B746F703A742C626F74746F6D3A742C6C6566743A742C72696768743A742C696E73696465486F72697A6F6E74616C3A742C696E73696465566572746963616C3A747D7D76617220773D';
wwv_flow_imp.g_varchar2_table(1015) := '4D6174682E726F756E6428322A28612E666F6E7453697A657C7C3729293B66756E6374696F6E207928652C74297B72657475726E20743D747C7C7B7D2C6E6577206F2E5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65';
wwv_flow_imp.g_varchar2_table(1016) := '292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C756E6465726C696E653A742E756E6465726C696E653F7B7D3A766F696420302C73697A653A742E73697A657C7C772C636F6C6F723A742E636F6C6F723F6D28742E';
wwv_flow_imp.g_varchar2_table(1017) := '636F6C6F72293A766F696420302C666F6E743A742E666F6E747C7C2243616C69627269227D297D66756E6374696F6E207828652C74297B76617220723D7928652C743D747C7C7B7D293B696628742E6C696E6B26262222213D3D537472696E67286E756C';
wwv_flow_imp.g_varchar2_table(1018) := '6C3D3D653F22223A6529297B766172206E3D6C652874293B6E2E756E6465726C696E653D21302C6E2E636F6C6F723D742E6C696E6B436F6C6F727C7C742E636F6C6F727C7C612E6C696E6B2C723D6E6577206F2E45787465726E616C48797065726C696E';
wwv_flow_imp.g_varchar2_table(1019) := '6B287B6C696E6B3A742E6C696E6B2C6368696C6472656E3A5B7928652C6E295D7D297D72657475726E206E6577206F2E506172616772617068287B6368696C6472656E3A5B725D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C61';
wwv_flow_imp.g_varchar2_table(1020) := '6C69676E6D656E743A227269676874223D3D3D742E616C69676E3F6F2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D742E616C69676E3F6F2E416C69676E6D656E74547970652E43454E5445523A6F2E416C69676E6D65';
wwv_flow_imp.g_varchar2_table(1021) := '6E74547970652E4C4546547D297D66756E6374696F6E204528652C74297B76617220723D766F69642030213D3D28743D747C7C7B7D292E7061643F742E7061643A33303B72657475726E206E6577206F2E5461626C6543656C6C287B6368696C6472656E';
wwv_flow_imp.g_varchar2_table(1022) := '3A5B7828652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B746F703A722C626F74746F6D3A722C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A742E6D6964646C657C7C226D6964646C';
wwv_flow_imp.g_varchar2_table(1023) := '65223D3D3D742E76616C69676E3F6F2E566572746963616C416C69676E2E43454E5445523A22626F74746F6D223D3D3D742E76616C69676E3F6F2E566572746963616C416C69676E2E424F54544F4D3A22746F70223D3D3D742E76616C69676E3F6F2E56';
wwv_flow_imp.g_varchar2_table(1024) := '6572746963616C416C69676E2E544F503A766F696420302C73686164696E673A742E66696C6C3F7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D28742E66696C6C297D3A766F69642030';
wwv_flow_imp.g_varchar2_table(1025) := '7D297D66756E6374696F6E205328297B72657475726E206E6577206F2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D66756E6374696F6E205428652C742C7229';
wwv_flow_imp.g_varchar2_table(1026) := '7B72657475726E206E6577206F2E506172616772617068287B6368696C6472656E3A5B7928652C7B626F6C643A742E626F6C642C73697A653A742E73697A653F4D6174682E726F756E6428322A742E73697A65293A31342C636F6C6F723A742E636F6C6F';
wwv_flow_imp.g_varchar2_table(1027) := '727D295D2C73706163696E673A7B6265666F72653A302C61667465723A32307D2C616C69676E6D656E743A227269676874223D3D3D723F6F2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D723F6F2E416C69676E6D656E';
wwv_flow_imp.g_varchar2_table(1028) := '74547970652E43454E5445523A6F2E416C69676E6D656E74547970652E4C4546542C73686164696E673A742E66696C6C3F7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D28742E66696C';
wwv_flow_imp.g_varchar2_table(1029) := '6C297D3A766F696420307D297D66756E6374696F6E204328652C742C722C6E2C612C6C297B76617220693D6E6577206F2E496D61676552756E287B747970653A226A7067223D3D3D652E6578743F226A7067223A22706E67222C646174613A652E627566';
wwv_flow_imp.g_varchar2_table(1030) := '2C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A74292C6865696768743A4D6174682E726F756E6428332E37382A72297D7D293B72657475726E206E6577206F2E506172616772617068287B616C69676E';
wwv_flow_imp.g_varchar2_table(1031) := '6D656E743A227269676874223D3D3D6E2E616C69676E3F6F2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6E2E616C69676E3F6F2E416C69676E6D656E74547970652E43454E5445523A6F2E416C69676E6D656E745479';
wwv_flow_imp.g_varchar2_table(1032) := '70652E4C4546542C73706163696E673A7B61667465723A766F69642030213D3D613F613A4D6174682E726F756E642835362E372A28766F69642030213D3D6E2E6761703F6E2E6761703A3329297D2C6368696C6472656E3A5B6C3F6E6577206F2E457874';
wwv_flow_imp.g_varchar2_table(1033) := '65726E616C48797065726C696E6B287B6C696E6B3A6C2C6368696C6472656E3A5B695D7D293A695D7D297D76617220413D28633F755B315D3A755B305D292F35362E372C4E3D28633F755B305D3A755B315D292F35362E373B66756E6374696F6E205028';
wwv_flow_imp.g_varchar2_table(1034) := '65297B76617220743D7A2865293B72657475726E20743F6E6577206F2E486561646572287B6368696C6472656E3A5B745D7D293A6E756C6C7D66756E6374696F6E204628652C74297B76617220723D68742865292C6E3D677428652C74292C6C3D5B5D2C';
wwv_flow_imp.g_varchar2_table(1035) := '693D5B5D2C733D7B7374796C653A6F2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C753D2131213D3D652E6C696E653F7B7374796C653A6F2E426F726465725374796C652E53494E474C452C7369';
wwv_flow_imp.g_varchar2_table(1036) := '7A653A4D6174682E6D617828322C4D6174682E726F756E642832302A28652E6C696E6557696474687C7C2E332929292C636F6C6F723A6D28652E6C696E65436F6C6F727C7C612E7072696D617279297D3A732C633D652E66696C6C3F7B747970653A6F2E';
wwv_flow_imp.g_varchar2_table(1037) := '53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D28652E66696C6C297D3A766F696420302C663D66756E6374696F6E28652C74297B72657475726E206C2E707573682874292C6E6577206F2E5461626C654365';
wwv_flow_imp.g_varchar2_table(1038) := '6C6C287B6368696C6472656E3A652C77696474683A7B73697A653A742C747970653A6F2E5769647468547970652E4458417D2C766572746963616C416C69676E3A6F2E566572746963616C416C69676E2E43454E5445522C6D617267696E733A7B746F70';
wwv_flow_imp.g_varchar2_table(1039) := '3A302C626F74746F6D3A302C6C6566743A302C72696768743A307D2C73686164696E673A637D297D2C683D66756E6374696F6E28652C6E2C61297B766172206C3D725B655D2C693D286C3F6C2E746578742E73706C697428225C6E22293A5B22225D292E';
wwv_flow_imp.g_varchar2_table(1040) := '6D61702866756E6374696F6E2865297B72657475726E206E6577206F2E506172616772617068287B616C69676E6D656E743A6E2C73706163696E673A7B6265666F72653A302C61667465723A307D2C6368696C6472656E3A6C3F6C7228652C742C7B7369';
wwv_flow_imp.g_varchar2_table(1041) := '7A653A4D6174682E726F756E6428322A6C2E73697A65292C636F6C6F723A6D286C2E636F6C6F72292C626F6C643A6C2E626F6C647D293A5B5D7D297D293B72657475726E206628692C61297D2C703D6E3F70742865293A22222C673D6E26262263656E74';
wwv_flow_imp.g_varchar2_table(1042) := '657222213D3D703F4D6174682E726F756E642835362E372A6E2E77292B3137303A302C763D642D672C623D227269676874223D3D3D702C773D66756E6374696F6E2865297B72657475726E2066285B6E6577206F2E506172616772617068287B73706163';
wwv_flow_imp.g_varchar2_table(1043) := '696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A623F6F2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D703F6F2E416C69676E6D656E74547970652E43454E5445523A6F2E416C69676E';
wwv_flow_imp.g_varchar2_table(1044) := '6D656E74547970652E4C4546542C6368696C6472656E3A5B6E6577206F2E496D61676552756E287B747970653A226A7067223D3D3D6E2E696D2E6578743F226A7067223A22706E67222C646174613A6E2E696D2E6275662C7472616E73666F726D617469';
wwv_flow_imp.g_varchar2_table(1045) := '6F6E3A7B77696474683A4D6174682E726F756E6428332E37382A6E2E77292C6865696768743A4D6174682E726F756E6428332E37382A6E2E68297D7D295D7D295D2C65297D3B6E2626226C656674223D3D3D702626692E707573682877286729293B7661';
wwv_flow_imp.g_varchar2_table(1046) := '7220793D4D6174682E666C6F6F72282E342A76292C783D4D6174682E666C6F6F72282E332A76292C453D762D792D783B72657475726E2263656E746572223D3D3D70262628453D762D28783D4D6174682E6D617828782C4D6174682E726F756E64283536';
wwv_flow_imp.g_varchar2_table(1047) := '2E372A6E2E77292B31373029292D28793D4D6174682E666C6F6F722828762D78292F322929292C692E70757368286828226C656674222C6F2E416C69676E6D656E74547970652E4C4546542C79292C2263656E746572223D3D3D703F772878293A682822';
wwv_flow_imp.g_varchar2_table(1048) := '63656E746572222C6F2E416C69676E6D656E74547970652E43454E5445522C78292C6828227269676874222C6F2E416C69676E6D656E74547970652E52494748542C4529292C6E2626622626692E707573682877286729292C6E6577206F2E5461626C65';
wwv_flow_imp.g_varchar2_table(1049) := '287B726F77733A5B6E6577206F2E5461626C65526F77287B6865696768743A7B76616C75653A4D6174682E726F756E642835362E372A284E756D62657228652E686569676874297C7C313229292C72756C653A6F2E48656967687452756C652E41544C45';
wwv_flow_imp.g_varchar2_table(1050) := '4153547D2C6368696C6472656E3A697D295D2C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A6C2C6C61796F75743A6F2E5461626C654C61796F7574547970652E4649584544';
wwv_flow_imp.g_varchar2_table(1051) := '2C626F72646572733A7B746F703A732C6C6566743A732C72696768743A732C696E73696465486F72697A6F6E74616C3A732C696E73696465566572746963616C3A732C626F74746F6D3A757D7D297D66756E6374696F6E207A2874297B76617220722C6E';
wwv_flow_imp.g_varchar2_table(1052) := '3D4A7428652C74293B696628216E2972657475726E206E756C6C3B7472797B723D66756E6374696F6E28652C742C72297B766172206E3D372E35362C6F3D4274284D6174682E726F756E6428742A6E292C4D6174682E726F756E6428722A6E29292C613D';
wwv_flow_imp.g_varchar2_table(1053) := '6F2E676574436F6E746578742822326422292C6C3D2248656C7665746963612C20417269616C2C2073616E732D7365726966223B612E666F6E743D22626F6C64203236362E37313638707820222B6C3B76617220693D4B7428652C612E6D656173757265';
wwv_flow_imp.g_varchar2_table(1054) := '5465787428652E74657874292E77696474682F6E2C742C72293B612E666F6E743D22626F6C6420222B2E333532382A692A6E2B22707820222B6C2C612E7472616E736C617465286F2E77696474682F322C6F2E6865696768742F32292C612E726F746174';
wwv_flow_imp.g_varchar2_table(1055) := '65282D652E616E676C652A4D6174682E50492F313830292C612E676C6F62616C416C7068613D652E6F7061636974792C612E66696C6C5374796C653D652E636F6C6F722C612E74657874416C69676E3D2263656E746572222C612E74657874426173656C';
wwv_flow_imp.g_varchar2_table(1056) := '696E653D226D6964646C65222C612E66696C6C5465787428652E746578742C302C30293B76617220733D5574286F2E746F4461746155524C2822696D6167652F706E6722292C6F2E77696474682C6F2E686569676874293B72657475726E20732E776D6D';
wwv_flow_imp.g_varchar2_table(1057) := '3D742C732E686D6D3D722C737D286E2C412C4E297D63617463682865297B72657475726E206E756C6C7D72657475726E206E6577206F2E506172616772617068287B6368696C6472656E3A5B6E6577206F2E496D61676552756E287B747970653A22706E';
wwv_flow_imp.g_varchar2_table(1058) := '67222C646174613A722E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A41292C6865696768743A4D6174682E726F756E6428332E37382A4E297D2C666C6F6174696E673A7B686F72697A6F6E74';
wwv_flow_imp.g_varchar2_table(1059) := '616C506F736974696F6E3A7B72656C61746976653A6F2E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6F2E486F72697A6F6E74616C506F736974696F6E416C69676E2E43454E5445527D2C76';
wwv_flow_imp.g_varchar2_table(1060) := '6572746963616C506F736974696F6E3A7B72656C61746976653A6F2E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6F2E566572746963616C506F736974696F6E416C69676E2E43454E5445527D2C';
wwv_flow_imp.g_varchar2_table(1061) := '626568696E64446F63756D656E743A21302C616C6C6F774F7665726C61703A21302C777261703A7B747970653A6F2E546578745772617070696E67547970652E4E4F4E457D7D7D295D7D297D766172204D3D742E6D61702866756E6374696F6E28722C6E';
wwv_flow_imp.g_varchar2_table(1062) := '297B766172206C3D5B5D2C683D742E6C656E6774683E313F225F222B286E2B31293A22223B777428652C22646F6378222C72292E666F72456163682866756E6374696F6E2074286E297B76617220753D6E2E747970653B69662822636F6C756D6E617322';
wwv_flow_imp.g_varchar2_table(1063) := '3D3D3D75297B76617220633D5474286E2C22646F6378222C722C642F35362E37293B69662821632E6C656E6774682972657475726E3B76617220663D6C2C673D642C763D4D6174682E726F756E642835362E372A28766F69642030213D3D6E2E636F6C47';
wwv_flow_imp.g_varchar2_table(1064) := '61703F4E756D626572286E2E636F6C476170293A3429292C413D5B5D2C4E3D5B5D3B72657475726E20632E666F72456163682866756E6374696F6E28652C72297B766172206E3D723D3D3D632E6C656E6774682D312C613D4D6174682E726F756E642835';
wwv_flow_imp.g_varchar2_table(1065) := '362E372A652E77293B6C3D5B5D2C643D612C652E736563732E666F72456163682874292C6C2E6C656E67746826266C5B6C2E6C656E6774682D315D696E7374616E63656F66206F2E5061726167726170687C7C6C2E70757368287828222229292C412E70';
wwv_flow_imp.g_varchar2_table(1066) := '757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A6C2C77696474683A7B73697A653A612B286E3F303A76292C747970653A6F2E5769647468547970652E4458417D2C6D617267696E733A7B746F703A302C626F74746F6D3A302C';
wwv_flow_imp.g_varchar2_table(1067) := '6C6566743A302C72696768743A6E3F303A767D2C766572746963616C416C69676E3A6F2E566572746963616C416C69676E2E544F507D29292C4E2E7075736828612B286E3F303A7629297D292C643D672C766F6964286C3D66292E70757368286E657720';
wwv_flow_imp.g_varchar2_table(1068) := '6F2E5461626C65287B726F77733A5B6E6577206F2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A417D295D2C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E';
wwv_flow_imp.g_varchar2_table(1069) := '5769647468733A4E2C626F72646572733A702C6C61796F75743A6F2E5461626C654C61796F7574547970652E46495845447D292C532829297D69662822677275706F223D3D3D75297B76617220503D722C463D682C7A3D6C2C4D3D642C6B3D4D6174682E';
wwv_flow_imp.g_varchar2_table(1070) := '726F756E642835362E372A28766F69642030213D3D6E2E70616464696E673F4E756D626572286E2E70616464696E67293A6E2E626F726465727C7C6E2E66696C6C3F333A3029292C4F3D6E2E626F726465723F62286E2E626F72646572436F6C6F727C7C';
wwv_flow_imp.g_varchar2_table(1071) := '5865293A703B72657475726E205374286E2C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C683D462B652E7375663B76617220693D4574286E2C22646F6378222C72293B696628692E6C656E6774687C7C6E2E7469746C65';
wwv_flow_imp.g_varchar2_table(1072) := '297B6C3D5B5D2C643D4D6174682E6D6178283630302C4D2D322A6B292C692E666F72456163682874292C6C2E6C656E67746826266C5B6C2E6C656E6774682D315D696E7374616E63656F66206F2E5061726167726170687C7C6C2E707573682878282222';
wwv_flow_imp.g_varchar2_table(1073) := '29293B76617220733D5B5D3B6E2E7469746C652626732E70757368286E6577206F2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B452847286E2E7469746C652C72292C7B626F6C643A21302C73697A653A4D617468';
wwv_flow_imp.g_varchar2_table(1074) := '2E726F756E6428322A286E2E7469746C6553697A657C7C28612E666F6E7453697A657C7C37292B3229292C636F6C6F723A6E2E7469746C65436F6C6F727C7C612E68656164546578742C66696C6C3A6E2E7469746C6546696C6C7C7C612E7072696D6172';
wwv_flow_imp.g_varchar2_table(1075) := '792C7061643A36307D295D7D29292C732E70757368286E6577206F2E5461626C65526F77287B63616E7453706C69743A2131213D3D6E2E6B656570546F6765746865722C6368696C6472656E3A5B6E6577206F2E5461626C6543656C6C287B6368696C64';
wwv_flow_imp.g_varchar2_table(1076) := '72656E3A6C2C6D617267696E733A7B746F703A6B2C626F74746F6D3A6B2C6C6566743A6B2C72696768743A6B7D2C73686164696E673A6E2E66696C6C3F7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C';
wwv_flow_imp.g_varchar2_table(1077) := '66696C6C3A6D286E2E66696C6C297D3A766F696420307D295D7D29292C643D4D2C286C3D7A292E70757368286E6577206F2E5461626C65287B726F77733A732C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C';
wwv_flow_imp.g_varchar2_table(1078) := '636F6C756D6E5769647468733A5B645D2C626F72646572733A4F2C6C61796F75743A6F2E5461626C654C61796F7574547970652E46495845447D292C532829297D7D292C6C3D7A2C643D4D2C723D502C766F696428683D46297D69662822686561646572';
wwv_flow_imp.g_varchar2_table(1079) := '223D3D3D75297B766172204C3D6674286E2C61292C443D6E2E666F6E743F4C2E666F6E745B315D3A766F696420302C6A3D5B6E6577206F2E5461626C65526F77287B6368696C6472656E3A5B452847286E2E7469746C652C72292C7B626F6C643A21302C';
wwv_flow_imp.g_varchar2_table(1080) := '73697A653A4D6174682E726F756E6428322A4C2E73697A65292C636F6C6F723A4C2E636F6C6F722C66696C6C3A4C2E66696C6C2C666F6E743A447D292C452847286E2E72696768742C72292C7B73697A653A4D6174682E726F756E6428322A4C2E726967';
wwv_flow_imp.g_varchar2_table(1081) := '687453697A65292C636F6C6F723A4C2E636F6C6F722C66696C6C3A4C2E66696C6C2C616C69676E3A227269676874222C666F6E743A442C6D6964646C653A21216E2E726967687453697A657D295D7D295D3B6E2E7375627469746C6526266A2E70757368';
wwv_flow_imp.g_varchar2_table(1082) := '286E6577206F2E5461626C65526F77287B6368696C6472656E3A5B452847286E2E7375627469746C652C72292C7B73697A653A4D6174682E726F756E6428322A4C2E73756253697A65292C636F6C6F723A4C2E636F6C6F722C66696C6C3A4C2E66696C6C';
wwv_flow_imp.g_varchar2_table(1083) := '2C7370616E3A322C666F6E743A447D295D7D29292C6C2E70757368286E6577206F2E5461626C65287B726F77733A6A2C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B4D61';
wwv_flow_imp.g_varchar2_table(1084) := '74682E726F756E64282E372A64292C4D6174682E726F756E64282E332A64295D2C626F72646572733A707D292C532829297D656C73652069662822746578746F223D3D3D75297B76617220493D7B72696768743A6F2E416C69676E6D656E74547970652E';
wwv_flow_imp.g_varchar2_table(1085) := '52494748542C63656E7465723A6F2E416C69676E6D656E74547970652E43454E5445522C6A7573746966793A6F2E416C69676E6D656E74547970652E4A55535449464945447D3B6565286E2C72292E666F72456163682866756E6374696F6E2874297B6C';
wwv_flow_imp.g_varchar2_table(1086) := '2E70757368286E6577206F2E506172616772617068287B616C69676E6D656E743A495B6E2E616C69676E5D7C7C6F2E416C69676E6D656E74547970652E4C4546542C696E64656E743A6E2E696E64656E743F7B6C6566743A4D6174682E726F756E642835';
wwv_flow_imp.g_varchar2_table(1087) := '362E372A6E2E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A766F69642030213D3D6E2E7061726167726170684761703F4D6174682E726F756E642835362E372A6E2E706172616772617068476170293A3132302C6C696E';
wwv_flow_imp.g_varchar2_table(1088) := '653A4D6174682E726F756E64283234302A286E2E6C696E654865696768747C7C312E313529297D2C6368696C6472656E3A5128742C7B666F6E743A6E2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F72';
wwv_flow_imp.g_varchar2_table(1089) := '2C6C696E6B3A612E6C696E6B7D292E7265647563652866756E6374696F6E28652C74297B76617220723D6E6577206F2E5465787452756E287B746578743A742E742C626F6C643A212821742E622626216E2E626F6C64292C6974616C6963733A21282174';
wwv_flow_imp.g_varchar2_table(1090) := '2E692626216E2E6974616C6963292C73697A653A322A286E2E73697A657C7C3130292C756E6465726C696E653A742E753F7B7D3A766F696420302C737472696B653A2121742E732C636F6C6F723A742E633F6D28742E63293A766F696420302C666F6E74';
wwv_flow_imp.g_varchar2_table(1091) := '3A715B742E665D5B315D7D293B72657475726E20742E683F652E6C6173742626652E6C6173742E683D3D3D742E683F28652E6C6173742E72756E732E707573682872292C65293A28652E6C6173743D7B683A742E682C72756E733A5B725D7D2C652E7075';
wwv_flow_imp.g_varchar2_table(1092) := '736828652E6C617374292C65293A28652E707573682872292C652E6C6173743D6E756C6C2C65297D2C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652E72756E733F6E6577206F2E45787465726E616C48797065726C696E6B287B';
wwv_flow_imp.g_varchar2_table(1093) := '6C696E6B3A652E682C6368696C6472656E3A652E72756E737D293A657D297D29297D297D656C736520696628226573706163696F223D3D3D75296C2E70757368286E6577206F2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E';
wwv_flow_imp.g_varchar2_table(1094) := '673A7B61667465723A4D6174682E726F756E642835362E372A286E2E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D75297B696628766F696420303D3D3D6E2E7831297B76617220523D4D6174682E726F756E6428';
wwv_flow_imp.g_varchar2_table(1095) := '35362E372A286E2E77696474687C7C3029292C553D523F4D6174682E6D617828302C4D6174682E726F756E642828642D52292F3229293A303B6C2E70757368286E6577206F2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E67';
wwv_flow_imp.g_varchar2_table(1096) := '3A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D6E2E6761703F6E2E6761703A3229297D2C696E64656E743A2263656E746572223D3D3D6E2E616C69676E3F7B6C6566743A552C72696768743A557D3A227269676874';
wwv_flow_imp.g_varchar2_table(1097) := '223D3D3D6E2E616C69676E3F7B6C6566743A322A557D3A7B72696768743A322A557D2C626F726465723A7B626F74746F6D3A7B7374796C653A6F2E426F726465725374796C652E53494E474C452C73697A653A4D6174682E6D617828322C4D6174682E72';
wwv_flow_imp.g_varchar2_table(1098) := '6F756E642832302A286E2E746869636B6E6573737C7C2E332929292C636F6C6F723A6D286E2E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C73652069662822696D6167656E223D3D3D75297B76617220423D6A74';
wwv_flow_imp.g_varchar2_table(1099) := '286E2C72293B69662842297B766172205F3D4974286E2C42293B6C2E70757368284328422C5F2E772C5F2E682C6E2C766F696420302C5A286E2C722C6E2E736F757263653F56286E2C72295B305D3A6E756C6C2929297D7D656C73652069662822677261';
wwv_flow_imp.g_varchar2_table(1100) := '6669636F223D3D3D75297B76617220483D5A74286E2C722C61293B4826266C2E70757368284328482C482E776D6D2C482E686D6D2C6E29297D656C73652069662822636F6469676F223D3D3D75297B76617220583D5974286E2C72293B69662858297B76';
wwv_flow_imp.g_varchar2_table(1101) := '6172204A3D71742858293B6C2E707573682843284A2C4A2E776D6D2C4A2E686D6D2C6E2C582E6C6162656C3F303A766F6964203029292C582E6C6162656C26266C2E70757368286E6577206F2E506172616772617068287B616C69676E6D656E743A2272';
wwv_flow_imp.g_varchar2_table(1102) := '69676874223D3D3D6E2E616C69676E3F6F2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6E2E616C69676E3F6F2E416C69676E6D656E74547970652E43454E5445523A6F2E416C69676E6D656E74547970652E4C454654';
wwv_flow_imp.g_varchar2_table(1103) := '2C696E64656E743A227269676874223D3D3D6E2E616C69676E7C7C2263656E746572223D3D3D6E2E616C69676E3F766F696420303A7B6C6566743A4D6174682E6D617828302C4D6174682E726F756E6428284A2E776D6D2D582E746578742E6C656E6774';
wwv_flow_imp.g_varchar2_table(1104) := '682A582E7465787453697A652A2E333532382A2E36292F322A35362E3729297D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D6E2E6761703F6E2E6761703A3329297D2C6368696C6472656E3A';
wwv_flow_imp.g_varchar2_table(1105) := '5B6E6577206F2E5465787452756E287B746578743A582E746578742C666F6E743A22436F7572696572204E6577222C73697A653A322A582E7465787453697A652C636F6C6F723A6D28582E636F6C6F72297D295D7D29297D7D656C736520696628227361';
wwv_flow_imp.g_varchar2_table(1106) := '6C746F223D3D3D75296C2E70757368286E6577206F2E506172616772617068287B6368696C6472656E3A5B6E6577206F2E50616765427265616B5D7D29293B656C736520696628226669636861223D3D3D75297B766172204B3D56286E2C72295B305D7C';
wwv_flow_imp.g_varchar2_table(1107) := '7C7B7D2C6E653D6E2E636F6C756D6E737C7C332C61653D5B5D2C6C653D5B5D3B6966284B6528286E2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5728652E7768656E2C722C4B29';
wwv_flow_imp.g_varchar2_table(1108) := '7D292C6E65292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E6374696F6E2865297B76617220743D652E662C6C3D21216E2E677269642C693D6C3F36303A766F696420303B696628652E656D707479297B76617220';
wwv_flow_imp.g_varchar2_table(1109) := '733D7B7374796C653A6F2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D3B6C652E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206F2E5061726167726170';
wwv_flow_imp.g_varchar2_table(1110) := '68287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A322A652E7370616E2C626F72646572733A6C3F7B746F703A732C626F74746F6D3A732C6C6566743A732C72696768743A737D3A766F696420307D29297D656C73657B7661722075';
wwv_flow_imp.g_varchar2_table(1111) := '2C633D6E7428742C6E292C663D4728742E6C6162656C2C722C4B293B696628226C65667422213D3D632E706F73297B76617220643D747428742C722C4B292C683D5B5D2C703D6C3F36303A33303B72657475726E22746F70223D3D3D632E706F73262668';
wwv_flow_imp.g_varchar2_table(1112) := '2E70757368285428617428662C63292C632C632E616C69676E7C7C642626642E616C69676E7C7C226C6566742229292C682E707573682878284D6528742C722C4B292C7B73697A653A31372C636F6C6F723A642626642E636F6C6F727C7C6E2E76616C75';
wwv_flow_imp.g_varchar2_table(1113) := '65436F6C6F722C626F6C643A643F642E626F6C643A766F696420302C616C69676E3A643F642E616C69676E3A766F696420302C6C696E6B3A5A28742C722C4B292C6C696E6B436F6C6F723A642626642E636F6C6F727C7C612E6C696E6B7D29292C766F69';
wwv_flow_imp.g_varchar2_table(1114) := '64206C652E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A682C636F6C756D6E5370616E3A322A652E7370616E2C6D617267696E733A7B746F703A702C626F74746F6D3A702C6C6566743A36302C72696768743A36307D2C';
wwv_flow_imp.g_varchar2_table(1115) := '766572746963616C416C69676E3A6C3F6F2E566572746963616C416C69676E2E43454E5445523A766F696420302C73686164696E673A642626642E66696C6C3F7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A22617574';
wwv_flow_imp.g_varchar2_table(1116) := '6F222C66696C6C3A6D28642E66696C6C297D3A766F696420307D29297D6C652E70757368284528617428662C63292C632E7374796C65643F7B626F6C643A632E626F6C642C73697A653A632E73697A653F4D6174682E726F756E6428322A632E73697A65';
wwv_flow_imp.g_varchar2_table(1117) := '293A31372C66696C6C3A632E66696C6C2C636F6C6F723A632E636F6C6F722C616C69676E3A632E616C69676E2C7061643A692C6D6964646C653A6C7D3A7B626F6C643A21302C73697A653A31372C66696C6C3A6E2E6C6162656C46696C6C2C636F6C6F72';
wwv_flow_imp.g_varchar2_table(1118) := '3A6E2E6C6162656C436F6C6F722C7061643A692C6D6964646C653A6C7D292C28753D747428742C722C4B292C45284D6528742C722C4B292C7B73697A653A31372C636F6C6F723A752626752E636F6C6F727C7C6E2E76616C7565436F6C6F722C7061643A';
wwv_flow_imp.g_varchar2_table(1119) := '692C6D6964646C653A6C2C626F6C643A753F752E626F6C643A766F696420302C616C69676E3A753F752E616C69676E3A766F696420302C66696C6C3A753F752E66696C6C3A766F696420302C6C696E6B3A5A28742C722C4B292C6C696E6B436F6C6F723A';
wwv_flow_imp.g_varchar2_table(1120) := '752626752E636F6C6F727C7C612E6C696E6B2C7370616E3A652E7370616E3E313F322A652E7370616E2D313A766F696420307D2929297D7D293B666F722876617220743D322A65742865293B743C322A6E653B742B2B296C652E70757368284528222229';
wwv_flow_imp.g_varchar2_table(1121) := '293B61652E70757368286E6577206F2E5461626C65526F77287B6368696C6472656E3A6C657D29292C6C653D5B5D7D292C61652E6C656E677468297B7661722075653D5B5D3B6966286E2E677269647C7C41727261792E69734172726179286E2E6C6162';
wwv_flow_imp.g_varchar2_table(1122) := '656C57696474687329297B666F72287661722063653D5B5D2C66653D302C64653D303B64653C6E653B64652B2B2963652E70757368284D6174682E726F756E642835362E372A5A65286E2C64652929292C66652B3D63655B64655D3B7661722068653D4D';
wwv_flow_imp.g_varchar2_table(1123) := '6174682E6D6178283630302C4D6174682E726F756E642828642D6665292F6E6529293B666F722864653D303B64653C6E653B64652B2B2975652E707573682863655B64655D2C6865297D656C736520666F72287661722070653D303B70653C322A6E653B';
wwv_flow_imp.g_varchar2_table(1124) := '70652B2B2975652E70757368284D6174682E726F756E6428642F28322A6E652929293B6C2E70757368286E6577206F2E5461626C65287B726F77733A61652C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C63';
wwv_flow_imp.g_varchar2_table(1125) := '6F6C756D6E5769647468733A75652C626F72646572733A6E2E677269643F62286E2E626F72646572436F6C6F727C7C5865293A702C6C61796F75743A6E2E677269643F6F2E5461626C654C61796F7574547970652E46495845443A766F696420307D292C';
wwv_flow_imp.g_varchar2_table(1126) := '532829297D7D656C736520696628227461726A65746173223D3D3D75297B7661722067653D6474286E2C722C61293B6966282167652E6974656D732E6C656E6774682972657475726E3B666F72287661722076653D4D6174682E726F756E642835362E37';
wwv_flow_imp.g_varchar2_table(1127) := '2A67652E63617264476170292C62653D4D6174682E666C6F6F722828642D76652A2867652E6E2D3129292F67652E6E292C77653D5B5D2C79653D5B5D2C53653D303B53653C67652E6E3B53652B2B295365262679652E70757368287665292C79652E7075';
wwv_flow_imp.g_varchar2_table(1128) := '7368286265293B666F72287661722043653D7B7374796C653A6F2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C41653D303B41653C67652E6974656D732E6C656E6774683B41652B3D67652E6E29';
wwv_flow_imp.g_varchar2_table(1129) := '7B666F7228766172206B653D5B5D2C44653D303B44653C67652E6E3B44652B2B297B766172206A653D67652E6974656D735B41652B44655D3B446526266B652E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B78282222';
wwv_flow_imp.g_varchar2_table(1130) := '295D2C626F72646572733A7B746F703A43652C626F74746F6D3A43652C6C6566743A43652C72696768743A43657D7D29292C6A653F6B652E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B78286A652E6C6162656C2C7B';
wwv_flow_imp.g_varchar2_table(1131) := '73697A653A322A67652E6C6162656C53697A652C636F6C6F723A67652E6C6162656C436F6C6F727D292C6E6577206F2E506172616772617068287B6368696C6472656E3A5B79286A652E76616C75652C7B626F6C643A21302C73697A653A322A67652E73';
wwv_flow_imp.g_varchar2_table(1132) := '697A652C636F6C6F723A6A652E636F6C6F727C7C67652E76616C7565436F6C6F727D295D2C73706163696E673A7B6265666F72653A34302C61667465723A307D7D295D2C6D617267696E733A7B746F703A3130302C626F74746F6D3A3130302C6C656674';
wwv_flow_imp.g_varchar2_table(1133) := '3A3136302C72696768743A3130307D2C766572746963616C416C69676E3A6F2E566572746963616C416C69676E2E43454E5445522C73686164696E673A7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C';
wwv_flow_imp.g_varchar2_table(1134) := '66696C6C3A6D2867652E66696C6C297D2C626F72646572733A7B746F703A43652C626F74746F6D3A43652C72696768743A43652C6C6566743A67652E616363656E743F7B7374796C653A6F2E426F726465725374796C652E53494E474C452C73697A653A';
wwv_flow_imp.g_varchar2_table(1135) := '32342C636F6C6F723A6D2867652E616363656E74297D3A43657D7D29293A6B652E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B78282222295D2C626F72646572733A7B746F703A43652C626F74746F6D3A43652C6C65';
wwv_flow_imp.g_varchar2_table(1136) := '66743A43652C72696768743A43657D7D29297D77652E6C656E677468262677652E70757368286E6577206F2E5461626C65526F77287B6865696768743A7B76616C75653A76652C72756C653A6F2E48656967687452756C652E45584143547D2C6368696C';
wwv_flow_imp.g_varchar2_table(1137) := '6472656E3A79652E6D61702866756E6374696F6E28297B72657475726E206E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B78282222295D2C626F72646572733A7B746F703A43652C626F74746F6D3A43652C6C6566743A43652C7269';
wwv_flow_imp.g_varchar2_table(1138) := '6768743A43657D7D297D297D29292C77652E70757368286E6577206F2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A6B657D29297D6C2E70757368286E6577206F2E5461626C65287B726F77733A77652C7769647468';
wwv_flow_imp.g_varchar2_table(1139) := '3A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A79652C626F72646572733A702C6C61796F75743A6F2E5461626C654C61796F7574547970652E46495845447D292C532829297D656C736520';
wwv_flow_imp.g_varchar2_table(1140) := '69662822666F726D756C6172696F223D3D3D75297B7661722049653D6E2E636F6C756D6E737C7C322C52653D5B5D2C42653D5B5D2C5F653D312C47653D5565286E2C722C68292C48653D7B7374796C653A6F2E426F726465725374796C652E53494E474C';
wwv_flow_imp.g_varchar2_table(1141) := '452C73697A653A342C636F6C6F723A6D284C65297D3B6966284B652847652C4965292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E6374696F6E2865297B76617220743D652E663B696628652E656D707479294265';
wwv_flow_imp.g_varchar2_table(1142) := '2E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206F2E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A322A652E7370616E7D29293B656C73657B7328742E6E616D';
wwv_flow_imp.g_varchar2_table(1143) := '65293B76617220723D692E6C656E6774683B692E707573682874292C5F653D4D6174682E6D6178285F652C742E6C696E6573293B766172206E3D742E6C696E65733E313F6F2E566572746963616C416C69676E2E544F503A6F2E566572746963616C416C';
wwv_flow_imp.g_varchar2_table(1144) := '69676E2E43454E5445522C613D742E6C61623B696628226C65667422213D3D612E706F73297B766172206C3D6E6577206F2E5461626C65287B77696474683A7B73697A653A3130302C747970653A6F2E5769647468547970652E50455243454E54414745';
wwv_flow_imp.g_varchar2_table(1145) := '7D2C626F72646572733A702C726F77733A5B6E6577206F2E5461626C65526F77287B6865696768743A742E6C696E65733E313F7B76616C75653A4D6174682E726F756E64283233302A742E6C696E65732B3630292C72756C653A6F2E4865696768745275';
wwv_flow_imp.g_varchar2_table(1146) := '6C652E41544C454153547D3A766F696420302C6368696C6472656E3A5B6E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206F2E506172616772617068287B6368696C6472656E3A5B792873722B722B22E29FA7222C7B73697A';
wwv_flow_imp.g_varchar2_table(1147) := '653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C766572746963616C416C69676E3A6E2C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F';
wwv_flow_imp.g_varchar2_table(1148) := '72646572733A7B746F703A48652C626F74746F6D3A48652C6C6566743A48652C72696768743A48657D2C73686164696E673A7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D284F65297D';
wwv_flow_imp.g_varchar2_table(1149) := '7D295D7D295D7D292C753D22746F70223D3D3D612E706F733F5B5428617428742E6C6162656C2C61292C612C612E616C69676E7C7C226C65667422295D3A5B5D3B72657475726E20752E70757368286C2C6E6577206F2E506172616772617068287B6368';
wwv_flow_imp.g_varchar2_table(1150) := '696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A302C61667465723A302C6C696E653A3132302C6C696E6552756C653A6F2E4C696E6552756C65547970652E45584143547D7D29292C766F69642042652E70757368286E6577206F2E5461';
wwv_flow_imp.g_varchar2_table(1151) := '626C6543656C6C287B6368696C6472656E3A752C636F6C756D6E5370616E3A322A652E7370616E2C766572746963616C416C69676E3A6F2E566572746963616C416C69676E2E544F502C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C';
wwv_flow_imp.g_varchar2_table(1152) := '6C6566743A36302C72696768743A36307D7D29297D42652E70757368286E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B612E7374796C65643F7828617428742E6C6162656C2C61292C7B626F6C643A612E626F6C642C73697A653A61';
wwv_flow_imp.g_varchar2_table(1153) := '2E73697A653F4D6174682E726F756E6428322A612E73697A65293A31372C636F6C6F723A612E636F6C6F722C616C69676E3A612E616C69676E7D293A7828742E6C6162656C2C7B626F6C643A21302C73697A653A31377D295D2C766572746963616C416C';
wwv_flow_imp.g_varchar2_table(1154) := '69676E3A6E2C73686164696E673A612E7374796C65642626612E66696C6C3F7B747970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D28612E66696C6C297D3A766F696420302C6D617267696E73';
wwv_flow_imp.g_varchar2_table(1155) := '3A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D292C6E6577206F2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206F2E506172616772617068287B6368696C6472656E3A5B792873722B722B';
wwv_flow_imp.g_varchar2_table(1156) := '22E29FA7222C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C636F6C756D6E5370616E3A652E7370616E3E313F322A652E7370616E2D313A766F696420302C766572746963616C416C69676E3A';
wwv_flow_imp.g_varchar2_table(1157) := '6E2C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A48652C626F74746F6D3A48652C6C6566743A48652C72696768743A48657D2C73686164696E673A7B74';
wwv_flow_imp.g_varchar2_table(1158) := '7970653A6F2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D284F65297D7D29297D7D293B666F722876617220743D322A65742865293B743C322A49653B742B2B2942652E70757368284528222229293B52';
wwv_flow_imp.g_varchar2_table(1159) := '652E70757368286E6577206F2E5461626C65526F77287B6368696C6472656E3A42652C63616E7453706C69743A21302C6865696768743A5F653E313F7B76616C75653A4D6174682E726F756E64283233302A5F652B313230292C72756C653A6F2E486569';
wwv_flow_imp.g_varchar2_table(1160) := '67687452756C652E41544C454153547D3A766F696420307D29292C42653D5B5D2C5F653D317D292C52652E6C656E677468297B7661722057653D5B5D2C56653D4D6174682E726F756E642835362E372A286E2E6C6162656C57696474687C7C333229292C';
wwv_flow_imp.g_varchar2_table(1161) := '24653D4D6174682E6D6178283630302C4D6174682E726F756E642828642D56652A4965292F496529293B56652A49652B3630302A49653E6426262856653D24653D4D6174682E726F756E6428642F28322A49652929293B666F72287661722059653D303B';
wwv_flow_imp.g_varchar2_table(1162) := '59653C49653B59652B2B2957652E707573682856652C2465293B6C2E70757368286E6577206F2E5461626C65287B726F77733A52652C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E57696474';
wwv_flow_imp.g_varchar2_table(1163) := '68733A57652C626F72646572733A702C6C61796F75743A6F2E5461626C654C61796F7574547970652E46495845447D292C532829297D7D656C73652069662822616C65727461223D3D3D752956286E2C72292E66696C7465722866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(1164) := '297B72657475726E2057286E2E7768656E2C722C65297D292E736C69636528302C6E2E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B6C2E70757368286E6577206F2E5461626C65287B726F77733A5B6E6577206F2E54';
wwv_flow_imp.g_varchar2_table(1165) := '61626C65526F77287B6368696C6472656E3A5B452847286E2E746578742C722C65292C7B626F6C643A21302C73697A653A31372C66696C6C3A24286E2E636F6C6F722C722C65297C7C2223453645434632227D295D7D295D2C77696474683A7B73697A65';
wwv_flow_imp.g_varchar2_table(1166) := '3A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A707D292C532829297D293B656C736520696628227461626C61223D3D3D75297B7661722071653D56286E2C72293B69662821';
wwv_flow_imp.g_varchar2_table(1167) := '71652E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B7661722051653D5065286E2C7165293B69662851652972657475726E20766F69642051652E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(1168) := '6F6E28652C72297B7226266C2E70757368286E6577206F2E506172616772617068287B6368696C6472656E3A5B6E6577206F2E50616765427265616B5D7D29292C742865297D293B7661722072743D7465286E2C722C7165292C6F743D5B5D3B6E2E7469';
wwv_flow_imp.g_varchar2_table(1169) := '746C6526266F742E70757368286E6577206F2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A5B452847286E2E7469746C652C72292C7B626F6C643A21302C636F6C6F723A612E68656164546578742C66696C6C3A';
wwv_flow_imp.g_varchar2_table(1170) := '612E7072696D6172792C7370616E3A72742E6C656E6774682C73697A653A772B327D295D7D29292C6E2E67726F75707326266F742E70757368286E6577206F2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A7265';
wwv_flow_imp.g_varchar2_table(1171) := '286E2C7274292E6D61702866756E6374696F6E2865297B72657475726E204528652E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A612E68656164546578742C66696C6C3A612E7072696D6172792C616C69676E3A2263656E746572222C';
wwv_flow_imp.g_varchar2_table(1172) := '7370616E3A652E636F6C737D297D297D29292C6F742E70757368286E6577206F2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A72742E6D61702866756E6374696F6E2865297B72657475726E204528652E6C6162';
wwv_flow_imp.g_varchar2_table(1173) := '656C2C7B626F6C643A21302C636F6C6F723A612E68656164546578742C66696C6C3A612E7072696D6172792C616C69676E3A4A6528652C6E297D297D297D29292C71652E6C656E6774687C7C6F742E70757368286E6577206F2E5461626C65526F77287B';
wwv_flow_imp.g_varchar2_table(1174) := '6368696C6472656E3A5B452847286E2E656D707479546578742C72292C7B6974616C69633A21302C7370616E3A72742E6C656E6774687D295D7D29293B766172206C743D5465286E292C69743D7B7D2C73743D6965286E2C7274292C75743D66756E6374';
wwv_flow_imp.g_varchar2_table(1175) := '696F6E2865297B76617220743D4528652E746578742C7B626F6C643A21302C616C69676E3A226C656674222C66696C6C3A612E746F74616C732C7370616E3A652E61747C7C72742E6C656E6774682C636F6C6F723A6E2E746F74616C73436F6C6F727D29';
wwv_flow_imp.g_varchar2_table(1176) := '2C723D652E63656C6C732E736C69636528652E6174292E6D61702866756E6374696F6E2865297B72657475726E204528652C7B626F6C643A21302C616C69676E3A227269676874222C66696C6C3A612E746F74616C732C636F6C6F723A6E2E746F74616C';
wwv_flow_imp.g_varchar2_table(1177) := '73436F6C6F727D297D293B72657475726E20303D3D3D652E61743F5B6E6577206F2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D7D292C6E6577206F2E5461626C65526F77287B63616E7453706C69743A2130';
wwv_flow_imp.g_varchar2_table(1178) := '2C6368696C6472656E3A727D295D3A5B6E6577206F2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D2E636F6E6361742872297D295D7D3B6966284E65286E2C7165292E666F72456163682866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(1179) := '2865297B696628226865616422213D3D652E6B296966282273756222213D3D652E6B297B76617220743D652E722C6C3D652E692C693D59286E2E726F775374796C652C722C74293B6F742E70757368286E6577206F2E5461626C65526F77287B63616E74';
wwv_flow_imp.g_varchar2_table(1180) := '53706C69743A21302C6368696C6472656E3A72742E6D61702866756E6374696F6E28652C73297B76617220752C632C663D5928652E63656C6C5374796C652C722C74297C7C697C7C7B7D3B696628652E63656C6C297B76617220643D736528652C742C72';
wwv_flow_imp.g_varchar2_table(1181) := '2C61292C683D662E66696C6C7C7C286C25323D3D3126262131213D3D6E2E7A656272613F612E7A656272613A6E756C6C293B6426262869745B735D3D4D6174682E6D61782869745B735D7C7C302C642E7729293B76617220703D652E76616C69676E7C7C';
wwv_flow_imp.g_varchar2_table(1182) := '73743B72657475726E206E6577206F2E5461626C6543656C6C287B766572746963616C416C69676E3A22746F70223D3D3D703F6F2E566572746963616C416C69676E2E544F503A22626F74746F6D223D3D3D703F6F2E566572746963616C416C69676E2E';
wwv_flow_imp.g_varchar2_table(1183) := '424F54544F4D3A6F2E566572746963616C416C69676E2E43454E5445522C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A683F7B747970653A6F2E53686164696E6754';
wwv_flow_imp.g_varchar2_table(1184) := '7970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6D2868297D3A766F696420302C6368696C6472656E3A5B6E6577206F2E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E';
wwv_flow_imp.g_varchar2_table(1185) := '6D656E743A227269676874223D3D3D652E616C69676E3F6F2E416C69676E6D656E74547970652E52494748543A226C656674223D3D3D652E616C69676E3F6F2E416C69676E6D656E74547970652E4C4546543A6F2E416C69676E6D656E74547970652E43';
wwv_flow_imp.g_varchar2_table(1186) := '454E5445522C6368696C6472656E3A643F5B28753D6E6577206F2E496D61676552756E287B747970653A226A7067223D3D3D642E696D2E6578743F226A7067223A22706E67222C646174613A642E696D2E6275662C7472616E73666F726D6174696F6E3A';
wwv_flow_imp.g_varchar2_table(1187) := '7B77696474683A4D6174682E726F756E6428332E37382A642E77292C6865696768743A4D6174682E726F756E6428332E37382A642E68297D7D292C633D5A28652C722C74292C633F6E6577206F2E45787465726E616C48797065726C696E6B287B6C696E';
wwv_flow_imp.g_varchar2_table(1188) := '6B3A632C6368696C6472656E3A5B755D7D293A75295D3A5B5D7D295D7D297D72657475726E2045286F6528652C742C72292C7B76616C69676E3A652E76616C69676E7C7C73742C616C69676E3A652E616C69676E2C626F6C643A652E626F6C647C7C662E';
wwv_flow_imp.g_varchar2_table(1189) := '626F6C642C636F6C6F723A662E636F6C6F727C7C652E636F6C6F722C6C696E6B3A5A28652C722C74292C6C696E6B436F6C6F723A662E636F6C6F727C7C652E636F6C6F727C7C612E6C696E6B2C66696C6C3A662E66696C6C7C7C286C25323D3D31262621';
wwv_flow_imp.g_varchar2_table(1190) := '31213D3D6E2E7A656272613F612E7A656272613A6E756C6C297D297D297D29297D656C73652075742878652872742C6C742C652E726F77732C7A65286E2C652C722929292E666F72456163682866756E6374696F6E2865297B6F742E707573682865297D';
wwv_flow_imp.g_varchar2_table(1191) := '293B656C7365206F742E70757368286E6577206F2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B45287A65286E2C652C72292C7B626F6C643A21302C66696C6C3A466528612C652E6C766C292C7370616E3A72742E';
wwv_flow_imp.g_varchar2_table(1192) := '6C656E6774687D295D7D29297D292C6D65286E2E746F74616C73292E6C656E677468262671652E6C656E677468297B7661722063743D6E2E5F616C6C526F77737C7C71653B75742878652872742C6D65286E2E746F74616C73292C63742C4565286E2C72';
wwv_flow_imp.g_varchar2_table(1193) := '2C63742929292E666F72456163682866756E6374696F6E2865297B6F742E707573682865297D297D7661722068743D72742E6D61702866756E6374696F6E28652C74297B72657475726E20652E77696474683F652E77696474682F32303A69745B745D3F';
wwv_flow_imp.g_varchar2_table(1194) := '4D6174682E6D617828312C2869745B745D2B34292F3230293A317D292C70743D68742E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C67743D68742E6D61702866756E6374696F6E2865297B72657475726E20';
wwv_flow_imp.g_varchar2_table(1195) := '4D6174682E666C6F6F7228642A652F7074297D293B6C2E70757368286E6577206F2E5461626C65287B726F77733A6F742C77696474683A7B73697A653A642C747970653A6F2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A6774';
wwv_flow_imp.g_varchar2_table(1196) := '2C626F72646572733A21313D3D3D6E2E677269643F703A62286E2E677269643F6E2E626F72646572436F6C6F727C7C58653A6E756C6C297D292C532829297D7D293B76617220673D652E666F6F7465722C763D502872292C413D652E7061676548656164';
wwv_flow_imp.g_varchar2_table(1197) := '65722626226F626A656374223D3D747970656F6620652E706167654865616465723F652E706167654865616465723A6E756C6C2C4E3D7B706167653A7B73697A653A7B77696474683A755B305D2C6865696768743A755B315D2C6F7269656E746174696F';
wwv_flow_imp.g_varchar2_table(1198) := '6E3A633F6F2E506167654F7269656E746174696F6E2E4C414E4453434150453A6F2E506167654F7269656E746174696F6E2E504F5254524149547D2C6D617267696E3A7B746F703A662C626F74746F6D3A662C6C6566743A662C72696768743A667D7D7D';
wwv_flow_imp.g_varchar2_table(1199) := '2C4D3D763F7B64656661756C743A767D3A766F696420302C6B3D673F7B64656661756C743A6E6577206F2E466F6F746572287B6368696C6472656E3A697228672C722C61297D297D3A766F696420303B69662841297B766172204F3D7A2872293B4D3D7B';
wwv_flow_imp.g_varchar2_table(1200) := '64656661756C743A6E6577206F2E486561646572287B6368696C6472656E3A284F3F5B4F5D3A5B5D292E636F6E636174285B4628412C72292C6E6577206F2E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D';
wwv_flow_imp.g_varchar2_table(1201) := '2C6368696C6472656E3A5B5D7D295D297D297D2C21313D3D3D412E6669727374506167652626284E2E7469746C65506167653D21302C4D2E66697273743D502872297C7C6E6577206F2E486561646572287B6368696C6472656E3A5B6E6577206F2E5061';
wwv_flow_imp.g_varchar2_table(1202) := '72616772617068287B6368696C6472656E3A5B5D7D295D7D292C672626286B2E66697273743D6E6577206F2E466F6F746572287B6368696C6472656E3A697228672C722C61297D2929297D72657475726E20742E6C656E6774683E31262666756E637469';
wwv_flow_imp.g_varchar2_table(1203) := '6F6E2865297B76617220743D4A534F4E2E737472696E67696679285B652E666F6F7465727C7C6E756C6C2C652E706167654865616465727C7C6E756C6C5D293B72657475726E2F5C7B444F4350414745533F5C7D2F2E746573742874297D286529262628';
wwv_flow_imp.g_varchar2_table(1204) := '4E2E706167652E706167654E756D626572733D7B73746172743A317D292C7B686561646572733A4D2C70726F706572746965733A4E2C666F6F746572733A6B2C6368696C6472656E3A6C2E6C656E6774683F6C3A5B78282222295D7D7D292C6B3D6E6577';
wwv_flow_imp.g_varchar2_table(1205) := '206F2E446F63756D656E74287B63726561746F723A226E6F76615265706F7274222C7469746C653A4728652E7469746C657C7C22222C745B305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A4D7D292C4F3D6F2E5061636B65722E746F42';
wwv_flow_imp.g_varchar2_table(1206) := '6C6F623F6F2E5061636B65722E746F426C6F62286B292E7468656E2866756E6374696F6E2865297B72657475726E20652E61727261794275666665723F652E617272617942756666657228293A657D293A6F2E5061636B65722E746F427566666572286B';
wwv_flow_imp.g_varchar2_table(1207) := '293B72657475726E20692E6C656E6774683F4F2E7468656E2866756E6374696F6E2874297B72657475726E20667228742C692C426528652C7229297D293A4F7D7661722068723D7B7D3B66756E6374696F6E2070722865297B76617220743D652E73706C';
wwv_flow_imp.g_varchar2_table(1208) := '697428227C22292C723D745B305D2E7472696D28292C6E3D745B315D3F745B315D2E7472696D28293A6E756C6C3B72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E223D3D3D722972657475726E20653B666F7228766172206F';
wwv_flow_imp.g_varchar2_table(1209) := '3D722E73706C697428222E22292C613D742626742E73636F70654C6973743F742E73636F70654C6973742E736C69636528292E7265766572736528293A5B655D2C6C3D303B6C3C612E6C656E6774683B6C2B2B297B666F722876617220693D615B6C5D2C';
wwv_flow_imp.g_varchar2_table(1210) := '733D21302C753D303B753C6F2E6C656E6774683B752B2B297B69662841727261792E697341727261792869292626753E30262628693D695B305D292C6E756C6C3D3D697C7C226F626A65637422213D747970656F6620697C7C21286F5B755D696E206929';
wwv_flow_imp.g_varchar2_table(1211) := '297B733D21313B627265616B7D693D695B6F5B755D5D7D696628732972657475726E206E26262141727261792E697341727261792869293F5328692C6E293A697D7D7D7D66756E6374696F6E20677228652C74297B76617220723D6E65772077696E646F';
wwv_flow_imp.g_varchar2_table(1212) := '772E50697A5A69702865292C6E3D6E657728302C77696E646F772E646F637874656D706C617465722928722C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A70722C6E756C6C4765747465723A66756E';
wwv_flow_imp.g_varchar2_table(1213) := '6374696F6E28297B72657475726E22227D7D293B72657475726E206E2E72656E6465722866756E6374696F6E2865297B76617220742C723D7B7D3B666F72287420696E20652E706172616D737C7C7B7D29725B745D3D652E706172616D735B745D3B666F';
wwv_flow_imp.g_varchar2_table(1214) := '72287420696E20652E646F637C7C7B7D29725B745D3D652E646F635B745D3B666F72287420696E20652E5329725B745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C';
wwv_flow_imp.g_varchar2_table(1215) := '722E4E4F573D6228292C722E544F4441593D7728292C727D287429292C50726F6D6973652E7265736F6C7665286E2E6765745A697028292E67656E6572617465287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445';
wwv_flow_imp.g_varchar2_table(1216) := '464C415445227D29297D66756E6374696F6E206D722865297B76617220743D7B7D2C723D7B7D3B72657475726E204F626A6563742E6B65797328657C7C7B7D292E666F72456163682866756E6374696F6E286E297B766172206F3D655B6E5D2C613D6F2E';
wwv_flow_imp.g_varchar2_table(1217) := '636F6C737C7C5B5D3B725B6E5D3D7B7D2C612E666F72456163682866756E6374696F6E2865297B725B6E5D5B652E6E616D655D3D652E747970657D292C745B6E5D3D286F2E726F77737C7C5B5D292E6D61702866756E6374696F6E2865297B7661722074';
wwv_flow_imp.g_varchar2_table(1218) := '3D7B7D3B72657475726E20612E666F72456163682866756E6374696F6E28722C6E297B745B722E6E616D655D3D655B6E5D7D292C747D297D292C7B533A742C543A727D7D66756E6374696F6E20767228652C74297B76617220723D652E532E444F43533B';
wwv_flow_imp.g_varchar2_table(1219) := '69662821722972657475726E5B7B533A652E532C543A652E542C646F633A7B7D2C706172616D733A747D5D3B766172206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B696628';
wwv_flow_imp.g_varchar2_table(1220) := '22444F435322213D3D7426264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B745D3D7B7D3B652E535B745D2E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(1221) := '6374696F6E2865297B76617220743D537472696E6728652E444F435F4B4559293B28725B745D3D725B745D7C7C5B5D292E707573682865297D297D7D292C722E6D61702866756E6374696F6E2872297B766172206F3D7B7D3B72657475726E204F626A65';
wwv_flow_imp.g_varchar2_table(1222) := '63742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B6F5B745D3D6E5B745D3F6E5B745D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B745D7D292C6F2E444F43533D5B725D2C7B533A6F2C543A652E';
wwv_flow_imp.g_varchar2_table(1223) := '542C646F633A722C706172616D733A747D7D297D66756E6374696F6E2062722865297B76617220743D646F63756D656E742E676574456C656D656E744279496428226E722D6176616E636522293B653F28747C7C2828743D646F63756D656E742E637265';
wwv_flow_imp.g_varchar2_table(1224) := '617465456C656D656E7428226469762229292E69643D226E722D6176616E6365222C742E7365744174747269627574652822726F6C65222C2273746174757322292C742E7374796C652E637373546578743D22706F736974696F6E3A66697865643B7269';
wwv_flow_imp.g_varchar2_table(1225) := '6768743A323470783B626F74746F6D3A323470783B7A2D696E6465783A313030303B70616464696E673A3134707820313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B';
wwv_flow_imp.g_varchar2_table(1226) := '666F6E742D73697A653A313370783B626F782D736861646F773A30203870782032347078207267626128302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287429292C';
wwv_flow_imp.g_varchar2_table(1227) := '742E696E6E657248544D4C3D273C7370616E20636C6173733D2266612066612D7370696E6E65722066612D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E72';
wwv_flow_imp.g_varchar2_table(1228) := '65706C616365282F5B263C3E225D2F672C66756E6374696F6E2865297B72657475726E7B2226223A2226616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B655D7D29293A742626742E72656D6F76';
wwv_flow_imp.g_varchar2_table(1229) := '6528297D66756E6374696F6E20777228652C74297B69662865262621652E636C6F736564297472797B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F616465724D73672977696E646F772E636F744C6F616465724D';
wwv_flow_imp.g_varchar2_table(1230) := '736728652C74293B656C73657B76617220723D652E646F63756D656E742E676574456C656D656E744279496428226D736722293B72262628722E74657874436F6E74656E743D74297D7D63617463682865297B7D7D66756E6374696F6E20797228652C74';
wwv_flow_imp.g_varchar2_table(1231) := '297B7472797B77696E646F772E617065782626617065782E6576656E742626617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C74297D63617463682865297B7D7D66756E6374696F6E207872';
wwv_flow_imp.g_varchar2_table(1232) := '2865297B77696E646F772E617065782626617065782E6D6573736167653F617065782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D66756E6374696F6E2045722865297B77696E646F772E61706578262661706578';
wwv_flow_imp.g_varchar2_table(1233) := '2E6D6573736167652626617065782E6D6573736167652E73686F7750616765537563636573732865297D7661722053723D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D';
wwv_flow_imp.g_varchar2_table(1234) := '6C666F726D6174732D6F6666696365646F63756D656E742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F72';
wwv_flow_imp.g_varchar2_table(1235) := '6470726F63657373696E676D6C2E646F63756D656E74227D2C54723D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E2043722865';
wwv_flow_imp.g_varchar2_table(1236) := '2C742C72297B766172206E3D4728652E66696C654E616D657C7C61282266696C654E616D6522292C74292C6F3D54725B725D3B72657475726E2045286E3D6E2E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C222229292B22';
wwv_flow_imp.g_varchar2_table(1237) := '2E222B6F7D66756E6374696F6E20417228652C742C722C6E297B72657475726E22706466223D3D3D653F657228742C722C6E2E686F6F6B732C6E293A22786C7378223D3D3D653F6E7228742C722C722E6C656E6774682C6E293A22646F6378223D3D3D65';
wwv_flow_imp.g_varchar2_table(1238) := '3F647228742C722C6E293A22646F63782D74656D706C617465223D3D3D653F286F3D6E2E74656D706C61746555726C2C6F3F286F3D4D74286F292C68725B6F5D3F50726F6D6973652E7265736F6C76652868725B6F5D293A6665746368286F2C7B637265';
wwv_flow_imp.g_varchar2_table(1239) := '64656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F722861282274706C446C222C652E73746174757329293B72657475726E20652E617272';
wwv_flow_imp.g_varchar2_table(1240) := '617942756666657228297D292E7468656E2866756E6374696F6E2865297B72657475726E2068725B6F5D3D652C657D29293A50726F6D6973652E72656A656374286E6577204572726F722861282274706C55726C22292929292E7468656E2866756E6374';
wwv_flow_imp.g_varchar2_table(1241) := '696F6E2865297B72657475726E20677228652C725B305D297D293A50726F6D6973652E72656A656374286E6577204572726F7228612822666D74426164222C652929293B766172206F7D66756E6374696F6E204E7228652C74297B76617220722C6E2C6F';
wwv_flow_imp.g_varchar2_table(1242) := '2C6C3D4D7228652E6C61796F7574292C693D7B7D3B666F72287220696E2075286C2C65292C6529695B725D3D655B725D3B72657475726E20692E6C61796F75743D6C2C50726F6D6973652E616C6C285B4C74286C292C286E3D6C2C6F3D652E666F726D61';
wwv_flow_imp.g_varchar2_table(1243) := '747C7C22706466222C2141727261792E69734172726179286E2E617070656E64297C7C2270646622213D3D6F262622616C6C22213D3D6F3F50726F6D6973652E7265736F6C766528293A50726F6D6973652E616C6C286E2E617070656E642E66696C7465';
wwv_flow_imp.g_varchar2_table(1244) := '722866756E6374696F6E2865297B72657475726E20652626652E75726C7D292E6D61702866756E6374696F6E2865297B76617220743D4D7428652E75726C293B72657475726E2046745B745D3F6E756C6C3A666574636828742C7B63726564656E746961';
wwv_flow_imp.g_varchar2_table(1245) := '6C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F72286128227064664C6F6164222C742C652E73746174757329293B72657475726E20652E6172726179';
wwv_flow_imp.g_varchar2_table(1246) := '42756666657228297D292E7468656E2866756E6374696F6E2865297B46745B745D3D657D297D2929295D292E7468656E2866756E6374696F6E28297B72657475726E2066756E6374696F6E28652C74297B76617220723D4D7228652E6C61796F7574292C';
wwv_flow_imp.g_varchar2_table(1247) := '6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D3B7528722C65293B766172206F3D6D722874292C6C3D7672286F2C652E706172616D737C7C7B7D292C69';
wwv_flow_imp.g_varchar2_table(1248) := '3D652E6F75747075747C7C2266696C65223B696628216C2E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228652E656D7074794D6573736167657C7C722E656D7074794D6573736167657C7C6128226E6F';
wwv_flow_imp.g_varchar2_table(1249) := '44617461222929293B696628722E62617463682626722E62617463682E6D6178446F637326266C2E6C656E6774683E722E62617463682E6D6178446F63732972657475726E2050726F6D6973652E72656A656374286E6577204572726F72286128226261';
wwv_flow_imp.g_varchar2_table(1250) := '7463684D6178222C722E62617463682E6D6178446F63732929293B6966282266696C65223D3D3D692626313D3D3D6C2E6C656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D692626313D3D3D6E2E6C656E677468262622646F';
wwv_flow_imp.g_varchar2_table(1251) := '63782D74656D706C61746522213D3D6E5B305D297B76617220733D6E5B305D3B72657475726E20417228732C722C6C2C65292E7468656E2866756E6374696F6E2874297B766172206E3D437228722C6C5B305D2C73293B6966286C2E6C656E6774683E31';
wwv_flow_imp.g_varchar2_table(1252) := '297B76617220693D722E6261746368262628722E62617463682E6D657267654E616D657C7C722E62617463682E7A69704E616D65297C7C722E66696C654E616D657C7C61282266696C654E616D6522293B6E3D4372287B66696C654E616D653A53747269';
wwv_flow_imp.g_varchar2_table(1253) := '6E672869292E7265706C616365282F5C2E7A6970242F692C2222297D2C7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C73297D72657475726E7B6B696E643A732C646174613A742C6E616D653A6E';
wwv_flow_imp.g_varchar2_table(1254) := '2C636F756E743A6C2E6C656E6774687D7D297D76617220632C663D6E65772077696E646F772E4A535A69702C643D302C683D302C703D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C673D7B7D3B666F72286320696E20652E';
wwv_flow_imp.g_varchar2_table(1255) := '706172616D737C7C7B7D29675B635D3D652E706172616D735B635D3B672E464F524D41544F3D6E2E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74';
wwv_flow_imp.g_varchar2_table(1256) := '656D706C617465223A22776F7264227D5B6E5B305D5D3B766172206D3D7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A677D2C763D7B7D3B66756E6374696F6E206228652C74297B666F722876617220723D652C6E3D323B765B722E';
wwv_flow_imp.g_varchar2_table(1257) := '746F4C6F7765724361736528295D3B29723D652E7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B6E2B22243122292C6E2B2B3B765B722E746F4C6F7765724361736528295D3D21302C662E66696C6528722C74292C642B2B7D7661722077';
wwv_flow_imp.g_varchar2_table(1258) := '3D50726F6D6973652E7265736F6C766528292C793D722E62617463682626722E62617463682E73756D6D6172793B792626227A6970223D3D3D69262628773D6E2E66696C7465722866756E6374696F6E2865297B72657475726E22646F63782D74656D70';
wwv_flow_imp.g_varchar2_table(1259) := '6C61746522213D3D657D292E7265647563652866756E6374696F6E28742C6E297B72657475726E20742E7468656E2866756E6374696F6E28297B76617220743D792E6C61796F75747C7C7B706167653A722E706167652C666F6F7465723A792E666F6F74';
wwv_flow_imp.g_varchar2_table(1260) := '65727C7C722E666F6F7465722C73656374696F6E733A792E73656374696F6E732C786C73783A792E786C73782C66696C654E616D653A792E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E66696C654E616D653D792E66';
wwv_flow_imp.g_varchar2_table(1261) := '696C654E616D657C7C2230305F726573756D656E22292C4172286E2C742C5B6D5D2C65292E7468656E2866756E6374696F6E2865297B6228437228742C6D2C6E292C65297D297D297D2C7729293B72657475726E20772E7468656E2866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(1262) := '28297B72657475726E206E65772050726F6D6973652866756E6374696F6E28742C6F297B66756E6374696F6E206928297B666F722876617220733D4D6174682E6D696E28682B702C6C2E6C656E677468292C753D50726F6D6973652E7265736F6C766528';
wwv_flow_imp.g_varchar2_table(1263) := '293B683C733B682B2B292866756E6374696F6E2874297B6E2E666F72456163682866756E6374696F6E286E297B753D752E7468656E2866756E6374696F6E28297B72657475726E204172286E2C722C5B745D2C65292E7468656E2866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(1264) := '65297B6228437228722C742C6E292C65297D297D297D297D29286C5B685D293B752E7468656E2866756E6374696F6E28297B652E6F6E50726F67726573732626652E6F6E50726F677265737328682C6C2E6C656E677468292C683C6C2E6C656E6774683F';
wwv_flow_imp.g_varchar2_table(1265) := '73657454696D656F757428692C30293A28652E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C64292C662E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D7072657373696F';
wwv_flow_imp.g_varchar2_table(1266) := '6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374696F6E2865297B766172206E3D4728722E62617463682626722E62617463682E7A69704E616D657C7C6128227A6970';
wwv_flow_imp.g_varchar2_table(1267) := '4E616D6522292C6D293B74287B6B696E643A227A6970222C646174613A652C6E616D653A45282F5C2E7A6970242F692E74657374286E293F6E3A6E2B222E7A697022292C636F756E743A6C2E6C656E6774682C66696C65733A647D297D2C6F29297D2C6F';
wwv_flow_imp.g_varchar2_table(1268) := '297D73657454696D656F757428692C30297D297D297D28692C74297D297D66756E6374696F6E2050722865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B65262628';
wwv_flow_imp.g_varchar2_table(1269) := '22636F6469676F223D3D3D652E747970652626227172223D3D3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292626742E696E6465784F6628227172636F646522293C302626742E7075736828227172636F646522';
wwv_flow_imp.g_varchar2_table(1270) := '292C226772616669636F223D3D3D652E747970652626742E696E6465784F66282263686172746A7322293C302626742E70757368282263686172746A7322292C22666F726D756C6172696F223D3D3D652E747970652626742E696E6465784F6628226A73';
wwv_flow_imp.g_varchar2_table(1271) := '7A697022293C302626742E7075736828226A737A697022292C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F72456163682872292C75655B652E747970655D2626722828652E6669656C64737C7C5B5D292E6D';
wwv_flow_imp.g_varchar2_table(1272) := '61702866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C22677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C227461626C61223D3D3D652E747970652626722828652E636F6C756D6E737C7C';
wwv_flow_imp.g_varchar2_table(1273) := '5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E63656C6C7D2929297D297D7228652E73656374696F6E73293B766172206E3D652E62617463682626652E62617463682E73756D6D6172793B72657475726E206E26262872';
wwv_flow_imp.g_varchar2_table(1274) := '286E2E73656374696F6E73292C6E2E6C61796F7574262672286E2E6C61796F75742E73656374696F6E7329292C41727261792E6973417272617928652E617070656E64292626652E617070656E642E6C656E6774682626742E7075736828227064666C69';
wwv_flow_imp.g_varchar2_table(1275) := '6222292C747D7661722046723D7B7461626C653A227461626C61222C63617264733A227461726A65746173222C64657461696C733A226669636861222C7265636F72643A226669636861222C616C6572743A22616C65727461222C746578743A22746578';
wwv_flow_imp.g_varchar2_table(1276) := '746F222C696D6167653A22696D6167656E222C63686172743A226772616669636F222C636F64653A22636F6469676F222C626172636F64653A22636F6469676F222C666F726D3A22666F726D756C6172696F222C6C696E653A226C696E6561222C636F6C';
wwv_flow_imp.g_varchar2_table(1277) := '756D6E733A22636F6C756D6E6173222C67726F75703A22677275706F222C73706163653A226573706163696F222C7370616365723A226573706163696F222C70616765627265616B3A2273616C746F222C627265616B3A2273616C746F227D3B66756E63';
wwv_flow_imp.g_varchar2_table(1278) := '74696F6E207A7228652C74297B69662822737472696E67223D3D747970656F66206526262240223D3D3D652E6368617241742830292626742626766F69642030213D3D745B652E7375627374722831295D2972657475726E207A7228745B652E73756273';
wwv_flow_imp.g_varchar2_table(1279) := '74722831295D2C74293B69662841727261792E697341727261792865292972657475726E20652E7265647563652866756E6374696F6E28652C72297B766172206E3D22737472696E67223D3D747970656F66207226262240223D3D3D722E636861724174';
wwv_flow_imp.g_varchar2_table(1280) := '283029262674262641727261792E6973417272617928745B722E7375627374722831295D292C6F3D7A7228722C74293B72657475726E206E3F652E636F6E636174286F293A652E636F6E636174285B6F5D297D2C5B5D293B696628652626226F626A6563';
wwv_flow_imp.g_varchar2_table(1281) := '74223D3D747970656F662065297B76617220723D7B7D3B72657475726E204F626A6563742E6B6579732865292E666F72456163682866756E6374696F6E286E297B725B6E5D3D2264656673223D3D3D6E3F655B6E5D3A7A7228655B6E5D2C74292C227479';
wwv_flow_imp.g_varchar2_table(1282) := '7065223D3D3D6E262622737472696E67223D3D747970656F6620725B6E5D26264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C2846722C725B6E5D2E746F4C6F77657243617365282929262628725B6E5D3D46';
wwv_flow_imp.g_varchar2_table(1283) := '725B725B6E5D2E746F4C6F7765724361736528295D297D292C727D72657475726E20657D66756E6374696F6E204D722865297B76617220743B696628652626226F626A656374223D3D747970656F66206529743D653B656C73657B76617220723D537472';
wwv_flow_imp.g_varchar2_table(1284) := '696E6728657C7C2222292E7472696D28293B696628227B223D3D3D722E63686172417428302929743D4A534F4E2E70617273652872293B656C7365206966282128743D722E73706C697428222E22292E7265647563652866756E6374696F6E28652C7429';
wwv_flow_imp.g_varchar2_table(1285) := '7B72657475726E20653F655B745D3A766F696420307D2C77696E646F772929297468726F77206E6577204572726F72286128226C61796F75744E46222C7229297D72657475726E207A7228742C742E64656673297D66756E6374696F6E206B722865297B';
wwv_flow_imp.g_varchar2_table(1286) := '69662865297B69662841727261792E697341727261792865297C7C22737472696E6722213D747970656F6620657C7C2F5B232E5C5B5D2F2E746573742865292972657475726E20653B76617220743D652E73706C697428222C22292E6D61702866756E63';
wwv_flow_imp.g_varchar2_table(1287) := '74696F6E2865297B72657475726E20652E7472696D28297D292E66696C74657228426F6F6C65616E293B72657475726E20742E6C656E6774683F743A766F696420307D7D66756E6374696F6E204F722865297B6E3D6C28652E6C616E67297C7C6928293B';
wwv_flow_imp.g_varchar2_table(1288) := '766172206F2C732C753D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C633D313D3D3D752E6C656E677468262622706466223D3D3D755B305D2626227A69';
wwv_flow_imp.g_varchar2_table(1289) := '7022213D3D652E6F7574707574262622646F776E6C6F616422213D3D652E706466416374696F6E2C663D6326262131213D3D652E6C6F616465723F66756E6374696F6E2865297B76617220743D77696E646F772E6F70656E2822222C225F626C616E6B22';
wwv_flow_imp.g_varchar2_table(1290) := '293B69662821742972657475726E206E756C6C3B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F61646572297472797B77696E646F772E636F744C6F616465722874293B76617220723D742E646F63756D656E742E';
wwv_flow_imp.g_varchar2_table(1291) := '676574456C656D656E747342795461674E616D652822683122295B305D3B72262628722E74657874436F6E74656E743D61282267656E65726174696E672229297D63617463682865297B7D656C736520742E646F63756D656E742E777269746528273C21';
wwv_flow_imp.g_varchar2_table(1292) := '646F63747970652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C7469746C653E272B61282267656E65726174696E6722292B27E280A63C2F7469746C653E3C7374796C653E626F64797B6D617267';
wwv_flow_imp.g_varchar2_table(1293) := '696E3A303B6865696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D';
wwv_flow_imp.g_varchar2_table(1294) := '73657269663B6261636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B77696474683A353670783B6865696768743A353670783B626F726465723A35707820736F6C';
wwv_flow_imp.g_varchar2_table(1295) := '696420236436653065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A72203173206C696E65617220696E66696E6974653B6D617267696E3A30206175746F2031';
wwv_flow_imp.g_varchar2_table(1296) := '3870787D406B65796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A23356236';
wwv_flow_imp.g_varchar2_table(1297) := '6237627D3C2F7374796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C68313E272B61282267656E65726174696E6722292B273C2F68313E3C702069643D226D736722';
wwv_flow_imp.g_varchar2_table(1298) := '3E3C2F703E3C2F6469763E3C2F626F64793E3C2F68746D6C3E27292C742E646F63756D656E742E636C6F736528293B72657475726E20777228742C65292C747D2821286F3D652E6D657373616765297C7C22657322213D3D6E26262F5E436F6E73756C74';
wwv_flow_imp.g_varchar2_table(1299) := '616E646F206461746F73285C2E5C2E5C2E7CE280A629242F2E7465737428537472696E67286F29293F6128227175657279696E6722293A6F293A6E756C6C2C643D77696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E7368';
wwv_flow_imp.g_varchar2_table(1300) := '6F775370696E6E657228293A6E756C6C2C683D227265736F6C766572223D3D3D652E6F726967696E262621652E646174612C703D227175657279223D3D3D652E6F726967696E262621652E646174613B696628216826262170297472797B733D4D722865';
wwv_flow_imp.g_varchar2_table(1301) := '2E6C61796F7574297D63617463682865297B72657475726E20642626642E72656D6F766528292C662626662E636C6F736528292C7872286128226C61796F7574426164222C652E6D65737361676529292C50726F6D6973652E72656A6563742865297D76';
wwv_flow_imp.g_varchar2_table(1302) := '617220673D7B6C61796F75743A732C666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D706C61746555726C2C686F6F6B733A65';
wwv_flow_imp.g_varchar2_table(1303) := '2E686F6F6B737C7C7B7D2C666F726D50617373776F72643A652E666F726D50617373776F72642C70646650617373776F72643A652E70646650617373776F72642C6C616E673A652E6C616E677D3B797228227374617274222C7B666F726D61743A652E66';
wwv_flow_imp.g_varchar2_table(1304) := '6F726D61742C6F75747075743A652E6F75747075742C7265706F72743A683F652E7265706F72743A766F696420307D293B766172206D3D722866756E6374696F6E28652C72297B766172206E3D5B5D3B72657475726E20652E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(1305) := '6374696F6E2865297B28745B655D7C7C5B5D292E666F72456163682866756E6374696F6E2865297B6E2E696E6465784F662865293C3026266E2E707573682865297D297D292C7226266E2E7075736828226A737A697022292C6E7D28752C226D65726765';
wwv_flow_imp.g_varchar2_table(1306) := '22213D3D652E6F7574707574292E636F6E63617428687C7C703F5B5D3A507228732929292C763D652E646174613F50726F6D6973652E7265736F6C7665287B646174613A652E646174617D293A6E65772050726F6D6973652866756E6374696F6E28742C';
wwv_flow_imp.g_varchar2_table(1307) := '72297B766172206F3D7B7830313A4A534F4E2E737472696E6769667928672E706172616D73292C7830323A227A6970223D3D3D652E6F75747075743F2259223A224E222C7830343A6E2C706167654974656D733A6B7228652E6974656D73297D3B696628';
wwv_flow_imp.g_varchar2_table(1308) := '68297B696628766F696420303D3D3D652E7265706F72747C7C6E756C6C3D3D3D652E7265706F72747C7C22223D3D3D652E7265706F72742972657475726E20766F69642072286E6577204572726F72286128227265706F7274526571222929293B6F2E78';
wwv_flow_imp.g_varchar2_table(1309) := '30333D537472696E6728652E7265706F7274297D617065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C6F2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B652626652E6F';
wwv_flow_imp.g_varchar2_table(1310) := '6B3F742865293A72286E6577204572726F7228652626652E6D73677C7C61282264617461457272222929297D2C66756E6374696F6E28652C742C6E297B72286E6577204572726F7228612822636F6D6D457272222C6E7C7C742929297D297D293B726574';
wwv_flow_imp.g_varchar2_table(1311) := '75726E2050726F6D6973652E616C6C285B762C6D5D292E7468656E2866756E6374696F6E2874297B766172206E3D745B305D2C6F3D50726F6D6973652E7265736F6C766528293B69662868297B7472797B733D4D72286E2E6C61796F7574297D63617463';
wwv_flow_imp.g_varchar2_table(1312) := '682865297B7468726F77206E6577204572726F72286128226C61796F7574426164222C652E6D65737361676529297D672E6C61796F75743D732C6E2E706172616D73262628672E706172616D733D6E2E706172616D73292C6E2E74656D706C6174655572';
wwv_flow_imp.g_varchar2_table(1313) := '6C262628672E74656D706C61746555726C3D6E2E74656D706C61746555726C292C6F3D72285072287329297D656C73652069662870297B766172206C3D6E2E6C61796F75747C7C652E6C61796F75743B696628216C297468726F77206E6577204572726F';
wwv_flow_imp.g_varchar2_table(1314) := '72286128226C61796F75744D697373696E672229293B7472797B733D4D72286C297D63617463682865297B7468726F77206E6577204572726F72286128226C61796F7574426164222C652E6D65737361676529297D672E6C61796F75743D732C6E2E7465';
wwv_flow_imp.g_varchar2_table(1315) := '6D706C61746555726C262628672E74656D706C61746555726C3D6E2E74656D706C61746555726C292C6F3D72285072287329297D72657475726E206F2E7468656E2866756E6374696F6E28297B72657475726E206E2E646174617D297D292E7468656E28';
wwv_flow_imp.g_varchar2_table(1316) := '66756E6374696F6E2874297B64262628642E72656D6F766528292C643D6E756C6C293B76617220723D652E7472616E73666F726D2626652E7472616E73666F726D2874297C7C743B72657475726E20777228662C6128226275696C64696E672229292C67';
wwv_flow_imp.g_varchar2_table(1317) := '2E6F6E50726F67726573733D66756E6374696F6E28652C74297B2D313D3D3D653F6272286128227A697070696E67222C7429293A2862722861282267656E4E222C652C7429292C7972282270726F6772657373222C7B646F6E653A652C746F74616C3A74';
wwv_flow_imp.g_varchar2_table(1318) := '7D29297D2C4E7228672C72297D292E7468656E2866756E6374696F6E2874297B76617220723D652E736176657C7C672E6C61796F75742626672E6C61796F75742E736176653B69662821727C7C21722E70726F636573732972657475726E20743B696628';
wwv_flow_imp.g_varchar2_table(1319) := '2177696E646F772E617065787C7C21617065782E736572766572297468726F77206E6577204572726F72286128226E656564417065782229293B72657475726E20627228612822736176696E672229292C66756E6374696F6E28652C742C72297B766172';
wwv_flow_imp.g_varchar2_table(1320) := '206E3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A53725B652E6B696E645D7C7C53722E646F63782C6F3D652E6461746120696E7374616E63656F6620426C6F623F652E646174613A6E657720426C6F62285B652E';
wwv_flow_imp.g_varchar2_table(1321) := '646174615D2C7B747970653A6E7D293B72657475726E206E65772050726F6D6973652866756E6374696F6E286C2C69297B76617220733D6E65772046696C655265616465723B732E6F6E6572726F723D66756E6374696F6E28297B69286E657720457272';
wwv_flow_imp.g_varchar2_table(1322) := '6F72286128227265616446696C65222929297D2C732E6F6E6C6F61643D66756E6374696F6E28297B766172206F2C753D537472696E6728732E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292C633D5B5D3B666F72';
wwv_flow_imp.g_varchar2_table(1323) := '286F3D303B6F3C752E6C656E6774683B6F2B3D33653429632E7075736828752E737562737472286F2C33653429293B617065782E7365727665722E70726F6365737328742E70726F636573732C7B7830313A652E6E616D652C7830323A6E2C7830333A76';
wwv_flow_imp.g_varchar2_table(1324) := '6F696420303D3D3D722E7265706F72743F22223A537472696E6728722E7265706F7274292C7830343A4A534F4E2E737472696E6769667928722E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A637D2C7B64617461547970653A226A';
wwv_flow_imp.g_varchar2_table(1325) := '736F6E227D292E7468656E2866756E6374696F6E2865297B65262621313D3D3D652E6F6B3F69286E6577204572726F7228652E6D73677C7C6128226E6F745361766564222929293A6C28657C7C7B7D297D2C66756E6374696F6E28652C742C72297B6928';
wwv_flow_imp.g_varchar2_table(1326) := '6E6577204572726F722861282273617665457272222C727C7C742929297D297D2C732E7265616441734461746155524C286F297D297D28742C722C7B7265706F72743A652E7265706F72742C706172616D733A672E706172616D737D292E7468656E2866';
wwv_flow_imp.g_varchar2_table(1327) := '756E6374696F6E2865297B72657475726E20742E73617665643D652C742E6F6E6C793D226F6E6C79223D3D3D722E6D6F64652C797228227361766564222C7B6E616D653A742E6E616D652C6B696E643A742E6B696E642C726573706F6E73653A657D292C';
wwv_flow_imp.g_varchar2_table(1328) := '747D297D292E7468656E2866756E6374696F6E2865297B696628627228292C652E6F6E6C7929662626662E636C6F736528292C457228652E73617665642626652E73617665642E6D73677C7C6128227361766564222C652E6E616D6529293B656C736520';
wwv_flow_imp.g_varchar2_table(1329) := '69662822706466223D3D3D652E6B696E64262663297B76617220743D55524C2E6372656174654F626A65637455524C286E657720426C6F62285B652E646174615D2C7B747970653A53722E7064667D29293B66262621662E636C6F7365643F662E6C6F63';
wwv_flow_imp.g_varchar2_table(1330) := '6174696F6E2E687265663D743A77696E646F772E6F70656E28742C225F626C616E6B22297D656C736520662626662E636C6F736528292C723D652E646174612C6E3D652E6E616D652C6F3D227A6970223D3D3D652E6B696E643F226170706C6963617469';
wwv_flow_imp.g_varchar2_table(1331) := '6F6E2F7A6970223A53725B652E6B696E645D7C7C53722E646F63782C6C3D7220696E7374616E63656F6620426C6F623F723A6E657720426C6F62285B725D2C7B747970653A6F7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D29';
wwv_flow_imp.g_varchar2_table(1332) := '2C28693D646F63756D656E742E637265617465456C656D656E742822612229292E687265663D55524C2E6372656174654F626A65637455524C286C292C692E646F776E6C6F61643D6E2C646F63756D656E742E626F64792E617070656E644368696C6428';
wwv_flow_imp.g_varchar2_table(1333) := '69292C692E636C69636B28292C73657454696D656F75742866756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C28692E68726566292C692E72656D6F766528297D2C346533292C227A6970223D3D3D652E6B696E64262645722861';
wwv_flow_imp.g_varchar2_table(1334) := '28227A6970446F6E65222C652E66696C65732C652E636F756E7429293B76617220722C6E2C6F2C6C2C693B72657475726E2079722822656E64222C7B6E616D653A652E6E616D652C636F756E743A652E636F756E742C66696C65733A652E66696C65737D';
wwv_flow_imp.g_varchar2_table(1335) := '292C657D292E63617463682866756E6374696F6E2865297B7468726F7720642626642E72656D6F766528292C627228292C66262621662E636C6F7365642626662E636C6F736528292C77696E646F772E636F6E736F6C652626636F6E736F6C652E657272';
wwv_flow_imp.g_varchar2_table(1336) := '6F722865292C797228226572726F72222C7B6D6573736167653A652E6D6573736167657D292C787228652E6D6573736167657C7C6128226661696C65642229292C657D297D766172204C723D21312C44723D6E756C6C3B72657475726E22756E64656669';
wwv_flow_imp.g_varchar2_table(1337) := '6E656422213D747970656F6620646F63756D656E742626646F63756D656E742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2865297B44723D65';
wwv_flow_imp.g_varchar2_table(1338) := '2E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D2C5B646174612D666F726D61745D22297C7C652E7461726765747D2C2130292C7B';
wwv_flow_imp.g_varchar2_table(1339) := '76657273696F6E3A22312E32342E30222C6C6962733A652C72756E3A4F722C64613A66756E6374696F6E2865297B76617220743D746869732626746869732E616374696F6E3F746869733A7B7D2C723D742E616374696F6E7C7C7B7D2C6E3D742E747269';
wwv_flow_imp.g_varchar2_table(1340) := '67676572696E67456C656D656E747C7C44722C6F3D742E62726F777365724576656E743B6966286F26266F2E70726576656E7444656661756C7426266F2E70726576656E7444656661756C7428292C214C72297B76617220613D652626226F626A656374';
wwv_flow_imp.g_varchar2_table(1341) := '223D3D747970656F6620653F653A7B7D2C6C3D2266756E6374696F6E223D3D747970656F6620653F653A612E696E69742C693D7B7D2C733D6E26266E2E646174617365747C7C7B7D2C753D612E7265706F72742C633D612E6F75747075747C7C722E6174';
wwv_flow_imp.g_varchar2_table(1342) := '7472696275746530337C7C2266696C65222C663D612E666F726D61747C7C722E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732873292E666F72456163682866756E6374696F6E2865297B226F757470757422213D3D653F22';
wwv_flow_imp.g_varchar2_table(1343) := '666F726D617422213D3D653F227265706F727422213D3D653F695B652E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D735B655D3A753D735B655D3A663D735B655D3A633D735B655D7D293B7661';
wwv_flow_imp.g_varchar2_table(1344) := '7220643D7B6C61796F75743A612E6C61796F75747C7C722E61747472696275746530312C666F726D61743A662C6F75747075743A632C6974656D733A612E6974656D737C7C722E61747472696275746530347C7C22222C706466416374696F6E3A612E70';
wwv_flow_imp.g_varchar2_table(1345) := '6466416374696F6E7C7C722E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A612E74656D706C61746555726C7C7C722E61747472696275746530362C6D6573736167653A612E6D6573736167657C7C722E617474726962';
wwv_flow_imp.g_varchar2_table(1346) := '75746530372C706172616D733A692C616A61784964656E7469666965723A612E616A61784964656E7469666965727C7C722E616A61784964656E7469666965722C6F726967696E3A612E6F726967696E7C7C2261747472696275746573222C7265706F72';
wwv_flow_imp.g_varchar2_table(1347) := '743A752C736176653A612E736176652C6C616E673A612E6C616E677D3B6966282266756E6374696F6E223D3D747970656F66206C297B76617220683D6C2864293B69662821313D3D3D682972657475726E3B643D687C7C647D4C723D21302C4F72286429';
wwv_flow_imp.g_varchar2_table(1348) := '2E7468656E2866756E6374696F6E28297B4C723D21317D2C66756E6374696F6E28297B4C723D21317D297D7D2C6C616E673A66756E6374696F6E28297B72657475726E206E7D2C6275696C643A4E722C656E737572653A722C6C61796F75744C6962733A';
wwv_flow_imp.g_varchar2_table(1349) := '50722C5F696E7465726E616C733A7B494D473A4E742C696D6744696D733A6B742C74706C3A472C636F6E643A572C666D743A532C6E6F726D616C697A653A6D722C636F6E74657874733A76722C636F64653132383A24742C706E67313A57742C6C61796F';
wwv_flow_imp.g_varchar2_table(1350) := '75744C6962733A50722C7368613531323A57652C776F72644C65676163794B65793A59652C776F7264486173683A71652C666F726D4E616D653A49652C7365744C6F63616C653A752C543A612C776F7264733A427D7D7D28293B';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(71250679706175556)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_file_name=>'novareport.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
