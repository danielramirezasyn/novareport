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
,p_version_identifier=>'1.19.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>31
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
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E31392E30202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C';
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
wwv_flow_imp.g_varchar2_table(20) := '28742C72297B72657475726E20742E7468656E2866756E6374696F6E28297B72657475726E20655B725D2E6F6B28293F6E756C6C3A28743D716528655B725D2E75726C292C6E65772050726F6D6973652866756E6374696F6E28652C72297B766172206E';
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
wwv_flow_imp.g_varchar2_table(34) := '22292E7472696D28297D66756E6374696F6E207028652C74297B6966286E756C6C3D3D657C7C22223D3D3D652972657475726E22223B69662821742972657475726E20537472696E672865293B76617220723D742E73706C697428223A22292C6E3D725B';
wwv_flow_imp.g_varchar2_table(35) := '305D3B696628226D6F6E6579223D3D3D6E7C7C226E756D223D3D3D6E297B766172206F3D766F69642030213D3D725B315D3F2B725B315D3A322C613D4E756D6265722865293B72657475726E2069734E614E2861293F537472696E672865293A612E746F';
wwv_flow_imp.g_varchar2_table(36) := '4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A6F2C6D6178696D756D4672616374696F6E4469676974733A6F7D297D72657475726E22696E74223D3D3D6E3F69734E614E284E756D626572';
wwv_flow_imp.g_varchar2_table(37) := '286529293F537472696E672865293A4D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D555322293A22706374223D3D3D6E3F7028652C226E756D3A222B28725B315D7C7C3229292B2225223A227570';
wwv_flow_imp.g_varchar2_table(38) := '706572223D3D3D6E3F537472696E672865292E746F55707065724361736528293A226C6F776572223D3D3D6E3F537472696E672865292E746F4C6F7765724361736528293A22796E223D3D3D6E3F2259223D3D3D657C7C2253223D3D3D653F2253C3AD22';
wwv_flow_imp.g_varchar2_table(39) := '3A224E223D3D3D653F224E6F223A537472696E672865293A226C6574726173223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A66756E6374696F6E28652C74297B76617220723D653C302C6E3D4D6174682E726F756E64';
wwv_flow_imp.g_varchar2_table(40) := '283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C613D6E253130302C6C3D79286F293B69662874297B2F284D494C4CC3934E7C4D494C4C4F4E45537C42494C4CC3934E7C42494C4C4F4E455329242F2E7465';
wwv_flow_imp.g_varchar2_table(41) := '7374286C292626286C2B3D2220444522293B76617220693D537472696E672874292E746F55707065724361736528292E73706C697428222F22293B6C2B3D2220222B28313D3D3D6F2626692E6C656E6774683E313F695B305D3A695B692E6C656E677468';
wwv_flow_imp.g_varchar2_table(42) := '2D315D297D656C7365206C3D6C2E7265706C616365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E2865297B72657475726E20652B224F227D293B72657475726E28723F224D454E4F532022';
wwv_flow_imp.g_varchar2_table(43) := '3A2222292B6C2B2220434F4E20222B28613C31303F2230223A2222292B612B222F313030227D284E756D6265722865292C722E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E6374696F6E20672865297B7265747572';
wwv_flow_imp.g_varchar2_table(44) := '6E2F5E2875707065727C6C6F7765727C796E7C6C657472617329283A7C24292F2E7465737428657C7C2222297D766172206D3D5B22222C22554E222C22444F53222C2254524553222C2243554154524F222C2243494E434F222C2253454953222C225349';
wwv_flow_imp.g_varchar2_table(45) := '455445222C224F43484F222C224E55455645222C224449455A222C224F4E4345222C22444F4345222C225452454345222C224341544F524345222C225155494E4345222C22444945434953C3894953222C2244494543495349455445222C224449454349';
wwv_flow_imp.g_varchar2_table(46) := '4F43484F222C2244494543494E55455645222C225645494E5445222C225645494E5449C39A4E222C225645494E544944C39353222C225645494E54495452C38953222C225645494E544943554154524F222C225645494E544943494E434F222C22564549';
wwv_flow_imp.g_varchar2_table(47) := '4E544953C3894953222C225645494E54495349455445222C225645494E54494F43484F222C225645494E54494E55455645225D2C763D5B22222C22222C22222C22545245494E5441222C2243554152454E5441222C2243494E4355454E5441222C225345';
wwv_flow_imp.g_varchar2_table(48) := '53454E5441222C22534554454E5441222C224F4348454E5441222C224E4F56454E5441225D2C623D5B22222C224349454E544F222C22444F534349454E544F53222C22545245534349454E544F53222C2243554154524F4349454E544F53222C22515549';
wwv_flow_imp.g_varchar2_table(49) := '4E49454E544F53222C22534549534349454E544F53222C22534554454349454E544F53222C224F43484F4349454E544F53222C224E4F56454349454E544F53225D3B66756E6374696F6E20772865297B6966283130303D3D3D652972657475726E224349';
wwv_flow_imp.g_varchar2_table(50) := '454E223B76617220743D4D6174682E666C6F6F7228652F313030292C723D65253130302C6E3D5B5D3B72657475726E207426266E2E7075736828625B745D292C7226266E2E7075736828723C33303F6D5B725D3A765B4D6174682E666C6F6F7228722F31';
wwv_flow_imp.g_varchar2_table(51) := '30295D2B28722531303F22205920222B6D5B722531305D3A222229292C6E2E6A6F696E28222022297D66756E6374696F6E20792865297B696628303D3D3D652972657475726E224345524F223B76617220743D5B5D3B5B5B316531322C2242494C4CC393';
wwv_flow_imp.g_varchar2_table(52) := '4E222C2242494C4C4F4E4553225D2C5B3165362C224D494C4CC3934E222C224D494C4C4F4E4553225D5D2E666F72456163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E707573682831';
wwv_flow_imp.g_varchar2_table(53) := '3D3D3D6E3F22554E20222B725B315D3A79286E292B2220222B725B325D292C652D3D6E2A725B305D297D293B76617220723D4D6174682E666C6F6F7228652F316533292C6E3D65253165333B72657475726E20722626742E7075736828313D3D3D723F22';
wwv_flow_imp.g_varchar2_table(54) := '4D494C223A772872292B22204D494C22292C6E2626742E707573682877286E29292C742E6A6F696E28222022297D66756E6374696F6E207828652C742C72297B766172206E3D537472696E672874292E746F55707065724361736528292C6F3D6E2E696E';
wwv_flow_imp.g_varchar2_table(55) := '6465784F6628222E22293B6966286F3E30297B76617220613D6E2E73756273747228302C6F292C6C3D6E2E737562737472286F2B31293B69662822444F43223D3D3D612972657475726E20652E646F633F652E646F635B6C5D3A766F696420303B696628';
wwv_flow_imp.g_varchar2_table(56) := '22504152414D223D3D3D612972657475726E20652E706172616D733F652E706172616D735B6C5D3A766F696420303B696628224954454D223D3D3D612972657475726E2066756E6374696F6E2865297B7472797B72657475726E2077696E646F772E6170';
wwv_flow_imp.g_varchar2_table(57) := '65782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D63617463682865297B72657475726E22227D7D286C293B76617220693D28652E535B615D7C7C5B5D295B305D3B72657475726E20693F695B6C5D3A';
wwv_flow_imp.g_varchar2_table(58) := '766F696420307D72657475726E224E4F57223D3D3D6E3F7528293A22544F444159223D3D3D6E3F6328293A2250414745223D3D3D6E7C7C225041474553223D3D3D6E3F227B222B6E2B227D223A7226264F626A6563742E70726F746F747970652E686173';
wwv_flow_imp.g_varchar2_table(59) := '4F776E50726F70657274792E63616C6C28722C6E293F725B6E5D3A652E646F6326264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F652E646F635B6E5D3A652E706172616D733F652E';
wwv_flow_imp.g_varchar2_table(60) := '706172616D735B6E5D3A766F696420307D66756E6374696F6E205328652C742C72297B72657475726E206E756C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C285B41';
wwv_flow_imp.g_varchar2_table(61) := '2D5A612D7A302D393A2FC381C389C38DC393C39AC391C39CC3A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B29293F5C7D2F672C66756E6374696F6E28652C6E2C6F297B76617220613D7828742C6E2C72293B72657475726E206E756C6C3D3D613F22223A702861';
wwv_flow_imp.g_varchar2_table(62) := '2C6F297D297D66756E6374696F6E204528652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E657865632865293B69';
wwv_flow_imp.g_varchar2_table(63) := '6628216E2972657475726E21313B766172206F3D7828742C6E5B325D2C72293B696628216E5B335D297B76617220613D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E223D3D3D6F293B72657475726E206E5B315D3F21613A617D';
wwv_flow_imp.g_varchar2_table(64) := '766172206C2C693D286C3D286C3D6E5B345D292E7472696D28292C2F5E272E2A27242F2E74657374286C297C7C2F5E222E2A22242F2E74657374286C293F6C2E736C69636528312C2D31293A226E756C6C223D3D3D6C3F6E756C6C3A22223D3D3D6C7C7C';
wwv_flow_imp.g_varchar2_table(65) := '69734E614E284E756D626572286C29293F766F696420303A4E756D626572286C29293B766F696420303D3D3D69262628693D7828742C6E5B345D2E7472696D28292C7229293B76617220733D6E756C6C3D3D6F7C7C22223D3D3D6F3F6E756C6C3D3D3D69';
wwv_flow_imp.g_varchar2_table(66) := '7C7C22223D3D3D693A537472696E67286F293D3D3D537472696E672869293B737769746368286E5B335D297B63617365223D3D223A72657475726E20733B6361736522213D223A72657475726E21733B63617365223E223A72657475726E204E756D6265';
wwv_flow_imp.g_varchar2_table(67) := '72286F293E4E756D6265722869293B63617365223C223A72657475726E204E756D626572286F293C4E756D6265722869293B63617365223E3D223A72657475726E204E756D626572286F293E3D4E756D6265722869293B63617365223C3D223A72657475';
wwv_flow_imp.g_varchar2_table(68) := '726E204E756D626572286F293C3D4E756D6265722869297D72657475726E21317D66756E6374696F6E205428652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C282266756E6374696F6E223D3D747970656F6620653F212165';
wwv_flow_imp.g_varchar2_table(69) := '28722C74293A537472696E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E65766572792866756E6374696F6E2865297B72657475726E204528652C742C72297D';
wwv_flow_imp.g_varchar2_table(70) := '297D29297D66756E6374696F6E204328652C74297B76617220723D742E535B537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C7465722866756E63';
wwv_flow_imp.g_varchar2_table(71) := '74696F6E2872297B72657475726E205428652E66696C7465722C742C72297D293A727D66756E6374696F6E204128652C742C72297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F6620652972657475726E20';
wwv_flow_imp.g_varchar2_table(72) := '653B766172206E3D7828742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E207A28652C742C72297B766172206E3D6E756C6C3B7265747572';
wwv_flow_imp.g_varchar2_table(73) := '6E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E21215428652E7768656E2C742C72292626286E3D652C2130297D292C6E7D766172204D3D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D';
wwv_flow_imp.g_varchar2_table(74) := '2C617269616C3A5B2268656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75';
wwv_flow_imp.g_varchar2_table(75) := '726965723A5B22636F7572696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E204E2865297B72657475726E20653D537472696E6728657C7C2268656C';
wwv_flow_imp.g_varchar2_table(76) := '76657469636122292E746F4C6F7765724361736528292C4D5B655D3F653A2268656C766574696361227D66756E6374696F6E204628652C74297B76617220722C6E3D5B5D2C6F3D7B623A21312C693A21312C753A21312C733A21317D2C613D5B28743D74';
wwv_flow_imp.g_varchar2_table(77) := '7C7C7B7D292E666F6E747C7C2268656C766574696361225D2C6C3D5B742E636F6C6F727C7C6E756C6C5D2C693D22222C733D303B66756E6374696F6E207528297B692626286E2E70757368287B743A692C623A6F2E622C693A6F2E692C753A6F2E752C73';
wwv_flow_imp.g_varchar2_table(78) := '3A6F2E732C663A4E28615B612E6C656E6774682D315D292C633A6C5B6C2E6C656E6774682D315D7D292C693D2222297D666F7228653D537472696E67286E756C6C3D3D653F22223A65293B733C652E6C656E6774683B297B76617220633D652E73756273';
wwv_flow_imp.g_varchar2_table(79) := '74722873293B225C5C223D3D3D632E6368617241742830292626632E6C656E6774683E313F28692B3D632E6368617241742831292C732B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286329293F287528292C612E70';
wwv_flow_imp.g_varchar2_table(80) := '75736828725B315D292C732B3D725B305D2E6C656E677468293A225B2F665D22213D3D632E73756273747228302C34293F28723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286329293F287528292C6C2E707573';
wwv_flow_imp.g_varchar2_table(81) := '6828725B315D292C732B3D725B305D2E6C656E677468293A225B2F635D22213D3D632E73756273747228302C34293F222A2A2A22213D3D632E73756273747228302C33293F222A2A22213D3D632E73756273747228302C32293F227E7E22213D3D632E73';
wwv_flow_imp.g_varchar2_table(82) := '756273747228302C32293F222B2B22213D3D632E73756273747228302C32293F222A22213D3D632E6368617241742830293F28692B3D632E6368617241742830292C732B2B293A287528292C6F2E693D216F2E692C732B3D31293A287528292C6F2E753D';
wwv_flow_imp.g_varchar2_table(83) := '216F2E752C732B3D32293A287528292C6F2E733D216F2E732C732B3D32293A287528292C6F2E623D216F2E622C732B3D32293A287528292C6F2E623D216F2E622C6F2E693D216F2E692C732B3D33293A287528292C6C2E6C656E6774683E3126266C2E70';
wwv_flow_imp.g_varchar2_table(84) := '6F7028292C732B3D34293A287528292C612E6C656E6774683E312626612E706F7028292C732B3D34297D72657475726E207528292C6E7D66756E6374696F6E205028652C74297B76617220723D652E736F757263653F4328652C74295B305D3A6E756C6C';
wwv_flow_imp.g_varchar2_table(85) := '3B72657475726E2841727261792E6973417272617928652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C697428225C6E2229292E6D61702866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(86) := '72657475726E205328652C742C72297D297D66756E6374696F6E206B28652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D742E545B6E5D7C7C7B7D2C6C3D652E636F6C756D6E';
wwv_flow_imp.g_varchar2_table(87) := '733B72657475726E206C26266C2E6C656E6774687C7C286C3D4F626A6563742E6B6579732861292E66696C7465722866756E6374696F6E2865297B72657475726E22444F435F4B455922213D3D657D292E6D61702866756E6374696F6E2865297B726574';
wwv_flow_imp.g_varchar2_table(88) := '75726E7B636F6C3A657D7D29292C286C3D6C2E66696C7465722866756E6374696F6E2865297B72657475726E22737472696E67223D3D747970656F6620657C7C21652E7768656E7C7C5428652E7768656E2C742C6E756C6C297D29292E6D61702866756E';
wwv_flow_imp.g_varchar2_table(89) := '6374696F6E2865297B76617220743D28653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C292E746F55707065724361736528293A6E756C6C2C6E3D743F615B745D3A6E756C6C2C6C';
wwv_flow_imp.g_varchar2_table(90) := '3D652E666D743B6C7C7C224E554D42455222213D3D6E7C7C652E76616C75657C7C286C3D722E736F6D652866756E6374696F6E2865297B72657475726E206F28655B745D2926264D6174682E726F756E6428655B745D29213D3D655B745D7D293F226D6F';
wwv_flow_imp.g_varchar2_table(91) := '6E6579223A6E756C6C293B76617220693D652E63656C6C2626525B652E63656C6C2E747970655D3F652E63656C6C3A6E756C6C3B72657475726E7B636F6C3A742C76616C75653A766F69642030213D3D652E76616C75653F652E76616C75653A652E6365';
wwv_flow_imp.g_varchar2_table(92) := '6C6C262622746578746F223D3D3D652E63656C6C2E747970653F652E63656C6C2E746578743A766F696420302C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628747C7C2222292C63656C6C3A692C76616C69676E3A2F';
wwv_flow_imp.g_varchar2_table(93) := '5E28746F707C6D6964646C657C626F74746F6D29242F2E7465737428537472696E6728652E76616C69676E7C7C2222292E746F4C6F776572436173652829293F537472696E6728652E76616C69676E292E746F4C6F7765724361736528293A6E756C6C2C';
wwv_flow_imp.g_varchar2_table(94) := '666D743A6C2C6D61703A652E6D61702C626F6C643A2121652E626F6C642C77696474683A652E77696474682C616C69676E3A652E616C69676E7C7C28693F2263656E746572223A6E756C6C297C7C2867286C293F226C656674223A224E554D424552223D';
wwv_flow_imp.g_varchar2_table(95) := '3D3D6E7C7C226D6F6E6579223D3D3D6C7C7C22696E74223D3D3D6C7C7C226E756D223D3D3D6C3F227269676874223A2244415445223D3D3D6E7C7C2264617465223D3D3D6C3F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63';
wwv_flow_imp.g_varchar2_table(96) := '656C6C5374796C652C636F6C6F723A652E636F6C6F722C68656164416C69676E3A652E68656164416C69676E2C69734E756D3A216926262167286C29262628224E554D424552223D3D3D6E262621652E6D6170262621652E76616C75657C7C226D6F6E65';
wwv_flow_imp.g_varchar2_table(97) := '79223D3D3D6C7C7C22696E74223D3D3D6C7C7C2F5E6E756D2F2E74657374286C7C7C222229297D7D297D66756E6374696F6E204F28652C74297B76617220723D5B5D2C6E3D303B72657475726E28652E67726F7570737C7C5B5D292E666F724561636828';
wwv_flow_imp.g_varchar2_table(98) := '66756E6374696F6E2865297B766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E677468262628722E70757368287B6C6162656C3A652E6C6162656C7C7C22222C';
wwv_flow_imp.g_varchar2_table(99) := '636F6C733A6F2C66726F6D3A6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C733A742E6C656E6774682D6E2C66726F6D3A6E2C6761703A21307D292C727D';
wwv_flow_imp.g_varchar2_table(100) := '66756E6374696F6E206A28652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E205328652E76616C75652C722C74293B766172206E3D745B652E636F6C5D3B72657475726E20652E6D617026266E756C6C213D6E2626766F';
wwv_flow_imp.g_varchar2_table(101) := '69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E204C28652C742C72297B766172206E3D6A28652C742C72293B72657475726E20652E6D61702626766F69642030213D3D652E6D61705B745B652E636F6C5D5D3F53';
wwv_flow_imp.g_varchar2_table(102) := '7472696E67286E293A70286E2C652E666D74297D76617220523D7B636F6469676F3A312C696D6167656E3A312C6772616669636F3A317D3B66756E6374696F6E20492865297B76617220742C723D7B7D3B666F72287420696E2065294F626A6563742E70';
wwv_flow_imp.g_varchar2_table(103) := '726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C7429262628725B745D3D655B745D293B72657475726E20727D66756E6374696F6E204428652C74297B76617220723D537472696E6728652E76616C69676E7C7C2222292E74';
wwv_flow_imp.g_varchar2_table(104) := '6F4C6F7765724361736528293B72657475726E22746F70223D3D3D727C7C226D6964646C65223D3D3D727C7C22626F74746F6D223D3D3D723F723A742E736F6D652866756E6374696F6E2865297B72657475726E20652E63656C6C7D293F226D6964646C';
wwv_flow_imp.g_varchar2_table(105) := '65223A6E756C6C7D66756E6374696F6E205528652C742C722C6E297B766172206F3D652E63656C6C3B696628216F2972657475726E206E756C6C3B69662822636F6469676F223D3D3D6F2E74797065297B76617220613D49286F293B612E73697A657C7C';
wwv_flow_imp.g_varchar2_table(106) := '28612E73697A653D3134292C612E77696474687C7C28612E77696474683D3330292C612E6865696768747C7C28612E6865696768743D38293B766172206C3D637428612C722C74293B696628216C2972657475726E206E756C6C3B76617220693D667428';
wwv_flow_imp.g_varchar2_table(107) := '6C293B72657475726E7B696D3A692C773A692E776D6D2C683A692E686D6D7D7D69662822696D6167656E223D3D3D6F2E74797065297B76617220733D6F2E6669656C643F745B537472696E67286F2E6669656C64292E746F55707065724361736528295D';
wwv_flow_imp.g_varchar2_table(108) := '3A6E756C6C2C753D6E756C6C3B7472797B753D733F4B652873293A6F2E75726C2626216F2E6669656C643F59655B71652853286F2E75726C2C722C7429295D3A6E756C6C7D63617463682865297B77696E646F772E636F6E736F6C652626636F6E736F6C';
wwv_flow_imp.g_varchar2_table(109) := '652E7761726E28226E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B6F2E6669656C642C65297D69662821752972657475726E206E756C6C3B76617220633D6574287B77696474683A6F2E77696474687C7C286F2E68';
wwv_flow_imp.g_varchar2_table(110) := '65696768743F766F696420303A3135292C6865696768743A6F2E6865696768747D2C75293B72657475726E7B696D3A752C773A632E772C683A632E687D7D76617220663D49286F293B64656C65746520662E66696C7465722C64656C65746520662E6C69';
wwv_flow_imp.g_varchar2_table(111) := '6E6B2C662E77696474687C7C28662E77696474683D3430292C662E6865696768747C7C28662E6865696768743D3135293B76617220643D687428662C66756E6374696F6E28652C742C72297B766172206E3D537472696E6728652E736F757263657C7C22';
wwv_flow_imp.g_varchar2_table(112) := '22292E746F55707065724361736528292C6F3D652E6C696E6B7C7C7B7D2C613D652E66696C7465723F5328652E66696C7465722C742C72293A6E756C6C2C6C3D28742E535B6E5D7C7C5B5D292E66696C7465722866756E6374696F6E2865297B666F7228';
wwv_flow_imp.g_varchar2_table(113) := '766172206E20696E206F296966284F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C286F2C6E292626537472696E6728655B6E2E746F55707065724361736528295D29213D3D537472696E6728725B537472696E';
wwv_flow_imp.g_varchar2_table(114) := '67286F5B6E5D292E746F55707065724361736528295D292972657475726E21313B72657475726E21617C7C5428612C742C65297D292C693D492874293B72657475726E20692E533D4928742E53292C692E535B6E5D3D6C2C697D286F2C722C74292C6E29';
wwv_flow_imp.g_varchar2_table(115) := '3B72657475726E20643F7B696D3A642C773A642E776D6D2C683A642E686D6D7D3A6E756C6C7D76617220423D7B666F726D756C6172696F3A312C66696368613A312C7461726A657461733A317D3B66756E6374696F6E20472865297B76617220743D5B5D';
wwv_flow_imp.g_varchar2_table(116) := '3B72657475726E28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B696628652626425B652E747970655D262628652E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E20652626652E626C6F63';
wwv_flow_imp.g_varchar2_table(117) := '6B7D29297B76617220723D6E756C6C2C6E3D302C6F3D66756E6374696F6E28297B722626722E6669656C64732E6C656E6774682626742E707573682872292C723D6E756C6C7D3B652E6669656C64732E666F72456163682866756E6374696F6E2861297B';
wwv_flow_imp.g_varchar2_table(118) := '696628612626612E626C6F636B297B766172206C3D612E626C6F636B3B696628216C7C7C2155655B6C2E747970655D7C7C22666F726D756C6172696F223D3D3D6C2E747970652972657475726E3B72657475726E206F28292C21286C3D49286C29292E73';
wwv_flow_imp.g_varchar2_table(119) := '6F757263652626652E736F757263652626226C696E656122213D3D6C2E747970652626226573706163696F22213D3D6C2E747970652626286C2E736F757263653D652E736F75726365292C612E7768656E2626216C2E7768656E2626286C2E7768656E3D';
wwv_flow_imp.g_varchar2_table(120) := '612E7768656E292C6E7C7C21652E7469746C657C7C227461626C6122213D3D6C2E747970657C7C6C2E7469746C657C7C286C2E7469746C653D652E7469746C65292C742E70757368286C292C766F6964206E2B2B7D727C7C2828723D49286529292E6669';
wwv_flow_imp.g_varchar2_table(121) := '656C64733D5B5D2C6E262664656C65746520722E7469746C652C6E2B2B292C722E6669656C64732E707573682861297D292C6F28297D656C736520742E707573682865297D292C747D76617220573D7B73756D3A392C6176673A312C6D696E3A352C6D61';
wwv_flow_imp.g_varchar2_table(122) := '783A342C636F756E743A337D2C5F3D7B73756D3A2253554D222C6176673A2241564552414745222C6D696E3A224D494E222C6D61783A224D4158222C636F756E743A22434F554E5441227D2C483D7B6176673A2250726F6D2E222C6D696E3A224DC3AD6E';
wwv_flow_imp.g_varchar2_table(123) := '2E222C6D61783A224DC3A1782E222C636F756E743A2243616E742E227D3B66756E6374696F6E20562865297B72657475726E2841727261792E697341727261792865293F653A5B5D292E6D61702866756E6374696F6E2865297B76617220743D65262622';
wwv_flow_imp.g_varchar2_table(124) := '6F626A656374223D3D747970656F6620653F653A7B636F6C3A657D2C723D537472696E6728742E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475726E7B636F6C3A537472696E6728742E636F6C7C7C2222292E746F5570706572';
wwv_flow_imp.g_varchar2_table(125) := '4361736528292C666E3A575B725D3F723A2273756D227D7D292E66696C7465722866756E6374696F6E2865297B72657475726E20652E636F6C7D297D66756E6374696F6E205928652C74297B666F722876617220723D303B723C652E6C656E6774683B72';
wwv_flow_imp.g_varchar2_table(126) := '2B2B29696628655B725D2E636F6C3D3D3D742972657475726E20655B725D3B72657475726E206E756C6C7D66756E6374696F6E20242865297B72657475726E20652E736F6D652866756E6374696F6E2865297B72657475726E2273756D22213D3D652E66';
wwv_flow_imp.g_varchar2_table(127) := '6E7D297D66756E6374696F6E20712865297B72657475726E206F2865297C7C22737472696E67223D3D747970656F66206526262222213D3D652E7472696D282926262169734E614E284E756D626572286529297D66756E6374696F6E205828652C742C72';
wwv_flow_imp.g_varchar2_table(128) := '297B766172206E3D652E6D61702866756E6374696F6E2865297B72657475726E20655B745D7D292E66696C7465722866756E6374696F6E2865297B72657475726E206E756C6C213D6526262222213D3D657D293B69662822636F756E74223D3D3D722972';
wwv_flow_imp.g_varchar2_table(129) := '657475726E206E2E6C656E6774683B6966282273756D223D3D3D727C7C22617667223D3D3D72297B766172206F3D6E2E66696C7465722871292E6D6170284E756D626572292C613D6F2E7265647563652866756E6374696F6E28652C74297B7265747572';
wwv_flow_imp.g_varchar2_table(130) := '6E20652B747D2C30293B72657475726E2273756D223D3D3D723F613A6F2E6C656E6774683F612F6F2E6C656E6774683A6E756C6C7D766172206C3D6E756C6C2C693D6E756C6C3B72657475726E206E2E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(131) := '76617220743D712865293F6E756C6C3A642865292C6E3D712865293F4E756D6265722865293A743F742E67657454696D6528293A537472696E672865293B286E756C6C3D3D3D697C7C28226D696E223D3D3D723F6E3C693A6E3E6929292626286C3D652C';
wwv_flow_imp.g_varchar2_table(132) := '693D6E297D292C6C7D66756E6374696F6E205A28652C742C722C6E297B766172206F3D242874292C613D2D312C6C3D652E6D61702866756E6374696F6E28652C6E297B766172206C3D652E636F6C3F5928742C652E636F6C293A6E756C6C3B7265747572';
wwv_flow_imp.g_varchar2_table(133) := '6E206C2626613C30262628613D6E292C6C3F66756E6374696F6E28652C742C722C6E297B766172206F2C613D5828722C742E636F6C2C742E666E293B72657475726E286F3D6E756C6C3D3D613F22223A22636F756E74223D3D3D742E666E3F7028612C22';
wwv_flow_imp.g_varchar2_table(134) := '696E7422293A226D696E223D3D3D742E666E7C7C226D6178223D3D3D742E666E3F712861293F7028612C652E666D747C7C226D6F6E657922293A7028612C652E666D74293A22617667223D3D3D742E666E3F7028612C652E666D74262622696E7422213D';
wwv_flow_imp.g_varchar2_table(135) := '3D652E666D743F652E666D743A226D6F6E657922293A7028612C652E666D747C7C226D6F6E657922292926266E2626485B742E666E5D3F485B742E666E5D2B2220222B6F3A6F7D28652C6C2C722C6F293A22227D293B72657475726E7B61743A613C303F';
wwv_flow_imp.g_varchar2_table(136) := '652E6C656E6774683A612C63656C6C733A6C2C746578743A6E7D7D66756E6374696F6E204A28652C742C72297B72657475726E205328652E746F74616C734C6162656C7C7C22546F74616C6573222C742C7B434F554E543A722E6C656E6774687D297D66';
wwv_flow_imp.g_varchar2_table(137) := '756E6374696F6E204B28652C74297B76617220723D7B636F6E74656E743A652E746578742C636F6C5370616E3A652E61747C7C742C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E20303D3D3D652E61743F5B5B725D2C652E';
wwv_flow_imp.g_varchar2_table(138) := '63656C6C732E736C69636528295D3A5B5B725D2E636F6E63617428652E63656C6C732E736C69636528652E617429295D7D66756E6374696F6E20512865297B72657475726E21313D3D3D652E627265616B546F74616C733F5B5D3A562841727261792E69';
wwv_flow_imp.g_varchar2_table(139) := '73417272617928652E627265616B546F74616C73293F652E627265616B546F74616C733A652E746F74616C73297D66756E6374696F6E20656528652C74297B69662821652E627265616B42797C7C21742E6C656E6774682972657475726E20742E6D6170';
wwv_flow_imp.g_varchar2_table(140) := '2866756E6374696F6E28652C74297B72657475726E7B6B3A22726F77222C723A652C693A747D7D293B76617220723D537472696E6728652E627265616B4279292E746F55707065724361736528292C6E3D5B5D2C6F3D6E756C6C2C613D302C6C3D512865';
wwv_flow_imp.g_varchar2_table(141) := '292E6C656E6774683E303B66756E6374696F6E206928297B6F26266C26266E2E70757368287B6B3A22737562222C723A6F2E722C726F77733A6F2E726F77737D297D72657475726E20742E666F72456163682866756E6374696F6E2874297B766172206C';
wwv_flow_imp.g_varchar2_table(142) := '3D537472696E67286E756C6C3D3D3D745B725D7C7C766F696420303D3D3D745B725D3F22223A745B725D293B6F26266F2E6B65793D3D3D6C7C7C286928292C6F3D7B6B65793A6C2C723A742C726F77733A5B5D7D2C2131213D3D652E627265616B546974';
wwv_flow_imp.g_varchar2_table(143) := '6C6526266E2E70757368287B6B3A2268656164222C723A742C726F77733A6F2E726F77737D29292C6F2E726F77732E707573682874292C6E2E70757368287B6B3A22726F77222C723A742C693A612B2B7D297D292C6928292C6E7D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(144) := '746528652C742C72297B766172206E2C6F3D7B7D2C613D537472696E6728652E627265616B4279292E746F55707065724361736528293B666F72286E20696E20742E72296F5B6E5D3D742E725B6E5D3B6F2E434F554E543D742E726F77732E6C656E6774';
wwv_flow_imp.g_varchar2_table(145) := '683B766172206C3D2268656164223D3D3D742E6B3F652E627265616B5469746C653A652E627265616B4C6162656C3B72657475726E206E756C6C213D6C26262130213D3D6C7C7C286C3D2268656164223D3D3D742E6B3F227B222B612B227D223A225375';
wwv_flow_imp.g_varchar2_table(146) := '62746F74616C207B222B612B227D22292C53286C2C722C6F297D66756E6374696F6E20726528652C742C72297B696628652E6D6170297B766172206E3D7828742C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C222229';
wwv_flow_imp.g_varchar2_table(147) := '2E73706C697428227C22295B305D2C72293B72657475726E20766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E';
wwv_flow_imp.g_varchar2_table(148) := '7D7C5D2B5C7D242F2E74657374286F7C7C2222293F70287828742C6F2E736C69636528312C2D31292C72292C652E666D74293A53286F2C742C72297D766172206E653D7B746578743A312C6D756C74696C696E653A312C6C6973743A312C636865636B62';
wwv_flow_imp.g_varchar2_table(149) := '6F783A317D2C6F653D2223463246364641222C61653D2223424643394434222C6C653D22E29892222C69653D22E29890223B66756E6374696F6E2073652865297B76617220743D537472696E67286E756C6C3D3D653F22223A65293B696628212F5E5B41';
wwv_flow_imp.g_varchar2_table(150) := '2D5A612D7A5F5D5B412D5A612D7A302D395F5D7B302C33397D242F2E746573742874297C7C2F5E5B412D5A612D7A5D7B312C337D5B302D395D2B242F2E746573742874297C7C2F5E5B527243635D242F2E746573742874297C7C2F5E5B52725D5B302D39';
wwv_flow_imp.g_varchar2_table(151) := '5D2A5B43635D5B302D395D2A242F2E74657374287429297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F20696E76C3A16C69646F3A2022272B742B27222E20557365206C65747261732C206EC3BA6D65726F732079205F';
wwv_flow_imp.g_varchar2_table(152) := '202868617374612034302C2073696E206573706163696F73206E692070756E746F7329207920717565206E6F20706172657A636120756E612063656C646120646520457863656C202841312C2052314331292E27293B72657475726E20747D66756E6374';
wwv_flow_imp.g_varchar2_table(153) := '696F6E20756528297B76617220653D7B7D3B72657475726E2066756E6374696F6E2874297B76617220723D742E746F4C6F7765724361736528293B696628655B725D297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F20';
wwv_flow_imp.g_varchar2_table(154) := '726570657469646F20656E20656C20646F63756D656E746F3A2022272B742B27222E27293B72657475726E20655B725D3D312C747D7D66756E6374696F6E20636528652C742C72297B766172206E3D4328652C74295B305D7C7C7B7D3B72657475726E28';
wwv_flow_imp.g_varchar2_table(155) := '652E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E7768656E7C7C5428652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E286F297B6966286F2E656D70747929726574';
wwv_flow_imp.g_varchar2_table(156) := '75726E7B656D7074793A21302C7370616E3A6F2E7370616E7D3B76617220613D537472696E67286F2E696E7075747C7C227465787422292E746F4C6F7765724361736528293B696628216E655B615D297468726F77206E6577204572726F722827546970';
wwv_flow_imp.g_varchar2_table(157) := '6F2064652063616D706F206E6F20736F706F727461646F3A2022272B6F2E696E7075742B27222028746578742C206D756C74696C696E652C206C6973742C20636865636B626F78292E27293B766172206C3D7365286F2E6E616D65292B28727C7C222229';
wwv_flow_imp.g_varchar2_table(158) := '2C693D766F696420303D3D3D6F2E76616C75657C7C6E756C6C3D3D3D6F2E76616C75653F22223A537472696E67287265286F2C742C6E29292C733D226C697374223D3D3D613F66756E6374696F6E28652C74297B76617220723D5B5D3B66756E6374696F';
wwv_flow_imp.g_varchar2_table(159) := '6E206E2865297B2222213D3D28653D537472696E67286E756C6C3D3D653F22223A6529292626722E696E6465784F662865293C302626722E707573682865297D6966282841727261792E6973417272617928652E6F7074696F6E73293F652E6F7074696F';
wwv_flow_imp.g_varchar2_table(160) := '6E733A5B5D292E666F7245616368286E292C652E6F7074696F6E7346726F6D297B766172206F3D537472696E6728652E6F7074696F6E7346726F6D292E73706C697428222E22292C613D6F5B315D3F6F5B315D2E746F55707065724361736528293A6E75';
wwv_flow_imp.g_varchar2_table(161) := '6C6C3B43287B736F757263653A6F5B305D7D2C74292E666F72456163682866756E6374696F6E2865297B6E28613F655B615D3A655B4F626A6563742E6B6579732865295B305D5D297D297D72657475726E20727D286F2C74293A5B5D3B696628226C6973';
wwv_flow_imp.g_varchar2_table(162) := '74223D3D3D61262621732E6C656E677468297468726F77206E6577204572726F722827456C2063616D706F2022272B6C2B272220657320756E61206C697374612073696E206F7063696F6E657320286F7074696F6E732075206F7074696F6E7346726F6D';
wwv_flow_imp.g_varchar2_table(163) := '292E27293B76617220752C633D282274657874223D3D3D617C7C226D756C74696C696E65223D3D3D612926264E756D626572286F2E6D61784C656E677468293E303F4D6174682E666C6F6F72284E756D626572286F2E6D61784C656E67746829293A303B';
wwv_flow_imp.g_varchar2_table(164) := '72657475726E226D756C74696C696E6522213D3D61262628693D692E7265706C616365282F5C723F5C6E2F672C22202229292C226C697374223D3D3D612626732E696E6465784F662869293C30262628693D2222292C63262628693D692E737562737472';
wwv_flow_imp.g_varchar2_table(165) := '28302C6329292C7B6C6162656C3A53286F2E6C6162656C2C742C6E292C6E616D653A6C2C696E7075743A612C6F7074696F6E733A732C76616C75653A22636865636B626F78223D3D3D613F22223A692C636865636B65643A22636865636B626F78223D3D';
wwv_flow_imp.g_varchar2_table(166) := '3D61262628753D692C21303D3D3D757C7C2F5E28737C73697C73C3AD7C797C7965737C317C787C747275657C6F6E29242F692E7465737428537472696E67286E756C6C3D3D753F22223A75292E7472696D282929292C6D61784C656E6774683A632C7265';
wwv_flow_imp.g_varchar2_table(167) := '61644F6E6C793A21303D3D3D6F2E726561644F6E6C792C6C696E65733A226D756C74696C696E65223D3D3D613F4D6174682E6D617828322C4D6174682E6D696E2832302C4E756D626572286F2E6C696E6573297C7C3329293A312C706C616365686F6C64';
wwv_flow_imp.g_varchar2_table(168) := '65723A6F2E706C616365686F6C6465723F53286F2E706C616365686F6C6465722C742C6E293A22222C7370616E3A6F2E7370616E2C6C61623A4D65286F2C65297D7D297D66756E6374696F6E20666528652C74297B76617220723D652E666F726D7C7C7B';
wwv_flow_imp.g_varchar2_table(169) := '7D2C6E3D742626766F69642030213D3D742E666F726D50617373776F726426266E756C6C213D3D742E666F726D50617373776F72643F742E666F726D50617373776F72643A722E70617373776F72643B72657475726E7B70726F746563743A2131213D3D';
wwv_flow_imp.g_varchar2_table(170) := '722E70726F746563742C70617373776F72643A6E3F537472696E67286E293A22227D7D66756E6374696F6E2064652865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E206526262822666F726D756C61';
wwv_flow_imp.g_varchar2_table(171) := '72696F223D3D3D652E747970657C7C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E736F6D65286465297C7C22677275706F223D3D3D652E747970652626646528652E73656374696F6E7329297D297D66756E6374';
wwv_flow_imp.g_varchar2_table(172) := '696F6E2068652865297B76617220743D652626652E62617463682626652E62617463682E73756D6D6172793B72657475726E20646528652626652E73656374696F6E73297C7C212821747C7C2128646528742E73656374696F6E73297C7C742E6C61796F';
wwv_flow_imp.g_varchar2_table(173) := '75742626646528742E6C61796F75742E73656374696F6E732929297D7661722070653D5B313131363335323430382C333630393736373435382C313839393434373434312C3630323839313732352C333034393332333437312C33393634343834333939';
wwv_flow_imp.g_varchar2_table(174) := '2C333932313030393537332C323137333239353534382C3936313938373136332C343038313632383437322C313530383937303939332C333035333833343236352C323435333633353734382C323933373637313537392C323837303736333232312C33';
wwv_flow_imp.g_varchar2_table(175) := '3636343630393536302C333632343338313038302C323733343838333339342C3331303539383430312C313136343939363534322C3630373232353237382C313332333631303736342C313432363838313938372C333539303330343939342C31393235';
wwv_flow_imp.g_varchar2_table(176) := '3037383338382C343036383138323338332C323136323037383230362C3939313333363131332C323631343838383130332C3633333830333331372C333234383232323538302C333437393737343836382C333833353339303430312C32363636363133';
wwv_flow_imp.g_varchar2_table(177) := '3435382C343032323232343737342C3934343731313133392C3236343334373037382C323334313236323737332C3630343830373632382C323030373830303933332C3737303235353938332C313439353939303930312C313234393135303132322C31';
wwv_flow_imp.g_varchar2_table(178) := '3835363433313233352C313535353038313639322C333137353231383133322C313939363036343938362C323139383935303833372C323535343232303838322C333939393731393333392C323832313833343334392C3736363738343031362C323935';
wwv_flow_imp.g_varchar2_table(179) := '323939363830382C323536363539343837392C333231303331333637312C333230333333373935362C333333363537313839312C313033343435373032362C333538343532383731312C323436363934383930312C3131333932363939332C3337353833';
wwv_flow_imp.g_varchar2_table(180) := '32363338332C3333383234313839352C3136383731373933362C3636363330373230352C313138383137393936342C3737333532393931322C313534363034353733342C313239343735373337322C313532323830353438352C31333936313832323931';
wwv_flow_imp.g_varchar2_table(181) := '2C323634333833333832332C313639353138333730302C323334333532373339302C313938363636313035312C313031343437373438302C323137373032363335302C313230363735393134322C323435363935363033372C3334343037373632372C32';
wwv_flow_imp.g_varchar2_table(182) := '3733303438353932312C313239303836333436302C323832303330323431312C333135383435343237332C333235393733303830302C333530353935323635372C333334353736343737312C3130363231373030382C333531363036353831372C333630';
wwv_flow_imp.g_varchar2_table(183) := '363030383334342C333630303335323830342C313433323732353737362C343039343537313930392C313436373033313539342C3237353432333334342C3835313136393732302C3433303232373733342C333130303832333735322C35303639343836';
wwv_flow_imp.g_varchar2_table(184) := '31362C313336333235383139352C3635393036303535362C333735303638353539332C3838333939373837372C333738353035303238302C3935383133393537312C333331383330373432372C313332323832323231382C333831323732333430332C31';
wwv_flow_imp.g_varchar2_table(185) := '3533373030323036332C323030333033343939352C313734373837333737392C333630323033363839392C313935353536323232322C313537353939303031322C323032343130343831352C313132353539323932382C323232373733303435322C3237';
wwv_flow_imp.g_varchar2_table(186) := '31363930343330362C323336313835323432342C3434323737363034342C323432383433363437342C3539333639383334342C323735363733343138372C333733333131303234392C333230343033313437392C323939393335313537332C3333323933';
wwv_flow_imp.g_varchar2_table(187) := '32353239382C333831353932303432372C333339313536393631342C333932383338333930302C333531353236373237312C3536363238303731312C333934303138373630362C333435343036393533342C343131383633303237312C34303030323339';
wwv_flow_imp.g_varchar2_table(188) := '3939322C3131363431383437342C313931343133383535342C3137343239323432312C323733313035353237302C3238393338303335362C333230333939333030362C3436303339333236392C3332303632303331352C3638353437313733332C353837';
wwv_flow_imp.g_varchar2_table(189) := '3439363833362C3835323134323937312C313038363739323835312C313031373033363239382C3336353534333130302C313132363030303538302C323631383239373637362C313238383033333437302C333430393835353135382C31353031353035';
wwv_flow_imp.g_varchar2_table(190) := '3934382C343233343530393836362C313630373136373931352C3938373136373436382C313831363430323331362C313234363138393539315D3B66756E6374696F6E2067652865297B76617220742C722C6E3D5B313737393033333730332C34303839';
wwv_flow_imp.g_varchar2_table(191) := '3233353732302C333134343133343237372C323232373837333539352C313031333930343234322C343237313137353732332C323737333438303736322C313539353735303132392C313335393839333131392C323931373536353133372C3236303038';
wwv_flow_imp.g_varchar2_table(192) := '32323932342C3732353531313139392C3532383733343633352C343231353338393534372C313534313435393232352C3332373033333230395D2C6F3D652E6C656E6774682C613D6F2B31372B3132373E3E373C3C372C6C3D6E65772055696E74384172';
wwv_flow_imp.g_varchar2_table(193) := '7261792861292C693D6E657720496E743332417272617928313630293B6C2E7365742865292C6C5B6F5D3D3132383B76617220733D382A6F3B6C5B612D315D3D32353526732C6C5B612D325D3D733E3E3E38263235352C6C5B612D335D3D733E3E3E3136';
wwv_flow_imp.g_varchar2_table(194) := '263235352C6C5B612D345D3D733E3E3E3234263235352C6C5B612D355D3D323535264D6174682E666C6F6F7228732F34323934393637323936293B666F722876617220753D343239343936373239362C633D303B633C613B632B3D313238297B666F7228';
wwv_flow_imp.g_varchar2_table(195) := '743D303B743C33323B742B2B29723D632B342A742C695B745D3D6C5B725D3C3C32347C6C5B722B315D3C3C31367C6C5B722B325D3C3C387C6C5B722B335D3B666F7228743D33323B743C3136303B742B3D32297B76617220663D695B742D33305D2C643D';
wwv_flow_imp.g_varchar2_table(196) := '695B742D32395D2C683D695B742D345D2C703D695B742D335D2C673D28663E3E3E317C643C3C3331295E28663E3E3E387C643C3C3234295E663E3E3E372C6D3D28683E3E3E31397C703C3C3133295E28703E3E3E32397C683C3C33295E683E3E3E362C76';
wwv_flow_imp.g_varchar2_table(197) := '3D28703E3E3E31397C683C3C3133295E28683E3E3E32397C703C3C33295E28703E3E3E367C683C3C3236292C623D282828643E3E3E317C663C3C3331295E28643E3E3E387C663C3C3234295E28643E3E3E377C663C3C323529293E3E3E30292B28695B74';
wwv_flow_imp.g_varchar2_table(198) := '2D31335D3E3E3E30292B28763E3E3E30292B28695B742D33315D3E3E3E30292C773D672B695B742D31345D2B6D2B695B742D33325D2B4D6174682E666C6F6F7228622F75297C303B695B745D3D772C695B742B315D3D307C627D76617220793D6E5B305D';
wwv_flow_imp.g_varchar2_table(199) := '2C783D6E5B315D2C533D6E5B325D2C453D6E5B335D2C543D6E5B345D2C433D6E5B355D2C413D6E5B365D2C7A3D6E5B375D2C4D3D6E5B385D2C4E3D6E5B395D2C463D6E5B31305D2C503D6E5B31315D2C6B3D6E5B31325D2C4F3D6E5B31335D2C6A3D6E5B';
wwv_flow_imp.g_varchar2_table(200) := '31345D2C4C3D6E5B31355D3B666F7228743D303B743C3136303B742B3D32297B76617220523D284D3E3E3E31347C4E3C3C3138295E284D3E3E3E31387C4E3C3C3134295E284E3E3E3E397C4D3C3C3233292C493D4D26465E7E4D266B2C443D284C3E3E3E';
wwv_flow_imp.g_varchar2_table(201) := '30292B2828284E3E3E3E31347C4D3C3C3138295E284E3E3E3E31387C4D3C3C3134295E284D3E3E3E397C4E3C3C323329293E3E3E30292B28284E26505E7E4E264F293E3E3E30292B2870655B742B315D3E3E3E30292B28695B742B315D3E3E3E30292C55';
wwv_flow_imp.g_varchar2_table(202) := '3D6A2B522B492B70655B745D2B695B745D2B4D6174682E666C6F6F7228442F75297C303B447C3D303B76617220423D282828783E3E3E32387C793C3C34295E28793E3E3E327C783C3C3330295E28793E3E3E377C783C3C323529293E3E3E30292B282878';
wwv_flow_imp.g_varchar2_table(203) := '26455E7826435E452643293E3E3E30292C473D2828793E3E3E32387C783C3C34295E28783E3E3E327C793C3C3330295E28783E3E3E377C793C3C323529292B287926535E7926545E532654292B4D6174682E666C6F6F7228422F75297C303B427C3D302C';
wwv_flow_imp.g_varchar2_table(204) := '6A3D6B2C4C3D4F2C6B3D462C4F3D502C463D4D2C503D4E3B76617220573D287A3E3E3E30292B28443E3E3E30293B4D3D412B552B4D6174682E666C6F6F7228572F75297C302C4E3D307C572C413D542C7A3D432C543D532C433D452C533D792C453D782C';
wwv_flow_imp.g_varchar2_table(205) := '573D28443E3E3E30292B28423E3E3E30292C793D552B472B4D6174682E666C6F6F7228572F75297C302C783D307C577D766172205F3D5B792C782C532C452C542C432C412C7A2C4D2C4E2C462C502C6B2C4F2C6A2C4C5D3B666F7228743D303B743C3136';
wwv_flow_imp.g_varchar2_table(206) := '3B742B3D32297B76617220483D286E5B742B315D3E3E3E30292B285F5B742B315D3E3E3E30293B6E5B745D3D6E5B745D2B5F5B745D2B4D6174682E666C6F6F7228482F75297C302C6E5B742B315D3D307C487D7D76617220563D6E65772055696E743841';
wwv_flow_imp.g_varchar2_table(207) := '72726179283634293B666F7228743D303B743C31363B742B2B29565B342A745D3D6E5B745D3E3E3E32342C565B342A742B315D3D6E5B745D3E3E3E3136263235352C565B342A742B325D3D6E5B745D3E3E3E38263235352C565B342A742B335D3D323535';
wwv_flow_imp.g_varchar2_table(208) := '266E5B745D3B72657475726E20567D766172206D653D5B35373834302C373433392C35323338302C33333938342C343336342C333630302C36313930322C31323630362C363235382C35373635372C35343238372C33343034312C31303235322C343333';
wwv_flow_imp.g_varchar2_table(209) := '37302C32303136335D2C76653D5B5B34343739362C31393932392C33393835382C31303035332C32303130362C34303231322C31303736315D2C5B33313538352C36333137302C36343933332C36303236372C35303933352C34303339392C3131313939';
wwv_flow_imp.g_varchar2_table(210) := '5D2C5B31373736332C33353532362C313435332C323930362C353831322C31313632342C32333234385D2C5B3838352C313737302C333534302C373038302C31343136302C32383332302C35363634305D2C5B35353336392C34313133392C3230383037';
wwv_flow_imp.g_varchar2_table(211) := '2C34313631342C32313832312C34333634322C31373632315D2C5B32383438352C35363937302C34343334312C31393031392C33383033382C31343630352C32393231305D2C5B36303139352C35303739312C34303137352C31303735312C3231353032';
wwv_flow_imp.g_varchar2_table(212) := '2C34333030342C32343533375D2C5B31383338372C33363737342C333934392C373839382C31353739362C33313539322C36333138345D2C5B34373230312C32343830332C34393630362C33373830352C31343230332C32383430362C35363831325D2C';
wwv_flow_imp.g_varchar2_table(213) := '5B31373832342C33353634382C313639372C333339342C363738382C31333537362C32373135325D2C5B34333630312C31373533392C33353037382C3535372C313131342C323232382C343435365D2C5B33303338382C36303737362C35313935332C33';
wwv_flow_imp.g_varchar2_table(214) := '343234332C373037392C31343135382C32383331365D2C5B31343132382C32383235362C35363531322C34333432352C31373235312C33343530322C373539375D2C5B31333130352C32363231302C35323432302C33353234312C3838332C313736362C';
wwv_flow_imp.g_varchar2_table(215) := '333533325D2C5B343132392C383235382C31363531362C33333033322C343635372C393331342C31383632385D5D3B66756E6374696F6E2062652865297B76617220742C722C6E3D5B5D2C6F3D66756E6374696F6E2865297B72657475726E28653C3136';
wwv_flow_imp.g_varchar2_table(216) := '3F2230223A2222292B652E746F537472696E67283136292E746F55707065724361736528297D3B666F7228743D303B743C652E6C656E6774683B742B2B297B76617220613D652E63686172436F646541742874293B6E2E707573682832353526617C7C61';
wwv_flow_imp.g_varchar2_table(217) := '3E3E3826323535297D766172206C3D6D655B6E2E6C656E6774682D315D2C693D31352D6E2E6C656E6774682C733D303B666F7228743D303B743C6E2E6C656E6774683B742B2B297B76617220753D6E5B745D2C633D76655B692B2B5D3B666F7228723D30';
wwv_flow_imp.g_varchar2_table(218) := '3B723C373B722B2B293126752626286C5E3D635B725D292C753E3E3D317D66756E6374696F6E20662865297B72657475726E20653E3E313426317C653C3C312633323736377D666F7228743D6E2E6C656E6774682D313B743E3D303B742D2D29733D6628';
wwv_flow_imp.g_varchar2_table(219) := '73295E6E5B745D3B72657475726E206F283235352628733D662873295E6E2E6C656E6774685E353238313129292B6F28733E3E3826323535292B6F28323535266C292B6F286C3E3E3826323535297D66756E6374696F6E20776528652C742C72297B6966';
wwv_flow_imp.g_varchar2_table(220) := '28212F5E5B5C7832302D5C7837455D7B312C31357D242F2E74657374286529297468726F77206E6577204572726F7228224C6120636F6E7472617365C3B1612064652070726F7465636369C3B36E20646520576F72642061646D69746520646520312061';
wwv_flow_imp.g_varchar2_table(221) := '2031352063617261637465726573204153434949202873696E2074696C646573206E6920C3B1292E22293B766172206E2C6F3D62652865292C613D6E65772055696E7438417272617928742E6C656E6774682B322A6F2E6C656E677468293B666F722861';
wwv_flow_imp.g_varchar2_table(222) := '2E7365742874292C6E3D303B6E3C6F2E6C656E6774683B6E2B2B29615B742E6C656E6774682B322A6E5D3D6F2E63686172436F64654174286E293B766172206C3D67652861292C693D6E65772055696E74384172726179283638293B666F72286E3D303B';
wwv_flow_imp.g_varchar2_table(223) := '6E3C723B6E2B2B29692E736574286C292C695B36345D3D323535266E2C695B36355D3D6E3E3E3E38263235352C695B36365D3D6E3E3E3E3136263235352C695B36375D3D6E3E3E3E3234263235352C6C3D67652869293B72657475726E206C7D76617220';
wwv_flow_imp.g_varchar2_table(224) := '79653D2223443544434533223B66756E6374696F6E20786528652C74297B76617220723D652E6C6162656C5769647468733B72657475726E2041727261792E6973417272617928722926264E756D62657228725B745D293E303F4E756D62657228725B74';
wwv_flow_imp.g_varchar2_table(225) := '5D293A652E6C6162656C57696474687C7C33327D66756E6374696F6E20536528652C74297B76617220723D652E68656164416C69676E7C7C742E68656164416C69676E7C7C2263656E746572223B72657475726E226175746F223D3D3D723F652E616C69';
wwv_flow_imp.g_varchar2_table(226) := '676E3A727D66756E6374696F6E20456528652C74297B76617220723D5B5D2C6E3D5B5D2C6F3D303B72657475726E20652E666F72456163682866756E6374696F6E2865297B76617220613D65262622726F77223D3D3D652E7370616E3F742D6F3A4D6174';
wwv_flow_imp.g_varchar2_table(227) := '682E6D617828312C4D6174682E6D696E28742C4D6174682E666C6F6F72284E756D62657228652626652E7370616E29297C7C3129293B6F2B613E74262628722E70757368286E292C6E3D5B5D2C6F3D30292C6E2E70757368287B663A652C636F6C3A6F2C';
wwv_flow_imp.g_varchar2_table(228) := '7370616E3A612C656D7074793A212821657C7C21652E656D707479297D292C286F2B3D61293D3D3D74262628722E70757368286E292C6E3D5B5D2C6F3D30297D292C6E2E6C656E6774682626722E70757368286E292C727D66756E6374696F6E20546528';
wwv_flow_imp.g_varchar2_table(229) := '65297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E2065262628652E656D7074797C7C652E7370616E262631213D3D652E7370616E297D297D66756E6374696F6E2043652865297B72657475726E20652E';
wwv_flow_imp.g_varchar2_table(230) := '7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E7370616E7D2C30297D66756E6374696F6E20416528652C742C72297B72657475726E2065262628652E616C69676E7C7C652E626F6C647C7C652E636F6C6F727C7C652E66';
wwv_flow_imp.g_varchar2_table(231) := '696C6C293F7B616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E7465737428652E616C69676E7C7C2222293F652E616C69676E3A6E756C6C2C626F6C643A2121652E626F6C642C636F6C6F723A652E636F6C6F723F4128652E63';
wwv_flow_imp.g_varchar2_table(232) := '6F6C6F722C742C72293A6E756C6C2C66696C6C3A652E66696C6C7C7C6E756C6C7D3A6E756C6C7D766172207A653D7B6C6566743A312C746F703A312C6E6F6E653A317D3B66756E6374696F6E204D6528652C74297B66756E6374696F6E20722872297B72';
wwv_flow_imp.g_varchar2_table(233) := '657475726E20652626766F69642030213D3D655B725D26266E756C6C213D3D655B725D26262222213D3D655B725D3F655B725D3A745B725D7D766172206E3D537472696E67287228226C6162656C506F736974696F6E22297C7C226C65667422292E746F';
wwv_flow_imp.g_varchar2_table(234) := '4C6F7765724361736528292C6F3D7228226C6162656C416C69676E22292C613D7228226C6162656C426F6C6422292C6C3D7B706F733A7A655B6E5D3F6E3A226C656674222C73697A653A4E756D626572287228226C6162656C53697A652229293E303F4E';
wwv_flow_imp.g_varchar2_table(235) := '756D626572287228226C6162656C53697A652229293A302C636F6C6F723A7228226C6162656C436F6C6F7222297C7C6E756C6C2C626F6C643A6E756C6C3D3D617C7C2131213D3D6126262266616C736522213D3D612C75707065723A227570706572223D';
wwv_flow_imp.g_varchar2_table(236) := '3D3D537472696E67287228226C6162656C4361736522297C7C2222292E746F4C6F7765724361736528292C616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E74657374286F7C7C2222293F6F3A6E756C6C2C66696C6C3A722822';
wwv_flow_imp.g_varchar2_table(237) := '6C6162656C46696C6C22297C7C6E756C6C7D3B72657475726E206C2E7374796C65643D212821657C7C2128652E6C6162656C53697A657C7C652E6C6162656C436F6C6F727C7C766F69642030213D3D652E6C6162656C426F6C6426266E756C6C213D3D65';
wwv_flow_imp.g_varchar2_table(238) := '2E6C6162656C426F6C647C7C652E6C6162656C436173657C7C652E6C6162656C416C69676E7C7C652E6C6162656C46696C6C29297C7C212128742E6C6162656C53697A657C7C766F69642030213D3D742E6C6162656C426F6C6426266E756C6C213D3D74';
wwv_flow_imp.g_varchar2_table(239) := '2E6C6162656C426F6C647C7C742E6C6162656C436173657C7C742E6C6162656C416C69676E292C6C7D66756E6374696F6E204E6528652C742C722C6E297B766172206F3D7B626F6C643A742E626F6C647D3B28742E73697A657C7C72292626286F2E7369';
wwv_flow_imp.g_varchar2_table(240) := '7A653D742E73697A657C7C39292C742E636F6C6F722626286F2E636F6C6F723D7B617267623A6C28742E636F6C6F72297D292C652E666F6E743D6F3B76617220613D742E616C69676E7C7C28723F6E3A6E756C6C293B696628617C7C72297B7661722069';
wwv_flow_imp.g_varchar2_table(241) := '3D7B7D3B4F626A6563742E6B65797328652E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2874297B695B745D3D652E616C69676E6D656E745B745D7D292C61262628692E686F72697A6F6E74616C3D61292C7226262869';
wwv_flow_imp.g_varchar2_table(242) := '2E766572746963616C3D22626F74746F6D22292C652E616C69676E6D656E743D697D742E66696C6C262628652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6C28742E';
wwv_flow_imp.g_varchar2_table(243) := '66696C6C297D7D297D66756E6374696F6E20466528652C74297B72657475726E20742E75707065723F537472696E672865292E746F55707065724361736528293A657D66756E6374696F6E2050652865297B72657475726E28652E6669656C64737C7C5B';
wwv_flow_imp.g_varchar2_table(244) := '5D292E736F6D652866756E6374696F6E2874297B72657475726E2074262621742E656D7074792626226C65667422213D3D4D6528742C65292E706F737D297D66756E6374696F6E206B6528652C74297B72657475726E20652E73697A657C7C4D6174682E';
wwv_flow_imp.g_varchar2_table(245) := '6D617828352C4D6174682E726F756E6428312E372A74292F32297D66756E6374696F6E204F6528652C74297B72657475726E2E333532382A6B6528652C74292A312E322B2E347D66756E6374696F6E206A652865297B76617220743D7B666F6E74537479';
wwv_flow_imp.g_varchar2_table(246) := '6C653A652E626F6C643F22626F6C64223A226E6F726D616C227D3B72657475726E20652E73697A65262628742E666F6E7453697A653D652E73697A65292C652E636F6C6F72262628742E74657874436F6C6F723D6128652E636F6C6F7229292C652E6669';
wwv_flow_imp.g_varchar2_table(247) := '6C6C262628742E66696C6C436F6C6F723D6128652E66696C6C29292C652E616C69676E262628742E68616C69676E3D652E616C69676E292C747D66756E6374696F6E204C6528652C742C722C6E2C6F297B766172206C3D722E6C622C693D6B65286C2C6E';
wwv_flow_imp.g_varchar2_table(248) := '292C733D2E333532382A693B6966286C2E66696C6C297B76617220753D61286C2E66696C6C293B652E73657446696C6C436F6C6F7228755B305D2C755B315D2C755B325D292C652E7265637428742E782B2E312C742E792B2E312C742E77696474682D2E';
wwv_flow_imp.g_varchar2_table(249) := '322C6F2B312E322A732B2E312C224622297D76617220633D61286C2E636F6C6F727C7C222330303030303022292C663D4D6174682E6D617828352C742E77696474682D322A6F293B652E736574466F6E74282268656C766574696361222C6C2E626F6C64';
wwv_flow_imp.g_varchar2_table(250) := '3F22626F6C64223A226E6F726D616C22292C652E736574466F6E7453697A652869292C652E73657454657874436F6C6F7228635B305D2C635B315D2C635B325D293B76617220643D227269676874223D3D3D722E616C69676E3F742E782B742E77696474';
wwv_flow_imp.g_varchar2_table(251) := '682D6F3A2263656E746572223D3D3D722E616C69676E3F742E782B742E77696474682F323A742E782B6F3B652E7465787428652E73706C697454657874546F53697A6528537472696E6728722E74657874292C66295B305D7C7C22222C642C742E792B6F';
wwv_flow_imp.g_varchar2_table(252) := '2B2E39352A732C7B616C69676E3A227269676874223D3D3D722E616C69676E7C7C2263656E746572223D3D3D722E616C69676E3F722E616C69676E3A226C656674227D292C652E736574466F6E74282268656C766574696361222C226E6F726D616C2229';
wwv_flow_imp.g_varchar2_table(253) := '2C652E73657454657874436F6C6F7228302C302C30297D66756E6374696F6E20526528652C74297B72657475726E7B73697A653A652E73697A657C7C31342C73756253697A653A652E7375627469746C6553697A657C7C392C726967687453697A653A65';
wwv_flow_imp.g_varchar2_table(254) := '2E726967687453697A657C7C392C666F6E743A4D5B4E28652E666F6E74295D2C66696C6C3A652E66696C6C7C7C742E7072696D6172792C636F6C6F723A652E636F6C6F727C7C742E68656164546578747D7D66756E6374696F6E20496528652C742C7229';
wwv_flow_imp.g_varchar2_table(255) := '7B766172206E3D4328652C74295B305D7C7C7B7D2C6F3D28652E6669656C64737C7C652E6974656D737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E2065262621652E656D70747926262821652E7768656E7C7C5428652E';
wwv_flow_imp.g_varchar2_table(256) := '7768656E2C742C6E29297D292E6D61702866756E6374696F6E2865297B72657475726E7B6C6162656C3A5328652E6C6162656C2C742C6E292C76616C75653A726528652C742C6E292C636F6C6F723A652E636F6C6F723F4128652E636F6C6F722C742C6E';
wwv_flow_imp.g_varchar2_table(257) := '293A6E756C6C7D7D293B72657475726E7B6974656D733A6F2C6E3A4D6174682E6D617828312C4D6174682E6D696E28362C4E756D62657228652E636F6C756D6E73297C7C4D6174682E6D696E286F2E6C656E6774682C36297C7C3129292C66696C6C3A65';
wwv_flow_imp.g_varchar2_table(258) := '2E66696C6C7C7C2223463146344632222C616363656E743A766F696420303D3D3D652E616363656E743F722E7072696D6172793A652E616363656E742C6C6162656C436F6C6F723A652E6C6162656C436F6C6F727C7C2223373837383738222C76616C75';
wwv_flow_imp.g_varchar2_table(259) := '65436F6C6F723A652E76616C7565436F6C6F727C7C722E7072696D6172792C6C6162656C53697A653A652E6C6162656C53697A657C7C372C73697A653A652E73697A657C7C31312C636172644761703A766F69642030213D3D652E636172644761703F4E';
wwv_flow_imp.g_varchar2_table(260) := '756D62657228652E63617264476170293A337D7D66756E6374696F6E20446528652C742C72297B766172206E3D66756E6374696F6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D3029';
wwv_flow_imp.g_varchar2_table(261) := '26262821727C7C486528652C7229297D2C6F3D28652E73656374696F6E737C7C5B5D292E66696C746572286E293B72657475726E20723F47286F292E66696C746572286E293A6F7D7661722055653D7B66696368613A312C666F726D756C6172696F3A31';
wwv_flow_imp.g_varchar2_table(262) := '2C7461726A657461733A312C746578746F3A312C696D6167656E3A312C636F6469676F3A312C616C657274613A312C6C696E65613A312C7461626C613A312C6772616669636F3A312C6573706163696F3A312C636F6C756D6E61733A312C677275706F3A';
wwv_flow_imp.g_varchar2_table(263) := '317D2C42653D7B6C696E65613A312C6573706163696F3A312C636F6C756D6E61733A312C677275706F3A317D3B66756E6374696F6E20476528652C742C72297B766172206E3D66756E6374696F6E2865297B72657475726E2065262655655B652E747970';
wwv_flow_imp.g_varchar2_table(264) := '655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30292626486528652C72297D3B72657475726E2047282841727261792E6973417272617928652E73656374696F6E73293F652E73656374696F6E733A5B';
wwv_flow_imp.g_varchar2_table(265) := '5D292E66696C746572286E292E6D61702866756E6374696F6E2874297B696628742E736F757263657C7C21652E736F757263657C7C42655B742E747970655D2972657475726E20743B76617220723D492874293B72657475726E20722E736F757263653D';
wwv_flow_imp.g_varchar2_table(266) := '652E736F757263652C727D29292E66696C746572286E297D66756E6374696F6E20576528652C74297B69662821652E656163687C7C21652E736F757263652972657475726E5B7B6374783A742C7375663A22227D5D3B76617220723D537472696E672865';
wwv_flow_imp.g_varchar2_table(267) := '2E736F75726365292E746F55707065724361736528292C6E3D4328652C74292C6F3D652E6C696E6B7C7C7B7D3B72657475726E204E756D62657228652E6D6178293E302626286E3D6E2E736C69636528302C4E756D62657228652E6D61782929292C6E2E';
wwv_flow_imp.g_varchar2_table(268) := '6D61702866756E6374696F6E28652C6E297B76617220612C6C3D492874292C693D4928742E646F637C7C7B7D293B666F72286120696E206C2E533D4928742E53292C6C2E535B725D3D5B655D2C4F626A6563742E6B657973286F292E666F724561636828';
wwv_flow_imp.g_varchar2_table(269) := '66756E6374696F6E2872297B766172206E3D6F5B725D7C7C7B7D2C613D537472696E672872292E746F55707065724361736528293B6C2E535B615D3D28742E535B615D7C7C5B5D292E66696C7465722866756E6374696F6E2874297B72657475726E204F';
wwv_flow_imp.g_varchar2_table(270) := '626A6563742E6B657973286E292E65766572792866756E6374696F6E2872297B72657475726E20537472696E6728745B722E746F55707065724361736528295D293D3D3D537472696E6728655B537472696E67286E5B725D292E746F5570706572436173';
wwv_flow_imp.g_varchar2_table(271) := '6528295D297D297D297D292C65294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C6129262628695B615D3D655B615D293B72657475726E206C2E646F633D692C7B6374783A6C2C7375663A225F222B28';
wwv_flow_imp.g_varchar2_table(272) := '6E2B31297D7D297D66756E6374696F6E205F6528652C742C722C6E297B766172206F3D2841727261792E6973417272617928652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33292C613D6F2E6C656E6774683B696628216129726574';
wwv_flow_imp.g_varchar2_table(273) := '75726E5B5D3B766172206C3D6F2E6D61702866756E6374696F6E28742C72297B766172206E3D4E756D6265722828652E7769647468737C7C5B5D295B725D293B72657475726E206E3E303F6E3A3130302F617D292C693D6C2E7265647563652866756E63';
wwv_flow_imp.g_varchar2_table(274) := '74696F6E28652C74297B72657475726E20652B747D2C30292C733D766F69642030213D3D652E636F6C4761703F4E756D62657228652E636F6C476170293A342C753D6E2D732A28612D31292C633D303B72657475726E206F2E6D61702866756E6374696F';
wwv_flow_imp.g_varchar2_table(275) := '6E28652C6E297B766172206F3D752A6C5B6E5D2F692C613D47282841727261792E697341727261792865293F653A5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E666F726D6174737C7C652E666F726D6174';
wwv_flow_imp.g_varchar2_table(276) := '732E696E6465784F662874293E3D30297D29292E66696C7465722866756E6374696F6E2865297B72657475726E2065262655655B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30292626';
wwv_flow_imp.g_varchar2_table(277) := '486528652C72297D292E6D61702866756E6374696F6E2865297B72657475726E2066756E6374696F6E28652C74297B76617220722C6E3D7B7D3B666F72287220696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F7065727479';
wwv_flow_imp.g_varchar2_table(278) := '2E63616C6C28652C72292626286E5B725D3D655B725D293B6966285B2278222C2279222C227831222C227931222C227832222C227932225D2E666F72456163682866756E6374696F6E2865297B64656C657465206E5B655D7D292C22696D6167656E223D';
wwv_flow_imp.g_varchar2_table(279) := '3D3D6E2E747970652626286E2E5F6D6178573D74292C226772616669636F223D3D3D6E2E74797065297B766172206F3D6E2E77696474687C7C3132302C613D6E2E6865696768747C7C37303B6F3E742626286E2E77696474683D742C6E2E686569676874';
wwv_flow_imp.g_varchar2_table(280) := '3D612A742F6F297D72657475726E22636F6469676F223D3D3D6E2E74797065262628227172223D3D3D537472696E67286E2E6B696E647C7C22717222292E746F4C6F7765724361736528292626286E2E73697A657C7C3330293E742626286E2E73697A65';
wwv_flow_imp.g_varchar2_table(281) := '3D74292C6E2E776964746826266E2E77696474683E742626286E2E77696474683D7429292C28226C696E6561223D3D3D6E2E747970657C7C22746578746F223D3D3D6E2E747970652926266E2E776964746826266E2E77696474683E742626286E2E7769';
wwv_flow_imp.g_varchar2_table(282) := '6474683D74292C6E7D28652C6F297D292C663D7B783A632C773A6F2C736563733A617D3B72657475726E20632B3D6F2B732C667D297D66756E6374696F6E20486528652C74297B72657475726E22616C65727461223D3D3D652E747970657C7C21652E77';
wwv_flow_imp.g_varchar2_table(283) := '68656E7C7C5428652E7768656E2C742C6E756C6C297D66756E6374696F6E2056652865297B76617220742C723D7B7D3B666F72287420696E206E29725B745D3D6E5B745D3B766172206F3D652E706167652626652E706167652E7468656D657C7C7B7D3B';
wwv_flow_imp.g_varchar2_table(284) := '666F72287420696E206F29725B745D3D6F5B745D3B72657475726E20727D7661722059653D7B7D2C24653D7B7D3B66756E6374696F6E2071652865297B76617220743D77696E646F772E617065782626617065782E656E767C7C7B7D3B72657475726E20';
wwv_flow_imp.g_varchar2_table(285) := '537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C2222292E7265706C6163652822234150505F494D4147455323222C742E4150505F46494C45537C7C2222292E7265706C616365';
wwv_flow_imp.g_varchar2_table(286) := '282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C616365282223494D4147455F50524546495823222C742E415045585F46494C45537C7C2222297D66756E6374696F6E2058652865';
wwv_flow_imp.g_varchar2_table(287) := '297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B315D2972657475726E7B773A28745B31365D3C3C32347C745B31375D3C3C31367C745B31385D3C3C387C745B31395D293E3E3E30';
wwv_flow_imp.g_varchar2_table(288) := '2C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22706E67227D3B6966283235353D3D3D745B305D26263231363D3D3D745B315D29666F722876617220723D323B723C742E6C656E';
wwv_flow_imp.g_varchar2_table(289) := '6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B335D3B6966286E3E3D31393226266E3C3D3230372626313936213D3D6E2626323030213D3D6E2626323034213D3D6E29726574';
wwv_flow_imp.g_varchar2_table(290) := '75726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A7067227D3B722B3D322B6F7D656C736520722B2B3B7468726F77206E6577204572726F722822466F726D61746F20646520696D61';
wwv_flow_imp.g_varchar2_table(291) := '67656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E205A652865297B666F722876617220743D6E65772055696E743841727261792865292C723D22222C6E3D303B6E3C742E6C656E6774683B6E';
wwv_flow_imp.g_varchar2_table(292) := '2B3D333237363829722B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E7375626172726179286E2C6E2B333237363829293B72657475726E2062746F612872297D66756E6374696F6E204A652865297B7265747572';
wwv_flow_imp.g_varchar2_table(293) := '6E2050726F6D6973652E616C6C2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B65262622696D6167656E223D3D3D652E74797065262665';
wwv_flow_imp.g_varchar2_table(294) := '2E75726C262621652E6669656C642626742E7075736828652E75726C292C65262622636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F72456163682872292C652626425B652E747970655D2626722828652E666965';
wwv_flow_imp.g_varchar2_table(295) := '6C64737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C65262622677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C652626227461626C61223D3D3D652E74797065';
wwv_flow_imp.g_varchar2_table(296) := '262628652E636F6C756D6E737C7C5B5D292E666F72456163682866756E6374696F6E2865297B652626652E63656C6C262622696D6167656E223D3D3D652E63656C6C2E747970652626652E63656C6C2E75726C262621652E63656C6C2E6669656C642626';
wwv_flow_imp.g_varchar2_table(297) := '537472696E6728652E63656C6C2E75726C292E696E6465784F6628227B22293C302626742E7075736828652E63656C6C2E75726C297D297D297D72657475726E207228652E73656374696F6E73292C652E62617463682626652E62617463682E73756D6D';
wwv_flow_imp.g_varchar2_table(298) := '6172792626287228652E62617463682E73756D6D6172792E73656374696F6E73292C652E62617463682E73756D6D6172792E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F75742E73656374696F6E7329292C747D2865292E';
wwv_flow_imp.g_varchar2_table(299) := '6D61702866756E6374696F6E2865297B76617220743D71652865293B72657475726E2059655B745D3F6E756C6C3A666574636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(300) := '69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20636172676172206C6120696D6167656E20222B742B222028222B652E7374617475732B222922293B72657475726E20652E617272617942756666657228297D';
wwv_flow_imp.g_varchar2_table(301) := '292E7468656E2866756E6374696F6E2865297B76617220723D58652865293B59655B745D3D7B6275663A652C773A722E772C683A722E682C6578743A722E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D722E6578743F';
wwv_flow_imp.g_varchar2_table(302) := '226A706567223A22706E6722292B223B6261736536342C222B5A652865297D7D297D29297D66756E6374696F6E204B652865297B76617220743D537472696E672865292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C61';
wwv_flow_imp.g_varchar2_table(303) := '6365282F5C732B2F672C2222293B69662821742972657475726E206E756C6C3B76617220723D226236343A222B742E6C656E6774682B223A222B742E73756273747228302C3634292B742E737562737472282D3634293B69662859655B725D2972657475';
wwv_flow_imp.g_varchar2_table(304) := '726E2059655B725D3B666F7228766172206E3D61746F622874292C6F3D6E65772055696E74384172726179286E2E6C656E677468292C613D303B613C6E2E6C656E6774683B612B2B296F5B615D3D6E2E63686172436F646541742861293B766172206C3D';
wwv_flow_imp.g_varchar2_table(305) := '5865286F2E627566666572293B72657475726E2059655B725D3D7B6275663A6F2E6275666665722C773A6C2E772C683A6C2E682C6578743A6C2E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D6C2E6578743F226A7065';
wwv_flow_imp.g_varchar2_table(306) := '67223A22706E6722292B223B6261736536342C222B747D2C59655B725D7D66756E6374696F6E20516528652C74297B696628652E6669656C64297B76617220723D2828652E736F757263653F4328652C74295B305D3A742E646F63297C7C7B7D295B5374';
wwv_flow_imp.g_varchar2_table(307) := '72696E6728652E6669656C64292E746F55707065724361736528295D3B7472797B72657475726E20723F4B652872293A6E756C6C7D63617463682874297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E';
wwv_flow_imp.g_varchar2_table(308) := '6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B652E6669656C642C74292C6E756C6C7D7D72657475726E2059655B716528652E75726C295D7C7C6E756C6C7D66756E6374696F6E20657428652C74297B76617220723D';
wwv_flow_imp.g_varchar2_table(309) := '652E77696474687C7C34302C6E3D652E6865696768747C7C722A742E682F742E773B72657475726E21652E77696474682626652E686569676874262628723D6E2A742E772F742E68292C652E5F6D6178572626723E652E5F6D6178572626286E3D6E2A65';
wwv_flow_imp.g_varchar2_table(310) := '2E5F6D6178572F722C723D652E5F6D617857292C7B773A722C683A6E7D7D66756E6374696F6E2074742865297B666F722876617220743D61746F622865292C723D6E65772055696E7438417272617928742E6C656E677468292C6E3D303B6E3C742E6C65';
wwv_flow_imp.g_varchar2_table(311) := '6E6774683B6E2B2B29725B6E5D3D742E63686172436F64654174286E293B72657475726E20722E6275666665727D66756E6374696F6E20727428652C742C72297B72657475726E7B6275663A747428652E7265706C616365282F5E646174613A5B5E2C5D';
wwv_flow_imp.g_varchar2_table(312) := '2A2C2F2C222229292C646174613A652C773A742C683A722C6578743A22706E67227D7D66756E6374696F6E206E7428652C74297B69662822756E646566696E6564223D3D747970656F6620646F63756D656E747C7C21646F63756D656E742E6372656174';
wwv_flow_imp.g_varchar2_table(313) := '65456C656D656E74297468726F77206E6577204572726F722822536520726571756965726520756E206E6176656761646F72202863616E7661732920706172612067656E65726172206772C3A16669636F732E22293B76617220723D646F63756D656E74';
wwv_flow_imp.g_varchar2_table(314) := '2E637265617465456C656D656E74282263616E76617322293B72657475726E20722E77696474683D652C722E6865696768743D742C727D766172206F743D6E756C6C3B66756E6374696F6E2061742865297B72657475726E5B653E3E3E3234263235352C';
wwv_flow_imp.g_varchar2_table(315) := '653E3E3E3136263235352C653E3E3E38263235352C32353526655D7D66756E6374696F6E206C7428652C74297B76617220723D5B652E63686172436F646541742830292C652E63686172436F646541742831292C652E63686172436F646541742832292C';
wwv_flow_imp.g_varchar2_table(316) := '652E63686172436F646541742833295D2C6E3D6E65772055696E7438417272617928342B742E6C656E677468293B6E2E73657428722C30292C6E2E73657428742C34293B766172206F3D6E65772055696E743841727261792831322B742E6C656E677468';
wwv_flow_imp.g_varchar2_table(317) := '293B72657475726E206F2E73657428617428742E6C656E677468292C30292C6F2E736574286E2C34292C6F2E7365742861742866756E6374696F6E2865297B696628216F74297B6F743D5B5D3B666F722876617220743D303B743C3235363B742B2B297B';
wwv_flow_imp.g_varchar2_table(318) := '666F722876617220723D742C6E3D303B6E3C383B6E2B2B29723D3126723F333938383239323338345E723E3E3E313A723E3E3E313B6F745B745D3D723E3E3E307D7D666F7228766172206F3D343239343936373239352C613D303B613C652E6C656E6774';
wwv_flow_imp.g_varchar2_table(319) := '683B612B2B296F3D6F745B32353526286F5E655B615D295D5E6F3E3E3E383B72657475726E28343239343936373239355E6F293E3E3E307D286E29292C382B742E6C656E677468292C6F7D66756E6374696F6E20697428652C742C722C6E297B76617220';
wwv_flow_imp.g_varchar2_table(320) := '6F2C6C2C693D4D6174682E6365696C28652F38292B312C733D6E65772055696E7438417272617928692A74293B666F72286C3D303B6C3C743B6C2B2B29666F72286F3D303B6F3C653B6F2B2B2972286F2C6C29262628735B6C2A692B312B286F3E3E3329';
wwv_flow_imp.g_varchar2_table(321) := '5D7C3D3132383E3E2837266F29293B76617220752C633D4D6174682E6365696C28732E6C656E6774682F3635353335292C663D6E65772055696E7438417272617928322B732E6C656E6774682B352A632B34292C643D322C683D312C703D303B666F7228';
wwv_flow_imp.g_varchar2_table(322) := '665B305D3D3132302C665B315D3D312C753D303B753C633B752B2B297B76617220673D36353533352A752C6D3D4D6174682E6D696E2836353533352C732E6C656E6774682D67293B665B642B2B5D3D753D3D3D632D313F313A302C665B642B2B5D3D3235';
wwv_flow_imp.g_varchar2_table(323) := '35266D2C665B642B2B5D3D6D3E3E382C665B642B2B5D3D323535267E6D2C665B642B2B5D3D7E6D3E3E38263235352C662E73657428732E737562617272617928672C672B6D292C64292C642B3D6D7D666F7228753D303B753C732E6C656E6774683B752B';
wwv_flow_imp.g_varchar2_table(324) := '2B29703D28702B28683D28682B735B755D2925363535323129292536353532313B662E7365742861742828703C3C31367C68293E3E3E30292C64293B76617220763D6E65772055696E74384172726179283133292C623D61286E7C7C2223303030303030';
wwv_flow_imp.g_varchar2_table(325) := '22293B762E7365742861742865292C30292C762E7365742861742874292C34292C765B385D3D312C765B395D3D333B76617220773D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31332C31302C32362C31305D292C6C7428';
wwv_flow_imp.g_varchar2_table(326) := '2249484452222C76292C6C742822504C5445222C6E65772055696E74384172726179285B3235352C3235352C3235352C625B305D2C625B315D2C625B325D5D29292C6C74282249444154222C66292C6C74282249454E44222C6E65772055696E74384172';
wwv_flow_imp.g_varchar2_table(327) := '726179283029295D2C793D772E7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E6C656E6774687D2C30292C783D6E65772055696E743841727261792879292C533D303B72657475726E20772E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(328) := '6374696F6E2865297B782E73657428652C53292C532B3D652E6C656E6774687D292C7B6275663A782E6275666665722C646174613A22646174613A696D6167652F706E673B6261736536342C222B5A6528782E627566666572292C773A652C683A742C65';
wwv_flow_imp.g_varchar2_table(329) := '78743A22706E67227D7D7661722073743D2232313232323220323232313232203232323232312031323132323320313231333232203133313232322031323232313320313232333132203133323231322032323132313320323231333132203233313231';
wwv_flow_imp.g_varchar2_table(330) := '32203131323233322031323231333220313232323331203131333232322031323331323220313233323231203232333231312032323131333220323231323331203231333231322032323331313220333132313331203331313232322033323131323220';
wwv_flow_imp.g_varchar2_table(331) := '33323132323120333132323132203332323131322033323232313120323132313233203231323332312032333231323120313131333233203133313132332031333133323120313132333133203133323131332031333233313120323131333133203233';
wwv_flow_imp.g_varchar2_table(332) := '31313133203233313331312031313231333320313132333331203133323133312031313331323320313133333231203133333132312033313331323120323131333331203233313133312032313331313320323133333131203231333133312033313131';
wwv_flow_imp.g_varchar2_table(333) := '32332033313133323120333331313231203331323131332033313233313120333332313131203331343131312032323134313120343331313131203131313232342031313134323220313231313234203132313432312031343131323220313431323231';
wwv_flow_imp.g_varchar2_table(334) := '20313132323134203131323431322031323231313420313232343131203134323131322031343232313120323431323131203232313131342034313331313120323431313132203133343131312031313132343220313231313432203132313234312031';
wwv_flow_imp.g_varchar2_table(335) := '31343231322031323431313220313234323131203431313231322034323131313220343231323131203231323134312032313431323120343132313231203131313134332031313133343120313331313431203131343131332031313433313120343131';
wwv_flow_imp.g_varchar2_table(336) := '31313320343131333131203131333134312031313431333120333131313431203431313133312032313134313220323131323134203231313233322032333331313132222E73706C697428222022293B66756E6374696F6E2075742865297B653D537472';
wwv_flow_imp.g_varchar2_table(337) := '696E672865292E7265706C616365282F5B5E5C7832302D5C7837455D2F672C223F22293B666F722876617220742C723D5B5D2C6E3D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B743D6E2E657865632865293B29696628745B';
wwv_flow_imp.g_varchar2_table(338) := '315D7C7C2F5E5C642B242F2E746573742865292626652E6C656E67746825323D3D30297B766172206F3D745B305D2C613D6F2E6C656E6774682D6F2E6C656E67746825323B722E70757368287B7365743A2243222C743A6F2E73756273747228302C6129';
wwv_flow_imp.g_varchar2_table(339) := '7D292C613C6F2E6C656E6774682626722E70757368287B7365743A2242222C743A6F2E7375627374722861297D297D656C736520722E70757368287B7365743A2242222C743A745B305D7D293B766172206C3D5B5D2C693D6E756C6C3B722E666F724561';
wwv_flow_imp.g_varchar2_table(340) := '63682866756E6374696F6E2865297B6966286E756C6C3D3D3D693F6C2E70757368282243223D3D3D652E7365743F3130353A313034293A69213D3D652E73657426266C2E70757368282243223D3D3D652E7365743F39393A313030292C693D652E736574';
wwv_flow_imp.g_varchar2_table(341) := '2C2243223D3D3D652E73657429666F722876617220743D303B743C652E742E6C656E6774683B742B3D32296C2E70757368282B652E742E73756273747228742C3229293B656C736520666F722876617220723D303B723C652E742E6C656E6774683B722B';
wwv_flow_imp.g_varchar2_table(342) := '2B296C2E7075736828652E742E63686172436F646541742872292D3332297D293B666F722876617220733D6C5B305D2C753D313B753C6C2E6C656E6774683B752B2B29732B3D752A6C5B755D3B6C2E707573682873253130332C313036293B7661722063';
wwv_flow_imp.g_varchar2_table(343) := '3D5B5D3B72657475726E206C2E666F72456163682866756E6374696F6E2865297B73745B655D2E73706C6974282222292E666F72456163682866756E6374696F6E28652C74297B666F722876617220723D303B723C2B653B722B2B29632E707573682874';
wwv_flow_imp.g_varchar2_table(344) := '25323D3D30297D297D292C637D66756E6374696F6E20637428652C742C72297B766172206E3D727C7C28652E736F757263653F4328652C74295B305D3A6E756C6C293B69662821722626652E736F757263652626216E2972657475726E206E756C6C3B76';
wwv_flow_imp.g_varchar2_table(345) := '6172206F3D5328652E76616C75652C742C6E293B696628216F2972657475726E206E756C6C3B76617220613D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292C6C3D652E636F6C6F727C7C2223303030303030223B';
wwv_flow_imp.g_varchar2_table(346) := '696628227172223D3D3D61297B76617220693D66756E6374696F6E28652C74297B76617220723D77696E646F772E7172636F64653B6966282172297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD';
wwv_flow_imp.g_varchar2_table(347) := '612064652063C3B36469676F732051522E22293B722E737472696E67546F427974657346756E63732626722E737472696E67546F427974657346756E63735B225554462D38225D262628722E737472696E67546F42797465733D722E737472696E67546F';
wwv_flow_imp.g_varchar2_table(348) := '427974657346756E63735B225554462D38225D293B766172206E3D7228302C537472696E6728747C7C224D22292E746F5570706572436173652829293B72657475726E206E2E6164644461746128537472696E67286529292C6E2E6D616B6528292C7B6E';
wwv_flow_imp.g_varchar2_table(349) := '3A6E2E6765744D6F64756C65436F756E7428292C6461726B3A66756E6374696F6E28652C74297B72657475726E206E2E69734461726B28742C65297D7D7D286F2C652E656363292C733D652E73697A657C7C33303B72657475726E7B6B696E643A227172';
wwv_flow_imp.g_varchar2_table(350) := '222C746578743A6F2C636F6C733A692E6E2C726F77733A692E6E2C6461726B3A692E6461726B2C773A732C683A732C636F6C6F723A6C2C71756965743A327D7D69662822636F6465313238223D3D3D61297B76617220753D7574286F292C633D652E7769';
wwv_flow_imp.g_varchar2_table(351) := '6474687C7C4D6174682E6D696E2839302C2E33332A752E6C656E677468293B72657475726E7B6B696E643A22626172222C746578743A6F2C636F6C733A752E6C656E6774682C726F77733A312C6461726B3A66756E6374696F6E2865297B72657475726E';
wwv_flow_imp.g_varchar2_table(352) := '20755B655D7D2C773A632C683A652E6865696768747C7C31322C636F6C6F723A6C2C71756965743A382C6C6162656C3A2131213D3D652E73686F77546578742C7465787453697A653A652E7465787453697A657C7C387D7D7468726F77206E6577204572';
wwv_flow_imp.g_varchar2_table(353) := '726F7228225469706F2064652063C3B36469676F206E6F20736F706F727461646F3A20222B612B222028757365207172206F20636F6465313238292E22297D66756E6374696F6E2066742865297B76617220743D652E71756965742C723D227172223D3D';
wwv_flow_imp.g_varchar2_table(354) := '3D652E6B696E643F383A332C6E3D28652E636F6C732B322A74292A722C6F3D6974286E2C227172223D3D3D652E6B696E643F6E3A4D6174682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E636F6C732A7229292C66756E6374696F';
wwv_flow_imp.g_varchar2_table(355) := '6E286E2C6F297B76617220613D4D6174682E666C6F6F72286E2F72292D742C6C3D227172223D3D3D652E6B696E643F4D6174682E666C6F6F72286F2F72292D743A303B72657475726E20613E3D3026266C3E3D302626613C652E636F6C7326266C3C652E';
wwv_flow_imp.g_varchar2_table(356) := '726F77732626652E6461726B28612C6C297D2C652E636F6C6F72293B72657475726E206F2E776D6D3D652E772A28652E636F6C732B322A74292F652E636F6C732C6F2E686D6D3D227172223D3D3D652E6B696E643F6F2E776D6D3A652E682C6F7D766172';
wwv_flow_imp.g_varchar2_table(357) := '2064743D5B2223314634453739222C2223453037423339222C2223324538423537222C2223433033393242222C2223374433433938222C2223313641303835222C2223443441433044222C2223354436443745222C2223413034303030222C2223323837';
wwv_flow_imp.g_varchar2_table(358) := '344136225D3B66756E6374696F6E20687428652C742C72297B766172206E3D77696E646F772E43686172743B696628216E297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD61206465206772C3A1';
wwv_flow_imp.g_varchar2_table(359) := '6669636F73202843686172742E6A73292E22293B766172206F3D4328652C74293B696628216F2E6C656E6774682972657475726E206E756C6C3B766172206C3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C69';
wwv_flow_imp.g_varchar2_table(360) := '3D742E545B6C5D7C7C7B7D2C733D4F626A6563742E6B6579732869292C753D652E63617465676F72793F537472696E6728652E63617465676F7279292E746F55707065724361736528293A732E66696C7465722866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(361) := '726E224E554D42455222213D3D695B655D262622444F435F4B455922213D3D657D295B305D7C7C735B305D2C633D28652E7365726965732626652E7365726965732E6C656E6774683F652E7365726965733A732E66696C7465722866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(362) := '65297B72657475726E224E554D424552223D3D3D695B655D262665213D3D75262622444F435F4B455922213D3D657D29292E6D61702866756E6374696F6E2865297B72657475726E20653D22737472696E67223D3D747970656F6620653F7B636F6C3A65';
wwv_flow_imp.g_varchar2_table(363) := '7D3A652C7B636F6C3A537472696E6728652E636F6C292E746F55707065724361736528292C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628652E636F6C292C636F6C6F723A652E636F6C6F727D7D292C643D652E6368';
wwv_flow_imp.g_varchar2_table(364) := '6172747C7C22626172222C683D22706965223D3D3D647C7C22646F7567686E7574223D3D3D642C673D31312E33343B68262628633D632E736C69636528302C3129293B766172206D3D652E77696474687C7C3132302C763D652E6865696768747C7C3730';
wwv_flow_imp.g_varchar2_table(365) := '2C623D6E74284D6174682E726F756E64286D2A67292C4D6174682E726F756E6428762A6729292C773D66756E6374696F6E2865297B72657475726E2E333532382A652A677D2C793D652E73697A657C7C382C783D2248656C7665746963612C2041726961';
wwv_flow_imp.g_varchar2_table(366) := '6C2C2073616E732D7365726966222C453D7B66616D696C793A782C73697A653A772879297D2C543D652E636F6C6F72732626652E636F6C6F72732E6C656E6774683F652E636F6C6F72733A5B722E7072696D6172795D2E636F6E6361742864742E736C69';
wwv_flow_imp.g_varchar2_table(367) := '6365283129292C413D66756E6374696F6E2874297B72657475726E207028742C652E666D747C7C284D6174682E726F756E642874293D3D3D743F22696E74223A226E756D3A322229297D2C7A3D6F2E6D61702866756E6374696F6E2874297B7661722072';
wwv_flow_imp.g_varchar2_table(368) := '3D745B755D3B72657475726E206E756C6C3D3D723F22223A652E63617465676F7279466D743F7028722C652E63617465676F7279466D74293A537472696E672872297D292C4D3D632E6D61702866756E6374696F6E28722C6E297B766172206C3D722E63';
wwv_flow_imp.g_varchar2_table(369) := '6F6C6F727C7C545B6E25542E6C656E6774685D2C693D7B6C6162656C3A5328722E6C6162656C2C74292C646174613A6F2E6D61702866756E6374696F6E2865297B76617220743D655B722E636F6C5D3B72657475726E206E756C6C3D3D747C7C22223D3D';
wwv_flow_imp.g_varchar2_table(370) := '3D743F6E756C6C3A4E756D6265722874297D297D3B72657475726E20683F28692E6261636B67726F756E64436F6C6F723D6F2E6D61702866756E6374696F6E28652C74297B72657475726E20545B7425542E6C656E6774685D7D292C692E626F72646572';
wwv_flow_imp.g_varchar2_table(371) := '436F6C6F723D2223464646464646222C692E626F7264657257696474683D77282E3829293A226C696E65223D3D3D647C7C2261726561223D3D3D643F28692E626F72646572436F6C6F723D6C2C692E6261636B67726F756E64436F6C6F723D2261726561';
wwv_flow_imp.g_varchar2_table(372) := '223D3D3D643F66756E6374696F6E28652C74297B76617220723D612865293B72657475726E227267626128222B725B305D2B222C222B725B315D2B222C222B725B325D2B222C222B742B2229227D286C2C2E3235293A6C2C692E66696C6C3D2261726561';
wwv_flow_imp.g_varchar2_table(373) := '223D3D3D642C692E626F7264657257696474683D7728312E34292C692E706F696E745261646975733D7728312E35292C692E706F696E744261636B67726F756E64436F6C6F723D6C2C692E74656E73696F6E3D652E736D6F6F74683F2E33353A30293A28';
wwv_flow_imp.g_varchar2_table(374) := '692E6261636B67726F756E64436F6C6F723D6C2C692E626F7264657257696474683D30292C697D292C4E3D7B666F6E743A452C636F6C6F723A2223343434343434227D2C463D7B7D3B6966282168297B76617220503D7B626567696E41745A65726F3A21';
wwv_flow_imp.g_varchar2_table(375) := '31213D3D652E626567696E41745A65726F2C737461636B65643A2121652E737461636B65642C67726163653A652E76616C7565733F2268626172223D3D3D643F22323525223A22313225223A302C677269643A7B636F6C6F723A2223453345374543222C';
wwv_flow_imp.g_varchar2_table(376) := '6C696E6557696474683A77282E34297D2C626F726465723A7B646973706C61793A21317D2C7469636B733A7B666F6E743A452C636F6C6F723A2223343434343434222C63616C6C6261636B3A66756E6374696F6E2865297B72657475726E20412865297D';
wwv_flow_imp.g_varchar2_table(377) := '7D7D2C6B3D7B737461636B65643A2121652E737461636B65642C677269643A7B646973706C61793A21317D2C7469636B733A4E7D3B463D2268626172223D3D3D643F7B783A502C793A6B7D3A7B783A6B2C793A507D7D766172204F3D766F69642030213D';
wwv_flow_imp.g_varchar2_table(378) := '3D652E6C6567656E643F2121652E6C6567656E643A687C7C632E6C656E6774683E312C6A3D6E6577206E28622E676574436F6E746578742822326422292C7B747970653A683F643A2268626172223D3D3D643F22626172223A2261726561223D3D3D643F';
wwv_flow_imp.g_varchar2_table(379) := '226C696E65223A642C646174613A7B6C6162656C733A7A2C64617461736574733A4D7D2C706C6174666F726D3A6E2E4261736963506C6174666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C616E696D6174696F6E3A21312C646576';
wwv_flow_imp.g_varchar2_table(380) := '696365506978656C526174696F3A312C696E646578417869733A2268626172223D3D3D643F2279223A2278222C6C61796F75743A7B70616464696E673A772834297D2C7363616C65733A462C706C7567696E733A7B6C6567656E643A7B646973706C6179';
wwv_flow_imp.g_varchar2_table(381) := '3A4F2C706F736974696F6E3A652E6C6567656E64506F736974696F6E7C7C28683F227269676874223A22626F74746F6D22292C6C6162656C733A7B666F6E743A452C636F6C6F723A2223333333333333222C626F7857696474683A772837292C626F7848';
wwv_flow_imp.g_varchar2_table(382) := '65696768743A772837297D7D2C7469746C653A7B646973706C61793A2121652E7469746C652C746578743A5328652E7469746C652C74292C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C793A782C73697A653A7728792B32292C77';
wwv_flow_imp.g_varchar2_table(383) := '65696768743A22626F6C64227D2C70616464696E673A7B626F74746F6D3A772834297D7D2C746F6F6C7469703A7B656E61626C65643A21317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C6265666F7265447261773A66756E637469';
wwv_flow_imp.g_varchar2_table(384) := '6F6E2865297B76617220743D652E6374783B742E7361766528292C742E66696C6C5374796C653D2223464646464646222C742E66696C6C5265637428302C302C652E77696474682C652E686569676874292C742E726573746F726528297D7D2C7B69643A';
wwv_flow_imp.g_varchar2_table(385) := '226E7256616C6F726573222C61667465724461746173657473447261773A66756E6374696F6E2874297B696628652E76616C756573297B76617220723D742E6374783B722E7361766528292C722E666F6E743D22626F6C6420222B7728792D2E35292B22';
wwv_flow_imp.g_varchar2_table(386) := '707820222B782C742E646174612E64617461736574732E666F72456163682866756E6374696F6E286E2C6F297B696628742E69734461746173657456697369626C65286F29297B76617220613D6E2E646174612E7265647563652866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(387) := '652C74297B72657475726E20652B28747C7C30297D2C30293B742E676574446174617365744D657461286F292E646174612E666F72456163682866756E6374696F6E28742C6F297B766172206C3D6E2E646174615B6F5D3B6966286E756C6C213D6C297B';
wwv_flow_imp.g_varchar2_table(388) := '76617220693D22706374223D3D3D652E76616C7565733F7028613F3130302A6C2F613A302C226E756D3A3122292B2225223A41286C293B69662868297B76617220733D742E746F6F6C746970506F736974696F6E28293B722E66696C6C5374796C653D22';
wwv_flow_imp.g_varchar2_table(389) := '23464646464646222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D226D6964646C65222C722E66696C6C5465787428692C732E782C732E79297D656C73652268626172223D3D3D643F28722E66696C6C5374';
wwv_flow_imp.g_varchar2_table(390) := '796C653D2223333333333333222C722E74657874416C69676E3D226C656674222C722E74657874426173656C696E653D226D6964646C65222C722E66696C6C5465787428692C742E782B7728312E35292C742E7929293A28722E66696C6C5374796C653D';
wwv_flow_imp.g_varchar2_table(391) := '2223333333333333222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D22626F74746F6D222C722E66696C6C5465787428692C742E782C742E792D7728312E352929297D7D297D7D292C722E726573746F7265';
wwv_flow_imp.g_varchar2_table(392) := '28297D7D7D5D7D292C4C3D622E746F4461746155524C2822696D6167652F706E6722293B6A2E64657374726F7928293B76617220523D7274284C2C622E77696474682C622E686569676874293B72657475726E20522E776D6D3D6D2C522E686D6D3D762C';
wwv_flow_imp.g_varchar2_table(393) := '527D66756E6374696F6E20707428652C74297B76617220723D652E77617465726D61726B3B69662821727C7C226F626A656374223D3D747970656F6620722626215428722E7768656E2C742C742E646F63292972657475726E206E756C6C3B2273747269';
wwv_flow_imp.g_varchar2_table(394) := '6E67223D3D747970656F662072262628723D7B746578743A727D293B766172206E3D5328722E746578742C742C742E646F63293B72657475726E206E3F7B746578743A6E2C636F6C6F723A722E636F6C6F727C7C2223433030303030222C6F7061636974';
wwv_flow_imp.g_varchar2_table(395) := '793A766F69642030213D3D722E6F7061636974793F722E6F7061636974793A2E31322C616E676C653A766F69642030213D3D722E616E676C653F722E616E676C653A34352C73697A653A722E73697A657D3A6E756C6C7D66756E6374696F6E2067742865';
wwv_flow_imp.g_varchar2_table(396) := '2C742C722C6E297B696628652E73697A652972657475726E20652E73697A653B766172206F3D652E616E676C65253138303D3D303F2E382A723A2E362A4D6174682E7371727428722A722B6E2A6E293B72657475726E204D6174682E6D61782832302C4D';
wwv_flow_imp.g_varchar2_table(397) := '6174682E6D696E283136302C3130302A6F2F7429297D66756E6374696F6E206D7428652C742C722C6E297B766172206F2C6C3D77696E646F772E6A737064662C693D722E782B2E362C733D722E792B2E362C753D722E77696474682D312E322C633D722E';
wwv_flow_imp.g_varchar2_table(398) := '6865696768742D312E322C663D61286F65292C643D61286165293B69662822636865636B626F78223D3D3D742E696E707574297B76617220683D4D6174682E6D696E28632C342E35293B732B3D28632D68292F322C753D682C633D687D652E7365744472';
wwv_flow_imp.g_varchar2_table(399) := '6177436F6C6F7228645B305D2C645B315D2C645B325D292C652E73657446696C6C436F6C6F7228665B305D2C665B315D2C665B325D292C652E7365744C696E655769647468282E32292C652E7265637428692C732C752C632C22464422292C652E736574';
wwv_flow_imp.g_varchar2_table(400) := '44726177436F6C6F7228302C302C30292C22636865636B626F78223D3D3D742E696E7075743F28286F3D6E6577206C2E4163726F466F726D436865636B426F78292E617070656172616E636553746174653D742E636865636B65643F224F6E223A224F66';
wwv_flow_imp.g_varchar2_table(401) := '66222C6F2E76616C75653D742E636865636B65643F224F6E223A224F666622293A226C697374223D3D3D742E696E7075743F28286F3D6E6577206C2E4163726F466F726D436F6D626F426F78292E7365744F7074696F6E7328742E6F7074696F6E73292C';
wwv_flow_imp.g_varchar2_table(402) := '6F2E656469743D21312C742E76616C75652626286F2E76616C75653D742E76616C756529293A28286F3D6E6577206C2E4163726F466F726D546578744669656C64292E6D756C74696C696E653D226D756C74696C696E65223D3D3D742E696E7075742C74';
wwv_flow_imp.g_varchar2_table(403) := '2E6D61784C656E6774682626286F2E6D61784C656E6774683D742E6D61784C656E677468292C742E76616C75652626286F2E76616C75653D742E76616C756529292C6F2E6669656C644E616D653D742E6E616D652C6F2E526563743D5B692C732C752C63';
wwv_flow_imp.g_varchar2_table(404) := '5D2C22636865636B626F7822213D3D742E696E7075742626286F2E666F6E7453697A653D6E2C652E5F5F6E72466F726D53697A657C7C28652E5F5F6E72466F726D53697A653D6E29292C742E726561644F6E6C792626286F2E726561644F6E6C793D2130';
wwv_flow_imp.g_varchar2_table(405) := '292C652E6164644669656C64286F297D66756E6374696F6E20767428652C742C72297B766172206E3D652E706167657C7C7B7D2C6F3D56652865292C6C3D6F2E666F6E7453697A652C693D6E65772077696E646F772E6A737064662E6A73504446287B6F';
wwv_flow_imp.g_varchar2_table(406) := '7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572222C636F6D70726573733A2168652865297D292C733D692E696E7465726E61';
wwv_flow_imp.g_varchar2_table(407) := '6C2E7061676553697A652E676574576964746828292C753D692E696E7465726E616C2E7061676553697A652E67657448656967687428292C633D6E2E6D617267696E7C7C382C663D61286F2E7072696D617279292C643D61286F2E686561645465787429';
wwv_flow_imp.g_varchar2_table(408) := '2C683D61286F2E7A65627261292C703D61286F2E746F74616C73292C673D632C6D3D21302C763D632C623D633B66756E6374696F6E207728297B72657475726E20692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E';
wwv_flow_imp.g_varchar2_table(409) := '616C593A677D66756E6374696F6E20792865297B673D7728292B28657C7C32297D66756E6374696F6E207828652C742C722C6E297B766172206F3D766F69642030213D3D652E783F652E783A227269676874223D3D3D652E616C69676E3F732D622D743A';
wwv_flow_imp.g_varchar2_table(410) := '2263656E746572223D3D3D652E616C69676E3F762B28732D762D622D74292F323A763B766F696420303D3D3D652E793F2828673D4D6174682E6D617828672C77282929292B723E752D632D3130262628692E6164645061676528292C673D63292C6E286F';
wwv_flow_imp.g_varchar2_table(411) := '2C67292C672B3D722B28766F69642030213D3D652E6761703F652E6761703A33292C692E6C6173744175746F5461626C653D7B66696E616C593A677D293A6E286F2C652E79297D76617220453D5B5D3B742E666F72456163682866756E6374696F6E284E';
wwv_flow_imp.g_varchar2_table(412) := '2C6A297B76617220523D742E6C656E6774683E313F225F222B286A2B31293A22223B6D7C7C692E6164645061676528292C6D3D21312C673D632C692E6C6173744175746F5461626C653D6E756C6C3B76617220493D7B6374783A4E2C66726F6D3A692E69';
wwv_flow_imp.g_varchar2_table(413) := '6E7465726E616C2E6765744E756D6265724F66506167657328297D3B452E707573682849292C446528652C22706466222C4E292E666F72456163682866756E6374696F6E2074286D297B76617220453D6D2E747970653B69662822686561646572223D3D';
wwv_flow_imp.g_varchar2_table(414) := '3D45297B766172206A3D5265286D2C6F292C493D6D2E66696C6C3F61286A2E66696C6C293A662C423D6D2E636F6C6F723F61286A2E636F6C6F72293A642C473D4D6174682E6D61782831302E352C332E352B2E333532382A6A2E73697A65292C573D472B';
wwv_flow_imp.g_varchar2_table(415) := '4D6174682E6D617828362C312E352B2E333532382A6A2E73756253697A652A312E31292C5F3D4D6174682E6D6178284E756D626572286D2E686569676874297C7C302C6D2E7375627469746C653F4D6174682E6D61782832302C572B332E35293A4D6174';
wwv_flow_imp.g_varchar2_table(416) := '682E6D61782831362C472B352E3529293B72657475726E20692E73657446696C6C436F6C6F7228495B305D2C495B315D2C495B325D292C692E7265637428302C302C732C5F2C224622292C692E73657454657874436F6C6F7228425B305D2C425B315D2C';
wwv_flow_imp.g_varchar2_table(417) := '425B325D292C692E736574466F6E74286A2E666F6E745B305D2C22626F6C6422292C692E736574466F6E7453697A65286A2E73697A65292C692E746578742853286D2E7469746C652C4E292C632C472C7B6D617857696474683A2E372A737D292C692E73';
wwv_flow_imp.g_varchar2_table(418) := '6574466F6E74286A2E666F6E745B305D2C226E6F726D616C22292C692E736574466F6E7453697A65286A2E726967687453697A65292C6D2E72696768742626692E746578742853286D2E72696768742C4E292C732D632C472C7B616C69676E3A22726967';
wwv_flow_imp.g_varchar2_table(419) := '6874227D292C6D2E7375627469746C65262628692E736574466F6E7453697A65286A2E73756253697A65292C692E746578742853286D2E7375627469746C652C4E292C632C5729292C692E736574466F6E74282268656C766574696361222C226E6F726D';
wwv_flow_imp.g_varchar2_table(420) := '616C22292C692E73657454657874436F6C6F7228302C302C30292C673D5F2B342C766F696428692E6C6173744175746F5461626C653D6E756C6C297D69662822746578746F223D3D3D45297B76617220483D766F69642030213D3D6D2E792C593D672C24';
wwv_flow_imp.g_varchar2_table(421) := '3D692E6C6173744175746F5461626C652C713D6D2E73697A657C7C31302C583D2E333532382A712A286D2E6C696E654865696768747C7C312E3335292C6E653D28766F69642030213D3D6D2E783F6D2E783A76292B286D2E696E64656E747C7C30292C6F';
wwv_flow_imp.g_varchar2_table(422) := '653D6D2E77696474687C7C732D622D6E652C61653D6D2E616C69676E7C7C226C656674222C6C653D61286D2E636F6C6F727C7C222330303030303022292C69653D66756E6374696F6E2865297B72657475726E28652E627C7C6D2E626F6C642926262865';
wwv_flow_imp.g_varchar2_table(423) := '2E697C7C6D2E6974616C6963293F22626F6C646974616C6963223A652E627C7C6D2E626F6C643F22626F6C64223A652E697C7C6D2E6974616C69633F226974616C6963223A226E6F726D616C227D2C73653D6D2E666F6E747C7C652E706167652626652E';
wwv_flow_imp.g_varchar2_table(424) := '706167652E666F6E747C7C2268656C766574696361223B72657475726E20692E736574466F6E7453697A652871292C692E73657454657874436F6C6F72286C655B305D2C6C655B315D2C6C655B325D292C673D483F6D2E793A4D6174682E6D617828672C';
wwv_flow_imp.g_varchar2_table(425) := '692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292C50286D2C4E292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B4628652C7B666F6E743A73652C636F6C6F723A6D2E63';
wwv_flow_imp.g_varchar2_table(426) := '6F6C6F727D292E666F72456163682866756E6374696F6E2865297B652E742E73706C6974282F28202B292F292E666F72456163682866756E6374696F6E2872297B2222213D3D722626742E70757368287B743A722C66616D3A4D5B652E665D5B305D2C66';
wwv_flow_imp.g_varchar2_table(427) := '3A69652865292C73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E633F6128652E63293A6C657D297D297D293B76617220723D5B5D2C6E3D5B5D2C6F3D303B666F7228742E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(428) := '65297B76617220743D66756E6374696F6E2865297B692E736574466F6E7428652E66616D2C652E66293B666F722876617220743D302C723D652E66616D2B652E662B712C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B766172206F3D722B652E';
wwv_flow_imp.g_varchar2_table(429) := '742E636861724174286E293B766F696420303D3D3D24655B6F5D26262824655B6F5D3D692E67657454657874576964746828652E742E636861724174286E2929292C742B3D24655B6F5D7D72657475726E20747D2865293B69662821652E737026266F2B';
wwv_flow_imp.g_varchar2_table(430) := '743E6F6526266E2E6C656E677468297B666F72283B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F7D292C6E3D5B5D2C6F3D307D652E73702626216E2E6C';
wwv_flow_imp.g_varchar2_table(431) := '656E6774687C7C28652E773D742C6E2E707573682865292C6F2B3D74297D293B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F2C6C6173743A21307D292C';
wwv_flow_imp.g_varchar2_table(432) := '652E7472696D28293F28722E666F72456163682866756E6374696F6E2865297B21482626672B583E752D632D3130262628692E6164645061676528292C673D63293B76617220743D652E77732E66696C7465722866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(433) := '726E20652E73707D292E6C656E6774682C723D226A757374696679223D3D3D6165262621652E6C6173742626743F286F652D652E77292F743A302C6E3D227269676874223D3D3D61653F6E652B6F652D652E773A2263656E746572223D3D3D61653F6E65';
wwv_flow_imp.g_varchar2_table(434) := '2B286F652D652E77292F323A6E652C6F3D672B2E37352A583B652E77732E666F72456163682866756E6374696F6E2865297B76617220743D652E772B28652E73703F723A30293B692E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C';
wwv_flow_imp.g_varchar2_table(435) := '652E635B325D292C692E73657444726177436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C692E7365744C696E655769647468282E3031322A71292C652E73707C7C28692E736574466F6E7428652E66616D2C652E66292C692E7465';
wwv_flow_imp.g_varchar2_table(436) := '787428652E742C6E2C6F29292C652E752626692E6C696E65286E2C6F2B2E30362A712C6E2B742C6F2B2E30362A71292C652E732626692E6C696E65286E2C6F2D2E31312A712C6E2B742C6F2D2E31312A71292C6E2B3D747D292C672B3D587D292C672B3D';
wwv_flow_imp.g_varchar2_table(437) := '766F69642030213D3D6D2E7061726167726170684761703F6D2E7061726167726170684761703A2E352A58293A672B3D587D292C692E73657454657874436F6C6F7228302C302C30292C766F696428483F28673D592C692E6C6173744175746F5461626C';
wwv_flow_imp.g_varchar2_table(438) := '653D24293A692E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226C696E6561223D3D3D45297B7661722066653D61286D2E636F6C6F727C7C222330303030303022293B696628692E73657444726177436F6C6F722866655B30';
wwv_flow_imp.g_varchar2_table(439) := '5D2C66655B315D2C66655B325D292C692E7365744C696E655769647468286D2E746869636B6E6573737C7C2E33292C766F69642030213D3D6D2E78312972657475726E20766F696420692E6C696E65286D2E78312C6D2E79312C766F69642030213D3D6D';
wwv_flow_imp.g_varchar2_table(440) := '2E78323F6D2E78323A6D2E78312C766F69642030213D3D6D2E79323F6D2E79323A6D2E7931293B673D4D6174682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292B286D2E676170';
wwv_flow_imp.g_varchar2_table(441) := '4265666F72657C7C30293B7661722064653D6D2E77696474687C7C732D762D622C68653D2263656E746572223D3D3D6D2E616C69676E3F762B28732D762D622D6465292F323A227269676874223D3D3D6D2E616C69676E3F732D622D64653A763B726574';
wwv_flow_imp.g_varchar2_table(442) := '75726E20692E6C696E652868652C672C68652B64652C67292C672B3D766F69642030213D3D6D2E6761703F6D2E6761703A322C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226573706163696F223D3D3D45';
wwv_flow_imp.g_varchar2_table(443) := '2972657475726E20673D4D6174682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292B286D2E6865696768747C7C36292C766F696428692E6C6173744175746F5461626C653D7B66';
wwv_flow_imp.g_varchar2_table(444) := '696E616C593A677D293B69662822696D6167656E22213D3D4529696628226772616669636F22213D3D452969662822636F6469676F22213D3D45297B6966282273616C746F223D3D3D452972657475726E20692E6164645061676528292C673D632C766F';
wwv_flow_imp.g_varchar2_table(445) := '696428692E6C6173744175746F5461626C653D7B66696E616C593A637D293B69662822636F6C756D6E6173223D3D3D45297B7661722070653D762C67653D623B69662821284A653D5F65286D2C22706466222C4E2C732D762D6229292E6C656E67746829';
wwv_flow_imp.g_varchar2_table(446) := '72657475726E3B766172206D653D66756E6374696F6E2865297B763D70652B652E782C623D732D2870652B652E782B652E77297D2C76653D692C62653D302C77653D21302C7A653D4D6174682E6D617828672C772829293B6966284A652E666F72456163';
wwv_flow_imp.g_varchar2_table(447) := '682866756E6374696F6E2865297B693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A';
wwv_flow_imp.g_varchar2_table(448) := '657C7C226C6574746572227D292C6D652865292C673D632C692E6C6173744175746F5461626C653D6E756C6C2C652E736563732E666F72456163682874292C692E696E7465726E616C2E6765744E756D6265724F66506167657328293E3126262877653D';
wwv_flow_imp.g_varchar2_table(449) := '2131292C62653D4D6174682E6D61782862652C4D6174682E6D617828672C772829292D63297D292C763D70652C623D67652C673D7A652C28693D7665292E6C6173744175746F5461626C653D7B66696E616C593A7A657D2C2177652972657475726E2076';
wwv_flow_imp.g_varchar2_table(450) := '6F6964204A652E666F72456163682866756E6374696F6E2865297B652E736563732E666F72456163682874297D293B672B62653E752D632D3130262628692E6164645061676528292C673D63293B766172204E653D672C6B653D673B72657475726E204A';
wwv_flow_imp.g_varchar2_table(451) := '652E666F72456163682866756E6374696F6E2865297B6D652865292C673D4E652C692E6C6173744175746F5461626C653D7B66696E616C593A4E657D2C652E736563732E666F72456163682874292C6B653D4D6174682E6D6178286B652C672C77282929';
wwv_flow_imp.g_varchar2_table(452) := '7D292C763D70652C623D67652C673D6B652B28766F69642030213D3D6D2E6761703F6D2E6761703A31292C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D69662822677275706F223D3D3D45297B7661722044653D4E';
wwv_flow_imp.g_varchar2_table(453) := '2C55653D522C42653D762C48653D622C56653D766F69642030213D3D6D2E70616464696E673F4E756D626572286D2E70616464696E67293A6D2E626F726465727C7C6D2E66696C6C3F333A302C59653D66756E6374696F6E2865297B76617220722C6E3D';
wwv_flow_imp.g_varchar2_table(454) := '4D6174682E6D617828672C772829293B763D42652C623D48652C673D6E2C6D2E7469746C65262628723D53286D2E7469746C652C4E292C692E6175746F5461626C65287B7374617274593A4D6174682E6D617828672C772829292C7468656D653A22706C';
wwv_flow_imp.g_varchar2_table(455) := '61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C626F64793A5B5B725D5D2C7374796C65733A7B666F6E7453697A653A6D2E7469746C6553697A657C7C6C2B322C666F6E745374796C653A22626F6C64222C63656C6C5061646469';
wwv_flow_imp.g_varchar2_table(456) := '6E673A312E362C66696C6C436F6C6F723A61286D2E7469746C6546696C6C7C7C6F2E7072696D617279292C74657874436F6C6F723A61286D2E7469746C65436F6C6F727C7C6F2E6865616454657874297D7D292C673D772829292C673D4D6174682E6D61';
wwv_flow_imp.g_varchar2_table(457) := '7828672C772829292B56652C692E6C6173744175746F5461626C653D7B66696E616C593A677D2C763D42652B56652C623D48652B56652C652E666F72456163682874293B76617220733D4D6174682E6D617828672C772829292B56653B72657475726E20';
wwv_flow_imp.g_varchar2_table(458) := '763D42652C623D48652C732D6E7D3B72657475726E205765286D2C4E292E666F72456163682866756E6374696F6E2865297B4E3D652E6374782C523D55652B652E7375663B76617220743D4765286D2C22706466222C4E293B696628742E6C656E677468';
wwv_flow_imp.g_varchar2_table(459) := '7C7C6D2E7469746C65297B76617220723D692C6F3D4D6174682E6D617828672C772829293B693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F72747261697422';
wwv_flow_imp.g_varchar2_table(460) := '2C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572227D292C673D632C692E6C6173744175746F5461626C653D6E756C6C3B766172206C3D59652874292C663D313D3D3D692E696E7465726E616C2E6765744E756D626572';
wwv_flow_imp.g_varchar2_table(461) := '4F66506167657328293B673D6F2C28693D72292E6C6173744175746F5461626C653D7B66696E616C593A6F7D2C6626262131213D3D6D2E6B656570546F6765746865722626672B6C3E752D632D3130262628692E6164645061676528292C673D632C692E';
wwv_flow_imp.g_varchar2_table(462) := '6C6173744175746F5461626C653D7B66696E616C593A677D293B76617220643D672C683D692E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265722C703D732D42652D48653B6966286626266D2E66696C';
wwv_flow_imp.g_varchar2_table(463) := '6C297B76617220763D61286D2E66696C6C293B692E73657446696C6C436F6C6F7228765B305D2C765B315D2C765B325D292C692E726563742842652C642C702C6C2C224622297D76617220623D59652874293B6966286D2E626F726465722626692E696E';
wwv_flow_imp.g_varchar2_table(464) := '7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265723D3D3D68297B76617220793D61286D2E626F72646572436F6C6F727C7C7965293B692E73657444726177436F6C6F7228795B305D2C795B315D2C795B325D';
wwv_flow_imp.g_varchar2_table(465) := '292C692E7365744C696E655769647468286D2E626F7264657257696474687C7C2E33292C692E726563742842652C642C702C622C225322292C692E73657444726177436F6C6F7228302C302C30297D673D642B622C692E696E7465726E616C2E67657443';
wwv_flow_imp.g_varchar2_table(466) := '757272656E7450616765496E666F28292E706167654E756D626572213D3D68262628673D4D6174682E6D617828672C77282929292C672B3D766F69642030213D3D6D2E6761703F4E756D626572286D2E676170293A332C692E6C6173744175746F546162';
wwv_flow_imp.g_varchar2_table(467) := '6C653D7B66696E616C593A677D7D7D292C4E3D44652C523D55652C763D42652C766F696428623D4865297D696628226669636861223D3D3D45297B7661722071653D43286D2C4E295B305D7C7C7B7D2C58653D6D2E636F6C756D6E737C7C332C5A653D5B';
wwv_flow_imp.g_varchar2_table(468) := '5D2C4A653D7B7D3B456528286D2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5428652E7768656E2C4E2C7165297D292C5865292E666F72456163682866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(469) := '7B76617220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E656D70747929742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B6C696E';
wwv_flow_imp.g_varchar2_table(470) := '6557696474683A302C66696C6C436F6C6F723A21317D7D293B656C73657B766172206E3D4D6528722C6D292C6F3D416528722C4E2C7165292C6C3D726528722C4E2C7165293B696628226C65667422213D3D6E2E706F73297B76617220693D7B666F6E74';
wwv_flow_imp.g_varchar2_table(471) := '5374796C653A6F26266F2E626F6C643F22626F6C64223A226E6F726D616C222C66696C6C436F6C6F723A2128216F7C7C216F2E66696C6C29262661286F2E66696C6C292C74657874436F6C6F723A61286F26266F2E636F6C6F727C7C6D2E76616C756543';
wwv_flow_imp.g_varchar2_table(472) := '6F6C6F727C7C222330303030303022292C68616C69676E3A6F26266F2E616C69676E7C7C226C656674227D2C733D7B636F6E74656E743A6C2C636F6C5370616E3A322A652E7370616E2C7374796C65733A697D3B72657475726E22746F70223D3D3D6E2E';
wwv_flow_imp.g_varchar2_table(473) := '706F73262628732E5F6E724C61623D7B746578743A4665285328722E6C6162656C2C4E2C7165292C6E292C6C623A6E2C616C69676E3A6E2E616C69676E7C7C692E68616C69676E7D292C766F696420742E707573682873297D6966286F7C7C652E737061';
wwv_flow_imp.g_varchar2_table(474) := '6E3E31297B76617220753D7B7D3B6F26266F2E616C69676E262628752E68616C69676E3D6F2E616C69676E292C6F26266F2E626F6C64262628752E666F6E745374796C653D22626F6C6422292C6F26266F2E636F6C6F72262628752E74657874436F6C6F';
wwv_flow_imp.g_varchar2_table(475) := '723D61286F2E636F6C6F7229292C6F26266F2E66696C6C262628752E66696C6C436F6C6F723D61286F2E66696C6C29292C6C3D7B636F6E74656E743A6C2C7374796C65733A757D2C652E7370616E3E312626286C2E636F6C5370616E3D322A652E737061';
wwv_flow_imp.g_varchar2_table(476) := '6E2D31297D76617220633D5328722E6C6162656C2C4E2C7165293B742E70757368286E2E7374796C65643F7B636F6E74656E743A466528632C6E292C7374796C65733A6A65286E297D3A632C6C297D7D293B666F722876617220723D322A43652865293B';
wwv_flow_imp.g_varchar2_table(477) := '723C322A58653B722B2B29742E70757368282222293B5A652E707573682874297D293B766172204B653D302C74743D5065286D293B6966285465286D2E6669656C6473297C7C7474297B666F72287661722072743D302C6E743D303B6E743C58653B6E74';
wwv_flow_imp.g_varchar2_table(478) := '2B2B2972742B3D7865286D2C6E74293B4B653D4D6174682E6D61782831302C28732D762D622D7274292F5865297D666F7228766172206F743D303B6F743C322A58653B6F742B3D32294A655B6F745D3D7B666F6E745374796C653A22626F6C64222C6365';
wwv_flow_imp.g_varchar2_table(479) := '6C6C57696474683A7865286D2C6F742F32297D2C4B652626284A655B6F742B315D3D7B63656C6C57696474683A4B657D292C6D2E6C6162656C46696C6C2626284A655B6F745D2E66696C6C436F6C6F723D61286D2E6C6162656C46696C6C29292C6D2E6C';
wwv_flow_imp.g_varchar2_table(480) := '6162656C436F6C6F722626284A655B6F745D2E74657874436F6C6F723D61286D2E6C6162656C436F6C6F7229292C6D2E76616C7565436F6C6F722626284A655B6F742B315D3D4A655B6F742B315D7C7C7B7D2C4A655B6F742B315D2E74657874436F6C6F';
wwv_flow_imp.g_varchar2_table(481) := '723D61286D2E76616C7565436F6C6F7229293B7661722061743D7B666F6E7453697A653A6D2E73697A657C7C382E352C63656C6C50616464696E673A2E397D3B6D2E6772696426262861742E63656C6C50616464696E673D312E362C61742E76616C6967';
wwv_flow_imp.g_varchar2_table(482) := '6E3D226D6964646C65222C61742E6C696E6557696474683D2E31352C61742E6C696E65436F6C6F723D61286D2E626F72646572436F6C6F727C7C796529293B766172206C743D7B7374617274593A672C626F64793A5A652C7468656D653A22706C61696E';
wwv_flow_imp.g_varchar2_table(483) := '222C6D617267696E3A7B6C6566743A762C72696768743A627D2C7374796C65733A61742C636F6C756D6E5374796C65733A4A657D3B6966287474297B7661722069743D61742E666F6E7453697A652C73743D61742E63656C6C50616464696E673B6C742E';
wwv_flow_imp.g_varchar2_table(484) := '646964506172736543656C6C3D66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B74262628652E63656C6C2E7374796C65732E63';
wwv_flow_imp.g_varchar2_table(485) := '656C6C50616464696E673D7B746F703A73742B4F6528742E6C622C6974292C72696768743A73742C626F74746F6D3A73742C6C6566743A73747D297D2C6C742E6469644472617743656C6C3D66756E6374696F6E2865297B76617220743D22626F647922';
wwv_flow_imp.g_varchar2_table(486) := '3D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B7426264C6528692C652E63656C6C2C742C69742C7374297D7D72657475726E20692E6175746F5461626C65286C74292C766F696420792832';
wwv_flow_imp.g_varchar2_table(487) := '297D696628227461726A65746173223D3D3D45297B7661722075743D4965286D2C4E2C6F293B6966282175742E6974656D732E6C656E6774682972657475726E3B7661722066743D28732D762D622D75742E636172644761702A2875742E6E2D3129292F';
wwv_flow_imp.g_varchar2_table(488) := '75742E6E2C64743D2E333532382A75742E6C6162656C53697A652C70743D2E333532382A75742E73697A652C67743D612875742E66696C6C292C76743D75742E616363656E743F612875742E616363656E74293A6E756C6C2C62743D76743F343A332C77';
wwv_flow_imp.g_varchar2_table(489) := '743D66742D62742D323B673D4D6174682E6D617828672C772829293B666F72287661722079743D303B79743C75742E6974656D732E6C656E6774683B79742B3D75742E6E297B7661722078743D75742E6974656D732E736C6963652879742C79742B7574';
wwv_flow_imp.g_varchar2_table(490) := '2E6E293B692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E736574466F6E7453697A652875742E73697A65293B7661722053743D78742E6D61702866756E6374696F6E2865297B72657475726E20692E73706C6974546578';
wwv_flow_imp.g_varchar2_table(491) := '74546F53697A6528537472696E6728652E76616C7565292C7774297D292C45743D4D6174682E6D61782E6170706C79286E756C6C2C53742E6D61702866756E6374696F6E2865297B72657475726E204D6174682E6D617828312C652E6C656E677468297D';
wwv_flow_imp.g_varchar2_table(492) := '29292C54743D312E322A64742B312E352B312E322A70742A45742C43743D4D6174682E6D6178286D2E6865696768747C7C302C332B54742B33293B672B43743E752D632D3130262628692E6164645061676528292C673D63292C78742E666F7245616368';
wwv_flow_imp.g_varchar2_table(493) := '2866756E6374696F6E28652C74297B76617220723D762B742A2866742B75742E63617264476170292C6E3D612875742E6C6162656C436F6C6F72292C6F3D6128652E636F6C6F727C7C75742E76616C7565436F6C6F72293B692E73657446696C6C436F6C';
wwv_flow_imp.g_varchar2_table(494) := '6F722867745B305D2C67745B315D2C67745B325D292C692E7265637428722C672C66742C43742C224622292C7674262628692E73657446696C6C436F6C6F722876745B305D2C76745B315D2C76745B325D292C692E7265637428722C672C312E322C4374';
wwv_flow_imp.g_varchar2_table(495) := '2C22462229293B766172206C3D672B2843742D5474292F322B64743B692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E736574466F6E7453697A652875742E6C6162656C53697A65292C692E73657454657874436F6C';
wwv_flow_imp.g_varchar2_table(496) := '6F72286E5B305D2C6E5B315D2C6E5B325D292C692E7465787428692E73706C697454657874546F53697A6528537472696E6728652E6C6162656C292C7774295B305D7C7C22222C722B62742C6C292C692E736574466F6E74282268656C76657469636122';
wwv_flow_imp.g_varchar2_table(497) := '2C22626F6C6422292C692E736574466F6E7453697A652875742E73697A65292C692E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C53745B745D2E666F72456163682866756E6374696F6E28652C74297B692E7465787428652C';
wwv_flow_imp.g_varchar2_table(498) := '722B62742C6C2B312E352B312E30352A70742B742A70742A312E32297D297D292C672B3D43742B2879742B75742E6E3C75742E6974656D732E6C656E6774683F75742E636172644761703A30297D72657475726E20692E736574466F6E74282268656C76';
wwv_flow_imp.g_varchar2_table(499) := '6574696361222C226E6F726D616C22292C692E73657454657874436F6C6F7228302C302C30292C672B3D766F69642030213D3D6D2E6761703F6D2E6761703A332C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D6966';
wwv_flow_imp.g_varchar2_table(500) := '2822666F726D756C6172696F223D3D3D45297B692E5F5F6E72466F726D7C7C28692E5F5F6E72466F726D3D75652829293B7661722041743D6365286D2C4E2C52292C7A743D6D2E636F6C756D6E737C7C322C4D743D5B5D2C4E743D7B7D2C46743D7B7D2C';
wwv_flow_imp.g_varchar2_table(501) := '50743D6D2E73697A657C7C382E353B69662845652841742C7A74292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E656D70747929';
wwv_flow_imp.g_varchar2_table(502) := '742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E7D293B656C73657B696628692E5F5F6E72466F726D28722E6E616D65292C226C65667422213D3D722E6C61622E706F73297B4E745B4D742E6C656E6774682B223A';
wwv_flow_imp.g_varchar2_table(503) := '222B322A652E636F6C5D3D723B766172206E3D7B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B666F6E745374796C653A226E6F726D616C227D7D3B72657475726E22746F70223D3D3D722E6C61622E706F73';
wwv_flow_imp.g_varchar2_table(504) := '2626286E2E5F6E724C61623D7B746578743A466528722E6C6162656C2C722E6C6162292C6C623A722E6C61622C616C69676E3A722E6C61622E616C69676E7C7C226C656674227D292C766F696420742E70757368286E297D4E745B4D742E6C656E677468';
wwv_flow_imp.g_varchar2_table(505) := '2B223A222B28322A652E636F6C2B31295D3D722C742E7075736828722E6C61622E7374796C65643F7B636F6E74656E743A466528722E6C6162656C2C722E6C6162292C7374796C65733A6A6528722E6C6162297D3A722E6C6162656C2C652E7370616E3E';
wwv_flow_imp.g_varchar2_table(506) := '313F7B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2D317D3A2222297D7D293B666F722876617220723D322A43652865293B723C322A7A743B722B2B29742E70757368282222293B4D742E707573682874297D292C214D742E6C65';
wwv_flow_imp.g_varchar2_table(507) := '6E6774682972657475726E3B666F7228766172206B743D5465286D2E6669656C6473297C7C5065286D293F4D6174682E6D61782831302C28732D762D622D286D2E6C6162656C57696474687C7C3332292A7A74292F7A74293A302C4F743D303B4F743C32';
wwv_flow_imp.g_varchar2_table(508) := '2A7A743B4F742B3D322946745B4F745D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A6D2E6C6162656C57696474687C7C33327D2C6B7426262846745B4F742B315D3D7B63656C6C57696474683A6B747D293B766172206A743D';
wwv_flow_imp.g_varchar2_table(509) := '2E333532382A50742A312E333B72657475726E20692E6175746F5461626C65287B7374617274593A672C626F64793A4D742C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C726F7750616765427265616B';
wwv_flow_imp.g_varchar2_table(510) := '3A2261766F6964222C7374796C65733A7B666F6E7453697A653A50742C63656C6C50616464696E673A312E322C76616C69676E3A226D6964646C65227D2C636F6C756D6E5374796C65733A46742C646964506172736543656C6C3A66756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(511) := '65297B76617220743D22626F6479223D3D3D652E73656374696F6E26264E745B652E726F772E696E6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F';
wwv_flow_imp.g_varchar2_table(512) := '6E724C61622C6E3D723F4F6528722E6C622C5074293A303B72262628652E63656C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A312E322B6E2C72696768743A312E322C626F74746F6D3A312E322C6C6566743A312E327D292C652E63';
wwv_flow_imp.g_varchar2_table(513) := '656C6C2E7374796C65732E6D696E43656C6C4865696768743D742E6C696E65732A6A742B332B6E7D7D2C6469644472617743656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E26264E745B652E726F77';
wwv_flow_imp.g_varchar2_table(514) := '2E696E6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B69662872297B766172206E3D4F6528722E6C622C5074292B312E323B4C6528';
wwv_flow_imp.g_varchar2_table(515) := '692C652E63656C6C2C722C50742C312E32292C6D7428692C742C7B783A652E63656C6C2E782C793A652E63656C6C2E792B6E2D2E362C77696474683A652E63656C6C2E77696474682C6865696768743A652E63656C6C2E6865696768742D6E2B2E367D2C';
wwv_flow_imp.g_varchar2_table(516) := '5074297D656C7365206D7428692C742C652E63656C6C2C5074297D7D7D292C766F696420792832297D69662822616C6572746122213D3D45297B696628227461626C61223D3D3D45297B766172204C743D43286D2C4E293B696628214C742E6C656E6774';
wwv_flow_imp.g_varchar2_table(517) := '6826262131213D3D6D2E68696465456D7074792626216D2E656D707479546578742972657475726E3B7661722052743D6B286D2C4E2C4C74292C49743D5B5D2C44743D7B7D3B6966286D2E7469746C65262649742E70757368285B7B636F6E74656E743A';
wwv_flow_imp.g_varchar2_table(518) := '53286D2E7469746C652C4E292C636F6C5370616E3A52742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E7453697A653A6C2B317D7D5D292C6D2E67726F757073297B7661722055743D5B5D2C42743D5B5D2C47743D7B';
wwv_flow_imp.g_varchar2_table(519) := '68616C69676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B4F286D2C5274292E666F72456163682866756E6374696F6E2865297B666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B29652E';
wwv_flow_imp.g_varchar2_table(520) := '6761703F55742E70757368287B636F6E74656E743A52745B745D2E6C6162656C2C726F775370616E3A322C7374796C65733A7B68616C69676E3A53652852745B745D2C6D292C76616C69676E3A226D6964646C65227D7D293A42742E70757368287B636F';
wwv_flow_imp.g_varchar2_table(521) := '6E74656E743A52745B745D2E6C6162656C2C7374796C65733A7B68616C69676E3A53652852745B745D2C6D297D7D293B652E6761707C7C55742E70757368287B636F6E74656E743A652E6C6162656C2C636F6C5370616E3A652E636F6C732C7374796C65';
wwv_flow_imp.g_varchar2_table(522) := '733A47747D297D292C49742E707573682855742C4274297D656C73652049742E707573682852742E6D61702866756E6374696F6E2865297B72657475726E7B636F6E74656E743A652E6C6162656C2C7374796C65733A7B68616C69676E3A536528652C6D';
wwv_flow_imp.g_varchar2_table(523) := '297D7D7D29293B52742E666F72456163682866756E6374696F6E28652C74297B44745B745D3D7B68616C69676E3A652E616C69676E7D2C652E636F6C6F7226262844745B745D2E74657874436F6C6F723D6128652E636F6C6F7229292C652E626F6C6426';
wwv_flow_imp.g_varchar2_table(524) := '262844745B745D2E666F6E745374796C653D22626F6C6422292C652E776964746826262844745B745D2E63656C6C57696474683D652E7769647468297D293B7661722057743D6565286D2C4C74292C5F743D51286D292C48743D61286F2E67726F757029';
wwv_flow_imp.g_varchar2_table(525) := '2C56743D5B5D2C59743D5B5D2C24743D7B7D3B5A653D4C742E6C656E6774683F5B5D3A5B5B7B636F6E74656E743A53286D2E656D707479546578742C4E292C636F6C5370616E3A52742E6C656E6774682C7374796C65733A7B68616C69676E3A226C6566';
wwv_flow_imp.g_varchar2_table(526) := '74222C666F6E745374796C653A226974616C6963227D7D5D5D3B4C742E6C656E67746826262857742E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B2972657475726E205A652E70757368285B7B636F6E74656E';
wwv_flow_imp.g_varchar2_table(527) := '743A7465286D2C652C4E292C636F6C5370616E3A52742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A48747D7D5D292C56742E707573682865292C766F69';
wwv_flow_imp.g_varchar2_table(528) := '642059742E70757368286E756C6C293B6966282273756222213D3D652E6B297B76617220743D6E756C6C3B5A652E707573682852742E6D61702866756E6374696F6E28722C6E297B69662821722E63656C6C2972657475726E204C28722C652E722C4E29';
wwv_flow_imp.g_varchar2_table(529) := '3B76617220613D5528722C652E722C4E2C6F293B72657475726E206126262828743D747C7C7B7D295B6E5D3D612C24745B6E5D3D4D6174682E6D61782824745B6E5D7C7C302C612E7729292C22227D29292C56742E707573682865292C59742E70757368';
wwv_flow_imp.g_varchar2_table(530) := '2874297D656C7365204B285A2852742C5F742C652E726F77732C7465286D2C652C4E29292C52742E6C656E677468292E666F72456163682866756E6374696F6E2874297B5A652E707573682874292C56742E707573682865292C59742E70757368286E75';
wwv_flow_imp.g_varchar2_table(531) := '6C6C297D297D292C4F626A6563742E6B657973282474292E666F72456163682866756E6374696F6E2865297B44745B655D2E63656C6C57696474683D4D6174682E6D61782852745B655D2E77696474687C7C302C24745B655D2B33297D29293B76617220';
wwv_flow_imp.g_varchar2_table(532) := '71743D6E756C6C2C58743D56286D2E746F74616C73293B58742E6C656E67746826264C742E6C656E67746826262871743D4B285A2852742C58742C4C742C4A286D2C4E2C4C7429292C52742E6C656E67746829293B766172205A743D7B666F6E7453697A';
wwv_flow_imp.g_varchar2_table(533) := '653A6D2E73697A657C7C6C2C63656C6C50616464696E673A6D2E677269643F312E323A2E387D2C4A743D44286D2C5274293B4A742626285A742E76616C69676E3D4A74292C52742E666F72456163682866756E6374696F6E28652C74297B652E76616C69';
wwv_flow_imp.g_varchar2_table(534) := '676E26262844745B745D2E76616C69676E3D652E76616C69676E297D292C6D2E677269642626285A742E6C696E6557696474683D2E31352C5A742E6C696E65436F6C6F723D61286D2E626F72646572436F6C6F727C7C796529292C692E6175746F546162';
wwv_flow_imp.g_varchar2_table(535) := '6C65287B7374617274593A672C6D617267696E3A7B6C6566743A762C72696768743A627D2C686561643A49742C626F64793A5A652C666F6F743A71747C7C766F696420302C73686F77486561643A21313D3D3D6D2E7265706561744865616465723F2266';
wwv_flow_imp.g_varchar2_table(536) := '6972737450616765223A22657665727950616765222C73686F77466F6F743A226C61737450616765222C7374796C65733A5A742C686561645374796C65733A7B66696C6C436F6C6F723A662C74657874436F6C6F723A642C68616C69676E3A2263656E74';
wwv_flow_imp.g_varchar2_table(537) := '6572222C666F6E7453697A653A6D2E73697A657C7C6C7D2C666F6F745374796C65733A7B66696C6C436F6C6F723A702C74657874436F6C6F723A6D2E746F74616C73436F6C6F723F61286D2E746F74616C73436F6C6F72293A302C666F6E745374796C65';
wwv_flow_imp.g_varchar2_table(538) := '3A22626F6C64222C68616C69676E3A227269676874227D2C616C7465726E617465526F775374796C65733A6D2E627265616B42793F7B7D3A7B66696C6C436F6C6F723A687D2C636F6C756D6E5374796C65733A44742C646964506172736543656C6C3A66';
wwv_flow_imp.g_varchar2_table(539) := '756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F6E26264C742E6C656E677468297B76617220743D56745B652E726F772E696E6465785D3B696628742626226865616422213D3D742E6B297B69662822737562223D3D3D742E';
wwv_flow_imp.g_varchar2_table(540) := '6B2972657475726E20652E63656C6C2E7374796C65732E66696C6C436F6C6F723D702C766F696428652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C6422293B766172206E3D742E722C6F3D52745B652E636F6C756D6E2E696E6465';
wwv_flow_imp.g_varchar2_table(541) := '785D3B6D2E627265616B4279262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D742E6925323D3D3126262131213D3D6D2E7A656272613F683A5B3235352C3235352C3235355D293B766172206C3D7A286D2E726F775374796C652C4E2C';
wwv_flow_imp.g_varchar2_table(542) := '6E293B6C2626286C2E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D61286C2E66696C6C29292C6C2E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D61286C2E636F6C6F7229292C6C2E62';
wwv_flow_imp.g_varchar2_table(543) := '6F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B76617220693D6F26267A286F2E63656C6C5374796C652C4E2C6E293B69262628692E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F';
wwv_flow_imp.g_varchar2_table(544) := '6C6F723D6128692E66696C6C29292C692E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D6128692E636F6C6F7229292C692E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C6422';
wwv_flow_imp.g_varchar2_table(545) := '29293B76617220733D59745B652E726F772E696E6465785D262659745B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B73262628652E63656C6C2E7374796C65732E6D696E43656C6C4865696768743D4D6174682E6D61782865';
wwv_flow_imp.g_varchar2_table(546) := '2E63656C6C2E7374796C65732E6D696E43656C6C4865696768747C7C302C732E682B3229292C722626722E70646643656C6C2626722E70646643656C6C28652C6E2C6F2C6D2C4E297D7D7D2C6469644472617743656C6C3A66756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(547) := '69662822626F6479223D3D3D652E73656374696F6E297B76617220743D59745B652E726F772E696E6465785D262659745B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D52745B652E636F6C756D';
wwv_flow_imp.g_varchar2_table(548) := '6E2E696E6465785D2E616C69676E2C6E3D226C656674223D3D3D723F652E63656C6C2E782B313A227269676874223D3D3D723F652E63656C6C2E782B652E63656C6C2E77696474682D742E772D313A652E63656C6C2E782B28652E63656C6C2E77696474';
wwv_flow_imp.g_varchar2_table(549) := '682D742E77292F322C6F3D52745B652E636F6C756D6E2E696E6465785D2E76616C69676E7C7C4A742C613D22746F70223D3D3D6F3F652E63656C6C2E792B313A22626F74746F6D223D3D3D6F3F652E63656C6C2E792B652E63656C6C2E6865696768742D';
wwv_flow_imp.g_varchar2_table(550) := '742E682D313A652E63656C6C2E792B28652E63656C6C2E6865696768742D742E68292F323B692E616464496D61676528742E696D2E646174612C226A7067223D3D3D742E696D2E6578743F224A504547223A22504E47222C6E2C612C742E772C742E682C';
wwv_flow_imp.g_varchar2_table(551) := '766F696420302C224641535422297D7D7D7D292C79286D2E6761707C7C33297D7D656C73652043286D2C4E292E66696C7465722866756E6374696F6E2865297B72657475726E2054286D2E7768656E2C4E2C65297D292E736C69636528302C6D2E656163';
wwv_flow_imp.g_varchar2_table(552) := '683F3939393A31292E666F72456163682866756E6374696F6E2865297B692E6175746F5461626C65287B7374617274593A672C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C626F64793A5B5B53286D2E';
wwv_flow_imp.g_varchar2_table(553) := '746578742C4E2C65295D5D2C7374796C65733A7B666F6E7453697A653A6D2E73697A657C7C382C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A612841286D2E636F6C6F722C4E2C65297C7C';
wwv_flow_imp.g_varchar2_table(554) := '222345364543463222297D7D292C792831297D297D656C73657B766172204B743D6374286D2C4E293B696628214B742972657475726E3B7661722051743D4B742E6C6162656C3F2E333532382A4B742E7465787453697A652A312E343A303B78286D2C4B';
wwv_flow_imp.g_varchar2_table(555) := '742E772C4B742E682B51742C66756E6374696F6E28652C74297B76617220723D4B742E772F4B742E636F6C732C6E3D4B742E682F4B742E726F77732C6F3D61284B742E636F6C6F72293B692E73657446696C6C436F6C6F72286F5B305D2C6F5B315D2C6F';
wwv_flow_imp.g_varchar2_table(556) := '5B325D293B666F7228766172206C3D303B6C3C4B742E726F77733B6C2B2B29666F722876617220733D303B733C4B742E636F6C733B732B2B296966284B742E6461726B28732C6C29297B666F722876617220753D733B732B313C4B742E636F6C7326264B';
wwv_flow_imp.g_varchar2_table(557) := '742E6461726B28732B312C6C293B29732B2B3B692E7265637428652B752A722C742B6C2A6E2C28732D752B31292A722C6E2B286C3C4B742E726F77732D313F2E30323A30292C224622297D4B742E6C6162656C262628692E736574466F6E742822636F75';
wwv_flow_imp.g_varchar2_table(558) := '72696572222C226E6F726D616C22292C692E736574466F6E7453697A65284B742E7465787453697A65292C692E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C692E74657874284B742E746578742C652B4B742E772F322C742B';
wwv_flow_imp.g_varchar2_table(559) := '4B742E682B2E333532382A4B742E7465787453697A652A312E312C7B616C69676E3A2263656E746572227D292C692E73657454657874436F6C6F7228302C302C3029297D297D656C73657B7661722065723D6874286D2C4E2C6F293B6966282165722972';
wwv_flow_imp.g_varchar2_table(560) := '657475726E3B78286D2C65722E776D6D2C65722E686D6D2C66756E6374696F6E28652C74297B692E616464496D6167652865722E646174612C22504E47222C652C742C65722E776D6D2C65722E686D6D2C766F696420302C224641535422297D297D656C';
wwv_flow_imp.g_varchar2_table(561) := '73657B7661722074723D5165286D2C4E293B6966282174722972657475726E3B7661722072723D6574286D2C7472292C6E723D226A7067223D3D3D74722E6578743F224A504547223A22504E47223B78286D2C72722E772C72722E682C66756E6374696F';
wwv_flow_imp.g_varchar2_table(562) := '6E28652C74297B692E616464496D6167652874722E646174612C6E722C652C742C72722E772C72722E68297D297D7D292C492E746F3D692E696E7465726E616C2E6765744E756D6265724F66506167657328297D292C452E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(563) := '74696F6E2874297B76617220723D707428652C742E637478293B69662872297B692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E736574466F6E7453697A6528313030293B766172206E3D677428722C692E676574546578';
wwv_flow_imp.g_varchar2_table(564) := '74576964746828722E74657874292C732C75292C6F3D722E616E676C652A4D6174682E50492F3138302C6C3D6128722E636F6C6F72293B692E736574466F6E7453697A65286E293B666F722876617220633D692E67657454657874576964746828722E74';
wwv_flow_imp.g_varchar2_table(565) := '657874292C663D2E333532382A6E2A2E372C643D732F322D632F322A4D6174682E636F73286F292B662F322A4D6174682E73696E286F292C683D752F322B632F322A4D6174682E73696E286F292B662F322A4D6174682E636F73286F292C703D742E6672';
wwv_flow_imp.g_varchar2_table(566) := '6F6D3B703C3D742E746F3B702B2B29692E736574506167652870292C692E736176654772617068696373537461746528292C692E736574475374617465286E657720692E475374617465287B6F7061636974793A722E6F7061636974797D29292C692E73';
wwv_flow_imp.g_varchar2_table(567) := '657454657874436F6C6F72286C5B305D2C6C5B315D2C6C5B325D292C692E7465787428722E746578742C642C682C7B616E676C653A722E616E676C657D292C692E726573746F72654772617068696373537461746528293B692E73657454657874436F6C';
wwv_flow_imp.g_varchar2_table(568) := '6F7228302C302C30297D7D293B766172204E3D652E666F6F7465722C6A3D692E696E7465726E616C2E6765744E756D6265724F66506167657328292C523D745B305D7C7C7B533A7B7D2C543A7B7D7D3B6966284E297B666F722876617220493D313B493C';
wwv_flow_imp.g_varchar2_table(569) := '3D6A3B492B2B297B692E736574506167652849292C692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E736574466F6E7453697A65284E2E73697A657C7C37293B76617220423D61286F2E6D75746564293B692E736574';
wwv_flow_imp.g_varchar2_table(570) := '54657874436F6C6F7228425B305D2C425B315D2C425B325D293B76617220473D66756E6374696F6E2865297B72657475726E205328652C52292E7265706C61636528227B504147457D222C49292E7265706C61636528227B50414745537D222C6A297D3B';
wwv_flow_imp.g_varchar2_table(571) := '6966284E2E6C656674297B76617220573D692E73706C697454657874546F53697A652847284E2E6C656674292C2E37382A73293B692E7465787428572C632C752D342D28572E6C656E6774682D31292A284E2E73697A657C7C37292A2E34297D4E2E7269';
wwv_flow_imp.g_varchar2_table(572) := '6768742626692E746578742847284E2E7269676874292C732D632C752D352C7B616C69676E3A227269676874227D297D692E73657454657874436F6C6F7228302C302C30297D72657475726E20652E7469746C652626692E73657450726F706572746965';
wwv_flow_imp.g_varchar2_table(573) := '73287B7469746C653A5328652E7469746C652C52297D292C66756E6374696F6E2865297B76617220743D652E696E7465726E616C2E6163726F666F726D506C7567696E2C723D742626742E6163726F466F726D44696374696F6E617279526F6F743B6966';
wwv_flow_imp.g_varchar2_table(574) := '28722626722E4669656C64732626722E4669656C64732E6C656E677468262621722E5F5F6E72297B766172206E3D223C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F48656C766574696361202F';
wwv_flow_imp.g_varchar2_table(575) := '456E636F64696E67202F57696E416E7369456E636F64696E67203E3E222C6F3D652E696E7465726E616C2E676574466F6E74282268656C766574696361222C226E6F726D616C22292E69643B722E44413D222F48656C7620222B28652E5F5F6E72466F72';
wwv_flow_imp.g_varchar2_table(576) := '6D53697A657C7C39292B2220546620302067222C4F626A6563742E646566696E6550726F706572747928722C224452222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A223C3C202F466F6E74203C3C202F';
wwv_flow_imp.g_varchar2_table(577) := '48656C7620222B6E2B286F26262248656C7622213D3D6F3F22202F222B6F2B2220222B6E3A2222292B22202F5A614462203C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F5A61706644696E6762';
wwv_flow_imp.g_varchar2_table(578) := '617473203E3E203E3E203E3E227D292C4F626A6563742E646566696E6550726F706572747928722C224E656564417070656172616E636573222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A2274727565';
wwv_flow_imp.g_varchar2_table(579) := '227D292C722E5F5F6E723D21307D7D2869292C50726F6D6973652E7265736F6C766528692E6F7574707574282261727261796275666665722229297D66756E6374696F6E2062742865297B72657475726E20537472696E6728652E6C6162656C7C7C652E';
wwv_flow_imp.g_varchar2_table(580) := '6E616D65292E7265706C616365282F5C732B2F672C222022292E73756273747228302C3332297D66756E6374696F6E20777428652C742C72297B766172206E3D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6C286165297D7D3B652E';
wwv_flow_imp.g_varchar2_table(581) := '66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6C286F65297D7D2C652E626F726465723D7B746F703A6E2C6C6566743A6E2C626F74746F6D3A6E2C72696768743A6E7D2C';
wwv_flow_imp.g_varchar2_table(582) := '652E70726F74656374696F6E3D7B6C6F636B65643A2121742E726561644F6E6C797D2C652E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65222C686F72697A6F6E74616C3A22636865636B62';
wwv_flow_imp.g_varchar2_table(583) := '6F78223D3D3D742E696E7075743F2263656E746572223A226C656674222C77726170546578743A226D756C74696C696E65223D3D3D742E696E7075747D2C22636865636B626F78223D3D3D742E696E7075743F28652E76616C75653D742E636865636B65';
wwv_flow_imp.g_varchar2_table(584) := '643F6C653A69652C652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21312C666F726D756C61653A5B2722E298902CE2989222275D2C73686F774572726F724D6573736167653A21302C6572726F72';
wwv_flow_imp.g_varchar2_table(585) := '5469746C653A62742874292C6572726F723A22456C696A6120E29890206F20E298922E227D293A28652E76616C75653D22223D3D3D742E76616C75653F6E756C6C3A742E76616C75652C652E6E756D466D743D2240222C226C697374223D3D3D742E696E';
wwv_flow_imp.g_varchar2_table(586) := '7075743F652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B7228742E6F7074696F6E73295D2C73686F774572726F724D6573736167653A21302C6572726F72546974';
wwv_flow_imp.g_varchar2_table(587) := '6C653A62742874292C6572726F723A22456C696A6120756E2076616C6F72206465206C61206C697374612E227D3A742E6D61784C656E677468262628652E6461746156616C69646174696F6E3D7B747970653A22746578744C656E677468222C6F706572';
wwv_flow_imp.g_varchar2_table(588) := '61746F723A226C6573735468616E4F72457175616C222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B742E6D61784C656E6774685D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A62742874292C657272';
wwv_flow_imp.g_varchar2_table(589) := '6F723A224DC3A178696D6F20222B742E6D61784C656E6774682B2220636172616374657265732E227D29292C652E6E616D653D742E6E616D657D66756E6374696F6E20797428652C742C722C6E297B76617220613D6E65772077696E646F772E45786365';
wwv_flow_imp.g_varchar2_table(590) := '6C4A532E576F726B626F6F6B2C693D56652865292C733D7B7D2C753D666528652C6E292C633D756528292C663D5B5D2C6D3D7B77733A6E756C6C2C6E3A302C7265663A7B7D7D3B612E63726561746F723D226E6F76615265706F7274223B76617220763D';
wwv_flow_imp.g_varchar2_table(591) := '652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C73782E73686565744E616D657C7C225265706F727465227D5D2C623D446528652C22786C737822292C773D652E706167657C7C7B7D2C793D7B74';
wwv_flow_imp.g_varchar2_table(592) := '7970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6C28692E7072696D617279297D7D3B66756E6374696F6E20452865297B666F722876617220743D682865292E7265706C616365282F5B5C5B';
wwv_flow_imp.g_varchar2_table(593) := '5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C723D742C6E3D323B735B722E746F4C6F7765724361736528295D3B29723D742E73756273747228302C33312D537472696E67286E292E6C656E6774682D31292B225F222B6E';
wwv_flow_imp.g_varchar2_table(594) := '2C6E2B2B3B72657475726E20735B722E746F4C6F7765724361736528295D3D21302C727D66756E6374696F6E204E2865297B72657475726E7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267';
wwv_flow_imp.g_varchar2_table(595) := '623A6C2865297D7D7D66756E6374696F6E204C2865297B76617220743D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6C28657C7C7965297D7D3B72657475726E7B746F703A742C6C6566743A742C626F74746F6D3A742C7269676874';
wwv_flow_imp.g_varchar2_table(596) := '3A747D7D66756E6374696F6E20522865297B76617220743D652E6A6F696E28222C22293B696628742E6C656E6774683C3D3235302626212F5B2C225D2F2E7465737428652E6A6F696E28222229292972657475726E2722272B742B2722273B6966286D2E';
wwv_flow_imp.g_varchar2_table(597) := '7265665B745D2972657475726E206D2E7265665B745D3B6D2E77737C7C286D2E77733D612E616464576F726B7368656574284528226E725F6C697374617322292C7B73746174653A2268696464656E227D29293B76617220723D2B2B6D2E6E3B652E666F';
wwv_flow_imp.g_varchar2_table(598) := '72456163682866756E6374696F6E28652C74297B6D2E77732E67657443656C6C28742B312C72292E76616C75653D657D293B766172206E3D6D2E77732E676574436F6C756D6E2872292E6C65747465723B72657475726E206D2E7265665B745D3D222722';
wwv_flow_imp.g_varchar2_table(599) := '2B6D2E77732E6E616D652B22272124222B6E2B2224313A24222B6E2B2224222B652E6C656E6774682C6D2E7265665B745D7D72657475726E20742E666F72456163682866756E6374696F6E28722C6E297B76617220733D742E6C656E6774683E313F225F';
wwv_flow_imp.g_varchar2_table(600) := '222B286E2B31293A22223B762E666F72456163682866756E6374696F6E286E297B76617220683D53286E2E6E616D652C72293B67652626742E6C656E6774683E31262628683D53286E2E6D657267654E616D657C7C28762E6C656E6774683E313F227B44';
wwv_flow_imp.g_varchar2_table(601) := '4F432E444F435F4B45597D20222B6E2E6E616D653A227B444F432E444F435F4B45597D22292C7229293B766172206D3D612E616464576F726B736865657428452868292C7B7061676553657475703A7B6F7269656E746174696F6E3A772E6F7269656E74';
wwv_flow_imp.g_varchar2_table(602) := '6174696F6E7C7C22706F727472616974222C706170657253697A653A226C6567616C223D3D3D772E73697A653F353A226134223D3D3D772E73697A653F393A312C666974546F506167653A21302C666974546F57696474683A312C666974546F48656967';
wwv_flow_imp.g_varchar2_table(603) := '68743A307D7D292C423D6E2E73656374696F6E733F6E2E73656374696F6E732E6D61702866756E6374696F6E2865297B72657475726E226E756D626572223D3D747970656F6620653F625B655D3A622E66696C7465722866756E6374696F6E2874297B72';
wwv_flow_imp.g_varchar2_table(604) := '657475726E20742E69643D3D3D657D295B305D7D292E66696C74657228426F6F6C65616E293A623B423D4728422E66696C7465722866756E6374696F6E2865297B72657475726E20486528652C72297D29292E66696C7465722866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(605) := '297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662822786C737822293E3D30292626486528652C72297D293B766172204B3D342C6E653D312C6F653D7B7D2C61653D302C6C653D6E756C6C2C69653D6E756C';
wwv_flow_imp.g_varchar2_table(606) := '6C2C73653D21312C75653D66756E6374696F6E2865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E22636F6C756D6E6173223D3D3D742E747970653F4D6174682E6D617828652C5F6528742C22786C7378';
wwv_flow_imp.g_varchar2_table(607) := '222C722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B756528742E73656373292B317D2C2D3129293A22677275706F223D3D3D742E747970653F4D6174682E6D617828652C756528476528742C22786C737822';
wwv_flow_imp.g_varchar2_table(608) := '2C722929293A4D6174682E6D617828652C227461626C61223D3D3D742E747970653F6B28742C722C4328742C7229292E6C656E6774683A226669636861223D3D3D742E747970653F322A28742E636F6C756D6E737C7C33293A22666F726D756C6172696F';
wwv_flow_imp.g_varchar2_table(609) := '223D3D3D742E747970653F322A28742E636F6C756D6E737C7C32293A227461726A65746173223D3D3D742E747970653F496528742C722C69292E6E3A22746578746F223D3D3D742E747970657C7C22616C65727461223D3D3D742E747970653F343A3229';
wwv_flow_imp.g_varchar2_table(610) := '7D2C32297D3B66756E6374696F6E20666528652C74297B76617220723D537472696E67286E756C6C3D3D743F22223A74292E6C656E6774683B6F655B652B3D64655D3D4D6174682E6D696E2836302C4D6174682E6D6178286F655B655D7C7C382C722B32';
wwv_flow_imp.g_varchar2_table(611) := '29297D422E666F72456163682866756E6374696F6E2865297B22636F6C756D6E6173223D3D3D652E747970652626284B3D4D6174682E6D6178284B2C5F6528652C22786C7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B';
wwv_flow_imp.g_varchar2_table(612) := '72657475726E20652B756528742E73656373292B317D2C2D312929292C227461626C61223D3D3D652E7479706526262861652B2B2C4B3D4D6174682E6D6178284B2C6B28652C722C4328652C7229292E6C656E67746829292C226669636861223D3D3D65';
wwv_flow_imp.g_varchar2_table(613) := '2E747970652626284B3D4D6174682E6D6178284B2C322A28652E636F6C756D6E737C7C332929292C22666F726D756C6172696F223D3D3D652E747970652626284B3D4D6174682E6D6178284B2C322A28652E636F6C756D6E737C7C322929292C22746172';
wwv_flow_imp.g_varchar2_table(614) := '6A65746173223D3D3D652E747970652626284B3D4D6174682E6D6178284B2C496528652C722C69292E6E29292C22677275706F223D3D3D652E747970652626284B3D4D6174682E6D6178284B2C756528476528652C22786C7378222C72292929297D293B';
wwv_flow_imp.g_varchar2_table(615) := '7661722064653D302C68653D21313B66756E6374696F6E20706528652C74297B72657475726E206D2E67657443656C6C28652C742B6465297D66756E6374696F6E20676528652C742C722C6E297B6D2E6D6572676543656C6C7328652C742B64652C722C';
wwv_flow_imp.g_varchar2_table(616) := '6E2B6465297D66756E6374696F6E206D6528652C74297B76617220723D6D2E676574526F772865293B722E6865696768743D4D6174682E6D617828722E6865696768747C7C302C74297D66756E6374696F6E20766528652C742C722C6E297B766172206F';
wwv_flow_imp.g_varchar2_table(617) := '3D612E616464496D616765287B6261736536343A652E646174612C657874656E73696F6E3A226A7067223D3D3D652E6578743F226A706567223A22706E67227D293B6D2E616464496D616765286F2C7B746C3A7B636F6C3A64652C726F773A6E652D317D';
wwv_flow_imp.g_varchar2_table(618) := '2C6578743A7B77696474683A332E37382A742C6865696768743A332E37382A727D7D292C6E652B3D4D6174682E6365696C28332E37382A722F3230292B286E3F303A31297D66756E6374696F6E20626528652C742C722C6E297B6765286E652C312C6E65';
wwv_flow_imp.g_varchar2_table(619) := '2C4B293B766172206F3D7065286E652C31293B6F2E76616C75653D652C6F2E66696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6E26266D65286E652C';
wwv_flow_imp.g_varchar2_table(620) := '68653F4D6174682E6D6178286E2C31352A4D6174682E6365696C28537472696E6728657C7C2222292E6C656E6774682F4D6174682E6D61782831362C392A4B2929293A6E292C6E652B2B7D422E666F72456163682866756E6374696F6E2074286E297B76';
wwv_flow_imp.g_varchar2_table(621) := '617220753D6E2E747970653B69662822636F6C756D6E6173223D3D3D75297B76617220663D6E652C683D6E652C763D64652C623D4B2C773D302C453D68653B72657475726E2068653D21302C5F65286E2C22786C7378222C722C313030292E666F724561';
wwv_flow_imp.g_varchar2_table(622) := '63682866756E6374696F6E2865297B76617220723D756528652E73656373293B64653D762B772C4B3D722C6E653D662C652E736563732E666F72456163682874292C683D4D6174682E6D617828682C6E65292C772B3D722B317D292C64653D762C4B3D62';
wwv_flow_imp.g_varchar2_table(623) := '2C68653D452C766F6964286E653D68297D69662822677275706F223D3D3D75297B76617220473D722C77653D733B72657475726E205765286E2C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C733D77652B652E7375663B';
wwv_flow_imp.g_varchar2_table(624) := '766172206F3D4765286E2C22786C7378222C72292C613D6E653B6966286F2E6C656E6774687C7C6E2E7469746C65297B6E2E7469746C65262662652853286E2E7469746C652C72292C4E286E2E7469746C6546696C6C7C7C692E7072696D617279292C7B';
wwv_flow_imp.g_varchar2_table(625) := '626F6C643A21302C636F6C6F723A7B617267623A6C286E2E7469746C65436F6C6F727C7C692E6865616454657874297D7D2C3230292C6F2E666F72456163682874293B76617220753D4D6174682E6D617828612C6E652D31293B6966286E2E66696C6C29';
wwv_flow_imp.g_varchar2_table(626) := '666F722876617220633D613B633C3D753B632B2B29666F722876617220663D313B663C3D4B3B662B2B297B76617220643D706528632C66293B642E66696C6C2626227061747465726E223D3D3D642E66696C6C2E747970657C7C28642E66696C6C3D4E28';
wwv_flow_imp.g_varchar2_table(627) := '6E2E66696C6C29297D6966286E2E626F7264657229666F722876617220683D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6C286E2E626F72646572436F6C6F727C7C7965297D7D2C703D613B703C3D753B702B2B29666F7228766172';
wwv_flow_imp.g_varchar2_table(628) := '20673D313B673C3D4B3B672B2B29696628703D3D3D617C7C703D3D3D757C7C313D3D3D677C7C673D3D3D4B297B766172206D3D706528702C67292C763D49286D2E626F726465727C7C7B7D293B703D3D3D61262628762E746F703D68292C703D3D3D7526';
wwv_flow_imp.g_varchar2_table(629) := '2628762E626F74746F6D3D68292C313D3D3D67262628762E6C6566743D68292C673D3D3D4B262628762E72696768743D68292C6D2E626F726465723D767D6E653D752B312B28303D3D3D6E2E6761703F303A31297D7D292C723D472C766F696428733D77';
wwv_flow_imp.g_varchar2_table(630) := '65297D69662822686561646572223D3D3D75297B7661722078653D5265286E2C69292C54653D6E2E66696C6C3F4E2878652E66696C6C293A792C43653D7B617267623A6C2878652E636F6C6F72297D2C7A653D7B626F6C643A21302C73697A653A78652E';
wwv_flow_imp.g_varchar2_table(631) := '73697A652C636F6C6F723A43657D2C50653D7B73697A653A6E2E7375627469746C653F78652E73756253697A653A78652E726967687453697A652C636F6C6F723A43657D3B6E2E666F6E742626287A652E6E616D653D50652E6E616D653D78652E666F6E';
wwv_flow_imp.g_varchar2_table(632) := '745B315D292C62652853286E2E7469746C652C72292C54652C7A652C4D6174682E6D61782832362C4D6174682E726F756E6428312E382A78652E73697A652929292C286E2E72696768747C7C6E2E7375627469746C652926266265285B53286E2E737562';
wwv_flow_imp.g_varchar2_table(633) := '7469746C652C72292C53286E2E72696768742C72295D2E66696C74657228426F6F6C65616E292E6A6F696E28222020207C20202022292C54652C50652C4D6174682E6D61782831362C4D6174682E726F756E6428312E382A50652E73697A652929292C6E';
wwv_flow_imp.g_varchar2_table(634) := '652B2B7D656C73652069662822746578746F223D3D3D752950286E2C72292E666F72456163682866756E6374696F6E2874297B6765286E652C312C6E652C4B293B76617220723D7065286E652C31293B722E76616C75653D7B72696368546578743A4628';
wwv_flow_imp.g_varchar2_table(635) := '742C7B666F6E743A6E2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E7B746578743A652E742C666F6E743A7B626F6C643A212821652E';
wwv_flow_imp.g_varchar2_table(636) := '622626216E2E626F6C64292C6974616C69633A212821652E692626216E2E6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F696420302C6E616D653A4D5B652E665D5B315D2C636F6C6F723A';
wwv_flow_imp.g_varchar2_table(637) := '652E633F7B617267623A6C28652E63297D3A766F696420302C73697A653A6E2E73697A657C7C31307D7D7D297D2C722E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22746F70222C686F72697A6F6E74616C3A226A75';
wwv_flow_imp.g_varchar2_table(638) := '7374696679223D3D3D6E2E616C69676E3F226A757374696679223A6E2E616C69676E7C7C226C656674227D2C6D65286E652C4D6174682E6D61782831352C31352A4D6174682E6365696C28742E6C656E6774682F2868653F4D6174682E6D61782831362C';
wwv_flow_imp.g_varchar2_table(639) := '392A4B293A313430292929292C6E652B2B7D293B656C736520696628226573706163696F223D3D3D75296E652B2B3B656C73652069662822696D6167656E223D3D3D75297B766172206B653D5165286E2C72293B6966286B65297B766172204F653D6574';
wwv_flow_imp.g_varchar2_table(640) := '286E2C6B65293B7665286B652C4F652E772C4F652E68297D7D656C736520696628226772616669636F223D3D3D75297B766172206A653D6874286E2C722C69293B6A6526267665286A652C6A652E776D6D2C6A652E686D6D297D656C7365206966282263';
wwv_flow_imp.g_varchar2_table(641) := '6F6469676F223D3D3D75297B766172204C653D6374286E2C72293B6966284C65297B7661722044653D6674284C65293B69662876652844652C44652E776D6D2C44652E686D6D2C4C652E6C6162656C292C4C652E6C6162656C297B7661722055653D7065';
wwv_flow_imp.g_varchar2_table(642) := '286E652C31293B55652E76616C75653D4C652E746578742C55652E666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A4C652E7465787453697A657D2C6E652B3D327D7D7D656C7365206966282273616C746F223D3D3D75296E65';
wwv_flow_imp.g_varchar2_table(643) := '2B2B3B656C736520696628226669636861223D3D3D75297B7661722042653D43286E2C72295B305D7C7C7B7D2C48653D6E2E636F6C756D6E737C7C332C56653D313B456528286E2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(644) := '65297B72657475726E21652E7768656E7C7C5428652E7768656E2C722C4265297D292C4865292E666F72456163682866756E6374696F6E28652C74297B743E3026266E652B2B3B76617220613D652E736F6D652866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(645) := '726E21652E656D707479262622746F70223D3D3D4D6528652E662C6E292E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220743D652E663B56653D312B322A652E636F6C3B76617220692C';
wwv_flow_imp.g_varchar2_table(646) := '733D4D6528742C6E292C753D56652B322A652E7370616E2D312C633D6E756C6C2C663D5328742E6C6162656C2C722C4265293B696628226C656674223D3D3D732E706F73297B696628633D7065286E652C5665292C693D7065286E652C56652B31292C63';
wwv_flow_imp.g_varchar2_table(647) := '2E76616C75653D466528662C73292C632E666F6E743D6E2E6C6162656C436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A6C286E2E6C6162656C436F6C6F72297D7D3A7B626F6C643A21307D2C6E2E6C6162656C46696C6C262628632E';
wwv_flow_imp.g_varchar2_table(648) := '66696C6C3D4E286E2E6C6162656C46696C6C29292C6E2E76616C7565436F6C6F72262628692E666F6E743D7B636F6C6F723A7B617267623A6C286E2E76616C7565436F6C6F72297D7D292C6E2E67726964262628632E626F726465723D692E626F726465';
wwv_flow_imp.g_varchar2_table(649) := '723D4C286E2E626F72646572436F6C6F72292C632E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C28652E7370616E3E317C7C61292626286765286E652C56652B312C613F6E652B313A6E65';
wwv_flow_imp.g_varchar2_table(650) := '2C75292C6E2E677269642929666F722876617220683D56652B323B683C3D753B682B2B297065286E652C68292E626F726465723D4C286E2E626F72646572436F6C6F72293B612626286765286E652C56652C6E652B312C5665292C632E616C69676E6D65';
wwv_flow_imp.g_varchar2_table(651) := '6E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C732E7374796C656426264E6528632C732C2131297D656C73657B76617220703D22746F70223D3D3D732E706F732626613F6E652B313A6E652C6D3D226E6F6E65';
wwv_flow_imp.g_varchar2_table(652) := '223D3D3D732E706F732626613F6E652B313A703B69662822746F70223D3D3D732E706F73297B28633D7065286E652C566529292E76616C75653D466528662C73292C753E566526266765286E652C56652C6E652C75292C6E2E67726964262628632E626F';
wwv_flow_imp.g_varchar2_table(653) := '726465723D4C286E2E626F72646572436F6C6F7229293B76617220763D416528742C722C4265293B4E6528632C732C21302C762626762E616C69676E297D693D706528702C5665292C28753E56657C7C6D3E70292626676528702C56652C6D2C75292C6E';
wwv_flow_imp.g_varchar2_table(654) := '2E76616C7565436F6C6F72262628692E666F6E743D7B636F6C6F723A7B617267623A6C286E2E76616C7565436F6C6F72297D7D292C6E2E67726964262628692E626F726465723D4C286E2E626F72646572436F6C6F7229297D76617220623D2F5E5C7B5B';
wwv_flow_imp.g_varchar2_table(655) := '5E7D7C5D2B5C7D242F2E7465737428742E76616C75657C7C222229262621742E6D61703F7828722C742E76616C75652E736C69636528312C2D31292C4265293A6E756C6C3B6F2862292626216728742E666D74293F28692E76616C75653D622C226D6F6E';
wwv_flow_imp.g_varchar2_table(656) := '6579223D3D3D742E666D74262628692E6E756D466D743D22232C2323302E303022292C692E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A2264617465223D3D3D742E666D742626642862293F28692E76616C75653D6428';
wwv_flow_imp.g_varchar2_table(657) := '62292C692E6E756D466D743D2264642F6D6D2F79797979222C692E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A692E76616C75653D726528742C722C4265292C6E2E67726964262628692E616C69676E6D656E743D7B68';
wwv_flow_imp.g_varchar2_table(658) := '6F72697A6F6E74616C3A226C656674222C766572746963616C3A226D6964646C65222C77726170546578743A21307D293B76617220773D416528742C722C4265293B69662877297B696628772E626F6C647C7C772E636F6C6F72297B76617220793D7B7D';
wwv_flow_imp.g_varchar2_table(659) := '3B4F626A6563742E6B65797328692E666F6E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B795B655D3D692E666F6E745B655D7D292C772E626F6C64262628792E626F6C643D2130292C772E636F6C6F72262628792E636F6C6F723D';
wwv_flow_imp.g_varchar2_table(660) := '7B617267623A6C28772E636F6C6F72297D292C692E666F6E743D797D696628772E616C69676E297B76617220453D7B7D3B4F626A6563742E6B65797328692E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B455B';
wwv_flow_imp.g_varchar2_table(661) := '655D3D692E616C69676E6D656E745B655D7D292C452E686F72697A6F6E74616C3D772E616C69676E2C692E616C69676E6D656E743D457D772E66696C6C262628692E66696C6C3D4E28772E66696C6C29297D226C656674223D3D3D732E706F733F286665';
wwv_flow_imp.g_varchar2_table(662) := '2856652C66292C313D3D3D652E7370616E262666652856652B312C726528742C722C42652929293A313D3D3D652E7370616E262666652856652B312C537472696E6728726528742C722C426529292E73756273747228302C343029297D7D292C6126266E';
wwv_flow_imp.g_varchar2_table(663) := '652B2B7D292C6E652B3D327D656C736520696628227461726A65746173223D3D3D7529666F72287661722059653D4965286E2C722C69292C24653D303B24653C59652E6974656D732E6C656E6774683B24652B3D59652E6E297B7661722071653D313B59';
wwv_flow_imp.g_varchar2_table(664) := '652E6974656D732E736C6963652824652C24652B59652E6E292E666F72456163682866756E6374696F6E28652C74297B76617220723D7065286E652C742B31292C6E3D7065286E652B312C742B31292C6F3D59652E616363656E743F7B6C6566743A7B73';
wwv_flow_imp.g_varchar2_table(665) := '74796C653A22746869636B222C636F6C6F723A7B617267623A6C2859652E616363656E74297D7D7D3A7B7D3B722E76616C75653D652E6C6162656C2C722E666F6E743D7B73697A653A59652E6C6162656C53697A652B312C636F6C6F723A7B617267623A';
wwv_flow_imp.g_varchar2_table(666) := '6C2859652E6C6162656C436F6C6F72297D7D2C6E2E76616C75653D652E76616C75652C6E2E666F6E743D7B626F6C643A21302C73697A653A59652E73697A652C636F6C6F723A7B617267623A6C28652E636F6C6F727C7C59652E76616C7565436F6C6F72';
wwv_flow_imp.g_varchar2_table(667) := '297D7D2C5B722C6E5D2E666F72456163682866756E6374696F6E2865297B652E66696C6C3D4E2859652E66696C6C292C652E626F726465723D6F2C652E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C696E64656E743A312C77';
wwv_flow_imp.g_varchar2_table(668) := '726170546578743A21307D7D292C666528742B312C652E6C6162656C292C666528742B312C537472696E6728652E76616C7565292E73756273747228302C3430292B2220202020202022292C71653D4D6174682E6D61782871652C4D6174682E6365696C';
wwv_flow_imp.g_varchar2_table(669) := '28537472696E6728652E76616C7565292E6C656E6774682F343029297D292C6D65286E652C3136292C6D65286E652B312C4D6174682E726F756E6428312E372A59652E73697A65292A7165292C6E652B3D337D656C73652069662822666F726D756C6172';
wwv_flow_imp.g_varchar2_table(670) := '696F223D3D3D75297B7661722058653D6E2E636F6C756D6E737C7C322C5A653D312C4A653D6365286E2C722C73293B4565284A652C5865292E666F72456163682866756E6374696F6E28652C74297B743E3026266E652B2B3B76617220723D652E736F6D';
wwv_flow_imp.g_varchar2_table(671) := '652866756E6374696F6E2865297B72657475726E21652E656D707479262622746F70223D3D3D652E662E6C61622E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220743D652E662C6E3D74';
wwv_flow_imp.g_varchar2_table(672) := '2E6C61623B5A653D312B322A652E636F6C2C6328742E6E616D65293B766172206F3D5A652B322A652E7370616E2D312C613D22636865636B626F78223D3D3D742E696E7075743F22223A742E76616C75652E6C656E6774683E32303F742E76616C75653A';
wwv_flow_imp.g_varchar2_table(673) := '6E6577204172726179283231292E6A6F696E28227822293B696628226C656674223D3D3D6E2E706F73297B766172206C3D7065286E652C5A65292C693D7065286E652C5A652B31293B72657475726E206C2E76616C75653D466528742E6C6162656C2C6E';
wwv_flow_imp.g_varchar2_table(674) := '292C6C2E666F6E743D7B626F6C643A21307D2C6C2E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65227D2C28652E7370616E3E317C7C722926266765286E652C5A652B312C723F6E652B313A';
wwv_flow_imp.g_varchar2_table(675) := '6E652C6F292C7226266765286E652C5A652C6E652B312C5A65292C6E2E7374796C656426264E65286C2C6E2C2131292C777428692C742C52292C742E6C696E65733E3126266D6528723F6E652B313A6E652C31352A742E6C696E6573292C6665285A652C';
wwv_flow_imp.g_varchar2_table(676) := '742E6C6162656C292C766F696428313D3D3D652E7370616E26266665285A652B312C6129297D76617220733D22746F70223D3D3D6E2E706F732626723F6E652B313A6E652C753D226E6F6E65223D3D3D6E2E706F732626723F6E652B313A733B69662822';
wwv_flow_imp.g_varchar2_table(677) := '746F70223D3D3D6E2E706F73297B76617220663D7065286E652C5A65293B662E76616C75653D466528742E6C6162656C2C6E292C6F3E5A6526266765286E652C5A652C6E652C6F292C4E6528662C6E2C2130297D286F3E5A657C7C753E73292626676528';
wwv_flow_imp.g_varchar2_table(678) := '732C5A652C752C6F292C777428706528732C5A65292C742C52292C742E6C696E65733E3126266D6528752C31352A742E6C696E6573292C313D3D3D652E7370616E26266665285A652B312C61297D7D292C7226266E652B2B7D292C4A652E6C656E677468';
wwv_flow_imp.g_varchar2_table(679) := '26262873653D21302C6E652B3D32297D656C73652069662822616C65727461223D3D3D752943286E2C72292E66696C7465722866756E6374696F6E2865297B72657475726E2054286E2E7768656E2C722C65297D292E736C69636528302C6E2E65616368';
wwv_flow_imp.g_varchar2_table(680) := '3F3939393A31292E666F72456163682866756E6374696F6E2865297B62652853286E2E746578742C722C65292C4E2841286E2E636F6C6F722C722C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C6E652B2B3B656C736520';
wwv_flow_imp.g_varchar2_table(681) := '696628227461626C61223D3D3D75297B766172204B653D43286E2C72293B696628214B652E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B7661722074743D6B286E2C722C4B65293B';
wwv_flow_imp.g_varchar2_table(682) := '6966286E2E7469746C65297B6765286E652C312C6E652C74742E6C656E677468293B7661722072743D7065286E652C31293B72742E76616C75653D53286E2E7469746C652C72292C72742E666F6E743D7B626F6C643A21302C636F6C6F723A7B61726762';
wwv_flow_imp.g_varchar2_table(683) := '3A6C28692E6865616454657874297D7D2C72742E66696C6C3D792C6E652B2B7D766172206E743D6E653B6966286E2E67726F757073297B766172206F743D313B4F286E2C7474292E666F72456163682866756E6374696F6E2865297B652E636F6C733E31';
wwv_flow_imp.g_varchar2_table(684) := '262621652E67617026266765286E652C6F742C6E652C6F742B652E636F6C732D31293B76617220743D7065286E652C6F74293B696628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B6765286E652C6F742B722C6E65';
wwv_flow_imp.g_varchar2_table(685) := '2B312C6F742B72293B766172206F3D7065286E652C6F742B72293B6F2E76616C75653D74745B652E66726F6D2B725D2E6C6162656C2C6F2E66696C6C3D792C6F2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E6865616454';
wwv_flow_imp.g_varchar2_table(686) := '657874297D7D2C6F2E616C69676E6D656E743D7B686F72697A6F6E74616C3A53652874745B652E66726F6D2B725D2C6E292C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6665286F742B722C74745B652E66726F6D2B72';
wwv_flow_imp.g_varchar2_table(687) := '5D2E6C6162656C297D6F742B3D652E636F6C737D656C736520742E76616C75653D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D792C742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E6865616454657874297D7D2C';
wwv_flow_imp.g_varchar2_table(688) := '742E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65227D2C6F742B3D652E636F6C737D292C6E652B2B7D7661722061743D6E652C6C743D7B7D3B6966286E2E67726F75707326264F';
wwv_flow_imp.g_varchar2_table(689) := '286E2C7474292E666F72456163682866756E6374696F6E2865297B696628652E67617029666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B296C745B745D3D317D292C74742E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(690) := '6F6E28652C74297B696628216C745B745D297B76617220723D7065286E652C742B31293B722E76616C75653D652E6C6162656C2C722E66696C6C3D792C722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6C28692E68656164546578';
wwv_flow_imp.g_varchar2_table(691) := '74297D7D2C722E616C69676E6D656E743D7B686F72697A6F6E74616C3A536528652C6E292C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C666528742B312C652E6C6162656C297D7D292C6E652B2B2C214B652E6C656E67';
wwv_flow_imp.g_varchar2_table(692) := '74682972657475726E206765286E652C312C6E652C74742E6C656E677468292C7065286E652C31292E76616C75653D53286E2E656D707479546578742C72292C7065286E652C31292E666F6E743D7B6974616C69633A21307D2C766F6964286E652B3D32';
wwv_flow_imp.g_varchar2_table(693) := '293B7661722069743D6E652C73743D6565286E2C4B65292C75743D51286E292C64743D6E756C6C2C70743D66756E6374696F6E28652C742C722C6F2C612C732C75297B76617220633D5A2874742C742C722C6F292C663D242874292C683D66756E637469';
wwv_flow_imp.g_varchar2_table(694) := '6F6E2865297B72657475726E20652E66696C6C3D4E28692E746F74616C73292C652E666F6E743D6E2E746F74616C73436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A6C286E2E746F74616C73436F6C6F72297D7D3A7B626F6C643A21';
wwv_flow_imp.g_varchar2_table(695) := '307D2C657D3B28632E61743E317C7C303D3D3D632E6174292626676528652C312C652C632E61747C7C74742E6C656E677468293B76617220673D6828706528652C3129293B72657475726E20672E76616C75653D6F2C672E616C69676E6D656E743D7B68';
wwv_flow_imp.g_varchar2_table(696) := '6F72697A6F6E74616C3A226C656674227D2C303D3D3D632E61742626652B2B2C74742E666F72456163682866756E6374696F6E286E2C6F297B69662821286F3C632E617429297B766172206C3D6828706528652C6F2B3129292C693D6E2E636F6C3F5928';
wwv_flow_imp.g_varchar2_table(697) := '742C6E2E636F6C293A6E756C6C3B69662869297B76617220673D6D2E676574436F6C756D6E286F2B312B6465292E6C65747465722C763D672B612B223A222B672B732C623D5828722C692E636F6C2C692E666E292C773D226D696E22213D3D692E666E26';
wwv_flow_imp.g_varchar2_table(698) := '26226D617822213D3D692E666E7C7C6E756C6C3D3D3D627C7C712862293F6E756C6C3A642862292C793D6E756C6C3D3D623F6E756C6C3A777C7C28712862293F4D6174682E726F756E64283130302A4E756D626572286229292F3130303A537472696E67';
wwv_flow_imp.g_varchar2_table(699) := '286229293B6C2E76616C75653D7B666F726D756C613A28753F22535542544F54414C28222B575B692E666E5D2B222C223A5F5B692E666E5D2B222822292B762B2229222C726573756C743A797D3B76617220783D22636F756E74223D3D3D692E666E3F22';
wwv_flow_imp.g_varchar2_table(700) := '232C232330223A773F2264642F6D6D2F79797979223A22232C2323302E3030223B6C2E6E756D466D743D662626485B692E666E5D3F2722272B485B692E666E5D2B272022272B783A782C6C2E616C69676E6D656E743D7B686F72697A6F6E74616C3A2272';
wwv_flow_imp.g_varchar2_table(701) := '69676874227D2C6E756C6C3D3D3D797C7C777C7C6665286F2B312C712879293F7028792C226D6F6E657922293A79297D7D7D292C652B317D3B73742E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B297B676528';
wwv_flow_imp.g_varchar2_table(702) := '6E652C312C6E652C74742E6C656E677468293B76617220743D7065286E652C31293B72657475726E20742E76616C75653D7465286E2C652C72292C742E666F6E743D7B626F6C643A21307D2C742E66696C6C3D4E28692E67726F7570292C766F6964206E';
wwv_flow_imp.g_varchar2_table(703) := '652B2B7D69662822737562223D3D3D652E6B2972657475726E206E653D7074286E652C75742C652E726F77732C7465286E2C652C72292C64742C6E652D312C2130292C766F69642864743D6E756C6C293B6E756C6C3D3D3D647426262864743D6E65293B';
wwv_flow_imp.g_varchar2_table(704) := '76617220733D652E722C753D652E692C633D44286E2C7474292C663D7A286E2E726F775374796C652C722C73293B74742E666F72456163682866756E6374696F6E28652C74297B76617220683D7065286E652C742B31292C763D6A28652C732C72293B69';
wwv_flow_imp.g_varchar2_table(705) := '6628652E63656C6C297B76617220623D5528652C732C722C69292C773D742B312B64653B696628682E76616C75653D6E756C6C2C28652E76616C69676E7C7C6329262628682E616C69676E6D656E743D7B686F72697A6F6E74616C3A652E616C69676E2C';
wwv_flow_imp.g_varchar2_table(706) := '766572746963616C3A652E76616C69676E7C7C637D292C7525323D3D3126262131213D3D6E2E7A65627261262628682E66696C6C3D4E28692E7A6562726129292C62297B76617220793D612E616464496D616765287B6261736536343A622E696D2E6461';
wwv_flow_imp.g_varchar2_table(707) := '74612C657874656E73696F6E3A226A7067223D3D3D622E696D2E6578743F226A706567223A22706E67227D293B6D2E616464496D61676528792C7B746C3A7B636F6C3A772D312B2E30382C726F773A6E652D312B2E30387D2C6578743A7B77696474683A';
wwv_flow_imp.g_varchar2_table(708) := '332E37382A622E772C6865696768743A332E37382A622E687D7D292C6D65286E652C322E3833352A622E682B34292C6F655B775D3D4D6174682E6D696E2836302C4D6174682E6D6178286F655B775D7C7C382C4D6174682E6365696C28332E37382A622E';
wwv_flow_imp.g_varchar2_table(709) := '772F37292B3229297D7D656C73657B652E69734E756D26266F2876293F28682E76616C75653D762C682E6E756D466D743D22696E74223D3D3D652E666D743F22232C232330223A226D6F6E6579223D3D3D652E666D747C7C2F5E6E756D2F2E7465737428';
wwv_flow_imp.g_varchar2_table(710) := '652E666D747C7C2222293F22232C2323302E222B6E657720417272617928312A2828652E666D747C7C2222292E73706C697428223A22295B315D7C7C32292B31292E6A6F696E28223022293A2247656E6572616C22293A226461746522213D3D652E666D';
wwv_flow_imp.g_varchar2_table(711) := '742626224441544522213D3D28722E545B537472696E67286E2E736F75726365292E746F55707065724361736528295D7C7C7B7D295B652E636F6C5D7C7C21642876293F682E76616C75653D6E756C6C3D3D763F6E756C6C3A6728652E666D7429262621';
wwv_flow_imp.g_varchar2_table(712) := '652E6D61703F7028762C652E666D74293A537472696E672876293A28682E76616C75653D642876292C682E6E756D466D743D2264642F6D6D2F7979797922292C682E616C69676E6D656E743D652E76616C69676E7C7C633F7B686F72697A6F6E74616C3A';
wwv_flow_imp.g_varchar2_table(713) := '652E616C69676E2C766572746963616C3A652E76616C69676E7C7C637D3A7B686F72697A6F6E74616C3A652E616C69676E7D3B76617220783D7A28652E63656C6C5374796C652C722C73297C7C663B782626782E66696C6C3F682E66696C6C3D4E28782E';
wwv_flow_imp.g_varchar2_table(714) := '66696C6C293A7525323D3D3126262131213D3D6E2E7A65627261262628682E66696C6C3D4E28692E7A6562726129293B76617220533D7B7D3B28652E626F6C647C7C782626782E626F6C6429262628532E626F6C643D2130292C28782626782E636F6C6F';
wwv_flow_imp.g_varchar2_table(715) := '727C7C652E636F6C6F7229262628532E636F6C6F723D7B617267623A6C28782626782E636F6C6F727C7C652E636F6C6F72297D292C28532E626F6C647C7C532E636F6C6F7229262628682E666F6E743D53292C666528742B312C652E69734E756D3F7028';
wwv_flow_imp.g_varchar2_table(716) := '762C652E666D74293A76297D7D292C6E652B2B7D293B7661722067743D6E652D312C6D743D56286E2E746F74616C73293B6966286D742E6C656E6774682626286E653D7074286E652C6D742C4B652C4A286E2C722C4B65292C69742C6E652D312C21216E';
wwv_flow_imp.g_varchar2_table(717) := '2E627265616B427929292C6E2E6772696429666F72287661722076743D4C286E2E626F72646572436F6C6F72292C62743D6E743B62743C6E653B62742B2B29666F72287661722079743D313B79743C3D74742E6C656E6774683B79742B2B297065286274';
wwv_flow_imp.g_varchar2_table(718) := '2C7974292E626F726465723D76743B31213D3D61657C7C6E2E627265616B42797C7C68657C7C2869653D7B66726F6D3A7B726F773A61742C636F6C756D6E3A317D2C746F3A7B726F773A67742C636F6C756D6E3A74742E6C656E6774687D7D2C422E696E';
wwv_flow_imp.g_varchar2_table(719) := '6465784F66286E293C3D312626286C653D617429292C6E652B2B7D7D292C4F626A6563742E6B657973286F65292E666F72456163682866756E6374696F6E2865297B6D2E676574436F6C756D6E282B65292E77696474683D6F655B655D7D292C69652626';
wwv_flow_imp.g_varchar2_table(720) := '286D2E6175746F46696C7465723D6965292C6C652626286D2E76696577733D5B7B73746174653A2266726F7A656E222C7953706C69743A6C657D5D292C73652626752E70726F746563742626662E70757368286D2E70726F7465637428752E7061737377';
wwv_flow_imp.g_varchar2_table(721) := '6F72642C7B73656C6563744C6F636B656443656C6C733A21302C73656C656374556E6C6F636B656443656C6C733A21302C666F726D6174436F6C756D6E733A21302C666F726D6174526F77733A21307D29292C652E666F6F7465722626286D2E68656164';
wwv_flow_imp.g_varchar2_table(722) := '6572466F6F7465722E6F6464466F6F7465723D22264C2638222B5328652E666F6F7465722E6C6566742C72292E7265706C616365282F262F672C22262622292E73756273747228302C323030292B222652263850C3A167696E6120265020646520264E22';
wwv_flow_imp.g_varchar2_table(723) := '297D297D292C6865286529262666756E6374696F6E2865297B76617220743D652E646566696E65644E616D65732C723D7426264F626A6563742E6765744F776E50726F706572747944657363726970746F72284F626A6563742E67657450726F746F7479';
wwv_flow_imp.g_varchar2_table(724) := '70654F662874292C226D6F64656C22293B722626722E676574262621742E5F5F6E722626284F626A6563742E646566696E6550726F706572747928742C226D6F64656C222C7B636F6E666967757261626C653A21302C6765743A66756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(725) := '7B72657475726E20722E6765742E63616C6C2874686973292E6D61702866756E6374696F6E2865297B72657475726E7B6E616D653A652E6E616D652C72616E6765733A652E72616E6765732E6D61702866756E6374696F6E2865297B76617220743D2F5E';
wwv_flow_imp.g_varchar2_table(726) := '285B5E27215D2B2921282E2B29242F2E657865632865293B72657475726E20743F2227222B745B315D2B222721222B745B325D3A657D297D7D297D2C7365743A66756E6374696F6E2865297B722E7365742E63616C6C28746869732C65297D7D292C742E';
wwv_flow_imp.g_varchar2_table(727) := '5F5F6E723D2130297D2861292C662E6C656E6774683F50726F6D6973652E616C6C2866292E7468656E2866756E6374696F6E28297B72657475726E20612E786C73782E777269746542756666657228297D293A612E786C73782E77726974654275666665';
wwv_flow_imp.g_varchar2_table(728) := '7228297D7661722078743D7B6C65747465723A5B31323234302C31353834305D2C6C6567616C3A5B31323234302C32303136305D2C61343A5B31313930362C31363833385D7D3B66756E6374696F6E20537428652C742C72297B766172206E3D77696E64';
wwv_flow_imp.g_varchar2_table(729) := '6F772E646F63782C6F3D5B5D2C613D4D6174682E726F756E6428322A28652E73697A657C7C3729292C6C3D6928722E6D75746564293B66756E6374696F6E20732865297B76617220723D5328652C74292E73706C6974282F285C7B50414745533F5C7D29';
wwv_flow_imp.g_varchar2_table(730) := '2F292C6F3D5B5D3B72657475726E20722E666F72456163682866756E6374696F6E2865297B227B504147457D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E4355525245';
wwv_flow_imp.g_varchar2_table(731) := '4E545D2C73697A653A612C636F6C6F723A6C7D29293A227B50414745537D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E544F54414C5F50414745535D2C73697A653A61';
wwv_flow_imp.g_varchar2_table(732) := '2C636F6C6F723A6C7D29293A6526266F2E70757368286E6577206E2E5465787452756E287B746578743A652C73697A653A612C636F6C6F723A6C7D29297D292C6F7D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772';
wwv_flow_imp.g_varchar2_table(733) := '617068287B6368696C6472656E3A7328652E6C656674297D29292C652E726967687426266F2E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E';
wwv_flow_imp.g_varchar2_table(734) := '3A7328652E7269676874297D29292C6F2E6C656E6774683F6F3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D7D7661722045743D22E29FA64E52463A223B66756E6374696F6E2054742865297B72657475726E205374';
wwv_flow_imp.g_varchar2_table(735) := '72696E672865292E7265706C616365282F262F672C2226616D703B22292E7265706C616365282F3C2F672C22266C743B22292E7265706C616365282F3E2F672C222667743B22292E7265706C616365282F222F672C222671756F743B22297D66756E6374';
wwv_flow_imp.g_varchar2_table(736) := '696F6E20437428652C74297B696628653D652E7265706C616365282F3C773A646F63756D656E7450726F74656374696F6E5B5E3E5D2A5C2F3E2F672C2222292C21742E70726F746563742972657475726E20653B76617220723D273C773A646F63756D65';
wwv_flow_imp.g_varchar2_table(737) := '6E7450726F74656374696F6E20773A656469743D22666F726D732220773A656E666F7263656D656E743D223122273B696628742E70617373776F7264297B766172206E3D66756E6374696F6E2865297B76617220743D6E65772055696E74384172726179';
wwv_flow_imp.g_varchar2_table(738) := '2865292C723D22756E646566696E656422213D747970656F662077696E646F7726262877696E646F772E63727970746F7C7C77696E646F772E6D7343727970746F293B696628722626722E67657452616E646F6D56616C75657329722E67657452616E64';
wwv_flow_imp.g_varchar2_table(739) := '6F6D56616C7565732874293B656C736520666F7228766172206E3D303B6E3C653B6E2B2B29745B6E5D3D4D6174682E666C6F6F72283235362A4D6174682E72616E646F6D2829293B72657475726E20747D283136292C6F3D3165353B722B3D2720773A63';
wwv_flow_imp.g_varchar2_table(740) := '7279707450726F7669646572547970653D227273614145532220773A6372797074416C676F726974686D436C6173733D22686173682220773A6372797074416C676F726974686D547970653D2274797065416E792220773A6372797074416C676F726974';
wwv_flow_imp.g_varchar2_table(741) := '686D5369643D2231342220773A63727970745370696E436F756E743D22272B6F2B272220773A686173683D22272B5A6528776528742E70617373776F72642C6E2C6F29292B272220773A73616C743D22272B5A65286E292B2722277D722B3D222F3E223B';
wwv_flow_imp.g_varchar2_table(742) := '76617220613D5B223C773A6576656E416E644F646448656164657273222C223C773A636F6D706174222C223C2F773A73657474696E67733E225D2E6D61702866756E6374696F6E2874297B72657475726E20652E696E6465784F662874297D292E66696C';
wwv_flow_imp.g_varchar2_table(743) := '7465722866756E6374696F6E2865297B72657475726E20653E3D307D295B305D3B72657475726E20652E73756273747228302C61292B722B652E7375627374722861297D66756E6374696F6E20417428652C742C72297B72657475726E20722E70726F74';
wwv_flow_imp.g_varchar2_table(744) := '6563742626722E70617373776F72642626776528722E70617373776F72642C6E65772055696E74384172726179283136292C30292C77696E646F772E4A535A69702E6C6F61644173796E632865292E7468656E2866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(745) := '726E2050726F6D6973652E616C6C285B652E66696C652822776F72642F646F63756D656E742E786D6C22292E6173796E632822737472696E6722292C652E66696C652822776F72642F73657474696E67732E786D6C22292E6173796E632822737472696E';
wwv_flow_imp.g_varchar2_table(746) := '6722295D292E7468656E2866756E6374696F6E286E297B766172206F3D302C613D6E65772052656745787028273C773A723E283C773A7250723E283F3A283F213C2F773A7250723E295B5C5C735C5C535D292A3C2F773A7250723E293F3C773A7420786D';
wwv_flow_imp.g_varchar2_table(747) := '6C3A73706163653D227072657365727665223EE29FA64E52463A285C5C642B29E29FA73C2F773A743E3C2F773A723E272C226722292C6C3D6E5B305D2E7265706C61636528612C66756E6374696F6E28652C722C6E297B72657475726E206F2B2B2C6675';
wwv_flow_imp.g_varchar2_table(748) := '6E6374696F6E28652C742C72297B766172206E3D273C773A616C69617320773A76616C3D22272B547428652E6C6162656C7C7C652E6E616D65292B27222F3E3C773A74616720773A76616C3D22272B547428652E6E616D65292B27222F3E3C773A696420';
wwv_flow_imp.g_varchar2_table(749) := '773A76616C3D22272B742B27222F3E272B28652E726561644F6E6C793F273C773A6C6F636B20773A76616C3D22736474436F6E74656E744C6F636B6564222F3E273A2222293B69662822636865636B626F78223D3D3D652E696E707574297B766172206F';
wwv_flow_imp.g_varchar2_table(750) := '3D722E7265706C616365282F3C773A72466F6E74735B5E3E5D2A5C2F3E2F2C2222292E7265706C61636528223C773A7250723E222C273C773A7250723E3C773A72466F6E747320773A61736369693D224D5320476F746869632220773A65617374417369';
wwv_flow_imp.g_varchar2_table(751) := '613D224D5320476F746869632220773A68416E73693D224D5320476F746869632220773A63733D224D5320476F74686963222F3E27293B72657475726E223C773A7364743E3C773A73647450723E222B6F2B6E2B273C7731343A636865636B626F783E3C';
wwv_flow_imp.g_varchar2_table(752) := '7731343A636865636B6564207731343A76616C3D22272B28652E636865636B65643F313A30292B27222F3E3C7731343A636865636B65645374617465207731343A76616C3D223236313222207731343A666F6E743D224D5320476F74686963222F3E3C77';
wwv_flow_imp.g_varchar2_table(753) := '31343A756E636865636B65645374617465207731343A76616C3D223236313022207731343A666F6E743D224D5320476F74686963222F3E3C2F7731343A636865636B626F783E3C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E27';
wwv_flow_imp.g_varchar2_table(754) := '2B6F2B223C773A743E222B28652E636865636B65643F6C653A6965292B223C2F773A743E3C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D76617220613D21652E76616C75652C6C3D652E76616C75657C7C652E706C616365';
wwv_flow_imp.g_varchar2_table(755) := '686F6C6465727C7C28226C697374223D3D3D652E696E7075743F22456C696A6120756E20656C656D656E746F2E223A6E65772041727261792839292E6A6F696E2822E280822229293B72657475726E223C773A7364743E3C773A73647450723E222B722B';
wwv_flow_imp.g_varchar2_table(756) := '6E2B28613F223C773A73686F77696E67506C634864722F3E223A2222292B28226C697374223D3D3D652E696E7075743F223C773A64726F70446F776E4C6973743E222B652E6F7074696F6E732E6D61702866756E6374696F6E2865297B72657475726E27';
wwv_flow_imp.g_varchar2_table(757) := '3C773A6C6973744974656D20773A646973706C6179546578743D22272B54742865292B272220773A76616C75653D22272B54742865292B27222F3E277D292E6A6F696E282222292B223C2F773A64726F70446F776E4C6973743E223A223C773A74657874';
wwv_flow_imp.g_varchar2_table(758) := '222B28226D756C74696C696E65223D3D3D652E696E7075743F2720773A6D756C74694C696E653D223122273A2222292B222F3E22292B223C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E222B722B537472696E67286C292E7370';
wwv_flow_imp.g_varchar2_table(759) := '6C6974282F5C723F5C6E2F292E6D61702866756E6374696F6E2865297B72657475726E273C773A7420786D6C3A73706163653D227072657365727665223E272B54742865292B223C2F773A743E227D292E6A6F696E28223C773A62722F3E22292B223C2F';
wwv_flow_imp.g_varchar2_table(760) := '773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D28745B2B6E5D2C3165332B4E756D626572286E292C727C7C223C773A7250723E3C2F773A7250723E22297D293B6966286F213D3D742E6C656E677468297468726F77206E657720';
wwv_flow_imp.g_varchar2_table(761) := '4572726F722822576F72643A206E6F207365207075646965726F6E20636F6C6F63617220746F646F73206C6F732063616D706F732064656C20666F726D756C6172696F2028222B6F2B2220646520222B742E6C656E6774682B22292E22293B7265747572';
wwv_flow_imp.g_varchar2_table(762) := '6E20652E66696C652822776F72642F646F63756D656E742E786D6C222C6C292C652E66696C652822776F72642F73657474696E67732E786D6C222C4374286E5B315D2C7229292C652E67656E65726174654173796E63287B747970653A22617272617962';
wwv_flow_imp.g_varchar2_table(763) := '7566666572222C636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D297D297D297D66756E6374696F6E207A7428652C742C72297B766172206E3D77696E646F772E646F6378';
wwv_flow_imp.g_varchar2_table(764) := '2C6F3D56652865292C613D652E706167657C7C7B7D2C6C3D5B5D2C733D756528292C753D78745B612E73697A657C7C226C6574746572225D7C7C78742E6C65747465722C633D226C616E647363617065223D3D3D612E6F7269656E746174696F6E2C663D';
wwv_flow_imp.g_varchar2_table(765) := '4D6174682E726F756E642835362E372A28612E6D617267696E7C7C31322E3729292C643D28633F755B315D3A755B305D292D322A662C683D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A2246464646';
wwv_flow_imp.g_varchar2_table(766) := '4646227D2C703D7B746F703A682C626F74746F6D3A682C6C6566743A682C72696768743A682C696E73696465486F72697A6F6E74616C3A682C696E73696465566572746963616C3A687D2C673D7B7374796C653A6E2E426F726465725374796C652E5349';
wwv_flow_imp.g_varchar2_table(767) := '4E474C452C73697A653A322C636F6C6F723A22424643394434227D2C6D3D7B746F703A672C626F74746F6D3A672C6C6566743A672C72696768743A672C696E73696465486F72697A6F6E74616C3A672C696E73696465566572746963616C3A677D3B6675';
wwv_flow_imp.g_varchar2_table(768) := '6E6374696F6E20762865297B69662821652972657475726E206D3B76617220743D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A692865297D3B72657475726E7B746F703A742C626F74746F6D3A';
wwv_flow_imp.g_varchar2_table(769) := '742C6C6566743A742C72696768743A742C696E73696465486F72697A6F6E74616C3A742C696E73696465566572746963616C3A747D7D76617220623D4D6174682E726F756E6428322A286F2E666F6E7453697A657C7C3729293B66756E6374696F6E2077';
wwv_flow_imp.g_varchar2_table(770) := '28652C74297B72657475726E20743D747C7C7B7D2C6E6577206E2E5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C73697A653A';
wwv_flow_imp.g_varchar2_table(771) := '742E73697A657C7C622C636F6C6F723A742E636F6C6F723F6928742E636F6C6F72293A766F696420302C666F6E743A742E666F6E747C7C2243616C69627269227D297D66756E6374696F6E207928652C74297B72657475726E20743D747C7C7B7D2C6E65';
wwv_flow_imp.g_varchar2_table(772) := '77206E2E506172616772617068287B6368696C6472656E3A5B7728652C74295D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A227269676874223D3D3D742E616C69676E3F6E2E416C69676E6D656E7454';
wwv_flow_imp.g_varchar2_table(773) := '7970652E52494748543A2263656E746572223D3D3D742E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546547D297D66756E6374696F6E207828652C74297B76617220723D766F69';
wwv_flow_imp.g_varchar2_table(774) := '642030213D3D28743D747C7C7B7D292E7061643F742E7061643A33303B72657475726E206E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B7928652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B746F';
wwv_flow_imp.g_varchar2_table(775) := '703A722C626F74746F6D3A722C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A742E6D6964646C657C7C226D6964646C65223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E43454E5445523A2262';
wwv_flow_imp.g_varchar2_table(776) := '6F74746F6D223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E424F54544F4D3A22746F70223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E544F503A766F696420302C73686164696E673A742E66696C6C3F';
wwv_flow_imp.g_varchar2_table(777) := '7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928742E66696C6C297D3A766F696420307D297D66756E6374696F6E204528297B72657475726E206E6577206E2E50617261677261706828';
wwv_flow_imp.g_varchar2_table(778) := '7B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D66756E6374696F6E204E28652C742C72297B72657475726E206E6577206E2E506172616772617068287B6368696C6472656E3A5B7728652C';
wwv_flow_imp.g_varchar2_table(779) := '7B626F6C643A742E626F6C642C73697A653A742E73697A653F4D6174682E726F756E6428322A742E73697A65293A31342C636F6C6F723A742E636F6C6F727D295D2C73706163696E673A7B6265666F72653A302C61667465723A32307D2C616C69676E6D';
wwv_flow_imp.g_varchar2_table(780) := '656E743A227269676874223D3D3D723F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D723F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C7368616469';
wwv_flow_imp.g_varchar2_table(781) := '6E673A742E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928742E66696C6C297D3A766F696420307D297D66756E6374696F6E206A28652C742C722C6F2C61297B72657475';
wwv_flow_imp.g_varchar2_table(782) := '726E206E6577206E2E506172616772617068287B616C69676E6D656E743A227269676874223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74';
wwv_flow_imp.g_varchar2_table(783) := '547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C73706163696E673A7B61667465723A766F69642030213D3D613F613A4D6174682E726F756E642835362E372A28766F69642030213D3D6F2E6761703F6F2E6761703A33';
wwv_flow_imp.g_varchar2_table(784) := '29297D2C6368696C6472656E3A5B6E6577206E2E496D61676552756E287B747970653A226A7067223D3D3D652E6578743F226A7067223A22706E67222C646174613A652E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E72';
wwv_flow_imp.g_varchar2_table(785) := '6F756E6428332E37382A74292C6865696768743A4D6174682E726F756E6428332E37382A72297D7D295D7D297D76617220523D28633F755B315D3A755B305D292F35362E372C493D28633F755B305D3A755B315D292F35362E373B66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(786) := '422874297B76617220722C6F3D707428652C74293B696628216F2972657475726E206E756C6C3B7472797B723D66756E6374696F6E28652C742C72297B766172206E3D372E35362C6F3D6E74284D6174682E726F756E6428742A6E292C4D6174682E726F';
wwv_flow_imp.g_varchar2_table(787) := '756E6428722A6E29292C613D6F2E676574436F6E746578742822326422292C6C3D2248656C7665746963612C20417269616C2C2073616E732D7365726966223B612E666F6E743D22626F6C64203236362E37313638707820222B6C3B76617220693D6774';
wwv_flow_imp.g_varchar2_table(788) := '28652C612E6D6561737572655465787428652E74657874292E77696474682F6E2C742C72293B612E666F6E743D22626F6C6420222B2E333532382A692A6E2B22707820222B6C2C612E7472616E736C617465286F2E77696474682F322C6F2E6865696768';
wwv_flow_imp.g_varchar2_table(789) := '742F32292C612E726F74617465282D652E616E676C652A4D6174682E50492F313830292C612E676C6F62616C416C7068613D652E6F7061636974792C612E66696C6C5374796C653D652E636F6C6F722C612E74657874416C69676E3D2263656E74657222';
wwv_flow_imp.g_varchar2_table(790) := '2C612E74657874426173656C696E653D226D6964646C65222C612E66696C6C5465787428652E746578742C302C30293B76617220733D7274286F2E746F4461746155524C2822696D6167652F706E6722292C6F2E77696474682C6F2E686569676874293B';
wwv_flow_imp.g_varchar2_table(791) := '72657475726E20732E776D6D3D742C732E686D6D3D722C737D286F2C522C49297D63617463682865297B72657475726E206E756C6C7D72657475726E206E6577206E2E486561646572287B6368696C6472656E3A5B6E6577206E2E506172616772617068';
wwv_flow_imp.g_varchar2_table(792) := '287B6368696C6472656E3A5B6E6577206E2E496D61676552756E287B747970653A22706E67222C646174613A722E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A52292C6865696768743A4D61';
wwv_flow_imp.g_varchar2_table(793) := '74682E726F756E6428332E37382A49297D2C666C6F6174696E673A7B686F72697A6F6E74616C506F736974696F6E3A7B72656C61746976653A6E2E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E';
wwv_flow_imp.g_varchar2_table(794) := '3A6E2E486F72697A6F6E74616C506F736974696F6E416C69676E2E43454E5445527D2C766572746963616C506F736974696F6E3A7B72656C61746976653A6E2E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C';
wwv_flow_imp.g_varchar2_table(795) := '69676E3A6E2E566572746963616C506F736974696F6E416C69676E2E43454E5445527D2C626568696E64446F63756D656E743A21302C616C6C6F774F7665726C61703A21302C777261703A7B747970653A6E2E546578745772617070696E67547970652E';
wwv_flow_imp.g_varchar2_table(796) := '4E4F4E457D7D7D295D7D295D7D297D76617220473D742E6D61702866756E6374696F6E28722C61297B76617220683D5B5D2C673D742E6C656E6774683E313F225F222B28612B31293A22223B446528652C22646F6378222C72292E666F72456163682866';
wwv_flow_imp.g_varchar2_table(797) := '756E6374696F6E20742861297B76617220753D612E747970653B69662822636F6C756D6E6173223D3D3D75297B76617220633D5F6528612C22646F6378222C722C642F35362E37293B69662821632E6C656E6774682972657475726E3B76617220663D68';
wwv_flow_imp.g_varchar2_table(798) := '2C6D3D642C523D4D6174682E726F756E642835362E372A28766F69642030213D3D612E636F6C4761703F4E756D62657228612E636F6C476170293A3429292C493D5B5D2C423D5B5D3B72657475726E20632E666F72456163682866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(799) := '2C72297B766172206F3D723D3D3D632E6C656E6774682D312C613D4D6174682E726F756E642835362E372A652E77293B683D5B5D2C643D612C652E736563732E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774682D315D696E';
wwv_flow_imp.g_varchar2_table(800) := '7374616E63656F66206E2E5061726167726170687C7C682E70757368287928222229292C492E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A682C77696474683A7B73697A653A612B286F3F303A52292C747970653A6E2E';
wwv_flow_imp.g_varchar2_table(801) := '5769647468547970652E4458417D2C6D617267696E733A7B746F703A302C626F74746F6D3A302C6C6566743A302C72696768743A6F3F303A527D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E544F507D29292C422E7075';
wwv_flow_imp.g_varchar2_table(802) := '736828612B286F3F303A5229297D292C643D6D2C766F696428683D66292E70757368286E6577206E2E5461626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A497D295D2C776964';
wwv_flow_imp.g_varchar2_table(803) := '74683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A422C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C452829297D69662822';
wwv_flow_imp.g_varchar2_table(804) := '677275706F223D3D3D75297B76617220473D722C573D672C5F3D682C483D642C593D4D6174682E726F756E642835362E372A28766F69642030213D3D612E70616464696E673F4E756D62657228612E70616464696E67293A612E626F726465727C7C612E';
wwv_flow_imp.g_varchar2_table(805) := '66696C6C3F333A3029292C243D612E626F726465723F7628612E626F72646572436F6C6F727C7C7965293A703B72657475726E20576528612C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C673D572B652E7375663B7661';
wwv_flow_imp.g_varchar2_table(806) := '72206C3D476528612C22646F6378222C72293B6966286C2E6C656E6774687C7C612E7469746C65297B683D5B5D2C643D4D6174682E6D6178283630302C482D322A59292C6C2E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774';
wwv_flow_imp.g_varchar2_table(807) := '682D315D696E7374616E63656F66206E2E5061726167726170687C7C682E70757368287928222229293B76617220733D5B5D3B612E7469746C652626732E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C';
wwv_flow_imp.g_varchar2_table(808) := '6472656E3A5B78285328612E7469746C652C72292C7B626F6C643A21302C73697A653A4D6174682E726F756E6428322A28612E7469746C6553697A657C7C286F2E666F6E7453697A657C7C37292B3229292C636F6C6F723A612E7469746C65436F6C6F72';
wwv_flow_imp.g_varchar2_table(809) := '7C7C6F2E68656164546578742C66696C6C3A612E7469746C6546696C6C7C7C6F2E7072696D6172792C7061643A36307D295D7D29292C732E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A2131213D3D612E6B656570546F';
wwv_flow_imp.g_varchar2_table(810) := '6765746865722C6368696C6472656E3A5B6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A682C6D617267696E733A7B746F703A592C626F74746F6D3A592C6C6566743A592C72696768743A597D2C73686164696E673A612E66696C6C3F';
wwv_flow_imp.g_varchar2_table(811) := '7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928612E66696C6C297D3A766F696420307D295D7D29292C643D482C28683D5F292E70757368286E6577206E2E5461626C65287B726F7773';
wwv_flow_imp.g_varchar2_table(812) := '3A732C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A242C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C45';
wwv_flow_imp.g_varchar2_table(813) := '2829297D7D292C683D5F2C643D482C723D472C766F696428673D57297D69662822686561646572223D3D3D75297B76617220713D526528612C6F292C583D612E666F6E743F712E666F6E745B315D3A766F696420302C4B3D5B6E6577206E2E5461626C65';
wwv_flow_imp.g_varchar2_table(814) := '526F77287B6368696C6472656E3A5B78285328612E7469746C652C72292C7B626F6C643A21302C73697A653A4D6174682E726F756E6428322A712E73697A65292C636F6C6F723A712E636F6C6F722C66696C6C3A712E66696C6C2C666F6E743A587D292C';
wwv_flow_imp.g_varchar2_table(815) := '78285328612E72696768742C72292C7B73697A653A4D6174682E726F756E6428322A712E726967687453697A65292C636F6C6F723A712E636F6C6F722C66696C6C3A712E66696C6C2C616C69676E3A227269676874222C666F6E743A582C6D6964646C65';
wwv_flow_imp.g_varchar2_table(816) := '3A2121612E726967687453697A657D295D7D295D3B612E7375627469746C6526264B2E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78285328612E7375627469746C652C72292C7B73697A653A4D6174682E726F756E64';
wwv_flow_imp.g_varchar2_table(817) := '28322A712E73756253697A65292C636F6C6F723A712E636F6C6F722C66696C6C3A712E66696C6C2C7370616E3A322C666F6E743A587D295D7D29292C682E70757368286E6577206E2E5461626C65287B726F77733A4B2C77696474683A7B73697A653A64';
wwv_flow_imp.g_varchar2_table(818) := '2C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B4D6174682E726F756E64282E372A64292C4D6174682E726F756E64282E332A64295D2C626F72646572733A707D292C452829297D656C736520696628227465';
wwv_flow_imp.g_varchar2_table(819) := '78746F223D3D3D75297B766172206E653D7B72696768743A6E2E416C69676E6D656E74547970652E52494748542C63656E7465723A6E2E416C69676E6D656E74547970652E43454E5445522C6A7573746966793A6E2E416C69676E6D656E74547970652E';
wwv_flow_imp.g_varchar2_table(820) := '4A55535449464945447D3B5028612C72292E666F72456163682866756E6374696F6E2874297B682E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A6E655B612E616C69676E5D7C7C6E2E416C69676E6D656E7454797065';
wwv_flow_imp.g_varchar2_table(821) := '2E4C4546542C696E64656E743A612E696E64656E743F7B6C6566743A4D6174682E726F756E642835362E372A612E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A766F69642030213D3D612E706172616772617068476170';
wwv_flow_imp.g_varchar2_table(822) := '3F4D6174682E726F756E642835362E372A612E706172616772617068476170293A3132302C6C696E653A4D6174682E726F756E64283234302A28612E6C696E654865696768747C7C312E313529297D2C6368696C6472656E3A4628742C7B666F6E743A61';
wwv_flow_imp.g_varchar2_table(823) := '2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A612E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E206E6577206E2E5465787452756E287B746578743A652E742C626F6C643A212821652E';
wwv_flow_imp.g_varchar2_table(824) := '62262621612E626F6C64292C6974616C6963733A212821652E69262621612E6974616C6963292C73697A653A322A28612E73697A657C7C3130292C756E6465726C696E653A652E753F7B7D3A766F696420302C737472696B653A2121652E732C636F6C6F';
wwv_flow_imp.g_varchar2_table(825) := '723A652E633F6928652E63293A766F696420302C666F6E743A4D5B652E665D5B315D7D297D297D29297D297D656C736520696628226573706163696F223D3D3D7529682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B';
wwv_flow_imp.g_varchar2_table(826) := '5D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28612E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D75297B696628766F696420303D3D3D612E7831297B766172206C653D4D61';
wwv_flow_imp.g_varchar2_table(827) := '74682E726F756E642835362E372A28612E77696474687C7C3029292C69653D6C653F4D6174682E6D617828302C4D6174682E726F756E642828642D6C65292F3229293A303B682E70757368286E6577206E2E506172616772617068287B6368696C647265';
wwv_flow_imp.g_varchar2_table(828) := '6E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3229297D2C696E64656E743A2263656E746572223D3D3D612E616C69676E3F7B6C6566743A69652C7269';
wwv_flow_imp.g_varchar2_table(829) := '6768743A69657D3A227269676874223D3D3D612E616C69676E3F7B6C6566743A322A69657D3A7B72696768743A322A69657D2C626F726465723A7B626F74746F6D3A7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A4D';
wwv_flow_imp.g_varchar2_table(830) := '6174682E6D617828322C4D6174682E726F756E642832302A28612E746869636B6E6573737C7C2E332929292C636F6C6F723A6928612E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C73652069662822696D616765';
wwv_flow_imp.g_varchar2_table(831) := '6E223D3D3D75297B7661722073653D516528612C72293B6966287365297B7661722075653D657428612C7365293B682E70757368286A2873652C75652E772C75652E682C6129297D7D656C736520696628226772616669636F223D3D3D75297B76617220';
wwv_flow_imp.g_varchar2_table(832) := '66653D687428612C722C6F293B66652626682E70757368286A2866652C66652E776D6D2C66652E686D6D2C6129297D656C73652069662822636F6469676F223D3D3D75297B7661722064653D637428612C72293B6966286465297B7661722068653D6674';
wwv_flow_imp.g_varchar2_table(833) := '286465293B682E70757368286A2868652C68652E776D6D2C68652E686D6D2C612C64652E6C6162656C3F303A766F6964203029292C64652E6C6162656C2626682E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A227269';
wwv_flow_imp.g_varchar2_table(834) := '676874223D3D3D612E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D612E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C';
wwv_flow_imp.g_varchar2_table(835) := '696E64656E743A227269676874223D3D3D612E616C69676E7C7C2263656E746572223D3D3D612E616C69676E3F766F696420303A7B6C6566743A4D6174682E6D617828302C4D6174682E726F756E64282868652E776D6D2D64652E746578742E6C656E67';
wwv_flow_imp.g_varchar2_table(836) := '74682A64652E7465787453697A652A2E333532382A2E36292F322A35362E3729297D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3329297D2C6368696C647265';
wwv_flow_imp.g_varchar2_table(837) := '6E3A5B6E6577206E2E5465787452756E287B746578743A64652E746578742C666F6E743A22436F7572696572204E6577222C73697A653A322A64652E7465787453697A652C636F6C6F723A692864652E636F6C6F72297D295D7D29297D7D656C73652069';
wwv_flow_imp.g_varchar2_table(838) := '66282273616C746F223D3D3D7529682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B6E6577206E2E50616765427265616B5D7D29293B656C736520696628226669636861223D3D3D75297B7661722070653D4328612C';
wwv_flow_imp.g_varchar2_table(839) := '72295B305D7C7C7B7D2C67653D612E636F6C756D6E737C7C332C6D653D5B5D2C76653D5B5D3B69662845652828612E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5428652E776865';
wwv_flow_imp.g_varchar2_table(840) := '6E2C722C7065297D292C6765292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E6374696F6E2865297B76617220743D652E662C6F3D2121612E677269642C6C3D6F3F36303A766F696420303B696628652E656D7074';
wwv_flow_imp.g_varchar2_table(841) := '79297B76617220733D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D3B76652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E50';
wwv_flow_imp.g_varchar2_table(842) := '6172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A322A652E7370616E2C626F72646572733A6F3F7B746F703A732C626F74746F6D3A732C6C6566743A732C72696768743A737D3A766F696420307D29297D656C73';
wwv_flow_imp.g_varchar2_table(843) := '657B76617220752C633D4D6528742C61292C663D5328742E6C6162656C2C722C7065293B696628226C65667422213D3D632E706F73297B76617220643D416528742C722C7065292C683D5B5D2C703D6F3F36303A33303B72657475726E22746F70223D3D';
wwv_flow_imp.g_varchar2_table(844) := '3D632E706F732626682E70757368284E28466528662C63292C632C632E616C69676E7C7C642626642E616C69676E7C7C226C6566742229292C682E70757368287928726528742C722C7065292C7B73697A653A31372C636F6C6F723A642626642E636F6C';
wwv_flow_imp.g_varchar2_table(845) := '6F727C7C612E76616C7565436F6C6F722C626F6C643A643F642E626F6C643A766F696420302C616C69676E3A643F642E616C69676E3A766F696420307D29292C766F69642076652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472';
wwv_flow_imp.g_varchar2_table(846) := '656E3A682C636F6C756D6E5370616E3A322A652E7370616E2C6D617267696E733A7B746F703A702C626F74746F6D3A702C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A6F3F6E2E566572746963616C416C69676E2E43';
wwv_flow_imp.g_varchar2_table(847) := '454E5445523A766F696420302C73686164696E673A642626642E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928642E66696C6C297D3A766F696420307D29297D76652E70';
wwv_flow_imp.g_varchar2_table(848) := '757368287828466528662C63292C632E7374796C65643F7B626F6C643A632E626F6C642C73697A653A632E73697A653F4D6174682E726F756E6428322A632E73697A65293A31372C66696C6C3A632E66696C6C2C636F6C6F723A632E636F6C6F722C616C';
wwv_flow_imp.g_varchar2_table(849) := '69676E3A632E616C69676E2C7061643A6C2C6D6964646C653A6F7D3A7B626F6C643A21302C73697A653A31372C66696C6C3A612E6C6162656C46696C6C2C636F6C6F723A612E6C6162656C436F6C6F722C7061643A6C2C6D6964646C653A6F7D292C2875';
wwv_flow_imp.g_varchar2_table(850) := '3D416528742C722C7065292C7828726528742C722C7065292C7B73697A653A31372C636F6C6F723A752626752E636F6C6F727C7C612E76616C7565436F6C6F722C7061643A6C2C6D6964646C653A6F2C626F6C643A753F752E626F6C643A766F69642030';
wwv_flow_imp.g_varchar2_table(851) := '2C616C69676E3A753F752E616C69676E3A766F696420302C66696C6C3A753F752E66696C6C3A766F696420302C7370616E3A652E7370616E3E313F322A652E7370616E2D313A766F696420307D2929297D7D293B666F722876617220743D322A43652865';
wwv_flow_imp.g_varchar2_table(852) := '293B743C322A67653B742B2B2976652E70757368287828222229293B6D652E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A76657D29292C76653D5B5D7D292C6D652E6C656E677468297B7661722062653D5B5D3B69662861';
wwv_flow_imp.g_varchar2_table(853) := '2E677269647C7C41727261792E6973417272617928612E6C6162656C57696474687329297B666F72287661722077653D5B5D2C54653D302C7A653D303B7A653C67653B7A652B2B2977652E70757368284D6174682E726F756E642835362E372A78652861';
wwv_flow_imp.g_varchar2_table(854) := '2C7A652929292C54652B3D77655B7A655D3B766172204E653D4D6174682E6D6178283630302C4D6174682E726F756E642828642D5465292F676529293B666F72287A653D303B7A653C67653B7A652B2B2962652E707573682877655B7A655D2C4E65297D';
wwv_flow_imp.g_varchar2_table(855) := '656C736520666F72287661722050653D303B50653C322A67653B50652B2B2962652E70757368284D6174682E726F756E6428642F28322A67652929293B682E70757368286E6577206E2E5461626C65287B726F77733A6D652C77696474683A7B73697A65';
wwv_flow_imp.g_varchar2_table(856) := '3A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A62652C626F72646572733A612E677269643F7628612E626F72646572436F6C6F727C7C7965293A702C6C61796F75743A612E677269643F6E2E5461626C65';
wwv_flow_imp.g_varchar2_table(857) := '4C61796F7574547970652E46495845443A766F696420307D292C452829297D7D656C736520696628227461726A65746173223D3D3D75297B766172206B653D496528612C722C6F293B696628216B652E6974656D732E6C656E6774682972657475726E3B';
wwv_flow_imp.g_varchar2_table(858) := '666F7228766172204F653D4D6174682E726F756E642835362E372A6B652E63617264476170292C6A653D4D6174682E666C6F6F722828642D4F652A286B652E6E2D3129292F6B652E6E292C4C653D5B5D2C44653D5B5D2C55653D303B55653C6B652E6E3B';
wwv_flow_imp.g_varchar2_table(859) := '55652B2B295565262644652E70757368284F65292C44652E70757368286A65293B666F72287661722042653D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C48653D303B4865';
wwv_flow_imp.g_varchar2_table(860) := '3C6B652E6974656D732E6C656E6774683B48652B3D6B652E6E297B666F72287661722056653D5B5D2C59653D303B59653C6B652E6E3B59652B2B297B7661722024653D6B652E6974656D735B48652B59655D3B5965262656652E70757368286E6577206E';
wwv_flow_imp.g_varchar2_table(861) := '2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F72646572733A7B746F703A42652C626F74746F6D3A42652C6C6566743A42652C72696768743A42657D7D29292C24653F56652E70757368286E6577206E2E5461626C654365';
wwv_flow_imp.g_varchar2_table(862) := '6C6C287B6368696C6472656E3A5B792824652E6C6162656C2C7B73697A653A322A6B652E6C6162656C53697A652C636F6C6F723A6B652E6C6162656C436F6C6F727D292C6E6577206E2E506172616772617068287B6368696C6472656E3A5B772824652E';
wwv_flow_imp.g_varchar2_table(863) := '76616C75652C7B626F6C643A21302C73697A653A322A6B652E73697A652C636F6C6F723A24652E636F6C6F727C7C6B652E76616C7565436F6C6F727D295D2C73706163696E673A7B6265666F72653A34302C61667465723A307D7D295D2C6D617267696E';
wwv_flow_imp.g_varchar2_table(864) := '733A7B746F703A3130302C626F74746F6D3A3130302C6C6566743A3136302C72696768743A3130307D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E43454E5445522C73686164696E673A7B747970653A6E2E5368616469';
wwv_flow_imp.g_varchar2_table(865) := '6E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A69286B652E66696C6C297D2C626F72646572733A7B746F703A42652C626F74746F6D3A42652C72696768743A42652C6C6566743A6B652E616363656E743F7B7374796C653A';
wwv_flow_imp.g_varchar2_table(866) := '6E2E426F726465725374796C652E53494E474C452C73697A653A32342C636F6C6F723A69286B652E616363656E74297D3A42657D7D29293A56652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F';
wwv_flow_imp.g_varchar2_table(867) := '72646572733A7B746F703A42652C626F74746F6D3A42652C6C6566743A42652C72696768743A42657D7D29297D4C652E6C656E67746826264C652E70757368286E6577206E2E5461626C65526F77287B6865696768743A7B76616C75653A4F652C72756C';
wwv_flow_imp.g_varchar2_table(868) := '653A6E2E48656967687452756C652E45584143547D2C6368696C6472656E3A44652E6D61702866756E6374696F6E28297B72657475726E206E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F72646572733A7B74';
wwv_flow_imp.g_varchar2_table(869) := '6F703A42652C626F74746F6D3A42652C6C6566743A42652C72696768743A42657D7D297D297D29292C4C652E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A56657D29297D682E7075736828';
wwv_flow_imp.g_varchar2_table(870) := '6E6577206E2E5461626C65287B726F77733A4C652C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A44652C626F72646572733A702C6C61796F75743A6E2E5461626C654C6179';
wwv_flow_imp.g_varchar2_table(871) := '6F7574547970652E46495845447D292C452829297D656C73652069662822666F726D756C6172696F223D3D3D75297B7661722071653D612E636F6C756D6E737C7C322C58653D5B5D2C5A653D5B5D2C4A653D312C4B653D636528612C722C67292C74743D';
wwv_flow_imp.g_varchar2_table(872) := '7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A342C636F6C6F723A69286165297D3B6966284565284B652C7165292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(873) := '65297B76617220743D652E663B696628652E656D707479295A652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E537061';
wwv_flow_imp.g_varchar2_table(874) := '6E3A322A652E7370616E7D29293B656C73657B7328742E6E616D65293B76617220723D6C2E6C656E6774683B6C2E707573682874292C4A653D4D6174682E6D6178284A652C742E6C696E6573293B766172206F3D742E6C696E65733E313F6E2E56657274';
wwv_flow_imp.g_varchar2_table(875) := '6963616C416C69676E2E544F503A6E2E566572746963616C416C69676E2E43454E5445522C613D742E6C61623B696628226C65667422213D3D612E706F73297B76617220753D6E6577206E2E5461626C65287B77696474683A7B73697A653A3130302C74';
wwv_flow_imp.g_varchar2_table(876) := '7970653A6E2E5769647468547970652E50455243454E544147457D2C626F72646572733A702C726F77733A5B6E6577206E2E5461626C65526F77287B6865696768743A742E6C696E65733E313F7B76616C75653A4D6174682E726F756E64283233302A74';
wwv_flow_imp.g_varchar2_table(877) := '2E6C696E65732B3630292C72756C653A6E2E48656967687452756C652E41544C454153547D3A766F696420302C6368696C6472656E3A5B6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B63';
wwv_flow_imp.g_varchar2_table(878) := '68696C6472656E3A5B772845742B722B22E29FA7222C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C766572746963616C416C69676E3A6F2C6D617267696E733A7B746F703A34302C626F7474';
wwv_flow_imp.g_varchar2_table(879) := '6F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A74742C626F74746F6D3A74742C6C6566743A74742C72696768743A74747D2C73686164696E673A7B747970653A6E2E53686164696E67547970652E434C4541';
wwv_flow_imp.g_varchar2_table(880) := '522C636F6C6F723A226175746F222C66696C6C3A69286F65297D7D295D7D295D7D292C633D22746F70223D3D3D612E706F733F5B4E28466528742E6C6162656C2C61292C612C612E616C69676E7C7C226C65667422295D3A5B5D3B72657475726E20632E';
wwv_flow_imp.g_varchar2_table(881) := '7075736828752C6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A302C61667465723A302C6C696E653A3132302C6C696E6552756C653A6E2E4C696E6552756C65547970652E4558414354';
wwv_flow_imp.g_varchar2_table(882) := '7D7D29292C766F6964205A652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A632C636F6C756D6E5370616E3A322A652E7370616E2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E544F502C';
wwv_flow_imp.g_varchar2_table(883) := '6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D29297D5A652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B612E7374796C65643F7928466528742E6C61';
wwv_flow_imp.g_varchar2_table(884) := '62656C2C61292C7B626F6C643A612E626F6C642C73697A653A612E73697A653F4D6174682E726F756E6428322A612E73697A65293A31372C636F6C6F723A612E636F6C6F722C616C69676E3A612E616C69676E7D293A7928742E6C6162656C2C7B626F6C';
wwv_flow_imp.g_varchar2_table(885) := '643A21302C73697A653A31377D295D2C766572746963616C416C69676E3A6F2C73686164696E673A612E7374796C65642626612E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C';
wwv_flow_imp.g_varchar2_table(886) := '3A6928612E66696C6C297D3A766F696420302C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D292C6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E5061';
wwv_flow_imp.g_varchar2_table(887) := '72616772617068287B6368696C6472656E3A5B772845742B722B22E29FA7222C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C636F6C756D6E5370616E3A652E7370616E3E313F322A652E7370';
wwv_flow_imp.g_varchar2_table(888) := '616E2D313A766F696420302C766572746963616C416C69676E3A6F2C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A74742C626F74746F6D3A74742C6C65';
wwv_flow_imp.g_varchar2_table(889) := '66743A74742C72696768743A74747D2C73686164696E673A7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A69286F65297D7D29297D7D293B666F722876617220743D322A43652865293B74';
wwv_flow_imp.g_varchar2_table(890) := '3C322A71653B742B2B295A652E70757368287828222229293B58652E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A5A652C63616E7453706C69743A21302C6865696768743A4A653E313F7B76616C75653A4D6174682E726F';
wwv_flow_imp.g_varchar2_table(891) := '756E64283233302A4A652B313230292C72756C653A6E2E48656967687452756C652E41544C454153547D3A766F696420307D29292C5A653D5B5D2C4A653D317D292C58652E6C656E677468297B7661722072743D5B5D2C6E743D4D6174682E726F756E64';
wwv_flow_imp.g_varchar2_table(892) := '2835362E372A28612E6C6162656C57696474687C7C333229292C6F743D4D6174682E6D6178283630302C4D6174682E726F756E642828642D6E742A7165292F716529293B6E742A71652B3630302A71653E642626286E743D6F743D4D6174682E726F756E';
wwv_flow_imp.g_varchar2_table(893) := '6428642F28322A71652929293B666F72287661722061743D303B61743C71653B61742B2B2972742E70757368286E742C6F74293B682E70757368286E6577206E2E5461626C65287B726F77733A58652C77696474683A7B73697A653A642C747970653A6E';
wwv_flow_imp.g_varchar2_table(894) := '2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A72742C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C452829297D7D656C73652069662822616C65727461223D3D3D';
wwv_flow_imp.g_varchar2_table(895) := '75294328612C72292E66696C7465722866756E6374696F6E2865297B72657475726E205428612E7768656E2C722C65297D292E736C69636528302C612E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B682E7075736828';
wwv_flow_imp.g_varchar2_table(896) := '6E6577206E2E5461626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78285328612E746578742C722C65292C7B626F6C643A21302C73697A653A31372C66696C6C3A4128612E636F6C6F722C722C65297C7C22';
wwv_flow_imp.g_varchar2_table(897) := '23453645434632227D295D7D295D2C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A707D292C452829297D293B656C736520696628227461626C';
wwv_flow_imp.g_varchar2_table(898) := '61223D3D3D75297B766172206C743D4328612C72293B696628216C742E6C656E67746826262131213D3D612E68696465456D707479262621612E656D707479546578742972657475726E3B7661722069743D6B28612C722C6C74292C73743D5B5D3B612E';
wwv_flow_imp.g_varchar2_table(899) := '7469746C65262673742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A5B78285328612E7469746C652C72292C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C';
wwv_flow_imp.g_varchar2_table(900) := '6C3A6F2E7072696D6172792C7370616E3A69742E6C656E6774682C73697A653A622B327D295D7D29292C612E67726F757073262673742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A';
wwv_flow_imp.g_varchar2_table(901) := '4F28612C6974292E6D61702866756E6374696F6E2865297B72657475726E207828652E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A2263656E74657222';
wwv_flow_imp.g_varchar2_table(902) := '2C7370616E3A652E636F6C737D297D297D29292C73742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A69742E6D61702866756E6374696F6E2865297B72657475726E207828652E6C61';
wwv_flow_imp.g_varchar2_table(903) := '62656C2C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A536528652C61297D297D297D29292C6C742E6C656E6774687C7C73742E70757368286E6577206E2E5461626C65526F7728';
wwv_flow_imp.g_varchar2_table(904) := '7B6368696C6472656E3A5B78285328612E656D707479546578742C72292C7B6974616C69633A21302C7370616E3A69742E6C656E6774687D295D7D29293B7661722075743D512861292C64743D7B7D2C70743D4428612C6974292C67743D66756E637469';
wwv_flow_imp.g_varchar2_table(905) := '6F6E2865297B76617220743D7828652E746578742C7B626F6C643A21302C616C69676E3A226C656674222C66696C6C3A6F2E746F74616C732C7370616E3A652E61747C7C69742E6C656E6774682C636F6C6F723A612E746F74616C73436F6C6F727D292C';
wwv_flow_imp.g_varchar2_table(906) := '723D652E63656C6C732E736C69636528652E6174292E6D61702866756E6374696F6E2865297B72657475726E207828652C7B626F6C643A21302C616C69676E3A227269676874222C66696C6C3A6F2E746F74616C732C636F6C6F723A612E746F74616C73';
wwv_flow_imp.g_varchar2_table(907) := '436F6C6F727D297D293B72657475726E20303D3D3D652E61743F5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D7D292C6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C';
wwv_flow_imp.g_varchar2_table(908) := '6368696C6472656E3A727D295D3A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D2E636F6E6361742872297D295D7D3B656528612C6C74292E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(909) := '696628226865616422213D3D652E6B296966282273756222213D3D652E6B297B76617220743D652E722C6C3D652E692C733D7A28612E726F775374796C652C722C74293B73742E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69';
wwv_flow_imp.g_varchar2_table(910) := '743A21302C6368696C6472656E3A69742E6D61702866756E6374696F6E28652C75297B76617220633D7A28652E63656C6C5374796C652C722C74297C7C737C7C7B7D3B696628652E63656C6C297B76617220663D5528652C742C722C6F292C643D632E66';
wwv_flow_imp.g_varchar2_table(911) := '696C6C7C7C286C25323D3D3126262131213D3D612E7A656272613F6F2E7A656272613A6E756C6C293B6626262864745B755D3D4D6174682E6D61782864745B755D7C7C302C662E7729293B76617220683D652E76616C69676E7C7C70743B72657475726E';
wwv_flow_imp.g_varchar2_table(912) := '206E6577206E2E5461626C6543656C6C287B766572746963616C416C69676E3A22746F70223D3D3D683F6E2E566572746963616C416C69676E2E544F503A22626F74746F6D223D3D3D683F6E2E566572746963616C416C69676E2E424F54544F4D3A6E2E';
wwv_flow_imp.g_varchar2_table(913) := '566572746963616C416C69676E2E43454E5445522C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A643F7B747970653A6E2E53686164696E67547970652E434C454152';
wwv_flow_imp.g_varchar2_table(914) := '2C636F6C6F723A226175746F222C66696C6C3A692864297D3A766F696420302C6368696C6472656E3A5B6E6577206E2E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A22726967';
wwv_flow_imp.g_varchar2_table(915) := '6874223D3D3D652E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A226C656674223D3D3D652E616C69676E3F6E2E416C69676E6D656E74547970652E4C4546543A6E2E416C69676E6D656E74547970652E43454E5445522C636869';
wwv_flow_imp.g_varchar2_table(916) := '6C6472656E3A663F5B6E6577206E2E496D61676552756E287B747970653A226A7067223D3D3D662E696D2E6578743F226A7067223A22706E67222C646174613A662E696D2E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E';
wwv_flow_imp.g_varchar2_table(917) := '726F756E6428332E37382A662E77292C6865696768743A4D6174682E726F756E6428332E37382A662E68297D7D295D3A5B5D7D295D7D297D72657475726E2078284C28652C742C72292C7B76616C69676E3A652E76616C69676E7C7C70742C616C69676E';
wwv_flow_imp.g_varchar2_table(918) := '3A652E616C69676E2C626F6C643A652E626F6C647C7C632E626F6C642C636F6C6F723A632E636F6C6F727C7C652E636F6C6F722C66696C6C3A632E66696C6C7C7C286C25323D3D3126262131213D3D612E7A656272613F6F2E7A656272613A6E756C6C29';
wwv_flow_imp.g_varchar2_table(919) := '7D297D297D29297D656C7365206774285A2869742C75742C652E726F77732C746528612C652C722929292E666F72456163682866756E6374696F6E2865297B73742E707573682865297D293B656C73652073742E70757368286E6577206E2E5461626C65';
wwv_flow_imp.g_varchar2_table(920) := '526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B7828746528612C652C72292C7B626F6C643A21302C66696C6C3A6F2E67726F75702C7370616E3A69742E6C656E6774687D295D7D29297D292C5628612E746F74616C73292E6C656E';
wwv_flow_imp.g_varchar2_table(921) := '67746826266C742E6C656E67746826266774285A2869742C5628612E746F74616C73292C6C742C4A28612C722C6C742929292E666F72456163682866756E6374696F6E2865297B73742E707573682865297D293B766172206D743D69742E6D6170286675';
wwv_flow_imp.g_varchar2_table(922) := '6E6374696F6E28652C74297B72657475726E20652E77696474683F652E77696474682F32303A64745B745D3F4D6174682E6D617828312C2864745B745D2B34292F3230293A317D292C76743D6D742E7265647563652866756E6374696F6E28652C74297B';
wwv_flow_imp.g_varchar2_table(923) := '72657475726E20652B747D2C30292C62743D6D742E6D61702866756E6374696F6E2865297B72657475726E204D6174682E666C6F6F7228642A652F7674297D293B682E70757368286E6577206E2E5461626C65287B726F77733A73742C77696474683A7B';
wwv_flow_imp.g_varchar2_table(924) := '73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A62742C626F72646572733A21313D3D3D612E677269643F703A7628612E677269643F612E626F72646572436F6C6F727C7C79653A6E756C6C297D';
wwv_flow_imp.g_varchar2_table(925) := '292C452829297D7D293B766172206D3D652E666F6F7465722C523D422872293B72657475726E7B686561646572733A523F7B64656661756C743A527D3A766F696420302C70726F706572746965733A7B706167653A7B73697A653A7B77696474683A755B';
wwv_flow_imp.g_varchar2_table(926) := '305D2C6865696768743A755B315D2C6F7269656E746174696F6E3A633F6E2E506167654F7269656E746174696F6E2E4C414E4453434150453A6E2E506167654F7269656E746174696F6E2E504F5254524149547D2C6D617267696E3A7B746F703A662C62';
wwv_flow_imp.g_varchar2_table(927) := '6F74746F6D3A662C6C6566743A662C72696768743A667D7D7D2C666F6F746572733A6D3F7B64656661756C743A6E6577206E2E466F6F746572287B6368696C6472656E3A5374286D2C722C6F297D297D3A766F696420302C6368696C6472656E3A682E6C';
wwv_flow_imp.g_varchar2_table(928) := '656E6774683F683A5B79282222295D7D7D292C573D6E6577206E2E446F63756D656E74287B63726561746F723A226E6F76615265706F7274222C7469746C653A5328652E7469746C657C7C22222C745B305D7C7C7B533A7B7D2C543A7B7D7D292C736563';
wwv_flow_imp.g_varchar2_table(929) := '74696F6E733A477D292C5F3D6E2E5061636B65722E746F426C6F623F6E2E5061636B65722E746F426C6F622857292E7468656E2866756E6374696F6E2865297B72657475726E20652E61727261794275666665723F652E61727261794275666665722829';
wwv_flow_imp.g_varchar2_table(930) := '3A657D293A6E2E5061636B65722E746F4275666665722857293B72657475726E206C2E6C656E6774683F5F2E7468656E2866756E6374696F6E2874297B72657475726E20417428742C6C2C666528652C7229297D293A5F7D766172204D743D7B7D3B6675';
wwv_flow_imp.g_varchar2_table(931) := '6E6374696F6E204E742865297B76617220743D652E73706C697428227C22292C723D745B305D2E7472696D28292C6E3D745B315D3F745B315D2E7472696D28293A6E756C6C3B72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E';
wwv_flow_imp.g_varchar2_table(932) := '223D3D3D722972657475726E20653B666F7228766172206F3D722E73706C697428222E22292C613D742626742E73636F70654C6973743F742E73636F70654C6973742E736C69636528292E7265766572736528293A5B655D2C6C3D303B6C3C612E6C656E';
wwv_flow_imp.g_varchar2_table(933) := '6774683B6C2B2B297B666F722876617220693D615B6C5D2C733D21302C753D303B753C6F2E6C656E6774683B752B2B297B69662841727261792E697341727261792869292626753E30262628693D695B305D292C6E756C6C3D3D697C7C226F626A656374';
wwv_flow_imp.g_varchar2_table(934) := '22213D747970656F6620697C7C21286F5B755D696E206929297B733D21313B627265616B7D693D695B6F5B755D5D7D696628732972657475726E206E26262141727261792E697341727261792869293F7028692C6E293A697D7D7D7D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(935) := '20467428652C74297B76617220723D6E65772077696E646F772E50697A5A69702865292C6E3D6E657728302C77696E646F772E646F637874656D706C617465722928722C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C';
wwv_flow_imp.g_varchar2_table(936) := '7061727365723A4E742C6E756C6C4765747465723A66756E6374696F6E28297B72657475726E22227D7D293B72657475726E206E2E72656E6465722866756E6374696F6E2865297B76617220742C723D7B7D3B666F72287420696E20652E706172616D73';
wwv_flow_imp.g_varchar2_table(937) := '7C7C7B7D29725B745D3D652E706172616D735B745D3B666F72287420696E20652E646F637C7C7B7D29725B745D3D652E646F635B745D3B666F72287420696E20652E5329725B745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C';
wwv_flow_imp.g_varchar2_table(938) := '7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D7528292C722E544F4441593D6328292C727D287429292C50726F6D6973652E7265736F6C7665286E2E6765745A697028292E67656E6572617465287B747970653A2261727261';
wwv_flow_imp.g_varchar2_table(939) := '79627566666572222C636F6D7072657373696F6E3A224445464C415445227D29297D66756E6374696F6E2050742865297B76617220743D7B7D2C723D7B7D3B72657475726E204F626A6563742E6B65797328657C7C7B7D292E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(940) := '6374696F6E286E297B766172206F3D655B6E5D2C613D6F2E636F6C737C7C5B5D3B725B6E5D3D7B7D2C612E666F72456163682866756E6374696F6E2865297B725B6E5D5B652E6E616D655D3D652E747970657D292C745B6E5D3D286F2E726F77737C7C5B';
wwv_flow_imp.g_varchar2_table(941) := '5D292E6D61702866756E6374696F6E2865297B76617220743D7B7D3B72657475726E20612E666F72456163682866756E6374696F6E28722C6E297B745B722E6E616D655D3D655B6E5D7D292C747D297D292C7B533A742C543A727D7D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(942) := '206B7428652C74297B76617220723D652E532E444F43533B69662821722972657475726E5B7B533A652E532C543A652E542C646F633A7B7D2C706172616D733A747D5D3B766172206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E5329';
wwv_flow_imp.g_varchar2_table(943) := '2E666F72456163682866756E6374696F6E2874297B69662822444F435322213D3D7426264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B';
wwv_flow_imp.g_varchar2_table(944) := '745D3D7B7D3B652E535B745D2E666F72456163682866756E6374696F6E2865297B76617220743D537472696E6728652E444F435F4B4559293B28725B745D3D725B745D7C7C5B5D292E707573682865297D297D7D292C722E6D61702866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(945) := '2872297B766172206F3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B6F5B745D3D6E5B745D3F6E5B745D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B74';
wwv_flow_imp.g_varchar2_table(946) := '5D7D292C6F2E444F43533D5B725D2C7B533A6F2C543A652E542C646F633A722C706172616D733A747D7D297D66756E6374696F6E204F742865297B76617220743D646F63756D656E742E676574456C656D656E744279496428226E722D6176616E636522';
wwv_flow_imp.g_varchar2_table(947) := '293B653F28747C7C2828743D646F63756D656E742E637265617465456C656D656E7428226469762229292E69643D226E722D6176616E6365222C742E7365744174747269627574652822726F6C65222C2273746174757322292C742E7374796C652E6373';
wwv_flow_imp.g_varchar2_table(948) := '73546578743D22706F736974696F6E3A66697865643B72696768743A323470783B626F74746F6D3A323470783B7A2D696E6465783A313030303B70616464696E673A3134707820313870783B626F726465722D7261646975733A3870783B6261636B6772';
wwv_flow_imp.g_varchar2_table(949) := '6F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A653A313370783B626F782D736861646F773A30203870782032347078207267626128302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D65';
wwv_flow_imp.g_varchar2_table(950) := '6E742E626F64792E617070656E644368696C64287429292C742E696E6E657248544D4C3D273C7370616E20636C6173733D2266612066612D7370696E6E65722066612D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F73';
wwv_flow_imp.g_varchar2_table(951) := '70616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B263C3E225D2F672C66756E6374696F6E2865297B72657475726E7B2226223A2226616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A2226';
wwv_flow_imp.g_varchar2_table(952) := '71756F743B227D5B655D7D29293A742626742E72656D6F766528297D66756E6374696F6E206A7428652C74297B69662865262621652E636C6F736564297472797B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F61';
wwv_flow_imp.g_varchar2_table(953) := '6465724D73672977696E646F772E636F744C6F616465724D736728652C74293B656C73657B76617220723D652E646F63756D656E742E676574456C656D656E744279496428226D736722293B72262628722E74657874436F6E74656E743D74297D7D6361';
wwv_flow_imp.g_varchar2_table(954) := '7463682865297B7D7D66756E6374696F6E204C7428652C74297B7472797B77696E646F772E617065782626617065782E6576656E742626617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C74';
wwv_flow_imp.g_varchar2_table(955) := '297D63617463682865297B7D7D66756E6374696F6E2052742865297B77696E646F772E617065782626617065782E6D6573736167653F617065782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(956) := '2049742865297B77696E646F772E617065782626617065782E6D6573736167652626617065782E6D6573736167652E73686F7750616765537563636573732865297D7661722044743D7B7064663A226170706C69636174696F6E2F706466222C786C7378';
wwv_flow_imp.g_varchar2_table(957) := '3A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F';
wwv_flow_imp.g_varchar2_table(958) := '726D6174732D6F6666696365646F63756D656E742E776F726470726F63657373696E676D6C2E646F63756D656E74227D2C55743D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C6174';
wwv_flow_imp.g_varchar2_table(959) := '65223A22646F6378227D3B66756E6374696F6E20427428652C742C72297B766172206E3D5328652E66696C654E616D657C7C227265706F727465222C74292C6F3D55745B725D3B72657475726E2068286E3D6E2E7265706C616365282F5C2E287064667C';
wwv_flow_imp.g_varchar2_table(960) := '786C73787C646F637829242F692C222229292B222E222B6F7D66756E6374696F6E20477428652C742C722C6E297B72657475726E22706466223D3D3D653F767428742C722C6E2E686F6F6B73293A22786C7378223D3D3D653F797428742C722C722E6C65';
wwv_flow_imp.g_varchar2_table(961) := '6E6774682C6E293A22646F6378223D3D3D653F7A7428742C722C6E293A22646F63782D74656D706C617465223D3D3D653F286F3D6E2E74656D706C61746555726C2C6F3F286F3D7165286F292C4D745B6F5D3F50726F6D6973652E7265736F6C7665284D';
wwv_flow_imp.g_varchar2_table(962) := '745B6F5D293A6665746368286F2C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20646573';
wwv_flow_imp.g_varchar2_table(963) := '636172676172206C6120706C616E74696C6C612028222B652E7374617475732B222922293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B72657475726E204D745B6F5D3D652C657D29293A50';
wwv_flow_imp.g_varchar2_table(964) := '726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C612055524C206465206C6120706C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C6120576F726422292E272929292E7468656E286675';
wwv_flow_imp.g_varchar2_table(965) := '6E6374696F6E2865297B72657475726E20467428652C725B305D297D293A50726F6D6973652E72656A656374286E6577204572726F722822466F726D61746F206E6F20736F706F727461646F3A20222B6529293B766172206F7D66756E6374696F6E2057';
wwv_flow_imp.g_varchar2_table(966) := '7428652C74297B76617220722C6E3D567428652E6C61796F7574292C6F3D7B7D3B666F72287220696E2065296F5B725D3D655B725D3B72657475726E206F2E6C61796F75743D6E2C4A65286E292E7468656E2866756E6374696F6E28297B72657475726E';
wwv_flow_imp.g_varchar2_table(967) := '2066756E6374696F6E28652C74297B76617220723D567428652E6C61796F7574292C6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C6F3D5074287429';
wwv_flow_imp.g_varchar2_table(968) := '2C613D6B74286F2C652E706172616D737C7C7B7D292C6C3D652E6F75747075747C7C2266696C65223B69662821612E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228652E656D7074794D657373616765';
wwv_flow_imp.g_varchar2_table(969) := '7C7C722E656D7074794D6573736167657C7C224E6F20686179206461746F7320706172612067656E6572617220656C207265706F7274652E2229293B696628722E62617463682626722E62617463682E6D6178446F63732626612E6C656E6774683E722E';
wwv_flow_imp.g_varchar2_table(970) := '62617463682E6D6178446F63732972657475726E2050726F6D6973652E72656A656374286E6577204572726F722822456C206C6F74652073757065726120656C206DC3A178696D6F20646520222B722E62617463682E6D6178446F63732B2220646F6375';
wwv_flow_imp.g_varchar2_table(971) := '6D656E746F732E2229293B6966282266696C65223D3D3D6C2626313D3D3D612E6C656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D6C2626313D3D3D6E2E6C656E677468262622646F63782D74656D706C61746522213D3D6E';
wwv_flow_imp.g_varchar2_table(972) := '5B305D297B76617220693D6E5B305D3B72657475726E20477428692C722C612C65292E7468656E2866756E6374696F6E2874297B766172206E3D427428722C615B305D2C69293B696628612E6C656E6774683E31297B766172206C3D722E626174636826';
wwv_flow_imp.g_varchar2_table(973) := '2628722E62617463682E6D657267654E616D657C7C722E62617463682E7A69704E616D65297C7C722E66696C654E616D657C7C227265706F727465223B6E3D4274287B66696C654E616D653A537472696E67286C292E7265706C616365282F5C2E7A6970';
wwv_flow_imp.g_varchar2_table(974) := '242F692C2222297D2C7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C69297D72657475726E7B6B696E643A692C646174613A742C6E616D653A6E2C636F756E743A612E6C656E6774687D7D297D76';
wwv_flow_imp.g_varchar2_table(975) := '617220732C753D6E65772077696E646F772E4A535A69702C633D302C663D302C643D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C703D7B7D3B666F72287320696E20652E706172616D737C7C7B7D29705B735D3D652E7061';
wwv_flow_imp.g_varchar2_table(976) := '72616D735B735D3B702E464F524D41544F3D6E2E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74656D706C617465223A22776F7264227D5B6E5B30';
wwv_flow_imp.g_varchar2_table(977) := '5D5D3B76617220673D7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A707D2C6D3D7B7D3B66756E6374696F6E207628652C74297B666F722876617220723D652C6E3D323B6D5B722E746F4C6F7765724361736528295D3B29723D652E';
wwv_flow_imp.g_varchar2_table(978) := '7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B6E2B22243122292C6E2B2B3B6D5B722E746F4C6F7765724361736528295D3D21302C752E66696C6528722C74292C632B2B7D76617220623D50726F6D6973652E7265736F6C766528292C77';
wwv_flow_imp.g_varchar2_table(979) := '3D722E62617463682626722E62617463682E73756D6D6172793B772626227A6970223D3D3D6C262628623D6E2E66696C7465722866756E6374696F6E2865297B72657475726E22646F63782D74656D706C61746522213D3D657D292E7265647563652866';
wwv_flow_imp.g_varchar2_table(980) := '756E6374696F6E28742C6E297B72657475726E20742E7468656E2866756E6374696F6E28297B76617220743D772E6C61796F75747C7C7B706167653A722E706167652C666F6F7465723A772E666F6F7465727C7C722E666F6F7465722C73656374696F6E';
wwv_flow_imp.g_varchar2_table(981) := '733A772E73656374696F6E732C786C73783A772E786C73782C66696C654E616D653A772E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E66696C654E616D653D772E66696C654E616D657C7C2230305F726573756D656E';
wwv_flow_imp.g_varchar2_table(982) := '22292C4774286E2C742C5B675D2C65292E7468656E2866756E6374696F6E2865297B7628427428742C672C6E292C65297D297D297D2C6229293B72657475726E20622E7468656E2866756E6374696F6E28297B72657475726E206E65772050726F6D6973';
wwv_flow_imp.g_varchar2_table(983) := '652866756E6374696F6E28742C6F297B66756E6374696F6E206C28297B666F722876617220693D4D6174682E6D696E28662B642C612E6C656E677468292C733D50726F6D6973652E7265736F6C766528293B663C693B662B2B292866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(984) := '74297B6E2E666F72456163682866756E6374696F6E286E297B733D732E7468656E2866756E6374696F6E28297B72657475726E204774286E2C722C5B745D2C65292E7468656E2866756E6374696F6E2865297B7628427428722C742C6E292C65297D297D';
wwv_flow_imp.g_varchar2_table(985) := '297D297D2928615B665D293B732E7468656E2866756E6374696F6E28297B652E6F6E50726F67726573732626652E6F6E50726F677265737328662C612E6C656E677468292C663C612E6C656E6774683F73657454696D656F7574286C2C30293A28652E6F';
wwv_flow_imp.g_varchar2_table(986) := '6E50726F67726573732626652E6F6E50726F6772657373282D312C63292C752E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373';
wwv_flow_imp.g_varchar2_table(987) := '696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374696F6E2865297B766172206E3D5328722E62617463682626722E62617463682E7A69704E616D657C7C227265706F727465732E7A6970222C67293B74287B6B696E643A';
wwv_flow_imp.g_varchar2_table(988) := '227A6970222C646174613A652C6E616D653A68282F5C2E7A6970242F692E74657374286E293F6E3A6E2B222E7A697022292C636F756E743A612E6C656E6774682C66696C65733A637D297D2C6F29297D2C6F297D73657454696D656F7574286C2C30297D';
wwv_flow_imp.g_varchar2_table(989) := '297D297D286F2C74297D297D66756E6374696F6E205F742865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B6526262822636F6469676F223D3D3D652E7479706526';
wwv_flow_imp.g_varchar2_table(990) := '26227172223D3D3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292626742E696E6465784F6628227172636F646522293C302626742E7075736828227172636F646522292C226772616669636F223D3D3D652E7479';
wwv_flow_imp.g_varchar2_table(991) := '70652626742E696E6465784F66282263686172746A7322293C302626742E70757368282263686172746A7322292C22666F726D756C6172696F223D3D3D652E747970652626742E696E6465784F6628226A737A697022293C302626742E7075736828226A';
wwv_flow_imp.g_varchar2_table(992) := '737A697022292C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F72456163682872292C425B652E747970655D2626722828652E6669656C64737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(993) := '726E20652626652E626C6F636B7D29292C22677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C227461626C61223D3D3D652E747970652626722828652E636F6C756D6E737C7C5B5D292E6D61702866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(994) := '7B72657475726E20652626652E63656C6C7D2929297D297D7228652E73656374696F6E73293B766172206E3D652E62617463682626652E62617463682E73756D6D6172793B72657475726E206E26262872286E2E73656374696F6E73292C6E2E6C61796F';
wwv_flow_imp.g_varchar2_table(995) := '7574262672286E2E6C61796F75742E73656374696F6E7329292C747D66756E6374696F6E20487428652C74297B69662822737472696E67223D3D747970656F66206526262240223D3D3D652E6368617241742830292626742626766F69642030213D3D74';
wwv_flow_imp.g_varchar2_table(996) := '5B652E7375627374722831295D2972657475726E20487428745B652E7375627374722831295D2C74293B69662841727261792E697341727261792865292972657475726E20652E7265647563652866756E6374696F6E28652C72297B766172206E3D2273';
wwv_flow_imp.g_varchar2_table(997) := '7472696E67223D3D747970656F66207226262240223D3D3D722E636861724174283029262674262641727261792E6973417272617928745B722E7375627374722831295D292C6F3D487428722C74293B72657475726E206E3F652E636F6E636174286F29';
wwv_flow_imp.g_varchar2_table(998) := '3A652E636F6E636174285B6F5D297D2C5B5D293B696628652626226F626A656374223D3D747970656F662065297B76617220723D7B7D3B72657475726E204F626A6563742E6B6579732865292E666F72456163682866756E6374696F6E286E297B725B6E';
wwv_flow_imp.g_varchar2_table(999) := '5D3D2264656673223D3D3D6E3F655B6E5D3A487428655B6E5D2C74297D292C727D72657475726E20657D66756E6374696F6E2056742865297B76617220743B696628652626226F626A656374223D3D747970656F66206529743D653B656C73657B766172';
wwv_flow_imp.g_varchar2_table(1000) := '20723D537472696E6728657C7C2222292E7472696D28293B696628227B223D3D3D722E63686172417428302929743D4A534F4E2E70617273652872293B656C7365206966282128743D722E73706C697428222E22292E7265647563652866756E6374696F';
wwv_flow_imp.g_varchar2_table(1001) := '6E28652C74297B72657475726E20653F655B745D3A766F696420307D2C77696E646F772929297468726F77206E6577204572726F7228224E6F20736520656E636F6E7472C3B320656C2064697365C3B16F3A20222B72297D72657475726E20487428742C';
wwv_flow_imp.g_varchar2_table(1002) := '742E64656673297D66756E6374696F6E2059742865297B69662865297B69662841727261792E697341727261792865297C7C22737472696E6722213D747970656F6620657C7C2F5B232E5C5B5D2F2E746573742865292972657475726E20653B76617220';
wwv_flow_imp.g_varchar2_table(1003) := '743D652E73706C697428222C22292E6D61702866756E6374696F6E2865297B72657475726E20652E7472696D28297D292E66696C74657228426F6F6C65616E293B72657475726E20742E6C656E6774683F743A766F696420307D7D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(1004) := '24742865297B766172206E2C6F3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C613D313D3D3D6F2E6C656E677468262622706466223D3D3D6F5B305D26';
wwv_flow_imp.g_varchar2_table(1005) := '26227A697022213D3D652E6F7574707574262622646F776E6C6F616422213D3D652E706466416374696F6E2C6C3D6126262131213D3D652E6C6F616465723F66756E6374696F6E2865297B76617220743D77696E646F772E6F70656E2822222C225F626C';
wwv_flow_imp.g_varchar2_table(1006) := '616E6B22293B69662821742972657475726E206E756C6C3B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F61646572297472797B77696E646F772E636F744C6F616465722874293B76617220723D742E646F63756D';
wwv_flow_imp.g_varchar2_table(1007) := '656E742E676574456C656D656E747342795461674E616D652822683122295B305D3B72262628722E74657874436F6E74656E743D2247656E6572616E646F207265706F72746522297D63617463682865297B7D656C736520742E646F63756D656E742E77';
wwv_flow_imp.g_varchar2_table(1008) := '7269746528273C21646F63747970652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C7469746C653E47656E6572616E646F207265706F727465E280A63C2F7469746C653E3C7374796C653E626F64';
wwv_flow_imp.g_varchar2_table(1009) := '797B6D617267696E3A303B6865696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B666F6E742D66616D696C793A73797374656D2D7569';
wwv_flow_imp.g_varchar2_table(1010) := '2C73616E732D73657269663B6261636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B77696474683A353670783B6865696768743A353670783B626F726465723A35';
wwv_flow_imp.g_varchar2_table(1011) := '707820736F6C696420236436653065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A72203173206C696E65617220696E66696E6974653B6D617267696E3A3020';
wwv_flow_imp.g_varchar2_table(1012) := '6175746F20313870787D406B65796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F';
wwv_flow_imp.g_varchar2_table(1013) := '723A233562366237627D3C2F7374796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C68313E47656E6572616E646F207265706F7274653C2F68313E3C702069643D22';
wwv_flow_imp.g_varchar2_table(1014) := '6D7367223E3C2F703E3C2F6469763E3C2F626F64793E3C2F68746D6C3E27292C742E646F63756D656E742E636C6F736528293B72657475726E206A7428742C65292C747D28652E6D6573736167657C7C22436F6E73756C74616E646F206461746F73E280';
wwv_flow_imp.g_varchar2_table(1015) := 'A622293A6E756C6C2C693D77696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E73686F775370696E6E657228293A6E756C6C2C733D227265736F6C766572223D3D3D652E6F726967696E262621652E646174612C753D2271';
wwv_flow_imp.g_varchar2_table(1016) := '75657279223D3D3D652E6F726967696E262621652E646174613B696628217326262175297472797B6E3D567428652E6C61796F7574297D63617463682865297B72657475726E20692626692E72656D6F766528292C6C26266C2E636C6F736528292C5274';
wwv_flow_imp.g_varchar2_table(1017) := '282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765292C50726F6D6973652E72656A6563742865297D76617220633D7B6C61796F75743A6E2C666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C';
wwv_flow_imp.g_varchar2_table(1018) := '706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D706C61746555726C2C686F6F6B733A652E686F6F6B737C7C7B7D2C666F726D50617373776F72643A652E666F726D50617373776F72647D3B4C742822737461';
wwv_flow_imp.g_varchar2_table(1019) := '7274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C7265706F72743A733F652E7265706F72743A766F696420307D293B76617220663D722866756E6374696F6E28652C72297B766172206E3D5B5D3B7265747572';
wwv_flow_imp.g_varchar2_table(1020) := '6E20652E666F72456163682866756E6374696F6E2865297B28745B655D7C7C5B5D292E666F72456163682866756E6374696F6E2865297B6E2E696E6465784F662865293C3026266E2E707573682865297D297D292C7226266E2E7075736828226A737A69';
wwv_flow_imp.g_varchar2_table(1021) := '7022292C6E7D286F2C226D6572676522213D3D652E6F7574707574292E636F6E63617428737C7C753F5B5D3A5F74286E2929292C643D652E646174613F50726F6D6973652E7265736F6C7665287B646174613A652E646174617D293A6E65772050726F6D';
wwv_flow_imp.g_varchar2_table(1022) := '6973652866756E6374696F6E28742C72297B766172206E3D7B7830313A4A534F4E2E737472696E6769667928632E706172616D73292C7830323A227A6970223D3D3D652E6F75747075743F2259223A224E222C706167654974656D733A597428652E6974';
wwv_flow_imp.g_varchar2_table(1023) := '656D73297D3B69662873297B696628766F696420303D3D3D652E7265706F72747C7C6E756C6C3D3D3D652E7265706F72747C7C22223D3D3D652E7265706F72742972657475726E20766F69642072286E6577204572726F722822496E646971756520656C';
wwv_flow_imp.g_varchar2_table(1024) := '207265706F72746520612067656E657261722028646174612D7265706F7274292E2229293B6E2E7830333D537472696E6728652E7265706F7274297D617065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C6E2C7B64';
wwv_flow_imp.g_varchar2_table(1025) := '617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B652626652E6F6B3F742865293A72286E6577204572726F7228652626652E6D73677C7C224572726F7220616C206F6274656E6572206C6F73206461746F732E222929';
wwv_flow_imp.g_varchar2_table(1026) := '7D2C66756E6374696F6E28652C742C6E297B72286E6577204572726F7228224572726F7220646520636F6D756E6963616369C3B36E3A20222B286E7C7C742929297D297D293B72657475726E2050726F6D6973652E616C6C285B642C665D292E7468656E';
wwv_flow_imp.g_varchar2_table(1027) := '2866756E6374696F6E2874297B766172206F3D745B305D2C613D50726F6D6973652E7265736F6C766528293B69662873297B7472797B6E3D5674286F2E6C61796F7574297D63617463682865297B7468726F77206E6577204572726F72282244697365C3';
wwv_flow_imp.g_varchar2_table(1028) := 'B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D632E6C61796F75743D6E2C6F2E706172616D73262628632E706172616D733D6F2E706172616D73292C6F2E74656D706C61746555726C262628632E74656D706C61746555726C3D6F2E';
wwv_flow_imp.g_varchar2_table(1029) := '74656D706C61746555726C292C613D72285F74286E29297D656C73652069662875297B766172206C3D6F2E6C61796F75747C7C652E6C61796F75743B696628216C297468726F77206E6577204572726F72282246616C746120656C2064697365C3B16F3A';
wwv_flow_imp.g_varchar2_table(1030) := '206C6120636F6E73756C74612064656C207265706F727465206E6F206465766F6C7669C3B3204C41594F5554207920656C20617472696275746F2044697365C3B16F20657374C3A120766163C3AD6F2E22293B7472797B6E3D5674286C297D6361746368';
wwv_flow_imp.g_varchar2_table(1031) := '2865297B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D632E6C61796F75743D6E2C6F2E74656D706C61746555726C262628632E74656D706C61746555726C3D6F2E74656D70';
wwv_flow_imp.g_varchar2_table(1032) := '6C61746555726C292C613D72285F74286E29297D72657475726E20612E7468656E2866756E6374696F6E28297B72657475726E206F2E646174617D297D292E7468656E2866756E6374696F6E2874297B69262628692E72656D6F766528292C693D6E756C';
wwv_flow_imp.g_varchar2_table(1033) := '6C293B76617220723D652E7472616E73666F726D2626652E7472616E73666F726D2874297C7C743B72657475726E206A74286C2C2241726D616E646F20656C20646F63756D656E746FE280A622292C632E6F6E50726F67726573733D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(1034) := '28652C74297B2D313D3D3D653F4F742822436F6D7072696D69656E646F20222B742B22206172636869766F73E280A622293A284F74282247656E6572616E646F20222B652B2220646520222B742B22E280A622292C4C74282270726F6772657373222C7B';
wwv_flow_imp.g_varchar2_table(1035) := '646F6E653A652C746F74616C3A747D29297D2C577428632C72297D292E7468656E2866756E6374696F6E2874297B76617220723D652E736176657C7C632E6C61796F75742626632E6C61796F75742E736176653B69662821727C7C21722E70726F636573';
wwv_flow_imp.g_varchar2_table(1036) := '732972657475726E20743B6966282177696E646F772E617065787C7C21617065782E736572766572297468726F77206E6577204572726F7228224775617264617220656E20656C207365727669646F7220726571756965726520415045582E22293B7265';
wwv_flow_imp.g_varchar2_table(1037) := '7475726E204F7428224775617264616E646F20656E20656C207365727669646F72E280A622292C66756E6374696F6E28652C742C72297B766172206E3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A44745B652E6B';
wwv_flow_imp.g_varchar2_table(1038) := '696E645D7C7C44742E646F63782C6F3D652E6461746120696E7374616E63656F6620426C6F623F652E646174613A6E657720426C6F62285B652E646174615D2C7B747970653A6E7D293B72657475726E206E65772050726F6D6973652866756E6374696F';
wwv_flow_imp.g_varchar2_table(1039) := '6E28612C6C297B76617220693D6E65772046696C655265616465723B692E6F6E6572726F723D66756E6374696F6E28297B6C286E6577204572726F7228224E6F207365207075646F206C65657220656C206172636869766F2067656E657261646F2E2229';
wwv_flow_imp.g_varchar2_table(1040) := '297D2C692E6F6E6C6F61643D66756E6374696F6E28297B766172206F2C733D537472696E6728692E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292C753D5B5D3B666F72286F3D303B6F3C732E6C656E6774683B6F';
wwv_flow_imp.g_varchar2_table(1041) := '2B3D33653429752E7075736828732E737562737472286F2C33653429293B617065782E7365727665722E70726F6365737328742E70726F636573732C7B7830313A652E6E616D652C7830323A6E2C7830333A766F696420303D3D3D722E7265706F72743F';
wwv_flow_imp.g_varchar2_table(1042) := '22223A537472696E6728722E7265706F7274292C7830343A4A534F4E2E737472696E6769667928722E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A757D2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374';
wwv_flow_imp.g_varchar2_table(1043) := '696F6E2865297B65262621313D3D3D652E6F6B3F6C286E6577204572726F7228652E6D73677C7C22456C207365727669646F72206E6F206775617264C3B320656C20646F63756D656E746F2E2229293A6128657C7C7B7D297D2C66756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(1044) := '2C742C72297B6C286E6577204572726F7228224E6F207365207075646F206775617264617220656E20656C207365727669646F723A20222B28727C7C742929297D297D2C692E7265616441734461746155524C286F297D297D28742C722C7B7265706F72';
wwv_flow_imp.g_varchar2_table(1045) := '743A652E7265706F72742C706172616D733A632E706172616D737D292E7468656E2866756E6374696F6E2865297B72657475726E20742E73617665643D652C742E6F6E6C793D226F6E6C79223D3D3D722E6D6F64652C4C7428227361766564222C7B6E61';
wwv_flow_imp.g_varchar2_table(1046) := '6D653A742E6E616D652C6B696E643A742E6B696E642C726573706F6E73653A657D292C747D297D292E7468656E2866756E6374696F6E2865297B6966284F7428292C652E6F6E6C79296C26266C2E636C6F736528292C497428652E73617665642626652E';
wwv_flow_imp.g_varchar2_table(1047) := '73617665642E6D73677C7C22446F63756D656E746F20677561726461646F3A20222B652E6E616D65293B656C73652069662822706466223D3D3D652E6B696E64262661297B76617220743D55524C2E6372656174654F626A65637455524C286E65772042';
wwv_flow_imp.g_varchar2_table(1048) := '6C6F62285B652E646174615D2C7B747970653A44742E7064667D29293B6C2626216C2E636C6F7365643F6C2E6C6F636174696F6E2E687265663D743A77696E646F772E6F70656E28742C225F626C616E6B22297D656C7365206C26266C2E636C6F736528';
wwv_flow_imp.g_varchar2_table(1049) := '292C723D652E646174612C6E3D652E6E616D652C6F3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A44745B652E6B696E645D7C7C44742E646F63782C693D7220696E7374616E63656F6620426C6F623F723A6E6577';
wwv_flow_imp.g_varchar2_table(1050) := '20426C6F62285B725D2C7B747970653A6F7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D292C28733D646F63756D656E742E637265617465456C656D656E742822612229292E687265663D55524C2E6372656174654F626A6563';
wwv_flow_imp.g_varchar2_table(1051) := '7455524C2869292C732E646F776E6C6F61643D6E2C646F63756D656E742E626F64792E617070656E644368696C642873292C732E636C69636B28292C73657454696D656F75742866756E6374696F6E28297B55524C2E7265766F6B654F626A6563745552';
wwv_flow_imp.g_varchar2_table(1052) := '4C28732E68726566292C732E72656D6F766528297D2C346533292C227A6970223D3D3D652E6B696E642626497428225A49502067656E657261646F3A20222B652E66696C65732B22206172636869766F7320646520222B652E636F756E742B2220646F63';
wwv_flow_imp.g_varchar2_table(1053) := '756D656E746F732E22293B76617220722C6E2C6F2C692C733B72657475726E204C742822656E64222C7B6E616D653A652E6E616D652C636F756E743A652E636F756E742C66696C65733A652E66696C65737D292C657D292E63617463682866756E637469';
wwv_flow_imp.g_varchar2_table(1054) := '6F6E2865297B7468726F7720692626692E72656D6F766528292C4F7428292C6C2626216C2E636C6F73656426266C2E636C6F736528292C77696E646F772E636F6E736F6C652626636F6E736F6C652E6572726F722865292C4C7428226572726F72222C7B';
wwv_flow_imp.g_varchar2_table(1055) := '6D6573736167653A652E6D6573736167657D292C527428652E6D6573736167657C7C224E6F207365207075646F2067656E6572617220656C207265706F7274652E22292C657D297D7661722071743D21312C58743D6E756C6C3B72657475726E22756E64';
wwv_flow_imp.g_varchar2_table(1056) := '6566696E656422213D747970656F6620646F63756D656E742626646F63756D656E742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2865297B58';
wwv_flow_imp.g_varchar2_table(1057) := '743D652E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D2C5B646174612D666F726D61745D22297C7C652E7461726765747D2C2130';
wwv_flow_imp.g_varchar2_table(1058) := '292C7B76657273696F6E3A22312E31392E30222C6C6962733A652C72756E3A24742C64613A66756E6374696F6E2865297B76617220743D746869732626746869732E616374696F6E3F746869733A7B7D2C723D742E616374696F6E7C7C7B7D2C6E3D742E';
wwv_flow_imp.g_varchar2_table(1059) := '74726967676572696E67456C656D656E747C7C58742C6F3D742E62726F777365724576656E743B6966286F26266F2E70726576656E7444656661756C7426266F2E70726576656E7444656661756C7428292C217174297B76617220613D652626226F626A';
wwv_flow_imp.g_varchar2_table(1060) := '656374223D3D747970656F6620653F653A7B7D2C6C3D2266756E6374696F6E223D3D747970656F6620653F653A612E696E69742C693D7B7D2C733D6E26266E2E646174617365747C7C7B7D2C753D612E7265706F72742C633D612E6F75747075747C7C72';
wwv_flow_imp.g_varchar2_table(1061) := '2E61747472696275746530337C7C2266696C65222C663D612E666F726D61747C7C722E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732873292E666F72456163682866756E6374696F6E2865297B226F757470757422213D3D';
wwv_flow_imp.g_varchar2_table(1062) := '653F22666F726D617422213D3D653F227265706F727422213D3D653F695B652E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D735B655D3A753D735B655D3A663D735B655D3A633D735B655D7D29';
wwv_flow_imp.g_varchar2_table(1063) := '3B76617220643D7B6C61796F75743A612E6C61796F75747C7C722E61747472696275746530312C666F726D61743A662C6F75747075743A632C6974656D733A612E6974656D737C7C722E61747472696275746530347C7C22222C706466416374696F6E3A';
wwv_flow_imp.g_varchar2_table(1064) := '612E706466416374696F6E7C7C722E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A612E74656D706C61746555726C7C7C722E61747472696275746530362C6D6573736167653A612E6D6573736167657C7C722E617474';
wwv_flow_imp.g_varchar2_table(1065) := '72696275746530372C706172616D733A692C616A61784964656E7469666965723A612E616A61784964656E7469666965727C7C722E616A61784964656E7469666965722C6F726967696E3A612E6F726967696E7C7C2261747472696275746573222C7265';
wwv_flow_imp.g_varchar2_table(1066) := '706F72743A752C736176653A612E736176657D3B6966282266756E6374696F6E223D3D747970656F66206C297B76617220683D6C2864293B69662821313D3D3D682972657475726E3B643D687C7C647D71743D21302C24742864292E7468656E2866756E';
wwv_flow_imp.g_varchar2_table(1067) := '6374696F6E28297B71743D21317D2C66756E6374696F6E28297B71743D21317D297D7D2C6275696C643A57742C656E737572653A722C6C61796F75744C6962733A5F742C5F696E7465726E616C733A7B494D473A59652C696D6744696D733A58652C7470';
wwv_flow_imp.g_varchar2_table(1068) := '6C3A532C636F6E643A542C666D743A702C6E6F726D616C697A653A50742C636F6E74657874733A6B742C636F64653132383A75742C706E67313A69742C6C61796F75744C6962733A5F742C7368613531323A67652C776F72644C65676163794B65793A62';
wwv_flow_imp.g_varchar2_table(1069) := '652C776F7264486173683A77652C666F726D4E616D653A73657D7D7D28293B';
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
