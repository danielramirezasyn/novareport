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
 p_version_yyyy_mm_dd=>'2023.10.31'
,p_release=>'23.2.0'
,p_default_workspace_id=>5173173563302459
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'AQS'
);
end;
/
 
prompt APPLICATION 100 - demo
--
-- Application Export:
--   Application:     100
--   Name:            demo
--   Date and Time:   17:35 Wednesday October 28, 2026
--   Exported By:     ADMIN
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 32000000000000001
--   Manifest End
--   Version:         23.2.0
--   Instance ID:     2371823922174481
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/dynamic_action/com_novacode_novareport
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(32000000000000001)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'COM.NOVACODE.NOVAREPORT'
,p_display_name=>'NovaCode Report (PDF / Excel / Word)'
,p_category=>'EXECUTE'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('-- novaReport: c\00F3digo PL/SQL del plugin (render + ajax) - APEX 23.2'),
'c_max_rows constant pls_integer := 250000;',
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
unistr('        raise_application_error(-20003, ''Configure la funci\00F3n resolver del plugin (p. ej. nrd_catalogo_pkg.resolver).'');'),
'    end if;',
'    if trim(p_id) is null then',
'        raise_application_error(-20004, ''Indique el reporte a generar (data-report).'');',
'    end if;',
'    execute immediate ''begin :r := '' || dbms_assert.qualified_sql_name(l_fn) || ''(p_id => :i, p_params => :p); end;''',
'        using out l_res, in trim(p_id), in p_params;',
'    if l_res is null then',
unistr('        raise_application_error(-20005, ''La funci\00F3n resolver no devolvi\00F3 el reporte.'');'),
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
'        raise_application_error(-20007, ''Configure la consulta del reporte (origen Consulta).'');',
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
unistr('            raise_application_error(-20008, ''La consulta del reporte devolvi\00F3 m\00E1s de una fila.'');'),
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
unistr('        raise_application_error(-20009, ''La consulta del reporte no devolvi\00F3 filas.'');'),
'    end if;',
'    if not l_known then',
'        raise_application_error(-20010, ''La consulta del reporte debe devolver las columnas LAYOUT y/o SOURCES.'');',
'    end if;',
'    if p_layout is not null and dbms_lob.getlength(p_layout) > 0 then',
'        begin',
'            l_chk := json_object_t.parse(p_layout);',
'        exception',
'            when others then',
unistr('                raise_application_error(-20011, ''La columna LAYOUT no es un JSON v\00E1lido: '' || regexp_replace(sqlerrm, ''^ORA-\005Cd+: '', ''''));'),
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
unistr('        raise_application_error(-20001, ''Defina al menos una fuente con una l\00EDnea "--@NOMBRE" antes del SELECT.'');'),
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
unistr('                raise_application_error(-20002, ''El reporte supera el m\00E1ximo de '' || c_max_rows || '' filas.'');'),
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
unistr('            raise_application_error(-20006, ''La funci\00F3n resolver no devolvi\00F3 el dise\00F1o.'');'),
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
unistr('    -- APEX 23.2 (API v1): configuraci\00F3n en this.action.attributeNN; origen e init en el objeto'),
'    l_r.ajax_identifier := apex_plugin.get_ajax_identifier;',
'    l_r.attribute_01 := p_dynamic_action.attribute_02;  -- layout',
'    l_r.attribute_02 := p_dynamic_action.attribute_03;  -- format',
'    l_r.attribute_03 := p_dynamic_action.attribute_04;  -- output',
'    l_r.attribute_04 := p_dynamic_action.attribute_05;  -- items',
'    l_r.attribute_05 := p_dynamic_action.attribute_06;  -- pdf_action',
'    l_r.attribute_06 := p_dynamic_action.attribute_07;  -- template_url',
'    l_r.attribute_07 := p_dynamic_action.attribute_08;  -- message',
'    l_r.javascript_function := ''function(){novaReport.da.call(this,{origin:''',
'        || apex_javascript.add_value(nvl(p_dynamic_action.attribute_09, ''attributes''), false)',
'        || case when l_init is not null then '',init:'' || l_init end',
'        || ''});}'';',
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
'    begin',
'        if nvl(p_dynamic_action.attribute_09, ''attributes'') = ''resolver'' then',
unistr('            -- Nunca se acepta SQL ni dise\00F1o del navegador: solo ID (x03) + par\00E1metros (x01)'),
'            l_res := nr_resolve(p_fn     => p_dynamic_action.attribute_10,',
'                                p_id     => apex_application.g_x03,',
'                                p_params => apex_application.g_x01);',
'            apex_json.initialize_clob_output;',
'            nr_write_json(p_sources => l_res.get_clob(''sources''),',
'                          p_params  => null,',
'                          p_summary => apex_application.g_x02 = ''Y'',',
'                          p_res     => l_res);',
'        elsif p_dynamic_action.attribute_09 = ''query'' then',
unistr('            -- Dise\00F1o y/o fuentes desde una consulta; lo que no devuelva se toma de los atributos'),
'            nr_query(p_sql     => p_dynamic_action.attribute_11,',
'                     p_params  => apex_application.g_x01,',
'                     p_layout  => l_lay,',
'                     p_sources => l_src,',
'                     p_tpl     => l_tpl);',
'            apex_json.initialize_clob_output;',
'            nr_write_json(p_sources => case when l_src is not null and dbms_lob.getlength(l_src) > 0 then l_src',
'                                            else to_clob(p_dynamic_action.attribute_01) end,',
'                          p_params  => apex_application.g_x01,',
'                          p_summary => apex_application.g_x02 = ''Y'',',
'                          p_layout  => l_lay,',
'                          p_tpl     => l_tpl);',
'        else',
'            apex_json.initialize_clob_output;',
'            nr_write_json(p_sources => p_dynamic_action.attribute_01,',
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
,p_subscribe_plugin_settings=>true
,p_help_text=>unistr('<p>Genera reportes PDF, Excel con estilos y Word desde fuentes SQL y un dise\00F1o JSON. Modo lote: un archivo por documento dentro de un ZIP, con resumen opcional. Librer\00EDas (jsPDF, autotable, ExcelJS, docx, docxtemplater, JSZip) se cargan bajo demanda.')
||'</p>'
,p_version_identifier=>'1.23.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>36
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000013)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Formato'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'pdf'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>unistr('Formato a generar. Puede sobrescribirse con <code>data-format</code> en el elemento que dispara la acci\00F3n.')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000032)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>20
,p_display_value=>'Excel (.xlsx con estilos)'
,p_return_value=>'xlsx'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000031)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>10
,p_display_value=>'PDF'
,p_return_value=>'pdf'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000035)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>50
,p_display_value=>'Todos (PDF + Excel + Word)'
,p_return_value=>'all'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000034)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>40
,p_display_value=>'Word desde plantilla'
,p_return_value=>'docx-template'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000033)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>30
,p_display_value=>'Word (.docx)'
,p_return_value=>'docx'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000015)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>unistr('\00CDtems a enviar')
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>unistr('\00CDtems cuyo valor actual de pantalla se env\00EDa antes de ejecutar las consultas.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000012)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>unistr('Dise\00F1o (JSON)')
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>unistr('Dise\00F1o en JSON (o el nombre de una variable JavaScript global con el dise\00F1o). Secciones: header, ficha, tabla, alerta, texto, salto. Plantillas {COL}, {FUENTE.COL}, {DOC.COL}, {ITEM.P1_X}, {NOW}, {PAGE}/{PAGES}; formatos {COL|money}, |int, |num:3, |p')
||'ct, |date, |upper. Reutilice bloques con "defs" y "@NOMBRE". Para Excel use "xlsx.sheets"; para lotes "batch" (zipName, summary, chunkSize, maxDocs).'
||unistr(' Con origen Consulta es opcional: se usa si la consulta no devuelve LAYOUT.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000018)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_prompt=>'Mensaje de espera'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Consultando datos...'
,p_max_length=>200
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000019)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>5
,p_prompt=>'Origen'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'attributes'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>unistr('<p><b>Atributos</b>: las fuentes SQL y el dise\00F1o se configuran en esta acci\00F3n.</p><p><b>Resolver</b>: el navegador solo env\00EDa el ID del reporte (<code>data-report</code> u <code>o.report</code> en Initialization Code) y los par\00E1metros; una funci\00F3n PL')
||unistr('/SQL valida el acceso y devuelve fuentes y dise\00F1o. Nunca se acepta SQL desde el navegador.</p><p><b>Consulta</b>: una consulta (sobre la tabla que usted elija) devuelve una fila con las columnas <code>LAYOUT</code> y/o <code>SOURCES</code> (y opcional <code>TEMP')
||unistr('LATE_URL</code>). Lo que no devuelva se toma de los atributos de esta acci\00F3n.</p>')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000061)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_display_sequence=>10
,p_display_value=>unistr('Atributos (fuentes y dise\00F1o aqu\00ED)')
,p_return_value=>'attributes'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175530)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_display_sequence=>15
,p_display_value=>unistr('Consulta (dise\00F1o y/o SQL desde una tabla)')
,p_return_value=>'query'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000062)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_display_sequence=>20
,p_display_value=>unistr('Resolver (funci\00F3n PL/SQL por ID de reporte)')
,p_return_value=>'resolver'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000014)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Salida'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'file'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>unistr('Puede sobrescribirse con <code>data-output</code> en el elemento (p. ej. un bot\00F3n con data-output="zip").')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000041)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000014)
,p_display_sequence=>10
,p_display_value=>'Archivo (ZIP si hay varios documentos)'
,p_return_value=>'file'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000043)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000014)
,p_display_sequence=>30
,p_display_value=>'Un solo archivo con todos los documentos'
,p_return_value=>'merge'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000042)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000014)
,p_display_sequence=>20
,p_display_value=>'ZIP: un archivo por documento + resumen'
,p_return_value=>'zip'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000016)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'PDF de un documento'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'open'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000051)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000016)
,p_display_sequence=>10
,p_display_value=>unistr('Abrir en una pesta\00F1a nueva (con pantalla de espera)')
,p_return_value=>'open'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000052)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000016)
,p_display_sequence=>20
,p_display_value=>'Descargar'
,p_return_value=>'download'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000020)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>6
,p_prompt=>unistr('Funci\00F3n resolver')
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_default_value=>'nrd_catalogo_pkg.resolver'
,p_display_length=>60
,p_max_length=>400
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>unistr('Funci\00F3n <code>f(p_id in varchar2, p_params in clob) return clob</code> que devuelve <code>{ "sources": "--@X ...", "layout": {...}, "params": {...}, "types": {"P": "text|number|date"} }</code>. Debe validar rol y par\00E1metros. Ver docs/API.md.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175529)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>7
,p_prompt=>'Consulta del reporte'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>true
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'query'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select layout, fuentes as sources',
'  from mis_reportes',
' where codigo = :P5_REPORTE'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('<p>Consulta que devuelve <b>una fila</b> con el dise\00F1o y/o las fuentes SQL guardados en una tabla. Columnas reconocidas por su alias:</p>'),
unistr('<ul><li><code>LAYOUT</code>: dise\00F1o JSON (CLOB).</li><li><code>SOURCES</code>: fuentes SQL con l\00EDneas <code>--@NOMBRE</code> (CLOB).</li><li><code>TEMPLATE_URL</code>: plantilla Word (opcional).</li></ul>'),
unistr('<p>Lo que no devuelva se toma de los atributos Dise\00F1o y Fuentes SQL. Admite \00EDtems de APEX (:P5_X) y binds desde <code>data-*</code>. Las fuentes SQL no viajan al navegador.</p>'),
unistr('<p><b>Seguridad</b>: el SQL guardado se ejecuta con los privilegios del schema; restrinja INSERT/UPDATE sobre esa tabla a los desarrolladores.</p>')))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000011)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Fuentes SQL'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('Una o varias consultas. Cada una inicia con una l\00EDnea <code>--@NOMBRE</code> (agregue <code>summary</code> para que solo se ejecute en descargas ZIP con resumen).'),
'<ul><li><b>DOCS</b> (opcional): una fila por documento; columna <code>DOC_KEY</code> obligatoria.</li>',
unistr('<li>Las dem\00E1s fuentes con columna <code>DOC_KEY</code> se reparten por documento; sin ella, se comparten.</li>'),
unistr('<li>Los \00EDtems de APEX se enlazan solos (:P1_X). Otros binds (:DET) toman su valor de los atributos <code>data-*</code> del elemento que dispara la acci\00F3n (data-det) o quedan en NULL.</li></ul>'),
'<p>Con origen Consulta es opcional: se usa si la consulta no devuelve SOURCES.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000017)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_prompt=>'Plantilla Word (URL)'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'docx-template'
,p_help_text=>'URL del .docx con marcadores {CAMPO}, {FUENTE.CAMPO}, bucles {#FUENTE}...{/FUENTE} y formatos {CAMPO|money}. Ej.: #APP_FILES#plantillas/carta.docx'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E32332E30202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C';
wwv_flow_imp.g_varchar2_table(2) := '72616D6972657A6173796E2F6E6F76617265706F7274202D204C6963656E636961204D49540A202A204E6F7661436F6465202D20706C7567696E2064652041636369C3B36E2044696EC3A16D69636120434F4D2E4E4F5641434F44452E4E4F5641524550';
wwv_flow_imp.g_varchar2_table(3) := '4F52540A202A0A202A204D6F746F72206465206C61796F75743A20756E206D69736D6F2064697365C3B16F20284A534F4E29207920756E6173206D69736D6173206675656E7465732053514C2067656E6572616E0A202A2050444620286A73504446202B';
wwv_flow_imp.g_varchar2_table(4) := '206175746F7461626C65292C20457863656C20636F6E20657374696C6F732028457863656C4A53292C20576F72642028646F637829206F20576F72642064657364650A202A20706C616E74696C6C612028646F637874656D706C61746572292E204D6F64';
wwv_flow_imp.g_varchar2_table(5) := '6F206C6F74653A20756E206172636869766F20706F7220646F63756D656E746F20656E20756E205A495020284A535A6970292E0A202A2F77696E646F772E6E6F76615265706F72743D2866756E6374696F6E28297B2275736520737472696374223B7661';
wwv_flow_imp.g_varchar2_table(6) := '72206C693D22312E32332E30222C756E3D7B6A737064663A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737064662F342E322E312F6A737064662E756D642E6D696E2E6A73222C6F';
wwv_flow_imp.g_varchar2_table(7) := '6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E6A73706466262677696E646F772E6A737064662E6A73504446297D7D2C6175746F7461626C653A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E63';
wwv_flow_imp.g_varchar2_table(8) := '6F6D2F616A61782F6C6962732F6A737064662D6175746F7461626C652F332E382E342F6A737064662E706C7567696E2E6175746F7461626C652E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E6A737064';
wwv_flow_imp.g_varchar2_table(9) := '66262677696E646F772E6A737064662E6A73504446262677696E646F772E6A737064662E6A735044462E4150492E6175746F5461626C65297D7D2C657863656C6A733A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F';
wwv_flow_imp.g_varchar2_table(10) := '6D2F616A61782F6C6962732F657863656C6A732F342E342E302F657863656C6A732E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E457863656C4A537D7D2C6A737A69703A7B75726C3A2268747470733A2F';
wwv_flow_imp.g_varchar2_table(11) := '2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737A69702F332E31302E312F6A737A69702E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E4A535A69707D7D2C646F6378';
wwv_flow_imp.g_varchar2_table(12) := '3A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637840392E352E312F646973742F696E6465782E696966652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E646F63';
wwv_flow_imp.g_varchar2_table(13) := '78262677696E646F772E646F63782E446F63756D656E74297D7D2C70697A7A69703A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F70697A7A697040332E312E382F646973742F70697A7A69702E6D696E2E6A73';
wwv_flow_imp.g_varchar2_table(14) := '222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E50697A5A69707D7D2C646F637874656D706C617465723A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637874656D706C6174';
wwv_flow_imp.g_varchar2_table(15) := '657240332E36302E302F6275696C642F646F637874656D706C617465722E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E646F637874656D706C617465727D7D2C7172636F64653A7B75726C3A2268747470';
wwv_flow_imp.g_varchar2_table(16) := '733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F7172636F64652D67656E657261746F7240312E342E342F7172636F64652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E20747970656F662077696E646F772E7172636F6465';
wwv_flow_imp.g_varchar2_table(17) := '3D3D2266756E6374696F6E227D7D2C63686172746A733A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F63686172742E6A7340342E342E392F646973742F63686172742E756D642E6A73222C6F6B3A66756E6374';
wwv_flow_imp.g_varchar2_table(18) := '696F6E28297B72657475726E21212877696E646F772E4368617274262677696E646F772E43686172742E7265676973746572297D7D2C7064666C69623A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A6178';
wwv_flow_imp.g_varchar2_table(19) := '2F6C6962732F7064662D6C69622F312E31372E312F7064662D6C69622E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E5044464C6962262677696E646F772E5044464C69622E504446446F63756D656E74';
wwv_flow_imp.g_varchar2_table(20) := '297D7D7D2C6F693D7B7064663A5B226A73706466222C226175746F7461626C65225D2C786C73783A5B22657863656C6A73225D2C646F63783A5B22646F6378225D2C22646F63782D74656D706C617465223A5B2270697A7A6970222C22646F637874656D';
wwv_flow_imp.g_varchar2_table(21) := '706C61746572225D2C7A69703A5B226A737A6970225D7D3B66756E6374696F6E2075692865297B72657475726E206E65772050726F6D6973652866756E6374696F6E28722C6E297B76617220743D77696E646F772E646566696E653B77696E646F772E64';
wwv_flow_imp.g_varchar2_table(22) := '6566696E653D766F696420303B76617220613D646F63756D656E742E637265617465456C656D656E74282273637269707422293B612E7372633D652C612E6F6E6C6F61643D66756E6374696F6E28297B77696E646F772E646566696E653D742C7228297D';
wwv_flow_imp.g_varchar2_table(23) := '2C612E6F6E6572726F723D66756E6374696F6E28297B77696E646F772E646566696E653D742C6E286E6577204572726F7228224E6F207365207075646F20636172676172206C61206C6962726572C3AD613A20222B6529297D2C646F63756D656E742E68';
wwv_flow_imp.g_varchar2_table(24) := '6561642E617070656E644368696C642861297D297D66756E6374696F6E204D742865297B72657475726E20652E7265647563652866756E6374696F6E28722C6E297B72657475726E20722E7468656E2866756E6374696F6E28297B72657475726E20756E';
wwv_flow_imp.g_varchar2_table(25) := '5B6E5D2E6F6B28293F6E756C6C3A756928247228756E5B6E5D2E75726C29297D297D2C50726F6D6973652E7265736F6C76652829297D76617220666E3D7B7072696D6172793A2223314634453739222C68656164546578743A2223464646464646222C7A';
wwv_flow_imp.g_varchar2_table(26) := '656272613A2223463546374641222C746F74616C733A2223453645434632222C746578743A2223303030303030222C6D757465643A2223373837383738222C666F6E7453697A653A372C67726F75703A2223444345364630222C6C696E6B3A2223303536';
wwv_flow_imp.g_varchar2_table(27) := '334331227D3B66756E6374696F6E204F742865297B72657475726E20747970656F6620653D3D226E756D6265722226262169734E614E2865297D66756E6374696F6E20242865297B72657475726E20653D537472696E6728657C7C222330303030303022';
wwv_flow_imp.g_varchar2_table(28) := '292E7265706C616365282223222C2222292C652E6C656E6774683D3D3D33262628653D652E7265706C616365282F282E292F672C22243124312229292C5B7061727365496E7428652E73756273747228302C32292C3136292C7061727365496E7428652E';
wwv_flow_imp.g_varchar2_table(29) := '73756273747228322C32292C3136292C7061727365496E7428652E73756273747228342C32292C3136295D7D66756E6374696F6E2046652865297B72657475726E224646222B537472696E6728657C7C222330303030303022292E7265706C6163652822';
wwv_flow_imp.g_varchar2_table(30) := '23222C2222292E746F55707065724361736528297D66756E6374696F6E2047652865297B72657475726E20537472696E6728657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E637469';
wwv_flow_imp.g_varchar2_table(31) := '6F6E204C742865297B72657475726E28653C31303F2230223A2222292B657D66756E6374696F6E20736E28297B76617220653D6E657720446174653B72657475726E204C7428652E676574446174652829292B222F222B4C7428652E6765744D6F6E7468';
wwv_flow_imp.g_varchar2_table(32) := '28292B31292B222F222B652E67657446756C6C5965617228292B2220222B4C7428652E676574486F7572732829292B223A222B4C7428652E6765744D696E757465732829297D66756E6374696F6E204A6E28297B72657475726E20736E28292E73756273';
wwv_flow_imp.g_varchar2_table(33) := '747228302C3130297D66756E6374696F6E20516E2865297B76617220723D537472696E672865292E746F4C6F7765724361736528292E7265706C616365282F5F2F672C222022293B72657475726E20722E6368617241742830292E746F55707065724361';
wwv_flow_imp.g_varchar2_table(34) := '736528292B722E736C6963652831297D66756E6374696F6E2074742865297B76617220723D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D29242F2E6578656328537472696E6728657C7C222229293B72657475726E20723F6E657720';
wwv_flow_imp.g_varchar2_table(35) := '4461746528446174652E555443282B725B335D2C2B725B325D2D312C2B725B315D29293A6E756C6C7D66756E6374696F6E20646E2865297B72657475726E20537472696E6728657C7C226172636869766F22292E7265706C616365282F5B5C5C5C2F3A2A';
wwv_flow_imp.g_varchar2_table(36) := '3F223C3E7C5D2B2F672C225F22292E7472696D28297D66756E6374696F6E204B6528652C72297B696628653D3D6E756C6C7C7C653D3D3D22222972657475726E22223B69662821722972657475726E20537472696E672865293B69662848722872292972';
wwv_flow_imp.g_varchar2_table(37) := '657475726E20736928652C72293B766172206E3D722E73706C697428223A22292C743D6E5B305D3B696628743D3D3D226D6F6E6579227C7C743D3D3D226E756D22297B76617220613D6E5B315D213D3D766F696420303F2B6E5B315D3A322C693D4E756D';
wwv_flow_imp.g_varchar2_table(38) := '6265722865293B72657475726E2069734E614E2869293F537472696E672865293A692E746F4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A612C6D6178696D756D4672616374696F6E4469';
wwv_flow_imp.g_varchar2_table(39) := '676974733A617D297D72657475726E20743D3D3D22696E74223F69734E614E284E756D626572286529293F537472696E672865293A4D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D555322293A74';
wwv_flow_imp.g_varchar2_table(40) := '3D3D3D22706374223F4B6528652C226E756D3A222B286E5B315D7C7C3229292B2225223A743D3D3D227570706572223F537472696E672865292E746F55707065724361736528293A743D3D3D226C6F776572223F537472696E672865292E746F4C6F7765';
wwv_flow_imp.g_varchar2_table(41) := '724361736528293A743D3D3D22796E223F653D3D3D2259227C7C653D3D3D2253223F2253C3AD223A653D3D3D224E223F224E6F223A537472696E672865293A743D3D3D226C6574726173223F69734E614E284E756D626572286529293F537472696E6728';
wwv_flow_imp.g_varchar2_table(42) := '65293A6369284E756D6265722865292C6E2E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E6374696F6E2044742865297B72657475726E2F5E2875707065727C6C6F7765727C796E7C6C657472617329283A7C24292F';
wwv_flow_imp.g_varchar2_table(43) := '2E7465737428657C7C2222297D7661722052743D7B7D3B66756E6374696F6E2065612865297B666F722876617220723D5B5D2C6E3D22222C743D21312C613D303B613C652E6C656E6774683B612B2B297B76617220693D652E6368617241742861293B69';
wwv_flow_imp.g_varchar2_table(44) := '6628693D3D3D225C5C2226262174297B6E2B3D692B28652E63686172417428612B31297C7C2222292C612B2B3B636F6E74696E75657D696628693D3D3D272227262628743D2174292C693D3D3D223B2226262174297B722E70757368286E292C6E3D2222';
wwv_flow_imp.g_varchar2_table(45) := '3B636F6E74696E75657D6E2B3D697D72657475726E20722E70757368286E292C727D66756E6374696F6E2072612865297B76617220723D5B5D2C6E3D6E756C6C2C743D21312C613D22222C693D21312C6F2C752C733D66756E6374696F6E28297B612626';
wwv_flow_imp.g_varchar2_table(46) := '28722E70757368287B743A226C222C763A617D292C613D2222297D3B666F72286F3D303B6F3C652E6C656E6774683B6F2B2B297B696628753D652E636861724174286F292C753D3D3D272227297B766172206C3D652E696E6465784F66282722272C6F2B';
wwv_flow_imp.g_varchar2_table(47) := '31293B6C3C302626286C3D652E6C656E677468292C612B3D652E736C696365286F2B312C6C292C6F3D6C3B636F6E74696E75657D696628753D3D3D225C5C22297B612B3D652E636861724174286F2B31292C6F2B2B3B636F6E74696E75657D696628753D';
wwv_flow_imp.g_varchar2_table(48) := '3D3D225B22297B76617220683D652E696E6465784F6628225D222C6F293B696628683E30297B7328292C722E70757368287B743A2278222C763A652E736C696365286F2C682B31297D292C6F3D683B636F6E74696E75657D7D696628753D3D3D225F2229';
wwv_flow_imp.g_varchar2_table(49) := '7B612B3D2220222C6F2B2B3B636F6E74696E75657D696628753D3D3D222A22297B6F2B2B3B636F6E74696E75657D696628217426262F5B23303F2C2E5D2F2E746573742875292626286E213D3D6E756C6C7C7C2F5B23303F5D2F2E746573742875297C7C';
wwv_flow_imp.g_varchar2_table(50) := '753D3D3D222E2226262F5B23303F5D2F2E7465737428652E636861724174286F2B31292929297B6E3D3D3D6E756C6C2626287328292C6E3D22222C722E70757368287B743A226E227D29292C6E2B3D753B636F6E74696E75657D6E213D3D6E756C6C2626';
wwv_flow_imp.g_varchar2_table(51) := '28743D2130292C753D3D3D222522262628693D2130292C612B3D757D7328292C6E3D6E7C7C22223B76617220673D6E2E6C617374496E6465784F6628222C22292C6D3D21313B673E3D3026262F5E5B23303F5D2B242F2E74657374286E2E736C69636528';
wwv_flow_imp.g_varchar2_table(52) := '672B3129292626286D3D6E2E696E6465784F6628222E22293E3D303F6E2E6C617374496E6465784F6628222E22293C673A6E2E6C656E6774682D672D31213D3D33292C6D2626286E3D6E2E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(53) := '76297B72657475726E20763D3D3D222E223F222C223A222E227D29293B76617220543D282F2C2B242F2E65786563286E297C7C5B22225D295B305D2E6C656E6774682C463D6E2E736C69636528302C6E2E6C656E6774682D54292C443D462E696E646578';
wwv_flow_imp.g_varchar2_table(54) := '4F6628222E22292C503D443C303F463A462E736C69636528302C44292C623D443C303F22223A462E736C69636528442B31292C70653D282F2C2B242F2E657865632850297C7C5B22225D295B305D2E6C656E6774682B543B72657475726E20503D502E73';
wwv_flow_imp.g_varchar2_table(55) := '6C69636528302C502E6C656E6774682D7065292C7B746F6B733A722C7261773A6E2C6861734E756D3A21216E2C7063743A692C7363616C653A4D6174682E706F77283165332C7065292C67726F75703A502E696E6465784F6628222C22293E3D302C6D69';
wwv_flow_imp.g_varchar2_table(56) := '6E496E743A28502E6D61746368282F302F67297C7C5B5D292E6C656E6774682C6D61784465633A28622E6D61746368282F5B23303F5D2F67297C7C5B5D292E6C656E6774682C6D696E4465633A28622E6D61746368282F302F67297C7C5B5D292E6C656E';
wwv_flow_imp.g_varchar2_table(57) := '6774682C6465633A6D3F222C223A222E222C6772703A6D3F222E223A222C227D7D66756E6374696F6E2066692865297B76617220723D5B5D2C6E3D22222C743D22222C612C693B666F7228613D303B613C652E6C656E6774683B612B2B297B696628693D';
wwv_flow_imp.g_varchar2_table(58) := '652E6368617241742861292C74297B693D3D3D743F743D22223A6E2B3D693B636F6E74696E75657D696628693D3D3D2227227C7C693D3D3D272227297B743D693B636F6E74696E75657D696628693D3D3D223B22297B722E70757368286E292C6E3D2222';
wwv_flow_imp.g_varchar2_table(59) := '3B636F6E74696E75657D6E2B3D697D722E70757368286E293B766172206F3D722E736869667428292E7472696D28292E746F55707065724361736528292C753D2F5E464D2F2E74657374286F292C733D7B6E6C733A222E2C222C6375723A2224222C6973';
wwv_flow_imp.g_varchar2_table(60) := '6F3A22555344227D3B722E666F72456163682866756E6374696F6E2877297B7661722068653D772E696E6465784F6628223D22293B68653E30262628735B772E736C69636528302C6865292E7472696D28292E746F4C6F7765724361736528295D3D772E';
wwv_flow_imp.g_varchar2_table(61) := '736C6963652868652B3129297D292C6F3D6F2E7265706C616365282F5E464D2F2C2222293B766172206C3D2F5052242F2E74657374286F292C683D216C26262F4D49242F2E74657374286F293B286C7C7C68292626286F3D6F2E736C69636528302C2D32';
wwv_flow_imp.g_varchar2_table(62) := '29293B76617220673D2F5E532F2E74657374286F292C6D3D21672626216C2626216826262F53242F2E74657374286F293B673F6F3D6F2E736C6963652831293A6D2626286F3D6F2E736C69636528302C2D3129293B76617220543D6F2E696E6465784F66';
wwv_flow_imp.g_varchar2_table(63) := '28224222293E3D302C463D22222C443D22222C503D22222C623D22222C70653D21312C763D21313B666F72286F3D6F2E7265706C616365282F422F672C2222292C613D303B613C6F2E6C656E6774683B612B2B29696628693D6F2E636861724174286129';
wwv_flow_imp.g_varchar2_table(64) := '2C693D3D3D2239227C7C693D3D3D22302229763D21302C70653F622B3D693D3D3D2239222626753F2223223A2230223A502B3D693B656C736520696628693D3D3D2247227C7C693D3D3D222C222970657C7C28502B3D222C22293B656C73652069662869';
wwv_flow_imp.g_varchar2_table(65) := '3D3D3D2244227C7C693D3D3D222E222970653D21303B656C736520696628693D3D3D224C227C7C693D3D3D2255227C7C693D3D3D2243227C7C693D3D3D222422297B76617220413D693D3D3D2243223F732E69736F3A693D3D3D2224223F2224223A732E';
wwv_flow_imp.g_varchar2_table(66) := '6375723B763F442B3D413A462B3D417D76617220793D502E696E6465784F6628223022293B503D502E7265706C616365282F5B39305D2F672C66756E6374696F6E28772C6865297B72657475726E20793E3D30262668653E3D793F2230223A2223227D29';
wwv_flow_imp.g_varchar2_table(67) := '2E7265706C616365282F5E2C2B2F2C2222293B766172204D3D502B28623F222E222B623A2222297C7C2223222C493D66756E6374696F6E2877297B72657475726E20773F2722272B537472696E672877292E7265706C616365282F222F672C2222292B27';
wwv_flow_imp.g_varchar2_table(68) := '22273A22227D2C5F3D492846292B4D2B492844292C66653D5F3B6C3F66653D5F2B223B222B4928223C222B46292B4D2B4928442B223E22293A683F66653D5F2B223B222B492846292B4D2B4928442B222D22293A673F66653D4928222B222B46292B4D2B';
wwv_flow_imp.g_varchar2_table(69) := '492844292B223B222B4928222D222B46292B4D2B492844293A6D26262866653D492846292B4D2B4928442B222B22292B223B222B492846292B4D2B4928442B222D2229292C5426262866653D3D3D5F26262866652B3D223B222B4928222D222B46292B4D';
wwv_flow_imp.g_varchar2_table(70) := '2B49284429292C66652B3D273B222227293B76617220423D537472696E6728732E6E6C737C7C222E2C22293B72657475726E7B7372633A66652C6465633A422E6368617241742830297C7C222E222C6772703A422E6368617241742831297C7C222C227D';
wwv_flow_imp.g_varchar2_table(71) := '7D66756E6374696F6E2074612865297B696628653D537472696E672865292C2152745B655D296966282F5E6F72613A2F2E74657374286529297B76617220723D666928652E736C696365283429293B52745B655D3D656128722E737263292E6D61702866';
wwv_flow_imp.g_varchar2_table(72) := '756E6374696F6E286E297B76617220743D7261286E293B72657475726E20742E6465633D722E6465632C742E6772703D722E6772702C747D297D656C73652052745B655D3D6561287069286529292E6D6170287261293B72657475726E2052745B655D7D';
wwv_flow_imp.g_varchar2_table(73) := '66756E6374696F6E20736928652C72297B766172206E3D4E756D6265722865293B696628653D3D6E756C6C7C7C653D3D3D22227C7C69734E614E286E292972657475726E20653D3D6E756C6C3F22223A537472696E672865293B76617220743D74612872';
wwv_flow_imp.g_varchar2_table(74) := '292C613D745B305D2C693D21313B6E3C302626742E6C656E6774683E312626745B315D2E746F6B732E6C656E6774683F28613D745B315D2C6E3D2D6E293A6E3C30262628693D21302C6E3D2D6E292C6E3D3D3D302626742E6C656E6774683E3226262861';
wwv_flow_imp.g_varchar2_table(75) := '3D745B325D2C693D2131292C612E7063742626286E3D6E2A313030292C6E3D6E2F612E7363616C653B766172206F3D4E756D626572286E2E746F466978656428612E6D617844656329293B6F3D3D3D30262628693D2131293B76617220753D6F2E746F4C';
wwv_flow_imp.g_varchar2_table(76) := '6F63616C65537472696E672822656E2D5553222C7B75736547726F7570696E673A612E67726F75702C6D696E696D756D496E74656765724469676974733A4D6174682E6D617828312C4D6174682E6D696E2832312C612E6D696E496E7429292C6D696E69';
wwv_flow_imp.g_varchar2_table(77) := '6D756D4672616374696F6E4469676974733A612E6D696E4465632C6D6178696D756D4672616374696F6E4469676974733A612E6D61784465637D293B21612E6D696E496E7426262F5E30285C2E7C24292F2E74657374287529262628753D752E736C6963';
wwv_flow_imp.g_varchar2_table(78) := '65283129292C28612E646563213D3D222E227C7C612E677270213D3D222C2229262628753D752E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E286C297B72657475726E206C3D3D3D222E223F612E6465633A612E6772707D29293B766172';
wwv_flow_imp.g_varchar2_table(79) := '20733D612E746F6B732E6D61702866756E6374696F6E286C297B72657475726E206C2E743D3D3D226E223F753A6C2E743D3D3D2278223F22223A6C2E767D292E6A6F696E282222293B72657475726E20693F222D222B733A737D66756E6374696F6E2070';
wwv_flow_imp.g_varchar2_table(80) := '6E2865297B72657475726E2074612865292E6D61702866756E6374696F6E2872297B72657475726E20722E746F6B732E6D61702866756E6374696F6E286E297B72657475726E206E2E743D3D3D226E223F722E7261773A6E2E743D3D3D2278223F6E2E76';
wwv_flow_imp.g_varchar2_table(81) := '3A6E2E762E73706C697428222522292E6D61702866756E6374696F6E2874297B72657475726E20743F2722272B742E7265706C616365282F222F672C2222292B2722273A22227D292E6A6F696E28222522297D292E6A6F696E282222297C7C272222277D';
wwv_flow_imp.g_varchar2_table(82) := '292E6A6F696E28223B22297D7661722064693D2F5E286D6F6E65797C6E756D7C696E747C7063747C646174657C75707065727C6C6F7765727C796E7C6C657472617329283A7C24292F3B66756E6374696F6E2048722865297B72657475726E20653D657C';
wwv_flow_imp.g_varchar2_table(83) := '7C22222C2F5E286D61736B7C6F7261293A2F2E746573742865297C7C2164692E7465737428652926262F5B23305D2F2E746573742865297D66756E6374696F6E2070692865297B72657475726E20653D537472696E672865292C2F5E6D61736B3A2F2E74';
wwv_flow_imp.g_varchar2_table(84) := '6573742865293F652E736C6963652835293A657D66756E6374696F6E2068692865297B72657475726E2048722865293F706E2865293A653D3D3D22696E74223F22232C232330223A653D3D3D226D6F6E6579227C7C2F5E6E756D2F2E7465737428657C7C';
wwv_flow_imp.g_varchar2_table(85) := '2222293F22232C2323302E222B6E6577204172726179282828657C7C2222292E73706C697428223A22295B315D7C7C32292A312B31292E6A6F696E28223022293A2247656E6572616C227D766172206E613D5B22222C22554E222C22444F53222C225452';
wwv_flow_imp.g_varchar2_table(86) := '4553222C2243554154524F222C2243494E434F222C2253454953222C225349455445222C224F43484F222C224E55455645222C224449455A222C224F4E4345222C22444F4345222C225452454345222C224341544F524345222C225155494E4345222C22';
wwv_flow_imp.g_varchar2_table(87) := '444945434953C3894953222C2244494543495349455445222C2244494543494F43484F222C2244494543494E55455645222C225645494E5445222C225645494E5449C39A4E222C225645494E544944C39353222C225645494E54495452C38953222C2256';
wwv_flow_imp.g_varchar2_table(88) := '45494E544943554154524F222C225645494E544943494E434F222C225645494E544953C3894953222C225645494E54495349455445222C225645494E54494F43484F222C225645494E54494E55455645225D2C67693D5B22222C22222C22222C22545245';
wwv_flow_imp.g_varchar2_table(89) := '494E5441222C2243554152454E5441222C2243494E4355454E5441222C22534553454E5441222C22534554454E5441222C224F4348454E5441222C224E4F56454E5441225D2C6D693D5B22222C224349454E544F222C22444F534349454E544F53222C22';
wwv_flow_imp.g_varchar2_table(90) := '545245534349454E544F53222C2243554154524F4349454E544F53222C225155494E49454E544F53222C22534549534349454E544F53222C22534554454349454E544F53222C224F43484F4349454E544F53222C224E4F56454349454E544F53225D3B66';
wwv_flow_imp.g_varchar2_table(91) := '756E6374696F6E2061612865297B696628653D3D3D3130302972657475726E224349454E223B76617220723D4D6174682E666C6F6F7228652F313030292C6E3D65253130302C743D5B5D3B72657475726E20722626742E70757368286D695B725D292C6E';
wwv_flow_imp.g_varchar2_table(92) := '2626742E70757368286E3C33303F6E615B6E5D3A67695B4D6174682E666C6F6F72286E2F3130295D2B286E2531303F22205920222B6E615B6E2531305D3A222229292C742E6A6F696E28222022297D66756E6374696F6E2069612865297B696628653D3D';
wwv_flow_imp.g_varchar2_table(93) := '3D302972657475726E224345524F223B76617220723D5B5D2C6E3D5B5B316531322C2242494C4CC3934E222C2242494C4C4F4E4553225D2C5B3165362C224D494C4CC3934E222C224D494C4C4F4E4553225D5D3B6E2E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(94) := '6F6E2869297B766172206F3D4D6174682E666C6F6F7228652F695B305D293B6F262628722E70757368286F3D3D3D313F22554E20222B695B315D3A6961286F292B2220222B695B325D292C652D3D6F2A695B305D297D293B76617220743D4D6174682E66';
wwv_flow_imp.g_varchar2_table(95) := '6C6F6F7228652F316533292C613D65253165333B72657475726E20742626722E7075736828743D3D3D313F224D494C223A61612874292B22204D494C22292C612626722E70757368286161286129292C722E6A6F696E28222022297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(96) := '20636928652C72297B766172206E3D653C302C743D4D6174682E726F756E64284D6174682E6162732865292A313030292C613D4D6174682E666C6F6F7228742F313030292C693D74253130302C6F3D69612861293B6966282172296F3D6F2E7265706C61';
wwv_flow_imp.g_varchar2_table(97) := '6365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E2873297B72657475726E20732B224F227D293B656C73657B2F284D494C4CC3934E7C4D494C4C4F4E45537C42494C4CC3934E7C42494C4C';
wwv_flow_imp.g_varchar2_table(98) := '4F4E455329242F2E74657374286F292626286F2B3D2220444522293B76617220753D537472696E672872292E746F55707065724361736528292E73706C697428222F22293B6F2B3D2220222B28613D3D3D312626752E6C656E6774683E313F755B305D3A';
wwv_flow_imp.g_varchar2_table(99) := '755B752E6C656E6774682D315D297D72657475726E286E3F224D454E4F5320223A2222292B6F2B2220434F4E20222B28693C31303F2230223A2222292B692B222F313030227D66756E6374696F6E2076692865297B7472797B72657475726E2077696E64';
wwv_flow_imp.g_varchar2_table(100) := '6F772E617065782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D63617463682872297B72657475726E22227D7D66756E6374696F6E20577228652C722C6E297B76617220743D537472696E672872292E';
wwv_flow_imp.g_varchar2_table(101) := '746F55707065724361736528292C613D742E696E6465784F6628222E22293B696628613E30297B76617220693D742E73756273747228302C61292C6F3D742E73756273747228612B31293B696628693D3D3D22444F43222972657475726E20652E646F63';
wwv_flow_imp.g_varchar2_table(102) := '3F652E646F635B6F5D3A766F696420303B696628693D3D3D22504152414D222972657475726E20652E706172616D733F652E706172616D735B6F5D3A766F696420303B696628693D3D3D224954454D222972657475726E207669286F293B76617220753D';
wwv_flow_imp.g_varchar2_table(103) := '28652E535B695D7C7C5B5D295B305D3B72657475726E20753F755B6F5D3A766F696420307D72657475726E20743D3D3D224E4F57223F736E28293A743D3D3D22544F444159223F4A6E28293A743D3D3D2250414745227C7C743D3D3D225041474553227C';
wwv_flow_imp.g_varchar2_table(104) := '7C743D3D3D22444F4350414745227C7C743D3D3D22444F435041474553223F227B222B742B227D223A6E26264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C286E2C74293F6E5B745D3A652E646F6326264F62';
wwv_flow_imp.g_varchar2_table(105) := '6A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C74293F652E646F635B745D3A652E706172616D733F652E706172616D735B745D3A766F696420307D66756E6374696F6E205628652C722C6E297B72';
wwv_flow_imp.g_varchar2_table(106) := '657475726E20653D3D6E756C6C3F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C28283F3A6D61736B7C6F7261293A5B5E7D5D2B7C5B412D5A612D7A302D393A2FC381C389C38DC3';
wwv_flow_imp.g_varchar2_table(107) := '93C39AC391C39CC3A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B7C5B5E7D5D2A5B23305D5B5E7D5D2A29293F5C7D2F672C66756E6374696F6E28742C612C69297B766172206F3D577228722C612C6E293B72657475726E206F3D3D6E756C6C3F22223A4B65286F';
wwv_flow_imp.g_varchar2_table(108) := '2C69297D297D66756E6374696F6E2062692865297B696628653D652E7472696D28292C2F5E272E2A27242F2E746573742865297C7C2F5E222E2A22242F2E746573742865292972657475726E20652E736C69636528312C2D31293B696628653D3D3D226E';
wwv_flow_imp.g_varchar2_table(109) := '756C6C222972657475726E206E756C6C3B69662865213D3D222226262169734E614E284E756D626572286529292972657475726E204E756D6265722865297D66756E6374696F6E20776928652C722C6E297B76617220743D2F5E5C732A28213F295C732A';
wwv_flow_imp.g_varchar2_table(110) := '285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E657865632865293B69662821742972657475726E21313B76617220613D577228722C745B325D2C6E293B69662821745B335D29';
wwv_flow_imp.g_varchar2_table(111) := '7B76617220693D2128613D3D6E756C6C7C7C613D3D3D22227C7C613D3D3D307C7C613D3D3D224E22293B72657475726E20745B315D3F21693A697D766172206F3D626928745B345D293B6F3D3D3D766F696420302626286F3D577228722C745B345D2E74';
wwv_flow_imp.g_varchar2_table(112) := '72696D28292C6E29293B76617220753D613D3D6E756C6C7C7C613D3D3D22223F6F3D3D3D6E756C6C7C7C6F3D3D3D22223A537472696E672861293D3D3D537472696E67286F293B73776974636828745B335D297B63617365223D3D223A72657475726E20';
wwv_flow_imp.g_varchar2_table(113) := '753B6361736522213D223A72657475726E21753B63617365223E223A72657475726E204E756D6265722861293E4E756D626572286F293B63617365223C223A72657475726E204E756D6265722861293C4E756D626572286F293B63617365223E3D223A72';
wwv_flow_imp.g_varchar2_table(114) := '657475726E204E756D6265722861293E3D4E756D626572286F293B63617365223C3D223A72657475726E204E756D6265722861293C3D4E756D626572286F297D72657475726E21317D66756E6374696F6E20657228652C722C6E297B72657475726E2065';
wwv_flow_imp.g_varchar2_table(115) := '3D3D6E756C6C7C7C653D3D3D22223F21303A747970656F6620653D3D2266756E6374696F6E223F212165286E2C72293A537472696E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2874297B72657475726E20742E73706C69';
wwv_flow_imp.g_varchar2_table(116) := '742822262622292E65766572792866756E6374696F6E2861297B72657475726E20776928612C722C6E297D297D297D66756E6374696F6E204F6528652C72297B696628652E5F726F77732972657475726E20652E5F726F77733B766172206E3D722E535B';
wwv_flow_imp.g_varchar2_table(117) := '537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F6E2E66696C7465722866756E6374696F6E2874297B72657475726E20657228652E66696C7465722C722C7429';
wwv_flow_imp.g_varchar2_table(118) := '7D293A6E7D66756E6374696F6E20707428652C722C6E297B69662821652972657475726E206E756C6C3B696628747970656F6620653D3D22737472696E67222972657475726E20653B76617220743D577228722C652E62792C6E293B72657475726E2065';
wwv_flow_imp.g_varchar2_table(119) := '2E76616C7565732626652E76616C7565735B745D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E206E7428652C722C6E297B76617220743D6E756C6C3B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2861297B72';
wwv_flow_imp.g_varchar2_table(120) := '657475726E20657228612E7768656E2C722C6E293F28743D612C2130293A21317D292C747D7661722068743D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D2C617269616C3A5B2268656C766574696361222C22417269';
wwv_flow_imp.g_varchar2_table(121) := '616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75726965723A5B22636F7572696572222C22436F7572696572';
wwv_flow_imp.g_varchar2_table(122) := '204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E206C612865297B696628653D537472696E6728653D3D6E756C6C3F22223A65292E7472696D28292C21652972657475726E206E756C';
wwv_flow_imp.g_varchar2_table(123) := '6C3B6966282F5E7777775C2E2F692E74657374286529262628653D2268747470733A2F2F222B65292C2F5E2868747470733F3A7C6D61696C746F3A7C74656C3A7C6674703A292F692E746573742865292972657475726E20652E7265706C616365282F20';
wwv_flow_imp.g_varchar2_table(124) := '2F672C2225323022293B6966282F5E5B412D5A612D7A5D5B412D5A612D7A302D392B2E2D5D2A3A2F2E746573742865292972657475726E206E756C6C3B7472797B69662877696E646F772E6C6F636174696F6E26262F5E68747470733F3A2F2E74657374';
wwv_flow_imp.g_varchar2_table(125) := '2877696E646F772E6C6F636174696F6E2E68726566292972657475726E206E65772055524C28652C77696E646F772E6C6F636174696F6E2E68726566292E687265667D63617463682872297B7D72657475726E206E756C6C7D66756E6374696F6E206D72';
wwv_flow_imp.g_varchar2_table(126) := '28652C722C6E297B72657475726E20652626652E687265663F6C61285628652E687265662C722C6E29293A6E756C6C7D66756E6374696F6E206F6128652C722C6E2C74297B6966286E297B652E6C696E6B28722E782C722E792C722E77696474682C722E';
wwv_flow_imp.g_varchar2_table(127) := '6865696768742C7B75726C3A6E7D293B76617220613D41727261792E6973417272617928722E74657874293F722E746578743A5B722E746578745D3B6966282128743D3D3D21317C7C21612E6A6F696E2822222929297B76617220693D652E696E746572';
wwv_flow_imp.g_varchar2_table(128) := '6E616C2E676574466F6E7453697A6528292F652E696E7465726E616C2E7363616C65466163746F722C6F3D692A28652E6765744C696E65486569676874466163746F723F652E6765744C696E65486569676874466163746F7228293A312E3135292C753D';
wwv_flow_imp.g_varchar2_table(129) := '722E67657454657874506F7328292C733D722E7374796C65732E76616C69676E2C6C3D722E7374796C65732E68616C69676E2C683D752E792B692A28322D312E3135293B733D3D3D226D6964646C65223F682D3D612E6C656E6774682F322A6F3A733D3D';
wwv_flow_imp.g_varchar2_table(130) := '3D22626F74746F6D22262628682D3D612E6C656E6774682A6F293B76617220673D722E7374796C65732E74657874436F6C6F723B69662841727261792E6973417272617928672929652E73657444726177436F6C6F7228675B305D2C675B315D2C675B32';
wwv_flow_imp.g_varchar2_table(131) := '5D293B656C736520696628747970656F6620673D3D22737472696E672226262F5E232F2E74657374286729297B766172206D3D242867293B652E73657444726177436F6C6F72286D5B305D2C6D5B315D2C6D5B325D297D656C736520652E736574447261';
wwv_flow_imp.g_varchar2_table(132) := '77436F6C6F7228677C7C30293B652E7365744C696E65576964746828692A2E303335292C612E666F72456163682866756E6374696F6E28542C46297B76617220443D652E676574537472696E67556E6974576964746828537472696E67285429292A692C';
wwv_flow_imp.g_varchar2_table(133) := '503D6C3D3D3D227269676874223F752E782D443A6C3D3D3D2263656E746572223F752E782D442F323A752E782C623D682B462A6F2B692A2E31373B443E302626652E6C696E6528502C622C502B442C62297D297D7D7D66756E6374696F6E207561286529';
wwv_flow_imp.g_varchar2_table(134) := '7B72657475726E20653D537472696E6728657C7C2268656C76657469636122292E746F4C6F7765724361736528292C68745B655D3F653A2268656C766574696361227D66756E6374696F6E20686E28652C72297B723D727C7C7B7D3B766172206E3D5B5D';
wwv_flow_imp.g_varchar2_table(135) := '2C743D7B623A21312C693A21312C753A21312C733A21317D2C613D5B722E666F6E747C7C2268656C766574696361225D2C693D5B722E636F6C6F727C7C6E756C6C5D2C6F3D5B5D2C753D22222C733D302C6C3B653D537472696E6728653D3D6E756C6C3F';
wwv_flow_imp.g_varchar2_table(136) := '22223A65293B66756E6374696F6E206828297B69662875297B766172206D3D6F5B6F2E6C656E6774682D315D2C543D695B692E6C656E6774682D315D3B6D26266D2E75726C2626692E6C656E6774683C3D6D2E6364262628543D722E6C696E6B7C7C666E';
wwv_flow_imp.g_varchar2_table(137) := '2E6C696E6B292C6E2E70757368287B743A752C623A742E622C693A742E692C753A742E757C7C2121286D26266D2E75726C292C733A742E732C663A756128615B612E6C656E6774682D315D292C633A542C683A6D3F6D2E75726C3A6E756C6C7D292C753D';
wwv_flow_imp.g_varchar2_table(138) := '22227D7D666F72283B733C652E6C656E6774683B297B76617220673D652E7375627374722873293B696628672E6368617241742830293D3D3D225C5C222626672E6C656E6774683E31297B752B3D672E6368617241742831292C732B3D323B636F6E7469';
wwv_flow_imp.g_varchar2_table(139) := '6E75657D6966286C3D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286729297B6828292C612E70757368286C5B315D292C732B3D6C5B305D2E6C656E6774683B636F6E74696E75657D696628672E73756273747228302C34293D3D3D22';
wwv_flow_imp.g_varchar2_table(140) := '5B2F665D22297B6828292C612E6C656E6774683E312626612E706F7028292C732B3D343B636F6E74696E75657D6966286C3D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286729297B6828292C692E70757368286C';
wwv_flow_imp.g_varchar2_table(141) := '5B315D292C732B3D6C5B305D2E6C656E6774683B636F6E74696E75657D696628672E73756273747228302C34293D3D3D225B2F635D22297B6828292C692E6C656E6774683E312626692E706F7028292C732B3D343B636F6E74696E75657D6966286C3D2F';
wwv_flow_imp.g_varchar2_table(142) := '5E5C5B613D285B5E5C5D5C735D2A295C5D2F2E65786563286729297B6828292C6F2E70757368287B75726C3A6C61286C5B315D292C63643A692E6C656E6774687D292C732B3D6C5B305D2E6C656E6774683B636F6E74696E75657D696628672E73756273';
wwv_flow_imp.g_varchar2_table(143) := '747228302C34293D3D3D225B2F615D22297B6828292C6F2E706F7028292C732B3D343B636F6E74696E75657D696628672E73756273747228302C33293D3D3D222A2A2A22297B6828292C742E623D21742E622C742E693D21742E692C732B3D333B636F6E';
wwv_flow_imp.g_varchar2_table(144) := '74696E75657D696628672E73756273747228302C32293D3D3D222A2A22297B6828292C742E623D21742E622C732B3D323B636F6E74696E75657D696628672E73756273747228302C32293D3D3D227E7E22297B6828292C742E733D21742E732C732B3D32';
wwv_flow_imp.g_varchar2_table(145) := '3B636F6E74696E75657D696628672E73756273747228302C32293D3D3D222B2B22297B6828292C742E753D21742E752C732B3D323B636F6E74696E75657D696628672E6368617241742830293D3D3D222A22297B6828292C742E693D21742E692C732B3D';
wwv_flow_imp.g_varchar2_table(146) := '313B636F6E74696E75657D752B3D672E6368617241742830292C732B2B7D72657475726E206828292C6E7D66756E6374696F6E20676E28652C72297B766172206E3D652E736F757263653F4F6528652C72295B305D3A6E756C6C2C743D41727261792E69';
wwv_flow_imp.g_varchar2_table(147) := '73417272617928652E74657874293F652E746578743A537472696E6728652E746578743D3D3D766F696420303F22223A652E74657874292E73706C697428225C6E22293B72657475726E20742E6D61702866756E6374696F6E2861297B72657475726E20';
wwv_flow_imp.g_varchar2_table(148) := '5628612C722C6E297D297D66756E6374696F6E20436C2865297B72657475726E20652E6D61702866756E6374696F6E2872297B72657475726E20722E747D292E6A6F696E282222297D66756E6374696F6E20677428652C722C6E297B76617220743D5374';
wwv_flow_imp.g_varchar2_table(149) := '72696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D652E5F74797065737C7C722E545B745D7C7C7B7D2C693D652E636F6C756D6E733B72657475726E2821697C7C21692E6C656E67746829262628693D4F626A656374';
wwv_flow_imp.g_varchar2_table(150) := '2E6B6579732861292E66696C7465722866756E6374696F6E286F297B72657475726E206F213D3D22444F435F4B4559227D292E6D61702866756E6374696F6E286F297B72657475726E7B636F6C3A6F7D7D29292C693D692E66696C7465722866756E6374';
wwv_flow_imp.g_varchar2_table(151) := '696F6E286F297B72657475726E20747970656F66206F3D3D22737472696E67227C7C216F2E7768656E7C7C6572286F2E7768656E2C722C6E756C6C297D292C692E6D61702866756E6374696F6E286F297B6F3D747970656F66206F3D3D22737472696E67';
wwv_flow_imp.g_varchar2_table(152) := '223F7B636F6C3A6F7D3A6F3B76617220753D6F2E636F6C3F537472696E67286F2E636F6C292E746F55707065724361736528293A6E756C6C2C733D753F615B755D3A6E756C6C2C6C3D6F2E666D743B216C2626733D3D3D224E554D424552222626216F2E';
wwv_flow_imp.g_varchar2_table(153) := '76616C75652626286C3D6E2E736F6D652866756E6374696F6E2867297B72657475726E204F7428675B755D2926264D6174682E726F756E6428675B755D29213D3D675B755D7D293F226D6F6E6579223A6E756C6C293B76617220683D6F2E63656C6C2626';
wwv_flow_imp.g_varchar2_table(154) := '79695B6F2E63656C6C2E747970655D3F6F2E63656C6C3A6E756C6C3B72657475726E7B636F6C3A752C76616C75653A6F2E76616C7565213D3D766F696420303F6F2E76616C75653A6F2E63656C6C26266F2E63656C6C2E747970653D3D3D22746578746F';
wwv_flow_imp.g_varchar2_table(155) := '223F6F2E63656C6C2E746578743A766F696420302C6C6162656C3A6F2E6C6162656C213D3D766F696420303F6F2E6C6162656C3A516E28757C7C2222292C63656C6C3A682C76616C69676E3A2F5E28746F707C6D6964646C657C626F74746F6D29242F2E';
wwv_flow_imp.g_varchar2_table(156) := '7465737428537472696E67286F2E76616C69676E7C7C2222292E746F4C6F776572436173652829293F537472696E67286F2E76616C69676E292E746F4C6F7765724361736528293A6E756C6C2C666D743A6C2C6D61703A6F2E6D61702C626F6C643A2121';
wwv_flow_imp.g_varchar2_table(157) := '6F2E626F6C642C77696474683A6F2E77696474682C616C69676E3A6F2E616C69676E7C7C28683F2263656E746572223A6E756C6C297C7C284474286C293F226C656674223A733D3D3D224E554D424552227C7C6C3D3D3D226D6F6E6579227C7C6C3D3D3D';
wwv_flow_imp.g_varchar2_table(158) := '22696E74227C7C6C3D3D3D226E756D227C7C4872286C293F227269676874223A733D3D3D2244415445227C7C6C3D3D3D2264617465223F2263656E746572223A226C65667422292C63656C6C5374796C653A6F2E63656C6C5374796C652C636F6C6F723A';
wwv_flow_imp.g_varchar2_table(159) := '6F2E636F6C6F722C68656164416C69676E3A6F2E68656164416C69676E2C687265663A6F2E687265667C7C6F2E63656C6C26266F2E63656C6C2E687265667C7C6E756C6C2C69734E756D3A21682626214474286C29262628733D3D3D224E554D42455222';
wwv_flow_imp.g_varchar2_table(160) := '2626216F2E6D61702626216F2E76616C75657C7C6C3D3D3D226D6F6E6579227C7C6C3D3D3D22696E74227C7C2F5E6E756D2F2E74657374286C7C7C2222297C7C4872286C29297D7D297D66756E6374696F6E206A7428652C72297B766172206E3D5B5D2C';
wwv_flow_imp.g_varchar2_table(161) := '743D303B72657475726E28652E67726F7570737C7C5B5D292E666F72456163682866756E6374696F6E2861297B76617220693D4D6174682E6D617828312C4D6174682E6D696E28612E636F6C737C7C312C722E6C656E6774682D7429293B743C722E6C65';
wwv_flow_imp.g_varchar2_table(162) := '6E6774682626286E2E70757368287B6C6162656C3A612E6C6162656C7C7C22222C636F6C733A692C66726F6D3A742C6761703A21612E6C6162656C7D292C742B3D69297D292C743C722E6C656E67746826266E2E70757368287B6C6162656C3A22222C63';
wwv_flow_imp.g_varchar2_table(163) := '6F6C733A722E6C656E6774682D742C66726F6D3A742C6761703A21307D292C6E7D66756E6374696F6E20666128652C722C6E297B696628652E76616C7565213D3D766F696420302972657475726E205628652E76616C75652C6E2C72293B76617220743D';
wwv_flow_imp.g_varchar2_table(164) := '725B652E636F6C5D3B72657475726E20652E6D6170262674213D3D6E756C6C262674213D3D766F696420302626652E6D61705B745D213D3D766F696420303F652E6D61705B745D3A747D66756E6374696F6E206D6E28652C722C6E297B76617220743D66';
wwv_flow_imp.g_varchar2_table(165) := '6128652C722C6E293B72657475726E20652E6D61702626652E6D61705B725B652E636F6C5D5D213D3D766F696420303F537472696E672874293A4B6528742C652E666D74297D7661722079693D7B636F6469676F3A312C696D6167656E3A312C67726166';
wwv_flow_imp.g_varchar2_table(166) := '69636F3A317D3B66756E6374696F6E2069722865297B76617220723D7B7D2C6E3B666F72286E20696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C6E29262628725B6E5D3D655B6E5D293B72';
wwv_flow_imp.g_varchar2_table(167) := '657475726E20727D66756E6374696F6E20456928652C722C6E297B76617220743D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D652E6C696E6B7C7C7B7D2C693D652E66696C7465723F5628652E66696C74';
wwv_flow_imp.g_varchar2_table(168) := '65722C722C6E293A6E756C6C2C6F3D28722E535B745D7C7C5B5D292E66696C7465722866756E6374696F6E2873297B666F7228766172206C20696E2061296966284F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C';
wwv_flow_imp.g_varchar2_table(169) := '6C28612C6C292626537472696E6728735B6C2E746F55707065724361736528295D29213D3D537472696E67286E5B537472696E6728615B6C5D292E746F55707065724361736528295D292972657475726E21313B72657475726E21697C7C657228692C72';
wwv_flow_imp.g_varchar2_table(170) := '2C73297D292C753D69722872293B72657475726E20752E533D697228722E53292C752E535B745D3D6F2C757D66756E6374696F6E20636E28652C72297B766172206E3D537472696E6728652E76616C69676E7C7C2222292E746F4C6F7765724361736528';
wwv_flow_imp.g_varchar2_table(171) := '293B72657475726E206E3D3D3D22746F70227C7C6E3D3D3D226D6964646C65227C7C6E3D3D3D22626F74746F6D223F6E3A722E736F6D652866756E6374696F6E2874297B72657475726E20742E63656C6C7D293F226D6964646C65223A6E756C6C7D6675';
wwv_flow_imp.g_varchar2_table(172) := '6E6374696F6E20766E28652C722C6E2C74297B76617220613D652E63656C6C3B69662821612972657475726E206E756C6C3B696628612E747970653D3D3D22636F6469676F22297B76617220693D69722861293B692E73697A657C7C28692E73697A653D';
wwv_flow_imp.g_varchar2_table(173) := '3134292C692E77696474687C7C28692E77696474683D3330292C692E6865696768747C7C28692E6865696768743D38293B766172206F3D4A7428692C6E2C72293B696628216F2972657475726E206E756C6C3B76617220753D5F6E286F293B7265747572';
wwv_flow_imp.g_varchar2_table(174) := '6E7B696D3A752C773A752E776D6D2C683A752E686D6D7D7D696628612E747970653D3D3D22696D6167656E22297B76617220733D612E6669656C643F725B537472696E6728612E6669656C64292E746F55707065724361736528295D3A6E756C6C2C6C3D';
wwv_flow_imp.g_varchar2_table(175) := '6E756C6C3B7472797B6C3D733F78612873293A612E75726C262621612E6669656C643F4D725B2472285628612E75726C2C6E2C7229295D3A6E756C6C7D63617463682854297B77696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E2822';
wwv_flow_imp.g_varchar2_table(176) := '6E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B612E6669656C642C54297D696628216C2972657475726E206E756C6C3B76617220683D5374287B77696474683A612E77696474687C7C28612E6865696768743F766F';
wwv_flow_imp.g_varchar2_table(177) := '696420303A3135292C6865696768743A612E6865696768747D2C6C293B72657475726E7B696D3A6C2C773A682E772C683A682E687D7D76617220673D69722861293B64656C65746520672E66696C7465722C64656C65746520672E6C696E6B2C672E7769';
wwv_flow_imp.g_varchar2_table(178) := '6474687C7C28672E77696474683D3430292C672E6865696768747C7C28672E6865696768743D3135293B766172206D3D517428672C456928612C6E2C72292C74293B72657475726E206D3F7B696D3A6D2C773A6D2E776D6D2C683A6D2E686D6D7D3A6E75';
wwv_flow_imp.g_varchar2_table(179) := '6C6C7D76617220626E3D7B666F726D756C6172696F3A312C66696368613A312C7461726A657461733A317D3B66756E6374696F6E206B742865297B76617220723D5B5D3B72657475726E28657C7C5B5D292E666F72456163682866756E6374696F6E286E';
wwv_flow_imp.g_varchar2_table(180) := '297B696628216E7C7C21626E5B6E2E747970655D7C7C21286E2E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E286F297B72657475726E206F26266F2E626C6F636B7D29297B722E70757368286E293B72657475726E7D76617220743D6E';
wwv_flow_imp.g_varchar2_table(181) := '756C6C2C613D302C693D66756E6374696F6E28297B742626742E6669656C64732E6C656E6774682626722E707573682874292C743D6E756C6C7D3B6E2E6669656C64732E666F72456163682866756E6374696F6E286F297B6966286F26266F2E626C6F63';
wwv_flow_imp.g_varchar2_table(182) := '6B297B76617220753D6F2E626C6F636B3B69662821757C7C21446E5B752E747970655D7C7C752E747970653D3D3D22666F726D756C6172696F222972657475726E3B6928292C753D69722875292C21752E736F7572636526266E2E736F75726365262675';
wwv_flow_imp.g_varchar2_table(183) := '2E74797065213D3D226C696E6561222626752E74797065213D3D226573706163696F22262628752E736F757263653D6E2E736F75726365292C6F2E7768656E262621752E7768656E262628752E7768656E3D6F2E7768656E292C216126266E2E7469746C';
wwv_flow_imp.g_varchar2_table(184) := '652626752E747970653D3D3D227461626C6122262621752E7469746C65262628752E7469746C653D6E2E7469746C65292C722E707573682875292C612B2B3B72657475726E7D747C7C28743D6972286E292C742E6669656C64733D5B5D2C61262664656C';
wwv_flow_imp.g_varchar2_table(185) := '65746520742E7469746C652C612B2B292C742E6669656C64732E70757368286F297D292C6928297D292C727D7661722073613D7B73756D3A392C6176673A312C6D696E3A352C6D61783A342C636F756E743A337D2C53693D7B73756D3A2253554D222C61';
wwv_flow_imp.g_varchar2_table(186) := '76673A2241564552414745222C6D696E3A224D494E222C6D61783A224D4158222C636F756E743A22434F554E5441227D2C49743D7B6176673A2250726F6D2E222C6D696E3A224DC3AD6E2E222C6D61783A224DC3A1782E222C636F756E743A2243616E74';
wwv_flow_imp.g_varchar2_table(187) := '2E227D3B66756E6374696F6E2061742865297B72657475726E2841727261792E697341727261792865293F653A5B5D292E6D61702866756E6374696F6E2872297B766172206E3D722626747970656F6620723D3D226F626A656374223F723A7B636F6C3A';
wwv_flow_imp.g_varchar2_table(188) := '727D2C743D537472696E67286E2E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475726E7B636F6C3A537472696E67286E2E636F6C7C7C2222292E746F55707065724361736528292C666E3A73615B745D3F743A2273756D227D7D';
wwv_flow_imp.g_varchar2_table(189) := '292E66696C7465722866756E6374696F6E2872297B72657475726E20722E636F6C7D297D66756E6374696F6E20776E28652C72297B666F7228766172206E3D303B6E3C652E6C656E6774683B6E2B2B29696628655B6E5D2E636F6C3D3D3D722972657475';
wwv_flow_imp.g_varchar2_table(190) := '726E20655B6E5D3B72657475726E206E756C6C7D66756E6374696F6E2064612865297B72657475726E20652E736F6D652866756E6374696F6E2872297B72657475726E20722E666E213D3D2273756D227D297D66756E6374696F6E2056722865297B7265';
wwv_flow_imp.g_varchar2_table(191) := '7475726E204F742865297C7C747970656F6620653D3D22737472696E67222626652E7472696D2829213D3D222226262169734E614E284E756D626572286529297D66756E6374696F6E20557428652C722C6E297B76617220743D652E6D61702866756E63';
wwv_flow_imp.g_varchar2_table(192) := '74696F6E2873297B72657475726E20735B725D7D292E66696C7465722866756E6374696F6E2873297B72657475726E2073213D6E756C6C262673213D3D22227D293B6966286E3D3D3D22636F756E74222972657475726E20742E6C656E6774683B696628';
wwv_flow_imp.g_varchar2_table(193) := '6E3D3D3D2273756D227C7C6E3D3D3D2261766722297B76617220613D742E66696C746572285672292E6D6170284E756D626572292C693D612E7265647563652866756E6374696F6E28732C6C297B72657475726E20732B6C7D2C30293B72657475726E20';
wwv_flow_imp.g_varchar2_table(194) := '6E3D3D3D2273756D223F693A612E6C656E6774683F692F612E6C656E6774683A6E756C6C7D766172206F3D6E756C6C2C753D6E756C6C3B72657475726E20742E666F72456163682866756E6374696F6E2873297B766172206C3D56722873293F6E756C6C';
wwv_flow_imp.g_varchar2_table(195) := '3A74742873292C683D56722873293F4E756D6265722873293A6C3F6C2E67657454696D6528293A537472696E672873293B28753D3D3D6E756C6C7C7C286E3D3D3D226D696E223F683C753A683E7529292626286F3D732C753D68297D292C6F7D66756E63';
wwv_flow_imp.g_varchar2_table(196) := '74696F6E20546928652C722C6E2C74297B76617220613D5574286E2C722E636F6C2C722E666E292C693B72657475726E20613D3D6E756C6C3F693D22223A722E666E3D3D3D22636F756E74223F693D4B6528612C22696E7422293A722E666E3D3D3D226D';
wwv_flow_imp.g_varchar2_table(197) := '696E227C7C722E666E3D3D3D226D6178223F693D56722861293F4B6528612C652E666D747C7C226D6F6E657922293A4B6528612C652E666D74293A722E666E3D3D3D22617667223F693D4B6528612C652E666D742626652E666D74213D3D22696E74223F';
wwv_flow_imp.g_varchar2_table(198) := '652E666D743A226D6F6E657922293A693D4B6528612C652E666D747C7C226D6F6E657922292C69262674262649745B722E666E5D3F49745B722E666E5D2B2220222B693A697D66756E6374696F6E206D7428652C722C6E2C74297B76617220613D646128';
wwv_flow_imp.g_varchar2_table(199) := '72292C693D2D312C6F3D652E6D61702866756E6374696F6E28752C73297B766172206C3D752E636F6C3F776E28722C752E636F6C293A6E756C6C3B72657475726E206C2626693C30262628693D73292C6C3F546928752C6C2C6E2C61293A22227D293B72';
wwv_flow_imp.g_varchar2_table(200) := '657475726E7B61743A693C303F652E6C656E6774683A692C63656C6C733A6F2C746578743A747D7D66756E6374696F6E20796E28652C722C6E297B72657475726E205628652E746F74616C734C6162656C7C7C22546F74616C6573222C722C7B434F554E';
wwv_flow_imp.g_varchar2_table(201) := '543A6E2E6C656E6774687D297D66756E6374696F6E20706128652C72297B766172206E3D7B636F6E74656E743A652E746578742C636F6C5370616E3A652E61747C7C722C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E2065';
wwv_flow_imp.g_varchar2_table(202) := '2E61743D3D3D303F5B5B6E5D2C652E63656C6C732E736C69636528295D3A5B5B6E5D2E636F6E63617428652E63656C6C732E736C69636528652E617429295D7D66756E6374696F6E205F742865297B72657475726E20652E627265616B546F74616C733D';
wwv_flow_imp.g_varchar2_table(203) := '3D3D21313F5B5D3A61742841727261792E6973417272617928652E627265616B546F74616C73293F652E627265616B546F74616C733A652E746F74616C73297D66756E6374696F6E2042742865297B76617220723D652E627265616B42793B7265747572';
wwv_flow_imp.g_varchar2_table(204) := '6E20723F2841727261792E697341727261792872293F723A5B725D292E6D61702866756E6374696F6E286E297B72657475726E20537472696E67286E7C7C2222292E746F55707065724361736528297D292E66696C74657228426F6F6C65616E293A5B5D';
wwv_flow_imp.g_varchar2_table(205) := '7D66756E6374696F6E20456E28652C72297B72657475726E2041727261792E697341727261792865293F655B725D3A657D66756E6374696F6E20536E28652C72297B766172206E3D42742865293B696628216E2E6C656E6774687C7C21722E6C656E6774';
wwv_flow_imp.g_varchar2_table(206) := '682972657475726E20722E6D61702866756E6374696F6E28732C6C297B72657475726E7B6B3A22726F77222C723A732C693A6C7D7D293B76617220743D5B5D2C613D5B5D2C693D302C6F3D5F742865292E6C656E6774683E303B66756E6374696F6E2075';
wwv_flow_imp.g_varchar2_table(207) := '2873297B666F72283B612E6C656E6774683E733B297B766172206C3D612E706F7028293B6F2626456E28652E627265616B4C6162656C2C612E6C656E67746829213D3D21312626742E70757368287B6B3A22737562222C6C766C3A612E6C656E6774682C';
wwv_flow_imp.g_varchar2_table(208) := '636F6C3A6C2E636F6C2C723A6C2E722C726F77733A6C2E726F77737D297D7D72657475726E20722E666F72456163682866756E6374696F6E2873297B666F7228766172206C3D6E2E6D61702866756E6374696F6E286D297B72657475726E20537472696E';
wwv_flow_imp.g_varchar2_table(209) := '6728735B6D5D3D3D3D6E756C6C7C7C735B6D5D3D3D3D766F696420303F22223A735B6D5D297D292C683D303B683C612E6C656E6774682626615B685D2E6B65793D3D3D6C5B685D3B29682B2B3B666F7228752868293B683C6E2E6C656E6774683B682B2B';
wwv_flow_imp.g_varchar2_table(210) := '297B76617220673D7B6B65793A6C5B685D2C636F6C3A6E5B685D2C723A732C726F77733A5B5D7D3B612E707573682867292C456E28652E627265616B5469746C652C6829213D3D21312626742E70757368287B6B3A2268656164222C6C766C3A682C636F';
wwv_flow_imp.g_varchar2_table(211) := '6C3A6E5B685D2C723A732C726F77733A672E726F77737D297D612E666F72456163682866756E6374696F6E286D297B6D2E726F77732E707573682873297D292C742E70757368287B6B3A22726F77222C723A732C693A692B2B7D297D292C752830292C74';
wwv_flow_imp.g_varchar2_table(212) := '7D66756E6374696F6E20686128652C72297B766172206E3D42742865295B305D3B69662821652E627265616B506167657C7C216E7C7C652E5F706172747C7C722E6C656E6774683C322972657475726E206E756C6C3B76617220743D5B5D2C613D6E756C';
wwv_flow_imp.g_varchar2_table(213) := '6C3B72657475726E20722E666F72456163682866756E6374696F6E2869297B766172206F3D537472696E6728695B6E5D3D3D3D6E756C6C7C7C695B6E5D3D3D3D766F696420303F22223A695B6E5D293B2821742E6C656E6774687C7C6F213D3D61292626';
wwv_flow_imp.g_varchar2_table(214) := '28742E70757368285B5D292C613D6F292C745B742E6C656E6774682D315D2E707573682869297D292C742E6C656E6774683C323F6E756C6C3A742E6D61702866756E6374696F6E28692C6F297B76617220753D69722865292C733D6F3D3D3D742E6C656E';
wwv_flow_imp.g_varchar2_table(215) := '6774682D313B72657475726E20752E5F726F77733D692C752E5F706172743D21302C752E5F616C6C526F77733D722C752E627265616B546F74616C733D3D3D766F69642030262628752E627265616B546F74616C733D652E746F74616C73292C737C7C28';
wwv_flow_imp.g_varchar2_table(216) := '752E746F74616C733D6E756C6C292C6F3E302626652E7469746C654F6E6365262664656C65746520752E7469746C652C757D297D66756E6374696F6E2043692865297B76617220723D652E63617272793B69662821722972657475726E206E756C6C3B76';
wwv_flow_imp.g_varchar2_table(217) := '6172206E3D723D3D3D21303F7B7D3A41727261792E697341727261792872293F7B636F6C733A727D3A722C743D6174286E2E636F6C737C7C652E746F74616C73292E66696C7465722866756E6374696F6E2861297B72657475726E20612E666E3D3D3D22';
wwv_flow_imp.g_varchar2_table(218) := '73756D227D293B72657475726E20742E6C656E6774683F7B636F6C733A742C6C6162656C3A6E2E6C6162656C7C7C2256616E222C6C6162656C46726F6D3A6E2E6C6162656C46726F6D7C7C225669656E656E227D3A6E756C6C7D66756E6374696F6E2054';
wwv_flow_imp.g_varchar2_table(219) := '6E28652C72297B69662821722972657475726E20652E67726F75703B766172206E3D2428652E67726F7570292C743D4D6174682E6D696E282E37352C2E342A72293B72657475726E2223222B6E2E6D61702866756E6374696F6E2861297B76617220693D';
wwv_flow_imp.g_varchar2_table(220) := '4D6174682E726F756E6428612B283235352D61292A74292E746F537472696E67283136293B72657475726E20692E6C656E6774683C323F2230222B693A697D292E6A6F696E282222292E746F55707065724361736528297D66756E6374696F6E20697428';
wwv_flow_imp.g_varchar2_table(221) := '652C722C6E297B76617220743D7B7D2C612C693D722E636F6C7C7C42742865295B305D3B666F72286120696E20722E7229745B615D3D722E725B615D3B742E434F554E543D722E726F77732E6C656E6774683B766172206F3D456E28722E6B3D3D3D2268';
wwv_flow_imp.g_varchar2_table(222) := '656164223F652E627265616B5469746C653A652E627265616B4C6162656C2C722E6C766C7C7C30293B72657475726E286F3D3D6E756C6C7C7C6F3D3D3D2130292626286F3D722E6B3D3D3D2268656164223F227B222B692B227D223A22537562746F7461';
wwv_flow_imp.g_varchar2_table(223) := '6C207B222B692B227D22292C56286F2C6E2C74297D66756E6374696F6E207A7228652C722C6E297B696628652E6D6170297B76617220743D577228722C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C2222292E73706C';
wwv_flow_imp.g_varchar2_table(224) := '697428227C22295B305D2C6E293B72657475726E20652E6D61705B745D213D3D766F696420303F652E6D61705B745D3A537472696E6728747C7C2222297D76617220613D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E7D7C5D2B';
wwv_flow_imp.g_varchar2_table(225) := '5C7D242F2E7465737428617C7C2222293F4B6528577228722C612E736C69636528312C2D31292C6E292C652E666D74293A5628612C722C6E297D7661722041693D7B746578743A312C6D756C74696C696E653A312C6C6973743A312C636865636B626F78';
wwv_flow_imp.g_varchar2_table(226) := '3A317D2C47743D2223463246364641222C436E3D2223424643394434222C48743D22E29892222C57743D22E29890223B66756E6374696F6E2067612865297B76617220723D537472696E6728653D3D6E756C6C3F22223A65293B696628212F5E5B412D5A';
wwv_flow_imp.g_varchar2_table(227) := '612D7A5F5D5B412D5A612D7A302D395F5D7B302C33397D242F2E746573742872297C7C2F5E5B412D5A612D7A5D7B312C337D5B302D395D2B242F2E746573742872297C7C2F5E5B527243635D242F2E746573742872297C7C2F5E5B52725D5B302D395D2A';
wwv_flow_imp.g_varchar2_table(228) := '5B43635D5B302D395D2A242F2E74657374287229297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F20696E76C3A16C69646F3A2022272B722B27222E20557365206C65747261732C206EC3BA6D65726F732079205F2028';
wwv_flow_imp.g_varchar2_table(229) := '68617374612034302C2073696E206573706163696F73206E692070756E746F7329207920717565206E6F20706172657A636120756E612063656C646120646520457863656C202841312C2052314331292E27293B72657475726E20727D66756E6374696F';
wwv_flow_imp.g_varchar2_table(230) := '6E20416E28297B76617220653D7B7D3B72657475726E2066756E6374696F6E2872297B766172206E3D722E746F4C6F7765724361736528293B696628655B6E5D297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F207265';
wwv_flow_imp.g_varchar2_table(231) := '70657469646F20656E20656C20646F63756D656E746F3A2022272B722B27222E27293B72657475726E20655B6E5D3D312C727D7D66756E6374696F6E2078692865297B72657475726E20653D3D3D21307C7C2F5E28737C73697C73C3AD7C797C7965737C';
wwv_flow_imp.g_varchar2_table(232) := '317C787C747275657C6F6E29242F692E7465737428537472696E6728653D3D6E756C6C3F22223A65292E7472696D2829297D66756E6374696F6E20466928652C72297B766172206E3D5B5D3B66756E6374696F6E2074286F297B6F3D537472696E67286F';
wwv_flow_imp.g_varchar2_table(233) := '3D3D6E756C6C3F22223A6F292C6F213D3D222226266E2E696E6465784F66286F293C3026266E2E70757368286F297D6966282841727261792E6973417272617928652E6F7074696F6E73293F652E6F7074696F6E733A5B5D292E666F7245616368287429';
wwv_flow_imp.g_varchar2_table(234) := '2C652E6F7074696F6E7346726F6D297B76617220613D537472696E6728652E6F7074696F6E7346726F6D292E73706C697428222E22292C693D615B315D3F615B315D2E746F55707065724361736528293A6E756C6C3B4F65287B736F757263653A615B30';
wwv_flow_imp.g_varchar2_table(235) := '5D7D2C72292E666F72456163682866756E6374696F6E286F297B7428693F6F5B695D3A6F5B4F626A6563742E6B657973286F295B305D5D297D297D72657475726E206E7D66756E6374696F6E20786E28652C722C6E297B76617220743D4F6528652C7229';
wwv_flow_imp.g_varchar2_table(236) := '5B305D7C7C7B7D3B72657475726E28652E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2861297B72657475726E206126262821612E7768656E7C7C657228612E7768656E2C722C7429297D292E6D61702866756E6374696F6E2861';
wwv_flow_imp.g_varchar2_table(237) := '297B696628612E656D7074792972657475726E7B656D7074793A21302C7370616E3A612E7370616E7D3B76617220693D537472696E6728612E696E7075747C7C227465787422292E746F4C6F7765724361736528293B6966282141695B695D297468726F';
wwv_flow_imp.g_varchar2_table(238) := '77206E6577204572726F7228275469706F2064652063616D706F206E6F20736F706F727461646F3A2022272B612E696E7075742B27222028746578742C206D756C74696C696E652C206C6973742C20636865636B626F78292E27293B766172206F3D6761';
wwv_flow_imp.g_varchar2_table(239) := '28612E6E616D65292B286E7C7C2222292C753D612E76616C75653D3D3D766F696420307C7C612E76616C75653D3D3D6E756C6C3F22223A537472696E67287A7228612C722C7429292C733D693D3D3D226C697374223F466928612C72293A5B5D3B696628';
wwv_flow_imp.g_varchar2_table(240) := '693D3D3D226C69737422262621732E6C656E677468297468726F77206E6577204572726F722827456C2063616D706F2022272B6F2B272220657320756E61206C697374612073696E206F7063696F6E657320286F7074696F6E732075206F7074696F6E73';
wwv_flow_imp.g_varchar2_table(241) := '46726F6D292E27293B766172206C3D28693D3D3D2274657874227C7C693D3D3D226D756C74696C696E65222926264E756D62657228612E6D61784C656E677468293E303F4D6174682E666C6F6F72284E756D62657228612E6D61784C656E67746829293A';
wwv_flow_imp.g_varchar2_table(242) := '303B72657475726E2069213D3D226D756C74696C696E6522262628753D752E7265706C616365282F5C723F5C6E2F672C22202229292C693D3D3D226C697374222626732E696E6465784F662875293C30262628753D2222292C6C262628753D752E737562';
wwv_flow_imp.g_varchar2_table(243) := '73747228302C6C29292C7B6C6162656C3A5628612E6C6162656C2C722C74292C6E616D653A6F2C696E7075743A692C6F7074696F6E733A732C76616C75653A693D3D3D22636865636B626F78223F22223A752C636865636B65643A693D3D3D2263686563';
wwv_flow_imp.g_varchar2_table(244) := '6B626F7822262678692875292C6D61784C656E6774683A6C2C726561644F6E6C793A612E726561644F6E6C793D3D3D21302C6C696E65733A693D3D3D226D756C74696C696E65223F4D6174682E6D617828322C4D6174682E6D696E2832302C4E756D6265';
wwv_flow_imp.g_varchar2_table(245) := '7228612E6C696E6573297C7C3329293A312C706C616365686F6C6465723A612E706C616365686F6C6465723F5628612E706C616365686F6C6465722C722C74293A22222C7370616E3A612E7370616E2C6C61623A757428612C65297D7D297D66756E6374';
wwv_flow_imp.g_varchar2_table(246) := '696F6E206D6128652C72297B766172206E3D652E666F726D7C7C7B7D2C743D722626722E666F726D50617373776F7264213D3D766F696420302626722E666F726D50617373776F7264213D3D6E756C6C3F722E666F726D50617373776F72643A6E2E7061';
wwv_flow_imp.g_varchar2_table(247) := '7373776F72643B72657475726E7B70726F746563743A6E2E70726F74656374213D3D21312C70617373776F72643A743F537472696E672874293A22227D7D66756E6374696F6E2063742865297B72657475726E28657C7C5B5D292E736F6D652866756E63';
wwv_flow_imp.g_varchar2_table(248) := '74696F6E2872297B72657475726E2072262628722E747970653D3D3D22666F726D756C6172696F227C7C722E747970653D3D3D22636F6C756D6E617322262628722E636F6C737C7C5B5D292E736F6D65286374297C7C722E747970653D3D3D2267727570';
wwv_flow_imp.g_varchar2_table(249) := '6F222626637428722E73656374696F6E7329297D297D66756E6374696F6E2063612865297B76617220723D652626652E62617463682626652E62617463682E73756D6D6172793B72657475726E20637428652626652E73656374696F6E73297C7C212128';
wwv_flow_imp.g_varchar2_table(250) := '72262628637428722E73656374696F6E73297C7C722E6C61796F75742626637428722E6C61796F75742E73656374696F6E732929297D7661722076613D5B313131363335323430382C333630393736373435382C313839393434373434312C3630323839';
wwv_flow_imp.g_varchar2_table(251) := '313732352C333034393332333437312C333936343438343339392C333932313030393537332C323137333239353534382C3936313938373136332C343038313632383437322C313530383937303939332C333035333833343236352C3234353336333537';
wwv_flow_imp.g_varchar2_table(252) := '34382C323933373637313537392C323837303736333232312C333636343630393536302C333632343338313038302C323733343838333339342C3331303539383430312C313136343939363534322C3630373232353237382C313332333631303736342C';
wwv_flow_imp.g_varchar2_table(253) := '313432363838313938372C333539303330343939342C313932353037383338382C343036383138323338332C323136323037383230362C3939313333363131332C323631343838383130332C3633333830333331372C333234383232323538302C333437';
wwv_flow_imp.g_varchar2_table(254) := '393737343836382C333833353339303430312C323636363631333435382C343032323232343737342C3934343731313133392C3236343334373037382C323334313236323737332C3630343830373632382C323030373830303933332C37373032353539';
wwv_flow_imp.g_varchar2_table(255) := '38332C313439353939303930312C313234393135303132322C313835363433313233352C313535353038313639322C333137353231383133322C313939363036343938362C323139383935303833372C323535343232303838322C333939393731393333';
wwv_flow_imp.g_varchar2_table(256) := '392C323832313833343334392C3736363738343031362C323935323939363830382C323536363539343837392C333231303331333637312C333230333333373935362C333333363537313839312C313033343435373032362C333538343532383731312C';
wwv_flow_imp.g_varchar2_table(257) := '323436363934383930312C3131333932363939332C333735383332363338332C3333383234313839352C3136383731373933362C3636363330373230352C313138383137393936342C3737333532393931322C313534363034353733342C313239343735';
wwv_flow_imp.g_varchar2_table(258) := '373337322C313532323830353438352C313339363138323239312C323634333833333832332C313639353138333730302C323334333532373339302C313938363636313035312C313031343437373438302C323137373032363335302C31323036373539';
wwv_flow_imp.g_varchar2_table(259) := '3134322C323435363935363033372C3334343037373632372C323733303438353932312C313239303836333436302C323832303330323431312C333135383435343237332C333235393733303830302C333530353935323635372C333334353736343737';
wwv_flow_imp.g_varchar2_table(260) := '312C3130363231373030382C333531363036353831372C333630363030383334342C333630303335323830342C313433323732353737362C343039343537313930392C313436373033313539342C3237353432333334342C3835313136393732302C3433';
wwv_flow_imp.g_varchar2_table(261) := '303232373733342C333130303832333735322C3530363934383631362C313336333235383139352C3635393036303535362C333735303638353539332C3838333939373837372C333738353035303238302C3935383133393537312C3333313833303734';
wwv_flow_imp.g_varchar2_table(262) := '32372C313332323832323231382C333831323732333430332C313533373030323036332C323030333033343939352C313734373837333737392C333630323033363839392C313935353536323232322C313537353939303031322C323032343130343831';
wwv_flow_imp.g_varchar2_table(263) := '352C313132353539323932382C323232373733303435322C323731363930343330362C323336313835323432342C3434323737363034342C323432383433363437342C3539333639383334342C323735363733343138372C333733333131303234392C33';
wwv_flow_imp.g_varchar2_table(264) := '3230343033313437392C323939393335313537332C333332393332353239382C333831353932303432372C333339313536393631342C333932383338333930302C333531353236373237312C3536363238303731312C333934303138373630362C333435';
wwv_flow_imp.g_varchar2_table(265) := '343036393533342C343131383633303237312C343030303233393939322C3131363431383437342C313931343133383535342C3137343239323432312C323733313035353237302C3238393338303335362C333230333939333030362C34363033393332';
wwv_flow_imp.g_varchar2_table(266) := '36392C3332303632303331352C3638353437313733332C3538373439363833362C3835323134323937312C313038363739323835312C313031373033363239382C3336353534333130302C313132363030303538302C323631383239373637362C313238';
wwv_flow_imp.g_varchar2_table(267) := '383033333437302C333430393835353135382C313530313530353934382C343233343530393836362C313630373136373931352C3938373136373436382C313831363430323331362C313234363138393539315D3B66756E6374696F6E20466E2865297B';
wwv_flow_imp.g_varchar2_table(268) := '76617220722C6E2C743D5B313737393033333730332C343038393233353732302C333134343133343237372C323232373837333539352C313031333930343234322C343237313137353732332C323737333438303736322C313539353735303132392C31';
wwv_flow_imp.g_varchar2_table(269) := '3335393839333131392C323931373536353133372C323630303832323932342C3732353531313139392C3532383733343633352C343231353338393534372C313534313435393232352C3332373033333230395D2C613D652E6C656E6774682C693D612B';
wwv_flow_imp.g_varchar2_table(270) := '31372B3132373E3E373C3C372C6F3D6E65772055696E743841727261792869292C753D6E657720496E743332417272617928313630293B6F2E7365742865292C6F5B615D3D3132383B76617220733D612A383B6F5B692D315D3D73263235352C6F5B692D';
wwv_flow_imp.g_varchar2_table(271) := '325D3D733E3E3E38263235352C6F5B692D335D3D733E3E3E3136263235352C6F5B692D345D3D733E3E3E3234263235352C6F5B692D355D3D4D6174682E666C6F6F7228732F3432393439363732393629263235353B666F7228766172206C3D3432393439';
wwv_flow_imp.g_varchar2_table(272) := '36373239362C683D303B683C693B682B3D313238297B666F7228723D303B723C33323B722B2B296E3D682B722A342C755B725D3D6F5B6E5D3C3C32347C6F5B6E2B315D3C3C31367C6F5B6E2B325D3C3C387C6F5B6E2B335D3B666F7228723D33323B723C';
wwv_flow_imp.g_varchar2_table(273) := '3136303B722B3D32297B76617220673D755B722D33305D2C6D3D755B722D32395D2C543D755B722D345D2C463D755B722D335D2C443D28673E3E3E317C6D3C3C3331295E28673E3E3E387C6D3C3C3234295E673E3E3E372C503D28543E3E3E31397C463C';
wwv_flow_imp.g_varchar2_table(274) := '3C3133295E28463E3E3E32397C543C3C33295E543E3E3E362C623D28463E3E3E31397C543C3C3133295E28543E3E3E32397C463C3C33295E28463E3E3E367C543C3C3236292C70653D2828286D3E3E3E317C673C3C3331295E286D3E3E3E387C673C3C32';
wwv_flow_imp.g_varchar2_table(275) := '34295E286D3E3E3E377C673C3C323529293E3E3E30292B28755B722D31335D3E3E3E30292B28623E3E3E30292B28755B722D33315D3E3E3E30292C763D442B755B722D31345D2B502B755B722D33325D2B4D6174682E666C6F6F722870652F6C297C303B';
wwv_flow_imp.g_varchar2_table(276) := '755B725D3D762C755B722B315D3D70657C307D76617220413D745B305D2C793D745B315D2C4D3D745B325D2C493D745B335D2C5F3D745B345D2C66653D745B355D2C423D745B365D2C773D745B375D2C68653D745B385D2C4C653D745B395D2C48653D74';
wwv_flow_imp.g_varchar2_table(277) := '5B31305D2C4A653D745B31315D2C533D745B31325D2C453D745B31335D2C433D745B31345D2C5A3D745B31355D3B666F7228723D303B723C3136303B722B3D32297B7661722061653D2868653E3E3E31347C4C653C3C3138295E2868653E3E3E31387C4C';
wwv_flow_imp.g_varchar2_table(278) := '653C3C3134295E284C653E3E3E397C68653C3C3233292C4B3D68652648655E7E686526532C593D285A3E3E3E30292B2828284C653E3E3E31347C68653C3C3138295E284C653E3E3E31387C68653C3C3134295E2868653E3E3E397C4C653C3C323329293E';
wwv_flow_imp.g_varchar2_table(279) := '3E3E30292B28284C65264A655E7E4C652645293E3E3E30292B2876615B722B315D3E3E3E30292B28755B722B315D3E3E3E30292C52653D432B61652B4B2B76615B725D2B755B725D2B4D6174682E666C6F6F7228592F6C297C303B597C3D303B76617220';
wwv_flow_imp.g_varchar2_table(280) := '57653D282828793E3E3E32387C413C3C34295E28413E3E3E327C793C3C3330295E28413E3E3E377C793C3C323529293E3E3E30292B28287926495E792666655E49266665293E3E3E30292C783D2828413E3E3E32387C793C3C34295E28793E3E3E327C41';
wwv_flow_imp.g_varchar2_table(281) := '3C3C3330295E28793E3E3E377C413C3C323529292B2841264D5E41265F5E4D265F292B4D6174682E666C6F6F722857652F6C297C303B57657C3D302C433D532C5A3D452C533D48652C453D4A652C48653D68652C4A653D4C653B7661722072653D28773E';
wwv_flow_imp.g_varchar2_table(282) := '3E3E30292B28593E3E3E30293B68653D422B52652B4D6174682E666C6F6F722872652F6C297C302C4C653D72657C302C423D5F2C773D66652C5F3D4D2C66653D492C4D3D412C493D792C72653D28593E3E3E30292B2857653E3E3E30292C413D52652B78';
wwv_flow_imp.g_varchar2_table(283) := '2B4D6174682E666C6F6F722872652F6C297C302C793D72657C307D7661722073653D5B412C792C4D2C492C5F2C66652C422C772C68652C4C652C48652C4A652C532C452C432C5A5D3B666F7228723D303B723C31363B722B3D32297B76617220643D2874';
wwv_flow_imp.g_varchar2_table(284) := '5B722B315D3E3E3E30292B2873655B722B315D3E3E3E30293B745B725D3D745B725D2B73655B725D2B4D6174682E666C6F6F7228642F6C297C302C745B722B315D3D647C307D7D76617220703D6E65772055696E74384172726179283634293B666F7228';
wwv_flow_imp.g_varchar2_table(285) := '723D303B723C31363B722B2B29705B722A345D3D745B725D3E3E3E32342C705B722A342B315D3D745B725D3E3E3E3136263235352C705B722A342B325D3D745B725D3E3E3E38263235352C705B722A342B335D3D745B725D263235353B72657475726E20';
wwv_flow_imp.g_varchar2_table(286) := '707D7661722050693D5B35373834302C373433392C35323338302C33333938342C343336342C333630302C36313930322C31323630362C363235382C35373635372C35343238372C33343034312C31303235322C34333337302C32303136335D2C4E693D';
wwv_flow_imp.g_varchar2_table(287) := '5B5B34343739362C31393932392C33393835382C31303035332C32303130362C34303231322C31303736315D2C5B33313538352C36333137302C36343933332C36303236372C35303933352C34303339392C31313139395D2C5B31373736332C33353532';
wwv_flow_imp.g_varchar2_table(288) := '362C313435332C323930362C353831322C31313632342C32333234385D2C5B3838352C313737302C333534302C373038302C31343136302C32383332302C35363634305D2C5B35353336392C34313133392C32303830372C34313631342C32313832312C';
wwv_flow_imp.g_varchar2_table(289) := '34333634322C31373632315D2C5B32383438352C35363937302C34343334312C31393031392C33383033382C31343630352C32393231305D2C5B36303139352C35303739312C34303137352C31303735312C32313530322C34333030342C32343533375D';
wwv_flow_imp.g_varchar2_table(290) := '2C5B31383338372C33363737342C333934392C373839382C31353739362C33313539322C36333138345D2C5B34373230312C32343830332C34393630362C33373830352C31343230332C32383430362C35363831325D2C5B31373832342C33353634382C';
wwv_flow_imp.g_varchar2_table(291) := '313639372C333339342C363738382C31333537362C32373135325D2C5B34333630312C31373533392C33353037382C3535372C313131342C323232382C343435365D2C5B33303338382C36303737362C35313935332C33343234332C373037392C313431';
wwv_flow_imp.g_varchar2_table(292) := '35382C32383331365D2C5B31343132382C32383235362C35363531322C34333432352C31373235312C33343530322C373539375D2C5B31333130352C32363231302C35323432302C33353234312C3838332C313736362C333533325D2C5B343132392C38';
wwv_flow_imp.g_varchar2_table(293) := '3235382C31363531362C33333033322C343635372C393331342C31383632385D5D3B66756E6374696F6E2062612865297B76617220722C6E2C743D5B5D2C613D66756E6374696F6E286D297B72657475726E286D3C31363F2230223A2222292B6D2E746F';
wwv_flow_imp.g_varchar2_table(294) := '537472696E67283136292E746F55707065724361736528297D3B666F7228723D303B723C652E6C656E6774683B722B2B297B76617220693D652E63686172436F646541742872293B742E707573682869263235357C7C693E3E3826323535297D76617220';
wwv_flow_imp.g_varchar2_table(295) := '6F3D50695B742E6C656E6774682D315D2C753D31352D742E6C656E6774682C733D303B666F7228723D303B723C742E6C656E6774683B722B2B297B766172206C3D745B725D2C683D4E695B752B2B5D3B666F72286E3D303B6E3C373B6E2B2B296C263126';
wwv_flow_imp.g_varchar2_table(296) := '26286F5E3D685B6E5D292C6C3E3E3D317D66756E6374696F6E2067286D297B72657475726E206D3E3E313426317C6D3C3C312633323736377D666F7228723D742E6C656E6774682D313B723E3D303B722D2D29733D672873295E745B725D3B7265747572';
wwv_flow_imp.g_varchar2_table(297) := '6E20733D672873295E742E6C656E6774685E35323831312C61287326323535292B6128733E3E3826323535292B61286F26323535292B61286F3E3E3826323535297D66756E6374696F6E20506E28652C722C6E297B696628212F5E5B5C7832302D5C7837';
wwv_flow_imp.g_varchar2_table(298) := '455D7B312C31357D242F2E74657374286529297468726F77206E6577204572726F7228224C6120636F6E7472617365C3B1612064652070726F7465636369C3B36E20646520576F72642061646D6974652064652031206120313520636172616374657265';
wwv_flow_imp.g_varchar2_table(299) := '73204153434949202873696E2074696C646573206E6920C3B1292E22293B76617220742C613D62612865292C693D6E65772055696E7438417272617928722E6C656E6774682B612E6C656E6774682A32293B666F7228692E7365742872292C743D303B74';
wwv_flow_imp.g_varchar2_table(300) := '3C612E6C656E6774683B742B2B29695B722E6C656E6774682B742A325D3D612E63686172436F646541742874293B766172206F3D466E2869292C753D6E65772055696E74384172726179283638293B666F7228743D303B743C6E3B742B2B29752E736574';
wwv_flow_imp.g_varchar2_table(301) := '286F292C755B36345D3D74263235352C755B36355D3D743E3E3E38263235352C755B36365D3D743E3E3E3136263235352C755B36375D3D743E3E3E3234263235352C6F3D466E2875293B72657475726E206F7D766172206B723D2223443544434533223B';
wwv_flow_imp.g_varchar2_table(302) := '66756E6374696F6E204E6E28652C72297B766172206E3D652E6C6162656C5769647468733B72657475726E2041727261792E69734172726179286E2926264E756D626572286E5B725D293E303F4E756D626572286E5B725D293A652E6C6162656C576964';
wwv_flow_imp.g_varchar2_table(303) := '74687C7C33327D66756E6374696F6E206C7428652C72297B766172206E3D652E68656164416C69676E7C7C722E68656164416C69676E7C7C2263656E746572223B72657475726E206E3D3D3D226175746F223F652E616C69676E3A6E7D66756E6374696F';
wwv_flow_imp.g_varchar2_table(304) := '6E206F7428652C72297B766172206E3D5B5D2C743D5B5D2C613D303B72657475726E20652E666F72456163682866756E6374696F6E2869297B766172206F3D692626692E7370616E3D3D3D22726F77223F722D613A4D6174682E6D617828312C4D617468';
wwv_flow_imp.g_varchar2_table(305) := '2E6D696E28722C4D6174682E666C6F6F72284E756D62657228692626692E7370616E29297C7C3129293B612B6F3E722626286E2E707573682874292C743D5B5D2C613D30292C742E70757368287B663A692C636F6C3A612C7370616E3A6F2C656D707479';
wwv_flow_imp.g_varchar2_table(306) := '3A212128692626692E656D707479297D292C612B3D6F2C613D3D3D722626286E2E707573682874292C743D5B5D2C613D30297D292C742E6C656E67746826266E2E707573682874292C6E7D66756E6374696F6E2077612865297B72657475726E28657C7C';
wwv_flow_imp.g_varchar2_table(307) := '5B5D292E736F6D652866756E6374696F6E2872297B72657475726E2072262628722E656D7074797C7C722E7370616E2626722E7370616E213D3D31297D297D66756E6374696F6E2056742865297B72657475726E20652E7265647563652866756E637469';
wwv_flow_imp.g_varchar2_table(308) := '6F6E28722C6E297B72657475726E20722B6E2E7370616E7D2C30297D66756E6374696F6E20767428652C722C6E297B69662821657C7C2128652E616C69676E7C7C652E626F6C647C7C652E636F6C6F727C7C652E66696C6C292972657475726E206E756C';
wwv_flow_imp.g_varchar2_table(309) := '6C3B76617220743D2F5E286C6566747C63656E7465727C726967687429242F2E7465737428652E616C69676E7C7C2222293F652E616C69676E3A6E756C6C3B72657475726E7B616C69676E3A742C626F6C643A2121652E626F6C642C636F6C6F723A652E';
wwv_flow_imp.g_varchar2_table(310) := '636F6C6F723F707428652E636F6C6F722C722C6E293A6E756C6C2C66696C6C3A652E66696C6C7C7C6E756C6C7D7D766172207A693D7B6C6566743A312C746F703A312C6E6F6E653A317D3B66756E6374696F6E20757428652C72297B66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(311) := '206E2875297B72657475726E20652626655B755D213D3D766F696420302626655B755D213D3D6E756C6C2626655B755D213D3D22223F655B755D3A725B755D7D76617220743D537472696E67286E28226C6162656C506F736974696F6E22297C7C226C65';
wwv_flow_imp.g_varchar2_table(312) := '667422292E746F4C6F7765724361736528292C613D6E28226C6162656C416C69676E22292C693D6E28226C6162656C426F6C6422292C6F3D7B706F733A7A695B745D3F743A226C656674222C73697A653A4E756D626572286E28226C6162656C53697A65';
wwv_flow_imp.g_varchar2_table(313) := '2229293E303F4E756D626572286E28226C6162656C53697A652229293A302C636F6C6F723A6E28226C6162656C436F6C6F7222297C7C6E756C6C2C626F6C643A693D3D6E756C6C3F21303A69213D3D2131262669213D3D2266616C7365222C7570706572';
wwv_flow_imp.g_varchar2_table(314) := '3A537472696E67286E28226C6162656C4361736522297C7C2222292E746F4C6F7765724361736528293D3D3D227570706572222C616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E7465737428617C7C2222293F613A6E756C6C';
wwv_flow_imp.g_varchar2_table(315) := '2C66696C6C3A6E28226C6162656C46696C6C22297C7C6E756C6C7D3B72657475726E206F2E7374796C65643D21212865262628652E6C6162656C53697A657C7C652E6C6162656C436F6C6F727C7C652E6C6162656C426F6C64213D3D766F696420302626';
wwv_flow_imp.g_varchar2_table(316) := '652E6C6162656C426F6C64213D3D6E756C6C7C7C652E6C6162656C436173657C7C652E6C6162656C416C69676E7C7C652E6C6162656C46696C6C29297C7C212128722E6C6162656C53697A657C7C722E6C6162656C426F6C64213D3D766F696420302626';
wwv_flow_imp.g_varchar2_table(317) := '722E6C6162656C426F6C64213D3D6E756C6C7C7C722E6C6162656C436173657C7C722E6C6162656C416C69676E292C6F7D66756E6374696F6E20247428652C722C6E2C74297B76617220613D7B626F6C643A722E626F6C647D3B28722E73697A657C7C6E';
wwv_flow_imp.g_varchar2_table(318) := '29262628612E73697A653D722E73697A657C7C39292C722E636F6C6F72262628612E636F6C6F723D7B617267623A466528722E636F6C6F72297D292C652E666F6E743D613B76617220693D722E616C69676E7C7C286E3F743A6E756C6C293B696628697C';
wwv_flow_imp.g_varchar2_table(319) := '7C6E297B766172206F3D7B7D3B4F626A6563742E6B65797328652E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2875297B6F5B755D3D652E616C69676E6D656E745B755D7D292C692626286F2E686F72697A6F6E74616C';
wwv_flow_imp.g_varchar2_table(320) := '3D69292C6E2626286F2E766572746963616C3D22626F74746F6D22292C652E616C69676E6D656E743D6F7D722E66696C6C262628652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B';
wwv_flow_imp.g_varchar2_table(321) := '617267623A466528722E66696C6C297D7D297D66756E6374696F6E20637228652C72297B72657475726E20722E75707065723F537472696E672865292E746F55707065724361736528293A657D66756E6374696F6E2079612865297B72657475726E2865';
wwv_flow_imp.g_varchar2_table(322) := '2E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E2872297B72657475726E2072262621722E656D7074792626757428722C65292E706F73213D3D226C656674227D297D66756E6374696F6E20456128652C72297B72657475726E20652E73';
wwv_flow_imp.g_varchar2_table(323) := '697A657C7C4D6174682E6D617828352C4D6174682E726F756E6428722A312E37292F32297D66756E6374696F6E207A6E28652C72297B72657475726E20456128652C72292A2E333532382A312E322B2E347D66756E6374696F6E2053612865297B766172';
wwv_flow_imp.g_varchar2_table(324) := '20723D7B666F6E745374796C653A652E626F6C643F22626F6C64223A226E6F726D616C227D3B72657475726E20652E73697A65262628722E666F6E7453697A653D652E73697A65292C652E636F6C6F72262628722E74657874436F6C6F723D2428652E63';
wwv_flow_imp.g_varchar2_table(325) := '6F6C6F7229292C652E66696C6C262628722E66696C6C436F6C6F723D2428652E66696C6C29292C652E616C69676E262628722E68616C69676E3D652E616C69676E292C727D66756E6374696F6E20546128652C722C6E2C742C61297B76617220693D6E2E';
wwv_flow_imp.g_varchar2_table(326) := '6C622C6F3D456128692C74292C753D6F2A2E333532383B696628692E66696C6C297B76617220733D2428692E66696C6C293B652E73657446696C6C436F6C6F7228735B305D2C735B315D2C735B325D292C652E7265637428722E782B2E312C722E792B2E';
wwv_flow_imp.g_varchar2_table(327) := '312C722E77696474682D2E322C612B752A312E322B2E312C224622297D766172206C3D2428692E636F6C6F727C7C222330303030303022292C683D4D6174682E6D617828352C722E77696474682D612A32293B652E736574466F6E74282268656C766574';
wwv_flow_imp.g_varchar2_table(328) := '696361222C692E626F6C643F22626F6C64223A226E6F726D616C22292C652E736574466F6E7453697A65286F292C652E73657454657874436F6C6F72286C5B305D2C6C5B315D2C6C5B325D293B76617220673D6E2E616C69676E3D3D3D22726967687422';
wwv_flow_imp.g_varchar2_table(329) := '3F722E782B722E77696474682D613A6E2E616C69676E3D3D3D2263656E746572223F722E782B722E77696474682F323A722E782B613B652E7465787428652E73706C697454657874546F53697A6528537472696E67286E2E74657874292C68295B305D7C';
wwv_flow_imp.g_varchar2_table(330) := '7C22222C672C722E792B612B752A2E39352C7B616C69676E3A6E2E616C69676E3D3D3D227269676874227C7C6E2E616C69676E3D3D3D2263656E746572223F6E2E616C69676E3A226C656674227D292C652E736574466F6E74282268656C766574696361';
wwv_flow_imp.g_varchar2_table(331) := '222C226E6F726D616C22292C652E73657454657874436F6C6F7228302C302C30297D66756E6374696F6E204D6E28652C72297B72657475726E7B73697A653A652E73697A657C7C31342C73756253697A653A652E7375627469746C6553697A657C7C392C';
wwv_flow_imp.g_varchar2_table(332) := '726967687453697A653A652E726967687453697A657C7C392C666F6E743A68745B756128652E666F6E74295D2C66696C6C3A652E66696C6C7C7C722E7072696D6172792C636F6C6F723A652E636F6C6F727C7C722E68656164546578747D7D66756E6374';
wwv_flow_imp.g_varchar2_table(333) := '696F6E20627428652C722C6E297B76617220743D4F6528652C72295B305D7C7C7B7D2C613D28652E6669656C64737C7C652E6974656D737C7C5B5D292E66696C7465722866756E6374696F6E286F297B72657475726E206F2626216F2E656D7074792626';
wwv_flow_imp.g_varchar2_table(334) := '28216F2E7768656E7C7C6572286F2E7768656E2C722C7429297D292E6D61702866756E6374696F6E286F297B72657475726E7B6C6162656C3A56286F2E6C6162656C2C722C74292C76616C75653A7A72286F2C722C74292C636F6C6F723A6F2E636F6C6F';
wwv_flow_imp.g_varchar2_table(335) := '723F7074286F2E636F6C6F722C722C74293A6E756C6C7D7D292C693D4D6174682E6D617828312C4D6174682E6D696E28362C4E756D62657228652E636F6C756D6E73297C7C4D6174682E6D696E28612E6C656E6774682C36297C7C3129293B7265747572';
wwv_flow_imp.g_varchar2_table(336) := '6E7B6974656D733A612C6E3A692C66696C6C3A652E66696C6C7C7C2223463146344632222C616363656E743A652E616363656E743D3D3D766F696420303F6E2E7072696D6172793A652E616363656E742C6C6162656C436F6C6F723A652E6C6162656C43';
wwv_flow_imp.g_varchar2_table(337) := '6F6C6F727C7C2223373837383738222C76616C7565436F6C6F723A652E76616C7565436F6C6F727C7C6E2E7072696D6172792C6C6162656C53697A653A652E6C6162656C53697A657C7C372C73697A653A652E73697A657C7C31312C636172644761703A';
wwv_flow_imp.g_varchar2_table(338) := '652E63617264476170213D3D766F696420303F4E756D62657228652E63617264476170293A337D7D66756E6374696F6E204F6E2865297B76617220723D7B7D3B72657475726E5B226C656674222C2263656E746572222C227269676874225D2E666F7245';
wwv_flow_imp.g_varchar2_table(339) := '6163682866756E6374696F6E286E297B76617220743D655B6E5D3B6966282128743D3D6E756C6C7C7C743D3D3D222229297B76617220613D747970656F6620743D3D226F626A6563742226262141727261792E697341727261792874293F743A7B746578';
wwv_flow_imp.g_varchar2_table(340) := '743A747D2C693D41727261792E6973417272617928612E74657874293F612E746578742E6A6F696E28225C6E22293A612E746578743B693D3D6E756C6C7C7C693D3D3D22227C7C28725B6E5D3D7B746578743A537472696E672869292C73697A653A4E75';
wwv_flow_imp.g_varchar2_table(341) := '6D62657228612E73697A657C7C652E73697A65297C7C382C626F6C643A612E626F6C64213D3D766F696420303F2121612E626F6C643A2121652E626F6C642C636F6C6F723A612E636F6C6F727C7C652E636F6C6F727C7C2223303030303030227D297D7D';
wwv_flow_imp.g_varchar2_table(342) := '292C727D66756E6374696F6E2043612865297B76617220723D537472696E6728652E696D6167652626652E696D6167652E616C69676E7C7C2222292E746F4C6F7765724361736528293B72657475726E20723D3D3D227269676874227C7C723D3D3D2263';
wwv_flow_imp.g_varchar2_table(343) := '656E746572223F723A226C656674227D66756E6374696F6E20416128652C72297B69662821652E696D6167652972657475726E206E756C6C3B766172206E3D697228652E696D616765292C743D5874286E2C72293B69662821742972657475726E206E75';
wwv_flow_imp.g_varchar2_table(344) := '6C6C3B216E2E77696474682626216E2E6865696768742626286E2E6865696768743D4D6174682E6D617828342C284E756D62657228652E686569676874297C7C3132292D3229293B76617220613D5374286E2C74293B72657475726E7B696D3A742C773A';
wwv_flow_imp.g_varchar2_table(345) := '612E772C683A612E687D7D766172204D693D7B73756D3A312C6176673A312C6D696E3A312C6D61783A312C636F756E743A317D3B66756E6374696F6E204F6928652C72297B766172206E3D4E756D6265722865292C743D4E756D6265722872293B726574';
wwv_flow_imp.g_varchar2_table(346) := '75726E2065213D3D2222262672213D3D222226262169734E614E286E2926262169734E614E2874293F6E2D743A653C723F2D313A653E723F313A307D66756E6374696F6E204C6928652C72297B766172206E3D537472696E6728652E736F757263657C7C';
wwv_flow_imp.g_varchar2_table(347) := '2222292E746F55707065724361736528292C743D4F6528652C72292C613D722E545B6E5D7C7C7B7D2C693D2841727261792E6973417272617928652E726F7773293F652E726F77733A5B652E726F77735D292E66696C74657228426F6F6C65616E292E6D';
wwv_flow_imp.g_varchar2_table(348) := '61702866756E6374696F6E2879297B72657475726E20537472696E672879292E746F55707065724361736528297D292C6F3D537472696E6728652E636F6C737C7C2222292E746F55707065724361736528292C753D537472696E6728652E76616C75657C';
wwv_flow_imp.g_varchar2_table(349) := '7C2222292E746F55707065724361736528292C733D537472696E6728652E666E7C7C2273756D22292E746F4C6F7765724361736528293B4D695B735D7C7C28733D2273756D22293B766172206C3D5B5D2C683D7B7D2C673D5B5D2C6D3D7B7D2C543D6675';
wwv_flow_imp.g_varchar2_table(350) := '6E6374696F6E2879297B72657475726E20733D3D3D22636F756E7422262621753F792E6C656E6774683A557428792C752C73297D3B696628742E666F72456163682866756E6374696F6E2879297B766172204D3D537472696E6728795B6F5D3D3D3D6E75';
wwv_flow_imp.g_varchar2_table(351) := '6C6C7C7C795B6F5D3D3D3D766F696420303F22223A795B6F5D293B4F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28682C4D297C7C28685B4D5D3D792C6C2E70757368284D29293B76617220493D692E6D6170';
wwv_flow_imp.g_varchar2_table(352) := '2866756E6374696F6E286665297B72657475726E20537472696E6728795B66655D3D3D3D6E756C6C7C7C795B66655D3D3D3D766F696420303F22223A795B66655D297D292E6A6F696E28220122292C5F3D6D5B495D3B5F7C7C285F3D6D5B495D3D7B723A';
wwv_flow_imp.g_varchar2_table(353) := '792C62793A7B7D2C616C6C3A5B5D7D2C672E70757368285F29292C285F2E62795B4D5D3D5F2E62795B4D5D7C7C5B5D292E707573682879292C5F2E616C6C2E707573682879297D292C41727261792E6973417272617928652E636F6C4F7264657229297B';
wwv_flow_imp.g_varchar2_table(354) := '76617220463D652E636F6C4F726465722E6D617028537472696E67292E66696C7465722866756E6374696F6E2879297B72657475726E204F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28682C79297D293B6C';
wwv_flow_imp.g_varchar2_table(355) := '3D462E636F6E636174286C2E66696C7465722866756E6374696F6E2879297B72657475726E20462E696E6465784F662879293C307D29297D656C736520652E736F7274436F6C7326266C2E736F7274284F69293B4E756D62657228652E6D6178436F6C73';
wwv_flow_imp.g_varchar2_table(356) := '293E302626286C3D6C2E736C69636528302C4E756D62657228652E6D6178436F6C732929293B76617220443D69722865292C503D7B7D2C623D5B5D2C70653D652E726F77546F74616C73213D3D213126266C2E6C656E6774683E313B5B22726F7773222C';
wwv_flow_imp.g_varchar2_table(357) := '22636F6C73222C2276616C7565222C22666E222C22636F6C4F72646572222C22736F7274436F6C73222C22636F6C4C6162656C222C22726F774C6162656C73222C22726F77546F74616C73222C22636F6C546F74616C73222C22746F74616C4C6162656C';
wwv_flow_imp.g_varchar2_table(358) := '222C22656D707479222C226D6178436F6C73222C2266696C746572225D2E666F72456163682866756E6374696F6E2879297B64656C65746520445B795D7D292C442E747970653D227461626C61222C692E666F72456163682866756E6374696F6E28792C';
wwv_flow_imp.g_varchar2_table(359) := '4D297B505B795D3D615B795D7C7C225641524348415232223B76617220493D28652E726F774C6162656C737C7C5B5D295B4D5D3B622E707573682849213D3D766F696420303F7B636F6C3A792C6C6162656C3A497D3A7B636F6C3A797D297D293B766172';
wwv_flow_imp.g_varchar2_table(360) := '20763D652E666D747C7C28733D3D3D22636F756E74223F22696E74223A766F69642030293B6966286C2E666F72456163682866756E6374696F6E28792C4D297B76617220493D224E52505F222B284D2B31293B505B495D3D224E554D424552222C622E70';
wwv_flow_imp.g_varchar2_table(361) := '757368287B636F6C3A492C6C6162656C3A5628652E636F6C4C6162656C7C7C227B222B6F2B227D222C722C685B795D292C666D743A762C616C69676E3A227269676874227D297D292C7065262628502E4E52505F544F54414C3D224E554D424552222C62';
wwv_flow_imp.g_varchar2_table(362) := '2E70757368287B636F6C3A224E52505F544F54414C222C6C6162656C3A652E746F74616C4C6162656C7C7C22546F74616C222C666D743A762C626F6C643A21302C616C69676E3A227269676874227D29292C442E636F6C756D6E733D622C442E5F747970';
wwv_flow_imp.g_varchar2_table(363) := '65733D502C442E5F726F77733D672E6D61702866756E6374696F6E2879297B766172204D3D7B7D3B72657475726E20692E666F72456163682866756E6374696F6E2849297B4D5B495D3D792E725B495D7D292C6C2E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(364) := '6E28492C5F297B4D5B224E52505F222B285F2B31295D3D792E62795B495D3F5428792E62795B495D293A652E656D707479213D3D766F696420303F652E656D7074793A6E756C6C7D292C70652626284D2E4E52505F544F54414C3D5428792E616C6C2929';
wwv_flow_imp.g_varchar2_table(365) := '2C4D7D292C652E636F6C546F74616C73213D3D2131262621442E746F74616C73297B76617220413D733D3D3D22636F756E74223F2273756D223A733B442E746F74616C733D622E736C69636528692E6C656E677468292E6D61702866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(366) := '79297B72657475726E7B636F6C3A792E636F6C2C666E3A417D7D297D72657475726E20442E746F74616C734C6162656C3D3D3D766F696420302626652E746F74616C4C6162656C262628442E746F74616C734C6162656C3D652E746F74616C4C6162656C';
wwv_flow_imp.g_varchar2_table(367) := '292C447D66756E6374696F6E20597428652C72297B72657475726E28657C7C5B5D292E6D61702866756E6374696F6E286E297B72657475726E206E26266E2E747970653D3D3D227069766F74223F4C69286E2C72293A6E7D297D66756E6374696F6E204C';
wwv_flow_imp.g_varchar2_table(368) := '6E28652C722C6E297B76617220743D66756E6374696F6E2869297B72657475726E2821692E666F726D6174737C7C692E666F726D6174732E696E6465784F662872293E3D3029262628216E7C7C457428692C6E29297D2C613D28652E73656374696F6E73';
wwv_flow_imp.g_varchar2_table(369) := '7C7C5B5D292E66696C7465722874293B72657475726E206E3F5974286B742861292E66696C7465722874292C6E293A617D76617220446E3D7B66696368613A312C666F726D756C6172696F3A312C7461726A657461733A312C746578746F3A312C696D61';
wwv_flow_imp.g_varchar2_table(370) := '67656E3A312C636F6469676F3A312C616C657274613A312C6C696E65613A312C7461626C613A312C6772616669636F3A312C6573706163696F3A312C7069766F743A312C636F6C756D6E61733A312C677275706F3A317D2C44693D7B6C696E65613A312C';
wwv_flow_imp.g_varchar2_table(371) := '6573706163696F3A312C636F6C756D6E61733A312C677275706F3A317D3B66756E6374696F6E20777428652C722C6E297B76617220743D66756E6374696F6E2861297B72657475726E20612626446E5B612E747970655D26262821612E666F726D617473';
wwv_flow_imp.g_varchar2_table(372) := '7C7C612E666F726D6174732E696E6465784F662872293E3D30292626457428612C6E297D3B72657475726E205974286B74282841727261792E6973417272617928652E73656374696F6E73293F652E73656374696F6E733A5B5D292E66696C7465722874';
wwv_flow_imp.g_varchar2_table(373) := '292E6D61702866756E6374696F6E2861297B696628612E736F757263657C7C21652E736F757263657C7C44695B612E747970655D2972657475726E20613B76617220693D69722861293B72657475726E20692E736F757263653D652E736F757263652C69';
wwv_flow_imp.g_varchar2_table(374) := '7D29292E66696C7465722874292C6E297D66756E6374696F6E20526E28652C72297B69662821652E656163687C7C21652E736F757263652972657475726E5B7B6374783A722C7375663A22227D5D3B766172206E3D537472696E6728652E736F75726365';
wwv_flow_imp.g_varchar2_table(375) := '292E746F55707065724361736528292C743D4F6528652C72292C613D652E6C696E6B7C7C7B7D3B72657475726E204E756D62657228652E6D6178293E30262628743D742E736C69636528302C4E756D62657228652E6D61782929292C742E6D6170286675';
wwv_flow_imp.g_varchar2_table(376) := '6E6374696F6E28692C6F297B76617220753D69722872292C733D697228722E646F637C7C7B7D292C6C3B752E533D697228722E53292C752E535B6E5D3D5B695D2C4F626A6563742E6B6579732861292E666F72456163682866756E6374696F6E2868297B';
wwv_flow_imp.g_varchar2_table(377) := '76617220673D615B685D7C7C7B7D2C6D3D537472696E672868292E746F55707065724361736528293B752E535B6D5D3D28722E535B6D5D7C7C5B5D292E66696C7465722866756E6374696F6E2854297B72657475726E204F626A6563742E6B6579732867';
wwv_flow_imp.g_varchar2_table(378) := '292E65766572792866756E6374696F6E2846297B72657475726E20537472696E6728545B462E746F55707065724361736528295D293D3D3D537472696E6728695B537472696E6728675B465D292E746F55707065724361736528295D297D297D297D293B';
wwv_flow_imp.g_varchar2_table(379) := '666F72286C20696E2069294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28692C6C29262628735B6C5D3D695B6C5D293B72657475726E20752E646F633D732C7B6374783A752C7375663A225F222B286F2B31';
wwv_flow_imp.g_varchar2_table(380) := '297D7D297D66756E6374696F6E20526928652C72297B766172206E3D7B7D2C743B666F72287420696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C74292626286E5B745D3D655B745D293B69';
wwv_flow_imp.g_varchar2_table(381) := '66285B2278222C2279222C227831222C227931222C227832222C227932225D2E666F72456163682866756E6374696F6E286F297B64656C657465206E5B6F5D7D292C6E2E747970653D3D3D22696D6167656E222626286E2E5F6D6178573D72292C6E2E74';
wwv_flow_imp.g_varchar2_table(382) := '7970653D3D3D226772616669636F22297B76617220613D6E2E77696474687C7C3132302C693D6E2E6865696768747C7C37303B613E722626286E2E77696474683D722C6E2E6865696768743D692A722F61297D72657475726E206E2E747970653D3D3D22';
wwv_flow_imp.g_varchar2_table(383) := '636F6469676F22262628537472696E67286E2E6B696E647C7C22717222292E746F4C6F7765724361736528293D3D3D227172222626286E2E73697A657C7C3330293E722626286E2E73697A653D72292C6E2E776964746826266E2E77696474683E722626';
wwv_flow_imp.g_varchar2_table(384) := '286E2E77696474683D7229292C286E2E747970653D3D3D226C696E6561227C7C6E2E747970653D3D3D22746578746F222926266E2E776964746826266E2E77696474683E722626286E2E77696474683D72292C6E7D66756E6374696F6E20797428652C72';
wwv_flow_imp.g_varchar2_table(385) := '2C6E2C74297B76617220613D2841727261792E6973417272617928652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33292C693D612E6C656E6774683B69662821692972657475726E5B5D3B766172206F3D612E6D61702866756E6374';
wwv_flow_imp.g_varchar2_table(386) := '696F6E28672C6D297B76617220543D4E756D6265722828652E7769647468737C7C5B5D295B6D5D293B72657475726E20543E303F543A3130302F697D292C753D6F2E7265647563652866756E6374696F6E28672C6D297B72657475726E20672B6D7D2C30';
wwv_flow_imp.g_varchar2_table(387) := '292C733D652E636F6C476170213D3D766F696420303F4E756D62657228652E636F6C476170293A342C6C3D742D732A28692D31292C683D303B72657475726E20612E6D61702866756E6374696F6E28672C6D297B76617220543D6C2A6F5B6D5D2F752C46';
wwv_flow_imp.g_varchar2_table(388) := '3D6B74282841727261792E697341727261792867293F673A5B5D292E66696C7465722866756E6374696F6E2850297B72657475726E205026262821502E666F726D6174737C7C502E666F726D6174732E696E6465784F662872293E3D30297D29292E6669';
wwv_flow_imp.g_varchar2_table(389) := '6C7465722866756E6374696F6E2850297B72657475726E20502626446E5B502E747970655D26262821502E666F726D6174737C7C502E666F726D6174732E696E6465784F662872293E3D30292626457428502C6E297D292E6D61702866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(390) := '2850297B72657475726E20526928502C54297D293B463D597428462C6E293B76617220443D7B783A682C773A542C736563733A467D3B72657475726E20682B3D542B732C447D297D66756E6374696F6E20457428652C72297B72657475726E20652E7479';
wwv_flow_imp.g_varchar2_table(391) := '70653D3D3D22616C65727461227C7C21652E7768656E7C7C657228652E7768656E2C722C6E756C6C297D66756E6374696F6E206A6E2865297B76617220723D7B7D2C6E3B666F72286E20696E20666E29725B6E5D3D666E5B6E5D3B76617220743D652E70';
wwv_flow_imp.g_varchar2_table(392) := '6167652626652E706167652E7468656D657C7C7B7D3B666F72286E20696E207429725B6E5D3D745B6E5D3B72657475726E20727D766172204D723D7B7D2C6B6E3D7B7D2C496E3D7B7D3B66756E6374696F6E206A6928652C72297B72657475726E214172';
wwv_flow_imp.g_varchar2_table(393) := '7261792E6973417272617928652E617070656E64297C7C72213D3D2270646622262672213D3D22616C6C223F50726F6D6973652E7265736F6C766528293A50726F6D6973652E616C6C28652E617070656E642E66696C7465722866756E6374696F6E286E';
wwv_flow_imp.g_varchar2_table(394) := '297B72657475726E206E26266E2E75726C7D292E6D61702866756E6374696F6E286E297B76617220743D2472286E2E75726C293B72657475726E20496E5B745D3F6E756C6C3A666574636828742C7B63726564656E7469616C733A2273616D652D6F7269';
wwv_flow_imp.g_varchar2_table(395) := '67696E227D292E7468656E2866756E6374696F6E2861297B69662821612E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F2063617267617220656C2050444620222B742B222028222B612E7374617475732B222922293B7265';
wwv_flow_imp.g_varchar2_table(396) := '7475726E20612E617272617942756666657228297D292E7468656E2866756E6374696F6E2861297B496E5B745D3D617D297D29297D66756E6374696F6E206B6928652C72297B766172206E3D41727261792E6973417272617928652E617070656E64293F';
wwv_flow_imp.g_varchar2_table(397) := '652E617070656E643A5B5D3B72657475726E206E2E6C656E6774683F722E6D61702866756E6374696F6E2874297B76617220613D5B5D3B72657475726E206E2E666F72456163682866756E6374696F6E2869297B696628212821697C7C21657228692E77';
wwv_flow_imp.g_varchar2_table(398) := '68656E2C742E6374782C6E756C6C2929297B696628692E75726C297B766172206F3D496E5B247228692E75726C295D3B6F2626612E70757368286F293B72657475726E7D696628692E6669656C64297B76617220753D692E736F757263653F4F6528692C';
wwv_flow_imp.g_varchar2_table(399) := '742E637478293A5B742E6374782E646F637C7C7B7D5D2C733D537472696E6728692E6669656C64292E746F55707065724361736528293B752E666F72456163682866756E6374696F6E286C297B76617220683D6C26266C5B735D3B682626612E70757368';
wwv_flow_imp.g_varchar2_table(400) := '28466128537472696E672868292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C22222929297D297D7D7D292C7B61667465723A742E746F2C6974656D733A617D7D292E66696C746572286675';
wwv_flow_imp.g_varchar2_table(401) := '6E6374696F6E2874297B72657475726E20742E6974656D732E6C656E6774687D293A5B5D7D66756E6374696F6E20496928652C72297B766172206E3D77696E646F772E5044464C69622C743D303B72657475726E206E2E504446446F63756D656E742E6C';
wwv_flow_imp.g_varchar2_table(402) := '6F61642865292E7468656E2866756E6374696F6E2861297B76617220693D50726F6D6973652E7265736F6C766528293B72657475726E20722E666F72456163682866756E6374696F6E286F297B6F2E6974656D732E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(403) := '6E2875297B693D692E7468656E2866756E6374696F6E28297B72657475726E206E2E504446446F63756D656E742E6C6F616428752C7B69676E6F7265456E6372797074696F6E3A21307D297D292E7468656E2866756E6374696F6E2873297B7265747572';
wwv_flow_imp.g_varchar2_table(404) := '6E20612E636F7079506167657328732C732E67657450616765496E64696365732829297D292E7468656E2866756E6374696F6E2873297B732E666F72456163682866756E6374696F6E286C297B612E696E7365727450616765286F2E61667465722B742C';
wwv_flow_imp.g_varchar2_table(405) := '6C292C742B2B7D297D292E63617463682866756E6374696F6E2873297B7468726F77206E6577204572726F7228224E6F207365207075646F20616E6578617220656C205044463A20222B28732626732E6D6573736167657C7C7329297D297D297D292C69';
wwv_flow_imp.g_varchar2_table(406) := '2E7468656E2866756E6374696F6E28297B72657475726E20612E7361766528297D297D292E7468656E2866756E6374696F6E2861297B72657475726E20612E6275666665722E736C69636528612E627974654F66667365742C612E627974654F66667365';
wwv_flow_imp.g_varchar2_table(407) := '742B612E627974654C656E677468297D297D7661722055693D7B7072696E743A312C6D6F646966793A312C636F70793A312C22616E6E6F742D666F726D73223A317D3B66756E6374696F6E205F6928652C722C6E297B76617220743D652E7064667C7C7B';
wwv_flow_imp.g_varchar2_table(408) := '7D2C613D6E26266E2E70646650617373776F7264213D3D766F6964203026266E2E70646650617373776F7264213D3D6E756C6C26266E2E70646650617373776F7264213D3D22223F537472696E67286E2E70646650617373776F7264293A742E70617373';
wwv_flow_imp.g_varchar2_table(409) := '776F72643F5628742E70617373776F72642C72293A22222C693D742E6F776E657250617373776F72643F5628742E6F776E657250617373776F72642C72293A22223B6966282161262621692972657475726E206E756C6C3B766172206F3D284172726179';
wwv_flow_imp.g_varchar2_table(410) := '2E6973417272617928742E7065726D697373696F6E73293F742E7065726D697373696F6E733A5B227072696E74225D292E66696C7465722866756E6374696F6E2875297B72657475726E2055695B755D7D293B72657475726E7B7573657250617373776F';
wwv_flow_imp.g_varchar2_table(411) := '72643A612C6F776E657250617373776F72643A697C7C612C757365725065726D697373696F6E733A6F7D7D66756E6374696F6E2024722865297B76617220723D77696E646F772E617065782626617065782E656E767C7C7B7D3B72657475726E20537472';
wwv_flow_imp.g_varchar2_table(412) := '696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C722E4150505F46494C45537C7C2222292E7265706C6163652822234150505F494D4147455323222C722E4150505F46494C45537C7C2222292E7265706C616365282223';
wwv_flow_imp.g_varchar2_table(413) := '574F524B53504143455F46494C455323222C722E574F524B53504143455F46494C45537C7C2222292E7265706C616365282223494D4147455F50524546495823222C722E415045585F46494C45537C7C2222297D66756E6374696F6E20556E2865297B76';
wwv_flow_imp.g_varchar2_table(414) := '617220723D6E65772055696E743841727261792865293B696628725B305D3D3D3D3133372626725B315D3D3D3D38302972657475726E7B773A28725B31365D3C3C32347C725B31375D3C3C31367C725B31385D3C3C387C725B31395D293E3E3E302C683A';
wwv_flow_imp.g_varchar2_table(415) := '28725B32305D3C3C32347C725B32315D3C3C31367C725B32325D3C3C387C725B32335D293E3E3E302C6578743A22706E67227D3B696628725B305D3D3D3D3235352626725B315D3D3D3D32313629666F7228766172206E3D323B6E3C722E6C656E677468';
wwv_flow_imp.g_varchar2_table(416) := '3B297B696628725B6E5D213D3D323535297B6E2B2B3B636F6E74696E75657D76617220743D725B6E2B315D2C613D725B6E2B325D3C3C387C725B6E2B335D3B696628743E3D3139322626743C3D323037262674213D3D313936262674213D3D3230302626';
wwv_flow_imp.g_varchar2_table(417) := '74213D3D3230342972657475726E7B683A725B6E2B355D3C3C387C725B6E2B365D2C773A725B6E2B375D3C3C387C725B6E2B385D2C6578743A226A7067227D3B6E2B3D322B617D7468726F77206E6577204572726F722822466F726D61746F2064652069';
wwv_flow_imp.g_varchar2_table(418) := '6D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E2071742865297B666F722876617220723D6E65772055696E743841727261792865292C6E3D22222C743D33323736382C613D303B613C';
wwv_flow_imp.g_varchar2_table(419) := '722E6C656E6774683B612B3D74296E2B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C722E737562617272617928612C612B7429293B72657475726E2062746F61286E297D66756E6374696F6E2042692865297B766172';
wwv_flow_imp.g_varchar2_table(420) := '20723D5B5D3B66756E6374696F6E206E2861297B28617C7C5B5D292E666F72456163682866756E6374696F6E2869297B692626692E747970653D3D3D22696D6167656E222626692E75726C262621692E6669656C642626722E7075736828692E75726C29';
wwv_flow_imp.g_varchar2_table(421) := '2C692626692E747970653D3D3D22636F6C756D6E617322262628692E636F6C737C7C5B5D292E666F7245616368286E292C692626626E5B692E747970655D26266E2828692E6669656C64737C7C5B5D292E6D61702866756E6374696F6E286F297B726574';
wwv_flow_imp.g_varchar2_table(422) := '75726E206F26266F2E626C6F636B7D29292C692626692E747970653D3D3D22677275706F2226266E28692E73656374696F6E73292C692626692E747970653D3D3D227461626C6122262628692E636F6C756D6E737C7C5B5D292E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(423) := '6E6374696F6E286F297B6F26266F2E63656C6C26266F2E63656C6C2E747970653D3D3D22696D6167656E2226266F2E63656C6C2E75726C2626216F2E63656C6C2E6669656C642626537472696E67286F2E63656C6C2E75726C292E696E6465784F662822';
wwv_flow_imp.g_varchar2_table(424) := '7B22293C302626722E70757368286F2E63656C6C2E75726C297D297D297D6E28652E73656374696F6E73292C652E62617463682626652E62617463682E73756D6D6172792626286E28652E62617463682E73756D6D6172792E73656374696F6E73292C65';
wwv_flow_imp.g_varchar2_table(425) := '2E62617463682E73756D6D6172792E6C61796F757426266E28652E62617463682E73756D6D6172792E6C61796F75742E73656374696F6E7329293B76617220743D652E706167654865616465722626652E706167654865616465722E696D6167653B7265';
wwv_flow_imp.g_varchar2_table(426) := '7475726E20742626742E75726C262621742E6669656C642626722E7075736828742E75726C292C727D66756E6374696F6E2047692865297B72657475726E2050726F6D6973652E616C6C2842692865292E6D61702866756E6374696F6E2872297B766172';
wwv_flow_imp.g_varchar2_table(427) := '206E3D24722872293B72657475726E204D725B6E5D3F6E756C6C3A6665746368286E2C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2874297B69662821742E6F6B297468726F77206E657720';
wwv_flow_imp.g_varchar2_table(428) := '4572726F7228224E6F207365207075646F20636172676172206C6120696D6167656E20222B6E2B222028222B742E7374617475732B222922293B72657475726E20742E617272617942756666657228297D292E7468656E2866756E6374696F6E2874297B';
wwv_flow_imp.g_varchar2_table(429) := '76617220613D556E2874293B4D725B6E5D3D7B6275663A742C773A612E772C683A612E682C6578743A612E6578742C646174613A22646174613A696D6167652F222B28612E6578743D3D3D226A7067223F226A706567223A22706E6722292B223B626173';
wwv_flow_imp.g_varchar2_table(430) := '6536342C222B71742874297D7D297D29297D66756E6374696F6E2078612865297B76617220723D537472696E672865292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C2222293B6966282172';
wwv_flow_imp.g_varchar2_table(431) := '2972657475726E206E756C6C3B766172206E3D226236343A222B722E6C656E6774682B223A222B722E73756273747228302C3634292B722E737562737472282D3634293B6966284D725B6E5D2972657475726E204D725B6E5D3B666F722876617220743D';
wwv_flow_imp.g_varchar2_table(432) := '61746F622872292C613D6E65772055696E7438417272617928742E6C656E677468292C693D303B693C742E6C656E6774683B692B2B29615B695D3D742E63686172436F646541742869293B766172206F3D556E28612E627566666572293B72657475726E';
wwv_flow_imp.g_varchar2_table(433) := '204D725B6E5D3D7B6275663A612E6275666665722C773A6F2E772C683A6F2E682C6578743A6F2E6578742C646174613A22646174613A696D6167652F222B286F2E6578743D3D3D226A7067223F226A706567223A22706E6722292B223B6261736536342C';
wwv_flow_imp.g_varchar2_table(434) := '222B727D2C4D725B6E5D7D66756E6374696F6E20587428652C72297B696628652E6669656C64297B766172206E3D28652E736F757263653F4F6528652C72295B305D3A722E646F63297C7C7B7D2C743D6E5B537472696E6728652E6669656C64292E746F';
wwv_flow_imp.g_varchar2_table(435) := '55707065724361736528295D3B7472797B72657475726E20743F78612874293A6E756C6C7D63617463682861297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D616765';
wwv_flow_imp.g_varchar2_table(436) := '6E20696E76C3A16C69646120656E20222B652E6669656C642C61292C6E756C6C7D7D72657475726E204D725B247228652E75726C295D7C7C6E756C6C7D66756E6374696F6E20537428652C72297B766172206E3D652E77696474687C7C34302C743D652E';
wwv_flow_imp.g_varchar2_table(437) := '6865696768747C7C6E2A722E682F722E773B72657475726E21652E77696474682626652E6865696768742626286E3D742A722E772F722E68292C652E5F6D61785726266E3E652E5F6D617857262628743D742A652E5F6D6178572F6E2C6E3D652E5F6D61';
wwv_flow_imp.g_varchar2_table(438) := '7857292C7B773A6E2C683A747D7D66756E6374696F6E2046612865297B666F722876617220723D61746F622865292C6E3D6E65772055696E7438417272617928722E6C656E677468292C743D303B743C722E6C656E6774683B742B2B296E5B745D3D722E';
wwv_flow_imp.g_varchar2_table(439) := '63686172436F646541742874293B72657475726E206E2E6275666665727D66756E6374696F6E20506128652C722C6E297B72657475726E7B6275663A466128652E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C222229292C646174613A652C';
wwv_flow_imp.g_varchar2_table(440) := '773A722C683A6E2C6578743A22706E67227D7D66756E6374696F6E204E6128652C72297B696628747970656F6620646F63756D656E743D3D22756E646566696E6564227C7C21646F63756D656E742E637265617465456C656D656E74297468726F77206E';
wwv_flow_imp.g_varchar2_table(441) := '6577204572726F722822536520726571756965726520756E206E6176656761646F72202863616E7661732920706172612067656E65726172206772C3A16669636F732E22293B766172206E3D646F63756D656E742E637265617465456C656D656E742822';
wwv_flow_imp.g_varchar2_table(442) := '63616E76617322293B72657475726E206E2E77696474683D652C6E2E6865696768743D722C6E7D766172205A743D6E756C6C3B66756E6374696F6E2048692865297B696628215A74297B5A743D5B5D3B666F722876617220723D303B723C3235363B722B';
wwv_flow_imp.g_varchar2_table(443) := '2B297B666F7228766172206E3D722C743D303B743C383B742B2B296E3D6E26313F333938383239323338345E6E3E3E3E313A6E3E3E3E313B5A745B725D3D6E3E3E3E307D7D666F722876617220613D343239343936373239352C693D303B693C652E6C65';
wwv_flow_imp.g_varchar2_table(444) := '6E6774683B692B2B29613D5A745B28615E655B695D29263235355D5E613E3E3E383B72657475726E28615E34323934393637323935293E3E3E307D66756E6374696F6E2054742865297B72657475726E5B653E3E3E3234263235352C653E3E3E31362632';
wwv_flow_imp.g_varchar2_table(445) := '35352C653E3E3E38263235352C65263235355D7D66756E6374696F6E204B7428652C72297B766172206E3D5B652E63686172436F646541742830292C652E63686172436F646541742831292C652E63686172436F646541742832292C652E63686172436F';
wwv_flow_imp.g_varchar2_table(446) := '646541742833295D2C743D6E65772055696E7438417272617928342B722E6C656E677468293B742E736574286E2C30292C742E73657428722C34293B76617220613D6E65772055696E743841727261792831322B722E6C656E677468293B72657475726E';
wwv_flow_imp.g_varchar2_table(447) := '20612E73657428547428722E6C656E677468292C30292C612E73657428742C34292C612E736574285474284869287429292C382B722E6C656E677468292C617D66756E6374696F6E207A6128652C722C6E2C74297B76617220613D4D6174682E6365696C';
wwv_flow_imp.g_varchar2_table(448) := '28652F38292B312C693D6E65772055696E7438417272617928612A72292C6F2C753B666F7228753D303B753C723B752B2B29666F72286F3D303B6F3C653B6F2B2B296E286F2C7529262628695B752A612B312B286F3E3E33295D7C3D3132383E3E286F26';
wwv_flow_imp.g_varchar2_table(449) := '3729293B76617220733D4D6174682E6365696C28692E6C656E6774682F3635353335292C6C3D6E65772055696E7438417272617928322B692E6C656E6774682B732A352B34292C683D322C673D312C6D3D302C543B666F72286C5B305D3D3132302C6C5B';
wwv_flow_imp.g_varchar2_table(450) := '315D3D312C543D303B543C733B542B2B297B76617220463D542A36353533352C443D4D6174682E6D696E2836353533352C692E6C656E6774682D46293B6C5B682B2B5D3D543D3D3D732D313F313A302C6C5B682B2B5D3D44263235352C6C5B682B2B5D3D';
wwv_flow_imp.g_varchar2_table(451) := '443E3E382C6C5B682B2B5D3D7E44263235352C6C5B682B2B5D3D7E443E3E38263235352C6C2E73657428692E737562617272617928462C462B44292C68292C682B3D447D666F7228543D303B543C692E6C656E6774683B542B2B29673D28672B695B545D';
wwv_flow_imp.g_varchar2_table(452) := '292536353532312C6D3D286D2B67292536353532313B6C2E73657428547428286D3C3C31367C67293E3E3E30292C68293B76617220503D6E65772055696E74384172726179283133292C623D2428747C7C222330303030303022293B502E736574285474';
wwv_flow_imp.g_varchar2_table(453) := '2865292C30292C502E7365742854742872292C34292C505B385D3D312C505B395D3D333B7661722070653D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31332C31302C32362C31305D292C4B74282249484452222C50292C';
wwv_flow_imp.g_varchar2_table(454) := '4B742822504C5445222C6E65772055696E74384172726179285B3235352C3235352C3235352C625B305D2C625B315D2C625B325D5D29292C4B74282249444154222C6C292C4B74282249454E44222C6E65772055696E74384172726179283029295D2C76';
wwv_flow_imp.g_varchar2_table(455) := '3D70652E7265647563652866756E6374696F6E284D2C49297B72657475726E204D2B492E6C656E6774687D2C30292C413D6E65772055696E743841727261792876292C793D303B72657475726E2070652E666F72456163682866756E6374696F6E284D29';
wwv_flow_imp.g_varchar2_table(456) := '7B412E736574284D2C79292C792B3D4D2E6C656E6774687D292C7B6275663A412E6275666665722C646174613A22646174613A696D6167652F706E673B6261736536342C222B717428412E627566666572292C773A652C683A722C6578743A22706E6722';
wwv_flow_imp.g_varchar2_table(457) := '7D7D7661722057693D22323132323232203232323132322032323232323120313231323233203132313332322031333132323220313232323133203132323331322031333232313220323231323133203232313331322032333132313220313132323332';
wwv_flow_imp.g_varchar2_table(458) := '20313232313332203132323233312031313332323220313233313232203132333232312032323332313120323231313332203232313233312032313332313220323233313132203331323133312033313132323220333231313232203332313232312033';
wwv_flow_imp.g_varchar2_table(459) := '31323231322033323231313220333232323131203231323132332032313233323120323332313231203131313332332031333131323320313331333231203131323331332031333231313320313332333131203231313331332032333131313320323331';
wwv_flow_imp.g_varchar2_table(460) := '33313120313132313333203131323333312031333231333120313133313233203131333332312031333331323120333133313231203231313333312032333131333120323133313133203231333331312032313331333120333131313233203331313332';
wwv_flow_imp.g_varchar2_table(461) := '31203333313132312033313231313320333132333131203333323131312033313431313120323231343131203433313131312031313132323420313131343232203132313132342031323134323120313431313232203134313232312031313232313420';
wwv_flow_imp.g_varchar2_table(462) := '31313234313220313232313134203132323431312031343231313220313432323131203234313231312032323131313420343133313131203234313131322031333431313120313131323432203132313134322031323132343120313134323132203132';
wwv_flow_imp.g_varchar2_table(463) := '34313132203132343231312034313132313220343231313132203432313231312032313231343120323134313231203431323132312031313131343320313131333431203133313134312031313431313320313134333131203431313131332034313133';
wwv_flow_imp.g_varchar2_table(464) := '3131203131333134312031313431333120333131313431203431313133312032313134313220323131323134203231313233322032333331313132222E73706C697428222022293B66756E6374696F6E204D612865297B653D537472696E672865292E72';
wwv_flow_imp.g_varchar2_table(465) := '65706C616365282F5B5E5C7832302D5C7837455D2F672C223F22293B666F722876617220723D5B5D2C6E2C743D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B6E3D742E657865632865293B296966286E5B315D7C7C2F5E5C64';
wwv_flow_imp.g_varchar2_table(466) := '2B242F2E746573742865292626652E6C656E67746825323D3D3D30297B76617220613D6E5B305D2C693D612E6C656E6774682D612E6C656E67746825323B722E70757368287B7365743A2243222C743A612E73756273747228302C69297D292C693C612E';
wwv_flow_imp.g_varchar2_table(467) := '6C656E6774682626722E70757368287B7365743A2242222C743A612E7375627374722869297D297D656C736520722E70757368287B7365743A2242222C743A6E5B305D7D293B766172206F3D5B5D2C753D6E756C6C3B722E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(468) := '74696F6E2867297B696628753D3D3D6E756C6C3F6F2E7075736828672E7365743D3D3D2243223F3130353A313034293A75213D3D672E73657426266F2E7075736828672E7365743D3D3D2243223F39393A313030292C753D672E7365742C672E7365743D';
wwv_flow_imp.g_varchar2_table(469) := '3D3D22432229666F7228766172206D3D303B6D3C672E742E6C656E6774683B6D2B3D32296F2E70757368282B672E742E737562737472286D2C3229293B656C736520666F722876617220543D303B543C672E742E6C656E6774683B542B2B296F2E707573';
wwv_flow_imp.g_varchar2_table(470) := '6828672E742E63686172436F646541742854292D3332297D293B666F722876617220733D6F5B305D2C6C3D313B6C3C6F2E6C656E6774683B6C2B2B29732B3D6C2A6F5B6C5D3B6F2E707573682873253130332C313036293B76617220683D5B5D3B726574';
wwv_flow_imp.g_varchar2_table(471) := '75726E206F2E666F72456163682866756E6374696F6E2867297B57695B675D2E73706C6974282222292E666F72456163682866756E6374696F6E286D2C54297B666F722876617220463D303B463C2B6D3B462B2B29682E70757368285425323D3D3D3029';
wwv_flow_imp.g_varchar2_table(472) := '7D297D292C687D66756E6374696F6E20566928652C72297B766172206E3D77696E646F772E7172636F64653B696628216E297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD612064652063C3B364';
wwv_flow_imp.g_varchar2_table(473) := '69676F732051522E22293B6E2E737472696E67546F427974657346756E637326266E2E737472696E67546F427974657346756E63735B225554462D38225D2626286E2E737472696E67546F42797465733D6E2E737472696E67546F427974657346756E63';
wwv_flow_imp.g_varchar2_table(474) := '735B225554462D38225D293B76617220743D6E28302C537472696E6728727C7C224D22292E746F5570706572436173652829293B72657475726E20742E6164644461746128537472696E67286529292C742E6D616B6528292C7B6E3A742E6765744D6F64';
wwv_flow_imp.g_varchar2_table(475) := '756C65436F756E7428292C6461726B3A66756E6374696F6E28612C69297B72657475726E20742E69734461726B28692C61297D7D7D66756E6374696F6E204A7428652C722C6E297B76617220743D6E7C7C28652E736F757263653F4F6528652C72295B30';
wwv_flow_imp.g_varchar2_table(476) := '5D3A6E756C6C293B696628216E2626652E736F75726365262621742972657475726E206E756C6C3B76617220613D5628652E76616C75652C722C74293B69662821612972657475726E206E756C6C3B76617220693D537472696E6728652E6B696E647C7C';
wwv_flow_imp.g_varchar2_table(477) := '22717222292E746F4C6F7765724361736528292C6F3D652E636F6C6F727C7C2223303030303030223B696628693D3D3D22717222297B76617220753D566928612C652E656363292C733D652E73697A657C7C33303B72657475726E7B6B696E643A227172';
wwv_flow_imp.g_varchar2_table(478) := '222C746578743A612C636F6C733A752E6E2C726F77733A752E6E2C6461726B3A752E6461726B2C773A732C683A732C636F6C6F723A6F2C71756965743A327D7D696628693D3D3D22636F646531323822297B766172206C3D4D612861292C683D652E7769';
wwv_flow_imp.g_varchar2_table(479) := '6474687C7C4D6174682E6D696E2839302C6C2E6C656E6774682A2E3333293B72657475726E7B6B696E643A22626172222C746578743A612C636F6C733A6C2E6C656E6774682C726F77733A312C6461726B3A66756E6374696F6E2867297B72657475726E';
wwv_flow_imp.g_varchar2_table(480) := '206C5B675D7D2C773A682C683A652E6865696768747C7C31322C636F6C6F723A6F2C71756965743A382C6C6162656C3A652E73686F7754657874213D3D21312C7465787453697A653A652E7465787453697A657C7C387D7D7468726F77206E6577204572';
wwv_flow_imp.g_varchar2_table(481) := '726F7228225469706F2064652063C3B36469676F206E6F20736F706F727461646F3A20222B692B222028757365207172206F20636F6465313238292E22297D66756E6374696F6E205F6E2865297B76617220723D652E71756965742C6E3D652E6B696E64';
wwv_flow_imp.g_varchar2_table(482) := '3D3D3D227172223F383A332C743D28652E636F6C732B322A72292A6E2C613D652E6B696E643D3D3D227172223F743A4D6174682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E636F6C732A6E29292C693D7A6128742C612C66756E';
wwv_flow_imp.g_varchar2_table(483) := '6374696F6E286F2C75297B76617220733D4D6174682E666C6F6F72286F2F6E292D722C6C3D652E6B696E643D3D3D227172223F4D6174682E666C6F6F7228752F6E292D723A303B72657475726E20733E3D3026266C3E3D302626733C652E636F6C732626';
wwv_flow_imp.g_varchar2_table(484) := '6C3C652E726F77732626652E6461726B28732C6C297D2C652E636F6C6F72293B72657475726E20692E776D6D3D652E772A28652E636F6C732B322A72292F652E636F6C732C692E686D6D3D652E6B696E643D3D3D227172223F692E776D6D3A652E682C69';
wwv_flow_imp.g_varchar2_table(485) := '7D7661722024693D5B2223314634453739222C2223453037423339222C2223324538423537222C2223433033393242222C2223374433433938222C2223313641303835222C2223443441433044222C2223354436443745222C2223413034303030222C22';
wwv_flow_imp.g_varchar2_table(486) := '23323837344136225D3B66756E6374696F6E20596928652C72297B766172206E3D242865293B72657475726E227267626128222B6E5B305D2B222C222B6E5B315D2B222C222B6E5B325D2B222C222B722B2229227D66756E6374696F6E20517428652C72';
wwv_flow_imp.g_varchar2_table(487) := '2C6E297B76617220743D77696E646F772E43686172743B6966282174297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD61206465206772C3A16669636F73202843686172742E6A73292E22293B76';
wwv_flow_imp.g_varchar2_table(488) := '617220613D4F6528652C72293B69662821612E6C656E6774682972657475726E206E756C6C3B76617220693D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6F3D722E545B695D7C7C7B7D2C753D4F626A656374';
wwv_flow_imp.g_varchar2_table(489) := '2E6B657973286F292C733D652E63617465676F72793F537472696E6728652E63617465676F7279292E746F55707065724361736528293A752E66696C7465722866756E6374696F6E2845297B72657475726E206F5B455D213D3D224E554D424552222626';
wwv_flow_imp.g_varchar2_table(490) := '45213D3D22444F435F4B4559227D295B305D7C7C755B305D2C6C3D28652E7365726965732626652E7365726965732E6C656E6774683F652E7365726965733A752E66696C7465722866756E6374696F6E2845297B72657475726E206F5B455D3D3D3D224E';
wwv_flow_imp.g_varchar2_table(491) := '554D42455222262645213D3D73262645213D3D22444F435F4B4559227D29292E6D61702866756E6374696F6E2845297B72657475726E20453D747970656F6620453D3D22737472696E67223F7B636F6C3A457D3A452C7B636F6C3A537472696E6728452E';
wwv_flow_imp.g_varchar2_table(492) := '636F6C292E746F55707065724361736528292C6C6162656C3A452E6C6162656C213D3D766F696420303F452E6C6162656C3A516E28452E636F6C292C636F6C6F723A452E636F6C6F727D7D292C683D652E63686172747C7C22626172222C673D683D3D3D';
wwv_flow_imp.g_varchar2_table(493) := '22706965227C7C683D3D3D22646F7567686E7574222C6D3D332C543D332E37382A6D3B672626286C3D6C2E736C69636528302C3129293B76617220463D652E77696474687C7C3132302C443D652E6865696768747C7C37302C503D4E61284D6174682E72';
wwv_flow_imp.g_varchar2_table(494) := '6F756E6428462A54292C4D6174682E726F756E6428442A5429292C623D66756E6374696F6E2845297B72657475726E20452A2E333532382A547D2C70653D652E73697A657C7C382C763D2248656C7665746963612C20417269616C2C2073616E732D7365';
wwv_flow_imp.g_varchar2_table(495) := '726966222C413D7B66616D696C793A762C73697A653A62287065297D2C793D652E636F6C6F72732626652E636F6C6F72732E6C656E6774683F652E636F6C6F72733A5B6E2E7072696D6172795D2E636F6E6361742824692E736C696365283129292C4D3D';
wwv_flow_imp.g_varchar2_table(496) := '66756E6374696F6E2845297B72657475726E204B6528452C652E666D747C7C284D6174682E726F756E642845293D3D3D453F22696E74223A226E756D3A322229297D2C493D612E6D61702866756E6374696F6E2845297B76617220433D455B735D3B7265';
wwv_flow_imp.g_varchar2_table(497) := '7475726E20433D3D6E756C6C3F22223A652E63617465676F7279466D743F4B6528432C652E63617465676F7279466D74293A537472696E672843297D292C5F3D6C2E6D61702866756E6374696F6E28452C43297B766172205A3D452E636F6C6F727C7C79';
wwv_flow_imp.g_varchar2_table(498) := '5B4325792E6C656E6774685D2C61653D7B6C6162656C3A5628452E6C6162656C2C72292C646174613A612E6D61702866756E6374696F6E284B297B76617220593D4B5B452E636F6C5D3B72657475726E20593D3D6E756C6C7C7C593D3D3D22223F6E756C';
wwv_flow_imp.g_varchar2_table(499) := '6C3A4E756D6265722859297D297D3B72657475726E20673F2861652E6261636B67726F756E64436F6C6F723D612E6D61702866756E6374696F6E284B2C59297B72657475726E20795B5925792E6C656E6774685D7D292C61652E626F72646572436F6C6F';
wwv_flow_imp.g_varchar2_table(500) := '723D2223464646464646222C61652E626F7264657257696474683D62282E3829293A683D3D3D226C696E65227C7C683D3D3D2261726561223F2861652E626F72646572436F6C6F723D5A2C61652E6261636B67726F756E64436F6C6F723D683D3D3D2261';
wwv_flow_imp.g_varchar2_table(501) := '726561223F5969285A2C2E3235293A5A2C61652E66696C6C3D683D3D3D2261726561222C61652E626F7264657257696474683D6228312E34292C61652E706F696E745261646975733D6228312E35292C61652E706F696E744261636B67726F756E64436F';
wwv_flow_imp.g_varchar2_table(502) := '6C6F723D5A2C61652E74656E73696F6E3D652E736D6F6F74683F2E33353A30293A2861652E6261636B67726F756E64436F6C6F723D5A2C61652E626F7264657257696474683D30292C61657D292C66653D7B666F6E743A412C636F6C6F723A2223343434';
wwv_flow_imp.g_varchar2_table(503) := '343434227D2C423D7B7D3B6966282167297B76617220773D7B626567696E41745A65726F3A652E626567696E41745A65726F213D3D21312C737461636B65643A2121652E737461636B65642C67726163653A652E76616C7565733F683D3D3D2268626172';
wwv_flow_imp.g_varchar2_table(504) := '223F22323525223A22313225223A302C677269643A7B636F6C6F723A2223453345374543222C6C696E6557696474683A62282E34297D2C626F726465723A7B646973706C61793A21317D2C7469636B733A7B666F6E743A412C636F6C6F723A2223343434';
wwv_flow_imp.g_varchar2_table(505) := '343434222C63616C6C6261636B3A66756E6374696F6E2845297B72657475726E204D2845297D7D7D2C68653D7B737461636B65643A2121652E737461636B65642C677269643A7B646973706C61793A21317D2C7469636B733A66657D3B423D683D3D3D22';
wwv_flow_imp.g_varchar2_table(506) := '68626172223F7B783A772C793A68657D3A7B783A68652C793A777D7D766172204C653D652E6C6567656E64213D3D766F696420303F2121652E6C6567656E643A677C7C6C2E6C656E6774683E312C48653D6E6577207428502E676574436F6E7465787428';
wwv_flow_imp.g_varchar2_table(507) := '22326422292C7B747970653A673F683A683D3D3D2268626172223F22626172223A683D3D3D2261726561223F226C696E65223A682C646174613A7B6C6162656C733A492C64617461736574733A5F7D2C706C6174666F726D3A742E4261736963506C6174';
wwv_flow_imp.g_varchar2_table(508) := '666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C616E696D6174696F6E3A21312C646576696365506978656C526174696F3A312C696E646578417869733A683D3D3D2268626172223F2279223A2278222C6C61796F75743A7B706164';
wwv_flow_imp.g_varchar2_table(509) := '64696E673A622834297D2C7363616C65733A422C706C7567696E733A7B6C6567656E643A7B646973706C61793A4C652C706F736974696F6E3A652E6C6567656E64506F736974696F6E7C7C28673F227269676874223A22626F74746F6D22292C6C616265';
wwv_flow_imp.g_varchar2_table(510) := '6C733A7B666F6E743A412C636F6C6F723A2223333333333333222C626F7857696474683A622837292C626F784865696768743A622837297D7D2C7469746C653A7B646973706C61793A2121652E7469746C652C746578743A5628652E7469746C652C7229';
wwv_flow_imp.g_varchar2_table(511) := '2C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C793A762C73697A653A622870652B32292C7765696768743A22626F6C64227D2C70616464696E673A7B626F74746F6D3A622834297D7D2C746F6F6C7469703A7B656E61626C65643A';
wwv_flow_imp.g_varchar2_table(512) := '21317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C6265666F7265447261773A66756E6374696F6E2845297B76617220433D452E6374783B432E7361766528292C432E66696C6C5374796C653D2223464646464646222C432E66696C';
wwv_flow_imp.g_varchar2_table(513) := '6C5265637428302C302C452E77696474682C452E686569676874292C432E726573746F726528297D7D2C7B69643A226E7256616C6F726573222C61667465724461746173657473447261773A66756E6374696F6E2845297B696628652E76616C75657329';
wwv_flow_imp.g_varchar2_table(514) := '7B76617220433D452E6374783B432E7361766528292C432E666F6E743D22626F6C6420222B622870652D2E35292B22707820222B762C452E646174612E64617461736574732E666F72456163682866756E6374696F6E285A2C6165297B696628452E6973';
wwv_flow_imp.g_varchar2_table(515) := '4461746173657456697369626C6528616529297B766172204B3D5A2E646174612E7265647563652866756E6374696F6E28592C5265297B72657475726E20592B2852657C7C30297D2C30293B452E676574446174617365744D657461286165292E646174';
wwv_flow_imp.g_varchar2_table(516) := '612E666F72456163682866756E6374696F6E28592C5265297B7661722057653D5A2E646174615B52655D3B6966285765213D6E756C6C297B76617220783D652E76616C7565733D3D3D22706374223F4B65284B3F57652A3130302F4B3A302C226E756D3A';
wwv_flow_imp.g_varchar2_table(517) := '3122292B2225223A4D285765293B69662867297B7661722072653D592E746F6F6C746970506F736974696F6E28293B432E66696C6C5374796C653D2223464646464646222C432E74657874416C69676E3D2263656E746572222C432E7465787442617365';
wwv_flow_imp.g_varchar2_table(518) := '6C696E653D226D6964646C65222C432E66696C6C5465787428782C72652E782C72652E79297D656C736520683D3D3D2268626172223F28432E66696C6C5374796C653D2223333333333333222C432E74657874416C69676E3D226C656674222C432E7465';
wwv_flow_imp.g_varchar2_table(519) := '7874426173656C696E653D226D6964646C65222C432E66696C6C5465787428782C592E782B6228312E35292C592E7929293A28432E66696C6C5374796C653D2223333333333333222C432E74657874416C69676E3D2263656E746572222C432E74657874';
wwv_flow_imp.g_varchar2_table(520) := '426173656C696E653D22626F74746F6D222C432E66696C6C5465787428782C592E782C592E792D6228312E352929297D7D297D7D292C432E726573746F726528297D7D7D5D7D292C4A653D502E746F4461746155524C2822696D6167652F706E6722293B';
wwv_flow_imp.g_varchar2_table(521) := '48652E64657374726F7928293B76617220533D5061284A652C502E77696474682C502E686569676874293B72657475726E20532E776D6D3D462C532E686D6D3D442C537D66756E6374696F6E204F6128652C72297B766172206E3D652E77617465726D61';
wwv_flow_imp.g_varchar2_table(522) := '726B3B696628216E7C7C747970656F66206E3D3D226F626A656374222626216572286E2E7768656E2C722C722E646F63292972657475726E206E756C6C3B747970656F66206E3D3D22737472696E67222626286E3D7B746578743A6E7D293B7661722074';
wwv_flow_imp.g_varchar2_table(523) := '3D56286E2E746578742C722C722E646F63293B72657475726E20743F7B746578743A742C636F6C6F723A6E2E636F6C6F727C7C2223433030303030222C6F7061636974793A6E2E6F706163697479213D3D766F696420303F6E2E6F7061636974793A2E31';
wwv_flow_imp.g_varchar2_table(524) := '322C616E676C653A6E2E616E676C65213D3D766F696420303F6E2E616E676C653A34352C73697A653A6E2E73697A657D3A6E756C6C7D66756E6374696F6E204C6128652C722C6E2C74297B696628652E73697A652972657475726E20652E73697A653B76';
wwv_flow_imp.g_varchar2_table(525) := '617220613D652E616E676C65253138303D3D3D303F6E2A2E383A4D6174682E73717274286E2A6E2B742A74292A2E363B72657475726E204D6174682E6D61782832302C4D6174682E6D696E283136302C3130302A612F7229297D66756E6374696F6E2071';
wwv_flow_imp.g_varchar2_table(526) := '6928652C722C6E297B76617220743D372E35362C613D4E61284D6174682E726F756E6428722A74292C4D6174682E726F756E64286E2A7429292C693D612E676574436F6E746578742822326422292C6F3D2248656C7665746963612C20417269616C2C20';
wwv_flow_imp.g_varchar2_table(527) := '73616E732D7365726966223B692E666F6E743D22626F6C6420222B3130302A2E333532382A742B22707820222B6F3B76617220753D4C6128652C692E6D6561737572655465787428652E74657874292E77696474682F742C722C6E293B692E666F6E743D';
wwv_flow_imp.g_varchar2_table(528) := '22626F6C6420222B752A2E333532382A742B22707820222B6F2C692E7472616E736C61746528612E77696474682F322C612E6865696768742F32292C692E726F74617465282D652E616E676C652A4D6174682E50492F313830292C692E676C6F62616C41';
wwv_flow_imp.g_varchar2_table(529) := '6C7068613D652E6F7061636974792C692E66696C6C5374796C653D652E636F6C6F722C692E74657874416C69676E3D2263656E746572222C692E74657874426173656C696E653D226D6964646C65222C692E66696C6C5465787428652E746578742C302C';
wwv_flow_imp.g_varchar2_table(530) := '30293B76617220733D506128612E746F4461746155524C2822696D6167652F706E6722292C612E77696474682C612E686569676874293B72657475726E20732E776D6D3D722C732E686D6D3D6E2C737D66756E6374696F6E20446128652C722C6E2C7429';
wwv_flow_imp.g_varchar2_table(531) := '7B76617220613D77696E646F772E6A737064662C692C6F3D6E2E782B2E362C753D6E2E792B2E362C733D6E2E77696474682D312E322C6C3D6E2E6865696768742D312E322C683D24284774292C673D2428436E293B696628722E696E7075743D3D3D2263';
wwv_flow_imp.g_varchar2_table(532) := '6865636B626F7822297B766172206D3D4D6174682E6D696E286C2C342E35293B752B3D286C2D6D292F322C733D6D2C6C3D6D7D652E73657444726177436F6C6F7228675B305D2C675B315D2C675B325D292C652E73657446696C6C436F6C6F7228685B30';
wwv_flow_imp.g_varchar2_table(533) := '5D2C685B315D2C685B325D292C652E7365744C696E655769647468282E32292C652E72656374286F2C752C732C6C2C22464422292C652E73657444726177436F6C6F7228302C302C30292C722E696E7075743D3D3D22636865636B626F78223F28693D6E';
wwv_flow_imp.g_varchar2_table(534) := '657720612E4163726F466F726D436865636B426F782C692E617070656172616E636553746174653D722E636865636B65643F224F6E223A224F6666222C692E76616C75653D722E636865636B65643F224F6E223A224F666622293A722E696E7075743D3D';
wwv_flow_imp.g_varchar2_table(535) := '3D226C697374223F28693D6E657720612E4163726F466F726D436F6D626F426F782C692E7365744F7074696F6E7328722E6F7074696F6E73292C692E656469743D21312C722E76616C7565262628692E76616C75653D722E76616C756529293A28693D6E';
wwv_flow_imp.g_varchar2_table(536) := '657720612E4163726F466F726D546578744669656C642C692E6D756C74696C696E653D722E696E7075743D3D3D226D756C74696C696E65222C722E6D61784C656E677468262628692E6D61784C656E6774683D722E6D61784C656E677468292C722E7661';
wwv_flow_imp.g_varchar2_table(537) := '6C7565262628692E76616C75653D722E76616C756529292C692E6669656C644E616D653D722E6E616D652C692E526563743D5B6F2C752C732C6C5D2C722E696E707574213D3D22636865636B626F7822262628692E666F6E7453697A653D742C652E5F5F';
wwv_flow_imp.g_varchar2_table(538) := '6E72466F726D53697A657C7C28652E5F5F6E72466F726D53697A653D7429292C722E726561644F6E6C79262628692E726561644F6E6C793D2130292C652E6164644669656C642869297D66756E6374696F6E2058692865297B76617220723D652E696E74';
wwv_flow_imp.g_varchar2_table(539) := '65726E616C2E6163726F666F726D506C7567696E2C6E3D722626722E6163726F466F726D44696374696F6E617279526F6F743B6966282128216E7C7C216E2E4669656C64737C7C216E2E4669656C64732E6C656E6774687C7C6E2E5F5F6E7229297B7661';
wwv_flow_imp.g_varchar2_table(540) := '7220743D223C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F48656C766574696361202F456E636F64696E67202F57696E416E7369456E636F64696E67203E3E222C613D652E696E7465726E616C';
wwv_flow_imp.g_varchar2_table(541) := '2E676574466F6E74282268656C766574696361222C226E6F726D616C22292E69643B6E2E44413D222F48656C7620222B28652E5F5F6E72466F726D53697A657C7C39292B2220546620302067222C4F626A6563742E646566696E6550726F706572747928';
wwv_flow_imp.g_varchar2_table(542) := '6E2C224452222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A223C3C202F466F6E74203C3C202F48656C7620222B742B2861262661213D3D2248656C76223F22202F222B612B2220222B743A2222292B22';
wwv_flow_imp.g_varchar2_table(543) := '202F5A614462203C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F5A61706644696E6762617473203E3E203E3E203E3E227D292C4F626A6563742E646566696E6550726F7065727479286E2C224E';
wwv_flow_imp.g_varchar2_table(544) := '656564417070656172616E636573222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A2274727565227D292C6E2E5F5F6E723D21307D7D66756E6374696F6E205A6928652C722C6E2C74297B76617220613D';
wwv_flow_imp.g_varchar2_table(545) := '652E706167657C7C7B7D2C693D6A6E2865292C6F3D692E666F6E7453697A652C753D5F6928652C725B305D7C7C7B533A7B7D2C543A7B7D7D2C74293B69662875262641727261792E6973417272617928652E617070656E64292626652E617070656E642E';
wwv_flow_imp.g_varchar2_table(546) := '6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228224E6F20736520707565646520616E657861722050444673206120756E2050444620636F6E20636F6E7472617365C3B1612E2229293B76617220733D7B';
wwv_flow_imp.g_varchar2_table(547) := '6F7269656E746174696F6E3A612E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A612E73697A657C7C226C6574746572222C636F6D70726573733A2163612865297D3B75262628732E656E637279';
wwv_flow_imp.g_varchar2_table(548) := '7074696F6E3D75293B766172206C3D6E65772077696E646F772E6A737064662E6A735044462873292C683D6C2E696E7465726E616C2E7061676553697A652E676574576964746828292C673D6C2E696E7465726E616C2E7061676553697A652E67657448';
wwv_flow_imp.g_varchar2_table(549) := '656967687428292C6D3D612E6D617267696E7C7C382C543D2428692E7072696D617279292C463D2428692E6865616454657874292C443D2428692E7A65627261292C503D2428692E746F74616C73292C623D6D2C70653D21302C763D6D2C413D6D2C793D';
wwv_flow_imp.g_varchar2_table(550) := '652E706167654865616465722626747970656F6620652E706167654865616465723D3D226F626A656374223F652E706167654865616465723A6E756C6C2C4D3D793F792E746F70213D3D766F696420303F4E756D62657228792E746F70293A4D6174682E';
wwv_flow_imp.g_varchar2_table(551) := '6D696E286D2C35293A302C493D793F4E756D62657228792E686569676874297C7C31323A302C5F3D793F4D2B492B28792E676170213D3D766F696420303F4E756D62657228792E676170293A33293A6D3B66756E6374696F6E20666528297B7661722078';
wwv_flow_imp.g_varchar2_table(552) := '3D7B6C6566743A762C72696768743A417D3B72657475726E2079262628782E746F703D5F292C787D66756E6374696F6E204228297B72657475726E206C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A62';
wwv_flow_imp.g_varchar2_table(553) := '7D66756E6374696F6E20772878297B623D4228292B28787C7C32297D66756E6374696F6E20686528782C72652C73652C64297B76617220703D782E78213D3D766F696420303F782E783A782E616C69676E3D3D3D227269676874223F682D412D72653A78';
wwv_flow_imp.g_varchar2_table(554) := '2E616C69676E3D3D3D2263656E746572223F762B28682D762D412D7265292F323A763B696628782E79213D3D766F69642030297B6428702C782E79293B72657475726E7D623D4D6174682E6D617828622C422829292C622B73653E672D6D2D3130262628';
wwv_flow_imp.g_varchar2_table(555) := '6C2E6164645061676528292C623D5F292C6428702C62292C622B3D73652B28782E676170213D3D766F696420303F782E6761703A33292C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D7D766172204C653D5B5D3B722E666F72456163';
wwv_flow_imp.g_varchar2_table(556) := '682866756E6374696F6E28782C7265297B7661722073653D722E6C656E6774683E313F225F222B2872652B31293A22223B70657C7C6C2E6164645061676528292C70653D21312C623D6D2C6C2E6C6173744175746F5461626C653D6E756C6C3B76617220';
wwv_flow_imp.g_varchar2_table(557) := '643D7B6374783A782C66726F6D3A6C2E696E7465726E616C2E6765744E756D6265724F66506167657328297D3B4C652E707573682864292C792626792E666972737450616765213D3D2131262628623D5F292C4C6E28652C22706466222C78292E666F72';
wwv_flow_imp.g_varchar2_table(558) := '456163682866756E6374696F6E20702866297B7661722069653D662E747970653B69662869653D3D3D2268656164657222297B7661722064653D4D6E28662C69292C53653D662E66696C6C3F242864652E66696C6C293A542C6A653D662E636F6C6F723F';
wwv_flow_imp.g_varchar2_table(559) := '242864652E636F6C6F72293A462C59653D4D6174682E6D61782831302E352C332E352B64652E73697A652A2E33353238292C6C723D59652B4D6174682E6D617828362C312E352B64652E73756253697A652A2E333532382A312E31292C79723D4D617468';
wwv_flow_imp.g_varchar2_table(560) := '2E6D6178284E756D62657228662E686569676874297C7C302C662E7375627469746C653F4D6174682E6D61782832302C6C722B332E35293A4D6174682E6D61782831362C59652B352E3529292C56653D79262628792E666972737450616765213D3D2131';
wwv_flow_imp.g_varchar2_table(561) := '7C7C6C2E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265723E642E66726F6D293F5F2D323A303B59652B3D56652C6C722B3D56652C6C2E73657446696C6C436F6C6F722853655B305D2C53655B315D2C';
wwv_flow_imp.g_varchar2_table(562) := '53655B325D292C6C2E7265637428302C56652C682C79722C224622292C6C2E73657454657874436F6C6F72286A655B305D2C6A655B315D2C6A655B325D292C6C2E736574466F6E742864652E666F6E745B305D2C22626F6C6422292C6C2E736574466F6E';
wwv_flow_imp.g_varchar2_table(563) := '7453697A652864652E73697A65292C6C2E74657874285628662E7469746C652C78292C6D2C59652C7B6D617857696474683A682A2E377D292C6C2E736574466F6E742864652E666F6E745B305D2C226E6F726D616C22292C6C2E736574466F6E7453697A';
wwv_flow_imp.g_varchar2_table(564) := '652864652E726967687453697A65292C662E726967687426266C2E74657874285628662E72696768742C78292C682D6D2C59652C7B616C69676E3A227269676874227D292C662E7375627469746C652626286C2E736574466F6E7453697A652864652E73';
wwv_flow_imp.g_varchar2_table(565) := '756253697A65292C6C2E74657874285628662E7375627469746C652C78292C6D2C6C7229292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C2E73657454657874436F6C6F7228302C302C30292C623D56652B79722B';
wwv_flow_imp.g_varchar2_table(566) := '342C6C2E6C6173744175746F5461626C653D6E756C6C3B72657475726E7D69662869653D3D3D22746578746F22297B7661722071653D662E79213D3D766F696420302C64723D622C66743D6C2E6C6173744175746F5461626C652C6B653D662E73697A65';
wwv_flow_imp.g_varchar2_table(567) := '7C7C31302C70723D6B652A2E333532382A28662E6C696E654865696768747C7C312E3335292C45723D28662E78213D3D766F696420303F662E783A76292B28662E696E64656E747C7C30292C4F723D662E77696474687C7C682D412D45722C53723D662E';
wwv_flow_imp.g_varchar2_table(568) := '616C69676E7C7C226C656674222C72723D2428662E636F6C6F727C7C222330303030303022292C4C723D66756E6374696F6E286A297B72657475726E286A2E627C7C662E626F6C64292626286A2E697C7C662E6974616C6963293F22626F6C646974616C';
wwv_flow_imp.g_varchar2_table(569) := '6963223A6A2E627C7C662E626F6C643F22626F6C64223A6A2E697C7C662E6974616C69633F226974616C6963223A226E6F726D616C227D2C59723D662E666F6E747C7C652E706167652626652E706167652E666F6E747C7C2268656C766574696361223B';
wwv_flow_imp.g_varchar2_table(570) := '6C2E736574466F6E7453697A65286B65292C6C2E73657454657874436F6C6F722872725B305D2C72725B315D2C72725B325D292C623D71653F662E793A4D6174682E6D617828622C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461';
wwv_flow_imp.g_varchar2_table(571) := '626C652E66696E616C593A62292C676E28662C78292E666F72456163682866756E6374696F6E286A297B76617220633D5B5D3B686E286A2C7B666F6E743A59722C636F6C6F723A662E636F6C6F722C6C696E6B3A692E6C696E6B7D292E666F7245616368';
wwv_flow_imp.g_varchar2_table(572) := '2866756E6374696F6E284C297B4C2E742E73706C6974282F28202B292F292E666F72456163682866756E6374696F6E2858297B58213D3D22222626632E70757368287B743A582C66616D3A68745B4C2E665D5B305D2C663A4C72284C292C73703A2F5E20';
wwv_flow_imp.g_varchar2_table(573) := '2B242F2E746573742858292C753A4C2E752C733A4C2E732C633A4C2E633F24284C2E63293A72722C683A4C2E687D297D297D293B766172207A3D66756E6374696F6E284C297B6C2E736574466F6E74284C2E66616D2C4C2E66293B666F72287661722058';
wwv_flow_imp.g_varchar2_table(574) := '3D302C73723D4C2E66616D2B4C2E662B6B652C42653D303B42653C4C2E742E6C656E6774683B42652B2B297B7661722061723D73722B4C2E742E636861724174284265293B6B6E5B61725D3D3D3D766F696420302626286B6E5B61725D3D6C2E67657454';
wwv_flow_imp.g_varchar2_table(575) := '6578745769647468284C2E742E6368617241742842652929292C582B3D6B6E5B61725D7D72657475726E20587D2C6E653D5B5D2C6B3D5B5D2C65653D303B666F7228632E666F72456163682866756E6374696F6E284C297B76617220583D7A284C293B69';
wwv_flow_imp.g_varchar2_table(576) := '6628214C2E7370262665652B583E4F7226266B2E6C656E677468297B666F72283B6B2E6C656E67746826266B5B6B2E6C656E6774682D315D2E73703B2965652D3D6B2E706F7028292E773B6E652E70757368287B77733A6B2C773A65657D292C6B3D5B5D';
wwv_flow_imp.g_varchar2_table(577) := '2C65653D307D4C2E73702626216B2E6C656E6774687C7C284C2E773D582C6B2E70757368284C292C65652B3D58297D293B6B2E6C656E67746826266B5B6B2E6C656E6774682D315D2E73703B2965652D3D6B2E706F7028292E773B6966286E652E707573';
wwv_flow_imp.g_varchar2_table(578) := '68287B77733A6B2C773A65652C6C6173743A21307D292C216A2E7472696D2829297B622B3D70723B72657475726E7D6E652E666F72456163682866756E6374696F6E284C297B2171652626622B70723E672D6D2D31302626286C2E616464506167652829';
wwv_flow_imp.g_varchar2_table(579) := '2C623D5F293B76617220583D4C2E77732E66696C7465722866756E6374696F6E284D65297B72657475726E204D652E73707D292E6C656E6774682C73723D53723D3D3D226A757374696679222626214C2E6C6173742626583F284F722D4C2E77292F583A';
wwv_flow_imp.g_varchar2_table(580) := '302C42653D53723D3D3D227269676874223F45722B4F722D4C2E773A53723D3D3D2263656E746572223F45722B284F722D4C2E77292F323A45722C61723D622B70722A2E37353B4C2E77732E666F72456163682866756E6374696F6E284D65297B766172';
wwv_flow_imp.g_varchar2_table(581) := '2041723D4D652E772B284D652E73703F73723A30293B6C2E73657454657874436F6C6F72284D652E635B305D2C4D652E635B315D2C4D652E635B325D292C6C2E73657444726177436F6C6F72284D652E635B305D2C4D652E635B315D2C4D652E635B325D';
wwv_flow_imp.g_varchar2_table(582) := '292C6C2E7365744C696E655769647468286B652A2E303132292C4D652E73707C7C286C2E736574466F6E74284D652E66616D2C4D652E66292C6C2E74657874284D652E742C42652C617229292C4D652E7526266C2E6C696E652842652C61722B6B652A2E';
wwv_flow_imp.g_varchar2_table(583) := '30362C42652B41722C61722B6B652A2E3036292C4D652E7326266C2E6C696E652842652C61722D6B652A2E31312C42652B41722C61722D6B652A2E3131292C4D652E6826266C2E6C696E6B2842652C622C41722C70722C7B75726C3A4D652E687D292C42';
wwv_flow_imp.g_varchar2_table(584) := '652B3D41727D292C622B3D70727D292C622B3D662E706172616772617068476170213D3D766F696420303F662E7061726167726170684761703A70722A2E357D292C6C2E73657454657874436F6C6F7228302C302C30292C71653F28623D64722C6C2E6C';
wwv_flow_imp.g_varchar2_table(585) := '6173744175746F5461626C653D6674293A6C2E6C6173744175746F5461626C653D7B66696E616C593A627D3B72657475726E7D69662869653D3D3D226C696E656122297B7661722058653D2428662E636F6C6F727C7C222330303030303022293B696628';
wwv_flow_imp.g_varchar2_table(586) := '6C2E73657444726177436F6C6F722858655B305D2C58655B315D2C58655B325D292C6C2E7365744C696E65576964746828662E746869636B6E6573737C7C2E33292C662E7831213D3D766F69642030297B6C2E6C696E6528662E78312C662E79312C662E';
wwv_flow_imp.g_varchar2_table(587) := '7832213D3D766F696420303F662E78323A662E78312C662E7932213D3D766F696420303F662E79323A662E7931293B72657475726E7D623D4D6174682E6D617828622C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66';
wwv_flow_imp.g_varchar2_table(588) := '696E616C593A62292B28662E6761704265666F72657C7C30293B766172206F723D662E77696474687C7C682D762D412C7A653D662E616C69676E3D3D3D2263656E746572223F762B28682D762D412D6F72292F323A662E616C69676E3D3D3D2272696768';
wwv_flow_imp.g_varchar2_table(589) := '74223F682D412D6F723A763B6C2E6C696E65287A652C622C7A652B6F722C62292C622B3D662E676170213D3D766F696420303F662E6761703A322C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D3B72657475726E7D69662869653D3D';
wwv_flow_imp.g_varchar2_table(590) := '3D226573706163696F22297B623D4D6174682E6D617828622C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A62292B28662E6865696768747C7C36292C6C2E6C6173744175746F5461626C653D7B6669';
wwv_flow_imp.g_varchar2_table(591) := '6E616C593A627D3B72657475726E7D69662869653D3D3D22696D6167656E22297B7661722050653D587428662C78293B6966282150652972657475726E3B766172205A653D537428662C5065292C44723D50652E6578743D3D3D226A7067223F224A5045';
wwv_flow_imp.g_varchar2_table(592) := '47223A22504E47222C54723D6D7228662C782C662E736F757263653F4F6528662C78295B305D3A6E756C6C293B686528662C5A652E772C5A652E682C66756E6374696F6E286A2C63297B6C2E616464496D6167652850652E646174612C44722C6A2C632C';
wwv_flow_imp.g_varchar2_table(593) := '5A652E772C5A652E68292C547226266C2E6C696E6B286A2C632C5A652E772C5A652E682C7B75726C3A54727D297D293B72657475726E7D69662869653D3D3D226772616669636F22297B7661722054653D517428662C782C69293B696628215465297265';
wwv_flow_imp.g_varchar2_table(594) := '7475726E3B686528662C54652E776D6D2C54652E686D6D2C66756E6374696F6E286A2C63297B6C2E616464496D6167652854652E646174612C22504E47222C6A2C632C54652E776D6D2C54652E686D6D2C766F696420302C224641535422297D293B7265';
wwv_flow_imp.g_varchar2_table(595) := '7475726E7D69662869653D3D3D22636F6469676F22297B7661722062653D4A7428662C78293B6966282162652972657475726E3B7661722043723D62652E6C6162656C3F62652E7465787453697A652A2E333532382A312E343A303B686528662C62652E';
wwv_flow_imp.g_varchar2_table(596) := '772C62652E682B43722C66756E6374696F6E286A2C63297B766172207A3D62652E772F62652E636F6C732C6E653D62652E682F62652E726F77732C6B3D242862652E636F6C6F72293B6C2E73657446696C6C436F6C6F72286B5B305D2C6B5B315D2C6B5B';
wwv_flow_imp.g_varchar2_table(597) := '325D293B666F72287661722065653D303B65653C62652E726F77733B65652B2B29666F7228766172204C3D303B4C3C62652E636F6C733B4C2B2B2969662862652E6461726B284C2C656529297B666F722876617220583D4C3B4C2B313C62652E636F6C73';
wwv_flow_imp.g_varchar2_table(598) := '262662652E6461726B284C2B312C6565293B294C2B2B3B6C2E72656374286A2B582A7A2C632B65652A6E652C284C2D582B31292A7A2C6E652B2865653C62652E726F77732D313F2E30323A30292C224622297D62652E6C6162656C2626286C2E73657446';
wwv_flow_imp.g_varchar2_table(599) := '6F6E742822636F7572696572222C226E6F726D616C22292C6C2E736574466F6E7453697A652862652E7465787453697A65292C6C2E73657454657874436F6C6F72286B5B305D2C6B5B315D2C6B5B325D292C6C2E746578742862652E746578742C6A2B62';
wwv_flow_imp.g_varchar2_table(600) := '652E772F322C632B62652E682B62652E7465787453697A652A2E333532382A312E312C7B616C69676E3A2263656E746572227D292C6C2E73657454657874436F6C6F7228302C302C3029297D293B72657475726E7D69662869653D3D3D2273616C746F22';
wwv_flow_imp.g_varchar2_table(601) := '297B6C2E6164645061676528292C623D5F2C6C2E6C6173744175746F5461626C653D7B66696E616C593A5F7D3B72657475726E7D69662869653D3D3D22636F6C756D6E617322297B7661722063653D762C49723D412C51653D797428662C22706466222C';
wwv_flow_imp.g_varchar2_table(602) := '782C682D762D41293B6966282151652E6C656E6774682972657475726E3B7661722077653D66756E6374696F6E286A297B763D63652B6A2E782C413D682D2863652B6A2E782B6A2E77297D2C55723D6C2C5F723D302C52723D21302C6A723D4D6174682E';
wwv_flow_imp.g_varchar2_table(603) := '6D617828622C422829293B69662851652E666F72456163682866756E6374696F6E286A297B6C3D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A612E6F7269656E746174696F6E7C7C22706F72747261697422';
wwv_flow_imp.g_varchar2_table(604) := '2C756E69743A226D6D222C666F726D61743A612E73697A657C7C226C6574746572227D292C7765286A292C623D6D2C6C2E6C6173744175746F5461626C653D6E756C6C2C6A2E736563732E666F72456163682870292C6C2E696E7465726E616C2E676574';
wwv_flow_imp.g_varchar2_table(605) := '4E756D6265724F66506167657328293E3126262852723D2131292C5F723D4D6174682E6D6178285F722C4D6174682E6D617828622C422829292D6D297D292C6C3D55722C763D63652C413D49722C623D6A722C6C2E6C6173744175746F5461626C653D7B';
wwv_flow_imp.g_varchar2_table(606) := '66696E616C593A6A727D2C215272297B51652E666F72456163682866756E6374696F6E286A297B6A2E736563732E666F72456163682870297D293B72657475726E7D622B5F723E672D6D2D31302626286C2E6164645061676528292C623D5F293B766172';
wwv_flow_imp.g_varchar2_table(607) := '2042723D622C4E653D623B51652E666F72456163682866756E6374696F6E286A297B7765286A292C623D42722C6C2E6C6173744175746F5461626C653D7B66696E616C593A42727D2C6A2E736563732E666F72456163682870292C4E653D4D6174682E6D';
wwv_flow_imp.g_varchar2_table(608) := '6178284E652C622C422829297D292C763D63652C413D49722C623D4E652B28662E676170213D3D766F696420303F662E6761703A31292C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D3B72657475726E7D69662869653D3D3D226772';
wwv_flow_imp.g_varchar2_table(609) := '75706F22297B7661722071723D782C78723D73652C75723D762C76723D412C74723D662E70616464696E67213D3D766F696420303F4E756D62657228662E70616464696E67293A662E626F726465727C7C662E66696C6C3F333A302C58723D66756E6374';
wwv_flow_imp.g_varchar2_table(610) := '696F6E286A297B6C2E6175746F5461626C65287B7374617274593A4D6174682E6D617828622C422829292C7468656D653A22706C61696E222C6D617267696E3A666528292C626F64793A5B5B6A5D5D2C7374796C65733A7B666F6E7453697A653A662E74';
wwv_flow_imp.g_varchar2_table(611) := '69746C6553697A657C7C6F2B322C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E362C66696C6C436F6C6F723A2428662E7469746C6546696C6C7C7C692E7072696D617279292C74657874436F6C6F723A2428662E746974';
wwv_flow_imp.g_varchar2_table(612) := '6C65436F6C6F727C7C692E6865616454657874297D7D292C623D4228297D2C67723D66756E6374696F6E286A297B76617220633D4D6174682E6D617828622C422829293B763D75722C413D76722C623D632C662E7469746C6526265872285628662E7469';
wwv_flow_imp.g_varchar2_table(613) := '746C652C7829292C623D4D6174682E6D617828622C422829292B74722C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D2C763D75722B74722C413D76722B74722C6A2E666F72456163682870293B766172207A3D4D6174682E6D617828';
wwv_flow_imp.g_varchar2_table(614) := '622C422829292B74723B72657475726E20763D75722C413D76722C7A2D637D3B526E28662C78292E666F72456163682866756E6374696F6E286A297B783D6A2E6374782C73653D78722B6A2E7375663B76617220633D777428662C22706466222C78293B';
wwv_flow_imp.g_varchar2_table(615) := '696628212821632E6C656E677468262621662E7469746C6529297B766172207A3D6C2C6E653D4D6174682E6D617828622C422829293B6C3D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A612E6F7269656E74';
wwv_flow_imp.g_varchar2_table(616) := '6174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A612E73697A657C7C226C6574746572227D292C623D6D2C6C2E6C6173744175746F5461626C653D6E756C6C3B766172206B3D67722863292C65653D6C2E696E7465';
wwv_flow_imp.g_varchar2_table(617) := '726E616C2E6765744E756D6265724F66506167657328293D3D3D313B6C3D7A2C623D6E652C6C2E6C6173744175746F5461626C653D7B66696E616C593A6E657D2C65652626662E6B656570546F676574686572213D3D21312626622B6B3E672D6D2D3130';
wwv_flow_imp.g_varchar2_table(618) := '2626286C2E6164645061676528292C623D5F2C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D293B766172204C3D622C583D6C2E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265722C';
wwv_flow_imp.g_varchar2_table(619) := '73723D682D75722D76723B69662865652626662E66696C6C297B7661722042653D2428662E66696C6C293B6C2E73657446696C6C436F6C6F722842655B305D2C42655B315D2C42655B325D292C6C2E726563742875722C4C2C73722C6B2C224622297D76';
wwv_flow_imp.g_varchar2_table(620) := '61722061723D67722863293B696628662E626F7264657226266C2E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265723D3D3D58297B766172204D653D2428662E626F72646572436F6C6F727C7C6B7229';
wwv_flow_imp.g_varchar2_table(621) := '3B6C2E73657444726177436F6C6F72284D655B305D2C4D655B315D2C4D655B325D292C6C2E7365744C696E65576964746828662E626F7264657257696474687C7C2E33292C6C2E726563742875722C4C2C73722C61722C225322292C6C2E736574447261';
wwv_flow_imp.g_varchar2_table(622) := '77436F6C6F7228302C302C30297D623D4C2B61722C6C2E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D626572213D3D58262628623D4D6174682E6D617828622C42282929292C622B3D662E676170213D3D';
wwv_flow_imp.g_varchar2_table(623) := '766F696420303F4E756D62657228662E676170293A332C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D7D7D292C783D71722C73653D78722C763D75722C413D76723B72657475726E7D69662869653D3D3D22666963686122297B7661';
wwv_flow_imp.g_varchar2_table(624) := '72206E723D4F6528662C78295B305D7C7C7B7D2C4E3D662E636F6C756D6E737C7C332C473D5B5D2C51653D7B7D2C483D21313B6F742828662E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2863297B72657475726E21632E776865';
wwv_flow_imp.g_varchar2_table(625) := '6E7C7C657228632E7768656E2C782C6E72297D292C4E292E666F72456163682866756E6374696F6E2863297B766172207A3D5B5D3B632E666F72456163682866756E6374696F6E286B297B7661722065653D6B2E663B6966286B2E656D707479297B7A2E';
wwv_flow_imp.g_varchar2_table(626) := '70757368287B636F6E74656E743A22222C636F6C5370616E3A6B2E7370616E2A322C7374796C65733A7B6C696E6557696474683A302C66696C6C436F6C6F723A21317D7D293B72657475726E7D766172204C3D75742865652C66292C583D76742865652C';
wwv_flow_imp.g_varchar2_table(627) := '782C6E72292C73723D7A722865652C782C6E72292C42653D6D722865652C782C6E72293B6966284C2E706F73213D3D226C65667422297B7661722061723D7B666F6E745374796C653A582626582E626F6C643F22626F6C64223A226E6F726D616C222C66';
wwv_flow_imp.g_varchar2_table(628) := '696C6C436F6C6F723A582626582E66696C6C3F2428582E66696C6C293A21312C74657874436F6C6F723A2428582626582E636F6C6F727C7C662E76616C7565436F6C6F727C7C222330303030303022292C68616C69676E3A582626582E616C69676E7C7C';
wwv_flow_imp.g_varchar2_table(629) := '226C656674227D3B4265262628582626582E636F6C6F727C7C2861722E74657874436F6C6F723D2428692E6C696E6B29292C483D2130293B766172204D653D7B636F6E74656E743A73722C636F6C5370616E3A6B2E7370616E2A322C7374796C65733A61';
wwv_flow_imp.g_varchar2_table(630) := '722C5F6E72487265663A42657D3B4C2E706F733D3D3D22746F70222626284D652E5F6E724C61623D7B746578743A637228562865652E6C6162656C2C782C6E72292C4C292C6C623A4C2C616C69676E3A4C2E616C69676E7C7C61722E68616C69676E7D29';
wwv_flow_imp.g_varchar2_table(631) := '2C7A2E70757368284D65293B72657475726E7D696628587C7C6B2E7370616E3E317C7C4265297B7661722041723D7B7D3B426526262841722E74657874436F6C6F723D2428692E6C696E6B292C483D2130292C582626582E616C69676E26262841722E68';
wwv_flow_imp.g_varchar2_table(632) := '616C69676E3D582E616C69676E292C582626582E626F6C6426262841722E666F6E745374796C653D22626F6C6422292C582626582E636F6C6F7226262841722E74657874436F6C6F723D2428582E636F6C6F7229292C582626582E66696C6C2626284172';
wwv_flow_imp.g_varchar2_table(633) := '2E66696C6C436F6C6F723D2428582E66696C6C29292C73723D7B636F6E74656E743A73722C7374796C65733A41722C5F6E72487265663A42657D2C6B2E7370616E3E3126262873722E636F6C5370616E3D6B2E7370616E2A322D31297D7661722069693D';
wwv_flow_imp.g_varchar2_table(634) := '562865652E6C6162656C2C782C6E72293B7A2E70757368284C2E7374796C65643F7B636F6E74656E743A63722869692C4C292C7374796C65733A5361284C297D3A69692C7372297D293B666F7228766172206E653D56742863292A323B6E653C4E2A323B';
wwv_flow_imp.g_varchar2_table(635) := '6E652B2B297A2E70757368282222293B472E70757368287A297D293B76617220573D302C553D79612866293B696628776128662E6669656C6473297C7C55297B666F7228766172206C653D302C43653D303B43653C4E3B43652B2B296C652B3D4E6E2866';
wwv_flow_imp.g_varchar2_table(636) := '2C4365293B573D4D6174682E6D61782831302C28682D762D412D6C65292F4E297D666F7228766172204F3D303B4F3C4E2A323B4F2B3D322951655B4F5D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A4E6E28662C4F2F32297D';
wwv_flow_imp.g_varchar2_table(637) := '2C5726262851655B4F2B315D3D7B63656C6C57696474683A577D292C662E6C6162656C46696C6C26262851655B4F5D2E66696C6C436F6C6F723D2428662E6C6162656C46696C6C29292C662E6C6162656C436F6C6F7226262851655B4F5D2E7465787443';
wwv_flow_imp.g_varchar2_table(638) := '6F6C6F723D2428662E6C6162656C436F6C6F7229292C662E76616C7565436F6C6F7226262851655B4F2B315D3D51655B4F2B315D7C7C7B7D2C51655B4F2B315D2E74657874436F6C6F723D2428662E76616C7565436F6C6F7229293B76617220713D7B66';
wwv_flow_imp.g_varchar2_table(639) := '6F6E7453697A653A662E73697A657C7C382E352C63656C6C50616464696E673A2E397D3B662E67726964262628712E63656C6C50616464696E673D312E362C712E76616C69676E3D226D6964646C65222C712E6C696E6557696474683D2E31352C712E6C';
wwv_flow_imp.g_varchar2_table(640) := '696E65436F6C6F723D2428662E626F72646572436F6C6F727C7C6B7229293B76617220513D7B7374617274593A622C626F64793A472C7468656D653A22706C61696E222C6D617267696E3A666528292C7374796C65733A712C636F6C756D6E5374796C65';
wwv_flow_imp.g_varchar2_table(641) := '733A51657D3B69662855297B766172206F653D712E666F6E7453697A652C75653D712E63656C6C50616464696E673B512E646964506172736543656C6C3D66756E6374696F6E2863297B766172207A3D632E73656374696F6E3D3D3D22626F6479222626';
wwv_flow_imp.g_varchar2_table(642) := '632E63656C6C2E7261772626632E63656C6C2E7261772E5F6E724C61623B7A262628632E63656C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A75652B7A6E287A2E6C622C6F65292C72696768743A75652C626F74746F6D3A75652C6C';
wwv_flow_imp.g_varchar2_table(643) := '6566743A75657D297D2C512E6469644472617743656C6C3D66756E6374696F6E2863297B766172207A3D632E73656374696F6E3D3D3D22626F6479222626632E63656C6C2E7261772626632E63656C6C2E7261772E5F6E724C61623B7A26265461286C2C';
wwv_flow_imp.g_varchar2_table(644) := '632E63656C6C2C7A2C6F652C7565297D7D69662848297B7661722049653D512E6469644472617743656C6C3B512E6469644472617743656C6C3D66756E6374696F6E2863297B632E73656374696F6E3D3D3D22626F6479222626632E63656C6C2E726177';
wwv_flow_imp.g_varchar2_table(645) := '2626632E63656C6C2E7261772E5F6E724872656626266F61286C2C632E63656C6C2C632E63656C6C2E7261772E5F6E7248726566292C4965262649652863297D7D6C2E6175746F5461626C652851292C772832293B72657475726E7D69662869653D3D3D';
wwv_flow_imp.g_varchar2_table(646) := '227461726A6574617322297B7661722067653D627428662C782C69293B6966282167652E6974656D732E6C656E6774682972657475726E3B7661722041653D28682D762D412D67652E636172644761702A2867652E6E2D3129292F67652E6E2C24653D67';
wwv_flow_imp.g_varchar2_table(647) := '652E6C6162656C53697A652A2E333532382C78653D67652E73697A652A2E333532382C55653D242867652E66696C6C292C66723D67652E616363656E743F242867652E616363656E74293A6E756C6C2C523D66723F343A332C4A3D41652D522D323B623D';
wwv_flow_imp.g_varchar2_table(648) := '4D6174682E6D617828622C422829293B666F72287661722074653D303B74653C67652E6974656D732E6C656E6774683B74652B3D67652E6E297B766172206D653D67652E6974656D732E736C6963652874652C74652B67652E6E293B6C2E736574466F6E';
wwv_flow_imp.g_varchar2_table(649) := '74282268656C766574696361222C22626F6C6422292C6C2E736574466F6E7453697A652867652E73697A65293B7661722076653D6D652E6D61702866756E6374696F6E286A297B72657475726E206C2E73706C697454657874546F53697A652853747269';
wwv_flow_imp.g_varchar2_table(650) := '6E67286A2E76616C7565292C4A297D292C62723D4D6174682E6D61782E6170706C79286E756C6C2C76652E6D61702866756E6374696F6E286A297B72657475726E204D6174682E6D617828312C6A2E6C656E677468297D29292C79653D24652A312E322B';
wwv_flow_imp.g_varchar2_table(651) := '312E352B78652A312E322A62722C45653D4D6174682E6D617828662E6865696768747C7C302C332B79652B33293B622B45653E672D6D2D31302626286C2E6164645061676528292C623D5F292C6D652E666F72456163682866756E6374696F6E286A2C63';
wwv_flow_imp.g_varchar2_table(652) := '297B766172207A3D762B632A2841652B67652E63617264476170292C6E653D242867652E6C6162656C436F6C6F72292C6B3D24286A2E636F6C6F727C7C67652E76616C7565436F6C6F72293B6C2E73657446696C6C436F6C6F722855655B305D2C55655B';
wwv_flow_imp.g_varchar2_table(653) := '315D2C55655B325D292C6C2E72656374287A2C622C41652C45652C224622292C66722626286C2E73657446696C6C436F6C6F722866725B305D2C66725B315D2C66725B325D292C6C2E72656374287A2C622C312E322C45652C22462229293B7661722065';
wwv_flow_imp.g_varchar2_table(654) := '653D622B2845652D7965292F322B24653B6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C2E736574466F6E7453697A652867652E6C6162656C53697A65292C6C2E73657454657874436F6C6F72286E655B305D2C6E65';
wwv_flow_imp.g_varchar2_table(655) := '5B315D2C6E655B325D292C6C2E74657874286C2E73706C697454657874546F53697A6528537472696E67286A2E6C6162656C292C4A295B305D7C7C22222C7A2B522C6565292C6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C';
wwv_flow_imp.g_varchar2_table(656) := '6C2E736574466F6E7453697A652867652E73697A65292C6C2E73657454657874436F6C6F72286B5B305D2C6B5B315D2C6B5B325D292C76655B635D2E666F72456163682866756E6374696F6E284C2C58297B6C2E74657874284C2C7A2B522C65652B312E';
wwv_flow_imp.g_varchar2_table(657) := '352B78652A312E30352B582A78652A312E32297D297D292C622B3D45652B2874652B67652E6E3C67652E6974656D732E6C656E6774683F67652E636172644761703A30297D6C2E736574466F6E74282268656C766574696361222C226E6F726D616C2229';
wwv_flow_imp.g_varchar2_table(658) := '2C6C2E73657454657874436F6C6F7228302C302C30292C622B3D662E676170213D3D766F696420303F662E6761703A332C6C2E6C6173744175746F5461626C653D7B66696E616C593A627D3B72657475726E7D69662869653D3D3D22666F726D756C6172';
wwv_flow_imp.g_varchar2_table(659) := '696F22297B6C2E5F5F6E72466F726D7C7C286C2E5F5F6E72466F726D3D416E2829293B7661722046723D786E28662C782C7365292C5F653D662E636F6C756D6E737C7C322C77723D5B5D2C50723D7B7D2C68723D7B7D2C5A723D662E73697A657C7C382E';
wwv_flow_imp.g_varchar2_table(660) := '353B6966286F742846722C5F65292E666F72456163682866756E6374696F6E286A297B76617220633D5B5D3B6A2E666F72456163682866756E6374696F6E286E65297B766172206B3D6E652E663B6966286E652E656D707479297B632E70757368287B63';
wwv_flow_imp.g_varchar2_table(661) := '6F6E74656E743A22222C636F6C5370616E3A6E652E7370616E2A327D293B72657475726E7D6966286C2E5F5F6E72466F726D286B2E6E616D65292C6B2E6C61622E706F73213D3D226C65667422297B50725B77722E6C656E6774682B223A222B6E652E63';
wwv_flow_imp.g_varchar2_table(662) := '6F6C2A325D3D6B3B7661722065653D7B636F6E74656E743A22222C636F6C5370616E3A6E652E7370616E2A322C7374796C65733A7B666F6E745374796C653A226E6F726D616C227D7D3B6B2E6C61622E706F733D3D3D22746F702226262865652E5F6E72';
wwv_flow_imp.g_varchar2_table(663) := '4C61623D7B746578743A6372286B2E6C6162656C2C6B2E6C6162292C6C623A6B2E6C61622C616C69676E3A6B2E6C61622E616C69676E7C7C226C656674227D292C632E70757368286565293B72657475726E7D50725B77722E6C656E6774682B223A222B';
wwv_flow_imp.g_varchar2_table(664) := '286E652E636F6C2A322B31295D3D6B2C632E70757368286B2E6C61622E7374796C65643F7B636F6E74656E743A6372286B2E6C6162656C2C6B2E6C6162292C7374796C65733A5361286B2E6C6162297D3A6B2E6C6162656C2C6E652E7370616E3E313F7B';
wwv_flow_imp.g_varchar2_table(665) := '636F6E74656E743A22222C636F6C5370616E3A6E652E7370616E2A322D317D3A2222297D293B666F7228766172207A3D5674286A292A323B7A3C5F652A323B7A2B2B29632E70757368282222293B77722E707573682863297D292C2177722E6C656E6774';
wwv_flow_imp.g_varchar2_table(666) := '682972657475726E3B666F72287661722071613D776128662E6669656C6473297C7C79612866293F4D6174682E6D61782831302C28682D762D412D28662E6C6162656C57696474687C7C3332292A5F65292F5F65293A302C6E6E3D303B6E6E3C5F652A32';
wwv_flow_imp.g_varchar2_table(667) := '3B6E6E2B3D322968725B6E6E5D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A662E6C6162656C57696474687C7C33327D2C716126262868725B6E6E2B315D3D7B63656C6C57696474683A71617D293B76617220766C3D2E3335';
wwv_flow_imp.g_varchar2_table(668) := '32382A5A722A312E333B6C2E6175746F5461626C65287B7374617274593A622C626F64793A77722C7468656D653A22706C61696E222C6D617267696E3A666528292C726F7750616765427265616B3A2261766F6964222C7374796C65733A7B666F6E7453';
wwv_flow_imp.g_varchar2_table(669) := '697A653A5A722C63656C6C50616464696E673A312E322C76616C69676E3A226D6964646C65227D2C636F6C756D6E5374796C65733A68722C646964506172736543656C6C3A66756E6374696F6E286A297B76617220633D6A2E73656374696F6E3D3D3D22';
wwv_flow_imp.g_varchar2_table(670) := '626F647922262650725B6A2E726F772E696E6465782B223A222B6A2E636F6C756D6E2E696E6465785D3B69662863297B766172207A3D6A2E63656C6C2E72617726266A2E63656C6C2E7261772E5F6E724C61622C6E653D7A3F7A6E287A2E6C622C5A7229';
wwv_flow_imp.g_varchar2_table(671) := '3A303B7A2626286A2E63656C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A312E322B6E652C72696768743A312E322C626F74746F6D3A312E322C6C6566743A312E327D292C6A2E63656C6C2E7374796C65732E6D696E43656C6C4865';
wwv_flow_imp.g_varchar2_table(672) := '696768743D632E6C696E65732A766C2B332B6E657D7D2C6469644472617743656C6C3A66756E6374696F6E286A297B76617220633D6A2E73656374696F6E3D3D3D22626F647922262650725B6A2E726F772E696E6465782B223A222B6A2E636F6C756D6E';
wwv_flow_imp.g_varchar2_table(673) := '2E696E6465785D3B69662863297B766172207A3D6A2E63656C6C2E72617726266A2E63656C6C2E7261772E5F6E724C61623B696628217A297B4461286C2C632C6A2E63656C6C2C5A72293B72657475726E7D766172206E653D7A6E287A2E6C622C5A7229';
wwv_flow_imp.g_varchar2_table(674) := '2B312E323B5461286C2C6A2E63656C6C2C7A2C5A722C312E32292C4461286C2C632C7B783A6A2E63656C6C2E782C793A6A2E63656C6C2E792B6E652D2E362C77696474683A6A2E63656C6C2E77696474682C6865696768743A6A2E63656C6C2E68656967';
wwv_flow_imp.g_varchar2_table(675) := '68742D6E652B2E367D2C5A72297D7D7D292C772832293B72657475726E7D69662869653D3D3D22616C6572746122297B4F6528662C78292E66696C7465722866756E6374696F6E286A297B72657475726E20657228662E7768656E2C782C6A297D292E73';
wwv_flow_imp.g_varchar2_table(676) := '6C69636528302C662E656163683F3939393A31292E666F72456163682866756E6374696F6E286A297B6C2E6175746F5461626C65287B7374617274593A622C7468656D653A22706C61696E222C6D617267696E3A666528292C626F64793A5B5B5628662E';
wwv_flow_imp.g_varchar2_table(677) := '746578742C782C6A295D5D2C7374796C65733A7B666F6E7453697A653A662E73697A657C7C382C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A2428707428662E636F6C6F722C782C6A297C';
wwv_flow_imp.g_varchar2_table(678) := '7C222345364543463222297D7D292C772831297D293B72657475726E7D69662869653D3D3D227461626C6122297B766172204E723D4F6528662C78293B696628214E722E6C656E6774682626662E68696465456D707479213D3D2131262621662E656D70';
wwv_flow_imp.g_varchar2_table(679) := '7479546578742972657475726E3B7661722058613D686128662C4E72293B6966285861297B58612E666F72456163682866756E6374696F6E28632C7A297B7A2626286C2E6164645061676528292C623D5F2C6C2E6C6173744175746F5461626C653D7B66';
wwv_flow_imp.g_varchar2_table(680) := '696E616C593A5F7D292C702863297D293B72657475726E7D7661722044653D677428662C782C4E72292C616E3D5B5D2C4B723D7B7D3B696628662E7469746C652626616E2E70757368285B7B636F6E74656E743A5628662E7469746C652C78292C636F6C';
wwv_flow_imp.g_varchar2_table(681) := '5370616E3A44652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E7453697A653A6F2B317D7D5D292C662E67726F757073297B76617220246E3D5B5D2C5A613D5B5D2C626C3D7B68616C69676E3A2263656E746572222C';
wwv_flow_imp.g_varchar2_table(682) := '76616C69676E3A226D6964646C65227D3B6A7428662C4465292E666F72456163682866756E6374696F6E2863297B666F7228766172207A3D632E66726F6D3B7A3C632E66726F6D2B632E636F6C733B7A2B2B29632E6761703F246E2E70757368287B636F';
wwv_flow_imp.g_varchar2_table(683) := '6E74656E743A44655B7A5D2E6C6162656C2C726F775370616E3A322C7374796C65733A7B68616C69676E3A6C742844655B7A5D2C66292C76616C69676E3A226D6964646C65227D7D293A5A612E70757368287B636F6E74656E743A44655B7A5D2E6C6162';
wwv_flow_imp.g_varchar2_table(684) := '656C2C7374796C65733A7B68616C69676E3A6C742844655B7A5D2C66297D7D293B632E6761707C7C246E2E70757368287B636F6E74656E743A632E6C6162656C2C636F6C5370616E3A632E636F6C732C7374796C65733A626C7D297D292C616E2E707573';
wwv_flow_imp.g_varchar2_table(685) := '6828246E2C5A61297D656C736520616E2E707573682844652E6D61702866756E6374696F6E2863297B72657475726E7B636F6E74656E743A632E6C6162656C2C7374796C65733A7B68616C69676E3A6C7428632C66297D7D7D29293B44652E666F724561';
wwv_flow_imp.g_varchar2_table(686) := '63682866756E6374696F6E28632C7A297B4B725B7A5D3D7B68616C69676E3A632E616C69676E7D2C632E636F6C6F722626284B725B7A5D2E74657874436F6C6F723D2428632E636F6C6F7229292C632E626F6C642626284B725B7A5D2E666F6E74537479';
wwv_flow_imp.g_varchar2_table(687) := '6C653D22626F6C6422292C632E77696474682626284B725B7A5D2E63656C6C57696474683D632E7769647468297D293B76617220776C3D536E28662C4E72292C796C3D5F742866292C456C3D2428692E67726F7570292C4A723D5B5D2C51723D5B5D2C65';
wwv_flow_imp.g_varchar2_table(688) := '743D5B5D2C6C6E3D7B7D2C473D4E722E6C656E6774683F5B5D3A5B5B7B636F6E74656E743A5628662E656D707479546578742C78292C636F6C5370616E3A44652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374';
wwv_flow_imp.g_varchar2_table(689) := '796C653A226974616C6963227D7D5D5D3B4E722E6C656E677468262628776C2E666F72456163682866756E6374696F6E2863297B696628632E6B3D3D3D226865616422297B472E70757368285B7B636F6E74656E743A697428662C632C78292C636F6C53';
wwv_flow_imp.g_varchar2_table(690) := '70616E3A44652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A632E6C766C3F2428546E28692C632E6C766C29293A456C7D7D5D292C4A722E707573682863';
wwv_flow_imp.g_varchar2_table(691) := '292C51722E70757368286E756C6C292C65742E70757368286E756C6C293B72657475726E7D696628632E6B3D3D3D2273756222297B7061286D742844652C796C2C632E726F77732C697428662C632C7829292C44652E6C656E677468292E666F72456163';
wwv_flow_imp.g_varchar2_table(692) := '682866756E6374696F6E286B297B472E70757368286B292C4A722E707573682863292C51722E70757368286E756C6C292C65742E70757368286E756C6C297D293B72657475726E7D766172207A3D6E756C6C2C6E653D6E756C6C3B44652E666F72456163';
wwv_flow_imp.g_varchar2_table(693) := '682866756E6374696F6E286B2C6565297B766172204C3D6D72286B2C782C632E72293B4C262628286E653D6E657C7C7B7D295B65655D3D4C297D292C472E707573682844652E6D61702866756E6374696F6E286B2C6565297B696628216B2E63656C6C29';
wwv_flow_imp.g_varchar2_table(694) := '72657475726E206D6E286B2C632E722C78293B766172204C3D766E286B2C632E722C782C69293B72657475726E204C262628287A3D7A7C7C7B7D295B65655D3D4C2C6C6E5B65655D3D4D6174682E6D6178286C6E5B65655D7C7C302C4C2E7729292C2222';
wwv_flow_imp.g_varchar2_table(695) := '7D29292C4A722E707573682863292C51722E70757368287A292C65742E70757368286E65297D292C4F626A6563742E6B657973286C6E292E666F72456163682866756E6374696F6E2863297B4B725B635D2E63656C6C57696474683D4D6174682E6D6178';
wwv_flow_imp.g_varchar2_table(696) := '2844655B635D2E77696474687C7C302C6C6E5B635D2B33297D29293B766172204B613D6E756C6C2C4A613D617428662E746F74616C73293B6966284A612E6C656E67746826264E722E6C656E677468297B7661722051613D662E5F616C6C526F77737C7C';
wwv_flow_imp.g_varchar2_table(697) := '4E723B4B613D7061286D742844652C4A612C51612C796E28662C782C516129292C44652E6C656E677468297D7661722047723D4E722E6C656E6774683F43692866293A6E756C6C2C7A743D28662E73697A657C7C6F292A2E333532382B322E342C65693D';
wwv_flow_imp.g_varchar2_table(698) := '7B7D2C596E3D5B5D2C72743D5B5D2C73743D666528293B477226262873742E746F703D2873742E746F70213D3D766F696420303F73742E746F703A34302F6C2E696E7465726E616C2E7363616C65466163746F72292B7A742C73742E626F74746F6D3D34';
wwv_flow_imp.g_varchar2_table(699) := '302F6C2E696E7465726E616C2E7363616C65466163746F722B7A74293B766172206F6E3D7B666F6E7453697A653A662E73697A657C7C6F2C63656C6C50616464696E673A662E677269643F312E323A2E387D2C716E3D636E28662C4465293B696628716E';
wwv_flow_imp.g_varchar2_table(700) := '2626286F6E2E76616C69676E3D716E292C44652E666F72456163682866756E6374696F6E28632C7A297B632E76616C69676E2626284B725B7A5D2E76616C69676E3D632E76616C69676E297D292C662E677269642626286F6E2E6C696E6557696474683D';
wwv_flow_imp.g_varchar2_table(701) := '2E31352C6F6E2E6C696E65436F6C6F723D2428662E626F72646572436F6C6F727C7C6B7229292C6C2E6175746F5461626C65287B7374617274593A622C6D617267696E3A73742C686561643A616E2C626F64793A472C666F6F743A4B617C7C766F696420';
wwv_flow_imp.g_varchar2_table(702) := '302C726F7750616765427265616B3A47723F2261766F6964223A766F696420302C64696444726177506167653A47723F66756E6374696F6E2863297B72742E70757368287B706167653A632E706167654E756D6265722C793A632E637572736F722E792C';
wwv_flow_imp.g_varchar2_table(703) := '6E3A596E2E6C656E6774687D297D3A766F696420302C73686F77486561643A662E7265706561744865616465723D3D3D21313F22666972737450616765223A22657665727950616765222C73686F77466F6F743A226C61737450616765222C7374796C65';
wwv_flow_imp.g_varchar2_table(704) := '733A6F6E2C686561645374796C65733A7B66696C6C436F6C6F723A542C74657874436F6C6F723A462C68616C69676E3A2263656E746572222C666F6E7453697A653A662E73697A657C7C6F7D2C666F6F745374796C65733A7B66696C6C436F6C6F723A50';
wwv_flow_imp.g_varchar2_table(705) := '2C74657874436F6C6F723A662E746F74616C73436F6C6F723F2428662E746F74616C73436F6C6F72293A302C666F6E745374796C653A22626F6C64222C68616C69676E3A227269676874227D2C616C7465726E617465526F775374796C65733A662E6272';
wwv_flow_imp.g_varchar2_table(706) := '65616B42793F7B7D3A7B66696C6C436F6C6F723A447D2C636F6C756D6E5374796C65733A4B722C646964506172736543656C6C3A66756E6374696F6E2863297B6966282128632E73656374696F6E213D3D22626F6479227C7C214E722E6C656E67746829';
wwv_flow_imp.g_varchar2_table(707) := '297B766172207A3D4A725B632E726F772E696E6465785D3B6966282128217A7C7C7A2E6B3D3D3D22686561642229297B6966287A2E6B3D3D3D2273756222297B632E63656C6C2E7374796C65732E66696C6C436F6C6F723D502C632E63656C6C2E737479';
wwv_flow_imp.g_varchar2_table(708) := '6C65732E666F6E745374796C653D22626F6C64223B72657475726E7D766172206E653D7A2E722C6B3D44655B632E636F6C756D6E2E696E6465785D3B662E627265616B4279262628632E63656C6C2E7374796C65732E66696C6C436F6C6F723D7A2E6925';
wwv_flow_imp.g_varchar2_table(709) := '323D3D3D312626662E7A65627261213D3D21313F443A5B3235352C3235352C3235355D292C65745B632E726F772E696E6465785D262665745B632E726F772E696E6465785D5B632E636F6C756D6E2E696E6465785D2626216B2E636F6C6F72262628632E';
wwv_flow_imp.g_varchar2_table(710) := '63656C6C2E7374796C65732E74657874436F6C6F723D2428692E6C696E6B29293B7661722065653D6E7428662E726F775374796C652C782C6E65293B656526262865652E66696C6C262628632E63656C6C2E7374796C65732E66696C6C436F6C6F723D24';
wwv_flow_imp.g_varchar2_table(711) := '2865652E66696C6C29292C65652E636F6C6F72262628632E63656C6C2E7374796C65732E74657874436F6C6F723D242865652E636F6C6F7229292C65652E626F6C64262628632E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229';
wwv_flow_imp.g_varchar2_table(712) := '293B766172204C3D6B26266E74286B2E63656C6C5374796C652C782C6E65293B4C2626284C2E66696C6C262628632E63656C6C2E7374796C65732E66696C6C436F6C6F723D24284C2E66696C6C29292C4C2E636F6C6F72262628632E63656C6C2E737479';
wwv_flow_imp.g_varchar2_table(713) := '6C65732E74657874436F6C6F723D24284C2E636F6C6F7229292C4C2E626F6C64262628632E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B76617220583D51725B632E726F772E696E6465785D262651725B632E726F772E';
wwv_flow_imp.g_varchar2_table(714) := '696E6465785D5B632E636F6C756D6E2E696E6465785D3B58262628632E63656C6C2E7374796C65732E6D696E43656C6C4865696768743D4D6174682E6D617828632E63656C6C2E7374796C65732E6D696E43656C6C4865696768747C7C302C582E682B32';
wwv_flow_imp.g_varchar2_table(715) := '29292C6E26266E2E70646643656C6C26266E2E70646643656C6C28632C6E652C6B2C662C78297D7D7D2C6469644472617743656C6C3A66756E6374696F6E2863297B696628632E73656374696F6E3D3D3D22626F647922297B477226262165695B632E72';
wwv_flow_imp.g_varchar2_table(716) := '6F772E696E6465785D26262865695B632E726F772E696E6465785D3D312C4A725B632E726F772E696E6465785D26264A725B632E726F772E696E6465785D2E6B3D3D3D22726F77222626596E2E70757368284A725B632E726F772E696E6465785D2E7229';
wwv_flow_imp.g_varchar2_table(717) := '293B766172207A3D51725B632E726F772E696E6465785D262651725B632E726F772E696E6465785D5B632E636F6C756D6E2E696E6465785D3B6966286F61286C2C632E63656C6C2C65745B632E726F772E696E6465785D262665745B632E726F772E696E';
wwv_flow_imp.g_varchar2_table(718) := '6465785D5B632E636F6C756D6E2E696E6465785D2C2144655B632E636F6C756D6E2E696E6465785D2E63656C6C292C21217A297B766172206E653D44655B632E636F6C756D6E2E696E6465785D2E616C69676E2C6B3D6E653D3D3D226C656674223F632E';
wwv_flow_imp.g_varchar2_table(719) := '63656C6C2E782B313A6E653D3D3D227269676874223F632E63656C6C2E782B632E63656C6C2E77696474682D7A2E772D313A632E63656C6C2E782B28632E63656C6C2E77696474682D7A2E77292F322C65653D44655B632E636F6C756D6E2E696E646578';
wwv_flow_imp.g_varchar2_table(720) := '5D2E76616C69676E7C7C716E2C4C3D65653D3D3D22746F70223F632E63656C6C2E792B313A65653D3D3D22626F74746F6D223F632E63656C6C2E792B632E63656C6C2E6865696768742D7A2E682D313A632E63656C6C2E792B28632E63656C6C2E686569';
wwv_flow_imp.g_varchar2_table(721) := '6768742D7A2E68292F323B6C2E616464496D616765287A2E696D2E646174612C7A2E696D2E6578743D3D3D226A7067223F224A504547223A22504E47222C6B2C4C2C7A2E772C7A2E682C766F696420302C224641535422297D7D7D7D292C477226267274';
wwv_flow_imp.g_varchar2_table(722) := '2E6C656E6774683E31297B666F72287661722072693D6C2E6C6173744175746F5461626C652C536C3D6C2E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265722C586E3D72692E73657474696E67732E6D';
wwv_flow_imp.g_varchar2_table(723) := '617267696E2E6C6566742C5A6E3D72692E636F6C756D6E732E6D61702866756E6374696F6E2863297B72657475726E20632E77696474687D292C546C3D5A6E2E7265647563652866756E6374696F6E28632C7A297B72657475726E20632B7A7D2C30292C';
wwv_flow_imp.g_varchar2_table(724) := '74693D662E73697A657C7C6F2C4B6E3D662E746F74616C73436F6C6F723F2428662E746F74616C73436F6C6F72293A5B302C302C305D2C6E693D66756E6374696F6E28632C7A2C6E652C6B297B6C2E736574506167652863292C6C2E73657446696C6C43';
wwv_flow_imp.g_varchar2_table(725) := '6F6C6F7228505B305D2C505B315D2C505B325D292C6C2E7265637428586E2C7A2C546C2C7A742C224622292C6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C6C2E736574466F6E7453697A65287469292C6C2E736574546578';
wwv_flow_imp.g_varchar2_table(726) := '74436F6C6F72284B6E5B305D2C4B6E5B315D2C4B6E5B325D293B7661722065653D7A2B7A742F322B74692A2E333532382A2E33352C4C3D586E3B6C2E746578742856286E652C782C7B434F554E543A6B2E6C656E6774687D292C586E2B312C6565292C44';
wwv_flow_imp.g_varchar2_table(727) := '652E666F72456163682866756E6374696F6E28582C7372297B582E636F6C2626776E2847722E636F6C732C582E636F6C2926266C2E74657874284B65285574286B2C582E636F6C2C2273756D22292C582E666D747C7C226D6F6E657922292C4C2B5A6E5B';
wwv_flow_imp.g_varchar2_table(728) := '73725D2D312C65652C7B616C69676E3A227269676874227D292C4C2B3D5A6E5B73725D7D297D2C64743D303B64743C72742E6C656E6774682D313B64742B2B297B7661722061693D596E2E736C69636528302C72745B64745D2E6E293B6E692872745B64';
wwv_flow_imp.g_varchar2_table(729) := '745D2E706167652C72745B64745D2E792C47722E6C6162656C2C6169292C6E692872745B64742B315D2E706167652C73742E746F702D7A742C47722E6C6162656C46726F6D2C6169297D6C2E7365745061676528536C292C6C2E736574466F6E74282268';
wwv_flow_imp.g_varchar2_table(730) := '656C766574696361222C226E6F726D616C22292C6C2E73657454657874436F6C6F7228302C302C30297D7728662E6761707C7C33297D7D292C642E746F3D6C2E696E7465726E616C2E6765744E756D6265724F66506167657328297D292C4C652E666F72';
wwv_flow_imp.g_varchar2_table(731) := '456163682866756E6374696F6E2878297B7661722072653D4F6128652C782E637478293B6966287265297B6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C6C2E736574466F6E7453697A6528313030293B7661722073653D4C';
wwv_flow_imp.g_varchar2_table(732) := '612872652C6C2E6765745465787457696474682872652E74657874292C682C67292C643D72652E616E676C652A4D6174682E50492F3138302C703D242872652E636F6C6F72293B6C2E736574466F6E7453697A65287365293B666F722876617220663D6C';
wwv_flow_imp.g_varchar2_table(733) := '2E6765745465787457696474682872652E74657874292C69653D73652A2E333532382A2E372C64653D682F322D662F322A4D6174682E636F732864292B69652F322A4D6174682E73696E2864292C53653D672F322B662F322A4D6174682E73696E286429';
wwv_flow_imp.g_varchar2_table(734) := '2B69652F322A4D6174682E636F732864292C6A653D782E66726F6D3B6A653C3D782E746F3B6A652B2B296C2E73657450616765286A65292C6C2E736176654772617068696373537461746528292C6C2E736574475374617465286E6577206C2E47537461';
wwv_flow_imp.g_varchar2_table(735) := '7465287B6F7061636974793A72652E6F7061636974797D29292C6C2E73657454657874436F6C6F7228705B305D2C705B315D2C705B325D292C6C2E746578742872652E746578742C64652C53652C7B616E676C653A72652E616E676C657D292C6C2E7265';
wwv_flow_imp.g_varchar2_table(736) := '73746F72654772617068696373537461746528293B6C2E73657454657874436F6C6F7228302C302C30297D7D293B7661722048653D652E666F6F7465722C4A653D6C2E696E7465726E616C2E6765744E756D6265724F66506167657328292C533D725B30';
wwv_flow_imp.g_varchar2_table(737) := '5D7C7C7B533A7B7D2C543A7B7D7D2C453D66756E6374696F6E28782C7265297B7661722073653D4C652E66696C7465722866756E6374696F6E2864297B72657475726E2072653E3D642E66726F6D262672653C3D642E746F7D295B305D7C7C7B66726F6D';
wwv_flow_imp.g_varchar2_table(738) := '3A312C746F3A4A657D3B72657475726E20537472696E672878292E7265706C616365282F5C7B444F4350414745535C7D2F672C73652E746F2D73652E66726F6D2B31292E7265706C616365282F5C7B444F43504147455C7D2F672C72652D73652E66726F';
wwv_flow_imp.g_varchar2_table(739) := '6D2B31297D3B69662879297B76617220433D4F6E2879292C5A3D792E6C696E65213D3D21313B4C652E666F72456163682866756E6374696F6E2878297B666F72287661722072653D416128792C782E637478292C73653D782E66726F6D3B73653C3D782E';
wwv_flow_imp.g_varchar2_table(740) := '746F3B73652B2B296966282128792E6669727374506167653D3D3D2131262673653D3D3D782E66726F6D29297B6966286C2E73657450616765287365292C792E66696C6C297B76617220643D2428792E66696C6C293B6C2E73657446696C6C436F6C6F72';
wwv_flow_imp.g_varchar2_table(741) := '28645B305D2C645B315D2C645B325D292C6C2E7265637428302C4D2C682C492C224622297D76617220703D6D2C663D682D6D2C69653D72653F43612879293A22223B69662872652626286C2E616464496D6167652872652E696D2E646174612C72652E69';
wwv_flow_imp.g_varchar2_table(742) := '6D2E6578743D3D3D226A7067223F224A504547223A22504E47222C69653D3D3D227269676874223F682D6D2D72652E773A69653D3D3D2263656E746572223F28682D72652E77292F323A6D2C4D2B28492D72652E68292F322C72652E772C72652E68292C';
wwv_flow_imp.g_varchar2_table(743) := '69653D3D3D227269676874223F663D682D6D2D72652E772D333A69653D3D3D226C65667422262628703D6D2B72652E772B3329292C5B226C656674222C2263656E746572222C227269676874225D2E666F72456163682866756E6374696F6E285365297B';
wwv_flow_imp.g_varchar2_table(744) := '766172206A653D435B53655D3B6966282128216A657C7C53653D3D3D2263656E74657222262669653D3D3D2263656E7465722229297B7661722059653D452856286A652E746578742C782E637478292E7265706C616365282F5C7B50414745535C7D2F67';
wwv_flow_imp.g_varchar2_table(745) := '2C4A65292E7265706C616365282F5C7B504147455C7D2F672C7365292C7365292E73706C697428225C6E22292C6C723D6A652E73697A652A2E333532382A312E322C79723D4D2B28492D6C722A59652E6C656E677468292F322B6A652E73697A652A2E33';
wwv_flow_imp.g_varchar2_table(746) := '3532382A2E392C56653D24286A652E636F6C6F72293B6C2E736574466F6E74282268656C766574696361222C6A652E626F6C643F22626F6C64223A226E6F726D616C22292C6C2E736574466F6E7453697A65286A652E73697A65292C6C2E736574546578';
wwv_flow_imp.g_varchar2_table(747) := '74436F6C6F722856655B305D2C56655B315D2C56655B325D292C59652E666F72456163682866756E6374696F6E2871652C6472297B6C2E746578742871652C53653D3D3D226C656674223F703A53653D3D3D2263656E746572223F682F323A662C79722B';
wwv_flow_imp.g_varchar2_table(748) := '64722A6C722C7B616C69676E3A53657D297D297D7D292C5A297B7661722064653D2428792E6C696E65436F6C6F727C7C692E7072696D617279293B6C2E73657444726177436F6C6F722864655B305D2C64655B315D2C64655B325D292C6C2E7365744C69';
wwv_flow_imp.g_varchar2_table(749) := '6E65576964746828792E6C696E6557696474687C7C2E33292C6C2E6C696E65286D2C4D2B492C682D6D2C4D2B49297D7D7D292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C2E73657454657874436F6C6F7228302C';
wwv_flow_imp.g_varchar2_table(750) := '302C30292C6C2E73657444726177436F6C6F7228302C302C30297D6966284865297B666F72287661722061653D313B61653C3D4A653B61652B2B297B6C2E73657450616765286165292C6C2E736574466F6E74282268656C766574696361222C226E6F72';
wwv_flow_imp.g_varchar2_table(751) := '6D616C22292C6C2E736574466F6E7453697A652848652E73697A657C7C37293B766172204B3D2428692E6D75746564293B6C2E73657454657874436F6C6F72284B5B305D2C4B5B315D2C4B5B325D293B76617220593D66756E6374696F6E2878297B7265';
wwv_flow_imp.g_varchar2_table(752) := '7475726E2045285628782C53292E7265706C61636528227B504147457D222C6165292E7265706C61636528227B50414745537D222C4A65292C6165297D3B69662848652E6C656674297B7661722052653D6C2E73706C697454657874546F53697A652859';
wwv_flow_imp.g_varchar2_table(753) := '2848652E6C656674292C682A2E3738293B6C2E746578742852652C6D2C672D342D2852652E6C656E6774682D31292A2848652E73697A657C7C37292A2E34297D48652E726967687426266C2E7465787428592848652E7269676874292C682D6D2C672D35';
wwv_flow_imp.g_varchar2_table(754) := '2C7B616C69676E3A227269676874227D297D6C2E73657454657874436F6C6F7228302C302C30297D652E7469746C6526266C2E73657450726F70657274696573287B7469746C653A5628652E7469746C652C53297D292C5869286C293B7661722057653D';
wwv_flow_imp.g_varchar2_table(755) := '6B6928652C4C65293B72657475726E2057652E6C656E6774683F2177696E646F772E5044464C69627C7C2177696E646F772E5044464C69622E504446446F63756D656E743F50726F6D6973652E72656A656374286E6577204572726F7228224E6F207365';
wwv_flow_imp.g_varchar2_table(756) := '207075646F20636172676172206C61206C6962726572C3AD613A207064662D6C69622229293A4969286C2E6F75747075742822617272617962756666657222292C5765293A50726F6D6973652E7265736F6C7665286C2E6F757470757428226172726179';
wwv_flow_imp.g_varchar2_table(757) := '6275666665722229297D66756E6374696F6E20426E2865297B72657475726E20537472696E6728652E6C6162656C7C7C652E6E616D65292E7265706C616365282F5C732B2F672C222022292E73756273747228302C3332297D66756E6374696F6E205261';
wwv_flow_imp.g_varchar2_table(758) := '28652C722C6E297B76617220743D7B7374796C653A227468696E222C636F6C6F723A7B617267623A466528436E297D7D3B652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267';
wwv_flow_imp.g_varchar2_table(759) := '623A4665284774297D7D2C652E626F726465723D7B746F703A742C6C6566743A742C626F74746F6D3A742C72696768743A747D2C652E70726F74656374696F6E3D7B6C6F636B65643A2121722E726561644F6E6C797D2C652E616C69676E6D656E743D7B';
wwv_flow_imp.g_varchar2_table(760) := '766572746963616C3A722E6C696E65733E313F22746F70223A226D6964646C65222C686F72697A6F6E74616C3A722E696E7075743D3D3D22636865636B626F78223F2263656E746572223A226C656674222C77726170546578743A722E696E7075743D3D';
wwv_flow_imp.g_varchar2_table(761) := '3D226D756C74696C696E65227D2C722E696E7075743D3D3D22636865636B626F78223F28652E76616C75653D722E636865636B65643F48743A57742C652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B';
wwv_flow_imp.g_varchar2_table(762) := '3A21312C666F726D756C61653A5B2722272B57742B222C222B48742B2722275D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A426E2872292C6572726F723A22456C696A6120222B57742B22206F20222B48742B222E22';
wwv_flow_imp.g_varchar2_table(763) := '7D293A28652E76616C75653D722E76616C75653D3D3D22223F6E756C6C3A722E76616C75652C652E6E756D466D743D2240222C722E696E7075743D3D3D226C697374223F652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C';
wwv_flow_imp.g_varchar2_table(764) := '6C6F77426C616E6B3A21302C666F726D756C61653A5B6E28722E6F7074696F6E73295D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A426E2872292C6572726F723A22456C696A6120756E2076616C6F72206465206C61';
wwv_flow_imp.g_varchar2_table(765) := '206C697374612E227D3A722E6D61784C656E677468262628652E6461746156616C69646174696F6E3D7B747970653A22746578744C656E677468222C6F70657261746F723A226C6573735468616E4F72457175616C222C616C6C6F77426C616E6B3A2130';
wwv_flow_imp.g_varchar2_table(766) := '2C666F726D756C61653A5B722E6D61784C656E6774685D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A426E2872292C6572726F723A224DC3A178696D6F20222B722E6D61784C656E6774682B22206361726163746572';
wwv_flow_imp.g_varchar2_table(767) := '65732E227D29292C652E6E616D653D722E6E616D657D66756E6374696F6E204B692865297B76617220723D652E646566696E65644E616D65732C6E3D7226264F626A6563742E6765744F776E50726F706572747944657363726970746F72284F626A6563';
wwv_flow_imp.g_varchar2_table(768) := '742E67657450726F746F747970654F662872292C226D6F64656C22293B216E7C7C216E2E6765747C7C722E5F5F6E727C7C284F626A6563742E646566696E6550726F706572747928722C226D6F64656C222C7B636F6E666967757261626C653A21302C67';
wwv_flow_imp.g_varchar2_table(769) := '65743A66756E6374696F6E28297B72657475726E206E2E6765742E63616C6C2874686973292E6D61702866756E6374696F6E2874297B72657475726E7B6E616D653A742E6E616D652C72616E6765733A742E72616E6765732E6D61702866756E6374696F';
wwv_flow_imp.g_varchar2_table(770) := '6E2861297B76617220693D2F5E285B5E27215D2B2921282E2B29242F2E657865632861293B72657475726E20693F2227222B695B315D2B222721222B695B325D3A617D297D7D297D2C7365743A66756E6374696F6E2874297B6E2E7365742E63616C6C28';
wwv_flow_imp.g_varchar2_table(771) := '746869732C74297D7D292C722E5F5F6E723D2130297D66756E6374696F6E204A6928652C722C6E2C74297B76617220613D6E65772077696E646F772E457863656C4A532E576F726B626F6F6B2C693D6A6E2865292C6F3D7B7D2C753D6D6128652C74292C';
wwv_flow_imp.g_varchar2_table(772) := '733D416E28292C6C3D5B5D2C683D7B77733A6E756C6C2C6E3A302C7265663A7B7D7D3B612E63726561746F723D226E6F76615265706F7274223B76617220673D652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C7378';
wwv_flow_imp.g_varchar2_table(773) := '2626652E786C73782E73686565744E616D657C7C225265706F727465227D5D2C6D3D4C6E28652C22786C737822292C543D652E706167657C7C7B7D2C463D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F';
wwv_flow_imp.g_varchar2_table(774) := '723A7B617267623A466528692E7072696D617279297D7D3B66756E6374696F6E20442876297B666F722876617220413D646E2876292E7265706C616365282F5B5C5B5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C793D41';
wwv_flow_imp.g_varchar2_table(775) := '2C4D3D323B6F5B792E746F4C6F7765724361736528295D3B29793D412E73756273747228302C33312D537472696E67284D292E6C656E6774682D31292B225F222B4D2C4D2B2B3B72657475726E206F5B792E746F4C6F7765724361736528295D3D21302C';
wwv_flow_imp.g_varchar2_table(776) := '797D66756E6374696F6E20502876297B72657475726E7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A46652876297D7D7D66756E6374696F6E20622876297B76617220413D7B737479';
wwv_flow_imp.g_varchar2_table(777) := '6C653A227468696E222C636F6C6F723A7B617267623A466528767C7C6B72297D7D3B72657475726E7B746F703A412C6C6566743A412C626F74746F6D3A412C72696768743A417D7D66756E6374696F6E2070652876297B76617220413D762E6A6F696E28';
wwv_flow_imp.g_varchar2_table(778) := '222C22293B696628412E6C656E6774683C3D3235302626212F5B2C225D2F2E7465737428762E6A6F696E28222229292972657475726E2722272B412B2722273B696628682E7265665B415D2972657475726E20682E7265665B415D3B682E77737C7C2868';
wwv_flow_imp.g_varchar2_table(779) := '2E77733D612E616464576F726B7368656574284428226E725F6C697374617322292C7B73746174653A2268696464656E227D29293B76617220793D2B2B682E6E3B762E666F72456163682866756E6374696F6E28492C5F297B682E77732E67657443656C';
wwv_flow_imp.g_varchar2_table(780) := '6C285F2B312C79292E76616C75653D497D293B766172204D3D682E77732E676574436F6C756D6E2879292E6C65747465723B72657475726E20682E7265665B415D3D2227222B682E77732E6E616D652B22272124222B4D2B2224313A24222B4D2B222422';
wwv_flow_imp.g_varchar2_table(781) := '2B762E6C656E6774682C682E7265665B415D7D72657475726E20722E666F72456163682866756E6374696F6E28762C41297B76617220793D722E6C656E6774683E313F225F222B28412B31293A22223B672E666F72456163682866756E6374696F6E284D';
wwv_flow_imp.g_varchar2_table(782) := '297B76617220493D56284D2E6E616D652C76293B592626722E6C656E6774683E31262628493D56284D2E6D657267654E616D657C7C28672E6C656E6774683E313F227B444F432E444F435F4B45597D20222B4D2E6E616D653A227B444F432E444F435F4B';
wwv_flow_imp.g_varchar2_table(783) := '45597D22292C7629293B766172205F3D612E616464576F726B736865657428442849292C7B7061676553657475703A7B6F7269656E746174696F6E3A542E6F7269656E746174696F6E7C7C22706F727472616974222C706170657253697A653A542E7369';
wwv_flow_imp.g_varchar2_table(784) := '7A653D3D3D226C6567616C223F353A542E73697A653D3D3D226134223F393A312C666974546F506167653A21302C666974546F57696474683A312C666974546F4865696768743A307D7D292C66653D4D2E73656374696F6E733F4D2E73656374696F6E73';
wwv_flow_imp.g_varchar2_table(785) := '2E6D61702866756E6374696F6E2864297B72657475726E20747970656F6620643D3D226E756D626572223F6D5B645D3A6D2E66696C7465722866756E6374696F6E2870297B72657475726E20702E69643D3D3D647D295B305D7D292E66696C7465722842';
wwv_flow_imp.g_varchar2_table(786) := '6F6F6C65616E293A6D3B66653D5974286B742866652E66696C7465722866756E6374696F6E2864297B72657475726E20457428642C76297D29292E66696C7465722866756E6374696F6E2864297B72657475726E2821642E666F726D6174737C7C642E66';
wwv_flow_imp.g_varchar2_table(787) := '6F726D6174732E696E6465784F662822786C737822293E3D30292626457428642C76297D292C76293B76617220423D342C773D312C68653D7B7D2C4C653D302C48653D6E756C6C2C4A653D6E756C6C2C533D21312C453D66756E6374696F6E2864297B72';
wwv_flow_imp.g_varchar2_table(788) := '657475726E20642E7265647563652866756E6374696F6E28702C66297B72657475726E20662E747970653D3D3D22636F6C756D6E6173223F4D6174682E6D617828702C797428662C22786C7378222C762C313030292E7265647563652866756E6374696F';
wwv_flow_imp.g_varchar2_table(789) := '6E2869652C6465297B72657475726E2069652B452864652E73656373292B317D2C2D3129293A662E747970653D3D3D22677275706F223F4D6174682E6D617828702C4528777428662C22786C7378222C762929293A4D6174682E6D617828702C662E7479';
wwv_flow_imp.g_varchar2_table(790) := '70653D3D3D227461626C61223F677428662C762C4F6528662C7629292E6C656E6774683A662E747970653D3D3D226669636861223F28662E636F6C756D6E737C7C33292A323A662E747970653D3D3D22666F726D756C6172696F223F28662E636F6C756D';
wwv_flow_imp.g_varchar2_table(791) := '6E737C7C32292A323A662E747970653D3D3D227461726A65746173223F627428662C762C69292E6E3A662E747970653D3D3D22746578746F227C7C662E747970653D3D3D22616C65727461223F343A32297D2C32297D3B66652E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(792) := '6E6374696F6E2864297B642E747970653D3D3D22636F6C756D6E617322262628423D4D6174682E6D617828422C797428642C22786C7378222C762C313030292E7265647563652866756E6374696F6E28702C66297B72657475726E20702B4528662E7365';
wwv_flow_imp.g_varchar2_table(793) := '6373292B317D2C2D312929292C642E747970653D3D3D227461626C61222626284C652B2B2C423D4D6174682E6D617828422C677428642C762C4F6528642C7629292E6C656E67746829292C642E747970653D3D3D22666963686122262628423D4D617468';
wwv_flow_imp.g_varchar2_table(794) := '2E6D617828422C28642E636F6C756D6E737C7C33292A3229292C642E747970653D3D3D22666F726D756C6172696F22262628423D4D6174682E6D617828422C28642E636F6C756D6E737C7C32292A3229292C642E747970653D3D3D227461726A65746173';
wwv_flow_imp.g_varchar2_table(795) := '22262628423D4D6174682E6D617828422C627428642C762C69292E6E29292C642E747970653D3D3D22677275706F22262628423D4D6174682E6D617828422C4528777428642C22786C7378222C76292929297D293B66756E6374696F6E204328642C7029';
wwv_flow_imp.g_varchar2_table(796) := '7B76617220663D537472696E6728703D3D6E756C6C3F22223A70292E6C656E6774683B642B3D5A2C68655B645D3D4D6174682E6D696E2836302C4D6174682E6D61782868655B645D7C7C382C662B3229297D766172205A3D302C61653D21313B66756E63';
wwv_flow_imp.g_varchar2_table(797) := '74696F6E204B28642C70297B72657475726E205F2E67657443656C6C28642C702B5A297D66756E6374696F6E205928642C702C662C6965297B5F2E6D6572676543656C6C7328642C702B5A2C662C69652B5A297D66756E6374696F6E20526528642C7029';
wwv_flow_imp.g_varchar2_table(798) := '7B76617220663D5F2E676574526F772864293B662E6865696768743D4D6174682E6D617828662E6865696768747C7C302C70297D66756E6374696F6E20576528642C702C662C69652C6465297B7661722053653D612E616464496D616765287B62617365';
wwv_flow_imp.g_varchar2_table(799) := '36343A642E646174612C657874656E73696F6E3A642E6578743D3D3D226A7067223F226A706567223A22706E67227D293B5F2E616464496D6167652853652C7B746C3A7B636F6C3A5A2C726F773A772D317D2C6578743A7B77696474683A702A332E3738';
wwv_flow_imp.g_varchar2_table(800) := '2C6865696768743A662A332E37387D2C68797065726C696E6B733A64653F7B68797065726C696E6B3A64652C746F6F6C7469703A64657D3A766F696420307D292C772B3D4D6174682E6365696C28662A332E37382F3230292B2869653F303A31297D6675';
wwv_flow_imp.g_varchar2_table(801) := '6E6374696F6E207828642C702C662C6965297B5928772C312C772C42293B7661722064653D4B28772C31293B64652E76616C75653D642C64652E66696C6C3D702C64652E666F6E743D662C64652E616C69676E6D656E743D7B766572746963616C3A226D';
wwv_flow_imp.g_varchar2_table(802) := '6964646C65222C77726170546578743A21307D2C69652626526528772C61653F4D6174682E6D61782869652C4D6174682E6365696C28537472696E6728647C7C2222292E6C656E6774682F4D6174682E6D61782831362C422A3929292A3135293A696529';
wwv_flow_imp.g_varchar2_table(803) := '2C772B2B7D69662866652E666F72456163682866756E6374696F6E20642870297B76617220663D702E747970653B696628663D3D3D22636F6C756D6E617322297B7661722069653D772C64653D772C53653D5A2C6A653D422C59653D302C6C723D61653B';
wwv_flow_imp.g_varchar2_table(804) := '61653D21302C797428702C22786C7378222C762C313030292E666F72456163682866756E6374696F6E284E297B76617220473D45284E2E73656373293B5A3D53652B59652C423D472C773D69652C4E2E736563732E666F72456163682864292C64653D4D';
wwv_flow_imp.g_varchar2_table(805) := '6174682E6D61782864652C77292C59652B3D472B317D292C5A3D53652C423D6A652C61653D6C722C773D64653B72657475726E7D696628663D3D3D22677275706F22297B7661722079723D762C56653D793B526E28702C76292E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(806) := '6E6374696F6E284E297B763D4E2E6374782C793D56652B4E2E7375663B76617220473D777428702C22786C7378222C76292C483D773B696628212821472E6C656E677468262621702E7469746C6529297B702E7469746C65262678285628702E7469746C';
wwv_flow_imp.g_varchar2_table(807) := '652C76292C5028702E7469746C6546696C6C7C7C692E7072696D617279292C7B626F6C643A21302C636F6C6F723A7B617267623A466528702E7469746C65436F6C6F727C7C692E6865616454657874297D7D2C3230292C472E666F72456163682864293B';
wwv_flow_imp.g_varchar2_table(808) := '76617220573D4D6174682E6D617828482C772D31293B696628702E66696C6C29666F722876617220553D483B553C3D573B552B2B29666F7228766172206C653D313B6C653C3D423B6C652B2B297B7661722043653D4B28552C6C65293B282143652E6669';
wwv_flow_imp.g_varchar2_table(809) := '6C6C7C7C43652E66696C6C2E74797065213D3D227061747465726E222926262843652E66696C6C3D5028702E66696C6C29297D696628702E626F72646572297B666F7228766172204F3D7B7374796C653A227468696E222C636F6C6F723A7B617267623A';
wwv_flow_imp.g_varchar2_table(810) := '466528702E626F72646572436F6C6F727C7C6B72297D7D2C713D483B713C3D573B712B2B29666F722876617220513D313B513C3D423B512B2B29696628212871213D3D48262671213D3D57262651213D3D31262651213D3D4229297B766172206F653D4B';
wwv_flow_imp.g_varchar2_table(811) := '28712C51292C75653D6972286F652E626F726465727C7C7B7D293B713D3D3D4826262875652E746F703D4F292C713D3D3D5726262875652E626F74746F6D3D4F292C513D3D3D3126262875652E6C6566743D4F292C513D3D3D4226262875652E72696768';
wwv_flow_imp.g_varchar2_table(812) := '743D4F292C6F652E626F726465723D75657D7D773D572B312B28702E6761703D3D3D303F303A31297D7D292C763D79722C793D56653B72657475726E7D696628663D3D3D2268656164657222297B7661722071653D4D6E28702C69292C64723D702E6669';
wwv_flow_imp.g_varchar2_table(813) := '6C6C3F502871652E66696C6C293A462C66743D7B617267623A46652871652E636F6C6F72297D2C6B653D7B626F6C643A21302C73697A653A71652E73697A652C636F6C6F723A66747D2C70723D7B73697A653A702E7375627469746C653F71652E737562';
wwv_flow_imp.g_varchar2_table(814) := '53697A653A71652E726967687453697A652C636F6C6F723A66747D3B702E666F6E742626286B652E6E616D653D70722E6E616D653D71652E666F6E745B315D292C78285628702E7469746C652C76292C64722C6B652C4D6174682E6D61782832362C4D61';
wwv_flow_imp.g_varchar2_table(815) := '74682E726F756E642871652E73697A652A312E382929292C28702E72696768747C7C702E7375627469746C6529262678285B5628702E7375627469746C652C76292C5628702E72696768742C76295D2E66696C74657228426F6F6C65616E292E6A6F696E';
wwv_flow_imp.g_varchar2_table(816) := '28222020207C20202022292C64722C70722C4D6174682E6D61782831362C4D6174682E726F756E642870722E73697A652A312E382929292C772B2B7D656C736520696628663D3D3D22746578746F2229676E28702C76292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(817) := '74696F6E284E297B5928772C312C772C42293B76617220473D4B28772C31292C483D686E284E2C7B666F6E743A702E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A702E636F6C6F722C6C696E6B3A692E6C696E6B7D29';
wwv_flow_imp.g_varchar2_table(818) := '3B472E76616C75653D7B72696368546578743A482E6D61702866756E6374696F6E2855297B72657475726E7B746578743A552E742C666F6E743A7B626F6C643A212128552E627C7C702E626F6C64292C6974616C69633A212128552E697C7C702E697461';
wwv_flow_imp.g_varchar2_table(819) := '6C6963292C756E6465726C696E653A552E757C7C766F696420302C737472696B653A552E737C7C766F696420302C6E616D653A68745B552E665D5B315D2C636F6C6F723A552E633F7B617267623A466528552E63297D3A766F696420302C73697A653A70';
wwv_flow_imp.g_varchar2_table(820) := '2E73697A657C7C31307D7D7D297D3B76617220573D482E66696C7465722866756E6374696F6E2855297B72657475726E20552E687D295B305D3B57262628472E76616C75653D7B746578743A472E76616C75652C68797065726C696E6B3A572E687D292C';
wwv_flow_imp.g_varchar2_table(821) := '472E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22746F70222C686F72697A6F6E74616C3A702E616C69676E3D3D3D226A757374696679223F226A757374696679223A702E616C69676E7C7C226C656674227D2C5265';
wwv_flow_imp.g_varchar2_table(822) := '28772C4D6174682E6D61782831352C4D6174682E6365696C284E2E6C656E6774682F2861653F4D6174682E6D61782831362C422A39293A31343029292A313529292C772B2B7D293B656C736520696628663D3D3D226573706163696F2229772B2B3B656C';
wwv_flow_imp.g_varchar2_table(823) := '736520696628663D3D3D22696D6167656E22297B7661722045723D587428702C76293B6966284572297B766172204F723D537428702C4572293B57652845722C4F722E772C4F722E682C21312C6D7228702C762C702E736F757263653F4F6528702C7629';
wwv_flow_imp.g_varchar2_table(824) := '5B305D3A6E756C6C29297D7D656C736520696628663D3D3D226772616669636F22297B7661722053723D517428702C762C69293B5372262657652853722C53722E776D6D2C53722E686D6D297D656C736520696628663D3D3D22636F6469676F22297B76';
wwv_flow_imp.g_varchar2_table(825) := '61722072723D4A7428702C76293B6966287272297B766172204C723D5F6E287272293B6966285765284C722C4C722E776D6D2C4C722E686D6D2C72722E6C6162656C292C72722E6C6162656C297B7661722059723D4B28772C31293B59722E76616C7565';
wwv_flow_imp.g_varchar2_table(826) := '3D72722E746578742C59722E666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A72722E7465787453697A657D2C772B3D327D7D7D656C736520696628663D3D3D2273616C746F2229772B2B3B656C736520696628663D3D3D2266';
wwv_flow_imp.g_varchar2_table(827) := '6963686122297B7661722058653D4F6528702C76295B305D7C7C7B7D2C6F723D702E636F6C756D6E737C7C332C7A653D313B6F742828702E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E284E297B72657475726E214E2E7768656E';
wwv_flow_imp.g_varchar2_table(828) := '7C7C6572284E2E7768656E2C762C5865297D292C6F72292E666F72456163682866756E6374696F6E284E2C47297B473E302626772B2B3B76617220483D4E2E736F6D652866756E6374696F6E2857297B72657475726E21572E656D707479262675742857';
wwv_flow_imp.g_varchar2_table(829) := '2E662C70292E706F733D3D3D22746F70227D293B4E2E666F72456163682866756E6374696F6E2857297B69662821572E656D707479297B76617220553D572E663B7A653D312B572E636F6C2A323B766172206C653D757428552C70292C43653D7A652B57';
wwv_flow_imp.g_varchar2_table(830) := '2E7370616E2A322D312C4F3D6E756C6C2C712C513D5628552E6C6162656C2C762C5865293B6966286C652E706F733D3D3D226C65667422297B6966284F3D4B28772C7A65292C713D4B28772C7A652B31292C4F2E76616C75653D637228512C6C65292C4F';
wwv_flow_imp.g_varchar2_table(831) := '2E666F6E743D702E6C6162656C436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A466528702E6C6162656C436F6C6F72297D7D3A7B626F6C643A21307D2C702E6C6162656C46696C6C2626284F2E66696C6C3D5028702E6C6162656C46';
wwv_flow_imp.g_varchar2_table(832) := '696C6C29292C702E76616C7565436F6C6F72262628712E666F6E743D7B636F6C6F723A7B617267623A466528702E76616C7565436F6C6F72297D7D292C702E677269642626284F2E626F726465723D712E626F726465723D6228702E626F72646572436F';
wwv_flow_imp.g_varchar2_table(833) := '6C6F72292C4F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C28572E7370616E3E317C7C48292626285928772C7A652B312C483F772B313A772C4365292C702E677269642929666F722876';
wwv_flow_imp.g_varchar2_table(834) := '6172206F653D7A652B323B6F653C3D43653B6F652B2B294B28772C6F65292E626F726465723D6228702E626F72646572436F6C6F72293B482626285928772C7A652C772B312C7A65292C4F2E616C69676E6D656E743D7B766572746963616C3A226D6964';
wwv_flow_imp.g_varchar2_table(835) := '646C65222C77726170546578743A21307D292C6C652E7374796C656426262474284F2C6C652C2131297D656C73657B7661722075653D6C652E706F733D3D3D22746F70222626483F772B313A772C49653D6C652E706F733D3D3D226E6F6E65222626483F';
wwv_flow_imp.g_varchar2_table(836) := '772B313A75653B6966286C652E706F733D3D3D22746F7022297B4F3D4B28772C7A65292C4F2E76616C75653D637228512C6C65292C43653E7A6526265928772C7A652C772C4365292C702E677269642626284F2E626F726465723D6228702E626F726465';
wwv_flow_imp.g_varchar2_table(837) := '72436F6C6F7229293B7661722067653D767428552C762C5865293B2474284F2C6C652C21302C6765262667652E616C69676E297D713D4B2875652C7A65292C2843653E7A657C7C49653E7565292626592875652C7A652C49652C4365292C702E76616C75';
wwv_flow_imp.g_varchar2_table(838) := '65436F6C6F72262628712E666F6E743D7B636F6C6F723A7B617267623A466528702E76616C7565436F6C6F72297D7D292C702E67726964262628712E626F726465723D6228702E626F72646572436F6C6F7229297D7661722041653D2F5E5C7B5B5E7D7C';
wwv_flow_imp.g_varchar2_table(839) := '5D2B5C7D242F2E7465737428552E76616C75657C7C222229262621552E6D61703F577228762C552E76616C75652E736C69636528312C2D31292C5865293A6E756C6C3B4F7428416529262621447428552E666D74293F28712E76616C75653D41652C552E';
wwv_flow_imp.g_varchar2_table(840) := '666D743D3D3D226D6F6E6579223F712E6E756D466D743D22232C2323302E3030223A487228552E666D7429262628712E6E756D466D743D706E28552E666D7429292C712E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A55';
wwv_flow_imp.g_varchar2_table(841) := '2E666D743D3D3D22646174652226267474284165293F28712E76616C75653D7474284165292C712E6E756D466D743D2264642F6D6D2F79797979222C712E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A712E76616C7565';
wwv_flow_imp.g_varchar2_table(842) := '3D7A7228552C762C5865293B7661722024653D6D7228552C762C5865293B2465262628712E76616C75653D7B746578743A537472696E67287A7228552C762C586529292C68797065726C696E6B3A24657D2C712E666F6E743D7B756E6465726C696E653A';
wwv_flow_imp.g_varchar2_table(843) := '21302C636F6C6F723A7B617267623A466528692E6C696E6B297D7D292C702E67726964262628712E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674222C766572746963616C3A226D6964646C65222C77726170546578743A21307D29';
wwv_flow_imp.g_varchar2_table(844) := '3B7661722078653D767428552C762C5865293B6966287865297B69662878652E626F6C647C7C78652E636F6C6F72297B7661722055653D7B7D3B4F626A6563742E6B65797328712E666F6E747C7C7B7D292E666F72456163682866756E6374696F6E2852';
wwv_flow_imp.g_varchar2_table(845) := '297B55655B525D3D712E666F6E745B525D7D292C78652E626F6C6426262855652E626F6C643D2130292C78652E636F6C6F7226262855652E636F6C6F723D7B617267623A46652878652E636F6C6F72297D292C712E666F6E743D55657D69662878652E61';
wwv_flow_imp.g_varchar2_table(846) := '6C69676E297B7661722066723D7B7D3B4F626A6563742E6B65797328712E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2852297B66725B525D3D712E616C69676E6D656E745B525D7D292C66722E686F72697A6F6E7461';
wwv_flow_imp.g_varchar2_table(847) := '6C3D78652E616C69676E2C712E616C69676E6D656E743D66727D78652E66696C6C262628712E66696C6C3D502878652E66696C6C29297D6C652E706F733D3D3D226C656674223F2843287A652C51292C572E7370616E3D3D3D31262643287A652B312C7A';
wwv_flow_imp.g_varchar2_table(848) := '7228552C762C58652929293A572E7370616E3D3D3D31262643287A652B312C537472696E67287A7228552C762C586529292E73756273747228302C343029297D7D292C482626772B2B7D292C772B3D327D656C736520696628663D3D3D227461726A6574';
wwv_flow_imp.g_varchar2_table(849) := '61732229666F72287661722050653D627428702C762C69292C5A653D303B5A653C50652E6974656D732E6C656E6774683B5A652B3D50652E6E297B7661722044723D313B50652E6974656D732E736C696365285A652C5A652B50652E6E292E666F724561';
wwv_flow_imp.g_varchar2_table(850) := '63682866756E6374696F6E284E2C47297B76617220483D4B28772C472B31292C573D4B28772B312C472B31292C553D50652E616363656E743F7B6C6566743A7B7374796C653A22746869636B222C636F6C6F723A7B617267623A46652850652E61636365';
wwv_flow_imp.g_varchar2_table(851) := '6E74297D7D7D3A7B7D3B482E76616C75653D4E2E6C6162656C2C482E666F6E743D7B73697A653A50652E6C6162656C53697A652B312C636F6C6F723A7B617267623A46652850652E6C6162656C436F6C6F72297D7D2C572E76616C75653D4E2E76616C75';
wwv_flow_imp.g_varchar2_table(852) := '652C572E666F6E743D7B626F6C643A21302C73697A653A50652E73697A652C636F6C6F723A7B617267623A4665284E2E636F6C6F727C7C50652E76616C7565436F6C6F72297D7D2C5B482C575D2E666F72456163682866756E6374696F6E286C65297B6C';
wwv_flow_imp.g_varchar2_table(853) := '652E66696C6C3D502850652E66696C6C292C6C652E626F726465723D552C6C652E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C696E64656E743A312C77726170546578743A21307D7D292C4328472B312C4E2E6C6162656C29';
wwv_flow_imp.g_varchar2_table(854) := '2C4328472B312C537472696E67284E2E76616C7565292E73756273747228302C3430292B2220202020202022292C44723D4D6174682E6D61782844722C4D6174682E6365696C28537472696E67284E2E76616C7565292E6C656E6774682F343029297D29';
wwv_flow_imp.g_varchar2_table(855) := '2C526528772C3136292C526528772B312C4D6174682E726F756E642850652E73697A652A312E37292A4472292C772B3D337D656C736520696628663D3D3D22666F726D756C6172696F22297B7661722054723D702E636F6C756D6E737C7C322C54653D31';
wwv_flow_imp.g_varchar2_table(856) := '2C62653D786E28702C762C79293B6F742862652C5472292E666F72456163682866756E6374696F6E284E2C47297B473E302626772B2B3B76617220483D4E2E736F6D652866756E6374696F6E2857297B72657475726E21572E656D7074792626572E662E';
wwv_flow_imp.g_varchar2_table(857) := '6C61622E706F733D3D3D22746F70227D293B4E2E666F72456163682866756E6374696F6E2857297B69662821572E656D707479297B76617220553D572E662C6C653D552E6C61623B54653D312B572E636F6C2A322C7328552E6E616D65293B7661722043';
wwv_flow_imp.g_varchar2_table(858) := '653D54652B572E7370616E2A322D312C4F3D552E696E7075743D3D3D22636865636B626F78223F22223A552E76616C75652E6C656E6774683E32303F552E76616C75653A6E6577204172726179283231292E6A6F696E28227822293B6966286C652E706F';
wwv_flow_imp.g_varchar2_table(859) := '733D3D3D226C65667422297B76617220713D4B28772C5465292C513D4B28772C54652B31293B712E76616C75653D637228552E6C6162656C2C6C65292C712E666F6E743D7B626F6C643A21307D2C712E616C69676E6D656E743D7B766572746963616C3A';
wwv_flow_imp.g_varchar2_table(860) := '552E6C696E65733E313F22746F70223A226D6964646C65227D2C28572E7370616E3E317C7C482926265928772C54652B312C483F772B313A772C4365292C4826265928772C54652C772B312C5465292C6C652E7374796C65642626247428712C6C652C21';
wwv_flow_imp.g_varchar2_table(861) := '31292C526128512C552C7065292C552E6C696E65733E312626526528483F772B313A772C31352A552E6C696E6573292C432854652C552E6C6162656C292C572E7370616E3D3D3D312626432854652B312C4F293B72657475726E7D766172206F653D6C65';
wwv_flow_imp.g_varchar2_table(862) := '2E706F733D3D3D22746F70222626483F772B313A772C75653D6C652E706F733D3D3D226E6F6E65222626483F772B313A6F653B6966286C652E706F733D3D3D22746F7022297B7661722049653D4B28772C5465293B49652E76616C75653D637228552E6C';
wwv_flow_imp.g_varchar2_table(863) := '6162656C2C6C65292C43653E546526265928772C54652C772C4365292C24742849652C6C652C2130297D2843653E54657C7C75653E6F6529262659286F652C54652C75652C4365292C5261284B286F652C5465292C552C7065292C552E6C696E65733E31';
wwv_flow_imp.g_varchar2_table(864) := '262652652875652C31352A552E6C696E6573292C572E7370616E3D3D3D312626432854652B312C4F297D7D292C482626772B2B7D292C62652E6C656E677468262628533D21302C772B3D32297D656C736520696628663D3D3D22616C6572746122294F65';
wwv_flow_imp.g_varchar2_table(865) := '28702C76292E66696C7465722866756E6374696F6E284E297B72657475726E20657228702E7768656E2C762C4E297D292E736C69636528302C702E656163683F3939393A31292E666F72456163682866756E6374696F6E284E297B78285628702E746578';
wwv_flow_imp.g_varchar2_table(866) := '742C762C4E292C5028707428702E636F6C6F722C762C4E297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C772B2B3B656C736520696628663D3D3D227461626C6122297B7661722043723D4F6528702C76293B6966282143722E';
wwv_flow_imp.g_varchar2_table(867) := '6C656E6774682626702E68696465456D707479213D3D2131262621702E656D707479546578742972657475726E3B7661722063653D677428702C762C4372293B696628702E7469746C65297B5928772C312C772C63652E6C656E677468293B7661722049';
wwv_flow_imp.g_varchar2_table(868) := '723D4B28772C31293B49722E76616C75653D5628702E7469746C652C76292C49722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A466528692E6865616454657874297D7D2C49722E66696C6C3D462C772B2B7D7661722051653D773B';
wwv_flow_imp.g_varchar2_table(869) := '696628702E67726F757073297B7661722077653D313B6A7428702C6365292E666F72456163682866756E6374696F6E284E297B4E2E636F6C733E312626214E2E67617026265928772C77652C772C77652B4E2E636F6C732D31293B76617220473D4B2877';
wwv_flow_imp.g_varchar2_table(870) := '2C7765293B6966284E2E676170297B666F722876617220483D303B483C4E2E636F6C733B482B2B297B5928772C77652B482C772B312C77652B48293B76617220573D4B28772C77652B48293B572E76616C75653D63655B4E2E66726F6D2B485D2E6C6162';
wwv_flow_imp.g_varchar2_table(871) := '656C2C572E66696C6C3D462C572E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A466528692E6865616454657874297D7D2C572E616C69676E6D656E743D7B686F72697A6F6E74616C3A6C742863655B4E2E66726F6D2B485D2C70292C';
wwv_flow_imp.g_varchar2_table(872) := '766572746963616C3A226D6964646C65222C77726170546578743A21307D2C432877652B482C63655B4E2E66726F6D2B485D2E6C6162656C297D77652B3D4E2E636F6C733B72657475726E7D472E76616C75653D4E2E6C6162656C7C7C6E756C6C2C472E';
wwv_flow_imp.g_varchar2_table(873) := '66696C6C3D462C472E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A466528692E6865616454657874297D7D2C472E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C';
wwv_flow_imp.g_varchar2_table(874) := '65227D2C77652B3D4E2E636F6C737D292C772B2B7D7661722055723D772C5F723D7B7D3B696628702E67726F75707326266A7428702C6365292E666F72456163682866756E6374696F6E284E297B6966284E2E67617029666F722876617220473D4E2E66';
wwv_flow_imp.g_varchar2_table(875) := '726F6D3B473C4E2E66726F6D2B4E2E636F6C733B472B2B295F725B475D3D317D292C63652E666F72456163682866756E6374696F6E284E2C47297B696628215F725B475D297B76617220483D4B28772C472B31293B482E76616C75653D4E2E6C6162656C';
wwv_flow_imp.g_varchar2_table(876) := '2C482E66696C6C3D462C482E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A466528692E6865616454657874297D7D2C482E616C69676E6D656E743D7B686F72697A6F6E74616C3A6C74284E2C70292C766572746963616C3A226D6964';
wwv_flow_imp.g_varchar2_table(877) := '646C65222C77726170546578743A21307D2C4328472B312C4E2E6C6162656C297D7D292C772B2B2C2143722E6C656E677468297B5928772C312C772C63652E6C656E677468292C4B28772C31292E76616C75653D5628702E656D707479546578742C7629';
wwv_flow_imp.g_varchar2_table(878) := '2C4B28772C31292E666F6E743D7B6974616C69633A21307D2C772B3D323B72657475726E7D7661722052723D772C6A723D536E28702C4372292C42723D5F742870292C4E653D5B5D2C71723D4D6174682E6D617828312C42742870292E6C656E67746829';
wwv_flow_imp.g_varchar2_table(879) := '2C78723D21312C75723D66756E6374696F6E284E2C472C482C572C552C6C652C4365297B766172204F3D6D742863652C472C482C57292C713D64612847292C513D66756E6374696F6E287565297B72657475726E2075652E66696C6C3D5028692E746F74';
wwv_flow_imp.g_varchar2_table(880) := '616C73292C75652E666F6E743D702E746F74616C73436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A466528702E746F74616C73436F6C6F72297D7D3A7B626F6C643A21307D2C75657D3B284F2E61743E317C7C4F2E61743D3D3D3029';
wwv_flow_imp.g_varchar2_table(881) := '262659284E2C312C4E2C4F2E61747C7C63652E6C656E677468293B766172206F653D51284B284E2C3129293B72657475726E206F652E76616C75653D572C6F652E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D2C4F2E61743D';
wwv_flow_imp.g_varchar2_table(882) := '3D3D3026264E2B2B2C63652E666F72456163682866756E6374696F6E2875652C4965297B696628212849653C4F2E617429297B7661722067653D51284B284E2C49652B3129292C41653D75652E636F6C3F776E28472C75652E636F6C293A6E756C6C3B69';
wwv_flow_imp.g_varchar2_table(883) := '66284165297B7661722024653D5F2E676574436F6C756D6E2849652B312B5A292E6C65747465722C78653D24652B552B223A222B24652B6C652C55653D557428482C41652E636F6C2C41652E666E292C66723D2841652E666E3D3D3D226D696E227C7C41';
wwv_flow_imp.g_varchar2_table(884) := '652E666E3D3D3D226D6178222926265565213D3D6E756C6C2626215672285565293F7474285565293A6E756C6C2C523D55653D3D6E756C6C3F6E756C6C3A66727C7C285672285565293F4D6174682E726F756E64284E756D626572285565292A31303029';
wwv_flow_imp.g_varchar2_table(885) := '2F3130303A537472696E6728556529293B67652E76616C75653D7B666F726D756C613A2843653F22535542544F54414C28222B73615B41652E666E5D2B222C223A53695B41652E666E5D2B222822292B78652B2229222C726573756C743A527D3B766172';
wwv_flow_imp.g_varchar2_table(886) := '204A3D41652E666E3D3D3D22636F756E74223F22232C232330223A66723F2264642F6D6D2F79797979223A48722875652E666D74293F706E2875652E666D74293A22232C2323302E3030223B67652E6E756D466D743D71262649745B41652E666E5D3F27';
wwv_flow_imp.g_varchar2_table(887) := '22272B49745B41652E666E5D2B272022272B4A3A4A2C67652E616C69676E6D656E743D7B686F72697A6F6E74616C3A227269676874227D2C52213D3D6E756C6C26262166722626432849652B312C56722852293F4B6528522C48722875652E666D742926';
wwv_flow_imp.g_varchar2_table(888) := '2641652E666E213D3D22636F756E74223F75652E666D743A226D6F6E657922293A52297D7D7D292C4E2B317D3B6A722E666F72456163682866756E6374696F6E284E297B6966284E2E6B3D3D3D226865616422297B702E627265616B506167652626214E';
wwv_flow_imp.g_varchar2_table(889) := '2E6C766C262628787226265F2E676574526F7728772D31292E61646450616765427265616B28292C78723D2130292C5928772C312C772C63652E6C656E677468293B76617220473D4B28772C31293B472E76616C75653D697428702C4E2C76292C472E66';
wwv_flow_imp.g_varchar2_table(890) := '6F6E743D7B626F6C643A21307D2C472E66696C6C3D5028546E28692C4E2E6C766C29292C772B2B3B72657475726E7D6966284E2E6B3D3D3D2273756222297B773D757228772C42722C4E2E726F77732C697428702C4E2C76292C4E655B4E2E6C766C7C7C';
wwv_flow_imp.g_varchar2_table(891) := '305D2C772D312C2130292C4E655B4E2E6C766C7C7C305D3D6E756C6C3B72657475726E7D666F722876617220483D303B483C71723B482B2B29284E655B485D3D3D3D6E756C6C7C7C4E655B485D3D3D3D766F69642030292626284E655B485D3D77293B76';
wwv_flow_imp.g_varchar2_table(892) := '617220573D4E2E722C553D4E2E692C6C653D636E28702C6365292C43653D6E7428702E726F775374796C652C762C57293B63652E666F72456163682866756E6374696F6E284F2C71297B76617220513D4B28772C712B31292C6F653D6661284F2C572C76';
wwv_flow_imp.g_varchar2_table(893) := '293B6966284F2E63656C6C297B7661722075653D766E284F2C572C762C69292C49653D712B312B5A3B696628512E76616C75653D6E756C6C2C284F2E76616C69676E7C7C6C6529262628512E616C69676E6D656E743D7B686F72697A6F6E74616C3A4F2E';
wwv_flow_imp.g_varchar2_table(894) := '616C69676E2C766572746963616C3A4F2E76616C69676E7C7C6C657D292C5525323D3D3D312626702E7A65627261213D3D2131262628512E66696C6C3D5028692E7A6562726129292C7565297B7661722067653D612E616464496D616765287B62617365';
wwv_flow_imp.g_varchar2_table(895) := '36343A75652E696D2E646174612C657874656E73696F6E3A75652E696D2E6578743D3D3D226A7067223F226A706567223A22706E67227D292C41653D6D72284F2C762C57293B5F2E616464496D6167652867652C7B746C3A7B636F6C3A49652D312B2E30';
wwv_flow_imp.g_varchar2_table(896) := '382C726F773A772D312B2E30387D2C6578743A7B77696474683A75652E772A332E37382C6865696768743A75652E682A332E37387D2C68797065726C696E6B733A41653F7B68797065726C696E6B3A41652C746F6F6C7469703A41657D3A766F69642030';
wwv_flow_imp.g_varchar2_table(897) := '7D292C526528772C75652E682A322E3833352B34292C68655B49655D3D4D6174682E6D696E2836302C4D6174682E6D61782868655B49655D7C7C382C4D6174682E6365696C2875652E772A332E37382F37292B3229297D72657475726E7D4F2E69734E75';
wwv_flow_imp.g_varchar2_table(898) := '6D26264F74286F65293F28512E76616C75653D6F652C512E6E756D466D743D6869284F2E666D7429293A284F2E666D743D3D3D2264617465227C7C28702E5F74797065737C7C762E545B537472696E6728702E736F75726365292E746F55707065724361';
wwv_flow_imp.g_varchar2_table(899) := '736528295D7C7C7B7D295B4F2E636F6C5D3D3D3D2244415445222926267474286F65293F28512E76616C75653D7474286F65292C512E6E756D466D743D2264642F6D6D2F7979797922293A512E76616C75653D6F653D3D6E756C6C3F6E756C6C3A447428';
wwv_flow_imp.g_varchar2_table(900) := '4F2E666D74292626214F2E6D61703F4B65286F652C4F2E666D74293A537472696E67286F65292C512E616C69676E6D656E743D4F2E76616C69676E7C7C6C653F7B686F72697A6F6E74616C3A4F2E616C69676E2C766572746963616C3A4F2E76616C6967';
wwv_flow_imp.g_varchar2_table(901) := '6E7C7C6C657D3A7B686F72697A6F6E74616C3A4F2E616C69676E7D3B7661722024653D6E74284F2E63656C6C5374796C652C762C57297C7C43653B2465262624652E66696C6C3F512E66696C6C3D502824652E66696C6C293A5525323D3D3D312626702E';
wwv_flow_imp.g_varchar2_table(902) := '7A65627261213D3D2131262628512E66696C6C3D5028692E7A6562726129293B7661722078653D7B7D3B284F2E626F6C647C7C2465262624652E626F6C642926262878652E626F6C643D2130292C282465262624652E636F6C6F727C7C4F2E636F6C6F72';
wwv_flow_imp.g_varchar2_table(903) := '2926262878652E636F6C6F723D7B617267623A4665282465262624652E636F6C6F727C7C4F2E636F6C6F72297D292C2878652E626F6C647C7C78652E636F6C6F7229262628512E666F6E743D7865293B7661722055653D6D72284F2C762C57293B556526';
wwv_flow_imp.g_varchar2_table(904) := '266F65213D3D6E756C6C26266F65213D3D766F6964203026266F65213D3D2222262628512E76616C75653D7B746578743A537472696E67286D6E284F2C572C7629292C68797065726C696E6B3A55657D2C512E666F6E743D7B626F6C643A78652E626F6C';
wwv_flow_imp.g_varchar2_table(905) := '642C756E6465726C696E653A21302C636F6C6F723A78652E636F6C6F727C7C7B617267623A466528692E6C696E6B297D7D292C4328712B312C4F2E69734E756D3F4B65286F652C4F2E666D74293A6F65297D292C772B2B7D293B7661722076723D772D31';
wwv_flow_imp.g_varchar2_table(906) := '2C74723D617428702E746F74616C73293B69662874722E6C656E677468262628773D757228772C74722C43722C796E28702C762C4372292C52722C772D312C2121702E627265616B427929292C702E6772696429666F72287661722058723D6228702E62';
wwv_flow_imp.g_varchar2_table(907) := '6F72646572436F6C6F72292C67723D51653B67723C773B67722B2B29666F7228766172206E723D313B6E723C3D63652E6C656E6774683B6E722B2B294B2867722C6E72292E626F726465723D58723B4C653D3D3D31262621702E627265616B4279262621';
wwv_flow_imp.g_varchar2_table(908) := '61652626284A653D7B66726F6D3A7B726F773A55722C636F6C756D6E3A317D2C746F3A7B726F773A76722C636F6C756D6E3A63652E6C656E6774687D7D2C66652E696E6465784F662870293C3D3126262848653D557229292C772B2B7D7D292C4F626A65';
wwv_flow_imp.g_varchar2_table(909) := '63742E6B657973286865292E666F72456163682866756E6374696F6E2864297B5F2E676574436F6C756D6E282B64292E77696474683D68655B645D7D292C4A652626285F2E6175746F46696C7465723D4A65292C48652626285F2E76696577733D5B7B73';
wwv_flow_imp.g_varchar2_table(910) := '746174653A2266726F7A656E222C7953706C69743A48657D5D292C532626752E70726F7465637426266C2E70757368285F2E70726F7465637428752E70617373776F72642C7B73656C6563744C6F636B656443656C6C733A21302C73656C656374556E6C';
wwv_flow_imp.g_varchar2_table(911) := '6F636B656443656C6C733A21302C666F726D6174436F6C756D6E733A21302C666F726D6174526F77733A21307D29292C652E666F6F7465722626285F2E686561646572466F6F7465722E6F6464466F6F7465723D22264C2638222B5628652E666F6F7465';
wwv_flow_imp.g_varchar2_table(912) := '722E6C6566742C76292E7265706C616365282F262F672C22262622292E73756273747228302C323030292B222652263850C3A167696E6120265020646520264E22292C652E706167654865616465722626747970656F6620652E70616765486561646572';
wwv_flow_imp.g_varchar2_table(913) := '3D3D226F626A65637422297B7661722072653D4F6E28652E70616765486561646572292C73653D22223B5B5B226C656674222C22264C225D2C5B2263656E746572222C222643225D2C5B227269676874222C222652225D5D2E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(914) := '6374696F6E2864297B76617220703D72655B645B305D5D3B69662870297B76617220663D5628702E746578742C76292E7265706C616365282F262F672C22262622292E7265706C616365282F5C7B28444F43293F50414745535C7D2F672C22264E22292E';
wwv_flow_imp.g_varchar2_table(915) := '7265706C616365282F5C7B28444F43293F504147455C7D2F672C22265022292E73756273747228302C3830293B73652B3D645B315D2B2226222B4D6174682E726F756E6428702E73697A65292B28702E636F6C6F722626702E636F6C6F72213D3D222330';
wwv_flow_imp.g_varchar2_table(916) := '3030303030223F22264B222B476528702E636F6C6F72293A2222292B28702E626F6C643F222642222B662B222642223A66297D7D292C73652626285F2E686561646572466F6F7465722E6F64644865616465723D7365292C652E70616765486561646572';
wwv_flow_imp.g_varchar2_table(917) := '2E6669727374506167653D3D3D21312626285F2E686561646572466F6F7465722E646966666572656E7446697273743D21302C5F2E686561646572466F6F7465722E6F6464466F6F7465722626285F2E686561646572466F6F7465722E6669727374466F';
wwv_flow_imp.g_varchar2_table(918) := '6F7465723D5F2E686561646572466F6F7465722E6F6464466F6F74657229297D7D297D292C636128652926264B692861292C6C2E6C656E6774683F50726F6D6973652E616C6C286C292E7468656E2866756E6374696F6E28297B72657475726E20612E78';
wwv_flow_imp.g_varchar2_table(919) := '6C73782E777269746542756666657228297D293A612E786C73782E777269746542756666657228297D766172206A613D7B6C65747465723A5B31323234302C31353834305D2C6C6567616C3A5B31323234302C32303136305D2C61343A5B31313930362C';
wwv_flow_imp.g_varchar2_table(920) := '31363833385D7D2C6B613D7B227B504147457D223A2243555252454E54222C227B50414745537D223A22544F54414C5F5041474553222C227B444F43504147457D223A2243555252454E54222C227B444F4350414745537D223A22544F54414C5F504147';
wwv_flow_imp.g_varchar2_table(921) := '45535F494E5F53454354494F4E227D3B66756E6374696F6E20496128652C722C6E297B76617220743D77696E646F772E646F63782C613D5B5D3B72657475726E205628652C72292E73706C6974282F285C7B283F3A444F43293F50414745533F5C7D292F';
wwv_flow_imp.g_varchar2_table(922) := '292E666F72456163682866756E6374696F6E2869297B6B615B695D3F612E70757368286E657720742E5465787452756E287B6368696C6472656E3A5B742E506167654E756D6265725B6B615B695D5D5D2C73697A653A6E2E73697A652C636F6C6F723A6E';
wwv_flow_imp.g_varchar2_table(923) := '2E636F6C6F722C626F6C643A6E2E626F6C647C7C766F696420307D29293A692626612E70757368286E657720742E5465787452756E287B746578743A692C73697A653A6E2E73697A652C636F6C6F723A6E2E636F6C6F722C626F6C643A6E2E626F6C647C';
wwv_flow_imp.g_varchar2_table(924) := '7C766F696420307D29297D292C617D66756E6374696F6E2051692865297B76617220723D4A534F4E2E737472696E67696679285B652E666F6F7465727C7C6E756C6C2C652E706167654865616465727C7C6E756C6C5D293B72657475726E2F5C7B444F43';
wwv_flow_imp.g_varchar2_table(925) := '50414745533F5C7D2F2E746573742872297D66756E6374696F6E20556128652C722C6E297B76617220743D77696E646F772E646F63782C613D5B5D2C693D4D6174682E726F756E642828652E73697A657C7C37292A32292C6F3D4765286E2E6D75746564';
wwv_flow_imp.g_varchar2_table(926) := '293B66756E6374696F6E20752873297B72657475726E20496128732C722C7B73697A653A692C636F6C6F723A6F7D297D72657475726E20652E6C6566742626612E70757368286E657720742E506172616772617068287B6368696C6472656E3A7528652E';
wwv_flow_imp.g_varchar2_table(927) := '6C656674297D29292C652E72696768742626612E70757368286E657720742E506172616772617068287B616C69676E6D656E743A742E416C69676E6D656E74547970652E52494748542C6368696C6472656E3A7528652E7269676874297D29292C612E6C';
wwv_flow_imp.g_varchar2_table(928) := '656E6774683F613A5B6E657720742E506172616772617068287B6368696C6472656E3A5B5D7D295D7D76617220476E3D22E29FA64E52463A222C486E3D22E29FA7223B66756E6374696F6E2043742865297B72657475726E20537472696E672865292E72';
wwv_flow_imp.g_varchar2_table(929) := '65706C616365282F262F672C2226616D703B22292E7265706C616365282F3C2F672C22266C743B22292E7265706C616365282F3E2F672C222667743B22292E7265706C616365282F222F672C222671756F743B22297D66756E6374696F6E20656C286529';
wwv_flow_imp.g_varchar2_table(930) := '7B76617220723D6E65772055696E743841727261792865292C6E3D747970656F662077696E646F77213D22756E646566696E65642226262877696E646F772E63727970746F7C7C77696E646F772E6D7343727970746F293B6966286E26266E2E67657452';
wwv_flow_imp.g_varchar2_table(931) := '616E646F6D56616C756573296E2E67657452616E646F6D56616C7565732872293B656C736520666F722876617220743D303B743C653B742B2B29725B745D3D4D6174682E666C6F6F72284D6174682E72616E646F6D28292A323536293B72657475726E20';
wwv_flow_imp.g_varchar2_table(932) := '727D66756E6374696F6E20726C28652C722C6E297B76617220743D273C773A616C69617320773A76616C3D22272B437428652E6C6162656C7C7C652E6E616D65292B27222F3E3C773A74616720773A76616C3D22272B437428652E6E616D65292B27222F';
wwv_flow_imp.g_varchar2_table(933) := '3E3C773A696420773A76616C3D22272B722B27222F3E272B28652E726561644F6E6C793F273C773A6C6F636B20773A76616C3D22736474436F6E74656E744C6F636B6564222F3E273A2222293B696628652E696E7075743D3D3D22636865636B626F7822';
wwv_flow_imp.g_varchar2_table(934) := '297B76617220613D273C773A72466F6E747320773A61736369693D224D5320476F746869632220773A65617374417369613D224D5320476F746869632220773A68416E73693D224D5320476F746869632220773A63733D224D5320476F74686963222F3E';
wwv_flow_imp.g_varchar2_table(935) := '272C693D6E2E7265706C616365282F3C773A72466F6E74735B5E3E5D2A5C2F3E2F2C2222292E7265706C61636528223C773A7250723E222C223C773A7250723E222B61293B72657475726E223C773A7364743E3C773A73647450723E222B692B742B273C';
wwv_flow_imp.g_varchar2_table(936) := '7731343A636865636B626F783E3C7731343A636865636B6564207731343A76616C3D22272B28652E636865636B65643F313A30292B27222F3E3C7731343A636865636B65645374617465207731343A76616C3D223236313222207731343A666F6E743D22';
wwv_flow_imp.g_varchar2_table(937) := '4D5320476F74686963222F3E3C7731343A756E636865636B65645374617465207731343A76616C3D223236313022207731343A666F6E743D224D5320476F74686963222F3E3C2F7731343A636865636B626F783E3C2F773A73647450723E3C773A736474';
wwv_flow_imp.g_varchar2_table(938) := '436F6E74656E743E3C773A723E272B692B223C773A743E222B28652E636865636B65643F48743A5774292B223C2F773A743E3C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D766172206F3D21652E76616C75652C753D652E';
wwv_flow_imp.g_varchar2_table(939) := '76616C75657C7C652E706C616365686F6C6465727C7C28652E696E7075743D3D3D226C697374223F22456C696A6120756E20656C656D656E746F2E223A6E65772041727261792839292E6A6F696E2822E280822229292C733D652E696E7075743D3D3D22';
wwv_flow_imp.g_varchar2_table(940) := '6C697374223F223C773A64726F70446F776E4C6973743E222B652E6F7074696F6E732E6D61702866756E6374696F6E2868297B72657475726E273C773A6C6973744974656D20773A646973706C6179546578743D22272B43742868292B272220773A7661';
wwv_flow_imp.g_varchar2_table(941) := '6C75653D22272B43742868292B27222F3E277D292E6A6F696E282222292B223C2F773A64726F70446F776E4C6973743E223A223C773A74657874222B28652E696E7075743D3D3D226D756C74696C696E65223F2720773A6D756C74694C696E653D223122';
wwv_flow_imp.g_varchar2_table(942) := '273A2222292B222F3E222C6C3D537472696E672875292E73706C6974282F5C723F5C6E2F292E6D61702866756E6374696F6E2868297B72657475726E273C773A7420786D6C3A73706163653D227072657365727665223E272B43742868292B223C2F773A';
wwv_flow_imp.g_varchar2_table(943) := '743E227D292E6A6F696E28223C773A62722F3E22293B72657475726E223C773A7364743E3C773A73647450723E222B6E2B742B286F3F223C773A73686F77696E67506C634864722F3E223A2222292B732B223C2F773A73647450723E3C773A736474436F';
wwv_flow_imp.g_varchar2_table(944) := '6E74656E743E3C773A723E222B6E2B6C2B223C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D66756E6374696F6E20746C28652C72297B696628653D652E7265706C616365282F3C773A646F63756D656E7450726F74656374';
wwv_flow_imp.g_varchar2_table(945) := '696F6E5B5E3E5D2A5C2F3E2F672C2222292C21722E70726F746563742972657475726E20653B766172206E3D273C773A646F63756D656E7450726F74656374696F6E20773A656469743D22666F726D732220773A656E666F7263656D656E743D22312227';
wwv_flow_imp.g_varchar2_table(946) := '3B696628722E70617373776F7264297B76617220743D656C283136292C613D3165353B6E2B3D2720773A637279707450726F7669646572547970653D227273614145532220773A6372797074416C676F726974686D436C6173733D22686173682220773A';
wwv_flow_imp.g_varchar2_table(947) := '6372797074416C676F726974686D547970653D2274797065416E792220773A6372797074416C676F726974686D5369643D2231342220773A63727970745370696E436F756E743D22272B612B272220773A686173683D22272B717428506E28722E706173';
wwv_flow_imp.g_varchar2_table(948) := '73776F72642C742C6129292B272220773A73616C743D22272B71742874292B2722277D6E2B3D222F3E223B76617220693D5B223C773A6576656E416E644F646448656164657273222C223C773A636F6D706174222C223C2F773A73657474696E67733E22';
wwv_flow_imp.g_varchar2_table(949) := '5D2E6D61702866756E6374696F6E286F297B72657475726E20652E696E6465784F66286F297D292E66696C7465722866756E6374696F6E286F297B72657475726E206F3E3D307D295B305D3B72657475726E20652E73756273747228302C69292B6E2B65';
wwv_flow_imp.g_varchar2_table(950) := '2E7375627374722869297D66756E6374696F6E206E6C28652C722C6E297B72657475726E206E2E70726F7465637426266E2E70617373776F72642626506E286E2E70617373776F72642C6E65772055696E74384172726179283136292C30292C77696E64';
wwv_flow_imp.g_varchar2_table(951) := '6F772E4A535A69702E6C6F61644173796E632865292E7468656E2866756E6374696F6E2874297B72657475726E2050726F6D6973652E616C6C285B742E66696C652822776F72642F646F63756D656E742E786D6C22292E6173796E632822737472696E67';
wwv_flow_imp.g_varchar2_table(952) := '22292C742E66696C652822776F72642F73657474696E67732E786D6C22292E6173796E632822737472696E6722295D292E7468656E2866756E6374696F6E2861297B76617220693D302C6F3D6E65772052656745787028273C773A723E283C773A725072';
wwv_flow_imp.g_varchar2_table(953) := '3E283F3A283F213C2F773A7250723E295B5C5C735C5C535D292A3C2F773A7250723E293F3C773A7420786D6C3A73706163653D227072657365727665223E272B476E2B22285C5C642B29222B486E2B223C2F773A743E3C2F773A723E222C226722292C75';
wwv_flow_imp.g_varchar2_table(954) := '3D615B305D2E7265706C616365286F2C66756E6374696F6E28732C6C2C68297B72657475726E20692B2B2C726C28725B2B685D2C3165332B4E756D6265722868292C6C7C7C223C773A7250723E3C2F773A7250723E22297D293B69662869213D3D722E6C';
wwv_flow_imp.g_varchar2_table(955) := '656E677468297468726F77206E6577204572726F722822576F72643A206E6F207365207075646965726F6E20636F6C6F63617220746F646F73206C6F732063616D706F732064656C20666F726D756C6172696F2028222B692B2220646520222B722E6C65';
wwv_flow_imp.g_varchar2_table(956) := '6E6774682B22292E22293B72657475726E20742E66696C652822776F72642F646F63756D656E742E786D6C222C75292C742E66696C652822776F72642F73657474696E67732E786D6C222C746C28615B315D2C6E29292C742E67656E6572617465417379';
wwv_flow_imp.g_varchar2_table(957) := '6E63287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D297D297D297D66756E6374696F6E20616C28652C722C6E297B76';
wwv_flow_imp.g_varchar2_table(958) := '617220743D77696E646F772E646F63782C613D6A6E2865292C693D652E706167657C7C7B7D2C6F3D5B5D2C753D416E28292C733D6A615B692E73697A657C7C226C6574746572225D7C7C6A612E6C65747465722C6C3D692E6F7269656E746174696F6E3D';
wwv_flow_imp.g_varchar2_table(959) := '3D3D226C616E647363617065222C683D4D6174682E726F756E642828692E6D617267696E7C7C31322E37292A35362E37292C673D286C3F735B315D3A735B305D292D322A682C6D3D7B7374796C653A742E426F726465725374796C652E4E4F4E452C7369';
wwv_flow_imp.g_varchar2_table(960) := '7A653A302C636F6C6F723A22464646464646227D2C543D7B746F703A6D2C626F74746F6D3A6D2C6C6566743A6D2C72696768743A6D2C696E73696465486F72697A6F6E74616C3A6D2C696E73696465566572746963616C3A6D7D2C463D7B7374796C653A';
wwv_flow_imp.g_varchar2_table(961) := '742E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A22424643394434227D2C443D7B746F703A462C626F74746F6D3A462C6C6566743A462C72696768743A462C696E73696465486F72697A6F6E74616C3A462C696E7369';
wwv_flow_imp.g_varchar2_table(962) := '6465566572746963616C3A467D3B66756E6374696F6E20502853297B69662821532972657475726E20443B76617220453D7B7374796C653A742E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A47652853297D3B726574';
wwv_flow_imp.g_varchar2_table(963) := '75726E7B746F703A452C626F74746F6D3A452C6C6566743A452C72696768743A452C696E73696465486F72697A6F6E74616C3A452C696E73696465566572746963616C3A457D7D76617220623D4D6174682E726F756E642828612E666F6E7453697A657C';
wwv_flow_imp.g_varchar2_table(964) := '7C37292A32293B66756E6374696F6E20706528532C45297B72657475726E20453D457C7C7B7D2C6E657720742E5465787452756E287B746578743A537472696E6728533D3D6E756C6C3F22223A53292C626F6C643A2121452E626F6C642C6974616C6963';
wwv_flow_imp.g_varchar2_table(965) := '733A2121452E6974616C69632C756E6465726C696E653A452E756E6465726C696E653F7B7D3A766F696420302C73697A653A452E73697A657C7C622C636F6C6F723A452E636F6C6F723F476528452E636F6C6F72293A766F696420302C666F6E743A452E';
wwv_flow_imp.g_varchar2_table(966) := '666F6E747C7C2243616C69627269227D297D66756E6374696F6E207628532C45297B453D457C7C7B7D3B76617220433D706528532C45293B696628452E6C696E6B2626537472696E6728533D3D6E756C6C3F22223A5329213D3D2222297B766172205A3D';
wwv_flow_imp.g_varchar2_table(967) := '69722845293B5A2E756E6465726C696E653D21302C5A2E636F6C6F723D452E6C696E6B436F6C6F727C7C452E636F6C6F727C7C612E6C696E6B2C433D6E657720742E45787465726E616C48797065726C696E6B287B6C696E6B3A452E6C696E6B2C636869';
wwv_flow_imp.g_varchar2_table(968) := '6C6472656E3A5B706528532C5A295D7D297D72657475726E206E657720742E506172616772617068287B6368696C6472656E3A5B435D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A452E616C69676E3D';
wwv_flow_imp.g_varchar2_table(969) := '3D3D227269676874223F742E416C69676E6D656E74547970652E52494748543A452E616C69676E3D3D3D2263656E746572223F742E416C69676E6D656E74547970652E43454E5445523A742E416C69676E6D656E74547970652E4C4546547D297D66756E';
wwv_flow_imp.g_varchar2_table(970) := '6374696F6E204128532C45297B453D457C7C7B7D3B76617220433D452E706164213D3D766F696420303F452E7061643A33303B72657475726E206E657720742E5461626C6543656C6C287B6368696C6472656E3A5B7628532C45295D2C636F6C756D6E53';
wwv_flow_imp.g_varchar2_table(971) := '70616E3A452E7370616E2C6D617267696E733A7B746F703A432C626F74746F6D3A432C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A452E6D6964646C657C7C452E76616C69676E3D3D3D226D6964646C65223F742E56';
wwv_flow_imp.g_varchar2_table(972) := '6572746963616C416C69676E2E43454E5445523A452E76616C69676E3D3D3D22626F74746F6D223F742E566572746963616C416C69676E2E424F54544F4D3A452E76616C69676E3D3D3D22746F70223F742E566572746963616C416C69676E2E544F503A';
wwv_flow_imp.g_varchar2_table(973) := '766F696420302C73686164696E673A452E66696C6C3F7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A476528452E66696C6C297D3A766F696420307D297D66756E6374696F6E207928297B';
wwv_flow_imp.g_varchar2_table(974) := '72657475726E206E657720742E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D66756E6374696F6E204D28532C452C43297B72657475726E206E657720742E5061';
wwv_flow_imp.g_varchar2_table(975) := '72616772617068287B6368696C6472656E3A5B706528532C7B626F6C643A452E626F6C642C73697A653A452E73697A653F4D6174682E726F756E6428452E73697A652A32293A31342C636F6C6F723A452E636F6C6F727D295D2C73706163696E673A7B62';
wwv_flow_imp.g_varchar2_table(976) := '65666F72653A302C61667465723A32307D2C616C69676E6D656E743A433D3D3D227269676874223F742E416C69676E6D656E74547970652E52494748543A433D3D3D2263656E746572223F742E416C69676E6D656E74547970652E43454E5445523A742E';
wwv_flow_imp.g_varchar2_table(977) := '416C69676E6D656E74547970652E4C4546542C73686164696E673A452E66696C6C3F7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A476528452E66696C6C297D3A766F696420307D297D66';
wwv_flow_imp.g_varchar2_table(978) := '756E6374696F6E204928532C452C432C5A2C61652C4B297B76617220593D6E657720742E496D61676552756E287B747970653A532E6578743D3D3D226A7067223F226A7067223A22706E67222C646174613A532E6275662C7472616E73666F726D617469';
wwv_flow_imp.g_varchar2_table(979) := '6F6E3A7B77696474683A4D6174682E726F756E6428452A332E3738292C6865696768743A4D6174682E726F756E6428432A332E3738297D7D293B72657475726E206E657720742E506172616772617068287B616C69676E6D656E743A5A2E616C69676E3D';
wwv_flow_imp.g_varchar2_table(980) := '3D3D227269676874223F742E416C69676E6D656E74547970652E52494748543A5A2E616C69676E3D3D3D2263656E746572223F742E416C69676E6D656E74547970652E43454E5445523A742E416C69676E6D656E74547970652E4C4546542C7370616369';
wwv_flow_imp.g_varchar2_table(981) := '6E673A7B61667465723A6165213D3D766F696420303F61653A4D6174682E726F756E6428285A2E676170213D3D766F696420303F5A2E6761703A33292A35362E37297D2C6368696C6472656E3A5B4B3F6E657720742E45787465726E616C48797065726C';
wwv_flow_imp.g_varchar2_table(982) := '696E6B287B6C696E6B3A4B2C6368696C6472656E3A5B595D7D293A595D7D297D766172205F3D286C3F735B315D3A735B305D292F35362E372C66653D286C3F735B305D3A735B315D292F35362E373B66756E6374696F6E20422853297B76617220453D68';
wwv_flow_imp.g_varchar2_table(983) := '652853293B72657475726E20453F6E657720742E486561646572287B6368696C6472656E3A5B455D7D293A6E756C6C7D66756E6374696F6E207728532C45297B76617220433D4F6E2853292C5A3D416128532C45292C61653D5B5D2C4B3D5B5D2C593D7B';
wwv_flow_imp.g_varchar2_table(984) := '7374796C653A742E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C52653D532E6C696E65213D3D21313F7B7374796C653A742E426F726465725374796C652E53494E474C452C73697A653A4D617468';
wwv_flow_imp.g_varchar2_table(985) := '2E6D617828322C4D6174682E726F756E642828532E6C696E6557696474687C7C2E33292A323029292C636F6C6F723A476528532E6C696E65436F6C6F727C7C612E7072696D617279297D3A592C57653D532E66696C6C3F7B747970653A742E5368616469';
wwv_flow_imp.g_varchar2_table(986) := '6E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A476528532E66696C6C297D3A766F696420302C783D66756E6374696F6E2859652C6C72297B72657475726E2061652E70757368286C72292C6E657720742E5461626C654365';
wwv_flow_imp.g_varchar2_table(987) := '6C6C287B6368696C6472656E3A59652C77696474683A7B73697A653A6C722C747970653A742E5769647468547970652E4458417D2C766572746963616C416C69676E3A742E566572746963616C416C69676E2E43454E5445522C6D617267696E733A7B74';
wwv_flow_imp.g_varchar2_table(988) := '6F703A302C626F74746F6D3A302C6C6566743A302C72696768743A307D2C73686164696E673A57657D297D2C72653D66756E6374696F6E2859652C6C722C7972297B7661722056653D435B59655D2C71653D2856653F56652E746578742E73706C697428';
wwv_flow_imp.g_varchar2_table(989) := '225C6E22293A5B22225D292E6D61702866756E6374696F6E286472297B72657475726E206E657720742E506172616772617068287B616C69676E6D656E743A6C722C73706163696E673A7B6265666F72653A302C61667465723A307D2C6368696C647265';
wwv_flow_imp.g_varchar2_table(990) := '6E3A56653F49612864722C452C7B73697A653A4D6174682E726F756E642856652E73697A652A32292C636F6C6F723A47652856652E636F6C6F72292C626F6C643A56652E626F6C647D293A5B5D7D297D293B72657475726E20782871652C7972297D2C73';
wwv_flow_imp.g_varchar2_table(991) := '653D5A3F43612853293A22222C643D5A26267365213D3D2263656E746572223F4D6174682E726F756E64285A2E772A35362E37292B3137303A302C703D672D642C663D73653D3D3D227269676874222C69653D66756E6374696F6E285965297B72657475';
wwv_flow_imp.g_varchar2_table(992) := '726E2078285B6E657720742E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A663F742E416C69676E6D656E74547970652E52494748543A73653D3D3D2263656E746572223F742E';
wwv_flow_imp.g_varchar2_table(993) := '416C69676E6D656E74547970652E43454E5445523A742E416C69676E6D656E74547970652E4C4546542C6368696C6472656E3A5B6E657720742E496D61676552756E287B747970653A5A2E696D2E6578743D3D3D226A7067223F226A7067223A22706E67';
wwv_flow_imp.g_varchar2_table(994) := '222C646174613A5A2E696D2E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E64285A2E772A332E3738292C6865696768743A4D6174682E726F756E64285A2E682A332E3738297D7D295D7D295D2C5965297D3B5A';
wwv_flow_imp.g_varchar2_table(995) := '262673653D3D3D226C6566742226264B2E70757368286965286429293B7661722064653D4D6174682E666C6F6F7228702A2E34292C53653D4D6174682E666C6F6F7228702A2E33292C6A653D702D64652D53653B72657475726E2073653D3D3D2263656E';
wwv_flow_imp.g_varchar2_table(996) := '7465722226262853653D4D6174682E6D61782853652C4D6174682E726F756E64285A2E772A35362E37292B313730292C64653D4D6174682E666C6F6F722828702D5365292F32292C6A653D702D53652D6465292C4B2E7075736828726528226C65667422';
wwv_flow_imp.g_varchar2_table(997) := '2C742E416C69676E6D656E74547970652E4C4546542C6465292C73653D3D3D2263656E746572223F6965285365293A7265282263656E746572222C742E416C69676E6D656E74547970652E43454E5445522C5365292C726528227269676874222C742E41';
wwv_flow_imp.g_varchar2_table(998) := '6C69676E6D656E74547970652E52494748542C6A6529292C5A26266626264B2E70757368286965286429292C6E657720742E5461626C65287B726F77733A5B6E657720742E5461626C65526F77287B6865696768743A7B76616C75653A4D6174682E726F';
wwv_flow_imp.g_varchar2_table(999) := '756E6428284E756D62657228532E686569676874297C7C3132292A35362E37292C72756C653A742E48656967687452756C652E41544C454153547D2C6368696C6472656E3A4B7D295D2C77696474683A7B73697A653A672C747970653A742E5769647468';
wwv_flow_imp.g_varchar2_table(1000) := '547970652E4458417D2C636F6C756D6E5769647468733A61652C6C61796F75743A742E5461626C654C61796F7574547970652E46495845442C626F72646572733A7B746F703A592C6C6566743A592C72696768743A592C696E73696465486F72697A6F6E';
wwv_flow_imp.g_varchar2_table(1001) := '74616C3A592C696E73696465566572746963616C3A592C626F74746F6D3A52657D7D297D66756E6374696F6E2068652853297B76617220453D4F6128652C53292C433B69662821452972657475726E206E756C6C3B7472797B433D716928452C5F2C6665';
wwv_flow_imp.g_varchar2_table(1002) := '297D6361746368285A297B72657475726E206E756C6C7D72657475726E206E657720742E506172616772617068287B6368696C6472656E3A5B6E657720742E496D61676552756E287B747970653A22706E67222C646174613A432E6275662C7472616E73';
wwv_flow_imp.g_varchar2_table(1003) := '666F726D6174696F6E3A7B77696474683A4D6174682E726F756E64285F2A332E3738292C6865696768743A4D6174682E726F756E642866652A332E3738297D2C666C6F6174696E673A7B686F72697A6F6E74616C506F736974696F6E3A7B72656C617469';
wwv_flow_imp.g_varchar2_table(1004) := '76653A742E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A742E486F72697A6F6E74616C506F736974696F6E416C69676E2E43454E5445527D2C766572746963616C506F736974696F6E3A7B72';
wwv_flow_imp.g_varchar2_table(1005) := '656C61746976653A742E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A742E566572746963616C506F736974696F6E416C69676E2E43454E5445527D2C626568696E64446F63756D656E743A21302C';
wwv_flow_imp.g_varchar2_table(1006) := '616C6C6F774F7665726C61703A21302C777261703A7B747970653A742E546578745772617070696E67547970652E4E4F4E457D7D7D295D7D297D766172204C653D722E6D61702866756E6374696F6E28532C45297B76617220433D5B5D2C5A3D722E6C65';
wwv_flow_imp.g_varchar2_table(1007) := '6E6774683E313F225F222B28452B31293A22223B4C6E28652C22646F6378222C53292E666F72456163682866756E6374696F6E2073652864297B76617220703D642E747970653B696628703D3D3D22636F6C756D6E617322297B76617220663D79742864';
wwv_flow_imp.g_varchar2_table(1008) := '2C22646F6378222C532C672F35362E37293B69662821662E6C656E6774682972657475726E3B7661722069653D432C64653D672C53653D4D6174682E726F756E642828642E636F6C476170213D3D766F696420303F4E756D62657228642E636F6C476170';
wwv_flow_imp.g_varchar2_table(1009) := '293A34292A35362E37292C6A653D5B5D2C59653D5B5D3B662E666F72456163682866756E6374696F6E28522C4A297B7661722074653D4A3D3D3D662E6C656E6774682D312C6D653D4D6174682E726F756E6428522E772A35362E37293B433D5B5D2C673D';
wwv_flow_imp.g_varchar2_table(1010) := '6D652C522E736563732E666F7245616368287365292C2821432E6C656E6774687C7C2128435B432E6C656E6774682D315D696E7374616E63656F6620742E50617261677261706829292626432E70757368287628222229292C6A652E70757368286E6577';
wwv_flow_imp.g_varchar2_table(1011) := '20742E5461626C6543656C6C287B6368696C6472656E3A432C77696474683A7B73697A653A6D652B2874653F303A5365292C747970653A742E5769647468547970652E4458417D2C6D617267696E733A7B746F703A302C626F74746F6D3A302C6C656674';
wwv_flow_imp.g_varchar2_table(1012) := '3A302C72696768743A74653F303A53657D2C766572746963616C416C69676E3A742E566572746963616C416C69676E2E544F507D29292C59652E70757368286D652B2874653F303A536529297D292C433D69652C673D64652C432E70757368286E657720';
wwv_flow_imp.g_varchar2_table(1013) := '742E5461626C65287B726F77733A5B6E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A6A657D295D2C77696474683A7B73697A653A672C747970653A742E5769647468547970652E4458417D2C636F6C756D';
wwv_flow_imp.g_varchar2_table(1014) := '6E5769647468733A59652C626F72646572733A542C6C61796F75743A742E5461626C654C61796F7574547970652E46495845447D292C792829293B72657475726E7D696628703D3D3D22677275706F22297B766172206C723D532C79723D5A2C56653D43';
wwv_flow_imp.g_varchar2_table(1015) := '2C71653D672C64723D4D6174682E726F756E642828642E70616464696E67213D3D766F696420303F4E756D62657228642E70616464696E67293A642E626F726465727C7C642E66696C6C3F333A30292A35362E37292C66743D642E626F726465723F5028';
wwv_flow_imp.g_varchar2_table(1016) := '642E626F72646572436F6C6F727C7C6B72293A543B526E28642C53292E666F72456163682866756E6374696F6E2852297B533D522E6374782C5A3D79722B522E7375663B766172204A3D777428642C22646F6378222C53293B6966282128214A2E6C656E';
wwv_flow_imp.g_varchar2_table(1017) := '677468262621642E7469746C6529297B433D5B5D2C673D4D6174682E6D6178283630302C71652D322A6472292C4A2E666F7245616368287365292C2821432E6C656E6774687C7C2128435B432E6C656E6774682D315D696E7374616E63656F6620742E50';
wwv_flow_imp.g_varchar2_table(1018) := '617261677261706829292626432E70757368287628222229293B7661722074653D5B5D3B642E7469746C65262674652E70757368286E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B41285628642E7469';
wwv_flow_imp.g_varchar2_table(1019) := '746C652C53292C7B626F6C643A21302C73697A653A4D6174682E726F756E642828642E7469746C6553697A657C7C28612E666F6E7453697A657C7C37292B32292A32292C636F6C6F723A642E7469746C65436F6C6F727C7C612E68656164546578742C66';
wwv_flow_imp.g_varchar2_table(1020) := '696C6C3A642E7469746C6546696C6C7C7C612E7072696D6172792C7061643A36307D295D7D29292C74652E70757368286E657720742E5461626C65526F77287B63616E7453706C69743A642E6B656570546F676574686572213D3D21312C6368696C6472';
wwv_flow_imp.g_varchar2_table(1021) := '656E3A5B6E657720742E5461626C6543656C6C287B6368696C6472656E3A432C6D617267696E733A7B746F703A64722C626F74746F6D3A64722C6C6566743A64722C72696768743A64727D2C73686164696E673A642E66696C6C3F7B747970653A742E53';
wwv_flow_imp.g_varchar2_table(1022) := '686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A476528642E66696C6C297D3A766F696420307D295D7D29292C433D56652C673D71652C432E70757368286E657720742E5461626C65287B726F77733A74652C7769';
wwv_flow_imp.g_varchar2_table(1023) := '6474683A7B73697A653A672C747970653A742E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B675D2C626F72646572733A66742C6C61796F75743A742E5461626C654C61796F7574547970652E46495845447D292C792829297D';
wwv_flow_imp.g_varchar2_table(1024) := '7D292C433D56652C673D71652C533D6C722C5A3D79723B72657475726E7D696628703D3D3D2268656164657222297B766172206B653D4D6E28642C61292C70723D642E666F6E743F6B652E666F6E745B315D3A766F696420302C45723D5B6E657720742E';
wwv_flow_imp.g_varchar2_table(1025) := '5461626C65526F77287B6368696C6472656E3A5B41285628642E7469746C652C53292C7B626F6C643A21302C73697A653A4D6174682E726F756E64286B652E73697A652A32292C636F6C6F723A6B652E636F6C6F722C66696C6C3A6B652E66696C6C2C66';
wwv_flow_imp.g_varchar2_table(1026) := '6F6E743A70727D292C41285628642E72696768742C53292C7B73697A653A4D6174682E726F756E64286B652E726967687453697A652A32292C636F6C6F723A6B652E636F6C6F722C66696C6C3A6B652E66696C6C2C616C69676E3A227269676874222C66';
wwv_flow_imp.g_varchar2_table(1027) := '6F6E743A70722C6D6964646C653A2121642E726967687453697A657D295D7D295D3B642E7375627469746C65262645722E70757368286E657720742E5461626C65526F77287B6368696C6472656E3A5B41285628642E7375627469746C652C53292C7B73';
wwv_flow_imp.g_varchar2_table(1028) := '697A653A4D6174682E726F756E64286B652E73756253697A652A32292C636F6C6F723A6B652E636F6C6F722C66696C6C3A6B652E66696C6C2C7370616E3A322C666F6E743A70727D295D7D29292C432E70757368286E657720742E5461626C65287B726F';
wwv_flow_imp.g_varchar2_table(1029) := '77733A45722C77696474683A7B73697A653A672C747970653A742E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B4D6174682E726F756E6428672A2E37292C4D6174682E726F756E6428672A2E33295D2C626F72646572733A54';
wwv_flow_imp.g_varchar2_table(1030) := '7D292C792829297D656C736520696628703D3D3D22746578746F22297B766172204F723D7B72696768743A742E416C69676E6D656E74547970652E52494748542C63656E7465723A742E416C69676E6D656E74547970652E43454E5445522C6A75737469';
wwv_flow_imp.g_varchar2_table(1031) := '66793A742E416C69676E6D656E74547970652E4A55535449464945447D3B676E28642C53292E666F72456163682866756E6374696F6E2852297B432E70757368286E657720742E506172616772617068287B616C69676E6D656E743A4F725B642E616C69';
wwv_flow_imp.g_varchar2_table(1032) := '676E5D7C7C742E416C69676E6D656E74547970652E4C4546542C696E64656E743A642E696E64656E743F7B6C6566743A4D6174682E726F756E6428642E696E64656E742A35362E37297D3A766F696420302C73706163696E673A7B61667465723A642E70';
wwv_flow_imp.g_varchar2_table(1033) := '6172616772617068476170213D3D766F696420303F4D6174682E726F756E6428642E7061726167726170684761702A35362E37293A3132302C6C696E653A4D6174682E726F756E64283234302A28642E6C696E654865696768747C7C312E313529297D2C';
wwv_flow_imp.g_varchar2_table(1034) := '6368696C6472656E3A686E28522C7B666F6E743A642E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A642E636F6C6F722C6C696E6B3A612E6C696E6B7D292E7265647563652866756E6374696F6E284A2C7465297B7661';
wwv_flow_imp.g_varchar2_table(1035) := '72206D653D6E657720742E5465787452756E287B746578743A74652E742C626F6C643A21212874652E627C7C642E626F6C64292C6974616C6963733A21212874652E697C7C642E6974616C6963292C73697A653A28642E73697A657C7C3130292A322C75';
wwv_flow_imp.g_varchar2_table(1036) := '6E6465726C696E653A74652E753F7B7D3A766F696420302C737472696B653A212174652E732C636F6C6F723A74652E633F47652874652E63293A766F696420302C666F6E743A68745B74652E665D5B315D7D293B72657475726E2074652E683F4A2E6C61';
wwv_flow_imp.g_varchar2_table(1037) := '737426264A2E6C6173742E683D3D3D74652E683F284A2E6C6173742E72756E732E70757368286D65292C4A293A284A2E6C6173743D7B683A74652E682C72756E733A5B6D655D7D2C4A2E70757368284A2E6C617374292C4A293A284A2E70757368286D65';
wwv_flow_imp.g_varchar2_table(1038) := '292C4A2E6C6173743D6E756C6C2C4A297D2C5B5D292E6D61702866756E6374696F6E284A297B72657475726E204A2E72756E733F6E657720742E45787465726E616C48797065726C696E6B287B6C696E6B3A4A2E682C6368696C6472656E3A4A2E72756E';
wwv_flow_imp.g_varchar2_table(1039) := '737D293A4A7D297D29297D297D656C736520696628703D3D3D226573706163696F2229432E70757368286E657720742E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E642828642E';
wwv_flow_imp.g_varchar2_table(1040) := '6865696768747C7C36292A35362E37297D7D29293B656C736520696628703D3D3D226C696E656122297B696628642E78313D3D3D766F69642030297B7661722053723D4D6174682E726F756E642828642E77696474687C7C30292A35362E37292C72723D';
wwv_flow_imp.g_varchar2_table(1041) := '53723F4D6174682E6D617828302C4D6174682E726F756E642828672D5372292F3229293A303B432E70757368286E657720742E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E6428';
wwv_flow_imp.g_varchar2_table(1042) := '28642E676170213D3D766F696420303F642E6761703A32292A35362E37297D2C696E64656E743A642E616C69676E3D3D3D2263656E746572223F7B6C6566743A72722C72696768743A72727D3A642E616C69676E3D3D3D227269676874223F7B6C656674';
wwv_flow_imp.g_varchar2_table(1043) := '3A72722A327D3A7B72696768743A72722A327D2C626F726465723A7B626F74746F6D3A7B7374796C653A742E426F726465725374796C652E53494E474C452C73697A653A4D6174682E6D617828322C4D6174682E726F756E642828642E746869636B6E65';
wwv_flow_imp.g_varchar2_table(1044) := '73737C7C2E33292A323029292C636F6C6F723A476528642E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C736520696628703D3D3D22696D6167656E22297B766172204C723D587428642C53293B6966284C72297B';
wwv_flow_imp.g_varchar2_table(1045) := '7661722059723D537428642C4C72293B432E707573682849284C722C59722E772C59722E682C642C766F696420302C6D7228642C532C642E736F757263653F4F6528642C53295B305D3A6E756C6C2929297D7D656C736520696628703D3D3D2267726166';
wwv_flow_imp.g_varchar2_table(1046) := '69636F22297B7661722058653D517428642C532C61293B58652626432E7075736828492858652C58652E776D6D2C58652E686D6D2C6429297D656C736520696628703D3D3D22636F6469676F22297B766172206F723D4A7428642C53293B6966286F7229';
wwv_flow_imp.g_varchar2_table(1047) := '7B766172207A653D5F6E286F72293B432E707573682849287A652C7A652E776D6D2C7A652E686D6D2C642C6F722E6C6162656C3F303A766F6964203029292C6F722E6C6162656C2626432E70757368286E657720742E506172616772617068287B616C69';
wwv_flow_imp.g_varchar2_table(1048) := '676E6D656E743A642E616C69676E3D3D3D227269676874223F742E416C69676E6D656E74547970652E52494748543A642E616C69676E3D3D3D2263656E746572223F742E416C69676E6D656E74547970652E43454E5445523A742E416C69676E6D656E74';
wwv_flow_imp.g_varchar2_table(1049) := '547970652E4C4546542C696E64656E743A642E616C69676E3D3D3D227269676874227C7C642E616C69676E3D3D3D2263656E746572223F766F696420303A7B6C6566743A4D6174682E6D617828302C4D6174682E726F756E6428287A652E776D6D2D6F72';
wwv_flow_imp.g_varchar2_table(1050) := '2E746578742E6C656E6774682A6F722E7465787453697A652A2E333532382A2E36292F322A35362E3729297D2C73706163696E673A7B61667465723A4D6174682E726F756E642828642E676170213D3D766F696420303F642E6761703A33292A35362E37';
wwv_flow_imp.g_varchar2_table(1051) := '297D2C6368696C6472656E3A5B6E657720742E5465787452756E287B746578743A6F722E746578742C666F6E743A22436F7572696572204E6577222C73697A653A6F722E7465787453697A652A322C636F6C6F723A4765286F722E636F6C6F72297D295D';
wwv_flow_imp.g_varchar2_table(1052) := '7D29297D7D656C736520696628703D3D3D2273616C746F2229432E70757368286E657720742E506172616772617068287B6368696C6472656E3A5B6E657720742E50616765427265616B5D7D29293B656C736520696628703D3D3D22666963686122297B';
wwv_flow_imp.g_varchar2_table(1053) := '7661722050653D4F6528642C53295B305D7C7C7B7D2C5A653D642E636F6C756D6E737C7C332C44723D5B5D2C54723D5B5D3B6966286F742828642E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2852297B72657475726E21522E77';
wwv_flow_imp.g_varchar2_table(1054) := '68656E7C7C657228522E7768656E2C532C5065297D292C5A65292E666F72456163682866756E6374696F6E2852297B522E666F72456163682866756E6374696F6E287465297B766172206D653D74652E662C76653D2121642E677269642C62723D76653F';
wwv_flow_imp.g_varchar2_table(1055) := '36303A766F696420303B69662874652E656D707479297B7661722079653D7B7374796C653A742E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D3B54722E70757368286E657720742E5461626C654365';
wwv_flow_imp.g_varchar2_table(1056) := '6C6C287B6368696C6472656E3A5B6E657720742E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A74652E7370616E2A322C626F72646572733A76653F7B746F703A79652C626F74746F6D3A79652C6C656674';
wwv_flow_imp.g_varchar2_table(1057) := '3A79652C72696768743A79657D3A766F696420307D29293B72657475726E7D7661722045653D7574286D652C64292C46723D56286D652E6C6162656C2C532C5065293B69662845652E706F73213D3D226C65667422297B766172205F653D7674286D652C';
wwv_flow_imp.g_varchar2_table(1058) := '532C5065292C77723D5B5D2C50723D76653F36303A33303B45652E706F733D3D3D22746F7022262677722E70757368284D2863722846722C4565292C45652C45652E616C69676E7C7C5F6526265F652E616C69676E7C7C226C6566742229292C77722E70';
wwv_flow_imp.g_varchar2_table(1059) := '7573682876287A72286D652C532C5065292C7B73697A653A31372C636F6C6F723A5F6526265F652E636F6C6F727C7C642E76616C7565436F6C6F722C626F6C643A5F653F5F652E626F6C643A766F696420302C616C69676E3A5F653F5F652E616C69676E';
wwv_flow_imp.g_varchar2_table(1060) := '3A766F696420302C6C696E6B3A6D72286D652C532C5065292C6C696E6B436F6C6F723A5F6526265F652E636F6C6F727C7C612E6C696E6B7D29292C54722E70757368286E657720742E5461626C6543656C6C287B6368696C6472656E3A77722C636F6C75';
wwv_flow_imp.g_varchar2_table(1061) := '6D6E5370616E3A74652E7370616E2A322C6D617267696E733A7B746F703A50722C626F74746F6D3A50722C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A76653F742E566572746963616C416C69676E2E43454E544552';
wwv_flow_imp.g_varchar2_table(1062) := '3A766F696420302C73686164696E673A5F6526265F652E66696C6C3F7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A4765285F652E66696C6C297D3A766F696420307D29293B7265747572';
wwv_flow_imp.g_varchar2_table(1063) := '6E7D54722E7075736828412863722846722C4565292C45652E7374796C65643F7B626F6C643A45652E626F6C642C73697A653A45652E73697A653F4D6174682E726F756E642845652E73697A652A32293A31372C66696C6C3A45652E66696C6C2C636F6C';
wwv_flow_imp.g_varchar2_table(1064) := '6F723A45652E636F6C6F722C616C69676E3A45652E616C69676E2C7061643A62722C6D6964646C653A76657D3A7B626F6C643A21302C73697A653A31372C66696C6C3A642E6C6162656C46696C6C2C636F6C6F723A642E6C6162656C436F6C6F722C7061';
wwv_flow_imp.g_varchar2_table(1065) := '643A62722C6D6964646C653A76657D292C2866756E6374696F6E286872297B72657475726E2041287A72286D652C532C5065292C7B73697A653A31372C636F6C6F723A6872262668722E636F6C6F727C7C642E76616C7565436F6C6F722C7061643A6272';
wwv_flow_imp.g_varchar2_table(1066) := '2C6D6964646C653A76652C626F6C643A68723F68722E626F6C643A766F696420302C616C69676E3A68723F68722E616C69676E3A766F696420302C66696C6C3A68723F68722E66696C6C3A766F696420302C6C696E6B3A6D72286D652C532C5065292C6C';
wwv_flow_imp.g_varchar2_table(1067) := '696E6B436F6C6F723A6872262668722E636F6C6F727C7C612E6C696E6B2C7370616E3A74652E7370616E3E313F74652E7370616E2A322D313A766F696420307D297D29287674286D652C532C50652929297D293B666F7228766172204A3D56742852292A';
wwv_flow_imp.g_varchar2_table(1068) := '323B4A3C5A652A323B4A2B2B2954722E70757368284128222229293B44722E70757368286E657720742E5461626C65526F77287B6368696C6472656E3A54727D29292C54723D5B5D7D292C44722E6C656E677468297B7661722054653D5B5D3B69662864';
wwv_flow_imp.g_varchar2_table(1069) := '2E677269647C7C41727261792E6973417272617928642E6C6162656C57696474687329297B666F72287661722062653D5B5D2C43723D302C63653D303B63653C5A653B63652B2B2962652E70757368284D6174682E726F756E64284E6E28642C6365292A';
wwv_flow_imp.g_varchar2_table(1070) := '35362E3729292C43722B3D62655B63655D3B7661722049723D4D6174682E6D6178283630302C4D6174682E726F756E642828672D4372292F5A6529293B666F722863653D303B63653C5A653B63652B2B2954652E707573682862655B63655D2C4972297D';
wwv_flow_imp.g_varchar2_table(1071) := '656C736520666F72287661722051653D303B51653C5A652A323B51652B2B2954652E70757368284D6174682E726F756E6428672F285A652A322929293B432E70757368286E657720742E5461626C65287B726F77733A44722C77696474683A7B73697A65';
wwv_flow_imp.g_varchar2_table(1072) := '3A672C747970653A742E5769647468547970652E4458417D2C636F6C756D6E5769647468733A54652C626F72646572733A642E677269643F5028642E626F72646572436F6C6F727C7C6B72293A542C6C61796F75743A642E677269643F742E5461626C65';
wwv_flow_imp.g_varchar2_table(1073) := '4C61796F7574547970652E46495845443A766F696420307D292C792829297D7D656C736520696628703D3D3D227461726A6574617322297B7661722077653D627428642C532C61293B6966282177652E6974656D732E6C656E6774682972657475726E3B';
wwv_flow_imp.g_varchar2_table(1074) := '666F72287661722055723D4D6174682E726F756E642877652E636172644761702A35362E37292C5F723D4D6174682E666C6F6F722828672D55722A2877652E6E2D3129292F77652E6E292C52723D5B5D2C6A723D5B5D2C42723D303B42723C77652E6E3B';
wwv_flow_imp.g_varchar2_table(1075) := '42722B2B29427226266A722E70757368285572292C6A722E70757368285F72293B666F7228766172204E653D7B7374796C653A742E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C71723D303B7172';
wwv_flow_imp.g_varchar2_table(1076) := '3C77652E6974656D732E6C656E6774683B71722B3D77652E6E297B666F72287661722078723D5B5D2C75723D303B75723C77652E6E3B75722B2B297B7661722076723D77652E6974656D735B71722B75725D3B6966287572262678722E70757368286E65';
wwv_flow_imp.g_varchar2_table(1077) := '7720742E5461626C6543656C6C287B6368696C6472656E3A5B76282222295D2C626F72646572733A7B746F703A4E652C626F74746F6D3A4E652C6C6566743A4E652C72696768743A4E657D7D29292C217672297B78722E70757368286E657720742E5461';
wwv_flow_imp.g_varchar2_table(1078) := '626C6543656C6C287B6368696C6472656E3A5B76282222295D2C626F72646572733A7B746F703A4E652C626F74746F6D3A4E652C6C6566743A4E652C72696768743A4E657D7D29293B636F6E74696E75657D78722E70757368286E657720742E5461626C';
wwv_flow_imp.g_varchar2_table(1079) := '6543656C6C287B6368696C6472656E3A5B762876722E6C6162656C2C7B73697A653A77652E6C6162656C53697A652A322C636F6C6F723A77652E6C6162656C436F6C6F727D292C6E657720742E506172616772617068287B6368696C6472656E3A5B7065';
wwv_flow_imp.g_varchar2_table(1080) := '2876722E76616C75652C7B626F6C643A21302C73697A653A77652E73697A652A322C636F6C6F723A76722E636F6C6F727C7C77652E76616C7565436F6C6F727D295D2C73706163696E673A7B6265666F72653A34302C61667465723A307D7D295D2C6D61';
wwv_flow_imp.g_varchar2_table(1081) := '7267696E733A7B746F703A3130302C626F74746F6D3A3130302C6C6566743A3136302C72696768743A3130307D2C766572746963616C416C69676E3A742E566572746963616C416C69676E2E43454E5445522C73686164696E673A7B747970653A742E53';
wwv_flow_imp.g_varchar2_table(1082) := '686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A47652877652E66696C6C297D2C626F72646572733A7B746F703A4E652C626F74746F6D3A4E652C72696768743A4E652C6C6566743A77652E616363656E743F7B73';
wwv_flow_imp.g_varchar2_table(1083) := '74796C653A742E426F726465725374796C652E53494E474C452C73697A653A32342C636F6C6F723A47652877652E616363656E74297D3A4E657D7D29297D52722E6C656E677468262652722E70757368286E657720742E5461626C65526F77287B686569';
wwv_flow_imp.g_varchar2_table(1084) := '6768743A7B76616C75653A55722C72756C653A742E48656967687452756C652E45584143547D2C6368696C6472656E3A6A722E6D61702866756E6374696F6E28297B72657475726E206E657720742E5461626C6543656C6C287B6368696C6472656E3A5B';
wwv_flow_imp.g_varchar2_table(1085) := '76282222295D2C626F72646572733A7B746F703A4E652C626F74746F6D3A4E652C6C6566743A4E652C72696768743A4E657D7D297D297D29292C52722E70757368286E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C64';
wwv_flow_imp.g_varchar2_table(1086) := '72656E3A78727D29297D432E70757368286E657720742E5461626C65287B726F77733A52722C77696474683A7B73697A653A672C747970653A742E5769647468547970652E4458417D2C636F6C756D6E5769647468733A6A722C626F72646572733A542C';
wwv_flow_imp.g_varchar2_table(1087) := '6C61796F75743A742E5461626C654C61796F7574547970652E46495845447D292C792829297D656C736520696628703D3D3D22666F726D756C6172696F22297B7661722074723D642E636F6C756D6E737C7C322C58723D5B5D2C67723D5B5D2C6E723D31';
wwv_flow_imp.g_varchar2_table(1088) := '2C4E3D786E28642C532C5A292C473D7B7374796C653A742E426F726465725374796C652E53494E474C452C73697A653A342C636F6C6F723A476528436E297D2C483D66756E6374696F6E28297B58722E70757368286E657720742E5461626C65526F7728';
wwv_flow_imp.g_varchar2_table(1089) := '7B6368696C6472656E3A67722C63616E7453706C69743A21302C6865696768743A6E723E313F7B76616C75653A4D6174682E726F756E64283233302A6E722B313230292C72756C653A742E48656967687452756C652E41544C454153547D3A766F696420';
wwv_flow_imp.g_varchar2_table(1090) := '307D29292C67723D5B5D2C6E723D317D3B6966286F74284E2C7472292E666F72456163682866756E6374696F6E2852297B522E666F72456163682866756E6374696F6E287465297B766172206D653D74652E663B69662874652E656D707479297B67722E';
wwv_flow_imp.g_varchar2_table(1091) := '70757368286E657720742E5461626C6543656C6C287B6368696C6472656E3A5B6E657720742E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A74652E7370616E2A327D29293B72657475726E7D75286D652E';
wwv_flow_imp.g_varchar2_table(1092) := '6E616D65293B7661722076653D6F2E6C656E6774683B6F2E70757368286D65292C6E723D4D6174682E6D6178286E722C6D652E6C696E6573293B7661722062723D6D652E6C696E65733E313F742E566572746963616C416C69676E2E544F503A742E5665';
wwv_flow_imp.g_varchar2_table(1093) := '72746963616C416C69676E2E43454E5445522C79653D6D652E6C61623B69662879652E706F73213D3D226C65667422297B7661722045653D6E657720742E5461626C65287B77696474683A7B73697A653A3130302C747970653A742E5769647468547970';
wwv_flow_imp.g_varchar2_table(1094) := '652E50455243454E544147457D2C626F72646572733A542C726F77733A5B6E657720742E5461626C65526F77287B6865696768743A6D652E6C696E65733E313F7B76616C75653A4D6174682E726F756E64283233302A6D652E6C696E65732B3630292C72';
wwv_flow_imp.g_varchar2_table(1095) := '756C653A742E48656967687452756C652E41544C454153547D3A766F696420302C6368696C6472656E3A5B6E657720742E5461626C6543656C6C287B6368696C6472656E3A5B6E657720742E506172616772617068287B6368696C6472656E3A5B706528';
wwv_flow_imp.g_varchar2_table(1096) := '476E2B76652B486E2C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C766572746963616C416C69676E3A62722C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36';
wwv_flow_imp.g_varchar2_table(1097) := '302C72696768743A36307D2C626F72646572733A7B746F703A472C626F74746F6D3A472C6C6566743A472C72696768743A477D2C73686164696E673A7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66';
wwv_flow_imp.g_varchar2_table(1098) := '696C6C3A4765284774297D7D295D7D295D7D292C46723D79652E706F733D3D3D22746F70223F5B4D286372286D652E6C6162656C2C7965292C79652C79652E616C69676E7C7C226C65667422295D3A5B5D3B46722E707573682845652C6E657720742E50';
wwv_flow_imp.g_varchar2_table(1099) := '6172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A302C61667465723A302C6C696E653A3132302C6C696E6552756C653A742E4C696E6552756C65547970652E45584143547D7D29292C67722E70757368286E';
wwv_flow_imp.g_varchar2_table(1100) := '657720742E5461626C6543656C6C287B6368696C6472656E3A46722C636F6C756D6E5370616E3A74652E7370616E2A322C766572746963616C416C69676E3A742E566572746963616C416C69676E2E544F502C6D617267696E733A7B746F703A33302C62';
wwv_flow_imp.g_varchar2_table(1101) := '6F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D29293B72657475726E7D67722E70757368286E657720742E5461626C6543656C6C287B6368696C6472656E3A5B79652E7374796C65643F76286372286D652E6C6162656C2C7965292C';
wwv_flow_imp.g_varchar2_table(1102) := '7B626F6C643A79652E626F6C642C73697A653A79652E73697A653F4D6174682E726F756E642879652E73697A652A32293A31372C636F6C6F723A79652E636F6C6F722C616C69676E3A79652E616C69676E7D293A76286D652E6C6162656C2C7B626F6C64';
wwv_flow_imp.g_varchar2_table(1103) := '3A21302C73697A653A31377D295D2C766572746963616C416C69676E3A62722C73686164696E673A79652E7374796C6564262679652E66696C6C3F7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C6669';
wwv_flow_imp.g_varchar2_table(1104) := '6C6C3A47652879652E66696C6C297D3A766F696420302C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D292C6E657720742E5461626C6543656C6C287B6368696C6472656E3A5B6E657720';
wwv_flow_imp.g_varchar2_table(1105) := '742E506172616772617068287B6368696C6472656E3A5B706528476E2B76652B486E2C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C636F6C756D6E5370616E3A74652E7370616E3E313F7465';
wwv_flow_imp.g_varchar2_table(1106) := '2E7370616E2A322D313A766F696420302C766572746963616C416C69676E3A62722C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A472C626F74746F6D3A';
wwv_flow_imp.g_varchar2_table(1107) := '472C6C6566743A472C72696768743A477D2C73686164696E673A7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A4765284774297D7D29297D293B666F7228766172204A3D56742852292A32';
wwv_flow_imp.g_varchar2_table(1108) := '3B4A3C74722A323B4A2B2B2967722E70757368284128222229293B4828297D292C58722E6C656E677468297B76617220573D5B5D2C553D4D6174682E726F756E642828642E6C6162656C57696474687C7C3332292A35362E37292C6C653D4D6174682E6D';
wwv_flow_imp.g_varchar2_table(1109) := '6178283630302C4D6174682E726F756E642828672D552A7472292F747229293B552A74722B3630302A74723E67262628553D6C653D4D6174682E726F756E6428672F2874722A322929293B666F72287661722043653D303B43653C74723B43652B2B2957';
wwv_flow_imp.g_varchar2_table(1110) := '2E7075736828552C6C65293B432E70757368286E657720742E5461626C65287B726F77733A58722C77696474683A7B73697A653A672C747970653A742E5769647468547970652E4458417D2C636F6C756D6E5769647468733A572C626F72646572733A54';
wwv_flow_imp.g_varchar2_table(1111) := '2C6C61796F75743A742E5461626C654C61796F7574547970652E46495845447D292C792829297D7D656C736520696628703D3D3D22616C6572746122294F6528642C53292E66696C7465722866756E6374696F6E2852297B72657475726E20657228642E';
wwv_flow_imp.g_varchar2_table(1112) := '7768656E2C532C52297D292E736C69636528302C642E656163683F3939393A31292E666F72456163682866756E6374696F6E2852297B432E70757368286E657720742E5461626C65287B726F77733A5B6E657720742E5461626C65526F77287B6368696C';
wwv_flow_imp.g_varchar2_table(1113) := '6472656E3A5B41285628642E746578742C532C52292C7B626F6C643A21302C73697A653A31372C66696C6C3A707428642E636F6C6F722C532C52297C7C2223453645434632227D295D7D295D2C77696474683A7B73697A653A672C747970653A742E5769';
wwv_flow_imp.g_varchar2_table(1114) := '647468547970652E4458417D2C636F6C756D6E5769647468733A5B675D2C626F72646572733A547D292C792829297D293B656C736520696628703D3D3D227461626C6122297B766172204F3D4F6528642C53293B696628214F2E6C656E6774682626642E';
wwv_flow_imp.g_varchar2_table(1115) := '68696465456D707479213D3D2131262621642E656D707479546578742972657475726E3B76617220713D686128642C4F293B69662871297B712E666F72456163682866756E6374696F6E28522C4A297B4A2626432E70757368286E657720742E50617261';
wwv_flow_imp.g_varchar2_table(1116) := '6772617068287B6368696C6472656E3A5B6E657720742E50616765427265616B5D7D29292C73652852297D293B72657475726E7D76617220513D677428642C532C4F292C6F653D5B5D3B642E7469746C6526266F652E70757368286E657720742E546162';
wwv_flow_imp.g_varchar2_table(1117) := '6C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A5B41285628642E7469746C652C53292C7B626F6C643A21302C636F6C6F723A612E68656164546578742C66696C6C3A612E7072696D6172792C7370616E3A512E6C656E6774';
wwv_flow_imp.g_varchar2_table(1118) := '682C73697A653A622B327D295D7D29292C642E67726F75707326266F652E70757368286E657720742E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A6A7428642C51292E6D61702866756E6374696F6E2852297B72';
wwv_flow_imp.g_varchar2_table(1119) := '657475726E204128522E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A612E68656164546578742C66696C6C3A612E7072696D6172792C616C69676E3A2263656E746572222C7370616E3A522E636F6C737D297D297D29292C6F652E7075';
wwv_flow_imp.g_varchar2_table(1120) := '7368286E657720742E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A512E6D61702866756E6374696F6E2852297B72657475726E204128522E6C6162656C2C7B626F6C643A21302C636F6C6F723A612E6865616454';
wwv_flow_imp.g_varchar2_table(1121) := '6578742C66696C6C3A612E7072696D6172792C616C69676E3A6C7428522C64297D297D297D29292C4F2E6C656E6774687C7C6F652E70757368286E657720742E5461626C65526F77287B6368696C6472656E3A5B41285628642E656D707479546578742C';
wwv_flow_imp.g_varchar2_table(1122) := '53292C7B6974616C69633A21302C7370616E3A512E6C656E6774687D295D7D29293B7661722075653D5F742864292C49653D7B7D2C67653D636E28642C51292C41653D66756E6374696F6E2852297B766172204A3D4128522E746578742C7B626F6C643A';
wwv_flow_imp.g_varchar2_table(1123) := '21302C616C69676E3A226C656674222C66696C6C3A612E746F74616C732C7370616E3A522E61747C7C512E6C656E6774682C636F6C6F723A642E746F74616C73436F6C6F727D292C74653D522E63656C6C732E736C69636528522E6174292E6D61702866';
wwv_flow_imp.g_varchar2_table(1124) := '756E6374696F6E286D65297B72657475726E2041286D652C7B626F6C643A21302C616C69676E3A227269676874222C66696C6C3A612E746F74616C732C636F6C6F723A642E746F74616C73436F6C6F727D297D293B72657475726E20522E61743D3D3D30';
wwv_flow_imp.g_varchar2_table(1125) := '3F5B6E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B4A5D7D292C6E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A74657D295D3A5B6E657720742E546162';
wwv_flow_imp.g_varchar2_table(1126) := '6C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B4A5D2E636F6E636174287465297D295D7D3B696628536E28642C4F292E666F72456163682866756E6374696F6E2852297B696628522E6B3D3D3D226865616422297B6F652E70';
wwv_flow_imp.g_varchar2_table(1127) := '757368286E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B4128697428642C522C53292C7B626F6C643A21302C66696C6C3A546E28612C522E6C766C292C7370616E3A512E6C656E6774687D295D7D2929';
wwv_flow_imp.g_varchar2_table(1128) := '3B72657475726E7D696628522E6B3D3D3D2273756222297B4165286D7428512C75652C522E726F77732C697428642C522C532929292E666F72456163682866756E6374696F6E287665297B6F652E70757368287665297D293B72657475726E7D76617220';
wwv_flow_imp.g_varchar2_table(1129) := '4A3D522E722C74653D522E692C6D653D6E7428642E726F775374796C652C532C4A293B6F652E70757368286E657720742E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A512E6D61702866756E6374696F6E2876652C62';
wwv_flow_imp.g_varchar2_table(1130) := '72297B7661722079653D6E742876652E63656C6C5374796C652C532C4A297C7C6D657C7C7B7D3B69662876652E63656C6C297B7661722045653D766E2876652C4A2C532C61292C46723D79652E66696C6C7C7C28746525323D3D3D312626642E7A656272';
wwv_flow_imp.g_varchar2_table(1131) := '61213D3D21313F612E7A656272613A6E756C6C293B456526262849655B62725D3D4D6174682E6D61782849655B62725D7C7C302C45652E7729293B766172205F653D76652E76616C69676E7C7C67653B72657475726E206E657720742E5461626C654365';
wwv_flow_imp.g_varchar2_table(1132) := '6C6C287B766572746963616C416C69676E3A5F653D3D3D22746F70223F742E566572746963616C416C69676E2E544F503A5F653D3D3D22626F74746F6D223F742E566572746963616C416C69676E2E424F54544F4D3A742E566572746963616C416C6967';
wwv_flow_imp.g_varchar2_table(1133) := '6E2E43454E5445522C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A46723F7B747970653A742E53686164696E67547970652E434C4541522C636F6C6F723A22617574';
wwv_flow_imp.g_varchar2_table(1134) := '6F222C66696C6C3A4765284672297D3A766F696420302C6368696C6472656E3A5B6E657720742E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A76652E616C69676E3D3D3D2272';
wwv_flow_imp.g_varchar2_table(1135) := '69676874223F742E416C69676E6D656E74547970652E52494748543A76652E616C69676E3D3D3D226C656674223F742E416C69676E6D656E74547970652E4C4546543A742E416C69676E6D656E74547970652E43454E5445522C6368696C6472656E3A45';
wwv_flow_imp.g_varchar2_table(1136) := '653F5B2866756E6374696F6E2877722C5072297B72657475726E2050723F6E657720742E45787465726E616C48797065726C696E6B287B6C696E6B3A50722C6368696C6472656E3A5B77725D7D293A77727D29286E657720742E496D61676552756E287B';
wwv_flow_imp.g_varchar2_table(1137) := '747970653A45652E696D2E6578743D3D3D226A7067223F226A7067223A22706E67222C646174613A45652E696D2E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E642845652E772A332E3738292C686569676874';
wwv_flow_imp.g_varchar2_table(1138) := '3A4D6174682E726F756E642845652E682A332E3738297D7D292C6D722876652C532C4A29295D3A5B5D7D295D7D297D72657475726E2041286D6E2876652C4A2C53292C7B76616C69676E3A76652E76616C69676E7C7C67652C616C69676E3A76652E616C';
wwv_flow_imp.g_varchar2_table(1139) := '69676E2C626F6C643A76652E626F6C647C7C79652E626F6C642C636F6C6F723A79652E636F6C6F727C7C76652E636F6C6F722C6C696E6B3A6D722876652C532C4A292C6C696E6B436F6C6F723A79652E636F6C6F727C7C76652E636F6C6F727C7C612E6C';
wwv_flow_imp.g_varchar2_table(1140) := '696E6B2C66696C6C3A79652E66696C6C7C7C28746525323D3D3D312626642E7A65627261213D3D21313F612E7A656272613A6E756C6C297D297D297D29297D292C617428642E746F74616C73292E6C656E67746826264F2E6C656E677468297B76617220';
wwv_flow_imp.g_varchar2_table(1141) := '24653D642E5F616C6C526F77737C7C4F3B4165286D7428512C617428642E746F74616C73292C24652C796E28642C532C24652929292E666F72456163682866756E6374696F6E2852297B6F652E707573682852297D297D7661722078653D512E6D617028';
wwv_flow_imp.g_varchar2_table(1142) := '66756E6374696F6E28522C4A297B72657475726E20522E77696474683F522E77696474682F32303A49655B4A5D3F4D6174682E6D617828312C2849655B4A5D2B34292F3230293A317D292C55653D78652E7265647563652866756E6374696F6E28522C4A';
wwv_flow_imp.g_varchar2_table(1143) := '297B72657475726E20522B4A7D2C30292C66723D78652E6D61702866756E6374696F6E2852297B72657475726E204D6174682E666C6F6F7228672A522F5565297D293B432E70757368286E657720742E5461626C65287B726F77733A6F652C7769647468';
wwv_flow_imp.g_varchar2_table(1144) := '3A7B73697A653A672C747970653A742E5769647468547970652E4458417D2C636F6C756D6E5769647468733A66722C626F72646572733A642E677269643D3D3D21313F543A5028642E677269643F642E626F72646572436F6C6F727C7C6B723A6E756C6C';
wwv_flow_imp.g_varchar2_table(1145) := '297D292C792829297D7D293B7661722061653D652E666F6F7465722C4B3D422853292C593D652E706167654865616465722626747970656F6620652E706167654865616465723D3D226F626A656374223F652E706167654865616465723A6E756C6C2C52';
wwv_flow_imp.g_varchar2_table(1146) := '653D7B706167653A7B73697A653A7B77696474683A735B305D2C6865696768743A735B315D2C6F7269656E746174696F6E3A6C3F742E506167654F7269656E746174696F6E2E4C414E4453434150453A742E506167654F7269656E746174696F6E2E504F';
wwv_flow_imp.g_varchar2_table(1147) := '5254524149547D2C6D617267696E3A7B746F703A682C626F74746F6D3A682C6C6566743A682C72696768743A687D7D7D2C57653D4B3F7B64656661756C743A4B7D3A766F696420302C783D61653F7B64656661756C743A6E657720742E466F6F74657228';
wwv_flow_imp.g_varchar2_table(1148) := '7B6368696C6472656E3A55612861652C532C61297D297D3A766F696420303B69662859297B7661722072653D68652853293B57653D7B64656661756C743A6E657720742E486561646572287B6368696C6472656E3A2872653F5B72655D3A5B5D292E636F';
wwv_flow_imp.g_varchar2_table(1149) := '6E636174285B7728592C53292C6E657720742E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C6368696C6472656E3A5B5D7D295D297D297D2C592E6669727374506167653D3D3D213126262852652E7469';
wwv_flow_imp.g_varchar2_table(1150) := '746C65506167653D21302C57652E66697273743D422853297C7C6E657720742E486561646572287B6368696C6472656E3A5B6E657720742E506172616772617068287B6368696C6472656E3A5B5D7D295D7D292C6165262628782E66697273743D6E6577';
wwv_flow_imp.g_varchar2_table(1151) := '20742E466F6F746572287B6368696C6472656E3A55612861652C532C61297D2929297D72657475726E20722E6C656E6774683E312626516928652926262852652E706167652E706167654E756D626572733D7B73746172743A317D292C7B686561646572';
wwv_flow_imp.g_varchar2_table(1152) := '733A57652C70726F706572746965733A52652C666F6F746572733A782C6368696C6472656E3A432E6C656E6774683F433A5B76282222295D7D7D292C48653D6E657720742E446F63756D656E74287B63726561746F723A226E6F76615265706F7274222C';
wwv_flow_imp.g_varchar2_table(1153) := '7469746C653A5628652E7469746C657C7C22222C725B305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A4C657D292C4A653D742E5061636B65722E746F426C6F623F742E5061636B65722E746F426C6F62284865292E7468656E2866756E';
wwv_flow_imp.g_varchar2_table(1154) := '6374696F6E2853297B72657475726E20532E61727261794275666665723F532E617272617942756666657228293A537D293A742E5061636B65722E746F427566666572284865293B72657475726E206F2E6C656E6774683F4A652E7468656E2866756E63';
wwv_flow_imp.g_varchar2_table(1155) := '74696F6E2853297B72657475726E206E6C28532C6F2C6D6128652C6E29297D293A4A657D76617220576E3D7B7D3B66756E6374696F6E20696C2865297B72657475726E20653F28653D24722865292C576E5B655D3F50726F6D6973652E7265736F6C7665';
wwv_flow_imp.g_varchar2_table(1156) := '28576E5B655D293A666574636828652C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2872297B69662821722E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F2064';
wwv_flow_imp.g_varchar2_table(1157) := '6573636172676172206C6120706C616E74696C6C612028222B722E7374617475732B222922293B72657475726E20722E617272617942756666657228297D292E7468656E2866756E6374696F6E2872297B72657475726E20576E5B655D3D722C727D2929';
wwv_flow_imp.g_varchar2_table(1158) := '3A50726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C612055524C206465206C6120706C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C6120576F726422292E2729297D66756E637469';
wwv_flow_imp.g_varchar2_table(1159) := '6F6E206C6C2865297B76617220723D7B7D2C6E3B666F72286E20696E20652E706172616D737C7C7B7D29725B6E5D3D652E706172616D735B6E5D3B666F72286E20696E20652E646F637C7C7B7D29725B6E5D3D652E646F635B6E5D3B666F72286E20696E';
wwv_flow_imp.g_varchar2_table(1160) := '20652E5329725B6E5D3D652E535B6E5D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D736E28292C722E544F4441593D4A6E28292C727D66756E6374696F6E206F6C2865';
wwv_flow_imp.g_varchar2_table(1161) := '297B76617220723D652E73706C697428227C22292C6E3D725B305D2E7472696D28292C743D725B315D3F725B315D2E7472696D28293A6E756C6C3B72657475726E7B6765743A66756E6374696F6E28612C69297B6966286E3D3D3D222E22297265747572';
wwv_flow_imp.g_varchar2_table(1162) := '6E20613B666F7228766172206F3D6E2E73706C697428222E22292C753D692626692E73636F70654C6973743F692E73636F70654C6973742E736C69636528292E7265766572736528293A5B615D2C733D303B733C752E6C656E6774683B732B2B297B666F';
wwv_flow_imp.g_varchar2_table(1163) := '7228766172206C3D755B735D2C683D21302C673D303B673C6F2E6C656E6774683B672B2B297B69662841727261792E69734172726179286C292626673E302626286C3D6C5B305D292C6C3D3D6E756C6C7C7C747970656F66206C213D226F626A65637422';
wwv_flow_imp.g_varchar2_table(1164) := '7C7C21286F5B675D696E206C29297B683D21313B627265616B7D6C3D6C5B6F5B675D5D7D696628682972657475726E207426262141727261792E69734172726179286C293F4B65286C2C74293A6C7D7D7D7D66756E6374696F6E20756C28652C72297B76';
wwv_flow_imp.g_varchar2_table(1165) := '6172206E3D6E65772077696E646F772E50697A5A69702865292C743D77696E646F772E646F637874656D706C617465722C613D6E65772074286E2C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A6F6C';
wwv_flow_imp.g_varchar2_table(1166) := '2C6E756C6C4765747465723A66756E6374696F6E28297B72657475726E22227D7D293B72657475726E20612E72656E646572286C6C287229292C50726F6D6973652E7265736F6C766528612E6765745A697028292E67656E6572617465287B747970653A';
wwv_flow_imp.g_varchar2_table(1167) := '226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445227D29297D66756E6374696F6E205F612865297B76617220723D7B7D2C6E3D7B7D3B72657475726E204F626A6563742E6B65797328657C7C7B7D292E666F72456163';
wwv_flow_imp.g_varchar2_table(1168) := '682866756E6374696F6E2874297B76617220613D655B745D2C693D612E636F6C737C7C5B5D3B6E5B745D3D7B7D2C692E666F72456163682866756E6374696F6E286F297B6E5B745D5B6F2E6E616D655D3D6F2E747970657D292C725B745D3D28612E726F';
wwv_flow_imp.g_varchar2_table(1169) := '77737C7C5B5D292E6D61702866756E6374696F6E286F297B76617220753D7B7D3B72657475726E20692E666F72456163682866756E6374696F6E28732C6C297B755B732E6E616D655D3D6F5B6C5D7D292C757D297D292C7B533A722C543A6E7D7D66756E';
wwv_flow_imp.g_varchar2_table(1170) := '6374696F6E20426128652C72297B766172206E3D652E532E444F43533B696628216E2972657475726E5B7B533A652E532C543A652E542C646F633A7B7D2C706172616D733A727D5D3B76617220743D7B7D3B72657475726E204F626A6563742E6B657973';
wwv_flow_imp.g_varchar2_table(1171) := '28652E53292E666F72456163682866756E6374696F6E2861297B6966282128613D3D3D22444F4353227C7C214F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E545B615D2C22444F435F4B455922292929';
wwv_flow_imp.g_varchar2_table(1172) := '7B76617220693D745B615D3D7B7D3B652E535B615D2E666F72456163682866756E6374696F6E286F297B76617220753D537472696E67286F2E444F435F4B4559293B28695B755D3D695B755D7C7C5B5D292E70757368286F297D297D7D292C6E2E6D6170';
wwv_flow_imp.g_varchar2_table(1173) := '2866756E6374696F6E2861297B76617220693D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E286F297B695B6F5D3D745B6F5D3F745B6F5D5B537472696E6728612E444F435F4B4559295D7C';
wwv_flow_imp.g_varchar2_table(1174) := '7C5B5D3A652E535B6F5D7D292C692E444F43533D5B615D2C7B533A692C543A652E542C646F633A612C706172616D733A727D7D297D66756E6374696F6E2041742865297B76617220723D646F63756D656E742E676574456C656D656E744279496428226E';
wwv_flow_imp.g_varchar2_table(1175) := '722D6176616E636522293B6966282165297B722626722E72656D6F766528293B72657475726E7D727C7C28723D646F63756D656E742E637265617465456C656D656E74282264697622292C722E69643D226E722D6176616E6365222C722E736574417474';
wwv_flow_imp.g_varchar2_table(1176) := '7269627574652822726F6C65222C2273746174757322292C722E7374796C652E637373546578743D22706F736974696F6E3A66697865643B72696768743A323470783B626F74746F6D3A323470783B7A2D696E6465783A313030303B70616464696E673A';
wwv_flow_imp.g_varchar2_table(1177) := '3134707820313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A653A313370783B626F782D736861646F773A30203870782032347078207267626128';
wwv_flow_imp.g_varchar2_table(1178) := '302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287229292C722E696E6E657248544D4C3D273C7370616E20636C6173733D2266612066612D7370696E6E6572206661';
wwv_flow_imp.g_varchar2_table(1179) := '2D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B263C3E225D2F672C66756E6374696F6E286E297B72657475726E7B2226223A2226';
wwv_flow_imp.g_varchar2_table(1180) := '616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B6E5D7D297D66756E6374696F6E20666C2865297B76617220723D77696E646F772E6F70656E2822222C225F626C616E6B22293B69662821722972';
wwv_flow_imp.g_varchar2_table(1181) := '657475726E206E756C6C3B696628747970656F662077696E646F772E636F744C6F616465723D3D2266756E6374696F6E22297472797B77696E646F772E636F744C6F616465722872293B766172206E3D722E646F63756D656E742E676574456C656D656E';
wwv_flow_imp.g_varchar2_table(1182) := '747342795461674E616D652822683122295B305D3B6E2626286E2E74657874436F6E74656E743D2247656E6572616E646F207265706F72746522297D63617463682874297B7D656C736520722E646F63756D656E742E777269746528273C21646F637479';
wwv_flow_imp.g_varchar2_table(1183) := '70652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C7469746C653E47656E6572616E646F207265706F727465E280A63C2F7469746C653E3C7374796C653E626F64797B6D617267696E3A303B6865';
wwv_flow_imp.g_varchar2_table(1184) := '696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D73657269663B62';
wwv_flow_imp.g_varchar2_table(1185) := '61636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B77696474683A353670783B6865696768743A353670783B626F726465723A35707820736F6C69642023643665';
wwv_flow_imp.g_varchar2_table(1186) := '3065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A72203173206C696E65617220696E66696E6974653B6D617267696E3A30206175746F20313870787D406B65';
wwv_flow_imp.g_varchar2_table(1187) := '796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A233562366237627D3C2F73';
wwv_flow_imp.g_varchar2_table(1188) := '74796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C68313E47656E6572616E646F207265706F7274653C2F68313E3C702069643D226D7367223E3C2F703E3C2F6469';
wwv_flow_imp.g_varchar2_table(1189) := '763E3C2F626F64793E3C2F68746D6C3E27292C722E646F63756D656E742E636C6F736528293B72657475726E20476128722C65292C727D66756E6374696F6E20476128652C72297B696628212821657C7C652E636C6F73656429297472797B6966287479';
wwv_flow_imp.g_varchar2_table(1190) := '70656F662077696E646F772E636F744C6F616465724D73673D3D2266756E6374696F6E222977696E646F772E636F744C6F616465724D736728652C72293B656C73657B766172206E3D652E646F63756D656E742E676574456C656D656E74427949642822';
wwv_flow_imp.g_varchar2_table(1191) := '6D736722293B6E2626286E2E74657874436F6E74656E743D72297D7D63617463682874297B7D7D66756E6374696F6E20736C28652C722C6E297B76617220743D6520696E7374616E63656F6620426C6F623F653A6E657720426C6F62285B655D2C7B7479';
wwv_flow_imp.g_varchar2_table(1192) := '70653A6E7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D292C613D646F63756D656E742E637265617465456C656D656E7428226122293B612E687265663D55524C2E6372656174654F626A65637455524C2874292C612E646F77';
wwv_flow_imp.g_varchar2_table(1193) := '6E6C6F61643D722C646F63756D656E742E626F64792E617070656E644368696C642861292C612E636C69636B28292C73657454696D656F75742866756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C28612E68726566292C612E72';
wwv_flow_imp.g_varchar2_table(1194) := '656D6F766528297D2C346533297D66756E6374696F6E20646C28652C722C6E297B76617220743D652E6B696E643D3D3D227A6970223F226170706C69636174696F6E2F7A6970223A46745B652E6B696E645D7C7C46742E646F63782C613D652E64617461';
wwv_flow_imp.g_varchar2_table(1195) := '20696E7374616E63656F6620426C6F623F652E646174613A6E657720426C6F62285B652E646174615D2C7B747970653A747D293B72657475726E206E65772050726F6D6973652866756E6374696F6E28692C6F297B76617220753D6E65772046696C6552';
wwv_flow_imp.g_varchar2_table(1196) := '65616465723B752E6F6E6572726F723D66756E6374696F6E28297B6F286E6577204572726F7228224E6F207365207075646F206C65657220656C206172636869766F2067656E657261646F2E2229297D2C752E6F6E6C6F61643D66756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(1197) := '7B76617220733D537472696E6728752E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292C6C3D5B5D2C683B666F7228683D303B683C732E6C656E6774683B682B3D336534296C2E7075736828732E73756273747228';
wwv_flow_imp.g_varchar2_table(1198) := '682C33653429293B617065782E7365727665722E70726F6365737328722E70726F636573732C7B7830313A652E6E616D652C7830323A742C7830333A6E2E7265706F72743D3D3D766F696420303F22223A537472696E67286E2E7265706F7274292C7830';
wwv_flow_imp.g_varchar2_table(1199) := '343A4A534F4E2E737472696E67696679286E2E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A6C7D2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2867297B696628672626672E6F6B3D3D3D2131';
wwv_flow_imp.g_varchar2_table(1200) := '297B6F286E6577204572726F7228672E6D73677C7C22456C207365727669646F72206E6F206775617264C3B320656C20646F63756D656E746F2E2229293B72657475726E7D6928677C7C7B7D297D2C66756E6374696F6E28672C6D2C54297B6F286E6577';
wwv_flow_imp.g_varchar2_table(1201) := '204572726F7228224E6F207365207075646F206775617264617220656E20656C207365727669646F723A20222B28547C7C6D2929297D297D2C752E7265616441734461746155524C2861297D297D66756E6374696F6E20787428652C72297B7472797B77';
wwv_flow_imp.g_varchar2_table(1202) := '696E646F772E617065782626617065782E6576656E742626617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C72297D6361746368286E297B7D7D66756E6374696F6E2048612865297B77696E';
wwv_flow_imp.g_varchar2_table(1203) := '646F772E617065782626617065782E6D6573736167653F617065782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D66756E6374696F6E2057612865297B77696E646F772E617065782626617065782E6D6573736167';
wwv_flow_imp.g_varchar2_table(1204) := '652626617065782E6D6573736167652E73686F7750616765537563636573732865297D7661722046743D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174';
wwv_flow_imp.g_varchar2_table(1205) := '732D6F6666696365646F63756D656E742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F726470726F636573';
wwv_flow_imp.g_varchar2_table(1206) := '73696E676D6C2E646F63756D656E74227D2C706C3D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E20656E28652C722C6E297B76';
wwv_flow_imp.g_varchar2_table(1207) := '617220743D5628652E66696C654E616D657C7C227265706F727465222C72292C613D706C5B6E5D3B72657475726E20743D742E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C2222292C646E2874292B222E222B617D66756E';
wwv_flow_imp.g_varchar2_table(1208) := '6374696F6E20566E28652C722C6E2C74297B72657475726E20653D3D3D22706466223F5A6928722C6E2C742E686F6F6B732C74293A653D3D3D22786C7378223F4A6928722C6E2C6E2E6C656E6774683E312C74293A653D3D3D22646F6378223F616C2872';
wwv_flow_imp.g_varchar2_table(1209) := '2C6E2C74293A653D3D3D22646F63782D74656D706C617465223F696C28742E74656D706C61746555726C292E7468656E2866756E6374696F6E2861297B72657475726E20756C28612C6E5B305D297D293A50726F6D6973652E72656A656374286E657720';
wwv_flow_imp.g_varchar2_table(1210) := '4572726F722822466F726D61746F206E6F20736F706F727461646F3A20222B6529297D66756E6374696F6E20566128652C72297B766172206E3D4E7428652E6C61796F7574292C743D7B7D2C613B666F72286120696E206529745B615D3D655B615D3B72';
wwv_flow_imp.g_varchar2_table(1211) := '657475726E20742E6C61796F75743D6E2C50726F6D6973652E616C6C285B4769286E292C6A69286E2C652E666F726D61747C7C2270646622295D292E7468656E2866756E6374696F6E28297B72657475726E20686C28742C72297D297D66756E6374696F';
wwv_flow_imp.g_varchar2_table(1212) := '6E20686C28652C72297B766172206E3D4E7428652E6C61796F7574292C743D652E666F726D61743D3D3D22616C6C223F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C613D5F612872292C693D4261';
wwv_flow_imp.g_varchar2_table(1213) := '28612C652E706172616D737C7C7B7D292C6F3D652E6F75747075747C7C2266696C65223B69662821692E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228652E656D7074794D6573736167657C7C6E2E65';
wwv_flow_imp.g_varchar2_table(1214) := '6D7074794D6573736167657C7C224E6F20686179206461746F7320706172612067656E6572617220656C207265706F7274652E2229293B6966286E2E626174636826266E2E62617463682E6D6178446F63732626692E6C656E6774683E6E2E6261746368';
wwv_flow_imp.g_varchar2_table(1215) := '2E6D6178446F63732972657475726E2050726F6D6973652E72656A656374286E6577204572726F722822456C206C6F74652073757065726120656C206DC3A178696D6F20646520222B6E2E62617463682E6D6178446F63732B2220646F63756D656E746F';
wwv_flow_imp.g_varchar2_table(1216) := '732E2229293B76617220753D6F3D3D3D2266696C65222626692E6C656E6774683D3D3D312626742E6C656E6774683D3D3D317C7C6F3D3D3D226D65726765222626742E6C656E6774683D3D3D312626745B305D213D3D22646F63782D74656D706C617465';
wwv_flow_imp.g_varchar2_table(1217) := '223B69662875297B76617220733D745B305D3B72657475726E20566E28732C6E2C692C65292E7468656E2866756E6374696F6E2841297B76617220793D656E286E2C695B305D2C73293B696628692E6C656E6774683E31297B766172204D3D6E2E626174';
wwv_flow_imp.g_varchar2_table(1218) := '63682626286E2E62617463682E6D657267654E616D657C7C6E2E62617463682E7A69704E616D65297C7C6E2E66696C654E616D657C7C227265706F727465223B793D656E287B66696C654E616D653A537472696E67284D292E7265706C616365282F5C2E';
wwv_flow_imp.g_varchar2_table(1219) := '7A6970242F692C2222297D2C7B533A612E532C543A612E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C73297D72657475726E7B6B696E643A732C646174613A412C6E616D653A792C636F756E743A692E6C656E6774687D7D';
wwv_flow_imp.g_varchar2_table(1220) := '297D766172206C3D6E65772077696E646F772E4A535A69702C683D302C673D302C6D3D6E2E626174636826266E2E62617463682E6368756E6B53697A657C7C352C543D7B7D2C463B666F72284620696E20652E706172616D737C7C7B7D29545B465D3D65';
wwv_flow_imp.g_varchar2_table(1221) := '2E706172616D735B465D3B542E464F524D41544F3D742E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74656D706C617465223A22776F7264227D5B';
wwv_flow_imp.g_varchar2_table(1222) := '745B305D5D3B76617220443D7B533A612E532C543A612E542C646F633A7B7D2C706172616D733A547D2C503D7B7D3B66756E6374696F6E206228412C79297B666F7228766172204D3D412C493D323B505B4D2E746F4C6F7765724361736528295D3B294D';
wwv_flow_imp.g_varchar2_table(1223) := '3D412E7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B492B22243122292C492B2B3B505B4D2E746F4C6F7765724361736528295D3D21302C6C2E66696C65284D2C79292C682B2B7D7661722070653D50726F6D6973652E7265736F6C7665';
wwv_flow_imp.g_varchar2_table(1224) := '28292C763D6E2E626174636826266E2E62617463682E73756D6D6172793B72657475726E207626266F3D3D3D227A69702226262870653D742E66696C7465722866756E6374696F6E2841297B72657475726E2041213D3D22646F63782D74656D706C6174';
wwv_flow_imp.g_varchar2_table(1225) := '65227D292E7265647563652866756E6374696F6E28412C79297B72657475726E20412E7468656E2866756E6374696F6E28297B766172204D3D762E6C61796F75747C7C7B706167653A6E2E706167652C666F6F7465723A762E666F6F7465727C7C6E2E66';
wwv_flow_imp.g_varchar2_table(1226) := '6F6F7465722C73656374696F6E733A762E73656374696F6E732C786C73783A762E786C73782C66696C654E616D653A762E66696C654E616D657D3B72657475726E204D2E66696C654E616D657C7C284D2E66696C654E616D653D762E66696C654E616D65';
wwv_flow_imp.g_varchar2_table(1227) := '7C7C2230305F726573756D656E22292C566E28792C4D2C5B445D2C65292E7468656E2866756E6374696F6E2849297B6228656E284D2C442C79292C49297D297D297D2C706529292C70652E7468656E2866756E6374696F6E28297B72657475726E206E65';
wwv_flow_imp.g_varchar2_table(1228) := '772050726F6D6973652866756E6374696F6E28412C79297B66756E6374696F6E204D28297B666F722876617220493D4D6174682E6D696E28672B6D2C692E6C656E677468292C5F3D50726F6D6973652E7265736F6C766528293B673C493B672B2B292866';
wwv_flow_imp.g_varchar2_table(1229) := '756E6374696F6E286665297B742E666F72456163682866756E6374696F6E2842297B5F3D5F2E7468656E2866756E6374696F6E28297B72657475726E20566E28422C6E2C5B66655D2C65292E7468656E2866756E6374696F6E2877297B6228656E286E2C';
wwv_flow_imp.g_varchar2_table(1230) := '66652C42292C77297D297D297D297D2928695B675D293B5F2E7468656E2866756E6374696F6E28297B696628652E6F6E50726F67726573732626652E6F6E50726F677265737328672C692E6C656E677468292C673C692E6C656E677468297B7365745469';
wwv_flow_imp.g_varchar2_table(1231) := '6D656F7574284D2C30293B72657475726E7D652E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C68292C6C2E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D707265737369';
wwv_flow_imp.g_varchar2_table(1232) := '6F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374696F6E286665297B76617220423D56286E2E626174636826266E2E62617463682E7A69704E616D657C7C22726570';
wwv_flow_imp.g_varchar2_table(1233) := '6F727465732E7A6970222C44293B41287B6B696E643A227A6970222C646174613A66652C6E616D653A646E282F5C2E7A6970242F692E746573742842293F423A422B222E7A697022292C636F756E743A692E6C656E6774682C66696C65733A687D297D2C';
wwv_flow_imp.g_varchar2_table(1234) := '79297D2C79297D73657454696D656F7574284D2C30297D297D297D66756E6374696F6E20676C28652C72297B766172206E3D5B5D3B72657475726E20652E666F72456163682866756E6374696F6E2874297B286F695B745D7C7C5B5D292E666F72456163';
wwv_flow_imp.g_varchar2_table(1235) := '682866756E6374696F6E2861297B6E2E696E6465784F662861293C3026266E2E707573682861297D297D292C7226266E2E7075736828226A737A697022292C6E7D66756E6374696F6E2050742865297B76617220723D5B5D3B66756E6374696F6E206E28';
wwv_flow_imp.g_varchar2_table(1236) := '61297B28617C7C5B5D292E666F72456163682866756E6374696F6E2869297B69262628692E747970653D3D3D22636F6469676F222626537472696E6728692E6B696E647C7C22717222292E746F4C6F7765724361736528293D3D3D227172222626722E69';
wwv_flow_imp.g_varchar2_table(1237) := '6E6465784F6628227172636F646522293C302626722E7075736828227172636F646522292C692E747970653D3D3D226772616669636F222626722E696E6465784F66282263686172746A7322293C302626722E70757368282263686172746A7322292C69';
wwv_flow_imp.g_varchar2_table(1238) := '2E747970653D3D3D22666F726D756C6172696F222626722E696E6465784F6628226A737A697022293C302626722E7075736828226A737A697022292C692E747970653D3D3D22636F6C756D6E617322262628692E636F6C737C7C5B5D292E666F72456163';
wwv_flow_imp.g_varchar2_table(1239) := '68286E292C626E5B692E747970655D26266E2828692E6669656C64737C7C5B5D292E6D61702866756E6374696F6E286F297B72657475726E206F26266F2E626C6F636B7D29292C692E747970653D3D3D22677275706F2226266E28692E73656374696F6E';
wwv_flow_imp.g_varchar2_table(1240) := '73292C692E747970653D3D3D227461626C612226266E2828692E636F6C756D6E737C7C5B5D292E6D61702866756E6374696F6E286F297B72657475726E206F26266F2E63656C6C7D2929297D297D6E28652E73656374696F6E73293B76617220743D652E';
wwv_flow_imp.g_varchar2_table(1241) := '62617463682626652E62617463682E73756D6D6172793B72657475726E20742626286E28742E73656374696F6E73292C742E6C61796F757426266E28742E6C61796F75742E73656374696F6E7329292C41727261792E6973417272617928652E61707065';
wwv_flow_imp.g_varchar2_table(1242) := '6E64292626652E617070656E642E6C656E6774682626722E7075736828227064666C696222292C727D66756E6374696F6E20726E28652C72297B696628747970656F6620653D3D22737472696E67222626652E6368617241742830293D3D3D2240222626';
wwv_flow_imp.g_varchar2_table(1243) := '722626725B652E7375627374722831295D213D3D766F696420302972657475726E20726E28725B652E7375627374722831295D2C72293B69662841727261792E697341727261792865292972657475726E20652E7265647563652866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(1244) := '742C61297B76617220693D747970656F6620613D3D22737472696E67222626612E6368617241742830293D3D3D224022262672262641727261792E6973417272617928725B612E7375627374722831295D292C6F3D726E28612C72293B72657475726E20';
wwv_flow_imp.g_varchar2_table(1245) := '693F742E636F6E636174286F293A742E636F6E636174285B6F5D297D2C5B5D293B696628652626747970656F6620653D3D226F626A65637422297B766172206E3D7B7D3B72657475726E204F626A6563742E6B6579732865292E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(1246) := '6E6374696F6E2874297B6E5B745D3D743D3D3D2264656673223F655B745D3A726E28655B745D2C72297D292C6E7D72657475726E20657D66756E6374696F6E204E742865297B76617220723B696628652626747970656F6620653D3D226F626A65637422';
wwv_flow_imp.g_varchar2_table(1247) := '29723D653B656C73657B766172206E3D537472696E6728657C7C2222292E7472696D28293B6966286E2E6368617241742830293D3D3D227B2229723D4A534F4E2E7061727365286E293B656C736520696628723D6E2E73706C697428222E22292E726564';
wwv_flow_imp.g_varchar2_table(1248) := '7563652866756E6374696F6E28742C61297B72657475726E20743F745B615D3A766F696420307D2C77696E646F77292C2172297468726F77206E6577204572726F7228224E6F20736520656E636F6E7472C3B320656C2064697365C3B16F3A20222B6E29';
wwv_flow_imp.g_varchar2_table(1249) := '7D72657475726E20726E28722C722E64656673297D66756E6374696F6E206D6C2865297B69662865297B69662841727261792E697341727261792865297C7C747970656F662065213D22737472696E67227C7C2F5B232E5C5B5D2F2E7465737428652929';
wwv_flow_imp.g_varchar2_table(1250) := '72657475726E20653B76617220723D652E73706C697428222C22292E6D61702866756E6374696F6E286E297B72657475726E206E2E7472696D28297D292E66696C74657228426F6F6C65616E293B72657475726E20722E6C656E6774683F723A766F6964';
wwv_flow_imp.g_varchar2_table(1251) := '20307D7D66756E6374696F6E2024612865297B76617220723D652E666F726D61743D3D3D22616C6C223F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C6E3D722E6C656E6774683D3D3D312626725B';
wwv_flow_imp.g_varchar2_table(1252) := '305D3D3D3D22706466222626652E6F7574707574213D3D227A6970222626652E706466416374696F6E213D3D22646F776E6C6F6164222C743D6E2626652E6C6F61646572213D3D21313F666C28652E6D6573736167657C7C22436F6E73756C74616E646F';
wwv_flow_imp.g_varchar2_table(1253) := '206461746F73E280A622293A6E756C6C2C613D77696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E73686F775370696E6E657228293A6E756C6C2C693D652E6F726967696E3D3D3D227265736F6C76657222262621652E64';
wwv_flow_imp.g_varchar2_table(1254) := '6174612C6F3D652E6F726967696E3D3D3D22717565727922262621652E646174612C753B69662821692626216F297472797B753D4E7428652E6C61796F7574297D6361746368286D297B72657475726E20612626612E72656D6F766528292C742626742E';
wwv_flow_imp.g_varchar2_table(1255) := '636C6F736528292C4861282244697365C3B16F20696E76C3A16C69646F3A20222B6D2E6D657373616765292C50726F6D6973652E72656A656374286D297D76617220733D7B6C61796F75743A752C666F726D61743A652E666F726D61742C6F7574707574';
wwv_flow_imp.g_varchar2_table(1256) := '3A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D706C61746555726C2C686F6F6B733A652E686F6F6B737C7C7B7D2C666F726D50617373776F72643A652E666F726D50617373776F72';
wwv_flow_imp.g_varchar2_table(1257) := '642C70646650617373776F72643A652E70646650617373776F72647D3B787428227374617274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C7265706F72743A693F652E7265706F72743A766F696420307D293B';
wwv_flow_imp.g_varchar2_table(1258) := '766172206C3D652E6F7574707574213D3D226D65726765222C683D4D7428676C28722C6C292E636F6E63617428697C7C6F3F5B5D3A507428752929292C673D652E646174613F50726F6D6973652E7265736F6C7665287B646174613A652E646174617D29';
wwv_flow_imp.g_varchar2_table(1259) := '3A6E65772050726F6D6973652866756E6374696F6E286D2C54297B76617220463D7B7830313A4A534F4E2E737472696E6769667928732E706172616D73292C7830323A652E6F75747075743D3D3D227A6970223F2259223A224E222C706167654974656D';
wwv_flow_imp.g_varchar2_table(1260) := '733A6D6C28652E6974656D73297D3B69662869297B696628652E7265706F72743D3D3D766F696420307C7C652E7265706F72743D3D3D6E756C6C7C7C652E7265706F72743D3D3D2222297B54286E6577204572726F722822496E646971756520656C2072';
wwv_flow_imp.g_varchar2_table(1261) := '65706F72746520612067656E657261722028646174612D7265706F7274292E2229293B72657475726E7D462E7830333D537472696E6728652E7265706F7274297D617065782E7365727665722E706C7567696E28652E616A61784964656E746966696572';
wwv_flow_imp.g_varchar2_table(1262) := '2C462C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2844297B69662821447C7C21442E6F6B297B54286E6577204572726F7228442626442E6D73677C7C224572726F7220616C206F6274656E6572206C6F7320646174';
wwv_flow_imp.g_varchar2_table(1263) := '6F732E2229293B72657475726E7D6D2844297D2C66756E6374696F6E28442C502C62297B54286E6577204572726F7228224572726F7220646520636F6D756E6963616369C3B36E3A20222B28627C7C502929297D297D293B72657475726E2050726F6D69';
wwv_flow_imp.g_varchar2_table(1264) := '73652E616C6C285B672C685D292E7468656E2866756E6374696F6E286D297B76617220543D6D5B305D2C463D50726F6D6973652E7265736F6C766528293B69662869297B7472797B753D4E7428542E6C61796F7574297D63617463682850297B7468726F';
wwv_flow_imp.g_varchar2_table(1265) := '77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B502E6D657373616765297D732E6C61796F75743D752C542E706172616D73262628732E706172616D733D542E706172616D73292C542E74656D706C61746555726C26';
wwv_flow_imp.g_varchar2_table(1266) := '2628732E74656D706C61746555726C3D542E74656D706C61746555726C292C463D4D74285074287529297D656C7365206966286F297B76617220443D542E6C61796F75747C7C652E6C61796F75743B6966282144297468726F77206E6577204572726F72';
wwv_flow_imp.g_varchar2_table(1267) := '282246616C746120656C2064697365C3B16F3A206C6120636F6E73756C74612064656C207265706F727465206E6F206465766F6C7669C3B3204C41594F5554207920656C20617472696275746F2044697365C3B16F20657374C3A120766163C3AD6F2E22';
wwv_flow_imp.g_varchar2_table(1268) := '293B7472797B753D4E742844297D63617463682850297B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B502E6D657373616765297D732E6C61796F75743D752C542E74656D706C61746555726C26262873';
wwv_flow_imp.g_varchar2_table(1269) := '2E74656D706C61746555726C3D542E74656D706C61746555726C292C463D4D74285074287529297D72657475726E20462E7468656E2866756E6374696F6E28297B72657475726E20542E646174617D297D292E7468656E2866756E6374696F6E286D297B';
wwv_flow_imp.g_varchar2_table(1270) := '61262628612E72656D6F766528292C613D6E756C6C293B76617220543D652E7472616E73666F726D2626652E7472616E73666F726D286D297C7C6D3B72657475726E20476128742C2241726D616E646F20656C20646F63756D656E746FE280A622292C73';
wwv_flow_imp.g_varchar2_table(1271) := '2E6F6E50726F67726573733D66756E6374696F6E28462C44297B463D3D3D2D313F41742822436F6D7072696D69656E646F20222B442B22206172636869766F73E280A622293A284174282247656E6572616E646F20222B462B2220646520222B442B22E2';
wwv_flow_imp.g_varchar2_table(1272) := '80A622292C7874282270726F6772657373222C7B646F6E653A462C746F74616C3A447D29297D2C566128732C54297D292E7468656E2866756E6374696F6E286D297B76617220543D652E736176657C7C732E6C61796F75742626732E6C61796F75742E73';
wwv_flow_imp.g_varchar2_table(1273) := '6176653B69662821547C7C21542E70726F636573732972657475726E206D3B696628212877696E646F772E617065782626617065782E73657276657229297468726F77206E6577204572726F7228224775617264617220656E20656C207365727669646F';
wwv_flow_imp.g_varchar2_table(1274) := '7220726571756965726520415045582E22293B72657475726E20417428224775617264616E646F20656E20656C207365727669646F72E280A622292C646C286D2C542C7B7265706F72743A652E7265706F72742C706172616D733A732E706172616D737D';
wwv_flow_imp.g_varchar2_table(1275) := '292E7468656E2866756E6374696F6E2846297B72657475726E206D2E73617665643D462C6D2E6F6E6C793D542E6D6F64653D3D3D226F6E6C79222C787428227361766564222C7B6E616D653A6D2E6E616D652C6B696E643A6D2E6B696E642C726573706F';
wwv_flow_imp.g_varchar2_table(1276) := '6E73653A467D292C6D7D297D292E7468656E2866756E6374696F6E286D297B696628417428292C6D2E6F6E6C7929742626742E636C6F736528292C5761286D2E736176656426266D2E73617665642E6D73677C7C22446F63756D656E746F206775617264';
wwv_flow_imp.g_varchar2_table(1277) := '61646F3A20222B6D2E6E616D65293B656C7365206966286D2E6B696E643D3D3D227064662226266E297B76617220543D55524C2E6372656174654F626A65637455524C286E657720426C6F62285B6D2E646174615D2C7B747970653A46742E7064667D29';
wwv_flow_imp.g_varchar2_table(1278) := '293B74262621742E636C6F7365643F742E6C6F636174696F6E2E687265663D543A77696E646F772E6F70656E28542C225F626C616E6B22297D656C736520742626742E636C6F736528292C736C286D2E646174612C6D2E6E616D652C6D2E6B696E643D3D';
wwv_flow_imp.g_varchar2_table(1279) := '3D227A6970223F226170706C69636174696F6E2F7A6970223A46745B6D2E6B696E645D7C7C46742E646F6378292C6D2E6B696E643D3D3D227A6970222626576128225A49502067656E657261646F3A20222B6D2E66696C65732B22206172636869766F73';
wwv_flow_imp.g_varchar2_table(1280) := '20646520222B6D2E636F756E742B2220646F63756D656E746F732E22293B72657475726E2078742822656E64222C7B6E616D653A6D2E6E616D652C636F756E743A6D2E636F756E742C66696C65733A6D2E66696C65737D292C6D7D292E63617463682866';
wwv_flow_imp.g_varchar2_table(1281) := '756E6374696F6E286D297B7468726F7720612626612E72656D6F766528292C417428292C74262621742E636C6F7365642626742E636C6F736528292C77696E646F772E636F6E736F6C652626636F6E736F6C652E6572726F72286D292C78742822657272';
wwv_flow_imp.g_varchar2_table(1282) := '6F72222C7B6D6573736167653A6D2E6D6573736167657D292C4861286D2E6D6573736167657C7C224E6F207365207075646F2067656E6572617220656C207265706F7274652E22292C6D7D297D76617220746E3D21312C59613D6E756C6C3B747970656F';
wwv_flow_imp.g_varchar2_table(1283) := '6620646F63756D656E74213D22756E646566696E6564222626646F63756D656E742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2865297B5961';
wwv_flow_imp.g_varchar2_table(1284) := '3D652E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D2C5B646174612D666F726D61745D22297C7C652E7461726765747D2C213029';
wwv_flow_imp.g_varchar2_table(1285) := '3B66756E6374696F6E20636C2865297B76617220723D746869732626746869732E616374696F6E3F746869733A7B7D2C6E3D722E616374696F6E7C7C7B7D2C743D722E74726967676572696E67456C656D656E747C7C59612C613D722E62726F77736572';
wwv_flow_imp.g_varchar2_table(1286) := '4576656E743B696628612626612E70726576656E7444656661756C742626612E70726576656E7444656661756C7428292C21746E297B76617220693D652626747970656F6620653D3D226F626A656374223F653A7B7D2C6F3D747970656F6620653D3D22';
wwv_flow_imp.g_varchar2_table(1287) := '66756E6374696F6E223F653A692E696E69742C753D7B7D2C733D742626742E646174617365747C7C7B7D2C6C3D692E7265706F72742C683D692E6F75747075747C7C6E2E61747472696275746530337C7C2266696C65222C673D692E666F726D61747C7C';
wwv_flow_imp.g_varchar2_table(1288) := '6E2E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732873292E666F72456163682866756E6374696F6E2846297B696628463D3D3D226F757470757422297B683D735B465D3B72657475726E7D696628463D3D3D22666F726D61';
wwv_flow_imp.g_varchar2_table(1289) := '7422297B673D735B465D3B72657475726E7D696628463D3D3D227265706F727422297B6C3D735B465D3B72657475726E7D755B462E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D735B465D7D29';
wwv_flow_imp.g_varchar2_table(1290) := '3B766172206D3D7B6C61796F75743A692E6C61796F75747C7C6E2E61747472696275746530312C666F726D61743A672C6F75747075743A682C6974656D733A692E6974656D737C7C6E2E61747472696275746530347C7C22222C706466416374696F6E3A';
wwv_flow_imp.g_varchar2_table(1291) := '692E706466416374696F6E7C7C6E2E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A692E74656D706C61746555726C7C7C6E2E61747472696275746530362C6D6573736167653A692E6D6573736167657C7C6E2E617474';
wwv_flow_imp.g_varchar2_table(1292) := '72696275746530372C706172616D733A752C616A61784964656E7469666965723A692E616A61784964656E7469666965727C7C6E2E616A61784964656E7469666965722C6F726967696E3A692E6F726967696E7C7C2261747472696275746573222C7265';
wwv_flow_imp.g_varchar2_table(1293) := '706F72743A6C2C736176653A692E736176657D3B696628747970656F66206F3D3D2266756E6374696F6E22297B76617220543D6F286D293B696628543D3D3D21312972657475726E3B6D3D547C7C6D7D746E3D21302C2461286D292E7468656E2866756E';
wwv_flow_imp.g_varchar2_table(1294) := '6374696F6E28297B746E3D21317D2C66756E6374696F6E28297B746E3D21317D297D7D72657475726E7B76657273696F6E3A6C692C6C6962733A756E2C72756E3A24612C64613A636C2C6275696C643A56612C656E737572653A4D742C6C61796F75744C';
wwv_flow_imp.g_varchar2_table(1295) := '6962733A50742C5F696E7465726E616C733A7B494D473A4D722C696D6744696D733A556E2C74706C3A562C636F6E643A65722C666D743A4B652C6E6F726D616C697A653A5F612C636F6E74657874733A42612C636F64653132383A4D612C706E67313A7A';
wwv_flow_imp.g_varchar2_table(1296) := '612C6C61796F75744C6962733A50742C7368613531323A466E2C776F72644C65676163794B65793A62612C776F7264486173683A506E2C666F726D4E616D653A67617D7D7D2928293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(32000000000000090)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
