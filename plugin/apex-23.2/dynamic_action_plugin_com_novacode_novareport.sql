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
,p_version_identifier=>'1.21.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>33
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
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E32312E30202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C';
wwv_flow_imp.g_varchar2_table(2) := '72616D6972657A6173796E2F6E6F76617265706F7274202D204C6963656E636961204D49540A202A204E6F7661436F6465202D20706C7567696E2064652041636369C3B36E2044696EC3A16D69636120434F4D2E4E4F5641434F44452E4E4F5641524550';
wwv_flow_imp.g_varchar2_table(3) := '4F52540A202A0A202A204D6F746F72206465206C61796F75743A20756E206D69736D6F2064697365C3B16F20284A534F4E29207920756E6173206D69736D6173206675656E7465732053514C2067656E6572616E0A202A2050444620286A73504446202B';
wwv_flow_imp.g_varchar2_table(4) := '206175746F7461626C65292C20457863656C20636F6E20657374696C6F732028457863656C4A53292C20576F72642028646F637829206F20576F72642064657364650A202A20706C616E74696C6C612028646F637874656D706C61746572292E204D6F64';
wwv_flow_imp.g_varchar2_table(5) := '6F206C6F74653A20756E206172636869766F20706F7220646F63756D656E746F20656E20756E205A495020284A535A6970292E0A202A2F0A77696E646F772E6E6F76615265706F72743D66756E6374696F6E28297B2275736520737472696374223B7661';
wwv_flow_imp.g_varchar2_table(6) := '7220653D7B6A737064663A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737064662F342E322E312F6A737064662E756D642E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B';
wwv_flow_imp.g_varchar2_table(7) := '72657475726E21282177696E646F772E6A737064667C7C2177696E646F772E6A737064662E6A73504446297D7D2C6175746F7461626C653A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C696273';
wwv_flow_imp.g_varchar2_table(8) := '2F6A737064662D6175746F7461626C652F332E382E342F6A737064662E706C7567696E2E6175746F7461626C652E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E6A73706466262677696E646F772E6A73';
wwv_flow_imp.g_varchar2_table(9) := '7064662E6A73504446262677696E646F772E6A737064662E6A735044462E4150492E6175746F5461626C65297D7D2C657863656C6A733A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F';
wwv_flow_imp.g_varchar2_table(10) := '657863656C6A732F342E342E302F657863656C6A732E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E457863656C4A537D7D2C6A737A69703A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564';
wwv_flow_imp.g_varchar2_table(11) := '666C6172652E636F6D2F616A61782F6C6962732F6A737A69702F332E31302E312F6A737A69702E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E4A535A69707D7D2C646F63783A7B75726C3A226874747073';
wwv_flow_imp.g_varchar2_table(12) := '3A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637840392E352E312F646973742F696E6465782E696966652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21282177696E646F772E646F63787C7C2177696E646F772E64';
wwv_flow_imp.g_varchar2_table(13) := '6F63782E446F63756D656E74297D7D2C70697A7A69703A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F70697A7A697040332E312E382F646973742F70697A7A69702E6D696E2E6A73222C6F6B3A66756E637469';
wwv_flow_imp.g_varchar2_table(14) := '6F6E28297B72657475726E212177696E646F772E50697A5A69707D7D2C646F637874656D706C617465723A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637874656D706C6174657240332E36302E302F62';
wwv_flow_imp.g_varchar2_table(15) := '75696C642F646F637874656D706C617465722E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E646F637874656D706C617465727D7D2C7172636F64653A7B75726C3A2268747470733A2F2F63646E2E6A7364';
wwv_flow_imp.g_varchar2_table(16) := '656C6976722E6E65742F6E706D2F7172636F64652D67656E657261746F7240312E342E342F7172636F64652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E2266756E6374696F6E223D3D747970656F662077696E646F772E7172636F6465';
wwv_flow_imp.g_varchar2_table(17) := '7D7D2C63686172746A733A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F63686172742E6A7340342E342E392F646973742F63686172742E756D642E6A73222C6F6B3A66756E6374696F6E28297B72657475726E';
wwv_flow_imp.g_varchar2_table(18) := '21282177696E646F772E43686172747C7C2177696E646F772E43686172742E7265676973746572297D7D7D2C743D7B7064663A5B226A73706466222C226175746F7461626C65225D2C786C73783A5B22657863656C6A73225D2C646F63783A5B22646F63';
wwv_flow_imp.g_varchar2_table(19) := '78225D2C22646F63782D74656D706C617465223A5B2270697A7A6970222C22646F637874656D706C61746572225D2C7A69703A5B226A737A6970225D7D3B66756E6374696F6E20722874297B72657475726E20742E7265647563652866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(20) := '28742C72297B72657475726E20742E7468656E2866756E6374696F6E28297B72657475726E20655B725D2E6F6B28293F6E756C6C3A28743D747428655B725D2E75726C292C6E65772050726F6D6973652866756E6374696F6E28652C72297B766172206E';
wwv_flow_imp.g_varchar2_table(21) := '3D77696E646F772E646566696E653B77696E646F772E646566696E653D766F696420303B766172206F3D646F63756D656E742E637265617465456C656D656E74282273637269707422293B6F2E7372633D742C6F2E6F6E6C6F61643D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(22) := '28297B77696E646F772E646566696E653D6E2C6528297D2C6F2E6F6E6572726F723D66756E6374696F6E28297B77696E646F772E646566696E653D6E2C72286E6577204572726F7228224E6F207365207075646F20636172676172206C61206C69627265';
wwv_flow_imp.g_varchar2_table(23) := '72C3AD613A20222B7429297D2C646F63756D656E742E686561642E617070656E644368696C64286F297D29293B76617220747D297D2C50726F6D6973652E7265736F6C76652829297D766172206E3D7B7072696D6172793A2223314634453739222C6865';
wwv_flow_imp.g_varchar2_table(24) := '6164546578743A2223464646464646222C7A656272613A2223463546374641222C746F74616C733A2223453645434632222C746578743A2223303030303030222C6D757465643A2223373837383738222C666F6E7453697A653A372C67726F75703A2223';
wwv_flow_imp.g_varchar2_table(25) := '444345364630227D3B66756E6374696F6E206F2865297B72657475726E226E756D626572223D3D747970656F66206526262169734E614E2865297D66756E6374696F6E20612865297B72657475726E20333D3D3D28653D537472696E6728657C7C222330';
wwv_flow_imp.g_varchar2_table(26) := '303030303022292E7265706C616365282223222C222229292E6C656E677468262628653D652E7265706C616365282F282E292F672C22243124312229292C5B7061727365496E7428652E73756273747228302C32292C3136292C7061727365496E742865';
wwv_flow_imp.g_varchar2_table(27) := '2E73756273747228322C32292C3136292C7061727365496E7428652E73756273747228342C32292C3136295D7D66756E6374696F6E206C2865297B72657475726E224646222B537472696E6728657C7C222330303030303022292E7265706C6163652822';
wwv_flow_imp.g_varchar2_table(28) := '23222C2222292E746F55707065724361736528297D66756E6374696F6E20692865297B72657475726E20537472696E6728657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E6374696F';
wwv_flow_imp.g_varchar2_table(29) := '6E20732865297B72657475726E28653C31303F2230223A2222292B657D66756E6374696F6E207528297B76617220653D6E657720446174653B72657475726E207328652E676574446174652829292B222F222B7328652E6765744D6F6E746828292B3129';
wwv_flow_imp.g_varchar2_table(30) := '2B222F222B652E67657446756C6C5965617228292B2220222B7328652E676574486F7572732829292B223A222B7328652E6765744D696E757465732829297D66756E6374696F6E206328297B72657475726E207528292E73756273747228302C3130297D';
wwv_flow_imp.g_varchar2_table(31) := '66756E6374696F6E20662865297B76617220743D537472696E672865292E746F4C6F7765724361736528292E7265706C616365282F5F2F672C222022293B72657475726E20742E6368617241742830292E746F55707065724361736528292B742E736C69';
wwv_flow_imp.g_varchar2_table(32) := '63652831297D66756E6374696F6E20642865297B76617220743D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D29242F2E6578656328537472696E6728657C7C222229293B72657475726E20743F6E6577204461746528446174652E55';
wwv_flow_imp.g_varchar2_table(33) := '5443282B745B335D2C2B745B325D2D312C2B745B315D29293A6E756C6C7D66756E6374696F6E20682865297B72657475726E20537472696E6728657C7C226172636869766F22292E7265706C616365282F5B5C5C5C2F3A2A3F223C3E7C5D2B2F672C225F';
wwv_flow_imp.g_varchar2_table(34) := '22292E7472696D28297D66756E6374696F6E207028652C74297B6966286E756C6C3D3D657C7C22223D3D3D652972657475726E22223B69662821742972657475726E20537472696E672865293B696628532874292972657475726E2066756E6374696F6E';
wwv_flow_imp.g_varchar2_table(35) := '28652C74297B76617220723D4E756D6265722865293B6966286E756C6C3D3D657C7C22223D3D3D657C7C69734E614E2872292972657475726E206E756C6C3D3D653F22223A537472696E672865293B766172206E3D772874292C6F3D6E5B305D2C613D21';
wwv_flow_imp.g_varchar2_table(36) := '313B723C3026266E2E6C656E6774683E3126266E5B315D2E746F6B732E6C656E6774683F286F3D6E5B315D2C723D2D72293A723C30262628613D21302C723D2D72293B303D3D3D7226266E2E6C656E6774683E322626286F3D6E5B325D2C613D2131293B';
wwv_flow_imp.g_varchar2_table(37) := '6F2E706374262628722A3D313030293B722F3D6F2E7363616C653B766172206C3D4E756D62657228722E746F4669786564286F2E6D617844656329293B303D3D3D6C262628613D2131293B76617220693D6C2E746F4C6F63616C65537472696E67282265';
wwv_flow_imp.g_varchar2_table(38) := '6E2D5553222C7B75736547726F7570696E673A6F2E67726F75702C6D696E696D756D496E74656765724469676974733A4D6174682E6D617828312C4D6174682E6D696E2832312C6F2E6D696E496E7429292C6D696E696D756D4672616374696F6E446967';
wwv_flow_imp.g_varchar2_table(39) := '6974733A6F2E6D696E4465632C6D6178696D756D4672616374696F6E4469676974733A6F2E6D61784465637D293B216F2E6D696E496E7426262F5E30285C2E7C24292F2E74657374286929262628693D692E736C696365283129293B222E223D3D3D6F2E';
wwv_flow_imp.g_varchar2_table(40) := '6465632626222C223D3D3D6F2E6772707C7C28693D692E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E2865297B72657475726E222E223D3D3D653F6F2E6465633A6F2E6772707D29293B76617220733D6F2E746F6B732E6D61702866756E';
wwv_flow_imp.g_varchar2_table(41) := '6374696F6E2865297B72657475726E226E223D3D3D652E743F693A2278223D3D3D652E743F22223A652E767D292E6A6F696E282222293B72657475726E20613F222D222B733A737D28652C74293B76617220723D742E73706C697428223A22292C6E3D72';
wwv_flow_imp.g_varchar2_table(42) := '5B305D3B696628226D6F6E6579223D3D3D6E7C7C226E756D223D3D3D6E297B766172206F3D766F69642030213D3D725B315D3F2B725B315D3A322C613D4E756D6265722865293B72657475726E2069734E614E2861293F537472696E672865293A612E74';
wwv_flow_imp.g_varchar2_table(43) := '6F4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A6F2C6D6178696D756D4672616374696F6E4469676974733A6F7D297D72657475726E22696E74223D3D3D6E3F69734E614E284E756D6265';
wwv_flow_imp.g_varchar2_table(44) := '72286529293F537472696E672865293A4D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D555322293A22706374223D3D3D6E3F7028652C226E756D3A222B28725B315D7C7C3229292B2225223A2275';
wwv_flow_imp.g_varchar2_table(45) := '70706572223D3D3D6E3F537472696E672865292E746F55707065724361736528293A226C6F776572223D3D3D6E3F537472696E672865292E746F4C6F7765724361736528293A22796E223D3D3D6E3F2259223D3D3D657C7C2253223D3D3D653F2253C3AD';
wwv_flow_imp.g_varchar2_table(46) := '223A224E223D3D3D653F224E6F223A537472696E672865293A226C6574726173223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A66756E6374696F6E28652C74297B76617220723D653C302C6E3D4D6174682E726F756E';
wwv_flow_imp.g_varchar2_table(47) := '64283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C613D6E253130302C6C3D7A286F293B69662874297B2F284D494C4CC3934E7C4D494C4C4F4E45537C42494C4CC3934E7C42494C4C4F4E455329242F2E74';
wwv_flow_imp.g_varchar2_table(48) := '657374286C292626286C2B3D2220444522293B76617220693D537472696E672874292E746F55707065724361736528292E73706C697428222F22293B6C2B3D2220222B28313D3D3D6F2626692E6C656E6774683E313F695B305D3A695B692E6C656E6774';
wwv_flow_imp.g_varchar2_table(49) := '682D315D297D656C7365206C3D6C2E7265706C616365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E2865297B72657475726E20652B224F227D293B72657475726E28723F224D454E4F5320';
wwv_flow_imp.g_varchar2_table(50) := '223A2222292B6C2B2220434F4E20222B28613C31303F2230223A2222292B612B222F313030227D284E756D6265722865292C722E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E6374696F6E20672865297B72657475';
wwv_flow_imp.g_varchar2_table(51) := '726E2F5E2875707065727C6C6F7765727C796E7C6C657472617329283A7C24292F2E7465737428657C7C2222297D766172206D3D7B7D3B66756E6374696F6E20762865297B666F722876617220743D5B5D2C723D22222C6E3D21312C6F3D303B6F3C652E';
wwv_flow_imp.g_varchar2_table(52) := '6C656E6774683B6F2B2B297B76617220613D652E636861724174286F293B225C5C22213D3D617C7C6E3F282722273D3D3D612626286E3D216E292C223B22213D3D617C7C6E3F722B3D613A28742E707573682872292C723D222229293A28722B3D612B28';
wwv_flow_imp.g_varchar2_table(53) := '652E636861724174286F2B31297C7C2222292C6F2B2B297D72657475726E20742E707573682872292C747D66756E6374696F6E20622865297B76617220742C722C6E3D5B5D2C6F3D6E756C6C2C613D21312C6C3D22222C693D21312C733D66756E637469';
wwv_flow_imp.g_varchar2_table(54) := '6F6E28297B6C2626286E2E70757368287B743A226C222C763A6C7D292C6C3D2222297D3B666F7228743D303B743C652E6C656E6774683B742B2B29696628272227213D3D28723D652E6368617241742874292929696628225C5C22213D3D72297B696628';
wwv_flow_imp.g_varchar2_table(55) := '225B223D3D3D72297B76617220753D652E696E6465784F6628225D222C74293B696628753E30297B7328292C6E2E70757368287B743A2278222C763A652E736C69636528742C752B31297D292C743D753B636F6E74696E75657D7D225F22213D3D723F22';
wwv_flow_imp.g_varchar2_table(56) := '2A22213D3D723F216126262F5B23303F2C2E5D2F2E746573742872292626286E756C6C213D3D6F7C7C2F5B23303F5D2F2E746573742872297C7C222E223D3D3D7226262F5B23303F5D2F2E7465737428652E63686172417428742B312929293F286E756C';
wwv_flow_imp.g_varchar2_table(57) := '6C3D3D3D6F2626287328292C6F3D22222C6E2E70757368287B743A226E227D29292C6F2B3D72293A286E756C6C213D3D6F262628613D2130292C2225223D3D3D72262628693D2130292C6C2B3D72293A742B2B3A286C2B3D2220222C742B2B297D656C73';
wwv_flow_imp.g_varchar2_table(58) := '65206C2B3D652E63686172417428742B31292C742B2B3B656C73657B76617220633D652E696E6465784F66282722272C742B31293B633C30262628633D652E6C656E677468292C6C2B3D652E736C69636528742B312C63292C743D637D7328293B766172';
wwv_flow_imp.g_varchar2_table(59) := '20663D286F3D6F7C7C2222292E6C617374496E6465784F6628222C22292C643D21313B663E3D3026262F5E5B23303F5D2B242F2E74657374286F2E736C69636528662B312929262628643D6F2E696E6465784F6628222E22293E3D303F6F2E6C61737449';
wwv_flow_imp.g_varchar2_table(60) := '6E6465784F6628222E22293C663A6F2E6C656E6774682D662D31213D33292C642626286F3D6F2E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E2865297B72657475726E222E223D3D3D653F222C223A222E227D29293B76617220683D282F';
wwv_flow_imp.g_varchar2_table(61) := '2C2B242F2E65786563286F297C7C5B22225D295B305D2E6C656E6774682C703D6F2E736C69636528302C6F2E6C656E6774682D68292C673D702E696E6465784F6628222E22292C6D3D673C303F703A702E736C69636528302C67292C763D673C303F2222';
wwv_flow_imp.g_varchar2_table(62) := '3A702E736C69636528672B31292C623D282F2C2B242F2E65786563286D297C7C5B22225D295B305D2E6C656E6774682B683B72657475726E206D3D6D2E736C69636528302C6D2E6C656E6774682D62292C7B746F6B733A6E2C7261773A6F2C6861734E75';
wwv_flow_imp.g_varchar2_table(63) := '6D3A21216F2C7063743A692C7363616C653A4D6174682E706F77283165332C62292C67726F75703A6D2E696E6465784F6628222C22293E3D302C6D696E496E743A286D2E6D61746368282F302F67297C7C5B5D292E6C656E6774682C6D61784465633A28';
wwv_flow_imp.g_varchar2_table(64) := '762E6D61746368282F5B23303F5D2F67297C7C5B5D292E6C656E6774682C6D696E4465633A28762E6D61746368282F302F67297C7C5B5D292E6C656E6774682C6465633A643F222C223A222E222C6772703A643F222E223A222C227D7D66756E6374696F';
wwv_flow_imp.g_varchar2_table(65) := '6E20772865297B696628653D537472696E672865292C216D5B655D296966282F5E6F72613A2F2E74657374286529297B76617220743D66756E6374696F6E2865297B76617220742C722C6E3D5B5D2C6F3D22222C613D22223B666F7228743D303B743C65';
wwv_flow_imp.g_varchar2_table(66) := '2E6C656E6774683B742B2B29723D652E6368617241742874292C613F723D3D3D613F613D22223A6F2B3D723A222722213D3D722626272227213D3D723F223B22213D3D723F6F2B3D723A286E2E70757368286F292C6F3D2222293A613D723B6E2E707573';
wwv_flow_imp.g_varchar2_table(67) := '68286F293B766172206C3D6E2E736869667428292E7472696D28292E746F55707065724361736528292C693D2F5E464D2F2E74657374286C292C733D7B6E6C733A222E2C222C6375723A2224222C69736F3A22555344227D3B6E2E666F72456163682866';
wwv_flow_imp.g_varchar2_table(68) := '756E6374696F6E2865297B76617220743D652E696E6465784F6628223D22293B743E30262628735B652E736C69636528302C74292E7472696D28292E746F4C6F7765724361736528295D3D652E736C69636528742B3129297D292C6C3D6C2E7265706C61';
wwv_flow_imp.g_varchar2_table(69) := '6365282F5E464D2F2C2222293B76617220753D2F5052242F2E74657374286C292C633D217526262F4D49242F2E74657374286C293B28757C7C63292626286C3D6C2E736C69636528302C2D3229293B76617220663D2F5E532F2E74657374286C292C643D';
wwv_flow_imp.g_varchar2_table(70) := '2166262621752626216326262F53242F2E74657374286C293B663F6C3D6C2E736C6963652831293A642626286C3D6C2E736C69636528302C2D3129293B76617220683D6C2E696E6465784F6628224222293E3D302C703D22222C673D22222C6D3D22222C';
wwv_flow_imp.g_varchar2_table(71) := '763D22222C623D21312C773D21313B666F72286C3D6C2E7265706C616365282F422F672C2222292C743D303B743C6C2E6C656E6774683B742B2B296966282239223D3D3D28723D6C2E636861724174287429297C7C2230223D3D3D7229773D21302C623F';
wwv_flow_imp.g_varchar2_table(72) := '762B3D2239223D3D3D722626693F2223223A2230223A6D2B3D723B656C7365206966282247223D3D3D727C7C222C223D3D3D7229627C7C286D2B3D222C22293B656C7365206966282244223D3D3D727C7C222E223D3D3D7229623D21303B656C73652069';
wwv_flow_imp.g_varchar2_table(73) := '6628224C223D3D3D727C7C2255223D3D3D727C7C2243223D3D3D727C7C2224223D3D3D72297B76617220793D2243223D3D3D723F732E69736F3A2224223D3D3D723F2224223A732E6375723B773F672B3D793A702B3D797D76617220783D6D2E696E6465';
wwv_flow_imp.g_varchar2_table(74) := '784F6628223022292C533D286D3D6D2E7265706C616365282F5B39305D2F672C66756E6374696F6E28652C74297B72657475726E20783E3D302626743E3D783F2230223A2223227D292E7265706C616365282F5E2C2B2F2C222229292B28763F222E222B';
wwv_flow_imp.g_varchar2_table(75) := '763A2222297C7C2223222C453D66756E6374696F6E2865297B72657475726E20653F2722272B537472696E672865292E7265706C616365282F222F672C2222292B2722273A22227D2C543D452870292B532B452867292C433D543B753F433D542B223B22';
wwv_flow_imp.g_varchar2_table(76) := '2B4528223C222B70292B532B4528672B223E22293A633F433D542B223B222B452870292B532B4528672B222D22293A663F433D4528222B222B70292B532B452867292B223B222B4528222D222B70292B532B452867293A64262628433D452870292B532B';
wwv_flow_imp.g_varchar2_table(77) := '4528672B222B22292B223B222B452870292B532B4528672B222D2229292C68262628433D3D3D54262628432B3D223B222B4528222D222B70292B532B45286729292C432B3D273B222227293B76617220413D537472696E6728732E6E6C737C7C222E2C22';
wwv_flow_imp.g_varchar2_table(78) := '293B72657475726E7B7372633A432C6465633A412E6368617241742830297C7C222E222C6772703A412E6368617241742831297C7C222C227D7D28652E736C696365283429293B6D5B655D3D7628742E737263292E6D61702866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(79) := '7B76617220723D622865293B72657475726E20722E6465633D742E6465632C722E6772703D742E6772702C727D297D656C7365206D5B655D3D762866756E6374696F6E2865297B72657475726E20653D537472696E672865292C2F5E6D61736B3A2F2E74';
wwv_flow_imp.g_varchar2_table(80) := '6573742865293F652E736C6963652835293A657D286529292E6D61702862293B72657475726E206D5B655D7D66756E6374696F6E20792865297B72657475726E20772865292E6D61702866756E6374696F6E2865297B72657475726E20652E746F6B732E';
wwv_flow_imp.g_varchar2_table(81) := '6D61702866756E6374696F6E2874297B72657475726E226E223D3D3D742E743F652E7261773A2278223D3D3D742E743F742E763A742E762E73706C697428222522292E6D61702866756E6374696F6E2865297B72657475726E20653F2722272B652E7265';
wwv_flow_imp.g_varchar2_table(82) := '706C616365282F222F672C2222292B2722273A22227D292E6A6F696E28222522297D292E6A6F696E282222297C7C272222277D292E6A6F696E28223B22297D76617220783D2F5E286D6F6E65797C6E756D7C696E747C7063747C646174657C7570706572';
wwv_flow_imp.g_varchar2_table(83) := '7C6C6F7765727C796E7C6C657472617329283A7C24292F3B66756E6374696F6E20532865297B72657475726E2F5E286D61736B7C6F7261293A2F2E7465737428653D657C7C2222297C7C21782E7465737428652926262F5B23305D2F2E74657374286529';
wwv_flow_imp.g_varchar2_table(84) := '7D76617220453D5B22222C22554E222C22444F53222C2254524553222C2243554154524F222C2243494E434F222C2253454953222C225349455445222C224F43484F222C224E55455645222C224449455A222C224F4E4345222C22444F4345222C225452';
wwv_flow_imp.g_varchar2_table(85) := '454345222C224341544F524345222C225155494E4345222C22444945434953C3894953222C2244494543495349455445222C2244494543494F43484F222C2244494543494E55455645222C225645494E5445222C225645494E5449C39A4E222C22564549';
wwv_flow_imp.g_varchar2_table(86) := '4E544944C39353222C225645494E54495452C38953222C225645494E544943554154524F222C225645494E544943494E434F222C225645494E544953C3894953222C225645494E54495349455445222C225645494E54494F43484F222C225645494E5449';
wwv_flow_imp.g_varchar2_table(87) := '4E55455645225D2C543D5B22222C22222C22222C22545245494E5441222C2243554152454E5441222C2243494E4355454E5441222C22534553454E5441222C22534554454E5441222C224F4348454E5441222C224E4F56454E5441225D2C433D5B22222C';
wwv_flow_imp.g_varchar2_table(88) := '224349454E544F222C22444F534349454E544F53222C22545245534349454E544F53222C2243554154524F4349454E544F53222C225155494E49454E544F53222C22534549534349454E544F53222C22534554454349454E544F53222C224F43484F4349';
wwv_flow_imp.g_varchar2_table(89) := '454E544F53222C224E4F56454349454E544F53225D3B66756E6374696F6E20412865297B6966283130303D3D3D652972657475726E224349454E223B76617220743D4D6174682E666C6F6F7228652F313030292C723D65253130302C6E3D5B5D3B726574';
wwv_flow_imp.g_varchar2_table(90) := '75726E207426266E2E7075736828435B745D292C7226266E2E7075736828723C33303F455B725D3A545B4D6174682E666C6F6F7228722F3130295D2B28722531303F22205920222B455B722531305D3A222229292C6E2E6A6F696E28222022297D66756E';
wwv_flow_imp.g_varchar2_table(91) := '6374696F6E207A2865297B696628303D3D3D652972657475726E224345524F223B76617220743D5B5D3B5B5B316531322C2242494C4CC3934E222C2242494C4C4F4E4553225D2C5B3165362C224D494C4CC3934E222C224D494C4C4F4E4553225D5D2E66';
wwv_flow_imp.g_varchar2_table(92) := '6F72456163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E7075736828313D3D3D6E3F22554E20222B725B315D3A7A286E292B2220222B725B325D292C652D3D6E2A725B305D297D293B';
wwv_flow_imp.g_varchar2_table(93) := '76617220723D4D6174682E666C6F6F7228652F316533292C6E3D65253165333B72657475726E20722626742E7075736828313D3D3D723F224D494C223A412872292B22204D494C22292C6E2626742E707573682841286E29292C742E6A6F696E28222022';
wwv_flow_imp.g_varchar2_table(94) := '297D66756E6374696F6E204D28652C742C72297B766172206E3D537472696E672874292E746F55707065724361736528292C6F3D6E2E696E6465784F6628222E22293B6966286F3E30297B76617220613D6E2E73756273747228302C6F292C6C3D6E2E73';
wwv_flow_imp.g_varchar2_table(95) := '7562737472286F2B31293B69662822444F43223D3D3D612972657475726E20652E646F633F652E646F635B6C5D3A766F696420303B69662822504152414D223D3D3D612972657475726E20652E706172616D733F652E706172616D735B6C5D3A766F6964';
wwv_flow_imp.g_varchar2_table(96) := '20303B696628224954454D223D3D3D612972657475726E2066756E6374696F6E2865297B7472797B72657475726E2077696E646F772E617065782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D636174';
wwv_flow_imp.g_varchar2_table(97) := '63682865297B72657475726E22227D7D286C293B76617220693D28652E535B615D7C7C5B5D295B305D3B72657475726E20693F695B6C5D3A766F696420307D72657475726E224E4F57223D3D3D6E3F7528293A22544F444159223D3D3D6E3F6328293A22';
wwv_flow_imp.g_varchar2_table(98) := '50414745223D3D3D6E7C7C225041474553223D3D3D6E3F227B222B6E2B227D223A7226264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28722C6E293F725B6E5D3A652E646F6326264F626A6563742E70726F';
wwv_flow_imp.g_varchar2_table(99) := '746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F652E646F635B6E5D3A652E706172616D733F652E706172616D735B6E5D3A766F696420307D66756E6374696F6E204E28652C742C72297B72657475726E206E75';
wwv_flow_imp.g_varchar2_table(100) := '6C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C28283F3A6D61736B7C6F7261293A5B5E7D5D2B7C5B412D5A612D7A302D393A2FC381C389C38DC393C39AC391C39CC3';
wwv_flow_imp.g_varchar2_table(101) := 'A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B7C5B5E7D5D2A5B23305D5B5E7D5D2A29293F5C7D2F672C66756E6374696F6E28652C6E2C6F297B76617220613D4D28742C6E2C72293B72657475726E206E756C6C3D3D613F22223A7028612C6F297D297D66756E63';
wwv_flow_imp.g_varchar2_table(102) := '74696F6E204628652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E657865632865293B696628216E297265747572';
wwv_flow_imp.g_varchar2_table(103) := '6E21313B766172206F3D4D28742C6E5B325D2C72293B696628216E5B335D297B76617220613D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E223D3D3D6F293B72657475726E206E5B315D3F21613A617D766172206C2C693D286C';
wwv_flow_imp.g_varchar2_table(104) := '3D286C3D6E5B345D292E7472696D28292C2F5E272E2A27242F2E74657374286C297C7C2F5E222E2A22242F2E74657374286C293F6C2E736C69636528312C2D31293A226E756C6C223D3D3D6C3F6E756C6C3A22223D3D3D6C7C7C69734E614E284E756D62';
wwv_flow_imp.g_varchar2_table(105) := '6572286C29293F766F696420303A4E756D626572286C29293B766F696420303D3D3D69262628693D4D28742C6E5B345D2E7472696D28292C7229293B76617220733D6E756C6C3D3D6F7C7C22223D3D3D6F3F6E756C6C3D3D3D697C7C22223D3D3D693A53';
wwv_flow_imp.g_varchar2_table(106) := '7472696E67286F293D3D3D537472696E672869293B737769746368286E5B335D297B63617365223D3D223A72657475726E20733B6361736522213D223A72657475726E21733B63617365223E223A72657475726E204E756D626572286F293E4E756D6265';
wwv_flow_imp.g_varchar2_table(107) := '722869293B63617365223C223A72657475726E204E756D626572286F293C4E756D6265722869293B63617365223E3D223A72657475726E204E756D626572286F293E3D4E756D6265722869293B63617365223C3D223A72657475726E204E756D62657228';
wwv_flow_imp.g_varchar2_table(108) := '6F293C3D4E756D6265722869297D72657475726E21317D66756E6374696F6E205028652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C282266756E6374696F6E223D3D747970656F6620653F21216528722C74293A53747269';
wwv_flow_imp.g_varchar2_table(109) := '6E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E65766572792866756E6374696F6E2865297B72657475726E204628652C742C72297D297D29297D66756E6374';
wwv_flow_imp.g_varchar2_table(110) := '696F6E206B28652C74297B76617220723D742E535B537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C7465722866756E6374696F6E2872297B7265';
wwv_flow_imp.g_varchar2_table(111) := '7475726E205028652E66696C7465722C742C72297D293A727D66756E6374696F6E204F28652C742C72297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F6620652972657475726E20653B766172206E3D4D28';
wwv_flow_imp.g_varchar2_table(112) := '742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E206A28652C742C72297B766172206E3D6E756C6C3B72657475726E28657C7C5B5D292E73';
wwv_flow_imp.g_varchar2_table(113) := '6F6D652866756E6374696F6E2865297B72657475726E21215028652E7768656E2C742C72292626286E3D652C2130297D292C6E7D76617220493D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D2C617269616C3A5B2268';
wwv_flow_imp.g_varchar2_table(114) := '656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75726965723A5B22636F75';
wwv_flow_imp.g_varchar2_table(115) := '72696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E204C2865297B72657475726E20653D537472696E6728657C7C2268656C76657469636122292E74';
wwv_flow_imp.g_varchar2_table(116) := '6F4C6F7765724361736528292C495B655D3F653A2268656C766574696361227D66756E6374696F6E205228652C74297B76617220722C6E3D5B5D2C6F3D7B623A21312C693A21312C753A21312C733A21317D2C613D5B28743D747C7C7B7D292E666F6E74';
wwv_flow_imp.g_varchar2_table(117) := '7C7C2268656C766574696361225D2C6C3D5B742E636F6C6F727C7C6E756C6C5D2C693D22222C733D303B66756E6374696F6E207528297B692626286E2E70757368287B743A692C623A6F2E622C693A6F2E692C753A6F2E752C733A6F2E732C663A4C2861';
wwv_flow_imp.g_varchar2_table(118) := '5B612E6C656E6774682D315D292C633A6C5B6C2E6C656E6774682D315D7D292C693D2222297D666F7228653D537472696E67286E756C6C3D3D653F22223A65293B733C652E6C656E6774683B297B76617220633D652E7375627374722873293B225C5C22';
wwv_flow_imp.g_varchar2_table(119) := '3D3D3D632E6368617241742830292626632E6C656E6774683E313F28692B3D632E6368617241742831292C732B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286329293F287528292C612E7075736828725B315D292C';
wwv_flow_imp.g_varchar2_table(120) := '732B3D725B305D2E6C656E677468293A225B2F665D22213D3D632E73756273747228302C34293F28723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286329293F287528292C6C2E7075736828725B315D292C732B';
wwv_flow_imp.g_varchar2_table(121) := '3D725B305D2E6C656E677468293A225B2F635D22213D3D632E73756273747228302C34293F222A2A2A22213D3D632E73756273747228302C33293F222A2A22213D3D632E73756273747228302C32293F227E7E22213D3D632E73756273747228302C3229';
wwv_flow_imp.g_varchar2_table(122) := '3F222B2B22213D3D632E73756273747228302C32293F222A22213D3D632E6368617241742830293F28692B3D632E6368617241742830292C732B2B293A287528292C6F2E693D216F2E692C732B3D31293A287528292C6F2E753D216F2E752C732B3D3229';
wwv_flow_imp.g_varchar2_table(123) := '3A287528292C6F2E733D216F2E732C732B3D32293A287528292C6F2E623D216F2E622C732B3D32293A287528292C6F2E623D216F2E622C6F2E693D216F2E692C732B3D33293A287528292C6C2E6C656E6774683E3126266C2E706F7028292C732B3D3429';
wwv_flow_imp.g_varchar2_table(124) := '3A287528292C612E6C656E6774683E312626612E706F7028292C732B3D34297D72657475726E207528292C6E7D66756E6374696F6E204428652C74297B76617220723D652E736F757263653F6B28652C74295B305D3A6E756C6C3B72657475726E284172';
wwv_flow_imp.g_varchar2_table(125) := '7261792E6973417272617928652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C697428225C6E2229292E6D61702866756E6374696F6E2865297B72657475726E204E2865';
wwv_flow_imp.g_varchar2_table(126) := '2C742C72297D297D66756E6374696F6E205528652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D742E545B6E5D7C7C7B7D2C6C3D652E636F6C756D6E733B72657475726E206C';
wwv_flow_imp.g_varchar2_table(127) := '26266C2E6C656E6774687C7C286C3D4F626A6563742E6B6579732861292E66696C7465722866756E6374696F6E2865297B72657475726E22444F435F4B455922213D3D657D292E6D61702866756E6374696F6E2865297B72657475726E7B636F6C3A657D';
wwv_flow_imp.g_varchar2_table(128) := '7D29292C286C3D6C2E66696C7465722866756E6374696F6E2865297B72657475726E22737472696E67223D3D747970656F6620657C7C21652E7768656E7C7C5028652E7768656E2C742C6E756C6C297D29292E6D61702866756E6374696F6E2865297B76';
wwv_flow_imp.g_varchar2_table(129) := '617220743D28653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C292E746F55707065724361736528293A6E756C6C2C6E3D743F615B745D3A6E756C6C2C6C3D652E666D743B6C7C7C';
wwv_flow_imp.g_varchar2_table(130) := '224E554D42455222213D3D6E7C7C652E76616C75657C7C286C3D722E736F6D652866756E6374696F6E2865297B72657475726E206F28655B745D2926264D6174682E726F756E6428655B745D29213D3D655B745D7D293F226D6F6E6579223A6E756C6C29';
wwv_flow_imp.g_varchar2_table(131) := '3B76617220693D652E63656C6C2626575B652E63656C6C2E747970655D3F652E63656C6C3A6E756C6C3B72657475726E7B636F6C3A742C76616C75653A766F69642030213D3D652E76616C75653F652E76616C75653A652E63656C6C262622746578746F';
wwv_flow_imp.g_varchar2_table(132) := '223D3D3D652E63656C6C2E747970653F652E63656C6C2E746578743A766F696420302C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628747C7C2222292C63656C6C3A692C76616C69676E3A2F5E28746F707C6D696464';
wwv_flow_imp.g_varchar2_table(133) := '6C657C626F74746F6D29242F2E7465737428537472696E6728652E76616C69676E7C7C2222292E746F4C6F776572436173652829293F537472696E6728652E76616C69676E292E746F4C6F7765724361736528293A6E756C6C2C666D743A6C2C6D61703A';
wwv_flow_imp.g_varchar2_table(134) := '652E6D61702C626F6C643A2121652E626F6C642C77696474683A652E77696474682C616C69676E3A652E616C69676E7C7C28693F2263656E746572223A6E756C6C297C7C2867286C293F226C656674223A224E554D424552223D3D3D6E7C7C226D6F6E65';
wwv_flow_imp.g_varchar2_table(135) := '79223D3D3D6C7C7C22696E74223D3D3D6C7C7C226E756D223D3D3D6C7C7C53286C293F227269676874223A2244415445223D3D3D6E7C7C2264617465223D3D3D6C3F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63656C6C53';
wwv_flow_imp.g_varchar2_table(136) := '74796C652C636F6C6F723A652E636F6C6F722C68656164416C69676E3A652E68656164416C69676E2C69734E756D3A216926262167286C29262628224E554D424552223D3D3D6E262621652E6D6170262621652E76616C75657C7C226D6F6E6579223D3D';
wwv_flow_imp.g_varchar2_table(137) := '3D6C7C7C22696E74223D3D3D6C7C7C2F5E6E756D2F2E74657374286C7C7C2222297C7C53286C29297D7D297D66756E6374696F6E204228652C74297B76617220723D5B5D2C6E3D303B72657475726E28652E67726F7570737C7C5B5D292E666F72456163';
wwv_flow_imp.g_varchar2_table(138) := '682866756E6374696F6E2865297B766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E677468262628722E70757368287B6C6162656C3A652E6C6162656C7C7C22';
wwv_flow_imp.g_varchar2_table(139) := '222C636F6C733A6F2C66726F6D3A6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C733A742E6C656E6774682D6E2C66726F6D3A6E2C6761703A21307D292C';
wwv_flow_imp.g_varchar2_table(140) := '727D66756E6374696F6E204728652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E204E28652E76616C75652C722C74293B766172206E3D745B652E636F6C5D3B72657475726E20652E6D617026266E756C6C213D6E2626';
wwv_flow_imp.g_varchar2_table(141) := '766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E205F28652C742C72297B766172206E3D4728652C742C72293B72657475726E20652E6D61702626766F69642030213D3D652E6D61705B745B652E636F6C5D5D';
wwv_flow_imp.g_varchar2_table(142) := '3F537472696E67286E293A70286E2C652E666D74297D76617220573D7B636F6469676F3A312C696D6167656E3A312C6772616669636F3A317D3B66756E6374696F6E20242865297B76617220742C723D7B7D3B666F72287420696E2065294F626A656374';
wwv_flow_imp.g_varchar2_table(143) := '2E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C7429262628725B745D3D655B745D293B72657475726E20727D66756E6374696F6E204828652C74297B76617220723D537472696E6728652E76616C69676E7C7C222229';
wwv_flow_imp.g_varchar2_table(144) := '2E746F4C6F7765724361736528293B72657475726E22746F70223D3D3D727C7C226D6964646C65223D3D3D727C7C22626F74746F6D223D3D3D723F723A742E736F6D652866756E6374696F6E2865297B72657475726E20652E63656C6C7D293F226D6964';
wwv_flow_imp.g_varchar2_table(145) := '646C65223A6E756C6C7D66756E6374696F6E205628652C742C722C6E297B766172206F3D652E63656C6C3B696628216F2972657475726E206E756C6C3B69662822636F6469676F223D3D3D6F2E74797065297B76617220613D24286F293B612E73697A65';
wwv_flow_imp.g_varchar2_table(146) := '7C7C28612E73697A653D3134292C612E77696474687C7C28612E77696474683D3330292C612E6865696768747C7C28612E6865696768743D38293B766172206C3D767428612C722C74293B696628216C2972657475726E206E756C6C3B76617220693D62';
wwv_flow_imp.g_varchar2_table(147) := '74286C293B72657475726E7B696D3A692C773A692E776D6D2C683A692E686D6D7D7D69662822696D6167656E223D3D3D6F2E74797065297B76617220733D6F2E6669656C643F745B537472696E67286F2E6669656C64292E746F55707065724361736528';
wwv_flow_imp.g_varchar2_table(148) := '295D3A6E756C6C2C753D6E756C6C3B7472797B753D733F61742873293A6F2E75726C2626216F2E6669656C643F51655B7474284E286F2E75726C2C722C7429295D3A6E756C6C7D63617463682865297B77696E646F772E636F6E736F6C652626636F6E73';
wwv_flow_imp.g_varchar2_table(149) := '6F6C652E7761726E28226E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B6F2E6669656C642C65297D69662821752972657475726E206E756C6C3B76617220633D6974287B77696474683A6F2E77696474687C7C286F';
wwv_flow_imp.g_varchar2_table(150) := '2E6865696768743F766F696420303A3135292C6865696768743A6F2E6865696768747D2C75293B72657475726E7B696D3A752C773A632E772C683A632E687D7D76617220663D24286F293B64656C65746520662E66696C7465722C64656C65746520662E';
wwv_flow_imp.g_varchar2_table(151) := '6C696E6B2C662E77696474687C7C28662E77696474683D3430292C662E6865696768747C7C28662E6865696768743D3135293B76617220643D797428662C66756E6374696F6E28652C742C72297B766172206E3D537472696E6728652E736F757263657C';
wwv_flow_imp.g_varchar2_table(152) := '7C2222292E746F55707065724361736528292C6F3D652E6C696E6B7C7C7B7D2C613D652E66696C7465723F4E28652E66696C7465722C742C72293A6E756C6C2C6C3D28742E535B6E5D7C7C5B5D292E66696C7465722866756E6374696F6E2865297B666F';
wwv_flow_imp.g_varchar2_table(153) := '7228766172206E20696E206F296966284F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C286F2C6E292626537472696E6728655B6E2E746F55707065724361736528295D29213D3D537472696E6728725B537472';
wwv_flow_imp.g_varchar2_table(154) := '696E67286F5B6E5D292E746F55707065724361736528295D292972657475726E21313B72657475726E21617C7C5028612C742C65297D292C693D242874293B72657475726E20692E533D2428742E53292C692E535B6E5D3D6C2C697D286F2C722C74292C';
wwv_flow_imp.g_varchar2_table(155) := '6E293B72657475726E20643F7B696D3A642C773A642E776D6D2C683A642E686D6D7D3A6E756C6C7D76617220593D7B666F726D756C6172696F3A312C66696368613A312C7461726A657461733A317D3B66756E6374696F6E20712865297B76617220743D';
wwv_flow_imp.g_varchar2_table(156) := '5B5D3B72657475726E28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B696628652626595B652E747970655D262628652E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E20652626652E626C';
wwv_flow_imp.g_varchar2_table(157) := '6F636B7D29297B76617220723D6E756C6C2C6E3D302C6F3D66756E6374696F6E28297B722626722E6669656C64732E6C656E6774682626742E707573682872292C723D6E756C6C7D3B652E6669656C64732E666F72456163682866756E6374696F6E2861';
wwv_flow_imp.g_varchar2_table(158) := '297B696628612626612E626C6F636B297B766172206C3D612E626C6F636B3B696628216C7C7C2156655B6C2E747970655D7C7C22666F726D756C6172696F223D3D3D6C2E747970652972657475726E3B72657475726E206F28292C21286C3D24286C2929';
wwv_flow_imp.g_varchar2_table(159) := '2E736F757263652626652E736F757263652626226C696E656122213D3D6C2E747970652626226573706163696F22213D3D6C2E747970652626286C2E736F757263653D652E736F75726365292C612E7768656E2626216C2E7768656E2626286C2E776865';
wwv_flow_imp.g_varchar2_table(160) := '6E3D612E7768656E292C6E7C7C21652E7469746C657C7C227461626C6122213D3D6C2E747970657C7C6C2E7469746C657C7C286C2E7469746C653D652E7469746C65292C742E70757368286C292C766F6964206E2B2B7D727C7C2828723D24286529292E';
wwv_flow_imp.g_varchar2_table(161) := '6669656C64733D5B5D2C6E262664656C65746520722E7469746C652C6E2B2B292C722E6669656C64732E707573682861297D292C6F28297D656C736520742E707573682865297D292C747D76617220583D7B73756D3A392C6176673A312C6D696E3A352C';
wwv_flow_imp.g_varchar2_table(162) := '6D61783A342C636F756E743A337D2C5A3D7B73756D3A2253554D222C6176673A2241564552414745222C6D696E3A224D494E222C6D61783A224D4158222C636F756E743A22434F554E5441227D2C4A3D7B6176673A2250726F6D2E222C6D696E3A224DC3';
wwv_flow_imp.g_varchar2_table(163) := 'AD6E2E222C6D61783A224DC3A1782E222C636F756E743A2243616E742E227D3B66756E6374696F6E204B2865297B72657475726E2841727261792E697341727261792865293F653A5B5D292E6D61702866756E6374696F6E2865297B76617220743D6526';
wwv_flow_imp.g_varchar2_table(164) := '26226F626A656374223D3D747970656F6620653F653A7B636F6C3A657D2C723D537472696E6728742E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475726E7B636F6C3A537472696E6728742E636F6C7C7C2222292E746F557070';
wwv_flow_imp.g_varchar2_table(165) := '65724361736528292C666E3A585B725D3F723A2273756D227D7D292E66696C7465722866756E6374696F6E2865297B72657475726E20652E636F6C7D297D66756E6374696F6E205128652C74297B666F722876617220723D303B723C652E6C656E677468';
wwv_flow_imp.g_varchar2_table(166) := '3B722B2B29696628655B725D2E636F6C3D3D3D742972657475726E20655B725D3B72657475726E206E756C6C7D66756E6374696F6E2065652865297B72657475726E20652E736F6D652866756E6374696F6E2865297B72657475726E2273756D22213D3D';
wwv_flow_imp.g_varchar2_table(167) := '652E666E7D297D66756E6374696F6E2074652865297B72657475726E206F2865297C7C22737472696E67223D3D747970656F66206526262222213D3D652E7472696D282926262169734E614E284E756D626572286529297D66756E6374696F6E20726528';
wwv_flow_imp.g_varchar2_table(168) := '652C742C72297B766172206E3D652E6D61702866756E6374696F6E2865297B72657475726E20655B745D7D292E66696C7465722866756E6374696F6E2865297B72657475726E206E756C6C213D6526262222213D3D657D293B69662822636F756E74223D';
wwv_flow_imp.g_varchar2_table(169) := '3D3D722972657475726E206E2E6C656E6774683B6966282273756D223D3D3D727C7C22617667223D3D3D72297B766172206F3D6E2E66696C746572287465292E6D6170284E756D626572292C613D6F2E7265647563652866756E6374696F6E28652C7429';
wwv_flow_imp.g_varchar2_table(170) := '7B72657475726E20652B747D2C30293B72657475726E2273756D223D3D3D723F613A6F2E6C656E6774683F612F6F2E6C656E6774683A6E756C6C7D766172206C3D6E756C6C2C693D6E756C6C3B72657475726E206E2E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(171) := '6F6E2865297B76617220743D74652865293F6E756C6C3A642865292C6E3D74652865293F4E756D6265722865293A743F742E67657454696D6528293A537472696E672865293B286E756C6C3D3D3D697C7C28226D696E223D3D3D723F6E3C693A6E3E6929';
wwv_flow_imp.g_varchar2_table(172) := '292626286C3D652C693D6E297D292C6C7D66756E6374696F6E206E6528652C742C722C6E297B766172206F3D65652874292C613D2D312C6C3D652E6D61702866756E6374696F6E28652C6E297B766172206C3D652E636F6C3F5128742C652E636F6C293A';
wwv_flow_imp.g_varchar2_table(173) := '6E756C6C3B72657475726E206C2626613C30262628613D6E292C6C3F66756E6374696F6E28652C742C722C6E297B766172206F2C613D726528722C742E636F6C2C742E666E293B72657475726E286F3D6E756C6C3D3D613F22223A22636F756E74223D3D';
wwv_flow_imp.g_varchar2_table(174) := '3D742E666E3F7028612C22696E7422293A226D696E223D3D3D742E666E7C7C226D6178223D3D3D742E666E3F74652861293F7028612C652E666D747C7C226D6F6E657922293A7028612C652E666D74293A22617667223D3D3D742E666E3F7028612C652E';
wwv_flow_imp.g_varchar2_table(175) := '666D74262622696E7422213D3D652E666D743F652E666D743A226D6F6E657922293A7028612C652E666D747C7C226D6F6E657922292926266E26264A5B742E666E5D3F4A5B742E666E5D2B2220222B6F3A6F7D28652C6C2C722C6F293A22227D293B7265';
wwv_flow_imp.g_varchar2_table(176) := '7475726E7B61743A613C303F652E6C656E6774683A612C63656C6C733A6C2C746578743A6E7D7D66756E6374696F6E206F6528652C742C72297B72657475726E204E28652E746F74616C734C6162656C7C7C22546F74616C6573222C742C7B434F554E54';
wwv_flow_imp.g_varchar2_table(177) := '3A722E6C656E6774687D297D66756E6374696F6E20616528652C74297B76617220723D7B636F6E74656E743A652E746578742C636F6C5370616E3A652E61747C7C742C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E20303D';
wwv_flow_imp.g_varchar2_table(178) := '3D3D652E61743F5B5B725D2C652E63656C6C732E736C69636528295D3A5B5B725D2E636F6E63617428652E63656C6C732E736C69636528652E617429295D7D66756E6374696F6E206C652865297B72657475726E21313D3D3D652E627265616B546F7461';
wwv_flow_imp.g_varchar2_table(179) := '6C733F5B5D3A4B2841727261792E6973417272617928652E627265616B546F74616C73293F652E627265616B546F74616C733A652E746F74616C73297D66756E6374696F6E20696528652C74297B69662821652E627265616B42797C7C21742E6C656E67';
wwv_flow_imp.g_varchar2_table(180) := '74682972657475726E20742E6D61702866756E6374696F6E28652C74297B72657475726E7B6B3A22726F77222C723A652C693A747D7D293B76617220723D537472696E6728652E627265616B4279292E746F55707065724361736528292C6E3D5B5D2C6F';
wwv_flow_imp.g_varchar2_table(181) := '3D6E756C6C2C613D302C6C3D6C652865292E6C656E6774683E303B66756E6374696F6E206928297B6F26266C26266E2E70757368287B6B3A22737562222C723A6F2E722C726F77733A6F2E726F77737D297D72657475726E20742E666F72456163682866';
wwv_flow_imp.g_varchar2_table(182) := '756E6374696F6E2874297B766172206C3D537472696E67286E756C6C3D3D3D745B725D7C7C766F696420303D3D3D745B725D3F22223A745B725D293B6F26266F2E6B65793D3D3D6C7C7C286928292C6F3D7B6B65793A6C2C723A742C726F77733A5B5D7D';
wwv_flow_imp.g_varchar2_table(183) := '2C2131213D3D652E627265616B5469746C6526266E2E70757368287B6B3A2268656164222C723A742C726F77733A6F2E726F77737D29292C6F2E726F77732E707573682874292C6E2E70757368287B6B3A22726F77222C723A742C693A612B2B7D297D29';
wwv_flow_imp.g_varchar2_table(184) := '2C6928292C6E7D66756E6374696F6E20736528652C742C72297B766172206E2C6F3D7B7D2C613D537472696E6728652E627265616B4279292E746F55707065724361736528293B666F72286E20696E20742E72296F5B6E5D3D742E725B6E5D3B6F2E434F';
wwv_flow_imp.g_varchar2_table(185) := '554E543D742E726F77732E6C656E6774683B766172206C3D2268656164223D3D3D742E6B3F652E627265616B5469746C653A652E627265616B4C6162656C3B72657475726E206E756C6C213D6C26262130213D3D6C7C7C286C3D2268656164223D3D3D74';
wwv_flow_imp.g_varchar2_table(186) := '2E6B3F227B222B612B227D223A22537562746F74616C207B222B612B227D22292C4E286C2C722C6F297D66756E6374696F6E20756528652C742C72297B696628652E6D6170297B766172206E3D4D28742C537472696E6728652E76616C7565292E726570';
wwv_flow_imp.g_varchar2_table(187) := '6C616365282F5B7B7D5D2F672C2222292E73706C697428227C22295B305D2C72293B72657475726E20766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475';
wwv_flow_imp.g_varchar2_table(188) := '726E20652E666D7426262F5E5C7B5B5E7D7C5D2B5C7D242F2E74657374286F7C7C2222293F70284D28742C6F2E736C69636528312C2D31292C72292C652E666D74293A4E286F2C742C72297D7661722063653D7B746578743A312C6D756C74696C696E65';
wwv_flow_imp.g_varchar2_table(189) := '3A312C6C6973743A312C636865636B626F783A317D2C66653D2223463246364641222C64653D2223424643394434222C68653D22E29892222C70653D22E29890223B66756E6374696F6E2067652865297B76617220743D537472696E67286E756C6C3D3D';
wwv_flow_imp.g_varchar2_table(190) := '653F22223A65293B696628212F5E5B412D5A612D7A5F5D5B412D5A612D7A302D395F5D7B302C33397D242F2E746573742874297C7C2F5E5B412D5A612D7A5D7B312C337D5B302D395D2B242F2E746573742874297C7C2F5E5B527243635D242F2E746573';
wwv_flow_imp.g_varchar2_table(191) := '742874297C7C2F5E5B52725D5B302D395D2A5B43635D5B302D395D2A242F2E74657374287429297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F20696E76C3A16C69646F3A2022272B742B27222E20557365206C657472';
wwv_flow_imp.g_varchar2_table(192) := '61732C206EC3BA6D65726F732079205F202868617374612034302C2073696E206573706163696F73206E692070756E746F7329207920717565206E6F20706172657A636120756E612063656C646120646520457863656C202841312C2052314331292E27';
wwv_flow_imp.g_varchar2_table(193) := '293B72657475726E20747D66756E6374696F6E206D6528297B76617220653D7B7D3B72657475726E2066756E6374696F6E2874297B76617220723D742E746F4C6F7765724361736528293B696628655B725D297468726F77206E6577204572726F722827';
wwv_flow_imp.g_varchar2_table(194) := '4E6F6D6272652064652063616D706F20726570657469646F20656E20656C20646F63756D656E746F3A2022272B742B27222E27293B72657475726E20655B725D3D312C747D7D66756E6374696F6E20766528652C742C72297B766172206E3D6B28652C74';
wwv_flow_imp.g_varchar2_table(195) := '295B305D7C7C7B7D3B72657475726E28652E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E7768656E7C7C5028652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E286F';
wwv_flow_imp.g_varchar2_table(196) := '297B6966286F2E656D7074792972657475726E7B656D7074793A21302C7370616E3A6F2E7370616E7D3B76617220613D537472696E67286F2E696E7075747C7C227465787422292E746F4C6F7765724361736528293B6966282163655B615D297468726F';
wwv_flow_imp.g_varchar2_table(197) := '77206E6577204572726F7228275469706F2064652063616D706F206E6F20736F706F727461646F3A2022272B6F2E696E7075742B27222028746578742C206D756C74696C696E652C206C6973742C20636865636B626F78292E27293B766172206C3D6765';
wwv_flow_imp.g_varchar2_table(198) := '286F2E6E616D65292B28727C7C2222292C693D766F696420303D3D3D6F2E76616C75657C7C6E756C6C3D3D3D6F2E76616C75653F22223A537472696E67287565286F2C742C6E29292C733D226C697374223D3D3D613F66756E6374696F6E28652C74297B';
wwv_flow_imp.g_varchar2_table(199) := '76617220723D5B5D3B66756E6374696F6E206E2865297B2222213D3D28653D537472696E67286E756C6C3D3D653F22223A6529292626722E696E6465784F662865293C302626722E707573682865297D6966282841727261792E6973417272617928652E';
wwv_flow_imp.g_varchar2_table(200) := '6F7074696F6E73293F652E6F7074696F6E733A5B5D292E666F7245616368286E292C652E6F7074696F6E7346726F6D297B766172206F3D537472696E6728652E6F7074696F6E7346726F6D292E73706C697428222E22292C613D6F5B315D3F6F5B315D2E';
wwv_flow_imp.g_varchar2_table(201) := '746F55707065724361736528293A6E756C6C3B6B287B736F757263653A6F5B305D7D2C74292E666F72456163682866756E6374696F6E2865297B6E28613F655B615D3A655B4F626A6563742E6B6579732865295B305D5D297D297D72657475726E20727D';
wwv_flow_imp.g_varchar2_table(202) := '286F2C74293A5B5D3B696628226C697374223D3D3D61262621732E6C656E677468297468726F77206E6577204572726F722827456C2063616D706F2022272B6C2B272220657320756E61206C697374612073696E206F7063696F6E657320286F7074696F';
wwv_flow_imp.g_varchar2_table(203) := '6E732075206F7074696F6E7346726F6D292E27293B76617220752C633D282274657874223D3D3D617C7C226D756C74696C696E65223D3D3D612926264E756D626572286F2E6D61784C656E677468293E303F4D6174682E666C6F6F72284E756D62657228';
wwv_flow_imp.g_varchar2_table(204) := '6F2E6D61784C656E67746829293A303B72657475726E226D756C74696C696E6522213D3D61262628693D692E7265706C616365282F5C723F5C6E2F672C22202229292C226C697374223D3D3D612626732E696E6465784F662869293C30262628693D2222';
wwv_flow_imp.g_varchar2_table(205) := '292C63262628693D692E73756273747228302C6329292C7B6C6162656C3A4E286F2E6C6162656C2C742C6E292C6E616D653A6C2C696E7075743A612C6F7074696F6E733A732C76616C75653A22636865636B626F78223D3D3D613F22223A692C63686563';
wwv_flow_imp.g_varchar2_table(206) := '6B65643A22636865636B626F78223D3D3D61262628753D692C21303D3D3D757C7C2F5E28737C73697C73C3AD7C797C7965737C317C787C747275657C6F6E29242F692E7465737428537472696E67286E756C6C3D3D753F22223A75292E7472696D282929';
wwv_flow_imp.g_varchar2_table(207) := '292C6D61784C656E6774683A632C726561644F6E6C793A21303D3D3D6F2E726561644F6E6C792C6C696E65733A226D756C74696C696E65223D3D3D613F4D6174682E6D617828322C4D6174682E6D696E2832302C4E756D626572286F2E6C696E6573297C';
wwv_flow_imp.g_varchar2_table(208) := '7C3329293A312C706C616365686F6C6465723A6F2E706C616365686F6C6465723F4E286F2E706C616365686F6C6465722C742C6E293A22222C7370616E3A6F2E7370616E2C6C61623A4965286F2C65297D7D297D66756E6374696F6E20626528652C7429';
wwv_flow_imp.g_varchar2_table(209) := '7B76617220723D652E666F726D7C7C7B7D2C6E3D742626766F69642030213D3D742E666F726D50617373776F726426266E756C6C213D3D742E666F726D50617373776F72643F742E666F726D50617373776F72643A722E70617373776F72643B72657475';
wwv_flow_imp.g_varchar2_table(210) := '726E7B70726F746563743A2131213D3D722E70726F746563742C70617373776F72643A6E3F537472696E67286E293A22227D7D66756E6374696F6E2077652865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B726574';
wwv_flow_imp.g_varchar2_table(211) := '75726E206526262822666F726D756C6172696F223D3D3D652E747970657C7C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E736F6D65287765297C7C22677275706F223D3D3D652E747970652626776528652E7365';
wwv_flow_imp.g_varchar2_table(212) := '6374696F6E7329297D297D66756E6374696F6E2079652865297B76617220743D652626652E62617463682626652E62617463682E73756D6D6172793B72657475726E20776528652626652E73656374696F6E73297C7C212821747C7C2128776528742E73';
wwv_flow_imp.g_varchar2_table(213) := '656374696F6E73297C7C742E6C61796F75742626776528742E6C61796F75742E73656374696F6E732929297D7661722078653D5B313131363335323430382C333630393736373435382C313839393434373434312C3630323839313732352C3330343933';
wwv_flow_imp.g_varchar2_table(214) := '32333437312C333936343438343339392C333932313030393537332C323137333239353534382C3936313938373136332C343038313632383437322C313530383937303939332C333035333833343236352C323435333633353734382C32393337363731';
wwv_flow_imp.g_varchar2_table(215) := '3537392C323837303736333232312C333636343630393536302C333632343338313038302C323733343838333339342C3331303539383430312C313136343939363534322C3630373232353237382C313332333631303736342C31343236383831393837';
wwv_flow_imp.g_varchar2_table(216) := '2C333539303330343939342C313932353037383338382C343036383138323338332C323136323037383230362C3939313333363131332C323631343838383130332C3633333830333331372C333234383232323538302C333437393737343836382C3338';
wwv_flow_imp.g_varchar2_table(217) := '33353339303430312C323636363631333435382C343032323232343737342C3934343731313133392C3236343334373037382C323334313236323737332C3630343830373632382C323030373830303933332C3737303235353938332C31343935393930';
wwv_flow_imp.g_varchar2_table(218) := '3930312C313234393135303132322C313835363433313233352C313535353038313639322C333137353231383133322C313939363036343938362C323139383935303833372C323535343232303838322C333939393731393333392C3238323138333433';
wwv_flow_imp.g_varchar2_table(219) := '34392C3736363738343031362C323935323939363830382C323536363539343837392C333231303331333637312C333230333333373935362C333333363537313839312C313033343435373032362C333538343532383731312C32343636393438393031';
wwv_flow_imp.g_varchar2_table(220) := '2C3131333932363939332C333735383332363338332C3333383234313839352C3136383731373933362C3636363330373230352C313138383137393936342C3737333532393931322C313534363034353733342C313239343735373337322C3135323238';
wwv_flow_imp.g_varchar2_table(221) := '30353438352C313339363138323239312C323634333833333832332C313639353138333730302C323334333532373339302C313938363636313035312C313031343437373438302C323137373032363335302C313230363735393134322C323435363935';
wwv_flow_imp.g_varchar2_table(222) := '363033372C3334343037373632372C323733303438353932312C313239303836333436302C323832303330323431312C333135383435343237332C333235393733303830302C333530353935323635372C333334353736343737312C3130363231373030';
wwv_flow_imp.g_varchar2_table(223) := '382C333531363036353831372C333630363030383334342C333630303335323830342C313433323732353737362C343039343537313930392C313436373033313539342C3237353432333334342C3835313136393732302C3433303232373733342C3331';
wwv_flow_imp.g_varchar2_table(224) := '30303832333735322C3530363934383631362C313336333235383139352C3635393036303535362C333735303638353539332C3838333939373837372C333738353035303238302C3935383133393537312C333331383330373432372C31333232383232';
wwv_flow_imp.g_varchar2_table(225) := '3231382C333831323732333430332C313533373030323036332C323030333033343939352C313734373837333737392C333630323033363839392C313935353536323232322C313537353939303031322C323032343130343831352C3131323535393239';
wwv_flow_imp.g_varchar2_table(226) := '32382C323232373733303435322C323731363930343330362C323336313835323432342C3434323737363034342C323432383433363437342C3539333639383334342C323735363733343138372C333733333131303234392C333230343033313437392C';
wwv_flow_imp.g_varchar2_table(227) := '323939393335313537332C333332393332353239382C333831353932303432372C333339313536393631342C333932383338333930302C333531353236373237312C3536363238303731312C333934303138373630362C333435343036393533342C3431';
wwv_flow_imp.g_varchar2_table(228) := '31383633303237312C343030303233393939322C3131363431383437342C313931343133383535342C3137343239323432312C323733313035353237302C3238393338303335362C333230333939333030362C3436303339333236392C33323036323033';
wwv_flow_imp.g_varchar2_table(229) := '31352C3638353437313733332C3538373439363833362C3835323134323937312C313038363739323835312C313031373033363239382C3336353534333130302C313132363030303538302C323631383239373637362C313238383033333437302C3334';
wwv_flow_imp.g_varchar2_table(230) := '30393835353135382C313530313530353934382C343233343530393836362C313630373136373931352C3938373136373436382C313831363430323331362C313234363138393539315D3B66756E6374696F6E2053652865297B76617220742C722C6E3D';
wwv_flow_imp.g_varchar2_table(231) := '5B313737393033333730332C343038393233353732302C333134343133343237372C323232373837333539352C313031333930343234322C343237313137353732332C323737333438303736322C313539353735303132392C313335393839333131392C';
wwv_flow_imp.g_varchar2_table(232) := '323931373536353133372C323630303832323932342C3732353531313139392C3532383733343633352C343231353338393534372C313534313435393232352C3332373033333230395D2C6F3D652E6C656E6774682C613D6F2B31372B3132373E3E373C';
wwv_flow_imp.g_varchar2_table(233) := '3C372C6C3D6E65772055696E743841727261792861292C693D6E657720496E743332417272617928313630293B6C2E7365742865292C6C5B6F5D3D3132383B76617220733D382A6F3B6C5B612D315D3D32353526732C6C5B612D325D3D733E3E3E382632';
wwv_flow_imp.g_varchar2_table(234) := '35352C6C5B612D335D3D733E3E3E3136263235352C6C5B612D345D3D733E3E3E3234263235352C6C5B612D355D3D323535264D6174682E666C6F6F7228732F34323934393637323936293B666F722876617220753D343239343936373239362C633D303B';
wwv_flow_imp.g_varchar2_table(235) := '633C613B632B3D313238297B666F7228743D303B743C33323B742B2B29723D632B342A742C695B745D3D6C5B725D3C3C32347C6C5B722B315D3C3C31367C6C5B722B325D3C3C387C6C5B722B335D3B666F7228743D33323B743C3136303B742B3D32297B';
wwv_flow_imp.g_varchar2_table(236) := '76617220663D695B742D33305D2C643D695B742D32395D2C683D695B742D345D2C703D695B742D335D2C673D28663E3E3E317C643C3C3331295E28663E3E3E387C643C3C3234295E663E3E3E372C6D3D28683E3E3E31397C703C3C3133295E28703E3E3E';
wwv_flow_imp.g_varchar2_table(237) := '32397C683C3C33295E683E3E3E362C763D28703E3E3E31397C683C3C3133295E28683E3E3E32397C703C3C33295E28703E3E3E367C683C3C3236292C623D282828643E3E3E317C663C3C3331295E28643E3E3E387C663C3C3234295E28643E3E3E377C66';
wwv_flow_imp.g_varchar2_table(238) := '3C3C323529293E3E3E30292B28695B742D31335D3E3E3E30292B28763E3E3E30292B28695B742D33315D3E3E3E30292C773D672B695B742D31345D2B6D2B695B742D33325D2B4D6174682E666C6F6F7228622F75297C303B695B745D3D772C695B742B31';
wwv_flow_imp.g_varchar2_table(239) := '5D3D307C627D76617220793D6E5B305D2C783D6E5B315D2C533D6E5B325D2C453D6E5B335D2C543D6E5B345D2C433D6E5B355D2C413D6E5B365D2C7A3D6E5B375D2C4D3D6E5B385D2C4E3D6E5B395D2C463D6E5B31305D2C503D6E5B31315D2C6B3D6E5B';
wwv_flow_imp.g_varchar2_table(240) := '31325D2C4F3D6E5B31335D2C6A3D6E5B31345D2C493D6E5B31355D3B666F7228743D303B743C3136303B742B3D32297B766172204C3D284D3E3E3E31347C4E3C3C3138295E284D3E3E3E31387C4E3C3C3134295E284E3E3E3E397C4D3C3C3233292C523D';
wwv_flow_imp.g_varchar2_table(241) := '4D26465E7E4D266B2C443D28493E3E3E30292B2828284E3E3E3E31347C4D3C3C3138295E284E3E3E3E31387C4D3C3C3134295E284D3E3E3E397C4E3C3C323329293E3E3E30292B28284E26505E7E4E264F293E3E3E30292B2878655B742B315D3E3E3E30';
wwv_flow_imp.g_varchar2_table(242) := '292B28695B742B315D3E3E3E30292C553D6A2B4C2B522B78655B745D2B695B745D2B4D6174682E666C6F6F7228442F75297C303B447C3D303B76617220423D282828783E3E3E32387C793C3C34295E28793E3E3E327C783C3C3330295E28793E3E3E377C';
wwv_flow_imp.g_varchar2_table(243) := '783C3C323529293E3E3E30292B28287826455E7826435E452643293E3E3E30292C473D2828793E3E3E32387C783C3C34295E28783E3E3E327C793C3C3330295E28783E3E3E377C793C3C323529292B287926535E7926545E532654292B4D6174682E666C';
wwv_flow_imp.g_varchar2_table(244) := '6F6F7228422F75297C303B427C3D302C6A3D6B2C493D4F2C6B3D462C4F3D502C463D4D2C503D4E3B766172205F3D287A3E3E3E30292B28443E3E3E30293B4D3D412B552B4D6174682E666C6F6F72285F2F75297C302C4E3D307C5F2C413D542C7A3D432C';
wwv_flow_imp.g_varchar2_table(245) := '543D532C433D452C533D792C453D782C5F3D28443E3E3E30292B28423E3E3E30292C793D552B472B4D6174682E666C6F6F72285F2F75297C302C783D307C5F7D76617220573D5B792C782C532C452C542C432C412C7A2C4D2C4E2C462C502C6B2C4F2C6A';
wwv_flow_imp.g_varchar2_table(246) := '2C495D3B666F7228743D303B743C31363B742B3D32297B76617220243D286E5B742B315D3E3E3E30292B28575B742B315D3E3E3E30293B6E5B745D3D6E5B745D2B575B745D2B4D6174682E666C6F6F7228242F75297C302C6E5B742B315D3D307C247D7D';
wwv_flow_imp.g_varchar2_table(247) := '76617220483D6E65772055696E74384172726179283634293B666F7228743D303B743C31363B742B2B29485B342A745D3D6E5B745D3E3E3E32342C485B342A742B315D3D6E5B745D3E3E3E3136263235352C485B342A742B325D3D6E5B745D3E3E3E3826';
wwv_flow_imp.g_varchar2_table(248) := '3235352C485B342A742B335D3D323535266E5B745D3B72657475726E20487D7661722045653D5B35373834302C373433392C35323338302C33333938342C343336342C333630302C36313930322C31323630362C363235382C35373635372C3534323837';
wwv_flow_imp.g_varchar2_table(249) := '2C33343034312C31303235322C34333337302C32303136335D2C54653D5B5B34343739362C31393932392C33393835382C31303035332C32303130362C34303231322C31303736315D2C5B33313538352C36333137302C36343933332C36303236372C35';
wwv_flow_imp.g_varchar2_table(250) := '303933352C34303339392C31313139395D2C5B31373736332C33353532362C313435332C323930362C353831322C31313632342C32333234385D2C5B3838352C313737302C333534302C373038302C31343136302C32383332302C35363634305D2C5B35';
wwv_flow_imp.g_varchar2_table(251) := '353336392C34313133392C32303830372C34313631342C32313832312C34333634322C31373632315D2C5B32383438352C35363937302C34343334312C31393031392C33383033382C31343630352C32393231305D2C5B36303139352C35303739312C34';
wwv_flow_imp.g_varchar2_table(252) := '303137352C31303735312C32313530322C34333030342C32343533375D2C5B31383338372C33363737342C333934392C373839382C31353739362C33313539322C36333138345D2C5B34373230312C32343830332C34393630362C33373830352C313432';
wwv_flow_imp.g_varchar2_table(253) := '30332C32383430362C35363831325D2C5B31373832342C33353634382C313639372C333339342C363738382C31333537362C32373135325D2C5B34333630312C31373533392C33353037382C3535372C313131342C323232382C343435365D2C5B333033';
wwv_flow_imp.g_varchar2_table(254) := '38382C36303737362C35313935332C33343234332C373037392C31343135382C32383331365D2C5B31343132382C32383235362C35363531322C34333432352C31373235312C33343530322C373539375D2C5B31333130352C32363231302C3532343230';
wwv_flow_imp.g_varchar2_table(255) := '2C33353234312C3838332C313736362C333533325D2C5B343132392C383235382C31363531362C33333033322C343635372C393331342C31383632385D5D3B66756E6374696F6E2043652865297B76617220742C722C6E3D5B5D2C6F3D66756E6374696F';
wwv_flow_imp.g_varchar2_table(256) := '6E2865297B72657475726E28653C31363F2230223A2222292B652E746F537472696E67283136292E746F55707065724361736528297D3B666F7228743D303B743C652E6C656E6774683B742B2B297B76617220613D652E63686172436F64654174287429';
wwv_flow_imp.g_varchar2_table(257) := '3B6E2E707573682832353526617C7C613E3E3826323535297D766172206C3D45655B6E2E6C656E6774682D315D2C693D31352D6E2E6C656E6774682C733D303B666F7228743D303B743C6E2E6C656E6774683B742B2B297B76617220753D6E5B745D2C63';
wwv_flow_imp.g_varchar2_table(258) := '3D54655B692B2B5D3B666F7228723D303B723C373B722B2B293126752626286C5E3D635B725D292C753E3E3D317D66756E6374696F6E20662865297B72657475726E20653E3E313426317C653C3C312633323736377D666F7228743D6E2E6C656E677468';
wwv_flow_imp.g_varchar2_table(259) := '2D313B743E3D303B742D2D29733D662873295E6E5B745D3B72657475726E206F283235352628733D662873295E6E2E6C656E6774685E353238313129292B6F28733E3E3826323535292B6F28323535266C292B6F286C3E3E3826323535297D66756E6374';
wwv_flow_imp.g_varchar2_table(260) := '696F6E20416528652C742C72297B696628212F5E5B5C7832302D5C7837455D7B312C31357D242F2E74657374286529297468726F77206E6577204572726F7228224C6120636F6E7472617365C3B1612064652070726F7465636369C3B36E20646520576F';
wwv_flow_imp.g_varchar2_table(261) := '72642061646D697465206465203120612031352063617261637465726573204153434949202873696E2074696C646573206E6920C3B1292E22293B766172206E2C6F3D43652865292C613D6E65772055696E7438417272617928742E6C656E6774682B32';
wwv_flow_imp.g_varchar2_table(262) := '2A6F2E6C656E677468293B666F7228612E7365742874292C6E3D303B6E3C6F2E6C656E6774683B6E2B2B29615B742E6C656E6774682B322A6E5D3D6F2E63686172436F64654174286E293B766172206C3D53652861292C693D6E65772055696E74384172';
wwv_flow_imp.g_varchar2_table(263) := '726179283638293B666F72286E3D303B6E3C723B6E2B2B29692E736574286C292C695B36345D3D323535266E2C695B36355D3D6E3E3E3E38263235352C695B36365D3D6E3E3E3E3136263235352C695B36375D3D6E3E3E3E3234263235352C6C3D536528';
wwv_flow_imp.g_varchar2_table(264) := '69293B72657475726E206C7D766172207A653D2223443544434533223B66756E6374696F6E204D6528652C74297B76617220723D652E6C6162656C5769647468733B72657475726E2041727261792E6973417272617928722926264E756D62657228725B';
wwv_flow_imp.g_varchar2_table(265) := '745D293E303F4E756D62657228725B745D293A652E6C6162656C57696474687C7C33327D66756E6374696F6E204E6528652C74297B76617220723D652E68656164416C69676E7C7C742E68656164416C69676E7C7C2263656E746572223B72657475726E';
wwv_flow_imp.g_varchar2_table(266) := '226175746F223D3D3D723F652E616C69676E3A727D66756E6374696F6E20466528652C74297B76617220723D5B5D2C6E3D5B5D2C6F3D303B72657475726E20652E666F72456163682866756E6374696F6E2865297B76617220613D65262622726F77223D';
wwv_flow_imp.g_varchar2_table(267) := '3D3D652E7370616E3F742D6F3A4D6174682E6D617828312C4D6174682E6D696E28742C4D6174682E666C6F6F72284E756D62657228652626652E7370616E29297C7C3129293B6F2B613E74262628722E70757368286E292C6E3D5B5D2C6F3D30292C6E2E';
wwv_flow_imp.g_varchar2_table(268) := '70757368287B663A652C636F6C3A6F2C7370616E3A612C656D7074793A212821657C7C21652E656D707479297D292C286F2B3D61293D3D3D74262628722E70757368286E292C6E3D5B5D2C6F3D30297D292C6E2E6C656E6774682626722E70757368286E';
wwv_flow_imp.g_varchar2_table(269) := '292C727D66756E6374696F6E2050652865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E2065262628652E656D7074797C7C652E7370616E262631213D3D652E7370616E297D297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(270) := '206B652865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E7370616E7D2C30297D66756E6374696F6E204F6528652C742C72297B72657475726E2065262628652E616C69676E7C7C652E626F';
wwv_flow_imp.g_varchar2_table(271) := '6C647C7C652E636F6C6F727C7C652E66696C6C293F7B616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E7465737428652E616C69676E7C7C2222293F652E616C69676E3A6E756C6C2C626F6C643A2121652E626F6C642C636F6C';
wwv_flow_imp.g_varchar2_table(272) := '6F723A652E636F6C6F723F4F28652E636F6C6F722C742C72293A6E756C6C2C66696C6C3A652E66696C6C7C7C6E756C6C7D3A6E756C6C7D766172206A653D7B6C6566743A312C746F703A312C6E6F6E653A317D3B66756E6374696F6E20496528652C7429';
wwv_flow_imp.g_varchar2_table(273) := '7B66756E6374696F6E20722872297B72657475726E20652626766F69642030213D3D655B725D26266E756C6C213D3D655B725D26262222213D3D655B725D3F655B725D3A745B725D7D766172206E3D537472696E67287228226C6162656C506F73697469';
wwv_flow_imp.g_varchar2_table(274) := '6F6E22297C7C226C65667422292E746F4C6F7765724361736528292C6F3D7228226C6162656C416C69676E22292C613D7228226C6162656C426F6C6422292C6C3D7B706F733A6A655B6E5D3F6E3A226C656674222C73697A653A4E756D62657228722822';
wwv_flow_imp.g_varchar2_table(275) := '6C6162656C53697A652229293E303F4E756D626572287228226C6162656C53697A652229293A302C636F6C6F723A7228226C6162656C436F6C6F7222297C7C6E756C6C2C626F6C643A6E756C6C3D3D617C7C2131213D3D6126262266616C736522213D3D';
wwv_flow_imp.g_varchar2_table(276) := '612C75707065723A227570706572223D3D3D537472696E67287228226C6162656C4361736522297C7C2222292E746F4C6F7765724361736528292C616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E74657374286F7C7C222229';
wwv_flow_imp.g_varchar2_table(277) := '3F6F3A6E756C6C2C66696C6C3A7228226C6162656C46696C6C22297C7C6E756C6C7D3B72657475726E206C2E7374796C65643D212821657C7C2128652E6C6162656C53697A657C7C652E6C6162656C436F6C6F727C7C766F69642030213D3D652E6C6162';
wwv_flow_imp.g_varchar2_table(278) := '656C426F6C6426266E756C6C213D3D652E6C6162656C426F6C647C7C652E6C6162656C436173657C7C652E6C6162656C416C69676E7C7C652E6C6162656C46696C6C29297C7C212128742E6C6162656C53697A657C7C766F69642030213D3D742E6C6162';
wwv_flow_imp.g_varchar2_table(279) := '656C426F6C6426266E756C6C213D3D742E6C6162656C426F6C647C7C742E6C6162656C436173657C7C742E6C6162656C416C69676E292C6C7D66756E6374696F6E204C6528652C742C722C6E297B766172206F3D7B626F6C643A742E626F6C647D3B2874';
wwv_flow_imp.g_varchar2_table(280) := '2E73697A657C7C72292626286F2E73697A653D742E73697A657C7C39292C742E636F6C6F722626286F2E636F6C6F723D7B617267623A6C28742E636F6C6F72297D292C652E666F6E743D6F3B76617220613D742E616C69676E7C7C28723F6E3A6E756C6C';
wwv_flow_imp.g_varchar2_table(281) := '293B696628617C7C72297B76617220693D7B7D3B4F626A6563742E6B65797328652E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2874297B695B745D3D652E616C69676E6D656E745B745D7D292C61262628692E686F72';
wwv_flow_imp.g_varchar2_table(282) := '697A6F6E74616C3D61292C72262628692E766572746963616C3D22626F74746F6D22292C652E616C69676E6D656E743D697D742E66696C6C262628652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667';
wwv_flow_imp.g_varchar2_table(283) := '436F6C6F723A7B617267623A6C28742E66696C6C297D7D297D66756E6374696F6E20526528652C74297B72657475726E20742E75707065723F537472696E672865292E746F55707065724361736528293A657D66756E6374696F6E2044652865297B7265';
wwv_flow_imp.g_varchar2_table(284) := '7475726E28652E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E2874297B72657475726E2074262621742E656D7074792626226C65667422213D3D496528742C65292E706F737D297D66756E6374696F6E20556528652C74297B72657475';
wwv_flow_imp.g_varchar2_table(285) := '726E20652E73697A657C7C4D6174682E6D617828352C4D6174682E726F756E6428312E372A74292F32297D66756E6374696F6E20426528652C74297B72657475726E2E333532382A556528652C74292A312E322B2E347D66756E6374696F6E2047652865';
wwv_flow_imp.g_varchar2_table(286) := '297B76617220743D7B666F6E745374796C653A652E626F6C643F22626F6C64223A226E6F726D616C227D3B72657475726E20652E73697A65262628742E666F6E7453697A653D652E73697A65292C652E636F6C6F72262628742E74657874436F6C6F723D';
wwv_flow_imp.g_varchar2_table(287) := '6128652E636F6C6F7229292C652E66696C6C262628742E66696C6C436F6C6F723D6128652E66696C6C29292C652E616C69676E262628742E68616C69676E3D652E616C69676E292C747D66756E6374696F6E205F6528652C742C722C6E2C6F297B766172';
wwv_flow_imp.g_varchar2_table(288) := '206C3D722E6C622C693D5565286C2C6E292C733D2E333532382A693B6966286C2E66696C6C297B76617220753D61286C2E66696C6C293B652E73657446696C6C436F6C6F7228755B305D2C755B315D2C755B325D292C652E7265637428742E782B2E312C';
wwv_flow_imp.g_varchar2_table(289) := '742E792B2E312C742E77696474682D2E322C6F2B312E322A732B2E312C224622297D76617220633D61286C2E636F6C6F727C7C222330303030303022292C663D4D6174682E6D617828352C742E77696474682D322A6F293B652E736574466F6E74282268';
wwv_flow_imp.g_varchar2_table(290) := '656C766574696361222C6C2E626F6C643F22626F6C64223A226E6F726D616C22292C652E736574466F6E7453697A652869292C652E73657454657874436F6C6F7228635B305D2C635B315D2C635B325D293B76617220643D227269676874223D3D3D722E';
wwv_flow_imp.g_varchar2_table(291) := '616C69676E3F742E782B742E77696474682D6F3A2263656E746572223D3D3D722E616C69676E3F742E782B742E77696474682F323A742E782B6F3B652E7465787428652E73706C697454657874546F53697A6528537472696E6728722E74657874292C66';
wwv_flow_imp.g_varchar2_table(292) := '295B305D7C7C22222C642C742E792B6F2B2E39352A732C7B616C69676E3A227269676874223D3D3D722E616C69676E7C7C2263656E746572223D3D3D722E616C69676E3F722E616C69676E3A226C656674227D292C652E736574466F6E74282268656C76';
wwv_flow_imp.g_varchar2_table(293) := '6574696361222C226E6F726D616C22292C652E73657454657874436F6C6F7228302C302C30297D66756E6374696F6E20576528652C74297B72657475726E7B73697A653A652E73697A657C7C31342C73756253697A653A652E7375627469746C6553697A';
wwv_flow_imp.g_varchar2_table(294) := '657C7C392C726967687453697A653A652E726967687453697A657C7C392C666F6E743A495B4C28652E666F6E74295D2C66696C6C3A652E66696C6C7C7C742E7072696D6172792C636F6C6F723A652E636F6C6F727C7C742E68656164546578747D7D6675';
wwv_flow_imp.g_varchar2_table(295) := '6E6374696F6E20246528652C742C72297B766172206E3D6B28652C74295B305D7C7C7B7D2C6F3D28652E6669656C64737C7C652E6974656D737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E2065262621652E656D707479';
wwv_flow_imp.g_varchar2_table(296) := '26262821652E7768656E7C7C5028652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E2865297B72657475726E7B6C6162656C3A4E28652E6C6162656C2C742C6E292C76616C75653A756528652C742C6E292C636F6C6F723A652E636F6C';
wwv_flow_imp.g_varchar2_table(297) := '6F723F4F28652E636F6C6F722C742C6E293A6E756C6C7D7D293B72657475726E7B6974656D733A6F2C6E3A4D6174682E6D617828312C4D6174682E6D696E28362C4E756D62657228652E636F6C756D6E73297C7C4D6174682E6D696E286F2E6C656E6774';
wwv_flow_imp.g_varchar2_table(298) := '682C36297C7C3129292C66696C6C3A652E66696C6C7C7C2223463146344632222C616363656E743A766F696420303D3D3D652E616363656E743F722E7072696D6172793A652E616363656E742C6C6162656C436F6C6F723A652E6C6162656C436F6C6F72';
wwv_flow_imp.g_varchar2_table(299) := '7C7C2223373837383738222C76616C7565436F6C6F723A652E76616C7565436F6C6F727C7C722E7072696D6172792C6C6162656C53697A653A652E6C6162656C53697A657C7C372C73697A653A652E73697A657C7C31312C636172644761703A766F6964';
wwv_flow_imp.g_varchar2_table(300) := '2030213D3D652E636172644761703F4E756D62657228652E63617264476170293A337D7D66756E6374696F6E20486528652C742C72297B766172206E3D66756E6374696F6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174';
wwv_flow_imp.g_varchar2_table(301) := '732E696E6465784F662874293E3D302926262821727C7C4A6528652C7229297D2C6F3D28652E73656374696F6E737C7C5B5D292E66696C746572286E293B72657475726E20723F71286F292E66696C746572286E293A6F7D7661722056653D7B66696368';
wwv_flow_imp.g_varchar2_table(302) := '613A312C666F726D756C6172696F3A312C7461726A657461733A312C746578746F3A312C696D6167656E3A312C636F6469676F3A312C616C657274613A312C6C696E65613A312C7461626C613A312C6772616669636F3A312C6573706163696F3A312C63';
wwv_flow_imp.g_varchar2_table(303) := '6F6C756D6E61733A312C677275706F3A317D2C59653D7B6C696E65613A312C6573706163696F3A312C636F6C756D6E61733A312C677275706F3A317D3B66756E6374696F6E20716528652C742C72297B766172206E3D66756E6374696F6E2865297B7265';
wwv_flow_imp.g_varchar2_table(304) := '7475726E2065262656655B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D302926264A6528652C72297D3B72657475726E2071282841727261792E6973417272617928652E73656374696F';
wwv_flow_imp.g_varchar2_table(305) := '6E73293F652E73656374696F6E733A5B5D292E66696C746572286E292E6D61702866756E6374696F6E2874297B696628742E736F757263657C7C21652E736F757263657C7C59655B742E747970655D2972657475726E20743B76617220723D242874293B';
wwv_flow_imp.g_varchar2_table(306) := '72657475726E20722E736F757263653D652E736F757263652C727D29292E66696C746572286E297D66756E6374696F6E20586528652C74297B69662821652E656163687C7C21652E736F757263652972657475726E5B7B6374783A742C7375663A22227D';
wwv_flow_imp.g_varchar2_table(307) := '5D3B76617220723D537472696E6728652E736F75726365292E746F55707065724361736528292C6E3D6B28652C74292C6F3D652E6C696E6B7C7C7B7D3B72657475726E204E756D62657228652E6D6178293E302626286E3D6E2E736C69636528302C4E75';
wwv_flow_imp.g_varchar2_table(308) := '6D62657228652E6D61782929292C6E2E6D61702866756E6374696F6E28652C6E297B76617220612C6C3D242874292C693D2428742E646F637C7C7B7D293B666F72286120696E206C2E533D2428742E53292C6C2E535B725D3D5B655D2C4F626A6563742E';
wwv_flow_imp.g_varchar2_table(309) := '6B657973286F292E666F72456163682866756E6374696F6E2872297B766172206E3D6F5B725D7C7C7B7D2C613D537472696E672872292E746F55707065724361736528293B6C2E535B615D3D28742E535B615D7C7C5B5D292E66696C7465722866756E63';
wwv_flow_imp.g_varchar2_table(310) := '74696F6E2874297B72657475726E204F626A6563742E6B657973286E292E65766572792866756E6374696F6E2872297B72657475726E20537472696E6728745B722E746F55707065724361736528295D293D3D3D537472696E6728655B537472696E6728';
wwv_flow_imp.g_varchar2_table(311) := '6E5B725D292E746F55707065724361736528295D297D297D297D292C65294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C6129262628695B615D3D655B615D293B72657475726E206C2E646F633D692C';
wwv_flow_imp.g_varchar2_table(312) := '7B6374783A6C2C7375663A225F222B286E2B31297D7D297D66756E6374696F6E205A6528652C742C722C6E297B766172206F3D2841727261792E6973417272617928652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33292C613D6F2E';
wwv_flow_imp.g_varchar2_table(313) := '6C656E6774683B69662821612972657475726E5B5D3B766172206C3D6F2E6D61702866756E6374696F6E28742C72297B766172206E3D4E756D6265722828652E7769647468737C7C5B5D295B725D293B72657475726E206E3E303F6E3A3130302F617D29';
wwv_flow_imp.g_varchar2_table(314) := '2C693D6C2E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C733D766F69642030213D3D652E636F6C4761703F4E756D62657228652E636F6C476170293A342C753D6E2D732A28612D31292C633D303B72657475';
wwv_flow_imp.g_varchar2_table(315) := '726E206F2E6D61702866756E6374696F6E28652C6E297B766172206F3D752A6C5B6E5D2F692C613D71282841727261792E697341727261792865293F653A5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E66';
wwv_flow_imp.g_varchar2_table(316) := '6F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30297D29292E66696C7465722866756E6374696F6E2865297B72657475726E2065262656655B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E';
wwv_flow_imp.g_varchar2_table(317) := '696E6465784F662874293E3D302926264A6528652C72297D292E6D61702866756E6374696F6E2865297B72657475726E2066756E6374696F6E28652C74297B76617220722C6E3D7B7D3B666F72287220696E2065294F626A6563742E70726F746F747970';
wwv_flow_imp.g_varchar2_table(318) := '652E6861734F776E50726F70657274792E63616C6C28652C72292626286E5B725D3D655B725D293B6966285B2278222C2279222C227831222C227931222C227832222C227932225D2E666F72456163682866756E6374696F6E2865297B64656C65746520';
wwv_flow_imp.g_varchar2_table(319) := '6E5B655D7D292C22696D6167656E223D3D3D6E2E747970652626286E2E5F6D6178573D74292C226772616669636F223D3D3D6E2E74797065297B766172206F3D6E2E77696474687C7C3132302C613D6E2E6865696768747C7C37303B6F3E742626286E2E';
wwv_flow_imp.g_varchar2_table(320) := '77696474683D742C6E2E6865696768743D612A742F6F297D72657475726E22636F6469676F223D3D3D6E2E74797065262628227172223D3D3D537472696E67286E2E6B696E647C7C22717222292E746F4C6F7765724361736528292626286E2E73697A65';
wwv_flow_imp.g_varchar2_table(321) := '7C7C3330293E742626286E2E73697A653D74292C6E2E776964746826266E2E77696474683E742626286E2E77696474683D7429292C28226C696E6561223D3D3D6E2E747970657C7C22746578746F223D3D3D6E2E747970652926266E2E77696474682626';
wwv_flow_imp.g_varchar2_table(322) := '6E2E77696474683E742626286E2E77696474683D74292C6E7D28652C6F297D292C663D7B783A632C773A6F2C736563733A617D3B72657475726E20632B3D6F2B732C667D297D66756E6374696F6E204A6528652C74297B72657475726E22616C65727461';
wwv_flow_imp.g_varchar2_table(323) := '223D3D3D652E747970657C7C21652E7768656E7C7C5028652E7768656E2C742C6E756C6C297D66756E6374696F6E204B652865297B76617220742C723D7B7D3B666F72287420696E206E29725B745D3D6E5B745D3B766172206F3D652E70616765262665';
wwv_flow_imp.g_varchar2_table(324) := '2E706167652E7468656D657C7C7B7D3B666F72287420696E206F29725B745D3D6F5B745D3B72657475726E20727D7661722051653D7B7D2C65743D7B7D3B66756E6374696F6E2074742865297B76617220743D77696E646F772E61706578262661706578';
wwv_flow_imp.g_varchar2_table(325) := '2E656E767C7C7B7D3B72657475726E20537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C2222292E7265706C6163652822234150505F494D4147455323222C742E4150505F4649';
wwv_flow_imp.g_varchar2_table(326) := '4C45537C7C2222292E7265706C616365282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C616365282223494D4147455F50524546495823222C742E415045585F46494C45537C7C22';
wwv_flow_imp.g_varchar2_table(327) := '22297D66756E6374696F6E2072742865297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B315D2972657475726E7B773A28745B31365D3C3C32347C745B31375D3C3C31367C745B31';
wwv_flow_imp.g_varchar2_table(328) := '385D3C3C387C745B31395D293E3E3E302C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22706E67227D3B6966283235353D3D3D745B305D26263231363D3D3D745B315D29666F72';
wwv_flow_imp.g_varchar2_table(329) := '2876617220723D323B723C742E6C656E6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B335D3B6966286E3E3D31393226266E3C3D3230372626313936213D3D6E262632303021';
wwv_flow_imp.g_varchar2_table(330) := '3D3D6E2626323034213D3D6E2972657475726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A7067227D3B722B3D322B6F7D656C736520722B2B3B7468726F77206E6577204572726F72';
wwv_flow_imp.g_varchar2_table(331) := '2822466F726D61746F20646520696D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E206E742865297B666F722876617220743D6E65772055696E743841727261792865292C723D22222C';
wwv_flow_imp.g_varchar2_table(332) := '6E3D303B6E3C742E6C656E6774683B6E2B3D333237363829722B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E7375626172726179286E2C6E2B333237363829293B72657475726E2062746F612872297D66756E63';
wwv_flow_imp.g_varchar2_table(333) := '74696F6E206F742865297B72657475726E2050726F6D6973652E616C6C2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B65262622696D61';
wwv_flow_imp.g_varchar2_table(334) := '67656E223D3D3D652E747970652626652E75726C262621652E6669656C642626742E7075736828652E75726C292C65262622636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F72456163682872292C652626595B65';
wwv_flow_imp.g_varchar2_table(335) := '2E747970655D2626722828652E6669656C64737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C65262622677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C652626';
wwv_flow_imp.g_varchar2_table(336) := '227461626C61223D3D3D652E74797065262628652E636F6C756D6E737C7C5B5D292E666F72456163682866756E6374696F6E2865297B652626652E63656C6C262622696D6167656E223D3D3D652E63656C6C2E747970652626652E63656C6C2E75726C26';
wwv_flow_imp.g_varchar2_table(337) := '2621652E63656C6C2E6669656C642626537472696E6728652E63656C6C2E75726C292E696E6465784F6628227B22293C302626742E7075736828652E63656C6C2E75726C297D297D297D72657475726E207228652E73656374696F6E73292C652E626174';
wwv_flow_imp.g_varchar2_table(338) := '63682626652E62617463682E73756D6D6172792626287228652E62617463682E73756D6D6172792E73656374696F6E73292C652E62617463682E73756D6D6172792E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F75742E73';
wwv_flow_imp.g_varchar2_table(339) := '656374696F6E7329292C747D2865292E6D61702866756E6374696F6E2865297B76617220743D74742865293B72657475726E2051655B745D3F6E756C6C3A666574636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E74';
wwv_flow_imp.g_varchar2_table(340) := '68656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20636172676172206C6120696D6167656E20222B742B222028222B652E7374617475732B222922293B72657475726E20';
wwv_flow_imp.g_varchar2_table(341) := '652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B76617220723D72742865293B51655B745D3D7B6275663A652C773A722E772C683A722E682C6578743A722E6578742C646174613A22646174613A696D6167652F22';
wwv_flow_imp.g_varchar2_table(342) := '2B28226A7067223D3D3D722E6578743F226A706567223A22706E6722292B223B6261736536342C222B6E742865297D7D297D29297D66756E6374696F6E2061742865297B76617220743D537472696E672865292E7265706C616365282F5E646174613A5B';
wwv_flow_imp.g_varchar2_table(343) := '5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C2222293B69662821742972657475726E206E756C6C3B76617220723D226236343A222B742E6C656E6774682B223A222B742E73756273747228302C3634292B742E737562737472282D36';
wwv_flow_imp.g_varchar2_table(344) := '34293B69662851655B725D2972657475726E2051655B725D3B666F7228766172206E3D61746F622874292C6F3D6E65772055696E74384172726179286E2E6C656E677468292C613D303B613C6E2E6C656E6774683B612B2B296F5B615D3D6E2E63686172';
wwv_flow_imp.g_varchar2_table(345) := '436F646541742861293B766172206C3D7274286F2E627566666572293B72657475726E2051655B725D3D7B6275663A6F2E6275666665722C773A6C2E772C683A6C2E682C6578743A6C2E6578742C646174613A22646174613A696D6167652F222B28226A';
wwv_flow_imp.g_varchar2_table(346) := '7067223D3D3D6C2E6578743F226A706567223A22706E6722292B223B6261736536342C222B747D2C51655B725D7D66756E6374696F6E206C7428652C74297B696628652E6669656C64297B76617220723D2828652E736F757263653F6B28652C74295B30';
wwv_flow_imp.g_varchar2_table(347) := '5D3A742E646F63297C7C7B7D295B537472696E6728652E6669656C64292E746F55707065724361736528295D3B7472797B72657475726E20723F61742872293A6E756C6C7D63617463682874297B72657475726E2077696E646F772E636F6E736F6C6526';
wwv_flow_imp.g_varchar2_table(348) := '26636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B652E6669656C642C74292C6E756C6C7D7D72657475726E2051655B747428652E75726C295D7C7C6E756C6C7D66756E6374696F';
wwv_flow_imp.g_varchar2_table(349) := '6E20697428652C74297B76617220723D652E77696474687C7C34302C6E3D652E6865696768747C7C722A742E682F742E773B72657475726E21652E77696474682626652E686569676874262628723D6E2A742E772F742E68292C652E5F6D617857262672';
wwv_flow_imp.g_varchar2_table(350) := '3E652E5F6D6178572626286E3D6E2A652E5F6D6178572F722C723D652E5F6D617857292C7B773A722C683A6E7D7D66756E6374696F6E2073742865297B666F722876617220743D61746F622865292C723D6E65772055696E7438417272617928742E6C65';
wwv_flow_imp.g_varchar2_table(351) := '6E677468292C6E3D303B6E3C742E6C656E6774683B6E2B2B29725B6E5D3D742E63686172436F64654174286E293B72657475726E20722E6275666665727D66756E6374696F6E20757428652C742C72297B72657475726E7B6275663A737428652E726570';
wwv_flow_imp.g_varchar2_table(352) := '6C616365282F5E646174613A5B5E2C5D2A2C2F2C222229292C646174613A652C773A742C683A722C6578743A22706E67227D7D66756E6374696F6E20637428652C74297B69662822756E646566696E6564223D3D747970656F6620646F63756D656E747C';
wwv_flow_imp.g_varchar2_table(353) := '7C21646F63756D656E742E637265617465456C656D656E74297468726F77206E6577204572726F722822536520726571756965726520756E206E6176656761646F72202863616E7661732920706172612067656E65726172206772C3A16669636F732E22';
wwv_flow_imp.g_varchar2_table(354) := '293B76617220723D646F63756D656E742E637265617465456C656D656E74282263616E76617322293B72657475726E20722E77696474683D652C722E6865696768743D742C727D7661722066743D6E756C6C3B66756E6374696F6E2064742865297B7265';
wwv_flow_imp.g_varchar2_table(355) := '7475726E5B653E3E3E3234263235352C653E3E3E3136263235352C653E3E3E38263235352C32353526655D7D66756E6374696F6E20687428652C74297B76617220723D5B652E63686172436F646541742830292C652E63686172436F646541742831292C';
wwv_flow_imp.g_varchar2_table(356) := '652E63686172436F646541742832292C652E63686172436F646541742833295D2C6E3D6E65772055696E7438417272617928342B742E6C656E677468293B6E2E73657428722C30292C6E2E73657428742C34293B766172206F3D6E65772055696E743841';
wwv_flow_imp.g_varchar2_table(357) := '727261792831322B742E6C656E677468293B72657475726E206F2E73657428647428742E6C656E677468292C30292C6F2E736574286E2C34292C6F2E7365742864742866756E6374696F6E2865297B696628216674297B66743D5B5D3B666F7228766172';
wwv_flow_imp.g_varchar2_table(358) := '20743D303B743C3235363B742B2B297B666F722876617220723D742C6E3D303B6E3C383B6E2B2B29723D3126723F333938383239323338345E723E3E3E313A723E3E3E313B66745B745D3D723E3E3E307D7D666F7228766172206F3D3432393439363732';
wwv_flow_imp.g_varchar2_table(359) := '39352C613D303B613C652E6C656E6774683B612B2B296F3D66745B32353526286F5E655B615D295D5E6F3E3E3E383B72657475726E28343239343936373239355E6F293E3E3E307D286E29292C382B742E6C656E677468292C6F7D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(360) := '707428652C742C722C6E297B766172206F2C6C2C693D4D6174682E6365696C28652F38292B312C733D6E65772055696E7438417272617928692A74293B666F72286C3D303B6C3C743B6C2B2B29666F72286F3D303B6F3C653B6F2B2B2972286F2C6C2926';
wwv_flow_imp.g_varchar2_table(361) := '2628735B6C2A692B312B286F3E3E33295D7C3D3132383E3E2837266F29293B76617220752C633D4D6174682E6365696C28732E6C656E6774682F3635353335292C663D6E65772055696E7438417272617928322B732E6C656E6774682B352A632B34292C';
wwv_flow_imp.g_varchar2_table(362) := '643D322C683D312C703D303B666F7228665B305D3D3132302C665B315D3D312C753D303B753C633B752B2B297B76617220673D36353533352A752C6D3D4D6174682E6D696E2836353533352C732E6C656E6774682D67293B665B642B2B5D3D753D3D3D63';
wwv_flow_imp.g_varchar2_table(363) := '2D313F313A302C665B642B2B5D3D323535266D2C665B642B2B5D3D6D3E3E382C665B642B2B5D3D323535267E6D2C665B642B2B5D3D7E6D3E3E38263235352C662E73657428732E737562617272617928672C672B6D292C64292C642B3D6D7D666F722875';
wwv_flow_imp.g_varchar2_table(364) := '3D303B753C732E6C656E6774683B752B2B29703D28702B28683D28682B735B755D2925363535323129292536353532313B662E7365742864742828703C3C31367C68293E3E3E30292C64293B76617220763D6E65772055696E7438417272617928313329';
wwv_flow_imp.g_varchar2_table(365) := '2C623D61286E7C7C222330303030303022293B762E7365742864742865292C30292C762E7365742864742874292C34292C765B385D3D312C765B395D3D333B76617220773D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31';
wwv_flow_imp.g_varchar2_table(366) := '332C31302C32362C31305D292C6874282249484452222C76292C68742822504C5445222C6E65772055696E74384172726179285B3235352C3235352C3235352C625B305D2C625B315D2C625B325D5D29292C6874282249444154222C66292C6874282249';
wwv_flow_imp.g_varchar2_table(367) := '454E44222C6E65772055696E74384172726179283029295D2C793D772E7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E6C656E6774687D2C30292C783D6E65772055696E743841727261792879292C533D303B72657475';
wwv_flow_imp.g_varchar2_table(368) := '726E20772E666F72456163682866756E6374696F6E2865297B782E73657428652C53292C532B3D652E6C656E6774687D292C7B6275663A782E6275666665722C646174613A22646174613A696D6167652F706E673B6261736536342C222B6E7428782E62';
wwv_flow_imp.g_varchar2_table(369) := '7566666572292C773A652C683A742C6578743A22706E67227D7D7661722067743D22323132323232203232323132322032323232323120313231323233203132313332322031333132323220313232323133203132323331322031333232313220323231';
wwv_flow_imp.g_varchar2_table(370) := '32313320323231333132203233313231322031313232333220313232313332203132323233312031313332323220313233313232203132333232312032323332313120323231313332203232313233312032313332313220323233313132203331323133';
wwv_flow_imp.g_varchar2_table(371) := '31203331313232322033323131323220333231323231203331323231322033323231313220333232323131203231323132332032313233323120323332313231203131313332332031333131323320313331333231203131323331332031333231313320';
wwv_flow_imp.g_varchar2_table(372) := '31333233313120323131333133203233313131332032333133313120313132313333203131323333312031333231333120313133313233203131333332312031333331323120333133313231203231313333312032333131333120323133313133203231';
wwv_flow_imp.g_varchar2_table(373) := '33333131203231333133312033313131323320333131333231203333313132312033313231313320333132333131203333323131312033313431313120323231343131203433313131312031313132323420313131343232203132313132342031323134';
wwv_flow_imp.g_varchar2_table(374) := '32312031343131323220313431323231203131323231342031313234313220313232313134203132323431312031343231313220313432323131203234313231312032323131313420343133313131203234313131322031333431313120313131323432';
wwv_flow_imp.g_varchar2_table(375) := '20313231313432203132313234312031313432313220313234313132203132343231312034313132313220343231313132203432313231312032313231343120323134313231203431323132312031313131343320313131333431203133313134312031';
wwv_flow_imp.g_varchar2_table(376) := '3134313133203131343331312034313131313320343131333131203131333134312031313431333120333131313431203431313133312032313134313220323131323134203231313233322032333331313132222E73706C697428222022293B66756E63';
wwv_flow_imp.g_varchar2_table(377) := '74696F6E206D742865297B653D537472696E672865292E7265706C616365282F5B5E5C7832302D5C7837455D2F672C223F22293B666F722876617220742C723D5B5D2C6E3D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B743D';
wwv_flow_imp.g_varchar2_table(378) := '6E2E657865632865293B29696628745B315D7C7C2F5E5C642B242F2E746573742865292626652E6C656E67746825323D3D30297B766172206F3D745B305D2C613D6F2E6C656E6774682D6F2E6C656E67746825323B722E70757368287B7365743A224322';
wwv_flow_imp.g_varchar2_table(379) := '2C743A6F2E73756273747228302C61297D292C613C6F2E6C656E6774682626722E70757368287B7365743A2242222C743A6F2E7375627374722861297D297D656C736520722E70757368287B7365743A2242222C743A745B305D7D293B766172206C3D5B';
wwv_flow_imp.g_varchar2_table(380) := '5D2C693D6E756C6C3B722E666F72456163682866756E6374696F6E2865297B6966286E756C6C3D3D3D693F6C2E70757368282243223D3D3D652E7365743F3130353A313034293A69213D3D652E73657426266C2E70757368282243223D3D3D652E736574';
wwv_flow_imp.g_varchar2_table(381) := '3F39393A313030292C693D652E7365742C2243223D3D3D652E73657429666F722876617220743D303B743C652E742E6C656E6774683B742B3D32296C2E70757368282B652E742E73756273747228742C3229293B656C736520666F722876617220723D30';
wwv_flow_imp.g_varchar2_table(382) := '3B723C652E742E6C656E6774683B722B2B296C2E7075736828652E742E63686172436F646541742872292D3332297D293B666F722876617220733D6C5B305D2C753D313B753C6C2E6C656E6774683B752B2B29732B3D752A6C5B755D3B6C2E7075736828';
wwv_flow_imp.g_varchar2_table(383) := '73253130332C313036293B76617220633D5B5D3B72657475726E206C2E666F72456163682866756E6374696F6E2865297B67745B655D2E73706C6974282222292E666F72456163682866756E6374696F6E28652C74297B666F722876617220723D303B72';
wwv_flow_imp.g_varchar2_table(384) := '3C2B653B722B2B29632E70757368287425323D3D30297D297D292C637D66756E6374696F6E20767428652C742C72297B766172206E3D727C7C28652E736F757263653F6B28652C74295B305D3A6E756C6C293B69662821722626652E736F757263652626';
wwv_flow_imp.g_varchar2_table(385) := '216E2972657475726E206E756C6C3B766172206F3D4E28652E76616C75652C742C6E293B696628216F2972657475726E206E756C6C3B76617220613D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292C6C3D652E63';
wwv_flow_imp.g_varchar2_table(386) := '6F6C6F727C7C2223303030303030223B696628227172223D3D3D61297B76617220693D66756E6374696F6E28652C74297B76617220723D77696E646F772E7172636F64653B6966282172297468726F77206E6577204572726F7228224E6F207365206361';
wwv_flow_imp.g_varchar2_table(387) := '7267C3B3206C61206C6962726572C3AD612064652063C3B36469676F732051522E22293B722E737472696E67546F427974657346756E63732626722E737472696E67546F427974657346756E63735B225554462D38225D262628722E737472696E67546F';
wwv_flow_imp.g_varchar2_table(388) := '42797465733D722E737472696E67546F427974657346756E63735B225554462D38225D293B766172206E3D7228302C537472696E6728747C7C224D22292E746F5570706572436173652829293B72657475726E206E2E6164644461746128537472696E67';
wwv_flow_imp.g_varchar2_table(389) := '286529292C6E2E6D616B6528292C7B6E3A6E2E6765744D6F64756C65436F756E7428292C6461726B3A66756E6374696F6E28652C74297B72657475726E206E2E69734461726B28742C65297D7D7D286F2C652E656363292C733D652E73697A657C7C3330';
wwv_flow_imp.g_varchar2_table(390) := '3B72657475726E7B6B696E643A227172222C746578743A6F2C636F6C733A692E6E2C726F77733A692E6E2C6461726B3A692E6461726B2C773A732C683A732C636F6C6F723A6C2C71756965743A327D7D69662822636F6465313238223D3D3D61297B7661';
wwv_flow_imp.g_varchar2_table(391) := '7220753D6D74286F292C633D652E77696474687C7C4D6174682E6D696E2839302C2E33332A752E6C656E677468293B72657475726E7B6B696E643A22626172222C746578743A6F2C636F6C733A752E6C656E6774682C726F77733A312C6461726B3A6675';
wwv_flow_imp.g_varchar2_table(392) := '6E6374696F6E2865297B72657475726E20755B655D7D2C773A632C683A652E6865696768747C7C31322C636F6C6F723A6C2C71756965743A382C6C6162656C3A2131213D3D652E73686F77546578742C7465787453697A653A652E7465787453697A657C';
wwv_flow_imp.g_varchar2_table(393) := '7C387D7D7468726F77206E6577204572726F7228225469706F2064652063C3B36469676F206E6F20736F706F727461646F3A20222B612B222028757365207172206F20636F6465313238292E22297D66756E6374696F6E2062742865297B76617220743D';
wwv_flow_imp.g_varchar2_table(394) := '652E71756965742C723D227172223D3D3D652E6B696E643F383A332C6E3D28652E636F6C732B322A74292A722C6F3D7074286E2C227172223D3D3D652E6B696E643F6E3A4D6174682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E';
wwv_flow_imp.g_varchar2_table(395) := '636F6C732A7229292C66756E6374696F6E286E2C6F297B76617220613D4D6174682E666C6F6F72286E2F72292D742C6C3D227172223D3D3D652E6B696E643F4D6174682E666C6F6F72286F2F72292D743A303B72657475726E20613E3D3026266C3E3D30';
wwv_flow_imp.g_varchar2_table(396) := '2626613C652E636F6C7326266C3C652E726F77732626652E6461726B28612C6C297D2C652E636F6C6F72293B72657475726E206F2E776D6D3D652E772A28652E636F6C732B322A74292F652E636F6C732C6F2E686D6D3D227172223D3D3D652E6B696E64';
wwv_flow_imp.g_varchar2_table(397) := '3F6F2E776D6D3A652E682C6F7D7661722077743D5B2223314634453739222C2223453037423339222C2223324538423537222C2223433033393242222C2223374433433938222C2223313641303835222C2223443441433044222C222335443644374522';
wwv_flow_imp.g_varchar2_table(398) := '2C2223413034303030222C2223323837344136225D3B66756E6374696F6E20797428652C742C72297B766172206E3D77696E646F772E43686172743B696628216E297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C';
wwv_flow_imp.g_varchar2_table(399) := '6962726572C3AD61206465206772C3A16669636F73202843686172742E6A73292E22293B766172206F3D6B28652C74293B696628216F2E6C656E6774682972657475726E206E756C6C3B766172206C3D537472696E6728652E736F757263657C7C222229';
wwv_flow_imp.g_varchar2_table(400) := '2E746F55707065724361736528292C693D742E545B6C5D7C7C7B7D2C733D4F626A6563742E6B6579732869292C753D652E63617465676F72793F537472696E6728652E63617465676F7279292E746F55707065724361736528293A732E66696C74657228';
wwv_flow_imp.g_varchar2_table(401) := '66756E6374696F6E2865297B72657475726E224E554D42455222213D3D695B655D262622444F435F4B455922213D3D657D295B305D7C7C735B305D2C633D28652E7365726965732626652E7365726965732E6C656E6774683F652E7365726965733A732E';
wwv_flow_imp.g_varchar2_table(402) := '66696C7465722866756E6374696F6E2865297B72657475726E224E554D424552223D3D3D695B655D262665213D3D75262622444F435F4B455922213D3D657D29292E6D61702866756E6374696F6E2865297B72657475726E20653D22737472696E67223D';
wwv_flow_imp.g_varchar2_table(403) := '3D747970656F6620653F7B636F6C3A657D3A652C7B636F6C3A537472696E6728652E636F6C292E746F55707065724361736528292C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628652E636F6C292C636F6C6F723A65';
wwv_flow_imp.g_varchar2_table(404) := '2E636F6C6F727D7D292C643D652E63686172747C7C22626172222C683D22706965223D3D3D647C7C22646F7567686E7574223D3D3D642C673D31312E33343B68262628633D632E736C69636528302C3129293B766172206D3D652E77696474687C7C3132';
wwv_flow_imp.g_varchar2_table(405) := '302C763D652E6865696768747C7C37302C623D6374284D6174682E726F756E64286D2A67292C4D6174682E726F756E6428762A6729292C773D66756E6374696F6E2865297B72657475726E2E333532382A652A677D2C793D652E73697A657C7C382C783D';
wwv_flow_imp.g_varchar2_table(406) := '2248656C7665746963612C20417269616C2C2073616E732D7365726966222C533D7B66616D696C793A782C73697A653A772879297D2C453D652E636F6C6F72732626652E636F6C6F72732E6C656E6774683F652E636F6C6F72733A5B722E7072696D6172';
wwv_flow_imp.g_varchar2_table(407) := '795D2E636F6E6361742877742E736C696365283129292C543D66756E6374696F6E2874297B72657475726E207028742C652E666D747C7C284D6174682E726F756E642874293D3D3D743F22696E74223A226E756D3A322229297D2C433D6F2E6D61702866';
wwv_flow_imp.g_varchar2_table(408) := '756E6374696F6E2874297B76617220723D745B755D3B72657475726E206E756C6C3D3D723F22223A652E63617465676F7279466D743F7028722C652E63617465676F7279466D74293A537472696E672872297D292C413D632E6D61702866756E6374696F';
wwv_flow_imp.g_varchar2_table(409) := '6E28722C6E297B766172206C3D722E636F6C6F727C7C455B6E25452E6C656E6774685D2C693D7B6C6162656C3A4E28722E6C6162656C2C74292C646174613A6F2E6D61702866756E6374696F6E2865297B76617220743D655B722E636F6C5D3B72657475';
wwv_flow_imp.g_varchar2_table(410) := '726E206E756C6C3D3D747C7C22223D3D3D743F6E756C6C3A4E756D6265722874297D297D3B72657475726E20683F28692E6261636B67726F756E64436F6C6F723D6F2E6D61702866756E6374696F6E28652C74297B72657475726E20455B7425452E6C65';
wwv_flow_imp.g_varchar2_table(411) := '6E6774685D7D292C692E626F72646572436F6C6F723D2223464646464646222C692E626F7264657257696474683D77282E3829293A226C696E65223D3D3D647C7C2261726561223D3D3D643F28692E626F72646572436F6C6F723D6C2C692E6261636B67';
wwv_flow_imp.g_varchar2_table(412) := '726F756E64436F6C6F723D2261726561223D3D3D643F66756E6374696F6E28652C74297B76617220723D612865293B72657475726E227267626128222B725B305D2B222C222B725B315D2B222C222B725B325D2B222C222B742B2229227D286C2C2E3235';
wwv_flow_imp.g_varchar2_table(413) := '293A6C2C692E66696C6C3D2261726561223D3D3D642C692E626F7264657257696474683D7728312E34292C692E706F696E745261646975733D7728312E35292C692E706F696E744261636B67726F756E64436F6C6F723D6C2C692E74656E73696F6E3D65';
wwv_flow_imp.g_varchar2_table(414) := '2E736D6F6F74683F2E33353A30293A28692E6261636B67726F756E64436F6C6F723D6C2C692E626F7264657257696474683D30292C697D292C7A3D7B666F6E743A532C636F6C6F723A2223343434343434227D2C4D3D7B7D3B6966282168297B76617220';
wwv_flow_imp.g_varchar2_table(415) := '463D7B626567696E41745A65726F3A2131213D3D652E626567696E41745A65726F2C737461636B65643A2121652E737461636B65642C67726163653A652E76616C7565733F2268626172223D3D3D643F22323525223A22313225223A302C677269643A7B';
wwv_flow_imp.g_varchar2_table(416) := '636F6C6F723A2223453345374543222C6C696E6557696474683A77282E34297D2C626F726465723A7B646973706C61793A21317D2C7469636B733A7B666F6E743A532C636F6C6F723A2223343434343434222C63616C6C6261636B3A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(417) := '2865297B72657475726E20542865297D7D7D2C503D7B737461636B65643A2121652E737461636B65642C677269643A7B646973706C61793A21317D2C7469636B733A7A7D3B4D3D2268626172223D3D3D643F7B783A462C793A507D3A7B783A502C793A46';
wwv_flow_imp.g_varchar2_table(418) := '7D7D766172204F3D766F69642030213D3D652E6C6567656E643F2121652E6C6567656E643A687C7C632E6C656E6774683E312C6A3D6E6577206E28622E676574436F6E746578742822326422292C7B747970653A683F643A2268626172223D3D3D643F22';
wwv_flow_imp.g_varchar2_table(419) := '626172223A2261726561223D3D3D643F226C696E65223A642C646174613A7B6C6162656C733A432C64617461736574733A417D2C706C6174666F726D3A6E2E4261736963506C6174666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C';
wwv_flow_imp.g_varchar2_table(420) := '616E696D6174696F6E3A21312C646576696365506978656C526174696F3A312C696E646578417869733A2268626172223D3D3D643F2279223A2278222C6C61796F75743A7B70616464696E673A772834297D2C7363616C65733A4D2C706C7567696E733A';
wwv_flow_imp.g_varchar2_table(421) := '7B6C6567656E643A7B646973706C61793A4F2C706F736974696F6E3A652E6C6567656E64506F736974696F6E7C7C28683F227269676874223A22626F74746F6D22292C6C6162656C733A7B666F6E743A532C636F6C6F723A2223333333333333222C626F';
wwv_flow_imp.g_varchar2_table(422) := '7857696474683A772837292C626F784865696768743A772837297D7D2C7469746C653A7B646973706C61793A2121652E7469746C652C746578743A4E28652E7469746C652C74292C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C79';
wwv_flow_imp.g_varchar2_table(423) := '3A782C73697A653A7728792B32292C7765696768743A22626F6C64227D2C70616464696E673A7B626F74746F6D3A772834297D7D2C746F6F6C7469703A7B656E61626C65643A21317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C62';
wwv_flow_imp.g_varchar2_table(424) := '65666F7265447261773A66756E6374696F6E2865297B76617220743D652E6374783B742E7361766528292C742E66696C6C5374796C653D2223464646464646222C742E66696C6C5265637428302C302C652E77696474682C652E686569676874292C742E';
wwv_flow_imp.g_varchar2_table(425) := '726573746F726528297D7D2C7B69643A226E7256616C6F726573222C61667465724461746173657473447261773A66756E6374696F6E2874297B696628652E76616C756573297B76617220723D742E6374783B722E7361766528292C722E666F6E743D22';
wwv_flow_imp.g_varchar2_table(426) := '626F6C6420222B7728792D2E35292B22707820222B782C742E646174612E64617461736574732E666F72456163682866756E6374696F6E286E2C6F297B696628742E69734461746173657456697369626C65286F29297B76617220613D6E2E646174612E';
wwv_flow_imp.g_varchar2_table(427) := '7265647563652866756E6374696F6E28652C74297B72657475726E20652B28747C7C30297D2C30293B742E676574446174617365744D657461286F292E646174612E666F72456163682866756E6374696F6E28742C6F297B766172206C3D6E2E64617461';
wwv_flow_imp.g_varchar2_table(428) := '5B6F5D3B6966286E756C6C213D6C297B76617220693D22706374223D3D3D652E76616C7565733F7028613F3130302A6C2F613A302C226E756D3A3122292B2225223A54286C293B69662868297B76617220733D742E746F6F6C746970506F736974696F6E';
wwv_flow_imp.g_varchar2_table(429) := '28293B722E66696C6C5374796C653D2223464646464646222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D226D6964646C65222C722E66696C6C5465787428692C732E782C732E79297D656C736522686261';
wwv_flow_imp.g_varchar2_table(430) := '72223D3D3D643F28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D226C656674222C722E74657874426173656C696E653D226D6964646C65222C722E66696C6C5465787428692C742E782B7728312E35292C742E79';
wwv_flow_imp.g_varchar2_table(431) := '29293A28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D22626F74746F6D222C722E66696C6C5465787428692C742E782C742E792D7728312E35292929';
wwv_flow_imp.g_varchar2_table(432) := '7D7D297D7D292C722E726573746F726528297D7D7D5D7D292C493D622E746F4461746155524C2822696D6167652F706E6722293B6A2E64657374726F7928293B766172204C3D757428492C622E77696474682C622E686569676874293B72657475726E20';
wwv_flow_imp.g_varchar2_table(433) := '4C2E776D6D3D6D2C4C2E686D6D3D762C4C7D66756E6374696F6E20787428652C74297B76617220723D652E77617465726D61726B3B69662821727C7C226F626A656374223D3D747970656F6620722626215028722E7768656E2C742C742E646F63292972';
wwv_flow_imp.g_varchar2_table(434) := '657475726E206E756C6C3B22737472696E67223D3D747970656F662072262628723D7B746578743A727D293B766172206E3D4E28722E746578742C742C742E646F63293B72657475726E206E3F7B746578743A6E2C636F6C6F723A722E636F6C6F727C7C';
wwv_flow_imp.g_varchar2_table(435) := '2223433030303030222C6F7061636974793A766F69642030213D3D722E6F7061636974793F722E6F7061636974793A2E31322C616E676C653A766F69642030213D3D722E616E676C653F722E616E676C653A34352C73697A653A722E73697A657D3A6E75';
wwv_flow_imp.g_varchar2_table(436) := '6C6C7D66756E6374696F6E20537428652C742C722C6E297B696628652E73697A652972657475726E20652E73697A653B766172206F3D652E616E676C65253138303D3D303F2E382A723A2E362A4D6174682E7371727428722A722B6E2A6E293B72657475';
wwv_flow_imp.g_varchar2_table(437) := '726E204D6174682E6D61782832302C4D6174682E6D696E283136302C3130302A6F2F7429297D66756E6374696F6E20457428652C742C722C6E297B766172206F2C6C3D77696E646F772E6A737064662C693D722E782B2E362C733D722E792B2E362C753D';
wwv_flow_imp.g_varchar2_table(438) := '722E77696474682D312E322C633D722E6865696768742D312E322C663D61286665292C643D61286465293B69662822636865636B626F78223D3D3D742E696E707574297B76617220683D4D6174682E6D696E28632C342E35293B732B3D28632D68292F32';
wwv_flow_imp.g_varchar2_table(439) := '2C753D682C633D687D652E73657444726177436F6C6F7228645B305D2C645B315D2C645B325D292C652E73657446696C6C436F6C6F7228665B305D2C665B315D2C665B325D292C652E7365744C696E655769647468282E32292C652E7265637428692C73';
wwv_flow_imp.g_varchar2_table(440) := '2C752C632C22464422292C652E73657444726177436F6C6F7228302C302C30292C22636865636B626F78223D3D3D742E696E7075743F28286F3D6E6577206C2E4163726F466F726D436865636B426F78292E617070656172616E636553746174653D742E';
wwv_flow_imp.g_varchar2_table(441) := '636865636B65643F224F6E223A224F6666222C6F2E76616C75653D742E636865636B65643F224F6E223A224F666622293A226C697374223D3D3D742E696E7075743F28286F3D6E6577206C2E4163726F466F726D436F6D626F426F78292E7365744F7074';
wwv_flow_imp.g_varchar2_table(442) := '696F6E7328742E6F7074696F6E73292C6F2E656469743D21312C742E76616C75652626286F2E76616C75653D742E76616C756529293A28286F3D6E6577206C2E4163726F466F726D546578744669656C64292E6D756C74696C696E653D226D756C74696C';
wwv_flow_imp.g_varchar2_table(443) := '696E65223D3D3D742E696E7075742C742E6D61784C656E6774682626286F2E6D61784C656E6774683D742E6D61784C656E677468292C742E76616C75652626286F2E76616C75653D742E76616C756529292C6F2E6669656C644E616D653D742E6E616D65';
wwv_flow_imp.g_varchar2_table(444) := '2C6F2E526563743D5B692C732C752C635D2C22636865636B626F7822213D3D742E696E7075742626286F2E666F6E7453697A653D6E2C652E5F5F6E72466F726D53697A657C7C28652E5F5F6E72466F726D53697A653D6E29292C742E726561644F6E6C79';
wwv_flow_imp.g_varchar2_table(445) := '2626286F2E726561644F6E6C793D2130292C652E6164644669656C64286F297D66756E6374696F6E20547428652C742C72297B766172206E3D652E706167657C7C7B7D2C6F3D4B652865292C6C3D6F2E666F6E7453697A652C693D6E65772077696E646F';
wwv_flow_imp.g_varchar2_table(446) := '772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572222C636F6D70726573733A21796528';
wwv_flow_imp.g_varchar2_table(447) := '65297D292C733D692E696E7465726E616C2E7061676553697A652E676574576964746828292C753D692E696E7465726E616C2E7061676553697A652E67657448656967687428292C633D6E2E6D617267696E7C7C382C663D61286F2E7072696D61727929';
wwv_flow_imp.g_varchar2_table(448) := '2C643D61286F2E6865616454657874292C683D61286F2E7A65627261292C703D61286F2E746F74616C73292C673D632C6D3D21302C763D632C623D633B66756E6374696F6E207728297B72657475726E20692E6C6173744175746F5461626C653F692E6C';
wwv_flow_imp.g_varchar2_table(449) := '6173744175746F5461626C652E66696E616C593A677D66756E6374696F6E20792865297B673D7728292B28657C7C32297D66756E6374696F6E207828652C742C722C6E297B766172206F3D766F69642030213D3D652E783F652E783A227269676874223D';
wwv_flow_imp.g_varchar2_table(450) := '3D3D652E616C69676E3F732D622D743A2263656E746572223D3D3D652E616C69676E3F762B28732D762D622D74292F323A763B766F696420303D3D3D652E793F2828673D4D6174682E6D617828672C77282929292B723E752D632D3130262628692E6164';
wwv_flow_imp.g_varchar2_table(451) := '645061676528292C673D63292C6E286F2C67292C672B3D722B28766F69642030213D3D652E6761703F652E6761703A33292C692E6C6173744175746F5461626C653D7B66696E616C593A677D293A6E286F2C652E79297D76617220533D5B5D3B742E666F';
wwv_flow_imp.g_varchar2_table(452) := '72456163682866756E6374696F6E28452C54297B76617220433D742E6C656E6774683E313F225F222B28542B31293A22223B6D7C7C692E6164645061676528292C6D3D21312C673D632C692E6C6173744175746F5461626C653D6E756C6C3B7661722041';
wwv_flow_imp.g_varchar2_table(453) := '3D7B6374783A452C66726F6D3A692E696E7465726E616C2E6765744E756D6265724F66506167657328297D3B532E707573682841292C486528652C22706466222C45292E666F72456163682866756E6374696F6E2074286D297B76617220533D6D2E7479';
wwv_flow_imp.g_varchar2_table(454) := '70653B69662822686561646572223D3D3D53297B76617220543D5765286D2C6F292C413D6D2E66696C6C3F6128542E66696C6C293A662C7A3D6D2E636F6C6F723F6128542E636F6C6F72293A642C4D3D4D6174682E6D61782831302E352C332E352B2E33';
wwv_flow_imp.g_varchar2_table(455) := '3532382A542E73697A65292C463D4D2B4D6174682E6D617828362C312E352B2E333532382A542E73756253697A652A312E31292C4C3D4D6174682E6D6178284E756D626572286D2E686569676874297C7C302C6D2E7375627469746C653F4D6174682E6D';
wwv_flow_imp.g_varchar2_table(456) := '61782832302C462B332E35293A4D6174682E6D61782831362C4D2B352E3529293B72657475726E20692E73657446696C6C436F6C6F7228415B305D2C415B315D2C415B325D292C692E7265637428302C302C732C4C2C224622292C692E73657454657874';
wwv_flow_imp.g_varchar2_table(457) := '436F6C6F72287A5B305D2C7A5B315D2C7A5B325D292C692E736574466F6E7428542E666F6E745B305D2C22626F6C6422292C692E736574466F6E7453697A6528542E73697A65292C692E74657874284E286D2E7469746C652C45292C632C4D2C7B6D6178';
wwv_flow_imp.g_varchar2_table(458) := '57696474683A2E372A737D292C692E736574466F6E7428542E666F6E745B305D2C226E6F726D616C22292C692E736574466F6E7453697A6528542E726967687453697A65292C6D2E72696768742626692E74657874284E286D2E72696768742C45292C73';
wwv_flow_imp.g_varchar2_table(459) := '2D632C4D2C7B616C69676E3A227269676874227D292C6D2E7375627469746C65262628692E736574466F6E7453697A6528542E73756253697A65292C692E74657874284E286D2E7375627469746C652C45292C632C4629292C692E736574466F6E742822';
wwv_flow_imp.g_varchar2_table(460) := '68656C766574696361222C226E6F726D616C22292C692E73657454657874436F6C6F7228302C302C30292C673D4C2B342C766F696428692E6C6173744175746F5461626C653D6E756C6C297D69662822746578746F223D3D3D53297B76617220473D766F';
wwv_flow_imp.g_varchar2_table(461) := '69642030213D3D6D2E792C573D672C243D692E6C6173744175746F5461626C652C593D6D2E73697A657C7C31302C713D2E333532382A592A286D2E6C696E654865696768747C7C312E3335292C583D28766F69642030213D3D6D2E783F6D2E783A76292B';
wwv_flow_imp.g_varchar2_table(462) := '286D2E696E64656E747C7C30292C5A3D6D2E77696474687C7C732D622D582C4A3D6D2E616C69676E7C7C226C656674222C513D61286D2E636F6C6F727C7C222330303030303022292C65653D66756E6374696F6E2865297B72657475726E28652E627C7C';
wwv_flow_imp.g_varchar2_table(463) := '6D2E626F6C6429262628652E697C7C6D2E6974616C6963293F22626F6C646974616C6963223A652E627C7C6D2E626F6C643F22626F6C64223A652E697C7C6D2E6974616C69633F226974616C6963223A226E6F726D616C227D2C74653D6D2E666F6E747C';
wwv_flow_imp.g_varchar2_table(464) := '7C652E706167652626652E706167652E666F6E747C7C2268656C766574696361223B72657475726E20692E736574466F6E7453697A652859292C692E73657454657874436F6C6F7228515B305D2C515B315D2C515B325D292C673D473F6D2E793A4D6174';
wwv_flow_imp.g_varchar2_table(465) := '682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292C44286D2C45292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B5228652C7B666F6E743A74652C63';
wwv_flow_imp.g_varchar2_table(466) := '6F6C6F723A6D2E636F6C6F727D292E666F72456163682866756E6374696F6E2865297B652E742E73706C6974282F28202B292F292E666F72456163682866756E6374696F6E2872297B2222213D3D722626742E70757368287B743A722C66616D3A495B65';
wwv_flow_imp.g_varchar2_table(467) := '2E665D5B305D2C663A65652865292C73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E633F6128652E63293A517D297D297D293B76617220723D5B5D2C6E3D5B5D2C6F3D303B666F7228742E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(468) := '6E6374696F6E2865297B76617220743D66756E6374696F6E2865297B692E736574466F6E7428652E66616D2C652E66293B666F722876617220743D302C723D652E66616D2B652E662B592C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B766172';
wwv_flow_imp.g_varchar2_table(469) := '206F3D722B652E742E636861724174286E293B766F696420303D3D3D65745B6F5D26262865745B6F5D3D692E67657454657874576964746828652E742E636861724174286E2929292C742B3D65745B6F5D7D72657475726E20747D2865293B6966282165';
wwv_flow_imp.g_varchar2_table(470) := '2E737026266F2B743E5A26266E2E6C656E677468297B666F72283B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F7D292C6E3D5B5D2C6F3D307D652E7370';
wwv_flow_imp.g_varchar2_table(471) := '2626216E2E6C656E6774687C7C28652E773D742C6E2E707573682865292C6F2B3D74297D293B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F2C6C617374';
wwv_flow_imp.g_varchar2_table(472) := '3A21307D292C652E7472696D28293F28722E666F72456163682866756E6374696F6E2865297B21472626672B713E752D632D3130262628692E6164645061676528292C673D63293B76617220743D652E77732E66696C7465722866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(473) := '297B72657475726E20652E73707D292E6C656E6774682C723D226A757374696679223D3D3D4A262621652E6C6173742626743F285A2D652E77292F743A302C6E3D227269676874223D3D3D4A3F582B5A2D652E773A2263656E746572223D3D3D4A3F582B';
wwv_flow_imp.g_varchar2_table(474) := '285A2D652E77292F323A582C6F3D672B2E37352A713B652E77732E666F72456163682866756E6374696F6E2865297B76617220743D652E772B28652E73703F723A30293B692E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C652E63';
wwv_flow_imp.g_varchar2_table(475) := '5B325D292C692E73657444726177436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C692E7365744C696E655769647468282E3031322A59292C652E73707C7C28692E736574466F6E7428652E66616D2C652E66292C692E7465787428';
wwv_flow_imp.g_varchar2_table(476) := '652E742C6E2C6F29292C652E752626692E6C696E65286E2C6F2B2E30362A592C6E2B742C6F2B2E30362A59292C652E732626692E6C696E65286E2C6F2D2E31312A592C6E2B742C6F2D2E31312A59292C6E2B3D747D292C672B3D717D292C672B3D766F69';
wwv_flow_imp.g_varchar2_table(477) := '642030213D3D6D2E7061726167726170684761703F6D2E7061726167726170684761703A2E352A71293A672B3D717D292C692E73657454657874436F6C6F7228302C302C30292C766F696428473F28673D572C692E6C6173744175746F5461626C653D24';
wwv_flow_imp.g_varchar2_table(478) := '293A692E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226C696E6561223D3D3D53297B7661722072653D61286D2E636F6C6F727C7C222330303030303022293B696628692E73657444726177436F6C6F722872655B305D2C72';
wwv_flow_imp.g_varchar2_table(479) := '655B315D2C72655B325D292C692E7365744C696E655769647468286D2E746869636B6E6573737C7C2E33292C766F69642030213D3D6D2E78312972657475726E20766F696420692E6C696E65286D2E78312C6D2E79312C766F69642030213D3D6D2E7832';
wwv_flow_imp.g_varchar2_table(480) := '3F6D2E78323A6D2E78312C766F69642030213D3D6D2E79323F6D2E79323A6D2E7931293B673D4D6174682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292B286D2E676170426566';
wwv_flow_imp.g_varchar2_table(481) := '6F72657C7C30293B7661722063653D6D2E77696474687C7C732D762D622C66653D2263656E746572223D3D3D6D2E616C69676E3F762B28732D762D622D6365292F323A227269676874223D3D3D6D2E616C69676E3F732D622D63653A763B72657475726E';
wwv_flow_imp.g_varchar2_table(482) := '20692E6C696E652866652C672C66652B63652C67292C672B3D766F69642030213D3D6D2E6761703F6D2E6761703A322C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226573706163696F223D3D3D53297265';
wwv_flow_imp.g_varchar2_table(483) := '7475726E20673D4D6174682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292B286D2E6865696768747C7C36292C766F696428692E6C6173744175746F5461626C653D7B66696E61';
wwv_flow_imp.g_varchar2_table(484) := '6C593A677D293B69662822696D6167656E22213D3D5329696628226772616669636F22213D3D532969662822636F6469676F22213D3D53297B6966282273616C746F223D3D3D532972657475726E20692E6164645061676528292C673D632C766F696428';
wwv_flow_imp.g_varchar2_table(485) := '692E6C6173744175746F5461626C653D7B66696E616C593A637D293B69662822636F6C756D6E6173223D3D3D53297B7661722064653D762C68653D623B696628212859653D5A65286D2C22706466222C452C732D762D6229292E6C656E67746829726574';
wwv_flow_imp.g_varchar2_table(486) := '75726E3B7661722070653D66756E6374696F6E2865297B763D64652B652E782C623D732D2864652B652E782B652E77297D2C67653D692C62653D302C77653D21302C79653D4D6174682E6D617828672C772829293B69662859652E666F72456163682866';
wwv_flow_imp.g_varchar2_table(487) := '756E6374696F6E2865297B693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C';
wwv_flow_imp.g_varchar2_table(488) := '226C6574746572227D292C70652865292C673D632C692E6C6173744175746F5461626C653D6E756C6C2C652E736563732E666F72456163682874292C692E696E7465726E616C2E6765744E756D6265724F66506167657328293E3126262877653D213129';
wwv_flow_imp.g_varchar2_table(489) := '2C62653D4D6174682E6D61782862652C4D6174682E6D617828672C772829292D63297D292C763D64652C623D68652C673D79652C28693D6765292E6C6173744175746F5461626C653D7B66696E616C593A79657D2C2177652972657475726E20766F6964';
wwv_flow_imp.g_varchar2_table(490) := '2059652E666F72456163682866756E6374696F6E2865297B652E736563732E666F72456163682874297D293B672B62653E752D632D3130262628692E6164645061676528292C673D63293B7661722078653D672C53653D673B72657475726E2059652E66';
wwv_flow_imp.g_varchar2_table(491) := '6F72456163682866756E6374696F6E2865297B70652865292C673D78652C692E6C6173744175746F5461626C653D7B66696E616C593A78657D2C652E736563732E666F72456163682874292C53653D4D6174682E6D61782853652C672C772829297D292C';
wwv_flow_imp.g_varchar2_table(492) := '763D64652C623D68652C673D53652B28766F69642030213D3D6D2E6761703F6D2E6761703A31292C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D69662822677275706F223D3D3D53297B7661722045653D452C5465';
wwv_flow_imp.g_varchar2_table(493) := '3D432C43653D762C41653D622C6A653D766F69642030213D3D6D2E70616464696E673F4E756D626572286D2E70616464696E67293A6D2E626F726465727C7C6D2E66696C6C3F333A302C4C653D66756E6374696F6E2865297B76617220722C6E3D4D6174';
wwv_flow_imp.g_varchar2_table(494) := '682E6D617828672C772829293B763D43652C623D41652C673D6E2C6D2E7469746C65262628723D4E286D2E7469746C652C45292C692E6175746F5461626C65287B7374617274593A4D6174682E6D617828672C772829292C7468656D653A22706C61696E';
wwv_flow_imp.g_varchar2_table(495) := '222C6D617267696E3A7B6C6566743A762C72696768743A627D2C626F64793A5B5B725D5D2C7374796C65733A7B666F6E7453697A653A6D2E7469746C6553697A657C7C6C2B322C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A';
wwv_flow_imp.g_varchar2_table(496) := '312E362C66696C6C436F6C6F723A61286D2E7469746C6546696C6C7C7C6F2E7072696D617279292C74657874436F6C6F723A61286D2E7469746C65436F6C6F727C7C6F2E6865616454657874297D7D292C673D772829292C673D4D6174682E6D61782867';
wwv_flow_imp.g_varchar2_table(497) := '2C772829292B6A652C692E6C6173744175746F5461626C653D7B66696E616C593A677D2C763D43652B6A652C623D41652B6A652C652E666F72456163682874293B76617220733D4D6174682E6D617828672C772829292B6A653B72657475726E20763D43';
wwv_flow_imp.g_varchar2_table(498) := '652C623D41652C732D6E7D3B72657475726E205865286D2C45292E666F72456163682866756E6374696F6E2865297B453D652E6374782C433D54652B652E7375663B76617220743D7165286D2C22706466222C45293B696628742E6C656E6774687C7C6D';
wwv_flow_imp.g_varchar2_table(499) := '2E7469746C65297B76617220723D692C6F3D4D6174682E6D617828672C772829293B693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E';
wwv_flow_imp.g_varchar2_table(500) := '69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572227D292C673D632C692E6C6173744175746F5461626C653D6E756C6C3B766172206C3D4C652874292C663D313D3D3D692E696E7465726E616C2E6765744E756D6265724F6650';
wwv_flow_imp.g_varchar2_table(501) := '6167657328293B673D6F2C28693D72292E6C6173744175746F5461626C653D7B66696E616C593A6F7D2C6626262131213D3D6D2E6B656570546F6765746865722626672B6C3E752D632D3130262628692E6164645061676528292C673D632C692E6C6173';
wwv_flow_imp.g_varchar2_table(502) := '744175746F5461626C653D7B66696E616C593A677D293B76617220643D672C683D692E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265722C703D732D43652D41653B6966286626266D2E66696C6C297B';
wwv_flow_imp.g_varchar2_table(503) := '76617220763D61286D2E66696C6C293B692E73657446696C6C436F6C6F7228765B305D2C765B315D2C765B325D292C692E726563742843652C642C702C6C2C224622297D76617220623D4C652874293B6966286D2E626F726465722626692E696E746572';
wwv_flow_imp.g_varchar2_table(504) := '6E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265723D3D3D68297B76617220793D61286D2E626F72646572436F6C6F727C7C7A65293B692E73657444726177436F6C6F7228795B305D2C795B315D2C795B325D292C69';
wwv_flow_imp.g_varchar2_table(505) := '2E7365744C696E655769647468286D2E626F7264657257696474687C7C2E33292C692E726563742843652C642C702C622C225322292C692E73657444726177436F6C6F7228302C302C30297D673D642B622C692E696E7465726E616C2E67657443757272';
wwv_flow_imp.g_varchar2_table(506) := '656E7450616765496E666F28292E706167654E756D626572213D3D68262628673D4D6174682E6D617828672C77282929292C672B3D766F69642030213D3D6D2E6761703F4E756D626572286D2E676170293A332C692E6C6173744175746F5461626C653D';
wwv_flow_imp.g_varchar2_table(507) := '7B66696E616C593A677D7D7D292C453D45652C433D54652C763D43652C766F696428623D4165297D696628226669636861223D3D3D53297B7661722055653D6B286D2C45295B305D7C7C7B7D2C48653D6D2E636F6C756D6E737C7C332C56653D5B5D2C59';
wwv_flow_imp.g_varchar2_table(508) := '653D7B7D3B466528286D2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5028652E7768656E2C452C5565297D292C4865292E666F72456163682866756E6374696F6E2865297B7661';
wwv_flow_imp.g_varchar2_table(509) := '7220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E656D70747929742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B6C696E655769';
wwv_flow_imp.g_varchar2_table(510) := '6474683A302C66696C6C436F6C6F723A21317D7D293B656C73657B766172206E3D496528722C6D292C6F3D4F6528722C452C5565292C6C3D756528722C452C5565293B696628226C65667422213D3D6E2E706F73297B76617220693D7B666F6E74537479';
wwv_flow_imp.g_varchar2_table(511) := '6C653A6F26266F2E626F6C643F22626F6C64223A226E6F726D616C222C66696C6C436F6C6F723A2128216F7C7C216F2E66696C6C29262661286F2E66696C6C292C74657874436F6C6F723A61286F26266F2E636F6C6F727C7C6D2E76616C7565436F6C6F';
wwv_flow_imp.g_varchar2_table(512) := '727C7C222330303030303022292C68616C69676E3A6F26266F2E616C69676E7C7C226C656674227D2C733D7B636F6E74656E743A6C2C636F6C5370616E3A322A652E7370616E2C7374796C65733A697D3B72657475726E22746F70223D3D3D6E2E706F73';
wwv_flow_imp.g_varchar2_table(513) := '262628732E5F6E724C61623D7B746578743A5265284E28722E6C6162656C2C452C5565292C6E292C6C623A6E2C616C69676E3A6E2E616C69676E7C7C692E68616C69676E7D292C766F696420742E707573682873297D6966286F7C7C652E7370616E3E31';
wwv_flow_imp.g_varchar2_table(514) := '297B76617220753D7B7D3B6F26266F2E616C69676E262628752E68616C69676E3D6F2E616C69676E292C6F26266F2E626F6C64262628752E666F6E745374796C653D22626F6C6422292C6F26266F2E636F6C6F72262628752E74657874436F6C6F723D61';
wwv_flow_imp.g_varchar2_table(515) := '286F2E636F6C6F7229292C6F26266F2E66696C6C262628752E66696C6C436F6C6F723D61286F2E66696C6C29292C6C3D7B636F6E74656E743A6C2C7374796C65733A757D2C652E7370616E3E312626286C2E636F6C5370616E3D322A652E7370616E2D31';
wwv_flow_imp.g_varchar2_table(516) := '297D76617220633D4E28722E6C6162656C2C452C5565293B742E70757368286E2E7374796C65643F7B636F6E74656E743A526528632C6E292C7374796C65733A4765286E297D3A632C6C297D7D293B666F722876617220723D322A6B652865293B723C32';
wwv_flow_imp.g_varchar2_table(517) := '2A48653B722B2B29742E70757368282222293B56652E707573682874297D293B766172204A653D302C4B653D4465286D293B6966285065286D2E6669656C6473297C7C4B65297B666F72287661722051653D302C74743D303B74743C48653B74742B2B29';
wwv_flow_imp.g_varchar2_table(518) := '51652B3D4D65286D2C7474293B4A653D4D6174682E6D61782831302C28732D762D622D5165292F4865297D666F72287661722072743D303B72743C322A48653B72742B3D322959655B72745D3D7B666F6E745374796C653A22626F6C64222C63656C6C57';
wwv_flow_imp.g_varchar2_table(519) := '696474683A4D65286D2C72742F32297D2C4A6526262859655B72742B315D3D7B63656C6C57696474683A4A657D292C6D2E6C6162656C46696C6C26262859655B72745D2E66696C6C436F6C6F723D61286D2E6C6162656C46696C6C29292C6D2E6C616265';
wwv_flow_imp.g_varchar2_table(520) := '6C436F6C6F7226262859655B72745D2E74657874436F6C6F723D61286D2E6C6162656C436F6C6F7229292C6D2E76616C7565436F6C6F7226262859655B72742B315D3D59655B72742B315D7C7C7B7D2C59655B72742B315D2E74657874436F6C6F723D61';
wwv_flow_imp.g_varchar2_table(521) := '286D2E76616C7565436F6C6F7229293B766172206E743D7B666F6E7453697A653A6D2E73697A657C7C382E352C63656C6C50616464696E673A2E397D3B6D2E677269642626286E742E63656C6C50616464696E673D312E362C6E742E76616C69676E3D22';
wwv_flow_imp.g_varchar2_table(522) := '6D6964646C65222C6E742E6C696E6557696474683D2E31352C6E742E6C696E65436F6C6F723D61286D2E626F72646572436F6C6F727C7C7A6529293B766172206F743D7B7374617274593A672C626F64793A56652C7468656D653A22706C61696E222C6D';
wwv_flow_imp.g_varchar2_table(523) := '617267696E3A7B6C6566743A762C72696768743A627D2C7374796C65733A6E742C636F6C756D6E5374796C65733A59657D3B6966284B65297B7661722061743D6E742E666F6E7453697A652C73743D6E742E63656C6C50616464696E673B6F742E646964';
wwv_flow_imp.g_varchar2_table(524) := '506172736543656C6C3D66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B74262628652E63656C6C2E7374796C65732E63656C6C';
wwv_flow_imp.g_varchar2_table(525) := '50616464696E673D7B746F703A73742B426528742E6C622C6174292C72696768743A73742C626F74746F6D3A73742C6C6566743A73747D297D2C6F742E6469644472617743656C6C3D66756E6374696F6E2865297B76617220743D22626F6479223D3D3D';
wwv_flow_imp.g_varchar2_table(526) := '652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B7426265F6528692C652E63656C6C2C742C61742C7374297D7D72657475726E20692E6175746F5461626C65286F74292C766F696420792832297D69';
wwv_flow_imp.g_varchar2_table(527) := '6628227461726A65746173223D3D3D53297B7661722075743D2465286D2C452C6F293B6966282175742E6974656D732E6C656E6774682972657475726E3B7661722063743D28732D762D622D75742E636172644761702A2875742E6E2D3129292F75742E';
wwv_flow_imp.g_varchar2_table(528) := '6E2C66743D2E333532382A75742E6C6162656C53697A652C64743D2E333532382A75742E73697A652C68743D612875742E66696C6C292C70743D75742E616363656E743F612875742E616363656E74293A6E756C6C2C67743D70743F343A332C6D743D63';
wwv_flow_imp.g_varchar2_table(529) := '742D67742D323B673D4D6174682E6D617828672C772829293B666F72287661722062743D303B62743C75742E6974656D732E6C656E6774683B62742B3D75742E6E297B7661722077743D75742E6974656D732E736C6963652862742C62742B75742E6E29';
wwv_flow_imp.g_varchar2_table(530) := '3B692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E736574466F6E7453697A652875742E73697A65293B7661722078743D77742E6D61702866756E6374696F6E2865297B72657475726E20692E73706C697454657874546F';
wwv_flow_imp.g_varchar2_table(531) := '53697A6528537472696E6728652E76616C7565292C6D74297D292C53743D4D6174682E6D61782E6170706C79286E756C6C2C78742E6D61702866756E6374696F6E2865297B72657475726E204D6174682E6D617828312C652E6C656E677468297D29292C';
wwv_flow_imp.g_varchar2_table(532) := '54743D312E322A66742B312E352B312E322A64742A53742C43743D4D6174682E6D6178286D2E6865696768747C7C302C332B54742B33293B672B43743E752D632D3130262628692E6164645061676528292C673D63292C77742E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(533) := '6E6374696F6E28652C74297B76617220723D762B742A2863742B75742E63617264476170292C6E3D612875742E6C6162656C436F6C6F72292C6F3D6128652E636F6C6F727C7C75742E76616C7565436F6C6F72293B692E73657446696C6C436F6C6F7228';
wwv_flow_imp.g_varchar2_table(534) := '68745B305D2C68745B315D2C68745B325D292C692E7265637428722C672C63742C43742C224622292C7074262628692E73657446696C6C436F6C6F722870745B305D2C70745B315D2C70745B325D292C692E7265637428722C672C312E322C43742C2246';
wwv_flow_imp.g_varchar2_table(535) := '2229293B766172206C3D672B2843742D5474292F322B66743B692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E736574466F6E7453697A652875742E6C6162656C53697A65292C692E73657454657874436F6C6F7228';
wwv_flow_imp.g_varchar2_table(536) := '6E5B305D2C6E5B315D2C6E5B325D292C692E7465787428692E73706C697454657874546F53697A6528537472696E6728652E6C6162656C292C6D74295B305D7C7C22222C722B67742C6C292C692E736574466F6E74282268656C766574696361222C2262';
wwv_flow_imp.g_varchar2_table(537) := '6F6C6422292C692E736574466F6E7453697A652875742E73697A65292C692E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C78745B745D2E666F72456163682866756E6374696F6E28652C74297B692E7465787428652C722B67';
wwv_flow_imp.g_varchar2_table(538) := '742C6C2B312E352B312E30352A64742B742A64742A312E32297D297D292C672B3D43742B2862742B75742E6E3C75742E6974656D732E6C656E6774683F75742E636172644761703A30297D72657475726E20692E736574466F6E74282268656C76657469';
wwv_flow_imp.g_varchar2_table(539) := '6361222C226E6F726D616C22292C692E73657454657874436F6C6F7228302C302C30292C672B3D766F69642030213D3D6D2E6761703F6D2E6761703A332C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D6966282266';
wwv_flow_imp.g_varchar2_table(540) := '6F726D756C6172696F223D3D3D53297B692E5F5F6E72466F726D7C7C28692E5F5F6E72466F726D3D6D652829293B7661722041743D7665286D2C452C43292C7A743D6D2E636F6C756D6E737C7C322C4D743D5B5D2C4E743D7B7D2C46743D7B7D2C50743D';
wwv_flow_imp.g_varchar2_table(541) := '6D2E73697A657C7C382E353B69662846652841742C7A74292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E656D70747929742E70';
wwv_flow_imp.g_varchar2_table(542) := '757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E7D293B656C73657B696628692E5F5F6E72466F726D28722E6E616D65292C226C65667422213D3D722E6C61622E706F73297B4E745B4D742E6C656E6774682B223A222B32';
wwv_flow_imp.g_varchar2_table(543) := '2A652E636F6C5D3D723B766172206E3D7B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B666F6E745374796C653A226E6F726D616C227D7D3B72657475726E22746F70223D3D3D722E6C61622E706F73262628';
wwv_flow_imp.g_varchar2_table(544) := '6E2E5F6E724C61623D7B746578743A526528722E6C6162656C2C722E6C6162292C6C623A722E6C61622C616C69676E3A722E6C61622E616C69676E7C7C226C656674227D292C766F696420742E70757368286E297D4E745B4D742E6C656E6774682B223A';
wwv_flow_imp.g_varchar2_table(545) := '222B28322A652E636F6C2B31295D3D722C742E7075736828722E6C61622E7374796C65643F7B636F6E74656E743A526528722E6C6162656C2C722E6C6162292C7374796C65733A476528722E6C6162297D3A722E6C6162656C2C652E7370616E3E313F7B';
wwv_flow_imp.g_varchar2_table(546) := '636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2D317D3A2222297D7D293B666F722876617220723D322A6B652865293B723C322A7A743B722B2B29742E70757368282222293B4D742E707573682874297D292C214D742E6C656E6774';
wwv_flow_imp.g_varchar2_table(547) := '682972657475726E3B666F7228766172206B743D5065286D2E6669656C6473297C7C4465286D293F4D6174682E6D61782831302C28732D762D622D286D2E6C6162656C57696474687C7C3332292A7A74292F7A74293A302C4F743D303B4F743C322A7A74';
wwv_flow_imp.g_varchar2_table(548) := '3B4F742B3D322946745B4F745D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A6D2E6C6162656C57696474687C7C33327D2C6B7426262846745B4F742B315D3D7B63656C6C57696474683A6B747D293B766172206A743D2E3335';
wwv_flow_imp.g_varchar2_table(549) := '32382A50742A312E333B72657475726E20692E6175746F5461626C65287B7374617274593A672C626F64793A4D742C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C726F7750616765427265616B3A2261';
wwv_flow_imp.g_varchar2_table(550) := '766F6964222C7374796C65733A7B666F6E7453697A653A50742C63656C6C50616464696E673A312E322C76616C69676E3A226D6964646C65227D2C636F6C756D6E5374796C65733A46742C646964506172736543656C6C3A66756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(551) := '76617220743D22626F6479223D3D3D652E73656374696F6E26264E745B652E726F772E696E6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C';
wwv_flow_imp.g_varchar2_table(552) := '61622C6E3D723F426528722E6C622C5074293A303B72262628652E63656C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A312E322B6E2C72696768743A312E322C626F74746F6D3A312E322C6C6566743A312E327D292C652E63656C6C';
wwv_flow_imp.g_varchar2_table(553) := '2E7374796C65732E6D696E43656C6C4865696768743D742E6C696E65732A6A742B332B6E7D7D2C6469644472617743656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E26264E745B652E726F772E696E';
wwv_flow_imp.g_varchar2_table(554) := '6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B69662872297B766172206E3D426528722E6C622C5074292B312E323B5F6528692C65';
wwv_flow_imp.g_varchar2_table(555) := '2E63656C6C2C722C50742C312E32292C457428692C742C7B783A652E63656C6C2E782C793A652E63656C6C2E792B6E2D2E362C77696474683A652E63656C6C2E77696474682C6865696768743A652E63656C6C2E6865696768742D6E2B2E367D2C507429';
wwv_flow_imp.g_varchar2_table(556) := '7D656C736520457428692C742C652E63656C6C2C5074297D7D7D292C766F696420792832297D69662822616C6572746122213D3D53297B696628227461626C61223D3D3D53297B7661722049743D6B286D2C45293B6966282149742E6C656E6774682626';
wwv_flow_imp.g_varchar2_table(557) := '2131213D3D6D2E68696465456D7074792626216D2E656D707479546578742972657475726E3B766172204C743D55286D2C452C4974292C52743D5B5D2C44743D7B7D3B6966286D2E7469746C65262652742E70757368285B7B636F6E74656E743A4E286D';
wwv_flow_imp.g_varchar2_table(558) := '2E7469746C652C45292C636F6C5370616E3A4C742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E7453697A653A6C2B317D7D5D292C6D2E67726F757073297B7661722055743D5B5D2C42743D5B5D2C47743D7B68616C';
wwv_flow_imp.g_varchar2_table(559) := '69676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B42286D2C4C74292E666F72456163682866756E6374696F6E2865297B666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B29652E676170';
wwv_flow_imp.g_varchar2_table(560) := '3F55742E70757368287B636F6E74656E743A4C745B745D2E6C6162656C2C726F775370616E3A322C7374796C65733A7B68616C69676E3A4E65284C745B745D2C6D292C76616C69676E3A226D6964646C65227D7D293A42742E70757368287B636F6E7465';
wwv_flow_imp.g_varchar2_table(561) := '6E743A4C745B745D2E6C6162656C2C7374796C65733A7B68616C69676E3A4E65284C745B745D2C6D297D7D293B652E6761707C7C55742E70757368287B636F6E74656E743A652E6C6162656C2C636F6C5370616E3A652E636F6C732C7374796C65733A47';
wwv_flow_imp.g_varchar2_table(562) := '747D297D292C52742E707573682855742C4274297D656C73652052742E70757368284C742E6D61702866756E6374696F6E2865297B72657475726E7B636F6E74656E743A652E6C6162656C2C7374796C65733A7B68616C69676E3A4E6528652C6D297D7D';
wwv_flow_imp.g_varchar2_table(563) := '7D29293B4C742E666F72456163682866756E6374696F6E28652C74297B44745B745D3D7B68616C69676E3A652E616C69676E7D2C652E636F6C6F7226262844745B745D2E74657874436F6C6F723D6128652E636F6C6F7229292C652E626F6C6426262844';
wwv_flow_imp.g_varchar2_table(564) := '745B745D2E666F6E745374796C653D22626F6C6422292C652E776964746826262844745B745D2E63656C6C57696474683D652E7769647468297D293B766172205F743D6965286D2C4974292C57743D6C65286D292C24743D61286F2E67726F7570292C48';
wwv_flow_imp.g_varchar2_table(565) := '743D5B5D2C56743D5B5D2C59743D7B7D3B56653D49742E6C656E6774683F5B5D3A5B5B7B636F6E74656E743A4E286D2E656D707479546578742C45292C636F6C5370616E3A4C742E6C656E6774682C7374796C65733A7B68616C69676E3A226C65667422';
wwv_flow_imp.g_varchar2_table(566) := '2C666F6E745374796C653A226974616C6963227D7D5D5D3B49742E6C656E6774682626285F742E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B2972657475726E2056652E70757368285B7B636F6E74656E743A';
wwv_flow_imp.g_varchar2_table(567) := '7365286D2C652C45292C636F6C5370616E3A4C742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A24747D7D5D292C48742E707573682865292C766F696420';
wwv_flow_imp.g_varchar2_table(568) := '56742E70757368286E756C6C293B6966282273756222213D3D652E6B297B76617220743D6E756C6C3B56652E70757368284C742E6D61702866756E6374696F6E28722C6E297B69662821722E63656C6C2972657475726E205F28722C652E722C45293B76';
wwv_flow_imp.g_varchar2_table(569) := '617220613D5628722C652E722C452C6F293B72657475726E206126262828743D747C7C7B7D295B6E5D3D612C59745B6E5D3D4D6174682E6D61782859745B6E5D7C7C302C612E7729292C22227D29292C48742E707573682865292C56742E707573682874';
wwv_flow_imp.g_varchar2_table(570) := '297D656C7365206165286E65284C742C57742C652E726F77732C7365286D2C652C4529292C4C742E6C656E677468292E666F72456163682866756E6374696F6E2874297B56652E707573682874292C48742E707573682865292C56742E70757368286E75';
wwv_flow_imp.g_varchar2_table(571) := '6C6C297D297D292C4F626A6563742E6B657973285974292E666F72456163682866756E6374696F6E2865297B44745B655D2E63656C6C57696474683D4D6174682E6D6178284C745B655D2E77696474687C7C302C59745B655D2B33297D29293B76617220';
wwv_flow_imp.g_varchar2_table(572) := '71743D6E756C6C2C58743D4B286D2E746F74616C73293B58742E6C656E677468262649742E6C656E67746826262871743D6165286E65284C742C58742C49742C6F65286D2C452C497429292C4C742E6C656E67746829293B766172205A743D7B666F6E74';
wwv_flow_imp.g_varchar2_table(573) := '53697A653A6D2E73697A657C7C6C2C63656C6C50616464696E673A6D2E677269643F312E323A2E387D2C4A743D48286D2C4C74293B4A742626285A742E76616C69676E3D4A74292C4C742E666F72456163682866756E6374696F6E28652C74297B652E76';
wwv_flow_imp.g_varchar2_table(574) := '616C69676E26262844745B745D2E76616C69676E3D652E76616C69676E297D292C6D2E677269642626285A742E6C696E6557696474683D2E31352C5A742E6C696E65436F6C6F723D61286D2E626F72646572436F6C6F727C7C7A6529292C692E6175746F';
wwv_flow_imp.g_varchar2_table(575) := '5461626C65287B7374617274593A672C6D617267696E3A7B6C6566743A762C72696768743A627D2C686561643A52742C626F64793A56652C666F6F743A71747C7C766F696420302C73686F77486561643A21313D3D3D6D2E726570656174486561646572';
wwv_flow_imp.g_varchar2_table(576) := '3F22666972737450616765223A22657665727950616765222C73686F77466F6F743A226C61737450616765222C7374796C65733A5A742C686561645374796C65733A7B66696C6C436F6C6F723A662C74657874436F6C6F723A642C68616C69676E3A2263';
wwv_flow_imp.g_varchar2_table(577) := '656E746572222C666F6E7453697A653A6D2E73697A657C7C6C7D2C666F6F745374796C65733A7B66696C6C436F6C6F723A702C74657874436F6C6F723A6D2E746F74616C73436F6C6F723F61286D2E746F74616C73436F6C6F72293A302C666F6E745374';
wwv_flow_imp.g_varchar2_table(578) := '796C653A22626F6C64222C68616C69676E3A227269676874227D2C616C7465726E617465526F775374796C65733A6D2E627265616B42793F7B7D3A7B66696C6C436F6C6F723A687D2C636F6C756D6E5374796C65733A44742C646964506172736543656C';
wwv_flow_imp.g_varchar2_table(579) := '6C3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F6E262649742E6C656E677468297B76617220743D48745B652E726F772E696E6465785D3B696628742626226865616422213D3D742E6B297B69662822737562223D3D';
wwv_flow_imp.g_varchar2_table(580) := '3D742E6B2972657475726E20652E63656C6C2E7374796C65732E66696C6C436F6C6F723D702C766F696428652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C6422293B766172206E3D742E722C6F3D4C745B652E636F6C756D6E2E69';
wwv_flow_imp.g_varchar2_table(581) := '6E6465785D3B6D2E627265616B4279262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D742E6925323D3D3126262131213D3D6D2E7A656272613F683A5B3235352C3235352C3235355D293B766172206C3D6A286D2E726F775374796C65';
wwv_flow_imp.g_varchar2_table(582) := '2C452C6E293B6C2626286C2E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D61286C2E66696C6C29292C6C2E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D61286C2E636F6C6F7229292C';
wwv_flow_imp.g_varchar2_table(583) := '6C2E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B76617220693D6F26266A286F2E63656C6C5374796C652C452C6E293B69262628692E66696C6C262628652E63656C6C2E7374796C65732E66696C';
wwv_flow_imp.g_varchar2_table(584) := '6C436F6C6F723D6128692E66696C6C29292C692E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D6128692E636F6C6F7229292C692E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F';
wwv_flow_imp.g_varchar2_table(585) := '6C642229293B76617220733D56745B652E726F772E696E6465785D262656745B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B73262628652E63656C6C2E7374796C65732E6D696E43656C6C4865696768743D4D6174682E6D61';
wwv_flow_imp.g_varchar2_table(586) := '7828652E63656C6C2E7374796C65732E6D696E43656C6C4865696768747C7C302C732E682B3229292C722626722E70646643656C6C2626722E70646643656C6C28652C6E2C6F2C6D2C45297D7D7D2C6469644472617743656C6C3A66756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(587) := '65297B69662822626F6479223D3D3D652E73656374696F6E297B76617220743D56745B652E726F772E696E6465785D262656745B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D4C745B652E636F';
wwv_flow_imp.g_varchar2_table(588) := '6C756D6E2E696E6465785D2E616C69676E2C6E3D226C656674223D3D3D723F652E63656C6C2E782B313A227269676874223D3D3D723F652E63656C6C2E782B652E63656C6C2E77696474682D742E772D313A652E63656C6C2E782B28652E63656C6C2E77';
wwv_flow_imp.g_varchar2_table(589) := '696474682D742E77292F322C6F3D4C745B652E636F6C756D6E2E696E6465785D2E76616C69676E7C7C4A742C613D22746F70223D3D3D6F3F652E63656C6C2E792B313A22626F74746F6D223D3D3D6F3F652E63656C6C2E792B652E63656C6C2E68656967';
wwv_flow_imp.g_varchar2_table(590) := '68742D742E682D313A652E63656C6C2E792B28652E63656C6C2E6865696768742D742E68292F323B692E616464496D61676528742E696D2E646174612C226A7067223D3D3D742E696D2E6578743F224A504547223A22504E47222C6E2C612C742E772C74';
wwv_flow_imp.g_varchar2_table(591) := '2E682C766F696420302C224641535422297D7D7D7D292C79286D2E6761707C7C33297D7D656C7365206B286D2C45292E66696C7465722866756E6374696F6E2865297B72657475726E2050286D2E7768656E2C452C65297D292E736C69636528302C6D2E';
wwv_flow_imp.g_varchar2_table(592) := '656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B692E6175746F5461626C65287B7374617274593A672C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C626F64793A5B5B4E';
wwv_flow_imp.g_varchar2_table(593) := '286D2E746578742C452C65295D5D2C7374796C65733A7B666F6E7453697A653A6D2E73697A657C7C382C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A61284F286D2E636F6C6F722C452C65';
wwv_flow_imp.g_varchar2_table(594) := '297C7C222345364543463222297D7D292C792831297D297D656C73657B766172204B743D7674286D2C45293B696628214B742972657475726E3B7661722051743D4B742E6C6162656C3F2E333532382A4B742E7465787453697A652A312E343A303B7828';
wwv_flow_imp.g_varchar2_table(595) := '6D2C4B742E772C4B742E682B51742C66756E6374696F6E28652C74297B76617220723D4B742E772F4B742E636F6C732C6E3D4B742E682F4B742E726F77732C6F3D61284B742E636F6C6F72293B692E73657446696C6C436F6C6F72286F5B305D2C6F5B31';
wwv_flow_imp.g_varchar2_table(596) := '5D2C6F5B325D293B666F7228766172206C3D303B6C3C4B742E726F77733B6C2B2B29666F722876617220733D303B733C4B742E636F6C733B732B2B296966284B742E6461726B28732C6C29297B666F722876617220753D733B732B313C4B742E636F6C73';
wwv_flow_imp.g_varchar2_table(597) := '26264B742E6461726B28732B312C6C293B29732B2B3B692E7265637428652B752A722C742B6C2A6E2C28732D752B31292A722C6E2B286C3C4B742E726F77732D313F2E30323A30292C224622297D4B742E6C6162656C262628692E736574466F6E742822';
wwv_flow_imp.g_varchar2_table(598) := '636F7572696572222C226E6F726D616C22292C692E736574466F6E7453697A65284B742E7465787453697A65292C692E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C692E74657874284B742E746578742C652B4B742E772F32';
wwv_flow_imp.g_varchar2_table(599) := '2C742B4B742E682B2E333532382A4B742E7465787453697A652A312E312C7B616C69676E3A2263656E746572227D292C692E73657454657874436F6C6F7228302C302C3029297D297D656C73657B7661722065723D7974286D2C452C6F293B6966282165';
wwv_flow_imp.g_varchar2_table(600) := '722972657475726E3B78286D2C65722E776D6D2C65722E686D6D2C66756E6374696F6E28652C74297B692E616464496D6167652865722E646174612C22504E47222C652C742C65722E776D6D2C65722E686D6D2C766F696420302C224641535422297D29';
wwv_flow_imp.g_varchar2_table(601) := '7D656C73657B7661722074723D6C74286D2C45293B6966282174722972657475726E3B7661722072723D6974286D2C7472292C6E723D226A7067223D3D3D74722E6578743F224A504547223A22504E47223B78286D2C72722E772C72722E682C66756E63';
wwv_flow_imp.g_varchar2_table(602) := '74696F6E28652C74297B692E616464496D6167652874722E646174612C6E722C652C742C72722E772C72722E68297D297D7D292C412E746F3D692E696E7465726E616C2E6765744E756D6265724F66506167657328297D292C532E666F72456163682866';
wwv_flow_imp.g_varchar2_table(603) := '756E6374696F6E2874297B76617220723D787428652C742E637478293B69662872297B692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E736574466F6E7453697A6528313030293B766172206E3D537428722C692E676574';
wwv_flow_imp.g_varchar2_table(604) := '54657874576964746828722E74657874292C732C75292C6F3D722E616E676C652A4D6174682E50492F3138302C6C3D6128722E636F6C6F72293B692E736574466F6E7453697A65286E293B666F722876617220633D692E67657454657874576964746828';
wwv_flow_imp.g_varchar2_table(605) := '722E74657874292C663D2E333532382A6E2A2E372C643D732F322D632F322A4D6174682E636F73286F292B662F322A4D6174682E73696E286F292C683D752F322B632F322A4D6174682E73696E286F292B662F322A4D6174682E636F73286F292C703D74';
wwv_flow_imp.g_varchar2_table(606) := '2E66726F6D3B703C3D742E746F3B702B2B29692E736574506167652870292C692E736176654772617068696373537461746528292C692E736574475374617465286E657720692E475374617465287B6F7061636974793A722E6F7061636974797D29292C';
wwv_flow_imp.g_varchar2_table(607) := '692E73657454657874436F6C6F72286C5B305D2C6C5B315D2C6C5B325D292C692E7465787428722E746578742C642C682C7B616E676C653A722E616E676C657D292C692E726573746F72654772617068696373537461746528293B692E73657454657874';
wwv_flow_imp.g_varchar2_table(608) := '436F6C6F7228302C302C30297D7D293B76617220453D652E666F6F7465722C543D692E696E7465726E616C2E6765744E756D6265724F66506167657328292C433D745B305D7C7C7B533A7B7D2C543A7B7D7D3B69662845297B666F722876617220413D31';
wwv_flow_imp.g_varchar2_table(609) := '3B413C3D543B412B2B297B692E736574506167652841292C692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E736574466F6E7453697A6528452E73697A657C7C37293B766172207A3D61286F2E6D75746564293B692E';
wwv_flow_imp.g_varchar2_table(610) := '73657454657874436F6C6F72287A5B305D2C7A5B315D2C7A5B325D293B766172204D3D66756E6374696F6E2865297B72657475726E204E28652C43292E7265706C61636528227B504147457D222C41292E7265706C61636528227B50414745537D222C54';
wwv_flow_imp.g_varchar2_table(611) := '297D3B696628452E6C656674297B76617220463D692E73706C697454657874546F53697A65284D28452E6C656674292C2E37382A73293B692E7465787428462C632C752D342D28462E6C656E6774682D31292A28452E73697A657C7C37292A2E34297D45';
wwv_flow_imp.g_varchar2_table(612) := '2E72696768742626692E74657874284D28452E7269676874292C732D632C752D352C7B616C69676E3A227269676874227D297D692E73657454657874436F6C6F7228302C302C30297D72657475726E20652E7469746C652626692E73657450726F706572';
wwv_flow_imp.g_varchar2_table(613) := '74696573287B7469746C653A4E28652E7469746C652C43297D292C66756E6374696F6E2865297B76617220743D652E696E7465726E616C2E6163726F666F726D506C7567696E2C723D742626742E6163726F466F726D44696374696F6E617279526F6F74';
wwv_flow_imp.g_varchar2_table(614) := '3B696628722626722E4669656C64732626722E4669656C64732E6C656E677468262621722E5F5F6E72297B766172206E3D223C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F48656C7665746963';
wwv_flow_imp.g_varchar2_table(615) := '61202F456E636F64696E67202F57696E416E7369456E636F64696E67203E3E222C6F3D652E696E7465726E616C2E676574466F6E74282268656C766574696361222C226E6F726D616C22292E69643B722E44413D222F48656C7620222B28652E5F5F6E72';
wwv_flow_imp.g_varchar2_table(616) := '466F726D53697A657C7C39292B2220546620302067222C4F626A6563742E646566696E6550726F706572747928722C224452222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A223C3C202F466F6E74203C';
wwv_flow_imp.g_varchar2_table(617) := '3C202F48656C7620222B6E2B286F26262248656C7622213D3D6F3F22202F222B6F2B2220222B6E3A2222292B22202F5A614462203C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F5A6170664469';
wwv_flow_imp.g_varchar2_table(618) := '6E6762617473203E3E203E3E203E3E227D292C4F626A6563742E646566696E6550726F706572747928722C224E656564417070656172616E636573222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A2274';
wwv_flow_imp.g_varchar2_table(619) := '727565227D292C722E5F5F6E723D21307D7D2869292C50726F6D6973652E7265736F6C766528692E6F7574707574282261727261796275666665722229297D66756E6374696F6E2043742865297B72657475726E20537472696E6728652E6C6162656C7C';
wwv_flow_imp.g_varchar2_table(620) := '7C652E6E616D65292E7265706C616365282F5C732B2F672C222022292E73756273747228302C3332297D66756E6374696F6E20417428652C742C72297B766172206E3D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6C286465297D7D';
wwv_flow_imp.g_varchar2_table(621) := '3B652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6C286665297D7D2C652E626F726465723D7B746F703A6E2C6C6566743A6E2C626F74746F6D3A6E2C72696768743A';
wwv_flow_imp.g_varchar2_table(622) := '6E7D2C652E70726F74656374696F6E3D7B6C6F636B65643A2121742E726561644F6E6C797D2C652E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65222C686F72697A6F6E74616C3A22636865';
wwv_flow_imp.g_varchar2_table(623) := '636B626F78223D3D3D742E696E7075743F2263656E746572223A226C656674222C77726170546578743A226D756C74696C696E65223D3D3D742E696E7075747D2C22636865636B626F78223D3D3D742E696E7075743F28652E76616C75653D742E636865';
wwv_flow_imp.g_varchar2_table(624) := '636B65643F68653A70652C652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21312C666F726D756C61653A5B2722E298902CE2989222275D2C73686F774572726F724D6573736167653A21302C6572';
wwv_flow_imp.g_varchar2_table(625) := '726F725469746C653A43742874292C6572726F723A22456C696A6120E29890206F20E298922E227D293A28652E76616C75653D22223D3D3D742E76616C75653F6E756C6C3A742E76616C75652C652E6E756D466D743D2240222C226C697374223D3D3D74';
wwv_flow_imp.g_varchar2_table(626) := '2E696E7075743F652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B7228742E6F7074696F6E73295D2C73686F774572726F724D6573736167653A21302C6572726F72';
wwv_flow_imp.g_varchar2_table(627) := '5469746C653A43742874292C6572726F723A22456C696A6120756E2076616C6F72206465206C61206C697374612E227D3A742E6D61784C656E677468262628652E6461746156616C69646174696F6E3D7B747970653A22746578744C656E677468222C6F';
wwv_flow_imp.g_varchar2_table(628) := '70657261746F723A226C6573735468616E4F72457175616C222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B742E6D61784C656E6774685D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A43742874292C';
wwv_flow_imp.g_varchar2_table(629) := '6572726F723A224DC3A178696D6F20222B742E6D61784C656E6774682B2220636172616374657265732E227D29292C652E6E616D653D742E6E616D657D66756E6374696F6E207A7428652C742C722C6E297B76617220613D6E65772077696E646F772E45';
wwv_flow_imp.g_varchar2_table(630) := '7863656C4A532E576F726B626F6F6B2C693D4B652865292C733D7B7D2C753D626528652C6E292C633D6D6528292C663D5B5D2C6D3D7B77733A6E756C6C2C6E3A302C7265663A7B7D7D3B612E63726561746F723D226E6F76615265706F7274223B766172';
wwv_flow_imp.g_varchar2_table(631) := '20763D652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C73782E73686565744E616D657C7C225265706F727465227D5D2C623D486528652C22786C737822292C773D652E706167657C7C7B7D2C78';
wwv_flow_imp.g_varchar2_table(632) := '3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6C28692E7072696D617279297D7D3B66756E6374696F6E20452865297B666F722876617220743D682865292E7265706C616365282F';
wwv_flow_imp.g_varchar2_table(633) := '5B5C5B5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C723D742C6E3D323B735B722E746F4C6F7765724361736528295D3B29723D742E73756273747228302C33312D537472696E67286E292E6C656E6774682D31292B225F';
wwv_flow_imp.g_varchar2_table(634) := '222B6E2C6E2B2B3B72657475726E20735B722E746F4C6F7765724361736528295D3D21302C727D66756E6374696F6E20542865297B72657475726E7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B';
wwv_flow_imp.g_varchar2_table(635) := '617267623A6C2865297D7D7D66756E6374696F6E20432865297B76617220743D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6C28657C7C7A65297D7D3B72657475726E7B746F703A742C6C6566743A742C626F74746F6D3A742C7269';
wwv_flow_imp.g_varchar2_table(636) := '6768743A747D7D66756E6374696F6E20412865297B76617220743D652E6A6F696E28222C22293B696628742E6C656E6774683C3D3235302626212F5B2C225D2F2E7465737428652E6A6F696E28222229292972657475726E2722272B742B2722273B6966';
wwv_flow_imp.g_varchar2_table(637) := '286D2E7265665B745D2972657475726E206D2E7265665B745D3B6D2E77737C7C286D2E77733D612E616464576F726B7368656574284528226E725F6C697374617322292C7B73746174653A2268696464656E227D29293B76617220723D2B2B6D2E6E3B65';
wwv_flow_imp.g_varchar2_table(638) := '2E666F72456163682866756E6374696F6E28652C74297B6D2E77732E67657443656C6C28742B312C72292E76616C75653D657D293B766172206E3D6D2E77732E676574436F6C756D6E2872292E6C65747465723B72657475726E206D2E7265665B745D3D';
wwv_flow_imp.g_varchar2_table(639) := '2227222B6D2E77732E6E616D652B22272124222B6E2B2224313A24222B6E2B2224222B652E6C656E6774682C6D2E7265665B745D7D72657475726E20742E666F72456163682866756E6374696F6E28722C6E297B76617220733D742E6C656E6774683E31';
wwv_flow_imp.g_varchar2_table(640) := '3F225F222B286E2B31293A22223B762E666F72456163682866756E6374696F6E286E297B76617220683D4E286E2E6E616D652C72293B6D652626742E6C656E6774683E31262628683D4E286E2E6D657267654E616D657C7C28762E6C656E6774683E313F';
wwv_flow_imp.g_varchar2_table(641) := '227B444F432E444F435F4B45597D20222B6E2E6E616D653A227B444F432E444F435F4B45597D22292C7229293B766172206D3D612E616464576F726B736865657428452868292C7B7061676553657475703A7B6F7269656E746174696F6E3A772E6F7269';
wwv_flow_imp.g_varchar2_table(642) := '656E746174696F6E7C7C22706F727472616974222C706170657253697A653A226C6567616C223D3D3D772E73697A653F353A226134223D3D3D772E73697A653F393A312C666974546F506167653A21302C666974546F57696474683A312C666974546F48';
wwv_flow_imp.g_varchar2_table(643) := '65696768743A307D7D292C7A3D6E2E73656374696F6E733F6E2E73656374696F6E732E6D61702866756E6374696F6E2865297B72657475726E226E756D626572223D3D747970656F6620653F625B655D3A622E66696C7465722866756E6374696F6E2874';
wwv_flow_imp.g_varchar2_table(644) := '297B72657475726E20742E69643D3D3D657D295B305D7D292E66696C74657228426F6F6C65616E293A623B7A3D71287A2E66696C7465722866756E6374696F6E2865297B72657475726E204A6528652C72297D29292E66696C7465722866756E6374696F';
wwv_flow_imp.g_varchar2_table(645) := '6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662822786C737822293E3D302926264A6528652C72297D293B76617220463D342C4C3D312C5F3D7B7D2C573D302C593D6E756C6C2C61653D6E756C6C';
wwv_flow_imp.g_varchar2_table(646) := '2C63653D21312C66653D66756E6374696F6E2865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E22636F6C756D6E6173223D3D3D742E747970653F4D6174682E6D617828652C5A6528742C22786C737822';
wwv_flow_imp.g_varchar2_table(647) := '2C722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B666528742E73656373292B317D2C2D3129293A22677275706F223D3D3D742E747970653F4D6174682E6D617828652C666528716528742C22786C7378222C';
wwv_flow_imp.g_varchar2_table(648) := '722929293A4D6174682E6D617828652C227461626C61223D3D3D742E747970653F5528742C722C6B28742C7229292E6C656E6774683A226669636861223D3D3D742E747970653F322A28742E636F6C756D6E737C7C33293A22666F726D756C6172696F22';
wwv_flow_imp.g_varchar2_table(649) := '3D3D3D742E747970653F322A28742E636F6C756D6E737C7C32293A227461726A65746173223D3D3D742E747970653F246528742C722C69292E6E3A22746578746F223D3D3D742E747970657C7C22616C65727461223D3D3D742E747970653F343A32297D';
wwv_flow_imp.g_varchar2_table(650) := '2C32297D3B66756E6374696F6E20646528652C74297B76617220723D537472696E67286E756C6C3D3D743F22223A74292E6C656E6774683B5F5B652B3D68655D3D4D6174682E6D696E2836302C4D6174682E6D6178285F5B655D7C7C382C722B3229297D';
wwv_flow_imp.g_varchar2_table(651) := '7A2E666F72456163682866756E6374696F6E2865297B22636F6C756D6E6173223D3D3D652E74797065262628463D4D6174682E6D617828462C5A6528652C22786C7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B726574';
wwv_flow_imp.g_varchar2_table(652) := '75726E20652B666528742E73656373292B317D2C2D312929292C227461626C61223D3D3D652E74797065262628572B2B2C463D4D6174682E6D617828462C5528652C722C6B28652C7229292E6C656E67746829292C226669636861223D3D3D652E747970';
wwv_flow_imp.g_varchar2_table(653) := '65262628463D4D6174682E6D617828462C322A28652E636F6C756D6E737C7C332929292C22666F726D756C6172696F223D3D3D652E74797065262628463D4D6174682E6D617828462C322A28652E636F6C756D6E737C7C322929292C227461726A657461';
wwv_flow_imp.g_varchar2_table(654) := '73223D3D3D652E74797065262628463D4D6174682E6D617828462C246528652C722C69292E6E29292C22677275706F223D3D3D652E74797065262628463D4D6174682E6D617828462C666528716528652C22786C7378222C72292929297D293B76617220';
wwv_flow_imp.g_varchar2_table(655) := '68653D302C70653D21313B66756E6374696F6E20676528652C74297B72657475726E206D2E67657443656C6C28652C742B6865297D66756E6374696F6E206D6528652C742C722C6E297B6D2E6D6572676543656C6C7328652C742B68652C722C6E2B6865';
wwv_flow_imp.g_varchar2_table(656) := '297D66756E6374696F6E20626528652C74297B76617220723D6D2E676574526F772865293B722E6865696768743D4D6174682E6D617828722E6865696768747C7C302C74297D66756E6374696F6E20776528652C742C722C6E297B766172206F3D612E61';
wwv_flow_imp.g_varchar2_table(657) := '6464496D616765287B6261736536343A652E646174612C657874656E73696F6E3A226A7067223D3D3D652E6578743F226A706567223A22706E67227D293B6D2E616464496D616765286F2C7B746C3A7B636F6C3A68652C726F773A4C2D317D2C6578743A';
wwv_flow_imp.g_varchar2_table(658) := '7B77696474683A332E37382A742C6865696768743A332E37382A727D7D292C4C2B3D4D6174682E6365696C28332E37382A722F3230292B286E3F303A31297D66756E6374696F6E20796528652C742C722C6E297B6D65284C2C312C4C2C46293B76617220';
wwv_flow_imp.g_varchar2_table(659) := '6F3D6765284C2C31293B6F2E76616C75653D652C6F2E66696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6E26266265284C2C70653F4D6174682E6D61';
wwv_flow_imp.g_varchar2_table(660) := '78286E2C31352A4D6174682E6365696C28537472696E6728657C7C2222292E6C656E6774682F4D6174682E6D61782831362C392A462929293A6E292C4C2B2B7D7A2E666F72456163682866756E6374696F6E2074286E297B76617220753D6E2E74797065';
wwv_flow_imp.g_varchar2_table(661) := '3B69662822636F6C756D6E6173223D3D3D75297B76617220663D4C2C683D4C2C763D68652C623D462C773D302C453D70653B72657475726E2070653D21302C5A65286E2C22786C7378222C722C313030292E666F72456163682866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(662) := '297B76617220723D666528652E73656373293B68653D762B772C463D722C4C3D662C652E736563732E666F72456163682874292C683D4D6174682E6D617828682C4C292C772B3D722B317D292C68653D762C463D622C70653D452C766F6964284C3D6829';
wwv_flow_imp.g_varchar2_table(663) := '7D69662822677275706F223D3D3D75297B76617220713D722C78653D733B72657475726E205865286E2C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C733D78652B652E7375663B766172206F3D7165286E2C22786C7378';
wwv_flow_imp.g_varchar2_table(664) := '222C72292C613D4C3B6966286F2E6C656E6774687C7C6E2E7469746C65297B6E2E7469746C6526267965284E286E2E7469746C652C72292C54286E2E7469746C6546696C6C7C7C692E7072696D617279292C7B626F6C643A21302C636F6C6F723A7B6172';
wwv_flow_imp.g_varchar2_table(665) := '67623A6C286E2E7469746C65436F6C6F727C7C692E6865616454657874297D7D2C3230292C6F2E666F72456163682874293B76617220753D4D6174682E6D617828612C4C2D31293B6966286E2E66696C6C29666F722876617220633D613B633C3D753B63';
wwv_flow_imp.g_varchar2_table(666) := '2B2B29666F722876617220663D313B663C3D463B662B2B297B76617220643D676528632C66293B642E66696C6C2626227061747465726E223D3D3D642E66696C6C2E747970657C7C28642E66696C6C3D54286E2E66696C6C29297D6966286E2E626F7264';
wwv_flow_imp.g_varchar2_table(667) := '657229666F722876617220683D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6C286E2E626F72646572436F6C6F727C7C7A65297D7D2C703D613B703C3D753B702B2B29666F722876617220673D313B673C3D463B672B2B2969662870';
wwv_flow_imp.g_varchar2_table(668) := '3D3D3D617C7C703D3D3D757C7C313D3D3D677C7C673D3D3D46297B766172206D3D676528702C67292C763D24286D2E626F726465727C7C7B7D293B703D3D3D61262628762E746F703D68292C703D3D3D75262628762E626F74746F6D3D68292C313D3D3D';
wwv_flow_imp.g_varchar2_table(669) := '67262628762E6C6566743D68292C673D3D3D46262628762E72696768743D68292C6D2E626F726465723D767D4C3D752B312B28303D3D3D6E2E6761703F303A31297D7D292C723D712C766F696428733D7865297D69662822686561646572223D3D3D7529';
wwv_flow_imp.g_varchar2_table(670) := '7B7661722053653D5765286E2C69292C45653D6E2E66696C6C3F542853652E66696C6C293A782C54653D7B617267623A6C2853652E636F6C6F72297D2C43653D7B626F6C643A21302C73697A653A53652E73697A652C636F6C6F723A54657D2C41653D7B';
wwv_flow_imp.g_varchar2_table(671) := '73697A653A6E2E7375627469746C653F53652E73756253697A653A53652E726967687453697A652C636F6C6F723A54657D3B6E2E666F6E7426262843652E6E616D653D41652E6E616D653D53652E666F6E745B315D292C7965284E286E2E7469746C652C';
wwv_flow_imp.g_varchar2_table(672) := '72292C45652C43652C4D6174682E6D61782832362C4D6174682E726F756E6428312E382A53652E73697A652929292C286E2E72696768747C7C6E2E7375627469746C652926267965285B4E286E2E7375627469746C652C72292C4E286E2E72696768742C';
wwv_flow_imp.g_varchar2_table(673) := '72295D2E66696C74657228426F6F6C65616E292E6A6F696E28222020207C20202022292C45652C41652C4D6174682E6D61782831362C4D6174682E726F756E6428312E382A41652E73697A652929292C4C2B2B7D656C73652069662822746578746F223D';
wwv_flow_imp.g_varchar2_table(674) := '3D3D752944286E2C72292E666F72456163682866756E6374696F6E2874297B6D65284C2C312C4C2C46293B76617220723D6765284C2C31293B722E76616C75653D7B72696368546578743A5228742C7B666F6E743A6E2E666F6E747C7C652E7061676526';
wwv_flow_imp.g_varchar2_table(675) := '26652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E7B746578743A652E742C666F6E743A7B626F6C643A212821652E622626216E2E626F6C64292C6974616C69633A21282165';
wwv_flow_imp.g_varchar2_table(676) := '2E692626216E2E6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F696420302C6E616D653A495B652E665D5B315D2C636F6C6F723A652E633F7B617267623A6C28652E63297D3A766F696420';
wwv_flow_imp.g_varchar2_table(677) := '302C73697A653A6E2E73697A657C7C31307D7D7D297D2C722E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22746F70222C686F72697A6F6E74616C3A226A757374696679223D3D3D6E2E616C69676E3F226A75737469';
wwv_flow_imp.g_varchar2_table(678) := '6679223A6E2E616C69676E7C7C226C656674227D2C6265284C2C4D6174682E6D61782831352C31352A4D6174682E6365696C28742E6C656E6774682F2870653F4D6174682E6D61782831362C392A46293A313430292929292C4C2B2B7D293B656C736520';
wwv_flow_imp.g_varchar2_table(679) := '696628226573706163696F223D3D3D75294C2B2B3B656C73652069662822696D6167656E223D3D3D75297B766172204D653D6C74286E2C72293B6966284D65297B7661722050653D6974286E2C4D65293B7765284D652C50652E772C50652E68297D7D65';
wwv_flow_imp.g_varchar2_table(680) := '6C736520696628226772616669636F223D3D3D75297B766172206B653D7974286E2C722C69293B6B6526267765286B652C6B652E776D6D2C6B652E686D6D297D656C73652069662822636F6469676F223D3D3D75297B766172206A653D7674286E2C7229';
wwv_flow_imp.g_varchar2_table(681) := '3B6966286A65297B7661722044653D6274286A65293B69662877652844652C44652E776D6D2C44652E686D6D2C6A652E6C6162656C292C6A652E6C6162656C297B7661722055653D6765284C2C31293B55652E76616C75653D6A652E746578742C55652E';
wwv_flow_imp.g_varchar2_table(682) := '666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A6A652E7465787453697A657D2C4C2B3D327D7D7D656C7365206966282273616C746F223D3D3D75294C2B2B3B656C736520696628226669636861223D3D3D75297B7661722042';
wwv_flow_imp.g_varchar2_table(683) := '653D6B286E2C72295B305D7C7C7B7D2C47653D6E2E636F6C756D6E737C7C332C5F653D313B466528286E2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5028652E7768656E2C722C';
wwv_flow_imp.g_varchar2_table(684) := '4265297D292C4765292E666F72456163682866756E6374696F6E28652C74297B743E3026264C2B2B3B76617220613D652E736F6D652866756E6374696F6E2865297B72657475726E21652E656D707479262622746F70223D3D3D496528652E662C6E292E';
wwv_flow_imp.g_varchar2_table(685) := '706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220743D652E663B5F653D312B322A652E636F6C3B76617220692C733D496528742C6E292C753D5F652B322A652E7370616E2D312C633D6E75';
wwv_flow_imp.g_varchar2_table(686) := '6C6C2C663D4E28742E6C6162656C2C722C4265293B696628226C656674223D3D3D732E706F73297B696628633D6765284C2C5F65292C693D6765284C2C5F652B31292C632E76616C75653D526528662C73292C632E666F6E743D6E2E6C6162656C436F6C';
wwv_flow_imp.g_varchar2_table(687) := '6F723F7B626F6C643A21302C636F6C6F723A7B617267623A6C286E2E6C6162656C436F6C6F72297D7D3A7B626F6C643A21307D2C6E2E6C6162656C46696C6C262628632E66696C6C3D54286E2E6C6162656C46696C6C29292C6E2E76616C7565436F6C6F';
wwv_flow_imp.g_varchar2_table(688) := '72262628692E666F6E743D7B636F6C6F723A7B617267623A6C286E2E76616C7565436F6C6F72297D7D292C6E2E67726964262628632E626F726465723D692E626F726465723D43286E2E626F72646572436F6C6F72292C632E616C69676E6D656E743D7B';
wwv_flow_imp.g_varchar2_table(689) := '766572746963616C3A226D6964646C65222C77726170546578743A21307D292C28652E7370616E3E317C7C61292626286D65284C2C5F652B312C613F4C2B313A4C2C75292C6E2E677269642929666F722876617220683D5F652B323B683C3D753B682B2B';
wwv_flow_imp.g_varchar2_table(690) := '296765284C2C68292E626F726465723D43286E2E626F72646572436F6C6F72293B612626286D65284C2C5F652C4C2B312C5F65292C632E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C732E';
wwv_flow_imp.g_varchar2_table(691) := '7374796C656426264C6528632C732C2131297D656C73657B76617220703D22746F70223D3D3D732E706F732626613F4C2B313A4C2C6D3D226E6F6E65223D3D3D732E706F732626613F4C2B313A703B69662822746F70223D3D3D732E706F73297B28633D';
wwv_flow_imp.g_varchar2_table(692) := '6765284C2C5F6529292E76616C75653D526528662C73292C753E5F6526266D65284C2C5F652C4C2C75292C6E2E67726964262628632E626F726465723D43286E2E626F72646572436F6C6F7229293B76617220763D4F6528742C722C4265293B4C652863';
wwv_flow_imp.g_varchar2_table(693) := '2C732C21302C762626762E616C69676E297D693D676528702C5F65292C28753E5F657C7C6D3E702926266D6528702C5F652C6D2C75292C6E2E76616C7565436F6C6F72262628692E666F6E743D7B636F6C6F723A7B617267623A6C286E2E76616C756543';
wwv_flow_imp.g_varchar2_table(694) := '6F6C6F72297D7D292C6E2E67726964262628692E626F726465723D43286E2E626F72646572436F6C6F7229297D76617220623D2F5E5C7B5B5E7D7C5D2B5C7D242F2E7465737428742E76616C75657C7C222229262621742E6D61703F4D28722C742E7661';
wwv_flow_imp.g_varchar2_table(695) := '6C75652E736C69636528312C2D31292C4265293A6E756C6C3B6F2862292626216728742E666D74293F28692E76616C75653D622C226D6F6E6579223D3D3D742E666D743F692E6E756D466D743D22232C2323302E3030223A5328742E666D742926262869';
wwv_flow_imp.g_varchar2_table(696) := '2E6E756D466D743D7928742E666D7429292C692E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A2264617465223D3D3D742E666D742626642862293F28692E76616C75653D642862292C692E6E756D466D743D2264642F6D';
wwv_flow_imp.g_varchar2_table(697) := '6D2F79797979222C692E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A692E76616C75653D756528742C722C4265292C6E2E67726964262628692E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674222C';
wwv_flow_imp.g_varchar2_table(698) := '766572746963616C3A226D6964646C65222C77726170546578743A21307D293B76617220773D4F6528742C722C4265293B69662877297B696628772E626F6C647C7C772E636F6C6F72297B76617220783D7B7D3B4F626A6563742E6B65797328692E666F';
wwv_flow_imp.g_varchar2_table(699) := '6E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B785B655D3D692E666F6E745B655D7D292C772E626F6C64262628782E626F6C643D2130292C772E636F6C6F72262628782E636F6C6F723D7B617267623A6C28772E636F6C6F72297D';
wwv_flow_imp.g_varchar2_table(700) := '292C692E666F6E743D787D696628772E616C69676E297B76617220453D7B7D3B4F626A6563742E6B65797328692E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B455B655D3D692E616C69676E6D656E745B655D';
wwv_flow_imp.g_varchar2_table(701) := '7D292C452E686F72697A6F6E74616C3D772E616C69676E2C692E616C69676E6D656E743D457D772E66696C6C262628692E66696C6C3D5428772E66696C6C29297D226C656674223D3D3D732E706F733F286465285F652C66292C313D3D3D652E7370616E';
wwv_flow_imp.g_varchar2_table(702) := '26266465285F652B312C756528742C722C42652929293A313D3D3D652E7370616E26266465285F652B312C537472696E6728756528742C722C426529292E73756273747228302C343029297D7D292C6126264C2B2B7D292C4C2B3D327D656C7365206966';
wwv_flow_imp.g_varchar2_table(703) := '28227461726A65746173223D3D3D7529666F72287661722048653D2465286E2C722C69292C56653D303B56653C48652E6974656D732E6C656E6774683B56652B3D48652E6E297B7661722059653D313B48652E6974656D732E736C6963652856652C5665';
wwv_flow_imp.g_varchar2_table(704) := '2B48652E6E292E666F72456163682866756E6374696F6E28652C74297B76617220723D6765284C2C742B31292C6E3D6765284C2B312C742B31292C6F3D48652E616363656E743F7B6C6566743A7B7374796C653A22746869636B222C636F6C6F723A7B61';
wwv_flow_imp.g_varchar2_table(705) := '7267623A6C2848652E616363656E74297D7D7D3A7B7D3B722E76616C75653D652E6C6162656C2C722E666F6E743D7B73697A653A48652E6C6162656C53697A652B312C636F6C6F723A7B617267623A6C2848652E6C6162656C436F6C6F72297D7D2C6E2E';
wwv_flow_imp.g_varchar2_table(706) := '76616C75653D652E76616C75652C6E2E666F6E743D7B626F6C643A21302C73697A653A48652E73697A652C636F6C6F723A7B617267623A6C28652E636F6C6F727C7C48652E76616C7565436F6C6F72297D7D2C5B722C6E5D2E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(707) := '6374696F6E2865297B652E66696C6C3D542848652E66696C6C292C652E626F726465723D6F2C652E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C696E64656E743A312C77726170546578743A21307D7D292C646528742B312C';
wwv_flow_imp.g_varchar2_table(708) := '652E6C6162656C292C646528742B312C537472696E6728652E76616C7565292E73756273747228302C3430292B2220202020202022292C59653D4D6174682E6D61782859652C4D6174682E6365696C28537472696E6728652E76616C7565292E6C656E67';
wwv_flow_imp.g_varchar2_table(709) := '74682F343029297D292C6265284C2C3136292C6265284C2B312C4D6174682E726F756E6428312E372A48652E73697A65292A5965292C4C2B3D337D656C73652069662822666F726D756C6172696F223D3D3D75297B766172204A653D6E2E636F6C756D6E';
wwv_flow_imp.g_varchar2_table(710) := '737C7C322C4B653D312C51653D7665286E2C722C73293B46652851652C4A65292E666F72456163682866756E6374696F6E28652C74297B743E3026264C2B2B3B76617220723D652E736F6D652866756E6374696F6E2865297B72657475726E21652E656D';
wwv_flow_imp.g_varchar2_table(711) := '707479262622746F70223D3D3D652E662E6C61622E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220743D652E662C6E3D742E6C61623B4B653D312B322A652E636F6C2C6328742E6E616D';
wwv_flow_imp.g_varchar2_table(712) := '65293B766172206F3D4B652B322A652E7370616E2D312C613D22636865636B626F78223D3D3D742E696E7075743F22223A742E76616C75652E6C656E6774683E32303F742E76616C75653A6E6577204172726179283231292E6A6F696E28227822293B69';
wwv_flow_imp.g_varchar2_table(713) := '6628226C656674223D3D3D6E2E706F73297B766172206C3D6765284C2C4B65292C693D6765284C2C4B652B31293B72657475726E206C2E76616C75653D526528742E6C6162656C2C6E292C6C2E666F6E743D7B626F6C643A21307D2C6C2E616C69676E6D';
wwv_flow_imp.g_varchar2_table(714) := '656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65227D2C28652E7370616E3E317C7C722926266D65284C2C4B652B312C723F4C2B313A4C2C6F292C7226266D65284C2C4B652C4C2B312C4B65292C6E2E737479';
wwv_flow_imp.g_varchar2_table(715) := '6C656426264C65286C2C6E2C2131292C417428692C742C41292C742E6C696E65733E312626626528723F4C2B313A4C2C31352A742E6C696E6573292C6465284B652C742E6C6162656C292C766F696428313D3D3D652E7370616E26266465284B652B312C';
wwv_flow_imp.g_varchar2_table(716) := '6129297D76617220733D22746F70223D3D3D6E2E706F732626723F4C2B313A4C2C753D226E6F6E65223D3D3D6E2E706F732626723F4C2B313A733B69662822746F70223D3D3D6E2E706F73297B76617220663D6765284C2C4B65293B662E76616C75653D';
wwv_flow_imp.g_varchar2_table(717) := '526528742E6C6162656C2C6E292C6F3E4B6526266D65284C2C4B652C4C2C6F292C4C6528662C6E2C2130297D286F3E4B657C7C753E732926266D6528732C4B652C752C6F292C417428676528732C4B65292C742C41292C742E6C696E65733E3126266265';
wwv_flow_imp.g_varchar2_table(718) := '28752C31352A742E6C696E6573292C313D3D3D652E7370616E26266465284B652B312C61297D7D292C7226264C2B2B7D292C51652E6C656E67746826262863653D21302C4C2B3D32297D656C73652069662822616C65727461223D3D3D75296B286E2C72';
wwv_flow_imp.g_varchar2_table(719) := '292E66696C7465722866756E6374696F6E2865297B72657475726E2050286E2E7768656E2C722C65297D292E736C69636528302C6E2E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B7965284E286E2E746578742C722C';
wwv_flow_imp.g_varchar2_table(720) := '65292C54284F286E2E636F6C6F722C722C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C4C2B2B3B656C736520696628227461626C61223D3D3D75297B7661722065743D6B286E2C72293B6966282165742E6C656E677468';
wwv_flow_imp.g_varchar2_table(721) := '26262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B7661722074743D55286E2C722C6574293B6966286E2E7469746C65297B6D65284C2C312C4C2C74742E6C656E677468293B7661722072743D6765284C';
wwv_flow_imp.g_varchar2_table(722) := '2C31293B72742E76616C75653D4E286E2E7469746C652C72292C72742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E6865616454657874297D7D2C72742E66696C6C3D782C4C2B2B7D766172206E743D4C3B6966286E2E67';
wwv_flow_imp.g_varchar2_table(723) := '726F757073297B766172206F743D313B42286E2C7474292E666F72456163682866756E6374696F6E2865297B652E636F6C733E31262621652E67617026266D65284C2C6F742C4C2C6F742B652E636F6C732D31293B76617220743D6765284C2C6F74293B';
wwv_flow_imp.g_varchar2_table(724) := '696628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B6D65284C2C6F742B722C4C2B312C6F742B72293B766172206F3D6765284C2C6F742B72293B6F2E76616C75653D74745B652E66726F6D2B725D2E6C6162656C2C';
wwv_flow_imp.g_varchar2_table(725) := '6F2E66696C6C3D782C6F2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E6865616454657874297D7D2C6F2E616C69676E6D656E743D7B686F72697A6F6E74616C3A4E652874745B652E66726F6D2B725D2C6E292C76657274';
wwv_flow_imp.g_varchar2_table(726) := '6963616C3A226D6964646C65222C77726170546578743A21307D2C6465286F742B722C74745B652E66726F6D2B725D2E6C6162656C297D6F742B3D652E636F6C737D656C736520742E76616C75653D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D';
wwv_flow_imp.g_varchar2_table(727) := '782C742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E6865616454657874297D7D2C742E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65227D2C6F74';
wwv_flow_imp.g_varchar2_table(728) := '2B3D652E636F6C737D292C4C2B2B7D7661722061743D4C2C73743D7B7D3B6966286E2E67726F757073262642286E2C7474292E666F72456163682866756E6374696F6E2865297B696628652E67617029666F722876617220743D652E66726F6D3B743C65';
wwv_flow_imp.g_varchar2_table(729) := '2E66726F6D2B652E636F6C733B742B2B2973745B745D3D317D292C74742E666F72456163682866756E6374696F6E28652C74297B6966282173745B745D297B76617220723D6765284C2C742B31293B722E76616C75653D652E6C6162656C2C722E66696C';
wwv_flow_imp.g_varchar2_table(730) := '6C3D782C722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E6865616454657874297D7D2C722E616C69676E6D656E743D7B686F72697A6F6E74616C3A4E6528652C6E292C766572746963616C3A226D6964646C65222C7772';
wwv_flow_imp.g_varchar2_table(731) := '6170546578743A21307D2C646528742B312C652E6C6162656C297D7D292C4C2B2B2C2165742E6C656E6774682972657475726E206D65284C2C312C4C2C74742E6C656E677468292C6765284C2C31292E76616C75653D4E286E2E656D707479546578742C';
wwv_flow_imp.g_varchar2_table(732) := '72292C6765284C2C31292E666F6E743D7B6974616C69633A21307D2C766F6964284C2B3D32293B7661722075743D4C2C63743D6965286E2C6574292C66743D6C65286E292C64743D6E756C6C2C68743D66756E6374696F6E28652C742C722C6F2C612C73';
wwv_flow_imp.g_varchar2_table(733) := '2C75297B76617220633D6E652874742C742C722C6F292C663D65652874292C683D66756E6374696F6E2865297B72657475726E20652E66696C6C3D5428692E746F74616C73292C652E666F6E743D6E2E746F74616C73436F6C6F723F7B626F6C643A2130';
wwv_flow_imp.g_varchar2_table(734) := '2C636F6C6F723A7B617267623A6C286E2E746F74616C73436F6C6F72297D7D3A7B626F6C643A21307D2C657D3B28632E61743E317C7C303D3D3D632E61742926266D6528652C312C652C632E61747C7C74742E6C656E677468293B76617220673D682867';
wwv_flow_imp.g_varchar2_table(735) := '6528652C3129293B72657475726E20672E76616C75653D6F2C672E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D2C303D3D3D632E61742626652B2B2C74742E666F72456163682866756E6374696F6E286E2C6F297B69662821';
wwv_flow_imp.g_varchar2_table(736) := '286F3C632E617429297B766172206C3D6828676528652C6F2B3129292C693D6E2E636F6C3F5128742C6E2E636F6C293A6E756C6C3B69662869297B76617220673D6D2E676574436F6C756D6E286F2B312B6865292E6C65747465722C763D672B612B223A';
wwv_flow_imp.g_varchar2_table(737) := '222B672B732C623D726528722C692E636F6C2C692E666E292C773D226D696E22213D3D692E666E2626226D617822213D3D692E666E7C7C6E756C6C3D3D3D627C7C74652862293F6E756C6C3A642862292C783D6E756C6C3D3D623F6E756C6C3A777C7C28';
wwv_flow_imp.g_varchar2_table(738) := '74652862293F4D6174682E726F756E64283130302A4E756D626572286229292F3130303A537472696E67286229293B6C2E76616C75653D7B666F726D756C613A28753F22535542544F54414C28222B585B692E666E5D2B222C223A5A5B692E666E5D2B22';
wwv_flow_imp.g_varchar2_table(739) := '2822292B762B2229222C726573756C743A787D3B76617220453D22636F756E74223D3D3D692E666E3F22232C232330223A773F2264642F6D6D2F79797979223A53286E2E666D74293F79286E2E666D74293A22232C2323302E3030223B6C2E6E756D466D';
wwv_flow_imp.g_varchar2_table(740) := '743D6626264A5B692E666E5D3F2722272B4A5B692E666E5D2B272022272B453A452C6C2E616C69676E6D656E743D7B686F72697A6F6E74616C3A227269676874227D2C6E756C6C3D3D3D787C7C777C7C6465286F2B312C74652878293F7028782C53286E';
wwv_flow_imp.g_varchar2_table(741) := '2E666D7429262622636F756E7422213D3D692E666E3F6E2E666D743A226D6F6E657922293A78297D7D7D292C652B317D3B63742E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B297B6D65284C2C312C4C2C7474';
wwv_flow_imp.g_varchar2_table(742) := '2E6C656E677468293B76617220743D6765284C2C31293B72657475726E20742E76616C75653D7365286E2C652C72292C742E666F6E743D7B626F6C643A21307D2C742E66696C6C3D5428692E67726F7570292C766F6964204C2B2B7D6966282273756222';
wwv_flow_imp.g_varchar2_table(743) := '3D3D3D652E6B2972657475726E204C3D6874284C2C66742C652E726F77732C7365286E2C652C72292C64742C4C2D312C2130292C766F69642864743D6E756C6C293B6E756C6C3D3D3D647426262864743D4C293B76617220733D652E722C753D652E692C';
wwv_flow_imp.g_varchar2_table(744) := '633D48286E2C7474292C663D6A286E2E726F775374796C652C722C73293B74742E666F72456163682866756E6374696F6E28652C74297B76617220683D6765284C2C742B31292C763D4728652C732C72293B696628652E63656C6C297B76617220623D56';
wwv_flow_imp.g_varchar2_table(745) := '28652C732C722C69292C773D742B312B68653B696628682E76616C75653D6E756C6C2C28652E76616C69676E7C7C6329262628682E616C69676E6D656E743D7B686F72697A6F6E74616C3A652E616C69676E2C766572746963616C3A652E76616C69676E';
wwv_flow_imp.g_varchar2_table(746) := '7C7C637D292C7525323D3D3126262131213D3D6E2E7A65627261262628682E66696C6C3D5428692E7A6562726129292C62297B76617220783D612E616464496D616765287B6261736536343A622E696D2E646174612C657874656E73696F6E3A226A7067';
wwv_flow_imp.g_varchar2_table(747) := '223D3D3D622E696D2E6578743F226A706567223A22706E67227D293B6D2E616464496D61676528782C7B746C3A7B636F6C3A772D312B2E30382C726F773A4C2D312B2E30387D2C6578743A7B77696474683A332E37382A622E772C6865696768743A332E';
wwv_flow_imp.g_varchar2_table(748) := '37382A622E687D7D292C6265284C2C322E3833352A622E682B34292C5F5B775D3D4D6174682E6D696E2836302C4D6174682E6D6178285F5B775D7C7C382C4D6174682E6365696C28332E37382A622E772F37292B3229297D7D656C73657B76617220453B';
wwv_flow_imp.g_varchar2_table(749) := '652E69734E756D26266F2876293F28682E76616C75653D762C682E6E756D466D743D5328453D652E666D74293F792845293A22696E74223D3D3D453F22232C232330223A226D6F6E6579223D3D3D457C7C2F5E6E756D2F2E7465737428457C7C2222293F';
wwv_flow_imp.g_varchar2_table(750) := '22232C2323302E222B6E657720417272617928312A2828457C7C2222292E73706C697428223A22295B315D7C7C32292B31292E6A6F696E28223022293A2247656E6572616C22293A226461746522213D3D652E666D742626224441544522213D3D28722E';
wwv_flow_imp.g_varchar2_table(751) := '545B537472696E67286E2E736F75726365292E746F55707065724361736528295D7C7C7B7D295B652E636F6C5D7C7C21642876293F682E76616C75653D6E756C6C3D3D763F6E756C6C3A6728652E666D7429262621652E6D61703F7028762C652E666D74';
wwv_flow_imp.g_varchar2_table(752) := '293A537472696E672876293A28682E76616C75653D642876292C682E6E756D466D743D2264642F6D6D2F7979797922292C682E616C69676E6D656E743D652E76616C69676E7C7C633F7B686F72697A6F6E74616C3A652E616C69676E2C76657274696361';
wwv_flow_imp.g_varchar2_table(753) := '6C3A652E76616C69676E7C7C637D3A7B686F72697A6F6E74616C3A652E616C69676E7D3B76617220433D6A28652E63656C6C5374796C652C722C73297C7C663B432626432E66696C6C3F682E66696C6C3D5428432E66696C6C293A7525323D3D31262621';
wwv_flow_imp.g_varchar2_table(754) := '31213D3D6E2E7A65627261262628682E66696C6C3D5428692E7A6562726129293B76617220413D7B7D3B28652E626F6C647C7C432626432E626F6C6429262628412E626F6C643D2130292C28432626432E636F6C6F727C7C652E636F6C6F722926262841';
wwv_flow_imp.g_varchar2_table(755) := '2E636F6C6F723D7B617267623A6C28432626432E636F6C6F727C7C652E636F6C6F72297D292C28412E626F6C647C7C412E636F6C6F7229262628682E666F6E743D41292C646528742B312C652E69734E756D3F7028762C652E666D74293A76297D7D292C';
wwv_flow_imp.g_varchar2_table(756) := '4C2B2B7D293B7661722070743D4C2D312C67743D4B286E2E746F74616C73293B69662867742E6C656E6774682626284C3D6874284C2C67742C65742C6F65286E2C722C6574292C75742C4C2D312C21216E2E627265616B427929292C6E2E677269642966';
wwv_flow_imp.g_varchar2_table(757) := '6F7228766172206D743D43286E2E626F72646572436F6C6F72292C77743D6E743B77743C4C3B77742B2B29666F72287661722078743D313B78743C3D74742E6C656E6774683B78742B2B2967652877742C7874292E626F726465723D6D743B31213D3D57';
wwv_flow_imp.g_varchar2_table(758) := '7C7C6E2E627265616B42797C7C70657C7C2861653D7B66726F6D3A7B726F773A61742C636F6C756D6E3A317D2C746F3A7B726F773A70742C636F6C756D6E3A74742E6C656E6774687D7D2C7A2E696E6465784F66286E293C3D31262628593D617429292C';
wwv_flow_imp.g_varchar2_table(759) := '4C2B2B7D7D292C4F626A6563742E6B657973285F292E666F72456163682866756E6374696F6E2865297B6D2E676574436F6C756D6E282B65292E77696474683D5F5B655D7D292C61652626286D2E6175746F46696C7465723D6165292C592626286D2E76';
wwv_flow_imp.g_varchar2_table(760) := '696577733D5B7B73746174653A2266726F7A656E222C7953706C69743A597D5D292C63652626752E70726F746563742626662E70757368286D2E70726F7465637428752E70617373776F72642C7B73656C6563744C6F636B656443656C6C733A21302C73';
wwv_flow_imp.g_varchar2_table(761) := '656C656374556E6C6F636B656443656C6C733A21302C666F726D6174436F6C756D6E733A21302C666F726D6174526F77733A21307D29292C652E666F6F7465722626286D2E686561646572466F6F7465722E6F6464466F6F7465723D22264C2638222B4E';
wwv_flow_imp.g_varchar2_table(762) := '28652E666F6F7465722E6C6566742C72292E7265706C616365282F262F672C22262622292E73756273747228302C323030292B222652263850C3A167696E6120265020646520264E22297D297D292C7965286529262666756E6374696F6E2865297B7661';
wwv_flow_imp.g_varchar2_table(763) := '7220743D652E646566696E65644E616D65732C723D7426264F626A6563742E6765744F776E50726F706572747944657363726970746F72284F626A6563742E67657450726F746F747970654F662874292C226D6F64656C22293B722626722E6765742626';
wwv_flow_imp.g_varchar2_table(764) := '21742E5F5F6E722626284F626A6563742E646566696E6550726F706572747928742C226D6F64656C222C7B636F6E666967757261626C653A21302C6765743A66756E6374696F6E28297B72657475726E20722E6765742E63616C6C2874686973292E6D61';
wwv_flow_imp.g_varchar2_table(765) := '702866756E6374696F6E2865297B72657475726E7B6E616D653A652E6E616D652C72616E6765733A652E72616E6765732E6D61702866756E6374696F6E2865297B76617220743D2F5E285B5E27215D2B2921282E2B29242F2E657865632865293B726574';
wwv_flow_imp.g_varchar2_table(766) := '75726E20743F2227222B745B315D2B222721222B745B325D3A657D297D7D297D2C7365743A66756E6374696F6E2865297B722E7365742E63616C6C28746869732C65297D7D292C742E5F5F6E723D2130297D2861292C662E6C656E6774683F50726F6D69';
wwv_flow_imp.g_varchar2_table(767) := '73652E616C6C2866292E7468656E2866756E6374696F6E28297B72657475726E20612E786C73782E777269746542756666657228297D293A612E786C73782E777269746542756666657228297D766172204D743D7B6C65747465723A5B31323234302C31';
wwv_flow_imp.g_varchar2_table(768) := '353834305D2C6C6567616C3A5B31323234302C32303136305D2C61343A5B31313930362C31363833385D7D3B66756E6374696F6E204E7428652C742C72297B766172206E3D77696E646F772E646F63782C6F3D5B5D2C613D4D6174682E726F756E642832';
wwv_flow_imp.g_varchar2_table(769) := '2A28652E73697A657C7C3729292C6C3D6928722E6D75746564293B66756E6374696F6E20732865297B76617220723D4E28652C74292E73706C6974282F285C7B50414745533F5C7D292F292C6F3D5B5D3B72657475726E20722E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(770) := '6E6374696F6E2865297B227B504147457D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E43555252454E545D2C73697A653A612C636F6C6F723A6C7D29293A227B504147';
wwv_flow_imp.g_varchar2_table(771) := '45537D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E544F54414C5F50414745535D2C73697A653A612C636F6C6F723A6C7D29293A6526266F2E70757368286E6577206E';
wwv_flow_imp.g_varchar2_table(772) := '2E5465787452756E287B746578743A652C73697A653A612C636F6C6F723A6C7D29297D292C6F7D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A7328652E6C656674297D29292C';
wwv_flow_imp.g_varchar2_table(773) := '652E726967687426266F2E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E3A7328652E7269676874297D29292C6F2E6C656E6774683F6F3A5B';
wwv_flow_imp.g_varchar2_table(774) := '6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D7D7661722046743D22E29FA64E52463A223B66756E6374696F6E2050742865297B72657475726E20537472696E672865292E7265706C616365282F262F672C2226616D703B';
wwv_flow_imp.g_varchar2_table(775) := '22292E7265706C616365282F3C2F672C22266C743B22292E7265706C616365282F3E2F672C222667743B22292E7265706C616365282F222F672C222671756F743B22297D66756E6374696F6E206B7428652C74297B696628653D652E7265706C61636528';
wwv_flow_imp.g_varchar2_table(776) := '2F3C773A646F63756D656E7450726F74656374696F6E5B5E3E5D2A5C2F3E2F672C2222292C21742E70726F746563742972657475726E20653B76617220723D273C773A646F63756D656E7450726F74656374696F6E20773A656469743D22666F726D7322';
wwv_flow_imp.g_varchar2_table(777) := '20773A656E666F7263656D656E743D223122273B696628742E70617373776F7264297B766172206E3D66756E6374696F6E2865297B76617220743D6E65772055696E743841727261792865292C723D22756E646566696E656422213D747970656F662077';
wwv_flow_imp.g_varchar2_table(778) := '696E646F7726262877696E646F772E63727970746F7C7C77696E646F772E6D7343727970746F293B696628722626722E67657452616E646F6D56616C75657329722E67657452616E646F6D56616C7565732874293B656C736520666F7228766172206E3D';
wwv_flow_imp.g_varchar2_table(779) := '303B6E3C653B6E2B2B29745B6E5D3D4D6174682E666C6F6F72283235362A4D6174682E72616E646F6D2829293B72657475726E20747D283136292C6F3D3165353B722B3D2720773A637279707450726F7669646572547970653D22727361414553222077';
wwv_flow_imp.g_varchar2_table(780) := '3A6372797074416C676F726974686D436C6173733D22686173682220773A6372797074416C676F726974686D547970653D2274797065416E792220773A6372797074416C676F726974686D5369643D2231342220773A63727970745370696E436F756E74';
wwv_flow_imp.g_varchar2_table(781) := '3D22272B6F2B272220773A686173683D22272B6E7428416528742E70617373776F72642C6E2C6F29292B272220773A73616C743D22272B6E74286E292B2722277D722B3D222F3E223B76617220613D5B223C773A6576656E416E644F6464486561646572';
wwv_flow_imp.g_varchar2_table(782) := '73222C223C773A636F6D706174222C223C2F773A73657474696E67733E225D2E6D61702866756E6374696F6E2874297B72657475726E20652E696E6465784F662874297D292E66696C7465722866756E6374696F6E2865297B72657475726E20653E3D30';
wwv_flow_imp.g_varchar2_table(783) := '7D295B305D3B72657475726E20652E73756273747228302C61292B722B652E7375627374722861297D66756E6374696F6E204F7428652C742C72297B72657475726E20722E70726F746563742626722E70617373776F72642626416528722E7061737377';
wwv_flow_imp.g_varchar2_table(784) := '6F72642C6E65772055696E74384172726179283136292C30292C77696E646F772E4A535A69702E6C6F61644173796E632865292E7468656E2866756E6374696F6E2865297B72657475726E2050726F6D6973652E616C6C285B652E66696C652822776F72';
wwv_flow_imp.g_varchar2_table(785) := '642F646F63756D656E742E786D6C22292E6173796E632822737472696E6722292C652E66696C652822776F72642F73657474696E67732E786D6C22292E6173796E632822737472696E6722295D292E7468656E2866756E6374696F6E286E297B76617220';
wwv_flow_imp.g_varchar2_table(786) := '6F3D302C613D6E65772052656745787028273C773A723E283C773A7250723E283F3A283F213C2F773A7250723E295B5C5C735C5C535D292A3C2F773A7250723E293F3C773A7420786D6C3A73706163653D227072657365727665223EE29FA64E52463A28';
wwv_flow_imp.g_varchar2_table(787) := '5C5C642B29E29FA73C2F773A743E3C2F773A723E272C226722292C6C3D6E5B305D2E7265706C61636528612C66756E6374696F6E28652C722C6E297B72657475726E206F2B2B2C66756E6374696F6E28652C742C72297B766172206E3D273C773A616C69';
wwv_flow_imp.g_varchar2_table(788) := '617320773A76616C3D22272B507428652E6C6162656C7C7C652E6E616D65292B27222F3E3C773A74616720773A76616C3D22272B507428652E6E616D65292B27222F3E3C773A696420773A76616C3D22272B742B27222F3E272B28652E726561644F6E6C';
wwv_flow_imp.g_varchar2_table(789) := '793F273C773A6C6F636B20773A76616C3D22736474436F6E74656E744C6F636B6564222F3E273A2222293B69662822636865636B626F78223D3D3D652E696E707574297B766172206F3D722E7265706C616365282F3C773A72466F6E74735B5E3E5D2A5C';
wwv_flow_imp.g_varchar2_table(790) := '2F3E2F2C2222292E7265706C61636528223C773A7250723E222C273C773A7250723E3C773A72466F6E747320773A61736369693D224D5320476F746869632220773A65617374417369613D224D5320476F746869632220773A68416E73693D224D532047';
wwv_flow_imp.g_varchar2_table(791) := '6F746869632220773A63733D224D5320476F74686963222F3E27293B72657475726E223C773A7364743E3C773A73647450723E222B6F2B6E2B273C7731343A636865636B626F783E3C7731343A636865636B6564207731343A76616C3D22272B28652E63';
wwv_flow_imp.g_varchar2_table(792) := '6865636B65643F313A30292B27222F3E3C7731343A636865636B65645374617465207731343A76616C3D223236313222207731343A666F6E743D224D5320476F74686963222F3E3C7731343A756E636865636B65645374617465207731343A76616C3D22';
wwv_flow_imp.g_varchar2_table(793) := '3236313022207731343A666F6E743D224D5320476F74686963222F3E3C2F7731343A636865636B626F783E3C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E272B6F2B223C773A743E222B28652E636865636B65643F68653A7065';
wwv_flow_imp.g_varchar2_table(794) := '292B223C2F773A743E3C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D76617220613D21652E76616C75652C6C3D652E76616C75657C7C652E706C616365686F6C6465727C7C28226C697374223D3D3D652E696E7075743F22';
wwv_flow_imp.g_varchar2_table(795) := '456C696A6120756E20656C656D656E746F2E223A6E65772041727261792839292E6A6F696E2822E280822229293B72657475726E223C773A7364743E3C773A73647450723E222B722B6E2B28613F223C773A73686F77696E67506C634864722F3E223A22';
wwv_flow_imp.g_varchar2_table(796) := '22292B28226C697374223D3D3D652E696E7075743F223C773A64726F70446F776E4C6973743E222B652E6F7074696F6E732E6D61702866756E6374696F6E2865297B72657475726E273C773A6C6973744974656D20773A646973706C6179546578743D22';
wwv_flow_imp.g_varchar2_table(797) := '272B50742865292B272220773A76616C75653D22272B50742865292B27222F3E277D292E6A6F696E282222292B223C2F773A64726F70446F776E4C6973743E223A223C773A74657874222B28226D756C74696C696E65223D3D3D652E696E7075743F2720';
wwv_flow_imp.g_varchar2_table(798) := '773A6D756C74694C696E653D223122273A2222292B222F3E22292B223C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E222B722B537472696E67286C292E73706C6974282F5C723F5C6E2F292E6D61702866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(799) := '297B72657475726E273C773A7420786D6C3A73706163653D227072657365727665223E272B50742865292B223C2F773A743E227D292E6A6F696E28223C773A62722F3E22292B223C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E';
wwv_flow_imp.g_varchar2_table(800) := '227D28745B2B6E5D2C3165332B4E756D626572286E292C727C7C223C773A7250723E3C2F773A7250723E22297D293B6966286F213D3D742E6C656E677468297468726F77206E6577204572726F722822576F72643A206E6F207365207075646965726F6E';
wwv_flow_imp.g_varchar2_table(801) := '20636F6C6F63617220746F646F73206C6F732063616D706F732064656C20666F726D756C6172696F2028222B6F2B2220646520222B742E6C656E6774682B22292E22293B72657475726E20652E66696C652822776F72642F646F63756D656E742E786D6C';
wwv_flow_imp.g_varchar2_table(802) := '222C6C292C652E66696C652822776F72642F73657474696E67732E786D6C222C6B74286E5B315D2C7229292C652E67656E65726174654173796E63287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445';
wwv_flow_imp.g_varchar2_table(803) := '222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D297D297D297D66756E6374696F6E206A7428652C742C72297B766172206E3D77696E646F772E646F63782C6F3D4B652865292C613D652E706167657C7C7B7D2C6C3D5B5D2C';
wwv_flow_imp.g_varchar2_table(804) := '733D6D6528292C753D4D745B612E73697A657C7C226C6574746572225D7C7C4D742E6C65747465722C633D226C616E647363617065223D3D3D612E6F7269656E746174696F6E2C663D4D6174682E726F756E642835362E372A28612E6D617267696E7C7C';
wwv_flow_imp.g_varchar2_table(805) := '31322E3729292C643D28633F755B315D3A755B305D292D322A662C683D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C703D7B746F703A682C626F74746F6D3A682C6C656674';
wwv_flow_imp.g_varchar2_table(806) := '3A682C72696768743A682C696E73696465486F72697A6F6E74616C3A682C696E73696465566572746963616C3A687D2C673D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A22424643394434227D';
wwv_flow_imp.g_varchar2_table(807) := '2C6D3D7B746F703A672C626F74746F6D3A672C6C6566743A672C72696768743A672C696E73696465486F72697A6F6E74616C3A672C696E73696465566572746963616C3A677D3B66756E6374696F6E20762865297B69662821652972657475726E206D3B';
wwv_flow_imp.g_varchar2_table(808) := '76617220743D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A692865297D3B72657475726E7B746F703A742C626F74746F6D3A742C6C6566743A742C72696768743A742C696E73696465486F7269';
wwv_flow_imp.g_varchar2_table(809) := '7A6F6E74616C3A742C696E73696465566572746963616C3A747D7D76617220623D4D6174682E726F756E6428322A286F2E666F6E7453697A657C7C3729293B66756E6374696F6E207728652C74297B72657475726E20743D747C7C7B7D2C6E6577206E2E';
wwv_flow_imp.g_varchar2_table(810) := '5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C73697A653A742E73697A657C7C622C636F6C6F723A742E636F6C6F723F692874';
wwv_flow_imp.g_varchar2_table(811) := '2E636F6C6F72293A766F696420302C666F6E743A742E666F6E747C7C2243616C69627269227D297D66756E6374696F6E207928652C74297B72657475726E20743D747C7C7B7D2C6E6577206E2E506172616772617068287B6368696C6472656E3A5B7728';
wwv_flow_imp.g_varchar2_table(812) := '652C74295D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A227269676874223D3D3D742E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D742E616C6967';
wwv_flow_imp.g_varchar2_table(813) := '6E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546547D297D66756E6374696F6E207828652C74297B76617220723D766F69642030213D3D28743D747C7C7B7D292E7061643F742E7061643A33';
wwv_flow_imp.g_varchar2_table(814) := '303B72657475726E206E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B7928652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B746F703A722C626F74746F6D3A722C6C6566743A36302C72696768743A';
wwv_flow_imp.g_varchar2_table(815) := '36307D2C766572746963616C416C69676E3A742E6D6964646C657C7C226D6964646C65223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E43454E5445523A22626F74746F6D223D3D3D742E76616C69676E3F6E2E56657274696361';
wwv_flow_imp.g_varchar2_table(816) := '6C416C69676E2E424F54544F4D3A22746F70223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E544F503A766F696420302C73686164696E673A742E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C63';
wwv_flow_imp.g_varchar2_table(817) := '6F6C6F723A226175746F222C66696C6C3A6928742E66696C6C297D3A766F696420307D297D66756E6374696F6E205328297B72657475726E206E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72';
wwv_flow_imp.g_varchar2_table(818) := '653A36302C61667465723A36307D7D297D66756E6374696F6E204528652C742C72297B72657475726E206E6577206E2E506172616772617068287B6368696C6472656E3A5B7728652C7B626F6C643A742E626F6C642C73697A653A742E73697A653F4D61';
wwv_flow_imp.g_varchar2_table(819) := '74682E726F756E6428322A742E73697A65293A31342C636F6C6F723A742E636F6C6F727D295D2C73706163696E673A7B6265666F72653A302C61667465723A32307D2C616C69676E6D656E743A227269676874223D3D3D723F6E2E416C69676E6D656E74';
wwv_flow_imp.g_varchar2_table(820) := '547970652E52494748543A2263656E746572223D3D3D723F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C73686164696E673A742E66696C6C3F7B747970653A6E2E53686164696E675479';
wwv_flow_imp.g_varchar2_table(821) := '70652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928742E66696C6C297D3A766F696420307D297D66756E6374696F6E205428652C742C722C6F2C61297B72657475726E206E6577206E2E506172616772617068287B616C69676E6D65';
wwv_flow_imp.g_varchar2_table(822) := '6E743A227269676874223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E7454797065';
wwv_flow_imp.g_varchar2_table(823) := '2E4C4546542C73706163696E673A7B61667465723A766F69642030213D3D613F613A4D6174682E726F756E642835362E372A28766F69642030213D3D6F2E6761703F6F2E6761703A3329297D2C6368696C6472656E3A5B6E6577206E2E496D6167655275';
wwv_flow_imp.g_varchar2_table(824) := '6E287B747970653A226A7067223D3D3D652E6578743F226A7067223A22706E67222C646174613A652E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A74292C6865696768743A4D6174682E726F';
wwv_flow_imp.g_varchar2_table(825) := '756E6428332E37382A72297D7D295D7D297D76617220433D28633F755B315D3A755B305D292F35362E372C413D28633F755B305D3A755B315D292F35362E373B66756E6374696F6E207A2874297B76617220722C6F3D787428652C74293B696628216F29';
wwv_flow_imp.g_varchar2_table(826) := '72657475726E206E756C6C3B7472797B723D66756E6374696F6E28652C742C72297B766172206E3D372E35362C6F3D6374284D6174682E726F756E6428742A6E292C4D6174682E726F756E6428722A6E29292C613D6F2E676574436F6E74657874282232';
wwv_flow_imp.g_varchar2_table(827) := '6422292C6C3D2248656C7665746963612C20417269616C2C2073616E732D7365726966223B612E666F6E743D22626F6C64203236362E37313638707820222B6C3B76617220693D537428652C612E6D6561737572655465787428652E74657874292E7769';
wwv_flow_imp.g_varchar2_table(828) := '6474682F6E2C742C72293B612E666F6E743D22626F6C6420222B2E333532382A692A6E2B22707820222B6C2C612E7472616E736C617465286F2E77696474682F322C6F2E6865696768742F32292C612E726F74617465282D652E616E676C652A4D617468';
wwv_flow_imp.g_varchar2_table(829) := '2E50492F313830292C612E676C6F62616C416C7068613D652E6F7061636974792C612E66696C6C5374796C653D652E636F6C6F722C612E74657874416C69676E3D2263656E746572222C612E74657874426173656C696E653D226D6964646C65222C612E';
wwv_flow_imp.g_varchar2_table(830) := '66696C6C5465787428652E746578742C302C30293B76617220733D7574286F2E746F4461746155524C2822696D6167652F706E6722292C6F2E77696474682C6F2E686569676874293B72657475726E20732E776D6D3D742C732E686D6D3D722C737D286F';
wwv_flow_imp.g_varchar2_table(831) := '2C432C41297D63617463682865297B72657475726E206E756C6C7D72657475726E206E6577206E2E486561646572287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B6E6577206E2E496D61676552756E28';
wwv_flow_imp.g_varchar2_table(832) := '7B747970653A22706E67222C646174613A722E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A43292C6865696768743A4D6174682E726F756E6428332E37382A41297D2C666C6F6174696E673A';
wwv_flow_imp.g_varchar2_table(833) := '7B686F72697A6F6E74616C506F736974696F6E3A7B72656C61746976653A6E2E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6E2E486F72697A6F6E74616C506F736974696F6E416C69676E2E';
wwv_flow_imp.g_varchar2_table(834) := '43454E5445527D2C766572746963616C506F736974696F6E3A7B72656C61746976653A6E2E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6E2E566572746963616C506F736974696F6E416C69676E';
wwv_flow_imp.g_varchar2_table(835) := '2E43454E5445527D2C626568696E64446F63756D656E743A21302C616C6C6F774F7665726C61703A21302C777261703A7B747970653A6E2E546578745772617070696E67547970652E4E4F4E457D7D7D295D7D295D7D297D766172204D3D742E6D617028';
wwv_flow_imp.g_varchar2_table(836) := '66756E6374696F6E28722C61297B76617220683D5B5D2C673D742E6C656E6774683E313F225F222B28612B31293A22223B486528652C22646F6378222C72292E666F72456163682866756E6374696F6E20742861297B76617220753D612E747970653B69';
wwv_flow_imp.g_varchar2_table(837) := '662822636F6C756D6E6173223D3D3D75297B76617220633D5A6528612C22646F6378222C722C642F35362E37293B69662821632E6C656E6774682972657475726E3B76617220663D682C6D3D642C433D4D6174682E726F756E642835362E372A28766F69';
wwv_flow_imp.g_varchar2_table(838) := '642030213D3D612E636F6C4761703F4E756D62657228612E636F6C476170293A3429292C413D5B5D2C7A3D5B5D3B72657475726E20632E666F72456163682866756E6374696F6E28652C72297B766172206F3D723D3D3D632E6C656E6774682D312C613D';
wwv_flow_imp.g_varchar2_table(839) := '4D6174682E726F756E642835362E372A652E77293B683D5B5D2C643D612C652E736563732E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774682D315D696E7374616E63656F66206E2E5061726167726170687C7C682E707573';
wwv_flow_imp.g_varchar2_table(840) := '68287928222229292C412E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A682C77696474683A7B73697A653A612B286F3F303A43292C747970653A6E2E5769647468547970652E4458417D2C6D617267696E733A7B746F70';
wwv_flow_imp.g_varchar2_table(841) := '3A302C626F74746F6D3A302C6C6566743A302C72696768743A6F3F303A437D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E544F507D29292C7A2E7075736828612B286F3F303A4329297D292C643D6D2C766F696428683D';
wwv_flow_imp.g_varchar2_table(842) := '66292E70757368286E6577206E2E5461626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A417D295D2C77696474683A7B73697A653A642C747970653A6E2E576964746854797065';
wwv_flow_imp.g_varchar2_table(843) := '2E4458417D2C636F6C756D6E5769647468733A7A2C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D69662822677275706F223D3D3D75297B766172204D3D722C463D672C4C3D68';
wwv_flow_imp.g_varchar2_table(844) := '2C473D642C573D4D6174682E726F756E642835362E372A28766F69642030213D3D612E70616464696E673F4E756D62657228612E70616464696E67293A612E626F726465727C7C612E66696C6C3F333A3029292C243D612E626F726465723F7628612E62';
wwv_flow_imp.g_varchar2_table(845) := '6F72646572436F6C6F727C7C7A65293A703B72657475726E20586528612C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C673D462B652E7375663B766172206C3D716528612C22646F6378222C72293B6966286C2E6C656E';
wwv_flow_imp.g_varchar2_table(846) := '6774687C7C612E7469746C65297B683D5B5D2C643D4D6174682E6D6178283630302C472D322A57292C6C2E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774682D315D696E7374616E63656F66206E2E5061726167726170687C';
wwv_flow_imp.g_varchar2_table(847) := '7C682E70757368287928222229293B76617220733D5B5D3B612E7469746C652626732E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B78284E28612E7469746C652C72292C7B626F6C643A';
wwv_flow_imp.g_varchar2_table(848) := '21302C73697A653A4D6174682E726F756E6428322A28612E7469746C6553697A657C7C286F2E666F6E7453697A657C7C37292B3229292C636F6C6F723A612E7469746C65436F6C6F727C7C6F2E68656164546578742C66696C6C3A612E7469746C654669';
wwv_flow_imp.g_varchar2_table(849) := '6C6C7C7C6F2E7072696D6172792C7061643A36307D295D7D29292C732E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A2131213D3D612E6B656570546F6765746865722C6368696C6472656E3A5B6E6577206E2E5461626C';
wwv_flow_imp.g_varchar2_table(850) := '6543656C6C287B6368696C6472656E3A682C6D617267696E733A7B746F703A572C626F74746F6D3A572C6C6566743A572C72696768743A577D2C73686164696E673A612E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C63';
wwv_flow_imp.g_varchar2_table(851) := '6F6C6F723A226175746F222C66696C6C3A6928612E66696C6C297D3A766F696420307D295D7D29292C643D472C28683D4C292E70757368286E6577206E2E5461626C65287B726F77733A732C77696474683A7B73697A653A642C747970653A6E2E576964';
wwv_flow_imp.g_varchar2_table(852) := '7468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A242C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D7D292C683D4C2C643D472C723D4D2C766F696428673D46';
wwv_flow_imp.g_varchar2_table(853) := '297D69662822686561646572223D3D3D75297B76617220593D576528612C6F292C713D612E666F6E743F592E666F6E745B315D3A766F696420302C583D5B6E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78284E28612E7469746C652C';
wwv_flow_imp.g_varchar2_table(854) := '72292C7B626F6C643A21302C73697A653A4D6174682E726F756E6428322A592E73697A65292C636F6C6F723A592E636F6C6F722C66696C6C3A592E66696C6C2C666F6E743A717D292C78284E28612E72696768742C72292C7B73697A653A4D6174682E72';
wwv_flow_imp.g_varchar2_table(855) := '6F756E6428322A592E726967687453697A65292C636F6C6F723A592E636F6C6F722C66696C6C3A592E66696C6C2C616C69676E3A227269676874222C666F6E743A712C6D6964646C653A2121612E726967687453697A657D295D7D295D3B612E73756274';
wwv_flow_imp.g_varchar2_table(856) := '69746C652626582E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78284E28612E7375627469746C652C72292C7B73697A653A4D6174682E726F756E6428322A592E73756253697A65292C636F6C6F723A592E636F6C6F72';
wwv_flow_imp.g_varchar2_table(857) := '2C66696C6C3A592E66696C6C2C7370616E3A322C666F6E743A717D295D7D29292C682E70757368286E6577206E2E5461626C65287B726F77733A582C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C75';
wwv_flow_imp.g_varchar2_table(858) := '6D6E5769647468733A5B4D6174682E726F756E64282E372A64292C4D6174682E726F756E64282E332A64295D2C626F72646572733A707D292C532829297D656C73652069662822746578746F223D3D3D75297B766172205A3D7B72696768743A6E2E416C';
wwv_flow_imp.g_varchar2_table(859) := '69676E6D656E74547970652E52494748542C63656E7465723A6E2E416C69676E6D656E74547970652E43454E5445522C6A7573746966793A6E2E416C69676E6D656E74547970652E4A55535449464945447D3B4428612C72292E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(860) := '6E6374696F6E2874297B682E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A5A5B612E616C69676E5D7C7C6E2E416C69676E6D656E74547970652E4C4546542C696E64656E743A612E696E64656E743F7B6C6566743A4D';
wwv_flow_imp.g_varchar2_table(861) := '6174682E726F756E642835362E372A612E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A766F69642030213D3D612E7061726167726170684761703F4D6174682E726F756E642835362E372A612E70617261677261706847';
wwv_flow_imp.g_varchar2_table(862) := '6170293A3132302C6C696E653A4D6174682E726F756E64283234302A28612E6C696E654865696768747C7C312E313529297D2C6368696C6472656E3A5228742C7B666F6E743A612E666F6E747C7C652E706167652626652E706167652E666F6E742C636F';
wwv_flow_imp.g_varchar2_table(863) := '6C6F723A612E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E206E6577206E2E5465787452756E287B746578743A652E742C626F6C643A212821652E62262621612E626F6C64292C6974616C6963733A212821652E69262621';
wwv_flow_imp.g_varchar2_table(864) := '612E6974616C6963292C73697A653A322A28612E73697A657C7C3130292C756E6465726C696E653A652E753F7B7D3A766F696420302C737472696B653A2121652E732C636F6C6F723A652E633F6928652E63293A766F696420302C666F6E743A495B652E';
wwv_flow_imp.g_varchar2_table(865) := '665D5B315D7D297D297D29297D297D656C736520696628226573706163696F223D3D3D7529682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E642835';
wwv_flow_imp.g_varchar2_table(866) := '362E372A28612E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D75297B696628766F696420303D3D3D612E7831297B766172204A3D4D6174682E726F756E642835362E372A28612E77696474687C7C3029292C513D';
wwv_flow_imp.g_varchar2_table(867) := '4A3F4D6174682E6D617828302C4D6174682E726F756E642828642D4A292F3229293A303B682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E64283536';
wwv_flow_imp.g_varchar2_table(868) := '2E372A28766F69642030213D3D612E6761703F612E6761703A3229297D2C696E64656E743A2263656E746572223D3D3D612E616C69676E3F7B6C6566743A512C72696768743A517D3A227269676874223D3D3D612E616C69676E3F7B6C6566743A322A51';
wwv_flow_imp.g_varchar2_table(869) := '7D3A7B72696768743A322A517D2C626F726465723A7B626F74746F6D3A7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A4D6174682E6D617828322C4D6174682E726F756E642832302A28612E746869636B6E6573737C';
wwv_flow_imp.g_varchar2_table(870) := '7C2E332929292C636F6C6F723A6928612E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C73652069662822696D6167656E223D3D3D75297B7661722065653D6C7428612C72293B6966286565297B7661722074653D';
wwv_flow_imp.g_varchar2_table(871) := '697428612C6565293B682E7075736828542865652C74652E772C74652E682C6129297D7D656C736520696628226772616669636F223D3D3D75297B7661722072653D797428612C722C6F293B72652626682E7075736828542872652C72652E776D6D2C72';
wwv_flow_imp.g_varchar2_table(872) := '652E686D6D2C6129297D656C73652069662822636F6469676F223D3D3D75297B7661722061653D767428612C72293B6966286165297B7661722063653D6274286165293B682E7075736828542863652C63652E776D6D2C63652E686D6D2C612C61652E6C';
wwv_flow_imp.g_varchar2_table(873) := '6162656C3F303A766F6964203029292C61652E6C6162656C2626682E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A227269676874223D3D3D612E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A';
wwv_flow_imp.g_varchar2_table(874) := '2263656E746572223D3D3D612E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C696E64656E743A227269676874223D3D3D612E616C69676E7C7C2263656E746572223D3D3D';
wwv_flow_imp.g_varchar2_table(875) := '612E616C69676E3F766F696420303A7B6C6566743A4D6174682E6D617828302C4D6174682E726F756E64282863652E776D6D2D61652E746578742E6C656E6774682A61652E7465787453697A652A2E333532382A2E36292F322A35362E3729297D2C7370';
wwv_flow_imp.g_varchar2_table(876) := '6163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3329297D2C6368696C6472656E3A5B6E6577206E2E5465787452756E287B746578743A61652E746578742C666F6E743A22';
wwv_flow_imp.g_varchar2_table(877) := '436F7572696572204E6577222C73697A653A322A61652E7465787453697A652C636F6C6F723A692861652E636F6C6F72297D295D7D29297D7D656C7365206966282273616C746F223D3D3D7529682E70757368286E6577206E2E50617261677261706828';
wwv_flow_imp.g_varchar2_table(878) := '7B6368696C6472656E3A5B6E6577206E2E50616765427265616B5D7D29293B656C736520696628226669636861223D3D3D75297B7661722068653D6B28612C72295B305D7C7C7B7D2C70653D612E636F6C756D6E737C7C332C67653D5B5D2C6D653D5B5D';
wwv_flow_imp.g_varchar2_table(879) := '3B69662846652828612E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5028652E7768656E2C722C6865297D292C7065292E666F72456163682866756E6374696F6E2865297B652E66';
wwv_flow_imp.g_varchar2_table(880) := '6F72456163682866756E6374696F6E2865297B76617220743D652E662C6F3D2121612E677269642C6C3D6F3F36303A766F696420303B696628652E656D707479297B76617220733D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C7369';
wwv_flow_imp.g_varchar2_table(881) := '7A653A302C636F6C6F723A22464646464646227D3B6D652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A32';
wwv_flow_imp.g_varchar2_table(882) := '2A652E7370616E2C626F72646572733A6F3F7B746F703A732C626F74746F6D3A732C6C6566743A732C72696768743A737D3A766F696420307D29297D656C73657B76617220752C633D496528742C61292C663D4E28742E6C6162656C2C722C6865293B69';
wwv_flow_imp.g_varchar2_table(883) := '6628226C65667422213D3D632E706F73297B76617220643D4F6528742C722C6865292C683D5B5D2C703D6F3F36303A33303B72657475726E22746F70223D3D3D632E706F732626682E70757368284528526528662C63292C632C632E616C69676E7C7C64';
wwv_flow_imp.g_varchar2_table(884) := '2626642E616C69676E7C7C226C6566742229292C682E70757368287928756528742C722C6865292C7B73697A653A31372C636F6C6F723A642626642E636F6C6F727C7C612E76616C7565436F6C6F722C626F6C643A643F642E626F6C643A766F69642030';
wwv_flow_imp.g_varchar2_table(885) := '2C616C69676E3A643F642E616C69676E3A766F696420307D29292C766F6964206D652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A682C636F6C756D6E5370616E3A322A652E7370616E2C6D617267696E733A7B746F70';
wwv_flow_imp.g_varchar2_table(886) := '3A702C626F74746F6D3A702C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A6F3F6E2E566572746963616C416C69676E2E43454E5445523A766F696420302C73686164696E673A642626642E66696C6C3F7B747970653A';
wwv_flow_imp.g_varchar2_table(887) := '6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928642E66696C6C297D3A766F696420307D29297D6D652E70757368287828526528662C63292C632E7374796C65643F7B626F6C643A632E626F6C642C73';
wwv_flow_imp.g_varchar2_table(888) := '697A653A632E73697A653F4D6174682E726F756E6428322A632E73697A65293A31372C66696C6C3A632E66696C6C2C636F6C6F723A632E636F6C6F722C616C69676E3A632E616C69676E2C7061643A6C2C6D6964646C653A6F7D3A7B626F6C643A21302C';
wwv_flow_imp.g_varchar2_table(889) := '73697A653A31372C66696C6C3A612E6C6162656C46696C6C2C636F6C6F723A612E6C6162656C436F6C6F722C7061643A6C2C6D6964646C653A6F7D292C28753D4F6528742C722C6865292C7828756528742C722C6865292C7B73697A653A31372C636F6C';
wwv_flow_imp.g_varchar2_table(890) := '6F723A752626752E636F6C6F727C7C612E76616C7565436F6C6F722C7061643A6C2C6D6964646C653A6F2C626F6C643A753F752E626F6C643A766F696420302C616C69676E3A753F752E616C69676E3A766F696420302C66696C6C3A753F752E66696C6C';
wwv_flow_imp.g_varchar2_table(891) := '3A766F696420302C7370616E3A652E7370616E3E313F322A652E7370616E2D313A766F696420307D2929297D7D293B666F722876617220743D322A6B652865293B743C322A70653B742B2B296D652E70757368287828222229293B67652E70757368286E';
wwv_flow_imp.g_varchar2_table(892) := '6577206E2E5461626C65526F77287B6368696C6472656E3A6D657D29292C6D653D5B5D7D292C67652E6C656E677468297B7661722062653D5B5D3B696628612E677269647C7C41727261792E6973417272617928612E6C6162656C57696474687329297B';
wwv_flow_imp.g_varchar2_table(893) := '666F72287661722077653D5B5D2C79653D302C78653D303B78653C70653B78652B2B2977652E70757368284D6174682E726F756E642835362E372A4D6528612C78652929292C79652B3D77655B78655D3B7661722053653D4D6174682E6D617828363030';
wwv_flow_imp.g_varchar2_table(894) := '2C4D6174682E726F756E642828642D7965292F706529293B666F722878653D303B78653C70653B78652B2B2962652E707573682877655B78655D2C5365297D656C736520666F72287661722045653D303B45653C322A70653B45652B2B2962652E707573';
wwv_flow_imp.g_varchar2_table(895) := '68284D6174682E726F756E6428642F28322A70652929293B682E70757368286E6577206E2E5461626C65287B726F77733A67652C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E576964746873';
wwv_flow_imp.g_varchar2_table(896) := '3A62652C626F72646572733A612E677269643F7628612E626F72646572436F6C6F727C7C7A65293A702C6C61796F75743A612E677269643F6E2E5461626C654C61796F7574547970652E46495845443A766F696420307D292C532829297D7D656C736520';
wwv_flow_imp.g_varchar2_table(897) := '696628227461726A65746173223D3D3D75297B7661722054653D246528612C722C6F293B6966282154652E6974656D732E6C656E6774682972657475726E3B666F72287661722043653D4D6174682E726F756E642835362E372A54652E63617264476170';
wwv_flow_imp.g_varchar2_table(898) := '292C41653D4D6174682E666C6F6F722828642D43652A2854652E6E2D3129292F54652E6E292C50653D5B5D2C6A653D5B5D2C4C653D303B4C653C54652E6E3B4C652B2B294C6526266A652E70757368284365292C6A652E70757368284165293B666F7228';
wwv_flow_imp.g_varchar2_table(899) := '7661722044653D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C55653D303B55653C54652E6974656D732E6C656E6774683B55652B3D54652E6E297B666F7228766172204265';
wwv_flow_imp.g_varchar2_table(900) := '3D5B5D2C47653D303B47653C54652E6E3B47652B2B297B766172205F653D54652E6974656D735B55652B47655D3B4765262642652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F72646572733A';
wwv_flow_imp.g_varchar2_table(901) := '7B746F703A44652C626F74746F6D3A44652C6C6566743A44652C72696768743A44657D7D29292C5F653F42652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79285F652E6C6162656C2C7B73697A653A322A54652E6C';
wwv_flow_imp.g_varchar2_table(902) := '6162656C53697A652C636F6C6F723A54652E6C6162656C436F6C6F727D292C6E6577206E2E506172616772617068287B6368696C6472656E3A5B77285F652E76616C75652C7B626F6C643A21302C73697A653A322A54652E73697A652C636F6C6F723A5F';
wwv_flow_imp.g_varchar2_table(903) := '652E636F6C6F727C7C54652E76616C7565436F6C6F727D295D2C73706163696E673A7B6265666F72653A34302C61667465723A307D7D295D2C6D617267696E733A7B746F703A3130302C626F74746F6D3A3130302C6C6566743A3136302C72696768743A';
wwv_flow_imp.g_varchar2_table(904) := '3130307D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E43454E5445522C73686164696E673A7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A692854652E66';
wwv_flow_imp.g_varchar2_table(905) := '696C6C297D2C626F72646572733A7B746F703A44652C626F74746F6D3A44652C72696768743A44652C6C6566743A54652E616363656E743F7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A32342C636F6C6F723A6928';
wwv_flow_imp.g_varchar2_table(906) := '54652E616363656E74297D3A44657D7D29293A42652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F72646572733A7B746F703A44652C626F74746F6D3A44652C6C6566743A44652C7269676874';
wwv_flow_imp.g_varchar2_table(907) := '3A44657D7D29297D50652E6C656E677468262650652E70757368286E6577206E2E5461626C65526F77287B6865696768743A7B76616C75653A43652C72756C653A6E2E48656967687452756C652E45584143547D2C6368696C6472656E3A6A652E6D6170';
wwv_flow_imp.g_varchar2_table(908) := '2866756E6374696F6E28297B72657475726E206E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F72646572733A7B746F703A44652C626F74746F6D3A44652C6C6566743A44652C72696768743A44657D7D297D29';
wwv_flow_imp.g_varchar2_table(909) := '7D29292C50652E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A42657D29297D682E70757368286E6577206E2E5461626C65287B726F77733A50652C77696474683A7B73697A653A642C7479';
wwv_flow_imp.g_varchar2_table(910) := '70653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A6A652C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D656C73652069662822666F726D756C61';
wwv_flow_imp.g_varchar2_table(911) := '72696F223D3D3D75297B7661722048653D612E636F6C756D6E737C7C322C56653D5B5D2C59653D5B5D2C4A653D312C4B653D766528612C722C67292C51653D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A342C636F';
wwv_flow_imp.g_varchar2_table(912) := '6C6F723A69286465297D3B6966284665284B652C4865292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E6374696F6E2865297B76617220743D652E663B696628652E656D7074792959652E70757368286E6577206E';
wwv_flow_imp.g_varchar2_table(913) := '2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A322A652E7370616E7D29293B656C73657B7328742E6E616D65293B76617220723D6C2E';
wwv_flow_imp.g_varchar2_table(914) := '6C656E6774683B6C2E707573682874292C4A653D4D6174682E6D6178284A652C742E6C696E6573293B766172206F3D742E6C696E65733E313F6E2E566572746963616C416C69676E2E544F503A6E2E566572746963616C416C69676E2E43454E5445522C';
wwv_flow_imp.g_varchar2_table(915) := '613D742E6C61623B696628226C65667422213D3D612E706F73297B76617220753D6E6577206E2E5461626C65287B77696474683A7B73697A653A3130302C747970653A6E2E5769647468547970652E50455243454E544147457D2C626F72646572733A70';
wwv_flow_imp.g_varchar2_table(916) := '2C726F77733A5B6E6577206E2E5461626C65526F77287B6865696768743A742E6C696E65733E313F7B76616C75653A4D6174682E726F756E64283233302A742E6C696E65732B3630292C72756C653A6E2E48656967687452756C652E41544C454153547D';
wwv_flow_imp.g_varchar2_table(917) := '3A766F696420302C6368696C6472656E3A5B6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B772846742B722B22E29FA7222C7B73697A653A31377D295D2C737061';
wwv_flow_imp.g_varchar2_table(918) := '63696E673A7B6265666F72653A302C61667465723A307D7D295D2C766572746963616C416C69676E3A6F2C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A';
wwv_flow_imp.g_varchar2_table(919) := '51652C626F74746F6D3A51652C6C6566743A51652C72696768743A51657D2C73686164696E673A7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A69286665297D7D295D7D295D7D292C633D';
wwv_flow_imp.g_varchar2_table(920) := '22746F70223D3D3D612E706F733F5B4528526528742E6C6162656C2C61292C612C612E616C69676E7C7C226C65667422295D3A5B5D3B72657475726E20632E7075736828752C6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73';
wwv_flow_imp.g_varchar2_table(921) := '706163696E673A7B6265666F72653A302C61667465723A302C6C696E653A3132302C6C696E6552756C653A6E2E4C696E6552756C65547970652E45584143547D7D29292C766F69642059652E70757368286E6577206E2E5461626C6543656C6C287B6368';
wwv_flow_imp.g_varchar2_table(922) := '696C6472656E3A632C636F6C756D6E5370616E3A322A652E7370616E2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E544F502C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C726967';
wwv_flow_imp.g_varchar2_table(923) := '68743A36307D7D29297D59652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B612E7374796C65643F7928526528742E6C6162656C2C61292C7B626F6C643A612E626F6C642C73697A653A612E73697A653F4D6174682E';
wwv_flow_imp.g_varchar2_table(924) := '726F756E6428322A612E73697A65293A31372C636F6C6F723A612E636F6C6F722C616C69676E3A612E616C69676E7D293A7928742E6C6162656C2C7B626F6C643A21302C73697A653A31377D295D2C766572746963616C416C69676E3A6F2C7368616469';
wwv_flow_imp.g_varchar2_table(925) := '6E673A612E7374796C65642626612E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928612E66696C6C297D3A766F696420302C6D617267696E733A7B746F703A33302C626F';
wwv_flow_imp.g_varchar2_table(926) := '74746F6D3A33302C6C6566743A36302C72696768743A36307D7D292C6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B772846742B722B22E29FA7222C7B73697A65';
wwv_flow_imp.g_varchar2_table(927) := '3A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C636F6C756D6E5370616E3A652E7370616E3E313F322A652E7370616E2D313A766F696420302C766572746963616C416C69676E3A6F2C6D617267696E733A7B';
wwv_flow_imp.g_varchar2_table(928) := '746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A51652C626F74746F6D3A51652C6C6566743A51652C72696768743A51657D2C73686164696E673A7B747970653A6E2E5368616469';
wwv_flow_imp.g_varchar2_table(929) := '6E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A69286665297D7D29297D7D293B666F722876617220743D322A6B652865293B743C322A48653B742B2B2959652E70757368287828222229293B56652E70757368286E657720';
wwv_flow_imp.g_varchar2_table(930) := '6E2E5461626C65526F77287B6368696C6472656E3A59652C63616E7453706C69743A21302C6865696768743A4A653E313F7B76616C75653A4D6174682E726F756E64283233302A4A652B313230292C72756C653A6E2E48656967687452756C652E41544C';
wwv_flow_imp.g_varchar2_table(931) := '454153547D3A766F696420307D29292C59653D5B5D2C4A653D317D292C56652E6C656E677468297B7661722065743D5B5D2C74743D4D6174682E726F756E642835362E372A28612E6C6162656C57696474687C7C333229292C72743D4D6174682E6D6178';
wwv_flow_imp.g_varchar2_table(932) := '283630302C4D6174682E726F756E642828642D74742A4865292F486529293B74742A48652B3630302A48653E6426262874743D72743D4D6174682E726F756E6428642F28322A48652929293B666F7228766172206E743D303B6E743C48653B6E742B2B29';
wwv_flow_imp.g_varchar2_table(933) := '65742E707573682874742C7274293B682E70757368286E6577206E2E5461626C65287B726F77733A56652C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A65742C626F726465';
wwv_flow_imp.g_varchar2_table(934) := '72733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D7D656C73652069662822616C65727461223D3D3D75296B28612C72292E66696C7465722866756E6374696F6E2865297B72657475726E205028';
wwv_flow_imp.g_varchar2_table(935) := '612E7768656E2C722C65297D292E736C69636528302C612E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B682E70757368286E6577206E2E5461626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B6368';
wwv_flow_imp.g_varchar2_table(936) := '696C6472656E3A5B78284E28612E746578742C722C65292C7B626F6C643A21302C73697A653A31372C66696C6C3A4F28612E636F6C6F722C722C65297C7C2223453645434632227D295D7D295D2C77696474683A7B73697A653A642C747970653A6E2E57';
wwv_flow_imp.g_varchar2_table(937) := '69647468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A707D292C532829297D293B656C736520696628227461626C61223D3D3D75297B766172206F743D6B28612C72293B696628216F742E6C656E6774682626';
wwv_flow_imp.g_varchar2_table(938) := '2131213D3D612E68696465456D707479262621612E656D707479546578742972657475726E3B7661722061743D5528612C722C6F74292C73743D5B5D3B612E7469746C65262673742E70757368286E6577206E2E5461626C65526F77287B7461626C6548';
wwv_flow_imp.g_varchar2_table(939) := '65616465723A21302C6368696C6472656E3A5B78284E28612E7469746C652C72292C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C7370616E3A61742E6C656E6774682C73697A653A622B327D29';
wwv_flow_imp.g_varchar2_table(940) := '5D7D29292C612E67726F757073262673742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A4228612C6174292E6D61702866756E6374696F6E2865297B72657475726E207828652E6C61';
wwv_flow_imp.g_varchar2_table(941) := '62656C7C7C22222C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A2263656E746572222C7370616E3A652E636F6C737D297D297D29292C73742E70757368286E6577206E2E546162';
wwv_flow_imp.g_varchar2_table(942) := '6C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A61742E6D61702866756E6374696F6E2865297B72657475726E207828652E6C6162656C2C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E';
wwv_flow_imp.g_varchar2_table(943) := '7072696D6172792C616C69676E3A4E6528652C61297D297D297D29292C6F742E6C656E6774687C7C73742E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78284E28612E656D707479546578742C72292C7B6974616C6963';
wwv_flow_imp.g_varchar2_table(944) := '3A21302C7370616E3A61742E6C656E6774687D295D7D29293B7661722075743D6C652861292C63743D7B7D2C66743D4828612C6174292C64743D66756E6374696F6E2865297B76617220743D7828652E746578742C7B626F6C643A21302C616C69676E3A';
wwv_flow_imp.g_varchar2_table(945) := '226C656674222C66696C6C3A6F2E746F74616C732C7370616E3A652E61747C7C61742E6C656E6774682C636F6C6F723A612E746F74616C73436F6C6F727D292C723D652E63656C6C732E736C69636528652E6174292E6D61702866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(946) := '297B72657475726E207828652C7B626F6C643A21302C616C69676E3A227269676874222C66696C6C3A6F2E746F74616C732C636F6C6F723A612E746F74616C73436F6C6F727D297D293B72657475726E20303D3D3D652E61743F5B6E6577206E2E546162';
wwv_flow_imp.g_varchar2_table(947) := '6C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D7D292C6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A727D295D3A5B6E6577206E2E5461626C65526F77287B63616E7453';
wwv_flow_imp.g_varchar2_table(948) := '706C69743A21302C6368696C6472656E3A5B745D2E636F6E6361742872297D295D7D3B696528612C6F74292E666F72456163682866756E6374696F6E2865297B696628226865616422213D3D652E6B296966282273756222213D3D652E6B297B76617220';
wwv_flow_imp.g_varchar2_table(949) := '743D652E722C6C3D652E692C733D6A28612E726F775374796C652C722C74293B73742E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A61742E6D61702866756E6374696F6E28652C75297B76';
wwv_flow_imp.g_varchar2_table(950) := '617220633D6A28652E63656C6C5374796C652C722C74297C7C737C7C7B7D3B696628652E63656C6C297B76617220663D5628652C742C722C6F292C643D632E66696C6C7C7C286C25323D3D3126262131213D3D612E7A656272613F6F2E7A656272613A6E';
wwv_flow_imp.g_varchar2_table(951) := '756C6C293B6626262863745B755D3D4D6174682E6D61782863745B755D7C7C302C662E7729293B76617220683D652E76616C69676E7C7C66743B72657475726E206E6577206E2E5461626C6543656C6C287B766572746963616C416C69676E3A22746F70';
wwv_flow_imp.g_varchar2_table(952) := '223D3D3D683F6E2E566572746963616C416C69676E2E544F503A22626F74746F6D223D3D3D683F6E2E566572746963616C416C69676E2E424F54544F4D3A6E2E566572746963616C416C69676E2E43454E5445522C6D617267696E733A7B746F703A3330';
wwv_flow_imp.g_varchar2_table(953) := '2C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A643F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A692864297D3A766F696420302C6368696C';
wwv_flow_imp.g_varchar2_table(954) := '6472656E3A5B6E6577206E2E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A227269676874223D3D3D652E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A';
wwv_flow_imp.g_varchar2_table(955) := '226C656674223D3D3D652E616C69676E3F6E2E416C69676E6D656E74547970652E4C4546543A6E2E416C69676E6D656E74547970652E43454E5445522C6368696C6472656E3A663F5B6E6577206E2E496D61676552756E287B747970653A226A7067223D';
wwv_flow_imp.g_varchar2_table(956) := '3D3D662E696D2E6578743F226A7067223A22706E67222C646174613A662E696D2E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A662E77292C6865696768743A4D6174682E726F756E6428332E';
wwv_flow_imp.g_varchar2_table(957) := '37382A662E68297D7D295D3A5B5D7D295D7D297D72657475726E2078285F28652C742C72292C7B76616C69676E3A652E76616C69676E7C7C66742C616C69676E3A652E616C69676E2C626F6C643A652E626F6C647C7C632E626F6C642C636F6C6F723A63';
wwv_flow_imp.g_varchar2_table(958) := '2E636F6C6F727C7C652E636F6C6F722C66696C6C3A632E66696C6C7C7C286C25323D3D3126262131213D3D612E7A656272613F6F2E7A656272613A6E756C6C297D297D297D29297D656C7365206474286E652861742C75742C652E726F77732C73652861';
wwv_flow_imp.g_varchar2_table(959) := '2C652C722929292E666F72456163682866756E6374696F6E2865297B73742E707573682865297D293B656C73652073742E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B7828736528612C';
wwv_flow_imp.g_varchar2_table(960) := '652C72292C7B626F6C643A21302C66696C6C3A6F2E67726F75702C7370616E3A61742E6C656E6774687D295D7D29297D292C4B28612E746F74616C73292E6C656E67746826266F742E6C656E67746826266474286E652861742C4B28612E746F74616C73';
wwv_flow_imp.g_varchar2_table(961) := '292C6F742C6F6528612C722C6F742929292E666F72456163682866756E6374696F6E2865297B73742E707573682865297D293B7661722068743D61742E6D61702866756E6374696F6E28652C74297B72657475726E20652E77696474683F652E77696474';
wwv_flow_imp.g_varchar2_table(962) := '682F32303A63745B745D3F4D6174682E6D617828312C2863745B745D2B34292F3230293A317D292C70743D68742E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C67743D68742E6D61702866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(963) := '2865297B72657475726E204D6174682E666C6F6F7228642A652F7074297D293B682E70757368286E6577206E2E5461626C65287B726F77733A73742C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C75';
wwv_flow_imp.g_varchar2_table(964) := '6D6E5769647468733A67742C626F72646572733A21313D3D3D612E677269643F703A7628612E677269643F612E626F72646572436F6C6F727C7C7A653A6E756C6C297D292C532829297D7D293B766172206D3D652E666F6F7465722C433D7A2872293B72';
wwv_flow_imp.g_varchar2_table(965) := '657475726E7B686561646572733A433F7B64656661756C743A437D3A766F696420302C70726F706572746965733A7B706167653A7B73697A653A7B77696474683A755B305D2C6865696768743A755B315D2C6F7269656E746174696F6E3A633F6E2E5061';
wwv_flow_imp.g_varchar2_table(966) := '67654F7269656E746174696F6E2E4C414E4453434150453A6E2E506167654F7269656E746174696F6E2E504F5254524149547D2C6D617267696E3A7B746F703A662C626F74746F6D3A662C6C6566743A662C72696768743A667D7D7D2C666F6F74657273';
wwv_flow_imp.g_varchar2_table(967) := '3A6D3F7B64656661756C743A6E6577206E2E466F6F746572287B6368696C6472656E3A4E74286D2C722C6F297D297D3A766F696420302C6368696C6472656E3A682E6C656E6774683F683A5B79282222295D7D7D292C463D6E6577206E2E446F63756D65';
wwv_flow_imp.g_varchar2_table(968) := '6E74287B63726561746F723A226E6F76615265706F7274222C7469746C653A4E28652E7469746C657C7C22222C745B305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A4D7D292C4C3D6E2E5061636B65722E746F426C6F623F6E2E506163';
wwv_flow_imp.g_varchar2_table(969) := '6B65722E746F426C6F622846292E7468656E2866756E6374696F6E2865297B72657475726E20652E61727261794275666665723F652E617272617942756666657228293A657D293A6E2E5061636B65722E746F4275666665722846293B72657475726E20';
wwv_flow_imp.g_varchar2_table(970) := '6C2E6C656E6774683F4C2E7468656E2866756E6374696F6E2874297B72657475726E204F7428742C6C2C626528652C7229297D293A4C7D7661722049743D7B7D3B66756E6374696F6E204C742865297B76617220743D652E73706C697428227C22292C72';
wwv_flow_imp.g_varchar2_table(971) := '3D745B305D2E7472696D28292C6E3D745B315D3F745B315D2E7472696D28293A6E756C6C3B72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E223D3D3D722972657475726E20653B666F7228766172206F3D722E73706C697428';
wwv_flow_imp.g_varchar2_table(972) := '222E22292C613D742626742E73636F70654C6973743F742E73636F70654C6973742E736C69636528292E7265766572736528293A5B655D2C6C3D303B6C3C612E6C656E6774683B6C2B2B297B666F722876617220693D615B6C5D2C733D21302C753D303B';
wwv_flow_imp.g_varchar2_table(973) := '753C6F2E6C656E6774683B752B2B297B69662841727261792E697341727261792869292626753E30262628693D695B305D292C6E756C6C3D3D697C7C226F626A65637422213D747970656F6620697C7C21286F5B755D696E206929297B733D21313B6272';
wwv_flow_imp.g_varchar2_table(974) := '65616B7D693D695B6F5B755D5D7D696628732972657475726E206E26262141727261792E697341727261792869293F7028692C6E293A697D7D7D7D66756E6374696F6E20527428652C74297B76617220723D6E65772077696E646F772E50697A5A697028';
wwv_flow_imp.g_varchar2_table(975) := '65292C6E3D6E657728302C77696E646F772E646F637874656D706C617465722928722C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A4C742C6E756C6C4765747465723A66756E6374696F6E28297B72';
wwv_flow_imp.g_varchar2_table(976) := '657475726E22227D7D293B72657475726E206E2E72656E6465722866756E6374696F6E2865297B76617220742C723D7B7D3B666F72287420696E20652E706172616D737C7C7B7D29725B745D3D652E706172616D735B745D3B666F72287420696E20652E';
wwv_flow_imp.g_varchar2_table(977) := '646F637C7C7B7D29725B745D3D652E646F635B745D3B666F72287420696E20652E5329725B745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D752829';
wwv_flow_imp.g_varchar2_table(978) := '2C722E544F4441593D6328292C727D287429292C50726F6D6973652E7265736F6C7665286E2E6765745A697028292E67656E6572617465287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445227D2929';
wwv_flow_imp.g_varchar2_table(979) := '7D66756E6374696F6E2044742865297B76617220743D7B7D2C723D7B7D3B72657475726E204F626A6563742E6B65797328657C7C7B7D292E666F72456163682866756E6374696F6E286E297B766172206F3D655B6E5D2C613D6F2E636F6C737C7C5B5D3B';
wwv_flow_imp.g_varchar2_table(980) := '725B6E5D3D7B7D2C612E666F72456163682866756E6374696F6E2865297B725B6E5D5B652E6E616D655D3D652E747970657D292C745B6E5D3D286F2E726F77737C7C5B5D292E6D61702866756E6374696F6E2865297B76617220743D7B7D3B7265747572';
wwv_flow_imp.g_varchar2_table(981) := '6E20612E666F72456163682866756E6374696F6E28722C6E297B745B722E6E616D655D3D655B6E5D7D292C747D297D292C7B533A742C543A727D7D66756E6374696F6E20557428652C74297B76617220723D652E532E444F43533B696628217229726574';
wwv_flow_imp.g_varchar2_table(982) := '75726E5B7B533A652E532C543A652E542C646F633A7B7D2C706172616D733A747D5D3B766172206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B69662822444F435322213D3D';
wwv_flow_imp.g_varchar2_table(983) := '7426264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B745D3D7B7D3B652E535B745D2E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(984) := '76617220743D537472696E6728652E444F435F4B4559293B28725B745D3D725B745D7C7C5B5D292E707573682865297D297D7D292C722E6D61702866756E6374696F6E2872297B766172206F3D7B7D3B72657475726E204F626A6563742E6B6579732865';
wwv_flow_imp.g_varchar2_table(985) := '2E53292E666F72456163682866756E6374696F6E2874297B6F5B745D3D6E5B745D3F6E5B745D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B745D7D292C6F2E444F43533D5B725D2C7B533A6F2C543A652E542C646F633A722C70';
wwv_flow_imp.g_varchar2_table(986) := '6172616D733A747D7D297D66756E6374696F6E2042742865297B76617220743D646F63756D656E742E676574456C656D656E744279496428226E722D6176616E636522293B653F28747C7C2828743D646F63756D656E742E637265617465456C656D656E';
wwv_flow_imp.g_varchar2_table(987) := '7428226469762229292E69643D226E722D6176616E6365222C742E7365744174747269627574652822726F6C65222C2273746174757322292C742E7374796C652E637373546578743D22706F736974696F6E3A66697865643B72696768743A323470783B';
wwv_flow_imp.g_varchar2_table(988) := '626F74746F6D3A323470783B7A2D696E6465783A313030303B70616464696E673A3134707820313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A65';
wwv_flow_imp.g_varchar2_table(989) := '3A313370783B626F782D736861646F773A30203870782032347078207267626128302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287429292C742E696E6E65724854';
wwv_flow_imp.g_varchar2_table(990) := '4D4C3D273C7370616E20636C6173733D2266612066612D7370696E6E65722066612D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B';
wwv_flow_imp.g_varchar2_table(991) := '263C3E225D2F672C66756E6374696F6E2865297B72657475726E7B2226223A2226616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B655D7D29293A742626742E72656D6F766528297D66756E6374';
wwv_flow_imp.g_varchar2_table(992) := '696F6E20477428652C74297B69662865262621652E636C6F736564297472797B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F616465724D73672977696E646F772E636F744C6F616465724D736728652C74293B65';
wwv_flow_imp.g_varchar2_table(993) := '6C73657B76617220723D652E646F63756D656E742E676574456C656D656E744279496428226D736722293B72262628722E74657874436F6E74656E743D74297D7D63617463682865297B7D7D66756E6374696F6E205F7428652C74297B7472797B77696E';
wwv_flow_imp.g_varchar2_table(994) := '646F772E617065782626617065782E6576656E742626617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C74297D63617463682865297B7D7D66756E6374696F6E2057742865297B77696E646F';
wwv_flow_imp.g_varchar2_table(995) := '772E617065782626617065782E6D6573736167653F617065782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D66756E6374696F6E2024742865297B77696E646F772E617065782626617065782E6D65737361676526';
wwv_flow_imp.g_varchar2_table(996) := '26617065782E6D6573736167652E73686F7750616765537563636573732865297D7661722048743D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D';
wwv_flow_imp.g_varchar2_table(997) := '6F6666696365646F63756D656E742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F726470726F6365737369';
wwv_flow_imp.g_varchar2_table(998) := '6E676D6C2E646F63756D656E74227D2C56743D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E20597428652C742C72297B766172';
wwv_flow_imp.g_varchar2_table(999) := '206E3D4E28652E66696C654E616D657C7C227265706F727465222C74292C6F3D56745B725D3B72657475726E2068286E3D6E2E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C222229292B222E222B6F7D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(1000) := '20717428652C742C722C6E297B72657475726E22706466223D3D3D653F547428742C722C6E2E686F6F6B73293A22786C7378223D3D3D653F7A7428742C722C722E6C656E6774682C6E293A22646F6378223D3D3D653F6A7428742C722C6E293A22646F63';
wwv_flow_imp.g_varchar2_table(1001) := '782D74656D706C617465223D3D3D653F286F3D6E2E74656D706C61746555726C2C6F3F286F3D7474286F292C49745B6F5D3F50726F6D6973652E7265736F6C76652849745B6F5D293A6665746368286F2C7B63726564656E7469616C733A2273616D652D';
wwv_flow_imp.g_varchar2_table(1002) := '6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20646573636172676172206C6120706C616E74696C6C612028222B652E7374617475732B22';
wwv_flow_imp.g_varchar2_table(1003) := '2922293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B72657475726E2049745B6F5D3D652C657D29293A50726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C';
wwv_flow_imp.g_varchar2_table(1004) := '612055524C206465206C6120706C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C6120576F726422292E272929292E7468656E2866756E6374696F6E2865297B72657475726E20527428652C725B305D297D293A50726F';
wwv_flow_imp.g_varchar2_table(1005) := '6D6973652E72656A656374286E6577204572726F722822466F726D61746F206E6F20736F706F727461646F3A20222B6529293B766172206F7D66756E6374696F6E20587428652C74297B76617220722C6E3D4B7428652E6C61796F7574292C6F3D7B7D3B';
wwv_flow_imp.g_varchar2_table(1006) := '666F72287220696E2065296F5B725D3D655B725D3B72657475726E206F2E6C61796F75743D6E2C6F74286E292E7468656E2866756E6374696F6E28297B72657475726E2066756E6374696F6E28652C74297B76617220723D4B7428652E6C61796F757429';
wwv_flow_imp.g_varchar2_table(1007) := '2C6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C6F3D44742874292C613D5574286F2C652E706172616D737C7C7B7D292C6C3D652E6F75747075747C';
wwv_flow_imp.g_varchar2_table(1008) := '7C2266696C65223B69662821612E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228652E656D7074794D6573736167657C7C722E656D7074794D6573736167657C7C224E6F20686179206461746F732070';
wwv_flow_imp.g_varchar2_table(1009) := '6172612067656E6572617220656C207265706F7274652E2229293B696628722E62617463682626722E62617463682E6D6178446F63732626612E6C656E6774683E722E62617463682E6D6178446F63732972657475726E2050726F6D6973652E72656A65';
wwv_flow_imp.g_varchar2_table(1010) := '6374286E6577204572726F722822456C206C6F74652073757065726120656C206DC3A178696D6F20646520222B722E62617463682E6D6178446F63732B2220646F63756D656E746F732E2229293B6966282266696C65223D3D3D6C2626313D3D3D612E6C';
wwv_flow_imp.g_varchar2_table(1011) := '656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D6C2626313D3D3D6E2E6C656E677468262622646F63782D74656D706C61746522213D3D6E5B305D297B76617220693D6E5B305D3B72657475726E20717428692C722C612C65';
wwv_flow_imp.g_varchar2_table(1012) := '292E7468656E2866756E6374696F6E2874297B766172206E3D597428722C615B305D2C69293B696628612E6C656E6774683E31297B766172206C3D722E6261746368262628722E62617463682E6D657267654E616D657C7C722E62617463682E7A69704E';
wwv_flow_imp.g_varchar2_table(1013) := '616D65297C7C722E66696C654E616D657C7C227265706F727465223B6E3D5974287B66696C654E616D653A537472696E67286C292E7265706C616365282F5C2E7A6970242F692C2222297D2C7B533A6F2E532C543A6F2E542C646F633A7B7D2C70617261';
wwv_flow_imp.g_varchar2_table(1014) := '6D733A652E706172616D737C7C7B7D7D2C69297D72657475726E7B6B696E643A692C646174613A742C6E616D653A6E2C636F756E743A612E6C656E6774687D7D297D76617220732C753D6E65772077696E646F772E4A535A69702C633D302C663D302C64';
wwv_flow_imp.g_varchar2_table(1015) := '3D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C703D7B7D3B666F72287320696E20652E706172616D737C7C7B7D29705B735D3D652E706172616D735B735D3B702E464F524D41544F3D6E2E6C656E6774683E313F22746F64';
wwv_flow_imp.g_varchar2_table(1016) := '6F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74656D706C617465223A22776F7264227D5B6E5B305D5D3B76617220673D7B533A6F2E532C543A6F2E542C646F633A7B7D2C70617261';
wwv_flow_imp.g_varchar2_table(1017) := '6D733A707D2C6D3D7B7D3B66756E6374696F6E207628652C74297B666F722876617220723D652C6E3D323B6D5B722E746F4C6F7765724361736528295D3B29723D652E7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B6E2B22243122292C';
wwv_flow_imp.g_varchar2_table(1018) := '6E2B2B3B6D5B722E746F4C6F7765724361736528295D3D21302C752E66696C6528722C74292C632B2B7D76617220623D50726F6D6973652E7265736F6C766528292C773D722E62617463682626722E62617463682E73756D6D6172793B772626227A6970';
wwv_flow_imp.g_varchar2_table(1019) := '223D3D3D6C262628623D6E2E66696C7465722866756E6374696F6E2865297B72657475726E22646F63782D74656D706C61746522213D3D657D292E7265647563652866756E6374696F6E28742C6E297B72657475726E20742E7468656E2866756E637469';
wwv_flow_imp.g_varchar2_table(1020) := '6F6E28297B76617220743D772E6C61796F75747C7C7B706167653A722E706167652C666F6F7465723A772E666F6F7465727C7C722E666F6F7465722C73656374696F6E733A772E73656374696F6E732C786C73783A772E786C73782C66696C654E616D65';
wwv_flow_imp.g_varchar2_table(1021) := '3A772E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E66696C654E616D653D772E66696C654E616D657C7C2230305F726573756D656E22292C7174286E2C742C5B675D2C65292E7468656E2866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(1022) := '7B7628597428742C672C6E292C65297D297D297D2C6229293B72657475726E20622E7468656E2866756E6374696F6E28297B72657475726E206E65772050726F6D6973652866756E6374696F6E28742C6F297B66756E6374696F6E206C28297B666F7228';
wwv_flow_imp.g_varchar2_table(1023) := '76617220693D4D6174682E6D696E28662B642C612E6C656E677468292C733D50726F6D6973652E7265736F6C766528293B663C693B662B2B292866756E6374696F6E2874297B6E2E666F72456163682866756E6374696F6E286E297B733D732E7468656E';
wwv_flow_imp.g_varchar2_table(1024) := '2866756E6374696F6E28297B72657475726E207174286E2C722C5B745D2C65292E7468656E2866756E6374696F6E2865297B7628597428722C742C6E292C65297D297D297D297D2928615B665D293B732E7468656E2866756E6374696F6E28297B652E6F';
wwv_flow_imp.g_varchar2_table(1025) := '6E50726F67726573732626652E6F6E50726F677265737328662C612E6C656E677468292C663C612E6C656E6774683F73657454696D656F7574286C2C30293A28652E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C63292C752E67';
wwv_flow_imp.g_varchar2_table(1026) := '656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374';
wwv_flow_imp.g_varchar2_table(1027) := '696F6E2865297B766172206E3D4E28722E62617463682626722E62617463682E7A69704E616D657C7C227265706F727465732E7A6970222C67293B74287B6B696E643A227A6970222C646174613A652C6E616D653A68282F5C2E7A6970242F692E746573';
wwv_flow_imp.g_varchar2_table(1028) := '74286E293F6E3A6E2B222E7A697022292C636F756E743A612E6C656E6774682C66696C65733A637D297D2C6F29297D2C6F297D73657454696D656F7574286C2C30297D297D297D286F2C74297D297D66756E6374696F6E205A742865297B76617220743D';
wwv_flow_imp.g_varchar2_table(1029) := '5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B6526262822636F6469676F223D3D3D652E747970652626227172223D3D3D537472696E6728652E6B696E647C7C22717222292E746F4C6F';
wwv_flow_imp.g_varchar2_table(1030) := '7765724361736528292626742E696E6465784F6628227172636F646522293C302626742E7075736828227172636F646522292C226772616669636F223D3D3D652E747970652626742E696E6465784F66282263686172746A7322293C302626742E707573';
wwv_flow_imp.g_varchar2_table(1031) := '68282263686172746A7322292C22666F726D756C6172696F223D3D3D652E747970652626742E696E6465784F6628226A737A697022293C302626742E7075736828226A737A697022292C22636F6C756D6E6173223D3D3D652E74797065262628652E636F';
wwv_flow_imp.g_varchar2_table(1032) := '6C737C7C5B5D292E666F72456163682872292C595B652E747970655D2626722828652E6669656C64737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C22677275706F223D3D3D652E74797065';
wwv_flow_imp.g_varchar2_table(1033) := '26267228652E73656374696F6E73292C227461626C61223D3D3D652E747970652626722828652E636F6C756D6E737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E63656C6C7D2929297D297D7228652E7365637469';
wwv_flow_imp.g_varchar2_table(1034) := '6F6E73293B766172206E3D652E62617463682626652E62617463682E73756D6D6172793B72657475726E206E26262872286E2E73656374696F6E73292C6E2E6C61796F7574262672286E2E6C61796F75742E73656374696F6E7329292C747D66756E6374';
wwv_flow_imp.g_varchar2_table(1035) := '696F6E204A7428652C74297B69662822737472696E67223D3D747970656F66206526262240223D3D3D652E6368617241742830292626742626766F69642030213D3D745B652E7375627374722831295D2972657475726E204A7428745B652E7375627374';
wwv_flow_imp.g_varchar2_table(1036) := '722831295D2C74293B69662841727261792E697341727261792865292972657475726E20652E7265647563652866756E6374696F6E28652C72297B766172206E3D22737472696E67223D3D747970656F66207226262240223D3D3D722E63686172417428';
wwv_flow_imp.g_varchar2_table(1037) := '3029262674262641727261792E6973417272617928745B722E7375627374722831295D292C6F3D4A7428722C74293B72657475726E206E3F652E636F6E636174286F293A652E636F6E636174285B6F5D297D2C5B5D293B696628652626226F626A656374';
wwv_flow_imp.g_varchar2_table(1038) := '223D3D747970656F662065297B76617220723D7B7D3B72657475726E204F626A6563742E6B6579732865292E666F72456163682866756E6374696F6E286E297B725B6E5D3D2264656673223D3D3D6E3F655B6E5D3A4A7428655B6E5D2C74297D292C727D';
wwv_flow_imp.g_varchar2_table(1039) := '72657475726E20657D66756E6374696F6E204B742865297B76617220743B696628652626226F626A656374223D3D747970656F66206529743D653B656C73657B76617220723D537472696E6728657C7C2222292E7472696D28293B696628227B223D3D3D';
wwv_flow_imp.g_varchar2_table(1040) := '722E63686172417428302929743D4A534F4E2E70617273652872293B656C7365206966282128743D722E73706C697428222E22292E7265647563652866756E6374696F6E28652C74297B72657475726E20653F655B745D3A766F696420307D2C77696E64';
wwv_flow_imp.g_varchar2_table(1041) := '6F772929297468726F77206E6577204572726F7228224E6F20736520656E636F6E7472C3B320656C2064697365C3B16F3A20222B72297D72657475726E204A7428742C742E64656673297D66756E6374696F6E2051742865297B69662865297B69662841';
wwv_flow_imp.g_varchar2_table(1042) := '727261792E697341727261792865297C7C22737472696E6722213D747970656F6620657C7C2F5B232E5C5B5D2F2E746573742865292972657475726E20653B76617220743D652E73706C697428222C22292E6D61702866756E6374696F6E2865297B7265';
wwv_flow_imp.g_varchar2_table(1043) := '7475726E20652E7472696D28297D292E66696C74657228426F6F6C65616E293B72657475726E20742E6C656E6774683F743A766F696420307D7D66756E6374696F6E2065722865297B766172206E2C6F3D22616C6C223D3D3D652E666F726D61743F5B22';
wwv_flow_imp.g_varchar2_table(1044) := '706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C613D313D3D3D6F2E6C656E677468262622706466223D3D3D6F5B305D2626227A697022213D3D652E6F7574707574262622646F776E6C6F616422213D3D65';
wwv_flow_imp.g_varchar2_table(1045) := '2E706466416374696F6E2C6C3D6126262131213D3D652E6C6F616465723F66756E6374696F6E2865297B76617220743D77696E646F772E6F70656E2822222C225F626C616E6B22293B69662821742972657475726E206E756C6C3B6966282266756E6374';
wwv_flow_imp.g_varchar2_table(1046) := '696F6E223D3D747970656F662077696E646F772E636F744C6F61646572297472797B77696E646F772E636F744C6F616465722874293B76617220723D742E646F63756D656E742E676574456C656D656E747342795461674E616D652822683122295B305D';
wwv_flow_imp.g_varchar2_table(1047) := '3B72262628722E74657874436F6E74656E743D2247656E6572616E646F207265706F72746522297D63617463682865297B7D656C736520742E646F63756D656E742E777269746528273C21646F63747970652068746D6C3E3C68746D6C3E3C686561643E';
wwv_flow_imp.g_varchar2_table(1048) := '3C6D65746120636861727365743D227574662D38223E3C7469746C653E47656E6572616E646F207265706F727465E280A63C2F7469746C653E3C7374796C653E626F64797B6D617267696E3A303B6865696768743A31303076683B646973706C61793A66';
wwv_flow_imp.g_varchar2_table(1049) := '6C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D73657269663B6261636B67726F756E643A236634663666393B636F';
wwv_flow_imp.g_varchar2_table(1050) := '6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B77696474683A353670783B6865696768743A353670783B626F726465723A35707820736F6C696420236436653065613B626F726465722D746F702D636F6C6F72';
wwv_flow_imp.g_varchar2_table(1051) := '3A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A72203173206C696E65617220696E66696E6974653B6D617267696E3A30206175746F20313870787D406B65796672616D657320727B746F7B7472616E73666F';
wwv_flow_imp.g_varchar2_table(1052) := '726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A233562366237627D3C2F7374796C653E3C2F686561643E3C626F64793E3C64';
wwv_flow_imp.g_varchar2_table(1053) := '697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C68313E47656E6572616E646F207265706F7274653C2F68313E3C702069643D226D7367223E3C2F703E3C2F6469763E3C2F626F64793E3C2F68746D6C3E27292C74';
wwv_flow_imp.g_varchar2_table(1054) := '2E646F63756D656E742E636C6F736528293B72657475726E20477428742C65292C747D28652E6D6573736167657C7C22436F6E73756C74616E646F206461746F73E280A622293A6E756C6C2C693D77696E646F772E617065782626617065782E7574696C';
wwv_flow_imp.g_varchar2_table(1055) := '3F617065782E7574696C2E73686F775370696E6E657228293A6E756C6C2C733D227265736F6C766572223D3D3D652E6F726967696E262621652E646174612C753D227175657279223D3D3D652E6F726967696E262621652E646174613B69662821732626';
wwv_flow_imp.g_varchar2_table(1056) := '2175297472797B6E3D4B7428652E6C61796F7574297D63617463682865297B72657475726E20692626692E72656D6F766528292C6C26266C2E636C6F736528292C5774282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D65737361676529';
wwv_flow_imp.g_varchar2_table(1057) := '2C50726F6D6973652E72656A6563742865297D76617220633D7B6C61796F75743A6E2C666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A65';
wwv_flow_imp.g_varchar2_table(1058) := '2E74656D706C61746555726C2C686F6F6B733A652E686F6F6B737C7C7B7D2C666F726D50617373776F72643A652E666F726D50617373776F72647D3B5F7428227374617274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F7574';
wwv_flow_imp.g_varchar2_table(1059) := '7075742C7265706F72743A733F652E7265706F72743A766F696420307D293B76617220663D722866756E6374696F6E28652C72297B766172206E3D5B5D3B72657475726E20652E666F72456163682866756E6374696F6E2865297B28745B655D7C7C5B5D';
wwv_flow_imp.g_varchar2_table(1060) := '292E666F72456163682866756E6374696F6E2865297B6E2E696E6465784F662865293C3026266E2E707573682865297D297D292C7226266E2E7075736828226A737A697022292C6E7D286F2C226D6572676522213D3D652E6F7574707574292E636F6E63';
wwv_flow_imp.g_varchar2_table(1061) := '617428737C7C753F5B5D3A5A74286E2929292C643D652E646174613F50726F6D6973652E7265736F6C7665287B646174613A652E646174617D293A6E65772050726F6D6973652866756E6374696F6E28742C72297B766172206E3D7B7830313A4A534F4E';
wwv_flow_imp.g_varchar2_table(1062) := '2E737472696E6769667928632E706172616D73292C7830323A227A6970223D3D3D652E6F75747075743F2259223A224E222C706167654974656D733A517428652E6974656D73297D3B69662873297B696628766F696420303D3D3D652E7265706F72747C';
wwv_flow_imp.g_varchar2_table(1063) := '7C6E756C6C3D3D3D652E7265706F72747C7C22223D3D3D652E7265706F72742972657475726E20766F69642072286E6577204572726F722822496E646971756520656C207265706F72746520612067656E657261722028646174612D7265706F7274292E';
wwv_flow_imp.g_varchar2_table(1064) := '2229293B6E2E7830333D537472696E6728652E7265706F7274297D617065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C6E2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(1065) := '7B652626652E6F6B3F742865293A72286E6577204572726F7228652626652E6D73677C7C224572726F7220616C206F6274656E6572206C6F73206461746F732E2229297D2C66756E6374696F6E28652C742C6E297B72286E6577204572726F7228224572';
wwv_flow_imp.g_varchar2_table(1066) := '726F7220646520636F6D756E6963616369C3B36E3A20222B286E7C7C742929297D297D293B72657475726E2050726F6D6973652E616C6C285B642C665D292E7468656E2866756E6374696F6E2874297B766172206F3D745B305D2C613D50726F6D697365';
wwv_flow_imp.g_varchar2_table(1067) := '2E7265736F6C766528293B69662873297B7472797B6E3D4B74286F2E6C61796F7574297D63617463682865297B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D632E6C61796F';
wwv_flow_imp.g_varchar2_table(1068) := '75743D6E2C6F2E706172616D73262628632E706172616D733D6F2E706172616D73292C6F2E74656D706C61746555726C262628632E74656D706C61746555726C3D6F2E74656D706C61746555726C292C613D72285A74286E29297D656C73652069662875';
wwv_flow_imp.g_varchar2_table(1069) := '297B766172206C3D6F2E6C61796F75747C7C652E6C61796F75743B696628216C297468726F77206E6577204572726F72282246616C746120656C2064697365C3B16F3A206C6120636F6E73756C74612064656C207265706F727465206E6F206465766F6C';
wwv_flow_imp.g_varchar2_table(1070) := '7669C3B3204C41594F5554207920656C20617472696275746F2044697365C3B16F20657374C3A120766163C3AD6F2E22293B7472797B6E3D4B74286C297D63617463682865297B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3';
wwv_flow_imp.g_varchar2_table(1071) := 'A16C69646F3A20222B652E6D657373616765297D632E6C61796F75743D6E2C6F2E74656D706C61746555726C262628632E74656D706C61746555726C3D6F2E74656D706C61746555726C292C613D72285A74286E29297D72657475726E20612E7468656E';
wwv_flow_imp.g_varchar2_table(1072) := '2866756E6374696F6E28297B72657475726E206F2E646174617D297D292E7468656E2866756E6374696F6E2874297B69262628692E72656D6F766528292C693D6E756C6C293B76617220723D652E7472616E73666F726D2626652E7472616E73666F726D';
wwv_flow_imp.g_varchar2_table(1073) := '2874297C7C743B72657475726E204774286C2C2241726D616E646F20656C20646F63756D656E746FE280A622292C632E6F6E50726F67726573733D66756E6374696F6E28652C74297B2D313D3D3D653F42742822436F6D7072696D69656E646F20222B74';
wwv_flow_imp.g_varchar2_table(1074) := '2B22206172636869766F73E280A622293A284274282247656E6572616E646F20222B652B2220646520222B742B22E280A622292C5F74282270726F6772657373222C7B646F6E653A652C746F74616C3A747D29297D2C587428632C72297D292E7468656E';
wwv_flow_imp.g_varchar2_table(1075) := '2866756E6374696F6E2874297B76617220723D652E736176657C7C632E6C61796F75742626632E6C61796F75742E736176653B69662821727C7C21722E70726F636573732972657475726E20743B6966282177696E646F772E617065787C7C2161706578';
wwv_flow_imp.g_varchar2_table(1076) := '2E736572766572297468726F77206E6577204572726F7228224775617264617220656E20656C207365727669646F7220726571756965726520415045582E22293B72657475726E20427428224775617264616E646F20656E20656C207365727669646F72';
wwv_flow_imp.g_varchar2_table(1077) := 'E280A622292C66756E6374696F6E28652C742C72297B766172206E3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A48745B652E6B696E645D7C7C48742E646F63782C6F3D652E6461746120696E7374616E63656F66';
wwv_flow_imp.g_varchar2_table(1078) := '20426C6F623F652E646174613A6E657720426C6F62285B652E646174615D2C7B747970653A6E7D293B72657475726E206E65772050726F6D6973652866756E6374696F6E28612C6C297B76617220693D6E65772046696C655265616465723B692E6F6E65';
wwv_flow_imp.g_varchar2_table(1079) := '72726F723D66756E6374696F6E28297B6C286E6577204572726F7228224E6F207365207075646F206C65657220656C206172636869766F2067656E657261646F2E2229297D2C692E6F6E6C6F61643D66756E6374696F6E28297B766172206F2C733D5374';
wwv_flow_imp.g_varchar2_table(1080) := '72696E6728692E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292C753D5B5D3B666F72286F3D303B6F3C732E6C656E6774683B6F2B3D33653429752E7075736828732E737562737472286F2C33653429293B617065';
wwv_flow_imp.g_varchar2_table(1081) := '782E7365727665722E70726F6365737328742E70726F636573732C7B7830313A652E6E616D652C7830323A6E2C7830333A766F696420303D3D3D722E7265706F72743F22223A537472696E6728722E7265706F7274292C7830343A4A534F4E2E73747269';
wwv_flow_imp.g_varchar2_table(1082) := '6E6769667928722E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A757D2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B65262621313D3D3D652E6F6B3F6C286E6577204572726F722865';
wwv_flow_imp.g_varchar2_table(1083) := '2E6D73677C7C22456C207365727669646F72206E6F206775617264C3B320656C20646F63756D656E746F2E2229293A6128657C7C7B7D297D2C66756E6374696F6E28652C742C72297B6C286E6577204572726F7228224E6F207365207075646F20677561';
wwv_flow_imp.g_varchar2_table(1084) := '7264617220656E20656C207365727669646F723A20222B28727C7C742929297D297D2C692E7265616441734461746155524C286F297D297D28742C722C7B7265706F72743A652E7265706F72742C706172616D733A632E706172616D737D292E7468656E';
wwv_flow_imp.g_varchar2_table(1085) := '2866756E6374696F6E2865297B72657475726E20742E73617665643D652C742E6F6E6C793D226F6E6C79223D3D3D722E6D6F64652C5F7428227361766564222C7B6E616D653A742E6E616D652C6B696E643A742E6B696E642C726573706F6E73653A657D';
wwv_flow_imp.g_varchar2_table(1086) := '292C747D297D292E7468656E2866756E6374696F6E2865297B696628427428292C652E6F6E6C79296C26266C2E636C6F736528292C247428652E73617665642626652E73617665642E6D73677C7C22446F63756D656E746F20677561726461646F3A2022';
wwv_flow_imp.g_varchar2_table(1087) := '2B652E6E616D65293B656C73652069662822706466223D3D3D652E6B696E64262661297B76617220743D55524C2E6372656174654F626A65637455524C286E657720426C6F62285B652E646174615D2C7B747970653A48742E7064667D29293B6C262621';
wwv_flow_imp.g_varchar2_table(1088) := '6C2E636C6F7365643F6C2E6C6F636174696F6E2E687265663D743A77696E646F772E6F70656E28742C225F626C616E6B22297D656C7365206C26266C2E636C6F736528292C723D652E646174612C6E3D652E6E616D652C6F3D227A6970223D3D3D652E6B';
wwv_flow_imp.g_varchar2_table(1089) := '696E643F226170706C69636174696F6E2F7A6970223A48745B652E6B696E645D7C7C48742E646F63782C693D7220696E7374616E63656F6620426C6F623F723A6E657720426C6F62285B725D2C7B747970653A6F7C7C226170706C69636174696F6E2F6F';
wwv_flow_imp.g_varchar2_table(1090) := '637465742D73747265616D227D292C28733D646F63756D656E742E637265617465456C656D656E742822612229292E687265663D55524C2E6372656174654F626A65637455524C2869292C732E646F776E6C6F61643D6E2C646F63756D656E742E626F64';
wwv_flow_imp.g_varchar2_table(1091) := '792E617070656E644368696C642873292C732E636C69636B28292C73657454696D656F75742866756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C28732E68726566292C732E72656D6F766528297D2C346533292C227A6970223D';
wwv_flow_imp.g_varchar2_table(1092) := '3D3D652E6B696E642626247428225A49502067656E657261646F3A20222B652E66696C65732B22206172636869766F7320646520222B652E636F756E742B2220646F63756D656E746F732E22293B76617220722C6E2C6F2C692C733B72657475726E205F';
wwv_flow_imp.g_varchar2_table(1093) := '742822656E64222C7B6E616D653A652E6E616D652C636F756E743A652E636F756E742C66696C65733A652E66696C65737D292C657D292E63617463682866756E6374696F6E2865297B7468726F7720692626692E72656D6F766528292C427428292C6C26';
wwv_flow_imp.g_varchar2_table(1094) := '26216C2E636C6F73656426266C2E636C6F736528292C77696E646F772E636F6E736F6C652626636F6E736F6C652E6572726F722865292C5F7428226572726F72222C7B6D6573736167653A652E6D6573736167657D292C577428652E6D6573736167657C';
wwv_flow_imp.g_varchar2_table(1095) := '7C224E6F207365207075646F2067656E6572617220656C207265706F7274652E22292C657D297D7661722074723D21312C72723D6E756C6C3B72657475726E22756E646566696E656422213D747970656F6620646F63756D656E742626646F63756D656E';
wwv_flow_imp.g_varchar2_table(1096) := '742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2865297B72723D652E7461726765742626652E7461726765742E636C6F736573742626652E74';
wwv_flow_imp.g_varchar2_table(1097) := '61726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D2C5B646174612D666F726D61745D22297C7C652E7461726765747D2C2130292C7B76657273696F6E3A22312E32312E30222C6C6962733A652C72756E3A6572';
wwv_flow_imp.g_varchar2_table(1098) := '2C64613A66756E6374696F6E2865297B76617220743D746869732626746869732E616374696F6E3F746869733A7B7D2C723D742E616374696F6E7C7C7B7D2C6E3D742E74726967676572696E67456C656D656E747C7C72722C6F3D742E62726F77736572';
wwv_flow_imp.g_varchar2_table(1099) := '4576656E743B6966286F26266F2E70726576656E7444656661756C7426266F2E70726576656E7444656661756C7428292C217472297B76617220613D652626226F626A656374223D3D747970656F6620653F653A7B7D2C6C3D2266756E6374696F6E223D';
wwv_flow_imp.g_varchar2_table(1100) := '3D747970656F6620653F653A612E696E69742C693D7B7D2C733D6E26266E2E646174617365747C7C7B7D2C753D612E7265706F72742C633D612E6F75747075747C7C722E61747472696275746530337C7C2266696C65222C663D612E666F726D61747C7C';
wwv_flow_imp.g_varchar2_table(1101) := '722E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732873292E666F72456163682866756E6374696F6E2865297B226F757470757422213D3D653F22666F726D617422213D3D653F227265706F727422213D3D653F695B652E72';
wwv_flow_imp.g_varchar2_table(1102) := '65706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D735B655D3A753D735B655D3A663D735B655D3A633D735B655D7D293B76617220643D7B6C61796F75743A612E6C61796F75747C7C722E617474726962';
wwv_flow_imp.g_varchar2_table(1103) := '75746530312C666F726D61743A662C6F75747075743A632C6974656D733A612E6974656D737C7C722E61747472696275746530347C7C22222C706466416374696F6E3A612E706466416374696F6E7C7C722E61747472696275746530357C7C226F70656E';
wwv_flow_imp.g_varchar2_table(1104) := '222C74656D706C61746555726C3A612E74656D706C61746555726C7C7C722E61747472696275746530362C6D6573736167653A612E6D6573736167657C7C722E61747472696275746530372C706172616D733A692C616A61784964656E7469666965723A';
wwv_flow_imp.g_varchar2_table(1105) := '612E616A61784964656E7469666965727C7C722E616A61784964656E7469666965722C6F726967696E3A612E6F726967696E7C7C2261747472696275746573222C7265706F72743A752C736176653A612E736176657D3B6966282266756E6374696F6E22';
wwv_flow_imp.g_varchar2_table(1106) := '3D3D747970656F66206C297B76617220683D6C2864293B69662821313D3D3D682972657475726E3B643D687C7C647D74723D21302C65722864292E7468656E2866756E6374696F6E28297B74723D21317D2C66756E6374696F6E28297B74723D21317D29';
wwv_flow_imp.g_varchar2_table(1107) := '7D7D2C6275696C643A58742C656E737572653A722C6C61796F75744C6962733A5A742C5F696E7465726E616C733A7B494D473A51652C696D6744696D733A72742C74706C3A4E2C636F6E643A502C666D743A702C6E6F726D616C697A653A44742C636F6E';
wwv_flow_imp.g_varchar2_table(1108) := '74657874733A55742C636F64653132383A6D742C706E67313A70742C6C61796F75744C6962733A5A742C7368613531323A53652C776F72644C65676163794B65793A43652C776F7264486173683A41652C666F726D4E616D653A67657D7D7D28293B';
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
