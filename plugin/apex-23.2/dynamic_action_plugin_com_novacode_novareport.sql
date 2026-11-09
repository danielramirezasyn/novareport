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
,p_version_identifier=>'1.22.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>34
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
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E32322E30202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C';
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
wwv_flow_imp.g_varchar2_table(20) := '28742C72297B72657475726E20742E7468656E2866756E6374696F6E28297B72657475726E20655B725D2E6F6B28293F6E756C6C3A28743D6F7428655B725D2E75726C292C6E65772050726F6D6973652866756E6374696F6E28652C72297B766172206E';
wwv_flow_imp.g_varchar2_table(21) := '3D77696E646F772E646566696E653B77696E646F772E646566696E653D766F696420303B766172206F3D646F63756D656E742E637265617465456C656D656E74282273637269707422293B6F2E7372633D742C6F2E6F6E6C6F61643D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(22) := '28297B77696E646F772E646566696E653D6E2C6528297D2C6F2E6F6E6572726F723D66756E6374696F6E28297B77696E646F772E646566696E653D6E2C72286E6577204572726F7228224E6F207365207075646F20636172676172206C61206C69627265';
wwv_flow_imp.g_varchar2_table(23) := '72C3AD613A20222B7429297D2C646F63756D656E742E686561642E617070656E644368696C64286F297D29293B76617220747D297D2C50726F6D6973652E7265736F6C76652829297D766172206E3D7B7072696D6172793A2223314634453739222C6865';
wwv_flow_imp.g_varchar2_table(24) := '6164546578743A2223464646464646222C7A656272613A2223463546374641222C746F74616C733A2223453645434632222C746578743A2223303030303030222C6D757465643A2223373837383738222C666F6E7453697A653A372C67726F75703A2223';
wwv_flow_imp.g_varchar2_table(25) := '444345364630222C6C696E6B3A2223303536334331227D3B66756E6374696F6E206F2865297B72657475726E226E756D626572223D3D747970656F66206526262169734E614E2865297D66756E6374696F6E206C2865297B72657475726E20333D3D3D28';
wwv_flow_imp.g_varchar2_table(26) := '653D537472696E6728657C7C222330303030303022292E7265706C616365282223222C222229292E6C656E677468262628653D652E7265706C616365282F282E292F672C22243124312229292C5B7061727365496E7428652E73756273747228302C3229';
wwv_flow_imp.g_varchar2_table(27) := '2C3136292C7061727365496E7428652E73756273747228322C32292C3136292C7061727365496E7428652E73756273747228342C32292C3136295D7D66756E6374696F6E20612865297B72657475726E224646222B537472696E6728657C7C2223303030';
wwv_flow_imp.g_varchar2_table(28) := '30303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E6374696F6E20692865297B72657475726E20537472696E6728657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065';
wwv_flow_imp.g_varchar2_table(29) := '724361736528297D66756E6374696F6E20732865297B72657475726E28653C31303F2230223A2222292B657D66756E6374696F6E207528297B76617220653D6E657720446174653B72657475726E207328652E676574446174652829292B222F222B7328';
wwv_flow_imp.g_varchar2_table(30) := '652E6765744D6F6E746828292B31292B222F222B652E67657446756C6C5965617228292B2220222B7328652E676574486F7572732829292B223A222B7328652E6765744D696E757465732829297D66756E6374696F6E206328297B72657475726E207528';
wwv_flow_imp.g_varchar2_table(31) := '292E73756273747228302C3130297D66756E6374696F6E20662865297B76617220743D537472696E672865292E746F4C6F7765724361736528292E7265706C616365282F5F2F672C222022293B72657475726E20742E6368617241742830292E746F5570';
wwv_flow_imp.g_varchar2_table(32) := '7065724361736528292B742E736C6963652831297D66756E6374696F6E20642865297B76617220743D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D29242F2E6578656328537472696E6728657C7C222229293B72657475726E20743F';
wwv_flow_imp.g_varchar2_table(33) := '6E6577204461746528446174652E555443282B745B335D2C2B745B325D2D312C2B745B315D29293A6E756C6C7D66756E6374696F6E20682865297B72657475726E20537472696E6728657C7C226172636869766F22292E7265706C616365282F5B5C5C5C';
wwv_flow_imp.g_varchar2_table(34) := '2F3A2A3F223C3E7C5D2B2F672C225F22292E7472696D28297D66756E6374696F6E207028652C74297B6966286E756C6C3D3D657C7C22223D3D3D652972657475726E22223B69662821742972657475726E20537472696E672865293B6966285328742929';
wwv_flow_imp.g_varchar2_table(35) := '72657475726E2066756E6374696F6E28652C74297B76617220723D4E756D6265722865293B6966286E756C6C3D3D657C7C22223D3D3D657C7C69734E614E2872292972657475726E206E756C6C3D3D653F22223A537472696E672865293B766172206E3D';
wwv_flow_imp.g_varchar2_table(36) := '772874292C6F3D6E5B305D2C6C3D21313B723C3026266E2E6C656E6774683E3126266E5B315D2E746F6B732E6C656E6774683F286F3D6E5B315D2C723D2D72293A723C302626286C3D21302C723D2D72293B303D3D3D7226266E2E6C656E6774683E3226';
wwv_flow_imp.g_varchar2_table(37) := '26286F3D6E5B325D2C6C3D2131293B6F2E706374262628722A3D313030293B722F3D6F2E7363616C653B76617220613D4E756D62657228722E746F4669786564286F2E6D617844656329293B303D3D3D612626286C3D2131293B76617220693D612E746F';
wwv_flow_imp.g_varchar2_table(38) := '4C6F63616C65537472696E672822656E2D5553222C7B75736547726F7570696E673A6F2E67726F75702C6D696E696D756D496E74656765724469676974733A4D6174682E6D617828312C4D6174682E6D696E2832312C6F2E6D696E496E7429292C6D696E';
wwv_flow_imp.g_varchar2_table(39) := '696D756D4672616374696F6E4469676974733A6F2E6D696E4465632C6D6178696D756D4672616374696F6E4469676974733A6F2E6D61784465637D293B216F2E6D696E496E7426262F5E30285C2E7C24292F2E74657374286929262628693D692E736C69';
wwv_flow_imp.g_varchar2_table(40) := '6365283129293B222E223D3D3D6F2E6465632626222C223D3D3D6F2E6772707C7C28693D692E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E2865297B72657475726E222E223D3D3D653F6F2E6465633A6F2E6772707D29293B7661722073';
wwv_flow_imp.g_varchar2_table(41) := '3D6F2E746F6B732E6D61702866756E6374696F6E2865297B72657475726E226E223D3D3D652E743F693A2278223D3D3D652E743F22223A652E767D292E6A6F696E282222293B72657475726E206C3F222D222B733A737D28652C74293B76617220723D74';
wwv_flow_imp.g_varchar2_table(42) := '2E73706C697428223A22292C6E3D725B305D3B696628226D6F6E6579223D3D3D6E7C7C226E756D223D3D3D6E297B766172206F3D766F69642030213D3D725B315D3F2B725B315D3A322C6C3D4E756D6265722865293B72657475726E2069734E614E286C';
wwv_flow_imp.g_varchar2_table(43) := '293F537472696E672865293A6C2E746F4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A6F2C6D6178696D756D4672616374696F6E4469676974733A6F7D297D72657475726E22696E74223D';
wwv_flow_imp.g_varchar2_table(44) := '3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A4D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D555322293A22706374223D3D3D6E3F7028652C226E756D3A222B2872';
wwv_flow_imp.g_varchar2_table(45) := '5B315D7C7C3229292B2225223A227570706572223D3D3D6E3F537472696E672865292E746F55707065724361736528293A226C6F776572223D3D3D6E3F537472696E672865292E746F4C6F7765724361736528293A22796E223D3D3D6E3F2259223D3D3D';
wwv_flow_imp.g_varchar2_table(46) := '657C7C2253223D3D3D653F2253C3AD223A224E223D3D3D653F224E6F223A537472696E672865293A226C6574726173223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A66756E6374696F6E28652C74297B76617220723D';
wwv_flow_imp.g_varchar2_table(47) := '653C302C6E3D4D6174682E726F756E64283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C6C3D6E253130302C613D7A286F293B69662874297B2F284D494C4CC3934E7C4D494C4C4F4E45537C42494C4CC393';
wwv_flow_imp.g_varchar2_table(48) := '4E7C42494C4C4F4E455329242F2E74657374286129262628612B3D2220444522293B76617220693D537472696E672874292E746F55707065724361736528292E73706C697428222F22293B612B3D2220222B28313D3D3D6F2626692E6C656E6774683E31';
wwv_flow_imp.g_varchar2_table(49) := '3F695B305D3A695B692E6C656E6774682D315D297D656C736520613D612E7265706C616365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E2865297B72657475726E20652B224F227D293B72';
wwv_flow_imp.g_varchar2_table(50) := '657475726E28723F224D454E4F5320223A2222292B612B2220434F4E20222B286C3C31303F2230223A2222292B6C2B222F313030227D284E756D6265722865292C722E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E';
wwv_flow_imp.g_varchar2_table(51) := '6374696F6E20672865297B72657475726E2F5E2875707065727C6C6F7765727C796E7C6C657472617329283A7C24292F2E7465737428657C7C2222297D766172206D3D7B7D3B66756E6374696F6E20762865297B666F722876617220743D5B5D2C723D22';
wwv_flow_imp.g_varchar2_table(52) := '222C6E3D21312C6F3D303B6F3C652E6C656E6774683B6F2B2B297B766172206C3D652E636861724174286F293B225C5C22213D3D6C7C7C6E3F282722273D3D3D6C2626286E3D216E292C223B22213D3D6C7C7C6E3F722B3D6C3A28742E70757368287229';
wwv_flow_imp.g_varchar2_table(53) := '2C723D222229293A28722B3D6C2B28652E636861724174286F2B31297C7C2222292C6F2B2B297D72657475726E20742E707573682872292C747D66756E6374696F6E20622865297B76617220742C722C6E3D5B5D2C6F3D6E756C6C2C6C3D21312C613D22';
wwv_flow_imp.g_varchar2_table(54) := '222C693D21312C733D66756E6374696F6E28297B612626286E2E70757368287B743A226C222C763A617D292C613D2222297D3B666F7228743D303B743C652E6C656E6774683B742B2B29696628272227213D3D28723D652E636861724174287429292969';
wwv_flow_imp.g_varchar2_table(55) := '6628225C5C22213D3D72297B696628225B223D3D3D72297B76617220753D652E696E6465784F6628225D222C74293B696628753E30297B7328292C6E2E70757368287B743A2278222C763A652E736C69636528742C752B31297D292C743D753B636F6E74';
wwv_flow_imp.g_varchar2_table(56) := '696E75657D7D225F22213D3D723F222A22213D3D723F216C26262F5B23303F2C2E5D2F2E746573742872292626286E756C6C213D3D6F7C7C2F5B23303F5D2F2E746573742872297C7C222E223D3D3D7226262F5B23303F5D2F2E7465737428652E636861';
wwv_flow_imp.g_varchar2_table(57) := '72417428742B312929293F286E756C6C3D3D3D6F2626287328292C6F3D22222C6E2E70757368287B743A226E227D29292C6F2B3D72293A286E756C6C213D3D6F2626286C3D2130292C2225223D3D3D72262628693D2130292C612B3D72293A742B2B3A28';
wwv_flow_imp.g_varchar2_table(58) := '612B3D2220222C742B2B297D656C736520612B3D652E63686172417428742B31292C742B2B3B656C73657B76617220633D652E696E6465784F66282722272C742B31293B633C30262628633D652E6C656E677468292C612B3D652E736C69636528742B31';
wwv_flow_imp.g_varchar2_table(59) := '2C63292C743D637D7328293B76617220663D286F3D6F7C7C2222292E6C617374496E6465784F6628222C22292C643D21313B663E3D3026262F5E5B23303F5D2B242F2E74657374286F2E736C69636528662B312929262628643D6F2E696E6465784F6628';
wwv_flow_imp.g_varchar2_table(60) := '222E22293E3D303F6F2E6C617374496E6465784F6628222E22293C663A6F2E6C656E6774682D662D31213D33292C642626286F3D6F2E7265706C616365282F5B2E2C5D2F672C66756E6374696F6E2865297B72657475726E222E223D3D3D653F222C223A';
wwv_flow_imp.g_varchar2_table(61) := '222E227D29293B76617220683D282F2C2B242F2E65786563286F297C7C5B22225D295B305D2E6C656E6774682C703D6F2E736C69636528302C6F2E6C656E6774682D68292C673D702E696E6465784F6628222E22292C6D3D673C303F703A702E736C6963';
wwv_flow_imp.g_varchar2_table(62) := '6528302C67292C763D673C303F22223A702E736C69636528672B31292C623D282F2C2B242F2E65786563286D297C7C5B22225D295B305D2E6C656E6774682B683B72657475726E206D3D6D2E736C69636528302C6D2E6C656E6774682D62292C7B746F6B';
wwv_flow_imp.g_varchar2_table(63) := '733A6E2C7261773A6F2C6861734E756D3A21216F2C7063743A692C7363616C653A4D6174682E706F77283165332C62292C67726F75703A6D2E696E6465784F6628222C22293E3D302C6D696E496E743A286D2E6D61746368282F302F67297C7C5B5D292E';
wwv_flow_imp.g_varchar2_table(64) := '6C656E6774682C6D61784465633A28762E6D61746368282F5B23303F5D2F67297C7C5B5D292E6C656E6774682C6D696E4465633A28762E6D61746368282F302F67297C7C5B5D292E6C656E6774682C6465633A643F222C223A222E222C6772703A643F22';
wwv_flow_imp.g_varchar2_table(65) := '2E223A222C227D7D66756E6374696F6E20772865297B696628653D537472696E672865292C216D5B655D296966282F5E6F72613A2F2E74657374286529297B76617220743D66756E6374696F6E2865297B76617220742C722C6E3D5B5D2C6F3D22222C6C';
wwv_flow_imp.g_varchar2_table(66) := '3D22223B666F7228743D303B743C652E6C656E6774683B742B2B29723D652E6368617241742874292C6C3F723D3D3D6C3F6C3D22223A6F2B3D723A222722213D3D722626272227213D3D723F223B22213D3D723F6F2B3D723A286E2E70757368286F292C';
wwv_flow_imp.g_varchar2_table(67) := '6F3D2222293A6C3D723B6E2E70757368286F293B76617220613D6E2E736869667428292E7472696D28292E746F55707065724361736528292C693D2F5E464D2F2E746573742861292C733D7B6E6C733A222E2C222C6375723A2224222C69736F3A225553';
wwv_flow_imp.g_varchar2_table(68) := '44227D3B6E2E666F72456163682866756E6374696F6E2865297B76617220743D652E696E6465784F6628223D22293B743E30262628735B652E736C69636528302C74292E7472696D28292E746F4C6F7765724361736528295D3D652E736C69636528742B';
wwv_flow_imp.g_varchar2_table(69) := '3129297D292C613D612E7265706C616365282F5E464D2F2C2222293B76617220753D2F5052242F2E746573742861292C633D217526262F4D49242F2E746573742861293B28757C7C6329262628613D612E736C69636528302C2D3229293B76617220663D';
wwv_flow_imp.g_varchar2_table(70) := '2F5E532F2E746573742861292C643D2166262621752626216326262F53242F2E746573742861293B663F613D612E736C6963652831293A64262628613D612E736C69636528302C2D3129293B76617220683D612E696E6465784F6628224222293E3D302C';
wwv_flow_imp.g_varchar2_table(71) := '703D22222C673D22222C6D3D22222C763D22222C623D21312C773D21313B666F7228613D612E7265706C616365282F422F672C2222292C743D303B743C612E6C656E6774683B742B2B296966282239223D3D3D28723D612E636861724174287429297C7C';
wwv_flow_imp.g_varchar2_table(72) := '2230223D3D3D7229773D21302C623F762B3D2239223D3D3D722626693F2223223A2230223A6D2B3D723B656C7365206966282247223D3D3D727C7C222C223D3D3D7229627C7C286D2B3D222C22293B656C7365206966282244223D3D3D727C7C222E223D';
wwv_flow_imp.g_varchar2_table(73) := '3D3D7229623D21303B656C736520696628224C223D3D3D727C7C2255223D3D3D727C7C2243223D3D3D727C7C2224223D3D3D72297B76617220793D2243223D3D3D723F732E69736F3A2224223D3D3D723F2224223A732E6375723B773F672B3D793A702B';
wwv_flow_imp.g_varchar2_table(74) := '3D797D76617220783D6D2E696E6465784F6628223022292C533D286D3D6D2E7265706C616365282F5B39305D2F672C66756E6374696F6E28652C74297B72657475726E20783E3D302626743E3D783F2230223A2223227D292E7265706C616365282F5E2C';
wwv_flow_imp.g_varchar2_table(75) := '2B2F2C222229292B28763F222E222B763A2222297C7C2223222C453D66756E6374696F6E2865297B72657475726E20653F2722272B537472696E672865292E7265706C616365282F222F672C2222292B2722273A22227D2C433D452870292B532B452867';
wwv_flow_imp.g_varchar2_table(76) := '292C543D433B753F543D432B223B222B4528223C222B70292B532B4528672B223E22293A633F543D432B223B222B452870292B532B4528672B222D22293A663F543D4528222B222B70292B532B452867292B223B222B4528222D222B70292B532B452867';
wwv_flow_imp.g_varchar2_table(77) := '293A64262628543D452870292B532B4528672B222B22292B223B222B452870292B532B4528672B222D2229292C68262628543D3D3D43262628542B3D223B222B4528222D222B70292B532B45286729292C542B3D273B222227293B76617220413D537472';
wwv_flow_imp.g_varchar2_table(78) := '696E6728732E6E6C737C7C222E2C22293B72657475726E7B7372633A542C6465633A412E6368617241742830297C7C222E222C6772703A412E6368617241742831297C7C222C227D7D28652E736C696365283429293B6D5B655D3D7628742E737263292E';
wwv_flow_imp.g_varchar2_table(79) := '6D61702866756E6374696F6E2865297B76617220723D622865293B72657475726E20722E6465633D742E6465632C722E6772703D742E6772702C727D297D656C7365206D5B655D3D762866756E6374696F6E2865297B72657475726E20653D537472696E';
wwv_flow_imp.g_varchar2_table(80) := '672865292C2F5E6D61736B3A2F2E746573742865293F652E736C6963652835293A657D286529292E6D61702862293B72657475726E206D5B655D7D66756E6374696F6E20792865297B72657475726E20772865292E6D61702866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(81) := '7B72657475726E20652E746F6B732E6D61702866756E6374696F6E2874297B72657475726E226E223D3D3D742E743F652E7261773A2278223D3D3D742E743F742E763A742E762E73706C697428222522292E6D61702866756E6374696F6E2865297B7265';
wwv_flow_imp.g_varchar2_table(82) := '7475726E20653F2722272B652E7265706C616365282F222F672C2222292B2722273A22227D292E6A6F696E28222522297D292E6A6F696E282222297C7C272222277D292E6A6F696E28223B22297D76617220783D2F5E286D6F6E65797C6E756D7C696E74';
wwv_flow_imp.g_varchar2_table(83) := '7C7063747C646174657C75707065727C6C6F7765727C796E7C6C657472617329283A7C24292F3B66756E6374696F6E20532865297B72657475726E2F5E286D61736B7C6F7261293A2F2E7465737428653D657C7C2222297C7C21782E7465737428652926';
wwv_flow_imp.g_varchar2_table(84) := '262F5B23305D2F2E746573742865297D76617220453D5B22222C22554E222C22444F53222C2254524553222C2243554154524F222C2243494E434F222C2253454953222C225349455445222C224F43484F222C224E55455645222C224449455A222C224F';
wwv_flow_imp.g_varchar2_table(85) := '4E4345222C22444F4345222C225452454345222C224341544F524345222C225155494E4345222C22444945434953C3894953222C2244494543495349455445222C2244494543494F43484F222C2244494543494E55455645222C225645494E5445222C22';
wwv_flow_imp.g_varchar2_table(86) := '5645494E5449C39A4E222C225645494E544944C39353222C225645494E54495452C38953222C225645494E544943554154524F222C225645494E544943494E434F222C225645494E544953C3894953222C225645494E54495349455445222C225645494E';
wwv_flow_imp.g_varchar2_table(87) := '54494F43484F222C225645494E54494E55455645225D2C433D5B22222C22222C22222C22545245494E5441222C2243554152454E5441222C2243494E4355454E5441222C22534553454E5441222C22534554454E5441222C224F4348454E5441222C224E';
wwv_flow_imp.g_varchar2_table(88) := '4F56454E5441225D2C543D5B22222C224349454E544F222C22444F534349454E544F53222C22545245534349454E544F53222C2243554154524F4349454E544F53222C225155494E49454E544F53222C22534549534349454E544F53222C225345544543';
wwv_flow_imp.g_varchar2_table(89) := '49454E544F53222C224F43484F4349454E544F53222C224E4F56454349454E544F53225D3B66756E6374696F6E20412865297B6966283130303D3D3D652972657475726E224349454E223B76617220743D4D6174682E666C6F6F7228652F313030292C72';
wwv_flow_imp.g_varchar2_table(90) := '3D65253130302C6E3D5B5D3B72657475726E207426266E2E7075736828545B745D292C7226266E2E7075736828723C33303F455B725D3A435B4D6174682E666C6F6F7228722F3130295D2B28722531303F22205920222B455B722531305D3A222229292C';
wwv_flow_imp.g_varchar2_table(91) := '6E2E6A6F696E28222022297D66756E6374696F6E207A2865297B696628303D3D3D652972657475726E224345524F223B76617220743D5B5D3B5B5B316531322C2242494C4CC3934E222C2242494C4C4F4E4553225D2C5B3165362C224D494C4CC3934E22';
wwv_flow_imp.g_varchar2_table(92) := '2C224D494C4C4F4E4553225D5D2E666F72456163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E7075736828313D3D3D6E3F22554E20222B725B315D3A7A286E292B2220222B725B325D';
wwv_flow_imp.g_varchar2_table(93) := '292C652D3D6E2A725B305D297D293B76617220723D4D6174682E666C6F6F7228652F316533292C6E3D65253165333B72657475726E20722626742E7075736828313D3D3D723F224D494C223A412872292B22204D494C22292C6E2626742E707573682841';
wwv_flow_imp.g_varchar2_table(94) := '286E29292C742E6A6F696E28222022297D66756E6374696F6E206B28652C742C72297B766172206E3D537472696E672874292E746F55707065724361736528292C6F3D6E2E696E6465784F6628222E22293B6966286F3E30297B766172206C3D6E2E7375';
wwv_flow_imp.g_varchar2_table(95) := '6273747228302C6F292C613D6E2E737562737472286F2B31293B69662822444F43223D3D3D6C2972657475726E20652E646F633F652E646F635B615D3A766F696420303B69662822504152414D223D3D3D6C2972657475726E20652E706172616D733F65';
wwv_flow_imp.g_varchar2_table(96) := '2E706172616D735B615D3A766F696420303B696628224954454D223D3D3D6C2972657475726E2066756E6374696F6E2865297B7472797B72657475726E2077696E646F772E617065782626617065782E6974656D3F617065782E6974656D2865292E6765';
wwv_flow_imp.g_varchar2_table(97) := '7456616C756528293A22227D63617463682865297B72657475726E22227D7D2861293B76617220693D28652E535B6C5D7C7C5B5D295B305D3B72657475726E20693F695B615D3A766F696420307D72657475726E224E4F57223D3D3D6E3F7528293A2254';
wwv_flow_imp.g_varchar2_table(98) := '4F444159223D3D3D6E3F6328293A2250414745223D3D3D6E7C7C225041474553223D3D3D6E3F227B222B6E2B227D223A7226264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28722C6E293F725B6E5D3A652E';
wwv_flow_imp.g_varchar2_table(99) := '646F6326264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F652E646F635B6E5D3A652E706172616D733F652E706172616D735B6E5D3A766F696420307D66756E6374696F6E204D2865';
wwv_flow_imp.g_varchar2_table(100) := '2C742C72297B72657475726E206E756C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C28283F3A6D61736B7C6F7261293A5B5E7D5D2B7C5B412D5A612D7A302D393A2F';
wwv_flow_imp.g_varchar2_table(101) := 'C381C389C38DC393C39AC391C39CC3A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B7C5B5E7D5D2A5B23305D5B5E7D5D2A29293F5C7D2F672C66756E6374696F6E28652C6E2C6F297B766172206C3D6B28742C6E2C72293B72657475726E206E756C6C3D3D6C3F22';
wwv_flow_imp.g_varchar2_table(102) := '223A70286C2C6F297D297D66756E6374696F6E204E28652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E65786563';
wwv_flow_imp.g_varchar2_table(103) := '2865293B696628216E2972657475726E21313B766172206F3D6B28742C6E5B325D2C72293B696628216E5B335D297B766172206C3D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E223D3D3D6F293B72657475726E206E5B315D3F';
wwv_flow_imp.g_varchar2_table(104) := '216C3A6C7D76617220612C693D28613D28613D6E5B345D292E7472696D28292C2F5E272E2A27242F2E746573742861297C7C2F5E222E2A22242F2E746573742861293F612E736C69636528312C2D31293A226E756C6C223D3D3D613F6E756C6C3A22223D';
wwv_flow_imp.g_varchar2_table(105) := '3D3D617C7C69734E614E284E756D626572286129293F766F696420303A4E756D626572286129293B766F696420303D3D3D69262628693D6B28742C6E5B345D2E7472696D28292C7229293B76617220733D6E756C6C3D3D6F7C7C22223D3D3D6F3F6E756C';
wwv_flow_imp.g_varchar2_table(106) := '6C3D3D3D697C7C22223D3D3D693A537472696E67286F293D3D3D537472696E672869293B737769746368286E5B335D297B63617365223D3D223A72657475726E20733B6361736522213D223A72657475726E21733B63617365223E223A72657475726E20';
wwv_flow_imp.g_varchar2_table(107) := '4E756D626572286F293E4E756D6265722869293B63617365223C223A72657475726E204E756D626572286F293C4E756D6265722869293B63617365223E3D223A72657475726E204E756D626572286F293E3D4E756D6265722869293B63617365223C3D22';
wwv_flow_imp.g_varchar2_table(108) := '3A72657475726E204E756D626572286F293C3D4E756D6265722869297D72657475726E21317D66756E6374696F6E204628652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C282266756E6374696F6E223D3D747970656F6620';
wwv_flow_imp.g_varchar2_table(109) := '653F21216528722C74293A537472696E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E65766572792866756E6374696F6E2865297B72657475726E204E28652C';
wwv_flow_imp.g_varchar2_table(110) := '742C72297D297D29297D66756E6374696F6E205028652C74297B76617220723D742E535B537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C746572';
wwv_flow_imp.g_varchar2_table(111) := '2866756E6374696F6E2872297B72657475726E204628652E66696C7465722C742C72297D293A727D66756E6374696F6E204F28652C742C72297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F662065297265';
wwv_flow_imp.g_varchar2_table(112) := '7475726E20653B766172206E3D6B28742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E206A28652C742C72297B766172206E3D6E756C6C3B';
wwv_flow_imp.g_varchar2_table(113) := '72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E21214628652E7768656E2C742C72292626286E3D652C2130297D292C6E7D766172204C3D7B68656C7665746963613A5B2268656C766574696361222C224172';
wwv_flow_imp.g_varchar2_table(114) := '69616C225D2C617269616C3A5B2268656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E22';
wwv_flow_imp.g_varchar2_table(115) := '5D2C636F75726965723A5B22636F7572696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E20492865297B6966282128653D537472696E67286E756C6C';
wwv_flow_imp.g_varchar2_table(116) := '3D3D653F22223A65292E7472696D2829292972657475726E206E756C6C3B6966282F5E7777775C2E2F692E74657374286529262628653D2268747470733A2F2F222B65292C2F5E2868747470733F3A7C6D61696C746F3A7C74656C3A7C6674703A292F69';
wwv_flow_imp.g_varchar2_table(117) := '2E746573742865292972657475726E20652E7265706C616365282F202F672C2225323022293B6966282F5E5B412D5A612D7A5D5B412D5A612D7A302D392B2E2D5D2A3A2F2E746573742865292972657475726E206E756C6C3B7472797B69662877696E64';
wwv_flow_imp.g_varchar2_table(118) := '6F772E6C6F636174696F6E26262F5E68747470733F3A2F2E746573742877696E646F772E6C6F636174696F6E2E68726566292972657475726E206E65772055524C28652C77696E646F772E6C6F636174696F6E2E68726566292E687265667D6361746368';
wwv_flow_imp.g_varchar2_table(119) := '2865297B7D72657475726E206E756C6C7D66756E6374696F6E205228652C742C72297B72657475726E20652626652E687265663F49284D28652E687265662C742C7229293A6E756C6C7D66756E6374696F6E204428652C742C722C6E297B69662872297B';
wwv_flow_imp.g_varchar2_table(120) := '652E6C696E6B28742E782C742E792C742E77696474682C742E6865696768742C7B75726C3A727D293B766172206F3D41727261792E6973417272617928742E74657874293F742E746578743A5B742E746578745D3B6966282131213D3D6E26266F2E6A6F';
wwv_flow_imp.g_varchar2_table(121) := '696E28222229297B76617220613D652E696E7465726E616C2E676574466F6E7453697A6528292F652E696E7465726E616C2E7363616C65466163746F722C693D612A28652E6765744C696E65486569676874466163746F723F652E6765744C696E654865';
wwv_flow_imp.g_varchar2_table(122) := '69676874466163746F7228293A312E3135292C733D742E67657454657874506F7328292C753D742E7374796C65732E76616C69676E2C633D742E7374796C65732E68616C69676E2C663D732E792B612A28322D312E3135293B226D6964646C65223D3D3D';
wwv_flow_imp.g_varchar2_table(123) := '753F662D3D6F2E6C656E6774682F322A693A22626F74746F6D223D3D3D75262628662D3D6F2E6C656E6774682A69293B76617220643D742E7374796C65732E74657874436F6C6F723B69662841727261792E6973417272617928642929652E7365744472';
wwv_flow_imp.g_varchar2_table(124) := '6177436F6C6F7228645B305D2C645B315D2C645B325D293B656C73652069662822737472696E67223D3D747970656F66206426262F5E232F2E74657374286429297B76617220683D6C2864293B652E73657444726177436F6C6F7228685B305D2C685B31';
wwv_flow_imp.g_varchar2_table(125) := '5D2C685B325D297D656C736520652E73657444726177436F6C6F7228647C7C30293B652E7365744C696E655769647468282E3033352A61292C6F2E666F72456163682866756E6374696F6E28742C72297B766172206E3D652E676574537472696E67556E';
wwv_flow_imp.g_varchar2_table(126) := '6974576964746828537472696E67287429292A612C6F3D227269676874223D3D3D633F732E782D6E3A2263656E746572223D3D3D633F732E782D6E2F323A732E782C6C3D662B722A692B2E31372A613B6E3E302626652E6C696E65286F2C6C2C6F2B6E2C';
wwv_flow_imp.g_varchar2_table(127) := '6C297D297D7D7D66756E6374696F6E20552865297B72657475726E20653D537472696E6728657C7C2268656C76657469636122292E746F4C6F7765724361736528292C4C5B655D3F653A2268656C766574696361227D66756E6374696F6E204228652C74';
wwv_flow_imp.g_varchar2_table(128) := '297B76617220722C6F3D5B5D2C6C3D7B623A21312C693A21312C753A21312C733A21317D2C613D5B28743D747C7C7B7D292E666F6E747C7C2268656C766574696361225D2C693D5B742E636F6C6F727C7C6E756C6C5D2C733D5B5D2C753D22222C633D30';
wwv_flow_imp.g_varchar2_table(129) := '3B66756E6374696F6E206628297B69662875297B76617220653D735B732E6C656E6774682D315D2C723D695B692E6C656E6774682D315D3B652626652E75726C2626692E6C656E6774683C3D652E6364262628723D742E6C696E6B7C7C6E2E6C696E6B29';
wwv_flow_imp.g_varchar2_table(130) := '2C6F2E70757368287B743A752C623A6C2E622C693A6C2E692C753A6C2E757C7C212821657C7C21652E75726C292C733A6C2E732C663A5528615B612E6C656E6774682D315D292C633A722C683A653F652E75726C3A6E756C6C7D292C753D22227D7D666F';
wwv_flow_imp.g_varchar2_table(131) := '7228653D537472696E67286E756C6C3D3D653F22223A65293B633C652E6C656E6774683B297B76617220643D652E7375627374722863293B225C5C223D3D3D642E6368617241742830292626642E6C656E6774683E313F28752B3D642E63686172417428';
wwv_flow_imp.g_varchar2_table(132) := '31292C632B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286429293F286628292C612E7075736828725B315D292C632B3D725B305D2E6C656E677468293A225B2F665D22213D3D642E73756273747228302C34293F28';
wwv_flow_imp.g_varchar2_table(133) := '723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286429293F286628292C692E7075736828725B315D292C632B3D725B305D2E6C656E677468293A225B2F635D22213D3D642E73756273747228302C34293F28723D';
wwv_flow_imp.g_varchar2_table(134) := '2F5E5C5B613D285B5E5C5D5C735D2A295C5D2F2E65786563286429293F286628292C732E70757368287B75726C3A4928725B315D292C63643A692E6C656E6774687D292C632B3D725B305D2E6C656E677468293A225B2F615D22213D3D642E7375627374';
wwv_flow_imp.g_varchar2_table(135) := '7228302C34293F222A2A2A22213D3D642E73756273747228302C33293F222A2A22213D3D642E73756273747228302C32293F227E7E22213D3D642E73756273747228302C32293F222B2B22213D3D642E73756273747228302C32293F222A22213D3D642E';
wwv_flow_imp.g_varchar2_table(136) := '6368617241742830293F28752B3D642E6368617241742830292C632B2B293A286628292C6C2E693D216C2E692C632B3D31293A286628292C6C2E753D216C2E752C632B3D32293A286628292C6C2E733D216C2E732C632B3D32293A286628292C6C2E623D';
wwv_flow_imp.g_varchar2_table(137) := '216C2E622C632B3D32293A286628292C6C2E623D216C2E622C6C2E693D216C2E692C632B3D33293A286628292C732E706F7028292C632B3D34293A286628292C692E6C656E6774683E312626692E706F7028292C632B3D34293A286628292C612E6C656E';
wwv_flow_imp.g_varchar2_table(138) := '6774683E312626612E706F7028292C632B3D34297D72657475726E206628292C6F7D66756E6374696F6E205F28652C74297B76617220723D652E736F757263653F5028652C74295B305D3A6E756C6C3B72657475726E2841727261792E69734172726179';
wwv_flow_imp.g_varchar2_table(139) := '28652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C697428225C6E2229292E6D61702866756E6374696F6E2865297B72657475726E204D28652C742C72297D297D66756E';
wwv_flow_imp.g_varchar2_table(140) := '6374696F6E204728652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6C3D742E545B6E5D7C7C7B7D2C613D652E636F6C756D6E733B72657475726E20612626612E6C656E6774687C';
wwv_flow_imp.g_varchar2_table(141) := '7C28613D4F626A6563742E6B657973286C292E66696C7465722866756E6374696F6E2865297B72657475726E22444F435F4B455922213D3D657D292E6D61702866756E6374696F6E2865297B72657475726E7B636F6C3A657D7D29292C28613D612E6669';
wwv_flow_imp.g_varchar2_table(142) := '6C7465722866756E6374696F6E2865297B72657475726E22737472696E67223D3D747970656F6620657C7C21652E7768656E7C7C4628652E7768656E2C742C6E756C6C297D29292E6D61702866756E6374696F6E2865297B76617220743D28653D227374';
wwv_flow_imp.g_varchar2_table(143) := '72696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C292E746F55707065724361736528293A6E756C6C2C6E3D743F6C5B745D3A6E756C6C2C613D652E666D743B617C7C224E554D42455222213D3D';
wwv_flow_imp.g_varchar2_table(144) := '6E7C7C652E76616C75657C7C28613D722E736F6D652866756E6374696F6E2865297B72657475726E206F28655B745D2926264D6174682E726F756E6428655B745D29213D3D655B745D7D293F226D6F6E6579223A6E756C6C293B76617220693D652E6365';
wwv_flow_imp.g_varchar2_table(145) := '6C6C2626565B652E63656C6C2E747970655D3F652E63656C6C3A6E756C6C3B72657475726E7B636F6C3A742C76616C75653A766F69642030213D3D652E76616C75653F652E76616C75653A652E63656C6C262622746578746F223D3D3D652E63656C6C2E';
wwv_flow_imp.g_varchar2_table(146) := '747970653F652E63656C6C2E746578743A766F696420302C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628747C7C2222292C63656C6C3A692C76616C69676E3A2F5E28746F707C6D6964646C657C626F74746F6D2924';
wwv_flow_imp.g_varchar2_table(147) := '2F2E7465737428537472696E6728652E76616C69676E7C7C2222292E746F4C6F776572436173652829293F537472696E6728652E76616C69676E292E746F4C6F7765724361736528293A6E756C6C2C666D743A612C6D61703A652E6D61702C626F6C643A';
wwv_flow_imp.g_varchar2_table(148) := '2121652E626F6C642C77696474683A652E77696474682C616C69676E3A652E616C69676E7C7C28693F2263656E746572223A6E756C6C297C7C28672861293F226C656674223A224E554D424552223D3D3D6E7C7C226D6F6E6579223D3D3D617C7C22696E';
wwv_flow_imp.g_varchar2_table(149) := '74223D3D3D617C7C226E756D223D3D3D617C7C532861293F227269676874223A2244415445223D3D3D6E7C7C2264617465223D3D3D613F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63656C6C5374796C652C636F6C6F723A';
wwv_flow_imp.g_varchar2_table(150) := '652E636F6C6F722C68656164416C69676E3A652E68656164416C69676E2C687265663A652E687265667C7C652E63656C6C2626652E63656C6C2E687265667C7C6E756C6C2C69734E756D3A216926262167286129262628224E554D424552223D3D3D6E26';
wwv_flow_imp.g_varchar2_table(151) := '2621652E6D6170262621652E76616C75657C7C226D6F6E6579223D3D3D617C7C22696E74223D3D3D617C7C2F5E6E756D2F2E7465737428617C7C2222297C7C53286129297D7D297D66756E6374696F6E205728652C74297B76617220723D5B5D2C6E3D30';
wwv_flow_imp.g_varchar2_table(152) := '3B72657475726E28652E67726F7570737C7C5B5D292E666F72456163682866756E6374696F6E2865297B766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E6774';
wwv_flow_imp.g_varchar2_table(153) := '68262628722E70757368287B6C6162656C3A652E6C6162656C7C7C22222C636F6C733A6F2C66726F6D3A6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C73';
wwv_flow_imp.g_varchar2_table(154) := '3A742E6C656E6774682D6E2C66726F6D3A6E2C6761703A21307D292C727D66756E6374696F6E204828652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E204D28652E76616C75652C722C74293B766172206E3D745B652E';
wwv_flow_imp.g_varchar2_table(155) := '636F6C5D3B72657475726E20652E6D617026266E756C6C213D6E2626766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E202428652C742C72297B766172206E3D4828652C742C72293B72657475726E20652E6D';
wwv_flow_imp.g_varchar2_table(156) := '61702626766F69642030213D3D652E6D61705B745B652E636F6C5D5D3F537472696E67286E293A70286E2C652E666D74297D76617220563D7B636F6469676F3A312C696D6167656E3A312C6772616669636F3A317D3B66756E6374696F6E20592865297B';
wwv_flow_imp.g_varchar2_table(157) := '76617220742C723D7B7D3B666F72287420696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C7429262628725B745D3D655B745D293B72657475726E20727D66756E6374696F6E207128652C74';
wwv_flow_imp.g_varchar2_table(158) := '297B76617220723D537472696E6728652E76616C69676E7C7C2222292E746F4C6F7765724361736528293B72657475726E22746F70223D3D3D727C7C226D6964646C65223D3D3D727C7C22626F74746F6D223D3D3D723F723A742E736F6D652866756E63';
wwv_flow_imp.g_varchar2_table(159) := '74696F6E2865297B72657475726E20652E63656C6C7D293F226D6964646C65223A6E756C6C7D66756E6374696F6E205A28652C742C722C6E297B766172206F3D652E63656C6C3B696628216F2972657475726E206E756C6C3B69662822636F6469676F22';
wwv_flow_imp.g_varchar2_table(160) := '3D3D3D6F2E74797065297B766172206C3D59286F293B6C2E73697A657C7C286C2E73697A653D3134292C6C2E77696474687C7C286C2E77696474683D3330292C6C2E6865696768747C7C286C2E6865696768743D38293B76617220613D7974286C2C722C';
wwv_flow_imp.g_varchar2_table(161) := '74293B69662821612972657475726E206E756C6C3B76617220693D78742861293B72657475726E7B696D3A692C773A692E776D6D2C683A692E686D6D7D7D69662822696D6167656E223D3D3D6F2E74797065297B76617220733D6F2E6669656C643F745B';
wwv_flow_imp.g_varchar2_table(162) := '537472696E67286F2E6669656C64292E746F55707065724361736528295D3A6E756C6C2C753D6E756C6C3B7472797B753D733F73742873293A6F2E75726C2626216F2E6669656C643F72745B6F74284D286F2E75726C2C722C7429295D3A6E756C6C7D63';
wwv_flow_imp.g_varchar2_table(163) := '617463682865297B77696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B6F2E6669656C642C65297D69662821752972657475726E206E756C6C';
wwv_flow_imp.g_varchar2_table(164) := '3B76617220633D6374287B77696474683A6F2E77696474687C7C286F2E6865696768743F766F696420303A3135292C6865696768743A6F2E6865696768747D2C75293B72657475726E7B696D3A752C773A632E772C683A632E687D7D76617220663D5928';
wwv_flow_imp.g_varchar2_table(165) := '6F293B64656C65746520662E66696C7465722C64656C65746520662E6C696E6B2C662E77696474687C7C28662E77696474683D3430292C662E6865696768747C7C28662E6865696768743D3135293B76617220643D457428662C66756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(166) := '2C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6F3D652E6C696E6B7C7C7B7D2C6C3D652E66696C7465723F4D28652E66696C7465722C742C72293A6E756C6C2C613D28742E535B6E';
wwv_flow_imp.g_varchar2_table(167) := '5D7C7C5B5D292E66696C7465722866756E6374696F6E2865297B666F7228766172206E20696E206F296966284F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C286F2C6E292626537472696E6728655B6E2E746F';
wwv_flow_imp.g_varchar2_table(168) := '55707065724361736528295D29213D3D537472696E6728725B537472696E67286F5B6E5D292E746F55707065724361736528295D292972657475726E21313B72657475726E216C7C7C46286C2C742C65297D292C693D592874293B72657475726E20692E';
wwv_flow_imp.g_varchar2_table(169) := '533D5928742E53292C692E535B6E5D3D612C697D286F2C722C74292C6E293B72657475726E20643F7B696D3A642C773A642E776D6D2C683A642E686D6D7D3A6E756C6C7D76617220583D7B666F726D756C6172696F3A312C66696368613A312C7461726A';
wwv_flow_imp.g_varchar2_table(170) := '657461733A317D3B66756E6374696F6E204A2865297B76617220743D5B5D3B72657475726E28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B696628652626585B652E747970655D262628652E6669656C64737C7C5B5D292E736F6D';
wwv_flow_imp.g_varchar2_table(171) := '652866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29297B76617220723D6E756C6C2C6E3D302C6F3D66756E6374696F6E28297B722626722E6669656C64732E6C656E6774682626742E707573682872292C723D6E756C6C7D';
wwv_flow_imp.g_varchar2_table(172) := '3B652E6669656C64732E666F72456163682866756E6374696F6E286C297B6966286C26266C2E626C6F636B297B76617220613D6C2E626C6F636B3B69662821617C7C215A655B612E747970655D7C7C22666F726D756C6172696F223D3D3D612E74797065';
wwv_flow_imp.g_varchar2_table(173) := '2972657475726E3B72657475726E206F28292C2128613D59286129292E736F757263652626652E736F757263652626226C696E656122213D3D612E747970652626226573706163696F22213D3D612E74797065262628612E736F757263653D652E736F75';
wwv_flow_imp.g_varchar2_table(174) := '726365292C6C2E7768656E262621612E7768656E262628612E7768656E3D6C2E7768656E292C6E7C7C21652E7469746C657C7C227461626C6122213D3D612E747970657C7C612E7469746C657C7C28612E7469746C653D652E7469746C65292C742E7075';
wwv_flow_imp.g_varchar2_table(175) := '73682861292C766F6964206E2B2B7D727C7C2828723D59286529292E6669656C64733D5B5D2C6E262664656C65746520722E7469746C652C6E2B2B292C722E6669656C64732E70757368286C297D292C6F28297D656C736520742E707573682865297D29';
wwv_flow_imp.g_varchar2_table(176) := '2C747D766172204B3D7B73756D3A392C6176673A312C6D696E3A352C6D61783A342C636F756E743A337D2C513D7B73756D3A2253554D222C6176673A2241564552414745222C6D696E3A224D494E222C6D61783A224D4158222C636F756E743A22434F55';
wwv_flow_imp.g_varchar2_table(177) := '4E5441227D2C65653D7B6176673A2250726F6D2E222C6D696E3A224DC3AD6E2E222C6D61783A224DC3A1782E222C636F756E743A2243616E742E227D3B66756E6374696F6E2074652865297B72657475726E2841727261792E697341727261792865293F';
wwv_flow_imp.g_varchar2_table(178) := '653A5B5D292E6D61702866756E6374696F6E2865297B76617220743D652626226F626A656374223D3D747970656F6620653F653A7B636F6C3A657D2C723D537472696E6728742E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475';
wwv_flow_imp.g_varchar2_table(179) := '726E7B636F6C3A537472696E6728742E636F6C7C7C2222292E746F55707065724361736528292C666E3A4B5B725D3F723A2273756D227D7D292E66696C7465722866756E6374696F6E2865297B72657475726E20652E636F6C7D297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(180) := '20726528652C74297B666F722876617220723D303B723C652E6C656E6774683B722B2B29696628655B725D2E636F6C3D3D3D742972657475726E20655B725D3B72657475726E206E756C6C7D66756E6374696F6E206E652865297B72657475726E20652E';
wwv_flow_imp.g_varchar2_table(181) := '736F6D652866756E6374696F6E2865297B72657475726E2273756D22213D3D652E666E7D297D66756E6374696F6E206F652865297B72657475726E206F2865297C7C22737472696E67223D3D747970656F66206526262222213D3D652E7472696D282926';
wwv_flow_imp.g_varchar2_table(182) := '262169734E614E284E756D626572286529297D66756E6374696F6E206C6528652C742C72297B766172206E3D652E6D61702866756E6374696F6E2865297B72657475726E20655B745D7D292E66696C7465722866756E6374696F6E2865297B7265747572';
wwv_flow_imp.g_varchar2_table(183) := '6E206E756C6C213D6526262222213D3D657D293B69662822636F756E74223D3D3D722972657475726E206E2E6C656E6774683B6966282273756D223D3D3D727C7C22617667223D3D3D72297B766172206F3D6E2E66696C746572286F65292E6D6170284E';
wwv_flow_imp.g_varchar2_table(184) := '756D626572292C6C3D6F2E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30293B72657475726E2273756D223D3D3D723F6C3A6F2E6C656E6774683F6C2F6F2E6C656E6774683A6E756C6C7D76617220613D6E756C6C';
wwv_flow_imp.g_varchar2_table(185) := '2C693D6E756C6C3B72657475726E206E2E666F72456163682866756E6374696F6E2865297B76617220743D6F652865293F6E756C6C3A642865292C6E3D6F652865293F4E756D6265722865293A743F742E67657454696D6528293A537472696E67286529';
wwv_flow_imp.g_varchar2_table(186) := '3B286E756C6C3D3D3D697C7C28226D696E223D3D3D723F6E3C693A6E3E692929262628613D652C693D6E297D292C617D66756E6374696F6E20616528652C742C722C6E297B766172206F3D6E652874292C6C3D2D312C613D652E6D61702866756E637469';
wwv_flow_imp.g_varchar2_table(187) := '6F6E28652C6E297B76617220613D652E636F6C3F726528742C652E636F6C293A6E756C6C3B72657475726E206126266C3C302626286C3D6E292C613F66756E6374696F6E28652C742C722C6E297B766172206F2C6C3D6C6528722C742E636F6C2C742E66';
wwv_flow_imp.g_varchar2_table(188) := '6E293B72657475726E286F3D6E756C6C3D3D6C3F22223A22636F756E74223D3D3D742E666E3F70286C2C22696E7422293A226D696E223D3D3D742E666E7C7C226D6178223D3D3D742E666E3F6F65286C293F70286C2C652E666D747C7C226D6F6E657922';
wwv_flow_imp.g_varchar2_table(189) := '293A70286C2C652E666D74293A22617667223D3D3D742E666E3F70286C2C652E666D74262622696E7422213D3D652E666D743F652E666D743A226D6F6E657922293A70286C2C652E666D747C7C226D6F6E657922292926266E262665655B742E666E5D3F';
wwv_flow_imp.g_varchar2_table(190) := '65655B742E666E5D2B2220222B6F3A6F7D28652C612C722C6F293A22227D293B72657475726E7B61743A6C3C303F652E6C656E6774683A6C2C63656C6C733A612C746578743A6E7D7D66756E6374696F6E20696528652C742C72297B72657475726E204D';
wwv_flow_imp.g_varchar2_table(191) := '28652E746F74616C734C6162656C7C7C22546F74616C6573222C742C7B434F554E543A722E6C656E6774687D297D66756E6374696F6E20736528652C74297B76617220723D7B636F6E74656E743A652E746578742C636F6C5370616E3A652E61747C7C74';
wwv_flow_imp.g_varchar2_table(192) := '2C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E20303D3D3D652E61743F5B5B725D2C652E63656C6C732E736C69636528295D3A5B5B725D2E636F6E63617428652E63656C6C732E736C69636528652E617429295D7D66756E';
wwv_flow_imp.g_varchar2_table(193) := '6374696F6E2075652865297B72657475726E21313D3D3D652E627265616B546F74616C733F5B5D3A74652841727261792E6973417272617928652E627265616B546F74616C73293F652E627265616B546F74616C733A652E746F74616C73297D66756E63';
wwv_flow_imp.g_varchar2_table(194) := '74696F6E20636528652C74297B69662821652E627265616B42797C7C21742E6C656E6774682972657475726E20742E6D61702866756E6374696F6E28652C74297B72657475726E7B6B3A22726F77222C723A652C693A747D7D293B76617220723D537472';
wwv_flow_imp.g_varchar2_table(195) := '696E6728652E627265616B4279292E746F55707065724361736528292C6E3D5B5D2C6F3D6E756C6C2C6C3D302C613D75652865292E6C656E6774683E303B66756E6374696F6E206928297B6F26266126266E2E70757368287B6B3A22737562222C723A6F';
wwv_flow_imp.g_varchar2_table(196) := '2E722C726F77733A6F2E726F77737D297D72657475726E20742E666F72456163682866756E6374696F6E2874297B76617220613D537472696E67286E756C6C3D3D3D745B725D7C7C766F696420303D3D3D745B725D3F22223A745B725D293B6F26266F2E';
wwv_flow_imp.g_varchar2_table(197) := '6B65793D3D3D617C7C286928292C6F3D7B6B65793A612C723A742C726F77733A5B5D7D2C2131213D3D652E627265616B5469746C6526266E2E70757368287B6B3A2268656164222C723A742C726F77733A6F2E726F77737D29292C6F2E726F77732E7075';
wwv_flow_imp.g_varchar2_table(198) := '73682874292C6E2E70757368287B6B3A22726F77222C723A742C693A6C2B2B7D297D292C6928292C6E7D66756E6374696F6E20666528652C742C72297B766172206E2C6F3D7B7D2C6C3D537472696E6728652E627265616B4279292E746F557070657243';
wwv_flow_imp.g_varchar2_table(199) := '61736528293B666F72286E20696E20742E72296F5B6E5D3D742E725B6E5D3B6F2E434F554E543D742E726F77732E6C656E6774683B76617220613D2268656164223D3D3D742E6B3F652E627265616B5469746C653A652E627265616B4C6162656C3B7265';
wwv_flow_imp.g_varchar2_table(200) := '7475726E206E756C6C213D6126262130213D3D617C7C28613D2268656164223D3D3D742E6B3F227B222B6C2B227D223A22537562746F74616C207B222B6C2B227D22292C4D28612C722C6F297D66756E6374696F6E20646528652C742C72297B69662865';
wwv_flow_imp.g_varchar2_table(201) := '2E6D6170297B766172206E3D6B28742C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C2222292E73706C697428227C22295B305D2C72293B72657475726E20766F69642030213D3D652E6D61705B6E5D3F652E6D61705B';
wwv_flow_imp.g_varchar2_table(202) := '6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E7D7C5D2B5C7D242F2E74657374286F7C7C2222293F70286B28742C6F2E736C69636528312C2D31292C72292C652E666D74';
wwv_flow_imp.g_varchar2_table(203) := '293A4D286F2C742C72297D7661722068653D7B746578743A312C6D756C74696C696E653A312C6C6973743A312C636865636B626F783A317D2C70653D2223463246364641222C67653D2223424643394434222C6D653D22E29892222C76653D22E2989022';
wwv_flow_imp.g_varchar2_table(204) := '3B66756E6374696F6E2062652865297B76617220743D537472696E67286E756C6C3D3D653F22223A65293B696628212F5E5B412D5A612D7A5F5D5B412D5A612D7A302D395F5D7B302C33397D242F2E746573742874297C7C2F5E5B412D5A612D7A5D7B31';
wwv_flow_imp.g_varchar2_table(205) := '2C337D5B302D395D2B242F2E746573742874297C7C2F5E5B527243635D242F2E746573742874297C7C2F5E5B52725D5B302D395D2A5B43635D5B302D395D2A242F2E74657374287429297468726F77206E6577204572726F7228274E6F6D627265206465';
wwv_flow_imp.g_varchar2_table(206) := '2063616D706F20696E76C3A16C69646F3A2022272B742B27222E20557365206C65747261732C206EC3BA6D65726F732079205F202868617374612034302C2073696E206573706163696F73206E692070756E746F7329207920717565206E6F2070617265';
wwv_flow_imp.g_varchar2_table(207) := '7A636120756E612063656C646120646520457863656C202841312C2052314331292E27293B72657475726E20747D66756E6374696F6E20776528297B76617220653D7B7D3B72657475726E2066756E6374696F6E2874297B76617220723D742E746F4C6F';
wwv_flow_imp.g_varchar2_table(208) := '7765724361736528293B696628655B725D297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F20726570657469646F20656E20656C20646F63756D656E746F3A2022272B742B27222E27293B72657475726E20655B725D3D';
wwv_flow_imp.g_varchar2_table(209) := '312C747D7D66756E6374696F6E20796528652C742C72297B766172206E3D5028652C74295B305D7C7C7B7D3B72657475726E28652E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E7768';
wwv_flow_imp.g_varchar2_table(210) := '656E7C7C4628652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E286F297B6966286F2E656D7074792972657475726E7B656D7074793A21302C7370616E3A6F2E7370616E7D3B766172206C3D537472696E67286F2E696E7075747C7C22';
wwv_flow_imp.g_varchar2_table(211) := '7465787422292E746F4C6F7765724361736528293B6966282168655B6C5D297468726F77206E6577204572726F7228275469706F2064652063616D706F206E6F20736F706F727461646F3A2022272B6F2E696E7075742B27222028746578742C206D756C';
wwv_flow_imp.g_varchar2_table(212) := '74696C696E652C206C6973742C20636865636B626F78292E27293B76617220613D6265286F2E6E616D65292B28727C7C2222292C693D766F696420303D3D3D6F2E76616C75657C7C6E756C6C3D3D3D6F2E76616C75653F22223A537472696E6728646528';
wwv_flow_imp.g_varchar2_table(213) := '6F2C742C6E29292C733D226C697374223D3D3D6C3F66756E6374696F6E28652C74297B76617220723D5B5D3B66756E6374696F6E206E2865297B2222213D3D28653D537472696E67286E756C6C3D3D653F22223A6529292626722E696E6465784F662865';
wwv_flow_imp.g_varchar2_table(214) := '293C302626722E707573682865297D6966282841727261792E6973417272617928652E6F7074696F6E73293F652E6F7074696F6E733A5B5D292E666F7245616368286E292C652E6F7074696F6E7346726F6D297B766172206F3D537472696E6728652E6F';
wwv_flow_imp.g_varchar2_table(215) := '7074696F6E7346726F6D292E73706C697428222E22292C6C3D6F5B315D3F6F5B315D2E746F55707065724361736528293A6E756C6C3B50287B736F757263653A6F5B305D7D2C74292E666F72456163682866756E6374696F6E2865297B6E286C3F655B6C';
wwv_flow_imp.g_varchar2_table(216) := '5D3A655B4F626A6563742E6B6579732865295B305D5D297D297D72657475726E20727D286F2C74293A5B5D3B696628226C697374223D3D3D6C262621732E6C656E677468297468726F77206E6577204572726F722827456C2063616D706F2022272B612B';
wwv_flow_imp.g_varchar2_table(217) := '272220657320756E61206C697374612073696E206F7063696F6E657320286F7074696F6E732075206F7074696F6E7346726F6D292E27293B76617220752C633D282274657874223D3D3D6C7C7C226D756C74696C696E65223D3D3D6C2926264E756D6265';
wwv_flow_imp.g_varchar2_table(218) := '72286F2E6D61784C656E677468293E303F4D6174682E666C6F6F72284E756D626572286F2E6D61784C656E67746829293A303B72657475726E226D756C74696C696E6522213D3D6C262628693D692E7265706C616365282F5C723F5C6E2F672C22202229';
wwv_flow_imp.g_varchar2_table(219) := '292C226C697374223D3D3D6C2626732E696E6465784F662869293C30262628693D2222292C63262628693D692E73756273747228302C6329292C7B6C6162656C3A4D286F2E6C6162656C2C742C6E292C6E616D653A612C696E7075743A6C2C6F7074696F';
wwv_flow_imp.g_varchar2_table(220) := '6E733A732C76616C75653A22636865636B626F78223D3D3D6C3F22223A692C636865636B65643A22636865636B626F78223D3D3D6C262628753D692C21303D3D3D757C7C2F5E28737C73697C73C3AD7C797C7965737C317C787C747275657C6F6E29242F';
wwv_flow_imp.g_varchar2_table(221) := '692E7465737428537472696E67286E756C6C3D3D753F22223A75292E7472696D282929292C6D61784C656E6774683A632C726561644F6E6C793A21303D3D3D6F2E726561644F6E6C792C6C696E65733A226D756C74696C696E65223D3D3D6C3F4D617468';
wwv_flow_imp.g_varchar2_table(222) := '2E6D617828322C4D6174682E6D696E2832302C4E756D626572286F2E6C696E6573297C7C3329293A312C706C616365686F6C6465723A6F2E706C616365686F6C6465723F4D286F2E706C616365686F6C6465722C742C6E293A22222C7370616E3A6F2E73';
wwv_flow_imp.g_varchar2_table(223) := '70616E2C6C61623A4465286F2C65297D7D297D66756E6374696F6E20786528652C74297B76617220723D652E666F726D7C7C7B7D2C6E3D742626766F69642030213D3D742E666F726D50617373776F726426266E756C6C213D3D742E666F726D50617373';
wwv_flow_imp.g_varchar2_table(224) := '776F72643F742E666F726D50617373776F72643A722E70617373776F72643B72657475726E7B70726F746563743A2131213D3D722E70726F746563742C70617373776F72643A6E3F537472696E67286E293A22227D7D66756E6374696F6E205365286529';
wwv_flow_imp.g_varchar2_table(225) := '7B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E206526262822666F726D756C6172696F223D3D3D652E747970657C7C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E';
wwv_flow_imp.g_varchar2_table(226) := '736F6D65285365297C7C22677275706F223D3D3D652E747970652626536528652E73656374696F6E7329297D297D66756E6374696F6E2045652865297B76617220743D652626652E62617463682626652E62617463682E73756D6D6172793B7265747572';
wwv_flow_imp.g_varchar2_table(227) := '6E20536528652626652E73656374696F6E73297C7C212821747C7C2128536528742E73656374696F6E73297C7C742E6C61796F75742626536528742E6C61796F75742E73656374696F6E732929297D7661722043653D5B313131363335323430382C3336';
wwv_flow_imp.g_varchar2_table(228) := '30393736373435382C313839393434373434312C3630323839313732352C333034393332333437312C333936343438343339392C333932313030393537332C323137333239353534382C3936313938373136332C343038313632383437322C3135303839';
wwv_flow_imp.g_varchar2_table(229) := '37303939332C333035333833343236352C323435333633353734382C323933373637313537392C323837303736333232312C333636343630393536302C333632343338313038302C323733343838333339342C3331303539383430312C31313634393936';
wwv_flow_imp.g_varchar2_table(230) := '3534322C3630373232353237382C313332333631303736342C313432363838313938372C333539303330343939342C313932353037383338382C343036383138323338332C323136323037383230362C3939313333363131332C32363134383838313033';
wwv_flow_imp.g_varchar2_table(231) := '2C3633333830333331372C333234383232323538302C333437393737343836382C333833353339303430312C323636363631333435382C343032323232343737342C3934343731313133392C3236343334373037382C323334313236323737332C363034';
wwv_flow_imp.g_varchar2_table(232) := '3830373632382C323030373830303933332C3737303235353938332C313439353939303930312C313234393135303132322C313835363433313233352C313535353038313639322C333137353231383133322C313939363036343938362C323139383935';
wwv_flow_imp.g_varchar2_table(233) := '303833372C323535343232303838322C333939393731393333392C323832313833343334392C3736363738343031362C323935323939363830382C323536363539343837392C333231303331333637312C333230333333373935362C3333333635373138';
wwv_flow_imp.g_varchar2_table(234) := '39312C313033343435373032362C333538343532383731312C323436363934383930312C3131333932363939332C333735383332363338332C3333383234313839352C3136383731373933362C3636363330373230352C313138383137393936342C3737';
wwv_flow_imp.g_varchar2_table(235) := '333532393931322C313534363034353733342C313239343735373337322C313532323830353438352C313339363138323239312C323634333833333832332C313639353138333730302C323334333532373339302C313938363636313035312C31303134';
wwv_flow_imp.g_varchar2_table(236) := '3437373438302C323137373032363335302C313230363735393134322C323435363935363033372C3334343037373632372C323733303438353932312C313239303836333436302C323832303330323431312C333135383435343237332C333235393733';
wwv_flow_imp.g_varchar2_table(237) := '303830302C333530353935323635372C333334353736343737312C3130363231373030382C333531363036353831372C333630363030383334342C333630303335323830342C313433323732353737362C343039343537313930392C3134363730333135';
wwv_flow_imp.g_varchar2_table(238) := '39342C3237353432333334342C3835313136393732302C3433303232373733342C333130303832333735322C3530363934383631362C313336333235383139352C3635393036303535362C333735303638353539332C3838333939373837372C33373835';
wwv_flow_imp.g_varchar2_table(239) := '3035303238302C3935383133393537312C333331383330373432372C313332323832323231382C333831323732333430332C313533373030323036332C323030333033343939352C313734373837333737392C333630323033363839392C313935353536';
wwv_flow_imp.g_varchar2_table(240) := '323232322C313537353939303031322C323032343130343831352C313132353539323932382C323232373733303435322C323731363930343330362C323336313835323432342C3434323737363034342C323432383433363437342C3539333639383334';
wwv_flow_imp.g_varchar2_table(241) := '342C323735363733343138372C333733333131303234392C333230343033313437392C323939393335313537332C333332393332353239382C333831353932303432372C333339313536393631342C333932383338333930302C33353135323637323731';
wwv_flow_imp.g_varchar2_table(242) := '2C3536363238303731312C333934303138373630362C333435343036393533342C343131383633303237312C343030303233393939322C3131363431383437342C313931343133383535342C3137343239323432312C323733313035353237302C323839';
wwv_flow_imp.g_varchar2_table(243) := '3338303335362C333230333939333030362C3436303339333236392C3332303632303331352C3638353437313733332C3538373439363833362C3835323134323937312C313038363739323835312C313031373033363239382C3336353534333130302C';
wwv_flow_imp.g_varchar2_table(244) := '313132363030303538302C323631383239373637362C313238383033333437302C333430393835353135382C313530313530353934382C343233343530393836362C313630373136373931352C3938373136373436382C313831363430323331362C3132';
wwv_flow_imp.g_varchar2_table(245) := '34363138393539315D3B66756E6374696F6E2054652865297B76617220742C722C6E3D5B313737393033333730332C343038393233353732302C333134343133343237372C323232373837333539352C313031333930343234322C343237313137353732';
wwv_flow_imp.g_varchar2_table(246) := '332C323737333438303736322C313539353735303132392C313335393839333131392C323931373536353133372C323630303832323932342C3732353531313139392C3532383733343633352C343231353338393534372C313534313435393232352C33';
wwv_flow_imp.g_varchar2_table(247) := '32373033333230395D2C6F3D652E6C656E6774682C6C3D6F2B31372B3132373E3E373C3C372C613D6E65772055696E74384172726179286C292C693D6E657720496E743332417272617928313630293B612E7365742865292C615B6F5D3D3132383B7661';
wwv_flow_imp.g_varchar2_table(248) := '7220733D382A6F3B615B6C2D315D3D32353526732C615B6C2D325D3D733E3E3E38263235352C615B6C2D335D3D733E3E3E3136263235352C615B6C2D345D3D733E3E3E3234263235352C615B6C2D355D3D323535264D6174682E666C6F6F7228732F3432';
wwv_flow_imp.g_varchar2_table(249) := '3934393637323936293B666F722876617220753D343239343936373239362C633D303B633C6C3B632B3D313238297B666F7228743D303B743C33323B742B2B29723D632B342A742C695B745D3D615B725D3C3C32347C615B722B315D3C3C31367C615B72';
wwv_flow_imp.g_varchar2_table(250) := '2B325D3C3C387C615B722B335D3B666F7228743D33323B743C3136303B742B3D32297B76617220663D695B742D33305D2C643D695B742D32395D2C683D695B742D345D2C703D695B742D335D2C673D28663E3E3E317C643C3C3331295E28663E3E3E387C';
wwv_flow_imp.g_varchar2_table(251) := '643C3C3234295E663E3E3E372C6D3D28683E3E3E31397C703C3C3133295E28703E3E3E32397C683C3C33295E683E3E3E362C763D28703E3E3E31397C683C3C3133295E28683E3E3E32397C703C3C33295E28703E3E3E367C683C3C3236292C623D282828';
wwv_flow_imp.g_varchar2_table(252) := '643E3E3E317C663C3C3331295E28643E3E3E387C663C3C3234295E28643E3E3E377C663C3C323529293E3E3E30292B28695B742D31335D3E3E3E30292B28763E3E3E30292B28695B742D33315D3E3E3E30292C773D672B695B742D31345D2B6D2B695B74';
wwv_flow_imp.g_varchar2_table(253) := '2D33325D2B4D6174682E666C6F6F7228622F75297C303B695B745D3D772C695B742B315D3D307C627D76617220793D6E5B305D2C783D6E5B315D2C533D6E5B325D2C453D6E5B335D2C433D6E5B345D2C543D6E5B355D2C413D6E5B365D2C7A3D6E5B375D';
wwv_flow_imp.g_varchar2_table(254) := '2C6B3D6E5B385D2C4D3D6E5B395D2C4E3D6E5B31305D2C463D6E5B31315D2C503D6E5B31325D2C4F3D6E5B31335D2C6A3D6E5B31345D2C4C3D6E5B31355D3B666F7228743D303B743C3136303B742B3D32297B76617220493D286B3E3E3E31347C4D3C3C';
wwv_flow_imp.g_varchar2_table(255) := '3138295E286B3E3E3E31387C4D3C3C3134295E284D3E3E3E397C6B3C3C3233292C523D6B264E5E7E6B26502C443D284C3E3E3E30292B2828284D3E3E3E31347C6B3C3C3138295E284D3E3E3E31387C6B3C3C3134295E286B3E3E3E397C4D3C3C32332929';
wwv_flow_imp.g_varchar2_table(256) := '3E3E3E30292B28284D26465E7E4D264F293E3E3E30292B2843655B742B315D3E3E3E30292B28695B742B315D3E3E3E30292C553D6A2B492B522B43655B745D2B695B745D2B4D6174682E666C6F6F7228442F75297C303B447C3D303B76617220423D2828';
wwv_flow_imp.g_varchar2_table(257) := '28783E3E3E32387C793C3C34295E28793E3E3E327C783C3C3330295E28793E3E3E377C783C3C323529293E3E3E30292B28287826455E7826545E452654293E3E3E30292C5F3D2828793E3E3E32387C783C3C34295E28783E3E3E327C793C3C3330295E28';
wwv_flow_imp.g_varchar2_table(258) := '783E3E3E377C793C3C323529292B287926535E7926435E532643292B4D6174682E666C6F6F7228422F75297C303B427C3D302C6A3D502C4C3D4F2C503D4E2C4F3D462C4E3D6B2C463D4D3B76617220473D287A3E3E3E30292B28443E3E3E30293B6B3D41';
wwv_flow_imp.g_varchar2_table(259) := '2B552B4D6174682E666C6F6F7228472F75297C302C4D3D307C472C413D432C7A3D542C433D532C543D452C533D792C453D782C473D28443E3E3E30292B28423E3E3E30292C793D552B5F2B4D6174682E666C6F6F7228472F75297C302C783D307C477D76';
wwv_flow_imp.g_varchar2_table(260) := '617220573D5B792C782C532C452C432C542C412C7A2C6B2C4D2C4E2C462C502C4F2C6A2C4C5D3B666F7228743D303B743C31363B742B3D32297B76617220483D286E5B742B315D3E3E3E30292B28575B742B315D3E3E3E30293B6E5B745D3D6E5B745D2B';
wwv_flow_imp.g_varchar2_table(261) := '575B745D2B4D6174682E666C6F6F7228482F75297C302C6E5B742B315D3D307C487D7D76617220243D6E65772055696E74384172726179283634293B666F7228743D303B743C31363B742B2B29245B342A745D3D6E5B745D3E3E3E32342C245B342A742B';
wwv_flow_imp.g_varchar2_table(262) := '315D3D6E5B745D3E3E3E3136263235352C245B342A742B325D3D6E5B745D3E3E3E38263235352C245B342A742B335D3D323535266E5B745D3B72657475726E20247D7661722041653D5B35373834302C373433392C35323338302C33333938342C343336';
wwv_flow_imp.g_varchar2_table(263) := '342C333630302C36313930322C31323630362C363235382C35373635372C35343238372C33343034312C31303235322C34333337302C32303136335D2C7A653D5B5B34343739362C31393932392C33393835382C31303035332C32303130362C34303231';
wwv_flow_imp.g_varchar2_table(264) := '322C31303736315D2C5B33313538352C36333137302C36343933332C36303236372C35303933352C34303339392C31313139395D2C5B31373736332C33353532362C313435332C323930362C353831322C31313632342C32333234385D2C5B3838352C31';
wwv_flow_imp.g_varchar2_table(265) := '3737302C333534302C373038302C31343136302C32383332302C35363634305D2C5B35353336392C34313133392C32303830372C34313631342C32313832312C34333634322C31373632315D2C5B32383438352C35363937302C34343334312C31393031';
wwv_flow_imp.g_varchar2_table(266) := '392C33383033382C31343630352C32393231305D2C5B36303139352C35303739312C34303137352C31303735312C32313530322C34333030342C32343533375D2C5B31383338372C33363737342C333934392C373839382C31353739362C33313539322C';
wwv_flow_imp.g_varchar2_table(267) := '36333138345D2C5B34373230312C32343830332C34393630362C33373830352C31343230332C32383430362C35363831325D2C5B31373832342C33353634382C313639372C333339342C363738382C31333537362C32373135325D2C5B34333630312C31';
wwv_flow_imp.g_varchar2_table(268) := '373533392C33353037382C3535372C313131342C323232382C343435365D2C5B33303338382C36303737362C35313935332C33343234332C373037392C31343135382C32383331365D2C5B31343132382C32383235362C35363531322C34333432352C31';
wwv_flow_imp.g_varchar2_table(269) := '373235312C33343530322C373539375D2C5B31333130352C32363231302C35323432302C33353234312C3838332C313736362C333533325D2C5B343132392C383235382C31363531362C33333033322C343635372C393331342C31383632385D5D3B6675';
wwv_flow_imp.g_varchar2_table(270) := '6E6374696F6E206B652865297B76617220742C722C6E3D5B5D2C6F3D66756E6374696F6E2865297B72657475726E28653C31363F2230223A2222292B652E746F537472696E67283136292E746F55707065724361736528297D3B666F7228743D303B743C';
wwv_flow_imp.g_varchar2_table(271) := '652E6C656E6774683B742B2B297B766172206C3D652E63686172436F646541742874293B6E2E7075736828323535266C7C7C6C3E3E3826323535297D76617220613D41655B6E2E6C656E6774682D315D2C693D31352D6E2E6C656E6774682C733D303B66';
wwv_flow_imp.g_varchar2_table(272) := '6F7228743D303B743C6E2E6C656E6774683B742B2B297B76617220753D6E5B745D2C633D7A655B692B2B5D3B666F7228723D303B723C373B722B2B29312675262628615E3D635B725D292C753E3E3D317D66756E6374696F6E20662865297B7265747572';
wwv_flow_imp.g_varchar2_table(273) := '6E20653E3E313426317C653C3C312633323736377D666F7228743D6E2E6C656E6774682D313B743E3D303B742D2D29733D662873295E6E5B745D3B72657475726E206F283235352628733D662873295E6E2E6C656E6774685E353238313129292B6F2873';
wwv_flow_imp.g_varchar2_table(274) := '3E3E3826323535292B6F283235352661292B6F28613E3E3826323535297D66756E6374696F6E204D6528652C742C72297B696628212F5E5B5C7832302D5C7837455D7B312C31357D242F2E74657374286529297468726F77206E6577204572726F722822';
wwv_flow_imp.g_varchar2_table(275) := '4C6120636F6E7472617365C3B1612064652070726F7465636369C3B36E20646520576F72642061646D697465206465203120612031352063617261637465726573204153434949202873696E2074696C646573206E6920C3B1292E22293B766172206E2C';
wwv_flow_imp.g_varchar2_table(276) := '6F3D6B652865292C6C3D6E65772055696E7438417272617928742E6C656E6774682B322A6F2E6C656E677468293B666F72286C2E7365742874292C6E3D303B6E3C6F2E6C656E6774683B6E2B2B296C5B742E6C656E6774682B322A6E5D3D6F2E63686172';
wwv_flow_imp.g_varchar2_table(277) := '436F64654174286E293B76617220613D5465286C292C693D6E65772055696E74384172726179283638293B666F72286E3D303B6E3C723B6E2B2B29692E7365742861292C695B36345D3D323535266E2C695B36355D3D6E3E3E3E38263235352C695B3636';
wwv_flow_imp.g_varchar2_table(278) := '5D3D6E3E3E3E3136263235352C695B36375D3D6E3E3E3E3234263235352C613D54652869293B72657475726E20617D766172204E653D2223443544434533223B66756E6374696F6E20466528652C74297B76617220723D652E6C6162656C576964746873';
wwv_flow_imp.g_varchar2_table(279) := '3B72657475726E2041727261792E6973417272617928722926264E756D62657228725B745D293E303F4E756D62657228725B745D293A652E6C6162656C57696474687C7C33327D66756E6374696F6E20506528652C74297B76617220723D652E68656164';
wwv_flow_imp.g_varchar2_table(280) := '416C69676E7C7C742E68656164416C69676E7C7C2263656E746572223B72657475726E226175746F223D3D3D723F652E616C69676E3A727D66756E6374696F6E204F6528652C74297B76617220723D5B5D2C6E3D5B5D2C6F3D303B72657475726E20652E';
wwv_flow_imp.g_varchar2_table(281) := '666F72456163682866756E6374696F6E2865297B766172206C3D65262622726F77223D3D3D652E7370616E3F742D6F3A4D6174682E6D617828312C4D6174682E6D696E28742C4D6174682E666C6F6F72284E756D62657228652626652E7370616E29297C';
wwv_flow_imp.g_varchar2_table(282) := '7C3129293B6F2B6C3E74262628722E70757368286E292C6E3D5B5D2C6F3D30292C6E2E70757368287B663A652C636F6C3A6F2C7370616E3A6C2C656D7074793A212821657C7C21652E656D707479297D292C286F2B3D6C293D3D3D74262628722E707573';
wwv_flow_imp.g_varchar2_table(283) := '68286E292C6E3D5B5D2C6F3D30297D292C6E2E6C656E6774682626722E70757368286E292C727D66756E6374696F6E206A652865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E2065262628652E656D';
wwv_flow_imp.g_varchar2_table(284) := '7074797C7C652E7370616E262631213D3D652E7370616E297D297D66756E6374696F6E204C652865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E7370616E7D2C30297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(285) := '20496528652C742C72297B72657475726E2065262628652E616C69676E7C7C652E626F6C647C7C652E636F6C6F727C7C652E66696C6C293F7B616C69676E3A2F5E286C6566747C63656E7465727C726967687429242F2E7465737428652E616C69676E7C';
wwv_flow_imp.g_varchar2_table(286) := '7C2222293F652E616C69676E3A6E756C6C2C626F6C643A2121652E626F6C642C636F6C6F723A652E636F6C6F723F4F28652E636F6C6F722C742C72293A6E756C6C2C66696C6C3A652E66696C6C7C7C6E756C6C7D3A6E756C6C7D7661722052653D7B6C65';
wwv_flow_imp.g_varchar2_table(287) := '66743A312C746F703A312C6E6F6E653A317D3B66756E6374696F6E20446528652C74297B66756E6374696F6E20722872297B72657475726E20652626766F69642030213D3D655B725D26266E756C6C213D3D655B725D26262222213D3D655B725D3F655B';
wwv_flow_imp.g_varchar2_table(288) := '725D3A745B725D7D766172206E3D537472696E67287228226C6162656C506F736974696F6E22297C7C226C65667422292E746F4C6F7765724361736528292C6F3D7228226C6162656C416C69676E22292C6C3D7228226C6162656C426F6C6422292C613D';
wwv_flow_imp.g_varchar2_table(289) := '7B706F733A52655B6E5D3F6E3A226C656674222C73697A653A4E756D626572287228226C6162656C53697A652229293E303F4E756D626572287228226C6162656C53697A652229293A302C636F6C6F723A7228226C6162656C436F6C6F7222297C7C6E75';
wwv_flow_imp.g_varchar2_table(290) := '6C6C2C626F6C643A6E756C6C3D3D6C7C7C2131213D3D6C26262266616C736522213D3D6C2C75707065723A227570706572223D3D3D537472696E67287228226C6162656C4361736522297C7C2222292E746F4C6F7765724361736528292C616C69676E3A';
wwv_flow_imp.g_varchar2_table(291) := '2F5E286C6566747C63656E7465727C726967687429242F2E74657374286F7C7C2222293F6F3A6E756C6C2C66696C6C3A7228226C6162656C46696C6C22297C7C6E756C6C7D3B72657475726E20612E7374796C65643D212821657C7C2128652E6C616265';
wwv_flow_imp.g_varchar2_table(292) := '6C53697A657C7C652E6C6162656C436F6C6F727C7C766F69642030213D3D652E6C6162656C426F6C6426266E756C6C213D3D652E6C6162656C426F6C647C7C652E6C6162656C436173657C7C652E6C6162656C416C69676E7C7C652E6C6162656C46696C';
wwv_flow_imp.g_varchar2_table(293) := '6C29297C7C212128742E6C6162656C53697A657C7C766F69642030213D3D742E6C6162656C426F6C6426266E756C6C213D3D742E6C6162656C426F6C647C7C742E6C6162656C436173657C7C742E6C6162656C416C69676E292C617D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(294) := '20556528652C742C722C6E297B766172206F3D7B626F6C643A742E626F6C647D3B28742E73697A657C7C72292626286F2E73697A653D742E73697A657C7C39292C742E636F6C6F722626286F2E636F6C6F723D7B617267623A6128742E636F6C6F72297D';
wwv_flow_imp.g_varchar2_table(295) := '292C652E666F6E743D6F3B766172206C3D742E616C69676E7C7C28723F6E3A6E756C6C293B6966286C7C7C72297B76617220693D7B7D3B4F626A6563742E6B65797328652E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(296) := '2874297B695B745D3D652E616C69676E6D656E745B745D7D292C6C262628692E686F72697A6F6E74616C3D6C292C72262628692E766572746963616C3D22626F74746F6D22292C652E616C69676E6D656E743D697D742E66696C6C262628652E66696C6C';
wwv_flow_imp.g_varchar2_table(297) := '3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6128742E66696C6C297D7D297D66756E6374696F6E20426528652C74297B72657475726E20742E75707065723F537472696E672865';
wwv_flow_imp.g_varchar2_table(298) := '292E746F55707065724361736528293A657D66756E6374696F6E205F652865297B72657475726E28652E6669656C64737C7C5B5D292E736F6D652866756E6374696F6E2874297B72657475726E2074262621742E656D7074792626226C65667422213D3D';
wwv_flow_imp.g_varchar2_table(299) := '446528742C65292E706F737D297D66756E6374696F6E20476528652C74297B72657475726E20652E73697A657C7C4D6174682E6D617828352C4D6174682E726F756E6428312E372A74292F32297D66756E6374696F6E20576528652C74297B7265747572';
wwv_flow_imp.g_varchar2_table(300) := '6E2E333532382A476528652C74292A312E322B2E347D66756E6374696F6E2048652865297B76617220743D7B666F6E745374796C653A652E626F6C643F22626F6C64223A226E6F726D616C227D3B72657475726E20652E73697A65262628742E666F6E74';
wwv_flow_imp.g_varchar2_table(301) := '53697A653D652E73697A65292C652E636F6C6F72262628742E74657874436F6C6F723D6C28652E636F6C6F7229292C652E66696C6C262628742E66696C6C436F6C6F723D6C28652E66696C6C29292C652E616C69676E262628742E68616C69676E3D652E';
wwv_flow_imp.g_varchar2_table(302) := '616C69676E292C747D66756E6374696F6E20246528652C742C722C6E2C6F297B76617220613D722E6C622C693D476528612C6E292C733D2E333532382A693B696628612E66696C6C297B76617220753D6C28612E66696C6C293B652E73657446696C6C43';
wwv_flow_imp.g_varchar2_table(303) := '6F6C6F7228755B305D2C755B315D2C755B325D292C652E7265637428742E782B2E312C742E792B2E312C742E77696474682D2E322C6F2B312E322A732B2E312C224622297D76617220633D6C28612E636F6C6F727C7C222330303030303022292C663D4D';
wwv_flow_imp.g_varchar2_table(304) := '6174682E6D617828352C742E77696474682D322A6F293B652E736574466F6E74282268656C766574696361222C612E626F6C643F22626F6C64223A226E6F726D616C22292C652E736574466F6E7453697A652869292C652E73657454657874436F6C6F72';
wwv_flow_imp.g_varchar2_table(305) := '28635B305D2C635B315D2C635B325D293B76617220643D227269676874223D3D3D722E616C69676E3F742E782B742E77696474682D6F3A2263656E746572223D3D3D722E616C69676E3F742E782B742E77696474682F323A742E782B6F3B652E74657874';
wwv_flow_imp.g_varchar2_table(306) := '28652E73706C697454657874546F53697A6528537472696E6728722E74657874292C66295B305D7C7C22222C642C742E792B6F2B2E39352A732C7B616C69676E3A227269676874223D3D3D722E616C69676E7C7C2263656E746572223D3D3D722E616C69';
wwv_flow_imp.g_varchar2_table(307) := '676E3F722E616C69676E3A226C656674227D292C652E736574466F6E74282268656C766574696361222C226E6F726D616C22292C652E73657454657874436F6C6F7228302C302C30297D66756E6374696F6E20566528652C74297B72657475726E7B7369';
wwv_flow_imp.g_varchar2_table(308) := '7A653A652E73697A657C7C31342C73756253697A653A652E7375627469746C6553697A657C7C392C726967687453697A653A652E726967687453697A657C7C392C666F6E743A4C5B5528652E666F6E74295D2C66696C6C3A652E66696C6C7C7C742E7072';
wwv_flow_imp.g_varchar2_table(309) := '696D6172792C636F6C6F723A652E636F6C6F727C7C742E68656164546578747D7D66756E6374696F6E20596528652C742C72297B766172206E3D5028652C74295B305D7C7C7B7D2C6F3D28652E6669656C64737C7C652E6974656D737C7C5B5D292E6669';
wwv_flow_imp.g_varchar2_table(310) := '6C7465722866756E6374696F6E2865297B72657475726E2065262621652E656D70747926262821652E7768656E7C7C4628652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E2865297B72657475726E7B6C6162656C3A4D28652E6C6162';
wwv_flow_imp.g_varchar2_table(311) := '656C2C742C6E292C76616C75653A646528652C742C6E292C636F6C6F723A652E636F6C6F723F4F28652E636F6C6F722C742C6E293A6E756C6C7D7D293B72657475726E7B6974656D733A6F2C6E3A4D6174682E6D617828312C4D6174682E6D696E28362C';
wwv_flow_imp.g_varchar2_table(312) := '4E756D62657228652E636F6C756D6E73297C7C4D6174682E6D696E286F2E6C656E6774682C36297C7C3129292C66696C6C3A652E66696C6C7C7C2223463146344632222C616363656E743A766F696420303D3D3D652E616363656E743F722E7072696D61';
wwv_flow_imp.g_varchar2_table(313) := '72793A652E616363656E742C6C6162656C436F6C6F723A652E6C6162656C436F6C6F727C7C2223373837383738222C76616C7565436F6C6F723A652E76616C7565436F6C6F727C7C722E7072696D6172792C6C6162656C53697A653A652E6C6162656C53';
wwv_flow_imp.g_varchar2_table(314) := '697A657C7C372C73697A653A652E73697A657C7C31312C636172644761703A766F69642030213D3D652E636172644761703F4E756D62657228652E63617264476170293A337D7D66756E6374696F6E20716528652C742C72297B766172206E3D66756E63';
wwv_flow_imp.g_varchar2_table(315) := '74696F6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D302926262821727C7C657428652C7229297D2C6F3D28652E73656374696F6E737C7C5B5D292E66696C746572286E293B726574';
wwv_flow_imp.g_varchar2_table(316) := '75726E20723F4A286F292E66696C746572286E293A6F7D766172205A653D7B66696368613A312C666F726D756C6172696F3A312C7461726A657461733A312C746578746F3A312C696D6167656E3A312C636F6469676F3A312C616C657274613A312C6C69';
wwv_flow_imp.g_varchar2_table(317) := '6E65613A312C7461626C613A312C6772616669636F3A312C6573706163696F3A312C636F6C756D6E61733A312C677275706F3A317D2C58653D7B6C696E65613A312C6573706163696F3A312C636F6C756D6E61733A312C677275706F3A317D3B66756E63';
wwv_flow_imp.g_varchar2_table(318) := '74696F6E204A6528652C742C72297B766172206E3D66756E6374696F6E2865297B72657475726E206526265A655B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30292626657428652C72';
wwv_flow_imp.g_varchar2_table(319) := '297D3B72657475726E204A282841727261792E6973417272617928652E73656374696F6E73293F652E73656374696F6E733A5B5D292E66696C746572286E292E6D61702866756E6374696F6E2874297B696628742E736F757263657C7C21652E736F7572';
wwv_flow_imp.g_varchar2_table(320) := '63657C7C58655B742E747970655D2972657475726E20743B76617220723D592874293B72657475726E20722E736F757263653D652E736F757263652C727D29292E66696C746572286E297D66756E6374696F6E204B6528652C74297B69662821652E6561';
wwv_flow_imp.g_varchar2_table(321) := '63687C7C21652E736F757263652972657475726E5B7B6374783A742C7375663A22227D5D3B76617220723D537472696E6728652E736F75726365292E746F55707065724361736528292C6E3D5028652C74292C6F3D652E6C696E6B7C7C7B7D3B72657475';
wwv_flow_imp.g_varchar2_table(322) := '726E204E756D62657228652E6D6178293E302626286E3D6E2E736C69636528302C4E756D62657228652E6D61782929292C6E2E6D61702866756E6374696F6E28652C6E297B766172206C2C613D592874292C693D5928742E646F637C7C7B7D293B666F72';
wwv_flow_imp.g_varchar2_table(323) := '286C20696E20612E533D5928742E53292C612E535B725D3D5B655D2C4F626A6563742E6B657973286F292E666F72456163682866756E6374696F6E2872297B766172206E3D6F5B725D7C7C7B7D2C6C3D537472696E672872292E746F5570706572436173';
wwv_flow_imp.g_varchar2_table(324) := '6528293B612E535B6C5D3D28742E535B6C5D7C7C5B5D292E66696C7465722866756E6374696F6E2874297B72657475726E204F626A6563742E6B657973286E292E65766572792866756E6374696F6E2872297B72657475726E20537472696E6728745B72';
wwv_flow_imp.g_varchar2_table(325) := '2E746F55707065724361736528295D293D3D3D537472696E6728655B537472696E67286E5B725D292E746F55707065724361736528295D297D297D297D292C65294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C';
wwv_flow_imp.g_varchar2_table(326) := '6C28652C6C29262628695B6C5D3D655B6C5D293B72657475726E20612E646F633D692C7B6374783A612C7375663A225F222B286E2B31297D7D297D66756E6374696F6E20516528652C742C722C6E297B766172206F3D2841727261792E69734172726179';
wwv_flow_imp.g_varchar2_table(327) := '28652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33292C6C3D6F2E6C656E6774683B696628216C2972657475726E5B5D3B76617220613D6F2E6D61702866756E6374696F6E28742C72297B766172206E3D4E756D6265722828652E77';
wwv_flow_imp.g_varchar2_table(328) := '69647468737C7C5B5D295B725D293B72657475726E206E3E303F6E3A3130302F6C7D292C693D612E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C733D766F69642030213D3D652E636F6C4761703F4E756D62';
wwv_flow_imp.g_varchar2_table(329) := '657228652E636F6C476170293A342C753D6E2D732A286C2D31292C633D303B72657475726E206F2E6D61702866756E6374696F6E28652C6E297B766172206F3D752A615B6E5D2F692C6C3D4A282841727261792E697341727261792865293F653A5B5D29';
wwv_flow_imp.g_varchar2_table(330) := '2E66696C7465722866756E6374696F6E2865297B72657475726E206526262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30297D29292E66696C7465722866756E6374696F6E2865297B72657475726E20652626';
wwv_flow_imp.g_varchar2_table(331) := '5A655B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D30292626657428652C72297D292E6D61702866756E6374696F6E2865297B72657475726E2066756E6374696F6E28652C74297B7661';
wwv_flow_imp.g_varchar2_table(332) := '7220722C6E3D7B7D3B666F72287220696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C72292626286E5B725D3D655B725D293B6966285B2278222C2279222C227831222C227931222C227832';
wwv_flow_imp.g_varchar2_table(333) := '222C227932225D2E666F72456163682866756E6374696F6E2865297B64656C657465206E5B655D7D292C22696D6167656E223D3D3D6E2E747970652626286E2E5F6D6178573D74292C226772616669636F223D3D3D6E2E74797065297B766172206F3D6E';
wwv_flow_imp.g_varchar2_table(334) := '2E77696474687C7C3132302C6C3D6E2E6865696768747C7C37303B6F3E742626286E2E77696474683D742C6E2E6865696768743D6C2A742F6F297D72657475726E22636F6469676F223D3D3D6E2E74797065262628227172223D3D3D537472696E67286E';
wwv_flow_imp.g_varchar2_table(335) := '2E6B696E647C7C22717222292E746F4C6F7765724361736528292626286E2E73697A657C7C3330293E742626286E2E73697A653D74292C6E2E776964746826266E2E77696474683E742626286E2E77696474683D7429292C28226C696E6561223D3D3D6E';
wwv_flow_imp.g_varchar2_table(336) := '2E747970657C7C22746578746F223D3D3D6E2E747970652926266E2E776964746826266E2E77696474683E742626286E2E77696474683D74292C6E7D28652C6F297D292C663D7B783A632C773A6F2C736563733A6C7D3B72657475726E20632B3D6F2B73';
wwv_flow_imp.g_varchar2_table(337) := '2C667D297D66756E6374696F6E20657428652C74297B72657475726E22616C65727461223D3D3D652E747970657C7C21652E7768656E7C7C4628652E7768656E2C742C6E756C6C297D66756E6374696F6E2074742865297B76617220742C723D7B7D3B66';
wwv_flow_imp.g_varchar2_table(338) := '6F72287420696E206E29725B745D3D6E5B745D3B766172206F3D652E706167652626652E706167652E7468656D657C7C7B7D3B666F72287420696E206F29725B745D3D6F5B745D3B72657475726E20727D7661722072743D7B7D2C6E743D7B7D3B66756E';
wwv_flow_imp.g_varchar2_table(339) := '6374696F6E206F742865297B76617220743D77696E646F772E617065782626617065782E656E767C7C7B7D3B72657475726E20537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C';
wwv_flow_imp.g_varchar2_table(340) := '2222292E7265706C6163652822234150505F494D4147455323222C742E4150505F46494C45537C7C2222292E7265706C616365282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C61';
wwv_flow_imp.g_varchar2_table(341) := '6365282223494D4147455F50524546495823222C742E415045585F46494C45537C7C2222297D66756E6374696F6E206C742865297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B31';
wwv_flow_imp.g_varchar2_table(342) := '5D2972657475726E7B773A28745B31365D3C3C32347C745B31375D3C3C31367C745B31385D3C3C387C745B31395D293E3E3E302C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22';
wwv_flow_imp.g_varchar2_table(343) := '706E67227D3B6966283235353D3D3D745B305D26263231363D3D3D745B315D29666F722876617220723D323B723C742E6C656E6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B';
wwv_flow_imp.g_varchar2_table(344) := '335D3B6966286E3E3D31393226266E3C3D3230372626313936213D3D6E2626323030213D3D6E2626323034213D3D6E2972657475726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A70';
wwv_flow_imp.g_varchar2_table(345) := '67227D3B722B3D322B6F7D656C736520722B2B3B7468726F77206E6577204572726F722822466F726D61746F20646520696D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E2061742865';
wwv_flow_imp.g_varchar2_table(346) := '297B666F722876617220743D6E65772055696E743841727261792865292C723D22222C6E3D303B6E3C742E6C656E6774683B6E2B3D333237363829722B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E7375626172';
wwv_flow_imp.g_varchar2_table(347) := '726179286E2C6E2B333237363829293B72657475726E2062746F612872297D66756E6374696F6E2069742865297B72657475726E2050726F6D6973652E616C6C2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B';
wwv_flow_imp.g_varchar2_table(348) := '28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B65262622696D6167656E223D3D3D652E747970652626652E75726C262621652E6669656C642626742E7075736828652E75726C292C65262622636F6C756D6E6173223D3D3D652E74';
wwv_flow_imp.g_varchar2_table(349) := '797065262628652E636F6C737C7C5B5D292E666F72456163682872292C652626585B652E747970655D2626722828652E6669656C64737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C652626';
wwv_flow_imp.g_varchar2_table(350) := '22677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C652626227461626C61223D3D3D652E74797065262628652E636F6C756D6E737C7C5B5D292E666F72456163682866756E6374696F6E2865297B652626652E63656C6C2626';
wwv_flow_imp.g_varchar2_table(351) := '22696D6167656E223D3D3D652E63656C6C2E747970652626652E63656C6C2E75726C262621652E63656C6C2E6669656C642626537472696E6728652E63656C6C2E75726C292E696E6465784F6628227B22293C302626742E7075736828652E63656C6C2E';
wwv_flow_imp.g_varchar2_table(352) := '75726C297D297D297D72657475726E207228652E73656374696F6E73292C652E62617463682626652E62617463682E73756D6D6172792626287228652E62617463682E73756D6D6172792E73656374696F6E73292C652E62617463682E73756D6D617279';
wwv_flow_imp.g_varchar2_table(353) := '2E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F75742E73656374696F6E7329292C747D2865292E6D61702866756E6374696F6E2865297B76617220743D6F742865293B72657475726E2072745B745D3F6E756C6C3A666574';
wwv_flow_imp.g_varchar2_table(354) := '636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20636172676172206C6120696D';
wwv_flow_imp.g_varchar2_table(355) := '6167656E20222B742B222028222B652E7374617475732B222922293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B76617220723D6C742865293B72745B745D3D7B6275663A652C773A722E77';
wwv_flow_imp.g_varchar2_table(356) := '2C683A722E682C6578743A722E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D722E6578743F226A706567223A22706E6722292B223B6261736536342C222B61742865297D7D297D29297D66756E6374696F6E20737428';
wwv_flow_imp.g_varchar2_table(357) := '65297B76617220743D537472696E672865292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C2222293B69662821742972657475726E206E756C6C3B76617220723D226236343A222B742E6C65';
wwv_flow_imp.g_varchar2_table(358) := '6E6774682B223A222B742E73756273747228302C3634292B742E737562737472282D3634293B69662872745B725D2972657475726E2072745B725D3B666F7228766172206E3D61746F622874292C6F3D6E65772055696E74384172726179286E2E6C656E';
wwv_flow_imp.g_varchar2_table(359) := '677468292C6C3D303B6C3C6E2E6C656E6774683B6C2B2B296F5B6C5D3D6E2E63686172436F64654174286C293B76617220613D6C74286F2E627566666572293B72657475726E2072745B725D3D7B6275663A6F2E6275666665722C773A612E772C683A61';
wwv_flow_imp.g_varchar2_table(360) := '2E682C6578743A612E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D612E6578743F226A706567223A22706E6722292B223B6261736536342C222B747D2C72745B725D7D66756E6374696F6E20757428652C74297B6966';
wwv_flow_imp.g_varchar2_table(361) := '28652E6669656C64297B76617220723D2828652E736F757263653F5028652C74295B305D3A742E646F63297C7C7B7D295B537472696E6728652E6669656C64292E746F55707065724361736528295D3B7472797B72657475726E20723F73742872293A6E';
wwv_flow_imp.g_varchar2_table(362) := '756C6C7D63617463682874297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B652E6669656C642C74292C6E756C6C7D';
wwv_flow_imp.g_varchar2_table(363) := '7D72657475726E2072745B6F7428652E75726C295D7C7C6E756C6C7D66756E6374696F6E20637428652C74297B76617220723D652E77696474687C7C34302C6E3D652E6865696768747C7C722A742E682F742E773B72657475726E21652E776964746826';
wwv_flow_imp.g_varchar2_table(364) := '26652E686569676874262628723D6E2A742E772F742E68292C652E5F6D6178572626723E652E5F6D6178572626286E3D6E2A652E5F6D6178572F722C723D652E5F6D617857292C7B773A722C683A6E7D7D66756E6374696F6E2066742865297B666F7228';
wwv_flow_imp.g_varchar2_table(365) := '76617220743D61746F622865292C723D6E65772055696E7438417272617928742E6C656E677468292C6E3D303B6E3C742E6C656E6774683B6E2B2B29725B6E5D3D742E63686172436F64654174286E293B72657475726E20722E6275666665727D66756E';
wwv_flow_imp.g_varchar2_table(366) := '6374696F6E20647428652C742C72297B72657475726E7B6275663A667428652E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C222229292C646174613A652C773A742C683A722C6578743A22706E67227D7D66756E6374696F6E20687428652C';
wwv_flow_imp.g_varchar2_table(367) := '74297B69662822756E646566696E6564223D3D747970656F6620646F63756D656E747C7C21646F63756D656E742E637265617465456C656D656E74297468726F77206E6577204572726F722822536520726571756965726520756E206E6176656761646F';
wwv_flow_imp.g_varchar2_table(368) := '72202863616E7661732920706172612067656E65726172206772C3A16669636F732E22293B76617220723D646F63756D656E742E637265617465456C656D656E74282263616E76617322293B72657475726E20722E77696474683D652C722E6865696768';
wwv_flow_imp.g_varchar2_table(369) := '743D742C727D7661722070743D6E756C6C3B66756E6374696F6E2067742865297B72657475726E5B653E3E3E3234263235352C653E3E3E3136263235352C653E3E3E38263235352C32353526655D7D66756E6374696F6E206D7428652C74297B76617220';
wwv_flow_imp.g_varchar2_table(370) := '723D5B652E63686172436F646541742830292C652E63686172436F646541742831292C652E63686172436F646541742832292C652E63686172436F646541742833295D2C6E3D6E65772055696E7438417272617928342B742E6C656E677468293B6E2E73';
wwv_flow_imp.g_varchar2_table(371) := '657428722C30292C6E2E73657428742C34293B766172206F3D6E65772055696E743841727261792831322B742E6C656E677468293B72657475726E206F2E73657428677428742E6C656E677468292C30292C6F2E736574286E2C34292C6F2E7365742867';
wwv_flow_imp.g_varchar2_table(372) := '742866756E6374696F6E2865297B696628217074297B70743D5B5D3B666F722876617220743D303B743C3235363B742B2B297B666F722876617220723D742C6E3D303B6E3C383B6E2B2B29723D3126723F333938383239323338345E723E3E3E313A723E';
wwv_flow_imp.g_varchar2_table(373) := '3E3E313B70745B745D3D723E3E3E307D7D666F7228766172206F3D343239343936373239352C6C3D303B6C3C652E6C656E6774683B6C2B2B296F3D70745B32353526286F5E655B6C5D295D5E6F3E3E3E383B72657475726E28343239343936373239355E';
wwv_flow_imp.g_varchar2_table(374) := '6F293E3E3E307D286E29292C382B742E6C656E677468292C6F7D66756E6374696F6E20767428652C742C722C6E297B766172206F2C612C693D4D6174682E6365696C28652F38292B312C733D6E65772055696E7438417272617928692A74293B666F7228';
wwv_flow_imp.g_varchar2_table(375) := '613D303B613C743B612B2B29666F72286F3D303B6F3C653B6F2B2B2972286F2C6129262628735B612A692B312B286F3E3E33295D7C3D3132383E3E2837266F29293B76617220752C633D4D6174682E6365696C28732E6C656E6774682F3635353335292C';
wwv_flow_imp.g_varchar2_table(376) := '663D6E65772055696E7438417272617928322B732E6C656E6774682B352A632B34292C643D322C683D312C703D303B666F7228665B305D3D3132302C665B315D3D312C753D303B753C633B752B2B297B76617220673D36353533352A752C6D3D4D617468';
wwv_flow_imp.g_varchar2_table(377) := '2E6D696E2836353533352C732E6C656E6774682D67293B665B642B2B5D3D753D3D3D632D313F313A302C665B642B2B5D3D323535266D2C665B642B2B5D3D6D3E3E382C665B642B2B5D3D323535267E6D2C665B642B2B5D3D7E6D3E3E38263235352C662E';
wwv_flow_imp.g_varchar2_table(378) := '73657428732E737562617272617928672C672B6D292C64292C642B3D6D7D666F7228753D303B753C732E6C656E6774683B752B2B29703D28702B28683D28682B735B755D2925363535323129292536353532313B662E7365742867742828703C3C31367C';
wwv_flow_imp.g_varchar2_table(379) := '68293E3E3E30292C64293B76617220763D6E65772055696E74384172726179283133292C623D6C286E7C7C222330303030303022293B762E7365742867742865292C30292C762E7365742867742874292C34292C765B385D3D312C765B395D3D333B7661';
wwv_flow_imp.g_varchar2_table(380) := '7220773D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31332C31302C32362C31305D292C6D74282249484452222C76292C6D742822504C5445222C6E65772055696E74384172726179285B3235352C3235352C3235352C62';
wwv_flow_imp.g_varchar2_table(381) := '5B305D2C625B315D2C625B325D5D29292C6D74282249444154222C66292C6D74282249454E44222C6E65772055696E74384172726179283029295D2C793D772E7265647563652866756E6374696F6E28652C74297B72657475726E20652B742E6C656E67';
wwv_flow_imp.g_varchar2_table(382) := '74687D2C30292C783D6E65772055696E743841727261792879292C533D303B72657475726E20772E666F72456163682866756E6374696F6E2865297B782E73657428652C53292C532B3D652E6C656E6774687D292C7B6275663A782E6275666665722C64';
wwv_flow_imp.g_varchar2_table(383) := '6174613A22646174613A696D6167652F706E673B6261736536342C222B617428782E627566666572292C773A652C683A742C6578743A22706E67227D7D7661722062743D2232313232323220323232313232203232323232312031323132323320313231';
wwv_flow_imp.g_varchar2_table(384) := '33323220313331323232203132323231332031323233313220313332323132203232313231332032323133313220323331323132203131323233322031323231333220313232323331203131333232322031323331323220313233323231203232333231';
wwv_flow_imp.g_varchar2_table(385) := '31203232313133322032323132333120323133323132203232333131322033313231333120333131323232203332313132322033323132323120333132323132203332323131322033323232313120323132313233203231323332312032333231323120';
wwv_flow_imp.g_varchar2_table(386) := '31313133323320313331313233203133313332312031313233313320313332313133203133323331312032313133313320323331313133203233313331312031313231333320313132333331203133323133312031313331323320313133333231203133';
wwv_flow_imp.g_varchar2_table(387) := '33313231203331333132312032313133333120323331313331203231333131332032313333313120323133313331203331313132332033313133323120333331313231203331323131332033313233313120333332313131203331343131312032323134';
wwv_flow_imp.g_varchar2_table(388) := '31312034333131313120313131323234203131313432322031323131323420313231343231203134313132322031343132323120313132323134203131323431322031323231313420313232343131203134323131322031343232313120323431323131';
wwv_flow_imp.g_varchar2_table(389) := '20323231313134203431333131312032343131313220313334313131203131313234322031323131343220313231323431203131343231322031323431313220313234323131203431313231322034323131313220343231323131203231323134312032';
wwv_flow_imp.g_varchar2_table(390) := '31343132312034313231323120313131313433203131313334312031333131343120313134313133203131343331312034313131313320343131333131203131333134312031313431333120333131313431203431313133312032313134313220323131';
wwv_flow_imp.g_varchar2_table(391) := '323134203231313233322032333331313132222E73706C697428222022293B66756E6374696F6E2077742865297B653D537472696E672865292E7265706C616365282F5B5E5C7832302D5C7837455D2F672C223F22293B666F722876617220742C723D5B';
wwv_flow_imp.g_varchar2_table(392) := '5D2C6E3D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B743D6E2E657865632865293B29696628745B315D7C7C2F5E5C642B242F2E746573742865292626652E6C656E67746825323D3D30297B766172206F3D745B305D2C6C3D';
wwv_flow_imp.g_varchar2_table(393) := '6F2E6C656E6774682D6F2E6C656E67746825323B722E70757368287B7365743A2243222C743A6F2E73756273747228302C6C297D292C6C3C6F2E6C656E6774682626722E70757368287B7365743A2242222C743A6F2E737562737472286C297D297D656C';
wwv_flow_imp.g_varchar2_table(394) := '736520722E70757368287B7365743A2242222C743A745B305D7D293B76617220613D5B5D2C693D6E756C6C3B722E666F72456163682866756E6374696F6E2865297B6966286E756C6C3D3D3D693F612E70757368282243223D3D3D652E7365743F313035';
wwv_flow_imp.g_varchar2_table(395) := '3A313034293A69213D3D652E7365742626612E70757368282243223D3D3D652E7365743F39393A313030292C693D652E7365742C2243223D3D3D652E73657429666F722876617220743D303B743C652E742E6C656E6774683B742B3D3229612E70757368';
wwv_flow_imp.g_varchar2_table(396) := '282B652E742E73756273747228742C3229293B656C736520666F722876617220723D303B723C652E742E6C656E6774683B722B2B29612E7075736828652E742E63686172436F646541742872292D3332297D293B666F722876617220733D615B305D2C75';
wwv_flow_imp.g_varchar2_table(397) := '3D313B753C612E6C656E6774683B752B2B29732B3D752A615B755D3B612E707573682873253130332C313036293B76617220633D5B5D3B72657475726E20612E666F72456163682866756E6374696F6E2865297B62745B655D2E73706C6974282222292E';
wwv_flow_imp.g_varchar2_table(398) := '666F72456163682866756E6374696F6E28652C74297B666F722876617220723D303B723C2B653B722B2B29632E70757368287425323D3D30297D297D292C637D66756E6374696F6E20797428652C742C72297B766172206E3D727C7C28652E736F757263';
wwv_flow_imp.g_varchar2_table(399) := '653F5028652C74295B305D3A6E756C6C293B69662821722626652E736F757263652626216E2972657475726E206E756C6C3B766172206F3D4D28652E76616C75652C742C6E293B696628216F2972657475726E206E756C6C3B766172206C3D537472696E';
wwv_flow_imp.g_varchar2_table(400) := '6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292C613D652E636F6C6F727C7C2223303030303030223B696628227172223D3D3D6C297B76617220693D66756E6374696F6E28652C74297B76617220723D77696E646F772E717263';
wwv_flow_imp.g_varchar2_table(401) := '6F64653B6966282172297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD612064652063C3B36469676F732051522E22293B722E737472696E67546F427974657346756E63732626722E737472696E';
wwv_flow_imp.g_varchar2_table(402) := '67546F427974657346756E63735B225554462D38225D262628722E737472696E67546F42797465733D722E737472696E67546F427974657346756E63735B225554462D38225D293B766172206E3D7228302C537472696E6728747C7C224D22292E746F55';
wwv_flow_imp.g_varchar2_table(403) := '70706572436173652829293B72657475726E206E2E6164644461746128537472696E67286529292C6E2E6D616B6528292C7B6E3A6E2E6765744D6F64756C65436F756E7428292C6461726B3A66756E6374696F6E28652C74297B72657475726E206E2E69';
wwv_flow_imp.g_varchar2_table(404) := '734461726B28742C65297D7D7D286F2C652E656363292C733D652E73697A657C7C33303B72657475726E7B6B696E643A227172222C746578743A6F2C636F6C733A692E6E2C726F77733A692E6E2C6461726B3A692E6461726B2C773A732C683A732C636F';
wwv_flow_imp.g_varchar2_table(405) := '6C6F723A612C71756965743A327D7D69662822636F6465313238223D3D3D6C297B76617220753D7774286F292C633D652E77696474687C7C4D6174682E6D696E2839302C2E33332A752E6C656E677468293B72657475726E7B6B696E643A22626172222C';
wwv_flow_imp.g_varchar2_table(406) := '746578743A6F2C636F6C733A752E6C656E6774682C726F77733A312C6461726B3A66756E6374696F6E2865297B72657475726E20755B655D7D2C773A632C683A652E6865696768747C7C31322C636F6C6F723A612C71756965743A382C6C6162656C3A21';
wwv_flow_imp.g_varchar2_table(407) := '31213D3D652E73686F77546578742C7465787453697A653A652E7465787453697A657C7C387D7D7468726F77206E6577204572726F7228225469706F2064652063C3B36469676F206E6F20736F706F727461646F3A20222B6C2B22202875736520717220';
wwv_flow_imp.g_varchar2_table(408) := '6F20636F6465313238292E22297D66756E6374696F6E2078742865297B76617220743D652E71756965742C723D227172223D3D3D652E6B696E643F383A332C6E3D28652E636F6C732B322A74292A722C6F3D7674286E2C227172223D3D3D652E6B696E64';
wwv_flow_imp.g_varchar2_table(409) := '3F6E3A4D6174682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E636F6C732A7229292C66756E6374696F6E286E2C6F297B766172206C3D4D6174682E666C6F6F72286E2F72292D742C613D227172223D3D3D652E6B696E643F4D61';
wwv_flow_imp.g_varchar2_table(410) := '74682E666C6F6F72286F2F72292D743A303B72657475726E206C3E3D302626613E3D3026266C3C652E636F6C732626613C652E726F77732626652E6461726B286C2C61297D2C652E636F6C6F72293B72657475726E206F2E776D6D3D652E772A28652E63';
wwv_flow_imp.g_varchar2_table(411) := '6F6C732B322A74292F652E636F6C732C6F2E686D6D3D227172223D3D3D652E6B696E643F6F2E776D6D3A652E682C6F7D7661722053743D5B2223314634453739222C2223453037423339222C2223324538423537222C2223433033393242222C22233744';
wwv_flow_imp.g_varchar2_table(412) := '33433938222C2223313641303835222C2223443441433044222C2223354436443745222C2223413034303030222C2223323837344136225D3B66756E6374696F6E20457428652C742C72297B766172206E3D77696E646F772E43686172743B696628216E';
wwv_flow_imp.g_varchar2_table(413) := '297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD61206465206772C3A16669636F73202843686172742E6A73292E22293B766172206F3D5028652C74293B696628216F2E6C656E67746829726574';
wwv_flow_imp.g_varchar2_table(414) := '75726E206E756C6C3B76617220613D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C693D742E545B615D7C7C7B7D2C733D4F626A6563742E6B6579732869292C753D652E63617465676F72793F537472696E6728';
wwv_flow_imp.g_varchar2_table(415) := '652E63617465676F7279292E746F55707065724361736528293A732E66696C7465722866756E6374696F6E2865297B72657475726E224E554D42455222213D3D695B655D262622444F435F4B455922213D3D657D295B305D7C7C735B305D2C633D28652E';
wwv_flow_imp.g_varchar2_table(416) := '7365726965732626652E7365726965732E6C656E6774683F652E7365726965733A732E66696C7465722866756E6374696F6E2865297B72657475726E224E554D424552223D3D3D695B655D262665213D3D75262622444F435F4B455922213D3D657D2929';
wwv_flow_imp.g_varchar2_table(417) := '2E6D61702866756E6374696F6E2865297B72657475726E20653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A652C7B636F6C3A537472696E6728652E636F6C292E746F55707065724361736528292C6C6162656C3A766F69642030';
wwv_flow_imp.g_varchar2_table(418) := '213D3D652E6C6162656C3F652E6C6162656C3A6628652E636F6C292C636F6C6F723A652E636F6C6F727D7D292C643D652E63686172747C7C22626172222C683D22706965223D3D3D647C7C22646F7567686E7574223D3D3D642C673D31312E33343B6826';
wwv_flow_imp.g_varchar2_table(419) := '2628633D632E736C69636528302C3129293B766172206D3D652E77696474687C7C3132302C763D652E6865696768747C7C37302C623D6874284D6174682E726F756E64286D2A67292C4D6174682E726F756E6428762A6729292C773D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(420) := '2865297B72657475726E2E333532382A652A677D2C793D652E73697A657C7C382C783D2248656C7665746963612C20417269616C2C2073616E732D7365726966222C533D7B66616D696C793A782C73697A653A772879297D2C453D652E636F6C6F727326';
wwv_flow_imp.g_varchar2_table(421) := '26652E636F6C6F72732E6C656E6774683F652E636F6C6F72733A5B722E7072696D6172795D2E636F6E6361742853742E736C696365283129292C433D66756E6374696F6E2874297B72657475726E207028742C652E666D747C7C284D6174682E726F756E';
wwv_flow_imp.g_varchar2_table(422) := '642874293D3D3D743F22696E74223A226E756D3A322229297D2C543D6F2E6D61702866756E6374696F6E2874297B76617220723D745B755D3B72657475726E206E756C6C3D3D723F22223A652E63617465676F7279466D743F7028722C652E6361746567';
wwv_flow_imp.g_varchar2_table(423) := '6F7279466D74293A537472696E672872297D292C413D632E6D61702866756E6374696F6E28722C6E297B76617220613D722E636F6C6F727C7C455B6E25452E6C656E6774685D2C693D7B6C6162656C3A4D28722E6C6162656C2C74292C646174613A6F2E';
wwv_flow_imp.g_varchar2_table(424) := '6D61702866756E6374696F6E2865297B76617220743D655B722E636F6C5D3B72657475726E206E756C6C3D3D747C7C22223D3D3D743F6E756C6C3A4E756D6265722874297D297D3B72657475726E20683F28692E6261636B67726F756E64436F6C6F723D';
wwv_flow_imp.g_varchar2_table(425) := '6F2E6D61702866756E6374696F6E28652C74297B72657475726E20455B7425452E6C656E6774685D7D292C692E626F72646572436F6C6F723D2223464646464646222C692E626F7264657257696474683D77282E3829293A226C696E65223D3D3D647C7C';
wwv_flow_imp.g_varchar2_table(426) := '2261726561223D3D3D643F28692E626F72646572436F6C6F723D612C692E6261636B67726F756E64436F6C6F723D2261726561223D3D3D643F66756E6374696F6E28652C74297B76617220723D6C2865293B72657475726E227267626128222B725B305D';
wwv_flow_imp.g_varchar2_table(427) := '2B222C222B725B315D2B222C222B725B325D2B222C222B742B2229227D28612C2E3235293A612C692E66696C6C3D2261726561223D3D3D642C692E626F7264657257696474683D7728312E34292C692E706F696E745261646975733D7728312E35292C69';
wwv_flow_imp.g_varchar2_table(428) := '2E706F696E744261636B67726F756E64436F6C6F723D612C692E74656E73696F6E3D652E736D6F6F74683F2E33353A30293A28692E6261636B67726F756E64436F6C6F723D612C692E626F7264657257696474683D30292C697D292C7A3D7B666F6E743A';
wwv_flow_imp.g_varchar2_table(429) := '532C636F6C6F723A2223343434343434227D2C6B3D7B7D3B6966282168297B766172204E3D7B626567696E41745A65726F3A2131213D3D652E626567696E41745A65726F2C737461636B65643A2121652E737461636B65642C67726163653A652E76616C';
wwv_flow_imp.g_varchar2_table(430) := '7565733F2268626172223D3D3D643F22323525223A22313225223A302C677269643A7B636F6C6F723A2223453345374543222C6C696E6557696474683A77282E34297D2C626F726465723A7B646973706C61793A21317D2C7469636B733A7B666F6E743A';
wwv_flow_imp.g_varchar2_table(431) := '532C636F6C6F723A2223343434343434222C63616C6C6261636B3A66756E6374696F6E2865297B72657475726E20432865297D7D7D2C463D7B737461636B65643A2121652E737461636B65642C677269643A7B646973706C61793A21317D2C7469636B73';
wwv_flow_imp.g_varchar2_table(432) := '3A7A7D3B6B3D2268626172223D3D3D643F7B783A4E2C793A467D3A7B783A462C793A4E7D7D766172204F3D766F69642030213D3D652E6C6567656E643F2121652E6C6567656E643A687C7C632E6C656E6774683E312C6A3D6E6577206E28622E67657443';
wwv_flow_imp.g_varchar2_table(433) := '6F6E746578742822326422292C7B747970653A683F643A2268626172223D3D3D643F22626172223A2261726561223D3D3D643F226C696E65223A642C646174613A7B6C6162656C733A542C64617461736574733A417D2C706C6174666F726D3A6E2E4261';
wwv_flow_imp.g_varchar2_table(434) := '736963506C6174666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C616E696D6174696F6E3A21312C646576696365506978656C526174696F3A312C696E646578417869733A2268626172223D3D3D643F2279223A2278222C6C61796F';
wwv_flow_imp.g_varchar2_table(435) := '75743A7B70616464696E673A772834297D2C7363616C65733A6B2C706C7567696E733A7B6C6567656E643A7B646973706C61793A4F2C706F736974696F6E3A652E6C6567656E64506F736974696F6E7C7C28683F227269676874223A22626F74746F6D22';
wwv_flow_imp.g_varchar2_table(436) := '292C6C6162656C733A7B666F6E743A532C636F6C6F723A2223333333333333222C626F7857696474683A772837292C626F784865696768743A772837297D7D2C7469746C653A7B646973706C61793A2121652E7469746C652C746578743A4D28652E7469';
wwv_flow_imp.g_varchar2_table(437) := '746C652C74292C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C793A782C73697A653A7728792B32292C7765696768743A22626F6C64227D2C70616464696E673A7B626F74746F6D3A772834297D7D2C746F6F6C7469703A7B656E61';
wwv_flow_imp.g_varchar2_table(438) := '626C65643A21317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C6265666F7265447261773A66756E6374696F6E2865297B76617220743D652E6374783B742E7361766528292C742E66696C6C5374796C653D2223464646464646222C';
wwv_flow_imp.g_varchar2_table(439) := '742E66696C6C5265637428302C302C652E77696474682C652E686569676874292C742E726573746F726528297D7D2C7B69643A226E7256616C6F726573222C61667465724461746173657473447261773A66756E6374696F6E2874297B696628652E7661';
wwv_flow_imp.g_varchar2_table(440) := '6C756573297B76617220723D742E6374783B722E7361766528292C722E666F6E743D22626F6C6420222B7728792D2E35292B22707820222B782C742E646174612E64617461736574732E666F72456163682866756E6374696F6E286E2C6F297B69662874';
wwv_flow_imp.g_varchar2_table(441) := '2E69734461746173657456697369626C65286F29297B766172206C3D6E2E646174612E7265647563652866756E6374696F6E28652C74297B72657475726E20652B28747C7C30297D2C30293B742E676574446174617365744D657461286F292E64617461';
wwv_flow_imp.g_varchar2_table(442) := '2E666F72456163682866756E6374696F6E28742C6F297B76617220613D6E2E646174615B6F5D3B6966286E756C6C213D61297B76617220693D22706374223D3D3D652E76616C7565733F70286C3F3130302A612F6C3A302C226E756D3A3122292B222522';
wwv_flow_imp.g_varchar2_table(443) := '3A432861293B69662868297B76617220733D742E746F6F6C746970506F736974696F6E28293B722E66696C6C5374796C653D2223464646464646222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D226D6964';
wwv_flow_imp.g_varchar2_table(444) := '646C65222C722E66696C6C5465787428692C732E782C732E79297D656C73652268626172223D3D3D643F28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D226C656674222C722E74657874426173656C696E653D22';
wwv_flow_imp.g_varchar2_table(445) := '6D6964646C65222C722E66696C6C5465787428692C742E782B7728312E35292C742E7929293A28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D22626F';
wwv_flow_imp.g_varchar2_table(446) := '74746F6D222C722E66696C6C5465787428692C742E782C742E792D7728312E352929297D7D297D7D292C722E726573746F726528297D7D7D5D7D292C4C3D622E746F4461746155524C2822696D6167652F706E6722293B6A2E64657374726F7928293B76';
wwv_flow_imp.g_varchar2_table(447) := '617220493D6474284C2C622E77696474682C622E686569676874293B72657475726E20492E776D6D3D6D2C492E686D6D3D762C497D66756E6374696F6E20437428652C74297B76617220723D652E77617465726D61726B3B69662821727C7C226F626A65';
wwv_flow_imp.g_varchar2_table(448) := '6374223D3D747970656F6620722626214628722E7768656E2C742C742E646F63292972657475726E206E756C6C3B22737472696E67223D3D747970656F662072262628723D7B746578743A727D293B766172206E3D4D28722E746578742C742C742E646F';
wwv_flow_imp.g_varchar2_table(449) := '63293B72657475726E206E3F7B746578743A6E2C636F6C6F723A722E636F6C6F727C7C2223433030303030222C6F7061636974793A766F69642030213D3D722E6F7061636974793F722E6F7061636974793A2E31322C616E676C653A766F69642030213D';
wwv_flow_imp.g_varchar2_table(450) := '3D722E616E676C653F722E616E676C653A34352C73697A653A722E73697A657D3A6E756C6C7D66756E6374696F6E20547428652C742C722C6E297B696628652E73697A652972657475726E20652E73697A653B766172206F3D652E616E676C6525313830';
wwv_flow_imp.g_varchar2_table(451) := '3D3D303F2E382A723A2E362A4D6174682E7371727428722A722B6E2A6E293B72657475726E204D6174682E6D61782832302C4D6174682E6D696E283136302C3130302A6F2F7429297D66756E6374696F6E20417428652C742C722C6E297B766172206F2C';
wwv_flow_imp.g_varchar2_table(452) := '613D77696E646F772E6A737064662C693D722E782B2E362C733D722E792B2E362C753D722E77696474682D312E322C633D722E6865696768742D312E322C663D6C287065292C643D6C286765293B69662822636865636B626F78223D3D3D742E696E7075';
wwv_flow_imp.g_varchar2_table(453) := '74297B76617220683D4D6174682E6D696E28632C342E35293B732B3D28632D68292F322C753D682C633D687D652E73657444726177436F6C6F7228645B305D2C645B315D2C645B325D292C652E73657446696C6C436F6C6F7228665B305D2C665B315D2C';
wwv_flow_imp.g_varchar2_table(454) := '665B325D292C652E7365744C696E655769647468282E32292C652E7265637428692C732C752C632C22464422292C652E73657444726177436F6C6F7228302C302C30292C22636865636B626F78223D3D3D742E696E7075743F28286F3D6E657720612E41';
wwv_flow_imp.g_varchar2_table(455) := '63726F466F726D436865636B426F78292E617070656172616E636553746174653D742E636865636B65643F224F6E223A224F6666222C6F2E76616C75653D742E636865636B65643F224F6E223A224F666622293A226C697374223D3D3D742E696E707574';
wwv_flow_imp.g_varchar2_table(456) := '3F28286F3D6E657720612E4163726F466F726D436F6D626F426F78292E7365744F7074696F6E7328742E6F7074696F6E73292C6F2E656469743D21312C742E76616C75652626286F2E76616C75653D742E76616C756529293A28286F3D6E657720612E41';
wwv_flow_imp.g_varchar2_table(457) := '63726F466F726D546578744669656C64292E6D756C74696C696E653D226D756C74696C696E65223D3D3D742E696E7075742C742E6D61784C656E6774682626286F2E6D61784C656E6774683D742E6D61784C656E677468292C742E76616C75652626286F';
wwv_flow_imp.g_varchar2_table(458) := '2E76616C75653D742E76616C756529292C6F2E6669656C644E616D653D742E6E616D652C6F2E526563743D5B692C732C752C635D2C22636865636B626F7822213D3D742E696E7075742626286F2E666F6E7453697A653D6E2C652E5F5F6E72466F726D53';
wwv_flow_imp.g_varchar2_table(459) := '697A657C7C28652E5F5F6E72466F726D53697A653D6E29292C742E726561644F6E6C792626286F2E726561644F6E6C793D2130292C652E6164644669656C64286F297D66756E6374696F6E207A7428652C742C72297B766172206E3D652E706167657C7C';
wwv_flow_imp.g_varchar2_table(460) := '7B7D2C6F3D74742865292C613D6F2E666F6E7453697A652C693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F';
wwv_flow_imp.g_varchar2_table(461) := '726D61743A6E2E73697A657C7C226C6574746572222C636F6D70726573733A2145652865297D292C733D692E696E7465726E616C2E7061676553697A652E676574576964746828292C753D692E696E7465726E616C2E7061676553697A652E6765744865';
wwv_flow_imp.g_varchar2_table(462) := '6967687428292C633D6E2E6D617267696E7C7C382C663D6C286F2E7072696D617279292C643D6C286F2E6865616454657874292C683D6C286F2E7A65627261292C703D6C286F2E746F74616C73292C673D632C6D3D21302C763D632C623D633B66756E63';
wwv_flow_imp.g_varchar2_table(463) := '74696F6E207728297B72657475726E20692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A677D66756E6374696F6E20792865297B673D7728292B28657C7C32297D66756E6374696F6E207828652C742C72';
wwv_flow_imp.g_varchar2_table(464) := '2C6E297B766172206F3D766F69642030213D3D652E783F652E783A227269676874223D3D3D652E616C69676E3F732D622D743A2263656E746572223D3D3D652E616C69676E3F762B28732D762D622D74292F323A763B766F696420303D3D3D652E793F28';
wwv_flow_imp.g_varchar2_table(465) := '28673D4D6174682E6D617828672C77282929292B723E752D632D3130262628692E6164645061676528292C673D63292C6E286F2C67292C672B3D722B28766F69642030213D3D652E6761703F652E6761703A33292C692E6C6173744175746F5461626C65';
wwv_flow_imp.g_varchar2_table(466) := '3D7B66696E616C593A677D293A6E286F2C652E79297D76617220533D5B5D3B742E666F72456163682866756E6374696F6E28452C43297B76617220543D742E6C656E6774683E313F225F222B28432B31293A22223B6D7C7C692E6164645061676528292C';
wwv_flow_imp.g_varchar2_table(467) := '6D3D21312C673D632C692E6C6173744175746F5461626C653D6E756C6C3B76617220413D7B6374783A452C66726F6D3A692E696E7465726E616C2E6765744E756D6265724F66506167657328297D3B532E707573682841292C716528652C22706466222C';
wwv_flow_imp.g_varchar2_table(468) := '45292E666F72456163682866756E6374696F6E2074286D297B76617220533D6D2E747970653B69662822686561646572223D3D3D53297B76617220433D5665286D2C6F292C413D6D2E66696C6C3F6C28432E66696C6C293A662C7A3D6D2E636F6C6F723F';
wwv_flow_imp.g_varchar2_table(469) := '6C28432E636F6C6F72293A642C6B3D4D6174682E6D61782831302E352C332E352B2E333532382A432E73697A65292C4E3D6B2B4D6174682E6D617828362C312E352B2E333532382A432E73756253697A652A312E31292C493D4D6174682E6D6178284E75';
wwv_flow_imp.g_varchar2_table(470) := '6D626572286D2E686569676874297C7C302C6D2E7375627469746C653F4D6174682E6D61782832302C4E2B332E35293A4D6174682E6D61782831362C6B2B352E3529293B72657475726E20692E73657446696C6C436F6C6F7228415B305D2C415B315D2C';
wwv_flow_imp.g_varchar2_table(471) := '415B325D292C692E7265637428302C302C732C492C224622292C692E73657454657874436F6C6F72287A5B305D2C7A5B315D2C7A5B325D292C692E736574466F6E7428432E666F6E745B305D2C22626F6C6422292C692E736574466F6E7453697A652843';
wwv_flow_imp.g_varchar2_table(472) := '2E73697A65292C692E74657874284D286D2E7469746C652C45292C632C6B2C7B6D617857696474683A2E372A737D292C692E736574466F6E7428432E666F6E745B305D2C226E6F726D616C22292C692E736574466F6E7453697A6528432E726967687453';
wwv_flow_imp.g_varchar2_table(473) := '697A65292C6D2E72696768742626692E74657874284D286D2E72696768742C45292C732D632C6B2C7B616C69676E3A227269676874227D292C6D2E7375627469746C65262628692E736574466F6E7453697A6528432E73756253697A65292C692E746578';
wwv_flow_imp.g_varchar2_table(474) := '74284D286D2E7375627469746C652C45292C632C4E29292C692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E73657454657874436F6C6F7228302C302C30292C673D492B342C766F696428692E6C6173744175746F54';
wwv_flow_imp.g_varchar2_table(475) := '61626C653D6E756C6C297D69662822746578746F223D3D3D53297B76617220553D766F69642030213D3D6D2E792C483D672C563D692E6C6173744175746F5461626C652C593D6D2E73697A657C7C31302C583D2E333532382A592A286D2E6C696E654865';
wwv_flow_imp.g_varchar2_table(476) := '696768747C7C312E3335292C4A3D28766F69642030213D3D6D2E783F6D2E783A76292B286D2E696E64656E747C7C30292C4B3D6D2E77696474687C7C732D622D4A2C513D6D2E616C69676E7C7C226C656674222C65653D6C286D2E636F6C6F727C7C2223';
wwv_flow_imp.g_varchar2_table(477) := '30303030303022292C72653D66756E6374696F6E2865297B72657475726E28652E627C7C6D2E626F6C6429262628652E697C7C6D2E6974616C6963293F22626F6C646974616C6963223A652E627C7C6D2E626F6C643F22626F6C64223A652E697C7C6D2E';
wwv_flow_imp.g_varchar2_table(478) := '6974616C69633F226974616C6963223A226E6F726D616C227D2C6E653D6D2E666F6E747C7C652E706167652626652E706167652E666F6E747C7C2268656C766574696361223B72657475726E20692E736574466F6E7453697A652859292C692E73657454';
wwv_flow_imp.g_varchar2_table(479) := '657874436F6C6F722865655B305D2C65655B315D2C65655B325D292C673D553F6D2E793A4D6174682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292C5F286D2C45292E666F7245';
wwv_flow_imp.g_varchar2_table(480) := '6163682866756E6374696F6E2865297B76617220743D5B5D3B4228652C7B666F6E743A6E652C636F6C6F723A6D2E636F6C6F722C6C696E6B3A6F2E6C696E6B7D292E666F72456163682866756E6374696F6E2865297B652E742E73706C6974282F28202B';
wwv_flow_imp.g_varchar2_table(481) := '292F292E666F72456163682866756E6374696F6E2872297B2222213D3D722626742E70757368287B743A722C66616D3A4C5B652E665D5B305D2C663A72652865292C73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E';
wwv_flow_imp.g_varchar2_table(482) := '633F6C28652E63293A65652C683A652E687D297D297D293B76617220723D5B5D2C6E3D5B5D2C613D303B666F7228742E666F72456163682866756E6374696F6E2865297B76617220743D66756E6374696F6E2865297B692E736574466F6E7428652E6661';
wwv_flow_imp.g_varchar2_table(483) := '6D2C652E66293B666F722876617220743D302C723D652E66616D2B652E662B592C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B766172206F3D722B652E742E636861724174286E293B766F696420303D3D3D6E745B6F5D2626286E745B6F5D3D';
wwv_flow_imp.g_varchar2_table(484) := '692E67657454657874576964746828652E742E636861724174286E2929292C742B3D6E745B6F5D7D72657475726E20747D2865293B69662821652E73702626612B743E4B26266E2E6C656E677468297B666F72283B6E2E6C656E67746826266E5B6E2E6C';
wwv_flow_imp.g_varchar2_table(485) := '656E6774682D315D2E73703B29612D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A617D292C6E3D5B5D2C613D307D652E73702626216E2E6C656E6774687C7C28652E773D742C6E2E707573682865292C612B3D74297D293B6E2E6C65';
wwv_flow_imp.g_varchar2_table(486) := '6E67746826266E5B6E2E6C656E6774682D315D2E73703B29612D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A612C6C6173743A21307D292C652E7472696D28293F28722E666F72456163682866756E6374696F6E2865297B21552626';
wwv_flow_imp.g_varchar2_table(487) := '672B583E752D632D3130262628692E6164645061676528292C673D63293B76617220743D652E77732E66696C7465722866756E6374696F6E2865297B72657475726E20652E73707D292E6C656E6774682C723D226A757374696679223D3D3D5126262165';
wwv_flow_imp.g_varchar2_table(488) := '2E6C6173742626743F284B2D652E77292F743A302C6E3D227269676874223D3D3D513F4A2B4B2D652E773A2263656E746572223D3D3D513F4A2B284B2D652E77292F323A4A2C6F3D672B2E37352A583B652E77732E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(489) := '6E2865297B76617220743D652E772B28652E73703F723A30293B692E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C692E73657444726177436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C';
wwv_flow_imp.g_varchar2_table(490) := '692E7365744C696E655769647468282E3031322A59292C652E73707C7C28692E736574466F6E7428652E66616D2C652E66292C692E7465787428652E742C6E2C6F29292C652E752626692E6C696E65286E2C6F2B2E30362A592C6E2B742C6F2B2E30362A';
wwv_flow_imp.g_varchar2_table(491) := '59292C652E732626692E6C696E65286E2C6F2D2E31312A592C6E2B742C6F2D2E31312A59292C652E682626692E6C696E6B286E2C672C742C582C7B75726C3A652E687D292C6E2B3D747D292C672B3D587D292C672B3D766F69642030213D3D6D2E706172';
wwv_flow_imp.g_varchar2_table(492) := '6167726170684761703F6D2E7061726167726170684761703A2E352A58293A672B3D587D292C692E73657454657874436F6C6F7228302C302C30292C766F696428553F28673D482C692E6C6173744175746F5461626C653D56293A692E6C617374417574';
wwv_flow_imp.g_varchar2_table(493) := '6F5461626C653D7B66696E616C593A677D297D696628226C696E6561223D3D3D53297B766172206F653D6C286D2E636F6C6F727C7C222330303030303022293B696628692E73657444726177436F6C6F72286F655B305D2C6F655B315D2C6F655B325D29';
wwv_flow_imp.g_varchar2_table(494) := '2C692E7365744C696E655769647468286D2E746869636B6E6573737C7C2E33292C766F69642030213D3D6D2E78312972657475726E20766F696420692E6C696E65286D2E78312C6D2E79312C766F69642030213D3D6D2E78323F6D2E78323A6D2E78312C';
wwv_flow_imp.g_varchar2_table(495) := '766F69642030213D3D6D2E79323F6D2E79323A6D2E7931293B673D4D6174682E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292B286D2E6761704265666F72657C7C30293B766172';
wwv_flow_imp.g_varchar2_table(496) := '206C653D6D2E77696474687C7C732D762D622C68653D2263656E746572223D3D3D6D2E616C69676E3F762B28732D762D622D6C65292F323A227269676874223D3D3D6D2E616C69676E3F732D622D6C653A763B72657475726E20692E6C696E652868652C';
wwv_flow_imp.g_varchar2_table(497) := '672C68652B6C652C67292C672B3D766F69642030213D3D6D2E6761703F6D2E6761703A322C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226573706163696F223D3D3D532972657475726E20673D4D617468';
wwv_flow_imp.g_varchar2_table(498) := '2E6D617828672C692E6C6173744175746F5461626C653F692E6C6173744175746F5461626C652E66696E616C593A67292B286D2E6865696768747C7C36292C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D293B69662822';
wwv_flow_imp.g_varchar2_table(499) := '696D6167656E22213D3D5329696628226772616669636F22213D3D532969662822636F6469676F22213D3D53297B6966282273616C746F223D3D3D532972657475726E20692E6164645061676528292C673D632C766F696428692E6C6173744175746F54';
wwv_flow_imp.g_varchar2_table(500) := '61626C653D7B66696E616C593A637D293B69662822636F6C756D6E6173223D3D3D53297B7661722070653D762C67653D623B69662821285A653D5165286D2C22706466222C452C732D762D6229292E6C656E6774682972657475726E3B766172206D653D';
wwv_flow_imp.g_varchar2_table(501) := '66756E6374696F6E2865297B763D70652B652E782C623D732D2870652B652E782B652E77297D2C76653D692C62653D302C78653D21302C53653D4D6174682E6D617828672C772829293B6966285A652E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(502) := '693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572227D292C';
wwv_flow_imp.g_varchar2_table(503) := '6D652865292C673D632C692E6C6173744175746F5461626C653D6E756C6C2C652E736563732E666F72456163682874292C692E696E7465726E616C2E6765744E756D6265724F66506167657328293E3126262878653D2131292C62653D4D6174682E6D61';
wwv_flow_imp.g_varchar2_table(504) := '782862652C4D6174682E6D617828672C772829292D63297D292C763D70652C623D67652C673D53652C28693D7665292E6C6173744175746F5461626C653D7B66696E616C593A53657D2C2178652972657475726E20766F6964205A652E666F7245616368';
wwv_flow_imp.g_varchar2_table(505) := '2866756E6374696F6E2865297B652E736563732E666F72456163682874297D293B672B62653E752D632D3130262628692E6164645061676528292C673D63293B7661722045653D672C43653D673B72657475726E205A652E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(506) := '74696F6E2865297B6D652865292C673D45652C692E6C6173744175746F5461626C653D7B66696E616C593A45657D2C652E736563732E666F72456163682874292C43653D4D6174682E6D61782843652C672C772829297D292C763D70652C623D67652C67';
wwv_flow_imp.g_varchar2_table(507) := '3D43652B28766F69642030213D3D6D2E6761703F6D2E6761703A31292C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D69662822677275706F223D3D3D53297B7661722054653D452C41653D542C7A653D762C6B653D';
wwv_flow_imp.g_varchar2_table(508) := '622C4D653D766F69642030213D3D6D2E70616464696E673F4E756D626572286D2E70616464696E67293A6D2E626F726465727C7C6D2E66696C6C3F333A302C52653D66756E6374696F6E2865297B76617220722C6E3D4D6174682E6D617828672C772829';
wwv_flow_imp.g_varchar2_table(509) := '293B763D7A652C623D6B652C673D6E2C6D2E7469746C65262628723D4D286D2E7469746C652C45292C692E6175746F5461626C65287B7374617274593A4D6174682E6D617828672C772829292C7468656D653A22706C61696E222C6D617267696E3A7B6C';
wwv_flow_imp.g_varchar2_table(510) := '6566743A762C72696768743A627D2C626F64793A5B5B725D5D2C7374796C65733A7B666F6E7453697A653A6D2E7469746C6553697A657C7C612B322C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E362C66696C6C436F6C';
wwv_flow_imp.g_varchar2_table(511) := '6F723A6C286D2E7469746C6546696C6C7C7C6F2E7072696D617279292C74657874436F6C6F723A6C286D2E7469746C65436F6C6F727C7C6F2E6865616454657874297D7D292C673D772829292C673D4D6174682E6D617828672C772829292B4D652C692E';
wwv_flow_imp.g_varchar2_table(512) := '6C6173744175746F5461626C653D7B66696E616C593A677D2C763D7A652B4D652C623D6B652B4D652C652E666F72456163682874293B76617220733D4D6174682E6D617828672C772829292B4D653B72657475726E20763D7A652C623D6B652C732D6E7D';
wwv_flow_imp.g_varchar2_table(513) := '3B72657475726E204B65286D2C45292E666F72456163682866756E6374696F6E2865297B453D652E6374782C543D41652B652E7375663B76617220743D4A65286D2C22706466222C45293B696628742E6C656E6774687C7C6D2E7469746C65297B766172';
wwv_flow_imp.g_varchar2_table(514) := '20723D692C6F3D4D6174682E6D617828672C772829293B693D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F72';
wwv_flow_imp.g_varchar2_table(515) := '6D61743A6E2E73697A657C7C226C6574746572227D292C673D632C692E6C6173744175746F5461626C653D6E756C6C3B76617220613D52652874292C663D313D3D3D692E696E7465726E616C2E6765744E756D6265724F66506167657328293B673D6F2C';
wwv_flow_imp.g_varchar2_table(516) := '28693D72292E6C6173744175746F5461626C653D7B66696E616C593A6F7D2C6626262131213D3D6D2E6B656570546F6765746865722626672B613E752D632D3130262628692E6164645061676528292C673D632C692E6C6173744175746F5461626C653D';
wwv_flow_imp.g_varchar2_table(517) := '7B66696E616C593A677D293B76617220643D672C683D692E696E7465726E616C2E67657443757272656E7450616765496E666F28292E706167654E756D6265722C703D732D7A652D6B653B6966286626266D2E66696C6C297B76617220763D6C286D2E66';
wwv_flow_imp.g_varchar2_table(518) := '696C6C293B692E73657446696C6C436F6C6F7228765B305D2C765B315D2C765B325D292C692E72656374287A652C642C702C612C224622297D76617220623D52652874293B6966286D2E626F726465722626692E696E7465726E616C2E67657443757272';
wwv_flow_imp.g_varchar2_table(519) := '656E7450616765496E666F28292E706167654E756D6265723D3D3D68297B76617220793D6C286D2E626F72646572436F6C6F727C7C4E65293B692E73657444726177436F6C6F7228795B305D2C795B315D2C795B325D292C692E7365744C696E65576964';
wwv_flow_imp.g_varchar2_table(520) := '7468286D2E626F7264657257696474687C7C2E33292C692E72656374287A652C642C702C622C225322292C692E73657444726177436F6C6F7228302C302C30297D673D642B622C692E696E7465726E616C2E67657443757272656E7450616765496E666F';
wwv_flow_imp.g_varchar2_table(521) := '28292E706167654E756D626572213D3D68262628673D4D6174682E6D617828672C77282929292C672B3D766F69642030213D3D6D2E6761703F4E756D626572286D2E676170293A332C692E6C6173744175746F5461626C653D7B66696E616C593A677D7D';
wwv_flow_imp.g_varchar2_table(522) := '7D292C453D54652C543D41652C763D7A652C766F696428623D6B65297D696628226669636861223D3D3D53297B7661722055653D50286D2C45295B305D7C7C7B7D2C47653D6D2E636F6C756D6E737C7C332C71653D5B5D2C5A653D7B7D2C58653D21313B';
wwv_flow_imp.g_varchar2_table(523) := '4F6528286D2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C4628652E7768656E2C452C5565297D292C4765292E666F72456163682866756E6374696F6E2865297B76617220743D5B';
wwv_flow_imp.g_varchar2_table(524) := '5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E656D70747929742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2C7374796C65733A7B6C696E6557696474683A30';
wwv_flow_imp.g_varchar2_table(525) := '2C66696C6C436F6C6F723A21317D7D293B656C73657B766172206E3D446528722C6D292C613D496528722C452C5565292C693D646528722C452C5565292C733D5228722C452C5565293B696628226C65667422213D3D6E2E706F73297B76617220753D7B';
wwv_flow_imp.g_varchar2_table(526) := '666F6E745374796C653A612626612E626F6C643F22626F6C64223A226E6F726D616C222C66696C6C436F6C6F723A212821617C7C21612E66696C6C2926266C28612E66696C6C292C74657874436F6C6F723A6C28612626612E636F6C6F727C7C6D2E7661';
wwv_flow_imp.g_varchar2_table(527) := '6C7565436F6C6F727C7C222330303030303022292C68616C69676E3A612626612E616C69676E7C7C226C656674227D3B73262628612626612E636F6C6F727C7C28752E74657874436F6C6F723D6C286F2E6C696E6B29292C58653D2130293B7661722063';
wwv_flow_imp.g_varchar2_table(528) := '3D7B636F6E74656E743A692C636F6C5370616E3A322A652E7370616E2C7374796C65733A752C5F6E72487265663A737D3B72657475726E22746F70223D3D3D6E2E706F73262628632E5F6E724C61623D7B746578743A4265284D28722E6C6162656C2C45';
wwv_flow_imp.g_varchar2_table(529) := '2C5565292C6E292C6C623A6E2C616C69676E3A6E2E616C69676E7C7C752E68616C69676E7D292C766F696420742E707573682863297D696628617C7C652E7370616E3E317C7C73297B76617220663D7B7D3B73262628662E74657874436F6C6F723D6C28';
wwv_flow_imp.g_varchar2_table(530) := '6F2E6C696E6B292C58653D2130292C612626612E616C69676E262628662E68616C69676E3D612E616C69676E292C612626612E626F6C64262628662E666F6E745374796C653D22626F6C6422292C612626612E636F6C6F72262628662E74657874436F6C';
wwv_flow_imp.g_varchar2_table(531) := '6F723D6C28612E636F6C6F7229292C612626612E66696C6C262628662E66696C6C436F6C6F723D6C28612E66696C6C29292C693D7B636F6E74656E743A692C7374796C65733A662C5F6E72487265663A737D2C652E7370616E3E31262628692E636F6C53';
wwv_flow_imp.g_varchar2_table(532) := '70616E3D322A652E7370616E2D31297D76617220643D4D28722E6C6162656C2C452C5565293B742E70757368286E2E7374796C65643F7B636F6E74656E743A426528642C6E292C7374796C65733A4865286E297D3A642C69297D7D293B666F7228766172';
wwv_flow_imp.g_varchar2_table(533) := '20723D322A4C652865293B723C322A47653B722B2B29742E70757368282222293B71652E707573682874297D293B7661722065743D302C74743D5F65286D293B6966286A65286D2E6669656C6473297C7C7474297B666F72287661722072743D302C6F74';
wwv_flow_imp.g_varchar2_table(534) := '3D303B6F743C47653B6F742B2B2972742B3D4665286D2C6F74293B65743D4D6174682E6D61782831302C28732D762D622D7274292F4765297D666F7228766172206C743D303B6C743C322A47653B6C742B3D32295A655B6C745D3D7B666F6E745374796C';
wwv_flow_imp.g_varchar2_table(535) := '653A22626F6C64222C63656C6C57696474683A4665286D2C6C742F32297D2C65742626285A655B6C742B315D3D7B63656C6C57696474683A65747D292C6D2E6C6162656C46696C6C2626285A655B6C745D2E66696C6C436F6C6F723D6C286D2E6C616265';
wwv_flow_imp.g_varchar2_table(536) := '6C46696C6C29292C6D2E6C6162656C436F6C6F722626285A655B6C745D2E74657874436F6C6F723D6C286D2E6C6162656C436F6C6F7229292C6D2E76616C7565436F6C6F722626285A655B6C742B315D3D5A655B6C742B315D7C7C7B7D2C5A655B6C742B';
wwv_flow_imp.g_varchar2_table(537) := '315D2E74657874436F6C6F723D6C286D2E76616C7565436F6C6F7229293B7661722061743D7B666F6E7453697A653A6D2E73697A657C7C382E352C63656C6C50616464696E673A2E397D3B6D2E6772696426262861742E63656C6C50616464696E673D31';
wwv_flow_imp.g_varchar2_table(538) := '2E362C61742E76616C69676E3D226D6964646C65222C61742E6C696E6557696474683D2E31352C61742E6C696E65436F6C6F723D6C286D2E626F72646572436F6C6F727C7C4E6529293B7661722069743D7B7374617274593A672C626F64793A71652C74';
wwv_flow_imp.g_varchar2_table(539) := '68656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C7374796C65733A61742C636F6C756D6E5374796C65733A5A657D3B6966287474297B7661722073743D61742E666F6E7453697A652C66743D61742E63656C6C';
wwv_flow_imp.g_varchar2_table(540) := '50616464696E673B69742E646964506172736543656C6C3D66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B74262628652E6365';
wwv_flow_imp.g_varchar2_table(541) := '6C6C2E7374796C65732E63656C6C50616464696E673D7B746F703A66742B576528742E6C622C7374292C72696768743A66742C626F74746F6D3A66742C6C6566743A66747D297D2C69742E6469644472617743656C6C3D66756E6374696F6E2865297B76';
wwv_flow_imp.g_varchar2_table(542) := '617220743D22626F6479223D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B742626246528692C652E63656C6C2C742C73742C6674297D7D6966285865297B7661722064743D69742E646964';
wwv_flow_imp.g_varchar2_table(543) := '4472617743656C6C3B69742E6469644472617743656C6C3D66756E6374696F6E2865297B22626F6479223D3D3D652E73656374696F6E2626652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724872656626264428692C652E63656C6C2C65';
wwv_flow_imp.g_varchar2_table(544) := '2E63656C6C2E7261772E5F6E7248726566292C6474262664742865297D7D72657475726E20692E6175746F5461626C65286974292C766F696420792832297D696628227461726A65746173223D3D3D53297B7661722068743D5965286D2C452C6F293B69';
wwv_flow_imp.g_varchar2_table(545) := '66282168742E6974656D732E6C656E6774682972657475726E3B7661722070743D28732D762D622D68742E636172644761702A2868742E6E2D3129292F68742E6E2C67743D2E333532382A68742E6C6162656C53697A652C6D743D2E333532382A68742E';
wwv_flow_imp.g_varchar2_table(546) := '73697A652C76743D6C2868742E66696C6C292C62743D68742E616363656E743F6C2868742E616363656E74293A6E756C6C2C77743D62743F343A332C78743D70742D77742D323B673D4D6174682E6D617828672C772829293B666F72287661722053743D';
wwv_flow_imp.g_varchar2_table(547) := '303B53743C68742E6974656D732E6C656E6774683B53742B3D68742E6E297B7661722043743D68742E6974656D732E736C6963652853742C53742B68742E6E293B692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E736574';
wwv_flow_imp.g_varchar2_table(548) := '466F6E7453697A652868742E73697A65293B7661722054743D43742E6D61702866756E6374696F6E2865297B72657475726E20692E73706C697454657874546F53697A6528537472696E6728652E76616C7565292C7874297D292C7A743D4D6174682E6D';
wwv_flow_imp.g_varchar2_table(549) := '61782E6170706C79286E756C6C2C54742E6D61702866756E6374696F6E2865297B72657475726E204D6174682E6D617828312C652E6C656E677468297D29292C6B743D312E322A67742B312E352B312E322A6D742A7A742C4D743D4D6174682E6D617828';
wwv_flow_imp.g_varchar2_table(550) := '6D2E6865696768747C7C302C332B6B742B33293B672B4D743E752D632D3130262628692E6164645061676528292C673D63292C43742E666F72456163682866756E6374696F6E28652C74297B76617220723D762B742A2870742B68742E63617264476170';
wwv_flow_imp.g_varchar2_table(551) := '292C6E3D6C2868742E6C6162656C436F6C6F72292C6F3D6C28652E636F6C6F727C7C68742E76616C7565436F6C6F72293B692E73657446696C6C436F6C6F722876745B305D2C76745B315D2C76745B325D292C692E7265637428722C672C70742C4D742C';
wwv_flow_imp.g_varchar2_table(552) := '224622292C6274262628692E73657446696C6C436F6C6F722862745B305D2C62745B315D2C62745B325D292C692E7265637428722C672C312E322C4D742C22462229293B76617220613D672B284D742D6B74292F322B67743B692E736574466F6E742822';
wwv_flow_imp.g_varchar2_table(553) := '68656C766574696361222C226E6F726D616C22292C692E736574466F6E7453697A652868742E6C6162656C53697A65292C692E73657454657874436F6C6F72286E5B305D2C6E5B315D2C6E5B325D292C692E7465787428692E73706C697454657874546F';
wwv_flow_imp.g_varchar2_table(554) := '53697A6528537472696E6728652E6C6162656C292C7874295B305D7C7C22222C722B77742C61292C692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E736574466F6E7453697A652868742E73697A65292C692E7365745465';
wwv_flow_imp.g_varchar2_table(555) := '7874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C54745B745D2E666F72456163682866756E6374696F6E28652C74297B692E7465787428652C722B77742C612B312E352B312E30352A6D742B742A6D742A312E32297D297D292C672B3D4D742B';
wwv_flow_imp.g_varchar2_table(556) := '2853742B68742E6E3C68742E6974656D732E6C656E6774683F68742E636172644761703A30297D72657475726E20692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E73657454657874436F6C6F7228302C302C30292C';
wwv_flow_imp.g_varchar2_table(557) := '672B3D766F69642030213D3D6D2E6761703F6D2E6761703A332C766F696428692E6C6173744175746F5461626C653D7B66696E616C593A677D297D69662822666F726D756C6172696F223D3D3D53297B692E5F5F6E72466F726D7C7C28692E5F5F6E7246';
wwv_flow_imp.g_varchar2_table(558) := '6F726D3D77652829293B766172204E743D7965286D2C452C54292C46743D6D2E636F6C756D6E737C7C322C50743D5B5D2C4F743D7B7D2C6A743D7B7D2C4C743D6D2E73697A657C7C382E353B6966284F65284E742C4674292E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(559) := '6374696F6E2865297B76617220743D5B5D3B652E666F72456163682866756E6374696F6E2865297B76617220723D652E663B696628652E656D70747929742E70757368287B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E7D293B65';
wwv_flow_imp.g_varchar2_table(560) := '6C73657B696628692E5F5F6E72466F726D28722E6E616D65292C226C65667422213D3D722E6C61622E706F73297B4F745B50742E6C656E6774682B223A222B322A652E636F6C5D3D723B766172206E3D7B636F6E74656E743A22222C636F6C5370616E3A';
wwv_flow_imp.g_varchar2_table(561) := '322A652E7370616E2C7374796C65733A7B666F6E745374796C653A226E6F726D616C227D7D3B72657475726E22746F70223D3D3D722E6C61622E706F732626286E2E5F6E724C61623D7B746578743A426528722E6C6162656C2C722E6C6162292C6C623A';
wwv_flow_imp.g_varchar2_table(562) := '722E6C61622C616C69676E3A722E6C61622E616C69676E7C7C226C656674227D292C766F696420742E70757368286E297D4F745B50742E6C656E6774682B223A222B28322A652E636F6C2B31295D3D722C742E7075736828722E6C61622E7374796C6564';
wwv_flow_imp.g_varchar2_table(563) := '3F7B636F6E74656E743A426528722E6C6162656C2C722E6C6162292C7374796C65733A486528722E6C6162297D3A722E6C6162656C2C652E7370616E3E313F7B636F6E74656E743A22222C636F6C5370616E3A322A652E7370616E2D317D3A2222297D7D';
wwv_flow_imp.g_varchar2_table(564) := '293B666F722876617220723D322A4C652865293B723C322A46743B722B2B29742E70757368282222293B50742E707573682874297D292C2150742E6C656E6774682972657475726E3B666F72287661722049743D6A65286D2E6669656C6473297C7C5F65';
wwv_flow_imp.g_varchar2_table(565) := '286D293F4D6174682E6D61782831302C28732D762D622D286D2E6C6162656C57696474687C7C3332292A4674292F4674293A302C52743D303B52743C322A46743B52742B3D32296A745B52745D3D7B666F6E745374796C653A22626F6C64222C63656C6C';
wwv_flow_imp.g_varchar2_table(566) := '57696474683A6D2E6C6162656C57696474687C7C33327D2C49742626286A745B52742B315D3D7B63656C6C57696474683A49747D293B7661722044743D2E333532382A4C742A312E333B72657475726E20692E6175746F5461626C65287B737461727459';
wwv_flow_imp.g_varchar2_table(567) := '3A672C626F64793A50742C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C726F7750616765427265616B3A2261766F6964222C7374796C65733A7B666F6E7453697A653A4C742C63656C6C50616464696E';
wwv_flow_imp.g_varchar2_table(568) := '673A312E322C76616C69676E3A226D6964646C65227D2C636F6C756D6E5374796C65733A6A742C646964506172736543656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E26264F745B652E726F772E69';
wwv_flow_imp.g_varchar2_table(569) := '6E6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61622C6E3D723F576528722E6C622C4C74293A303B72262628652E63656C6C2E7374796C';
wwv_flow_imp.g_varchar2_table(570) := '65732E63656C6C50616464696E673D7B746F703A312E322B6E2C72696768743A312E322C626F74746F6D3A312E322C6C6566743A312E327D292C652E63656C6C2E7374796C65732E6D696E43656C6C4865696768743D742E6C696E65732A44742B332B6E';
wwv_flow_imp.g_varchar2_table(571) := '7D7D2C6469644472617743656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E26264F745B652E726F772E696E6465782B223A222B652E636F6C756D6E2E696E6465785D3B69662874297B76617220723D';
wwv_flow_imp.g_varchar2_table(572) := '652E63656C6C2E7261772626652E63656C6C2E7261772E5F6E724C61623B69662872297B766172206E3D576528722E6C622C4C74292B312E323B246528692C652E63656C6C2C722C4C742C312E32292C417428692C742C7B783A652E63656C6C2E782C79';
wwv_flow_imp.g_varchar2_table(573) := '3A652E63656C6C2E792B6E2D2E362C77696474683A652E63656C6C2E77696474682C6865696768743A652E63656C6C2E6865696768742D6E2B2E367D2C4C74297D656C736520417428692C742C652E63656C6C2C4C74297D7D7D292C766F696420792832';
wwv_flow_imp.g_varchar2_table(574) := '297D69662822616C6572746122213D3D53297B696628227461626C61223D3D3D53297B7661722055743D50286D2C45293B6966282155742E6C656E67746826262131213D3D6D2E68696465456D7074792626216D2E656D70747954657874297265747572';
wwv_flow_imp.g_varchar2_table(575) := '6E3B7661722042743D47286D2C452C5574292C5F743D5B5D2C47743D7B7D3B6966286D2E7469746C6526265F742E70757368285B7B636F6E74656E743A4D286D2E7469746C652C45292C636F6C5370616E3A42742E6C656E6774682C7374796C65733A7B';
wwv_flow_imp.g_varchar2_table(576) := '68616C69676E3A226C656674222C666F6E7453697A653A612B317D7D5D292C6D2E67726F757073297B7661722057743D5B5D2C48743D5B5D2C24743D7B68616C69676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B57286D2C4274';
wwv_flow_imp.g_varchar2_table(577) := '292E666F72456163682866756E6374696F6E2865297B666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B29652E6761703F57742E70757368287B636F6E74656E743A42745B745D2E6C6162656C2C726F77537061';
wwv_flow_imp.g_varchar2_table(578) := '6E3A322C7374796C65733A7B68616C69676E3A50652842745B745D2C6D292C76616C69676E3A226D6964646C65227D7D293A48742E70757368287B636F6E74656E743A42745B745D2E6C6162656C2C7374796C65733A7B68616C69676E3A50652842745B';
wwv_flow_imp.g_varchar2_table(579) := '745D2C6D297D7D293B652E6761707C7C57742E70757368287B636F6E74656E743A652E6C6162656C2C636F6C5370616E3A652E636F6C732C7374796C65733A24747D297D292C5F742E707573682857742C4874297D656C7365205F742E70757368284274';
wwv_flow_imp.g_varchar2_table(580) := '2E6D61702866756E6374696F6E2865297B72657475726E7B636F6E74656E743A652E6C6162656C2C7374796C65733A7B68616C69676E3A506528652C6D297D7D7D29293B42742E666F72456163682866756E6374696F6E28652C74297B47745B745D3D7B';
wwv_flow_imp.g_varchar2_table(581) := '68616C69676E3A652E616C69676E7D2C652E636F6C6F7226262847745B745D2E74657874436F6C6F723D6C28652E636F6C6F7229292C652E626F6C6426262847745B745D2E666F6E745374796C653D22626F6C6422292C652E776964746826262847745B';
wwv_flow_imp.g_varchar2_table(582) := '745D2E63656C6C57696474683D652E7769647468297D293B7661722056743D6365286D2C5574292C59743D7565286D292C71743D6C286F2E67726F7570292C5A743D5B5D2C58743D5B5D2C4A743D5B5D2C4B743D7B7D3B71653D55742E6C656E6774683F';
wwv_flow_imp.g_varchar2_table(583) := '5B5D3A5B5B7B636F6E74656E743A4D286D2E656D707479546578742C45292C636F6C5370616E3A42742E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A226974616C6963227D7D5D5D3B55742E6C656E';
wwv_flow_imp.g_varchar2_table(584) := '67746826262856742E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B2972657475726E2071652E70757368285B7B636F6E74656E743A6665286D2C652C45292C636F6C5370616E3A42742E6C656E6774682C7374';
wwv_flow_imp.g_varchar2_table(585) := '796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A71747D7D5D292C5A742E707573682865292C58742E70757368286E756C6C292C766F6964204A742E70757368286E756C6C293B6966';
wwv_flow_imp.g_varchar2_table(586) := '282273756222213D3D652E6B297B76617220743D6E756C6C2C723D6E756C6C3B42742E666F72456163682866756E6374696F6E28742C6E297B766172206F3D5228742C452C652E72293B6F26262828723D727C7C7B7D295B6E5D3D6F297D292C71652E70';
wwv_flow_imp.g_varchar2_table(587) := '7573682842742E6D61702866756E6374696F6E28722C6E297B69662821722E63656C6C2972657475726E202428722C652E722C45293B766172206C3D5A28722C652E722C452C6F293B72657475726E206C26262828743D747C7C7B7D295B6E5D3D6C2C4B';
wwv_flow_imp.g_varchar2_table(588) := '745B6E5D3D4D6174682E6D6178284B745B6E5D7C7C302C6C2E7729292C22227D29292C5A742E707573682865292C58742E707573682874292C4A742E707573682872297D656C73652073652861652842742C59742C652E726F77732C6665286D2C652C45';
wwv_flow_imp.g_varchar2_table(589) := '29292C42742E6C656E677468292E666F72456163682866756E6374696F6E2874297B71652E707573682874292C5A742E707573682865292C58742E70757368286E756C6C292C4A742E70757368286E756C6C297D297D292C4F626A6563742E6B65797328';
wwv_flow_imp.g_varchar2_table(590) := '4B74292E666F72456163682866756E6374696F6E2865297B47745B655D2E63656C6C57696474683D4D6174682E6D61782842745B655D2E77696474687C7C302C4B745B655D2B33297D29293B7661722051743D6E756C6C2C65723D7465286D2E746F7461';
wwv_flow_imp.g_varchar2_table(591) := '6C73293B65722E6C656E677468262655742E6C656E67746826262851743D73652861652842742C65722C55742C6965286D2C452C557429292C42742E6C656E67746829293B7661722074723D7B666F6E7453697A653A6D2E73697A657C7C612C63656C6C';
wwv_flow_imp.g_varchar2_table(592) := '50616464696E673A6D2E677269643F312E323A2E387D2C72723D71286D2C4274293B727226262874722E76616C69676E3D7272292C42742E666F72456163682866756E6374696F6E28652C74297B652E76616C69676E26262847745B745D2E76616C6967';
wwv_flow_imp.g_varchar2_table(593) := '6E3D652E76616C69676E297D292C6D2E6772696426262874722E6C696E6557696474683D2E31352C74722E6C696E65436F6C6F723D6C286D2E626F72646572436F6C6F727C7C4E6529292C692E6175746F5461626C65287B7374617274593A672C6D6172';
wwv_flow_imp.g_varchar2_table(594) := '67696E3A7B6C6566743A762C72696768743A627D2C686561643A5F742C626F64793A71652C666F6F743A51747C7C766F696420302C73686F77486561643A21313D3D3D6D2E7265706561744865616465723F22666972737450616765223A226576657279';
wwv_flow_imp.g_varchar2_table(595) := '50616765222C73686F77466F6F743A226C61737450616765222C7374796C65733A74722C686561645374796C65733A7B66696C6C436F6C6F723A662C74657874436F6C6F723A642C68616C69676E3A2263656E746572222C666F6E7453697A653A6D2E73';
wwv_flow_imp.g_varchar2_table(596) := '697A657C7C617D2C666F6F745374796C65733A7B66696C6C436F6C6F723A702C74657874436F6C6F723A6D2E746F74616C73436F6C6F723F6C286D2E746F74616C73436F6C6F72293A302C666F6E745374796C653A22626F6C64222C68616C69676E3A22';
wwv_flow_imp.g_varchar2_table(597) := '7269676874227D2C616C7465726E617465526F775374796C65733A6D2E627265616B42793F7B7D3A7B66696C6C436F6C6F723A687D2C636F6C756D6E5374796C65733A47742C646964506172736543656C6C3A66756E6374696F6E2865297B6966282262';
wwv_flow_imp.g_varchar2_table(598) := '6F6479223D3D3D652E73656374696F6E262655742E6C656E677468297B76617220743D5A745B652E726F772E696E6465785D3B696628742626226865616422213D3D742E6B297B69662822737562223D3D3D742E6B2972657475726E20652E63656C6C2E';
wwv_flow_imp.g_varchar2_table(599) := '7374796C65732E66696C6C436F6C6F723D702C766F696428652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C6422293B766172206E3D742E722C613D42745B652E636F6C756D6E2E696E6465785D3B6D2E627265616B427926262865';
wwv_flow_imp.g_varchar2_table(600) := '2E63656C6C2E7374796C65732E66696C6C436F6C6F723D742E6925323D3D3126262131213D3D6D2E7A656272613F683A5B3235352C3235352C3235355D292C4A745B652E726F772E696E6465785D26264A745B652E726F772E696E6465785D5B652E636F';
wwv_flow_imp.g_varchar2_table(601) := '6C756D6E2E696E6465785D262621612E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D6C286F2E6C696E6B29293B76617220693D6A286D2E726F775374796C652C452C6E293B69262628692E66696C6C262628652E6365';
wwv_flow_imp.g_varchar2_table(602) := '6C6C2E7374796C65732E66696C6C436F6C6F723D6C28692E66696C6C29292C692E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D6C28692E636F6C6F7229292C692E626F6C64262628652E63656C6C2E7374796C65732E';
wwv_flow_imp.g_varchar2_table(603) := '666F6E745374796C653D22626F6C642229293B76617220733D6126266A28612E63656C6C5374796C652C452C6E293B73262628732E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D6C28732E66696C6C29292C732E636F6C';
wwv_flow_imp.g_varchar2_table(604) := '6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D6C28732E636F6C6F7229292C732E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B76617220753D58745B652E726F772E696E';
wwv_flow_imp.g_varchar2_table(605) := '6465785D262658745B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B75262628652E63656C6C2E7374796C65732E6D696E43656C6C4865696768743D4D6174682E6D617828652E63656C6C2E7374796C65732E6D696E43656C6C';
wwv_flow_imp.g_varchar2_table(606) := '4865696768747C7C302C752E682B3229292C722626722E70646643656C6C2626722E70646643656C6C28652C6E2C612C6D2C45297D7D7D2C6469644472617743656C6C3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F';
wwv_flow_imp.g_varchar2_table(607) := '6E297B76617220743D58745B652E726F772E696E6465785D262658745B652E726F772E696E6465785D5B652E636F6C756D6E2E696E6465785D3B6966284428692C652E63656C6C2C4A745B652E726F772E696E6465785D26264A745B652E726F772E696E';
wwv_flow_imp.g_varchar2_table(608) := '6465785D5B652E636F6C756D6E2E696E6465785D2C2142745B652E636F6C756D6E2E696E6465785D2E63656C6C292C74297B76617220723D42745B652E636F6C756D6E2E696E6465785D2E616C69676E2C6E3D226C656674223D3D3D723F652E63656C6C';
wwv_flow_imp.g_varchar2_table(609) := '2E782B313A227269676874223D3D3D723F652E63656C6C2E782B652E63656C6C2E77696474682D742E772D313A652E63656C6C2E782B28652E63656C6C2E77696474682D742E77292F322C6F3D42745B652E636F6C756D6E2E696E6465785D2E76616C69';
wwv_flow_imp.g_varchar2_table(610) := '676E7C7C72722C6C3D22746F70223D3D3D6F3F652E63656C6C2E792B313A22626F74746F6D223D3D3D6F3F652E63656C6C2E792B652E63656C6C2E6865696768742D742E682D313A652E63656C6C2E792B28652E63656C6C2E6865696768742D742E6829';
wwv_flow_imp.g_varchar2_table(611) := '2F323B692E616464496D61676528742E696D2E646174612C226A7067223D3D3D742E696D2E6578743F224A504547223A22504E47222C6E2C6C2C742E772C742E682C766F696420302C224641535422297D7D7D7D292C79286D2E6761707C7C33297D7D65';
wwv_flow_imp.g_varchar2_table(612) := '6C73652050286D2C45292E66696C7465722866756E6374696F6E2865297B72657475726E2046286D2E7768656E2C452C65297D292E736C69636528302C6D2E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B692E617574';
wwv_flow_imp.g_varchar2_table(613) := '6F5461626C65287B7374617274593A672C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C626F64793A5B5B4D286D2E746578742C452C65295D5D2C7374796C65733A7B666F6E7453697A653A6D2E73697A';
wwv_flow_imp.g_varchar2_table(614) := '657C7C382C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A6C284F286D2E636F6C6F722C452C65297C7C222345364543463222297D7D292C792831297D297D656C73657B766172206E723D79';
wwv_flow_imp.g_varchar2_table(615) := '74286D2C45293B696628216E722972657475726E3B766172206F723D6E722E6C6162656C3F2E333532382A6E722E7465787453697A652A312E343A303B78286D2C6E722E772C6E722E682B6F722C66756E6374696F6E28652C74297B76617220723D6E72';
wwv_flow_imp.g_varchar2_table(616) := '2E772F6E722E636F6C732C6E3D6E722E682F6E722E726F77732C6F3D6C286E722E636F6C6F72293B692E73657446696C6C436F6C6F72286F5B305D2C6F5B315D2C6F5B325D293B666F722876617220613D303B613C6E722E726F77733B612B2B29666F72';
wwv_flow_imp.g_varchar2_table(617) := '2876617220733D303B733C6E722E636F6C733B732B2B296966286E722E6461726B28732C6129297B666F722876617220753D733B732B313C6E722E636F6C7326266E722E6461726B28732B312C61293B29732B2B3B692E7265637428652B752A722C742B';
wwv_flow_imp.g_varchar2_table(618) := '612A6E2C28732D752B31292A722C6E2B28613C6E722E726F77732D313F2E30323A30292C224622297D6E722E6C6162656C262628692E736574466F6E742822636F7572696572222C226E6F726D616C22292C692E736574466F6E7453697A65286E722E74';
wwv_flow_imp.g_varchar2_table(619) := '65787453697A65292C692E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C692E74657874286E722E746578742C652B6E722E772F322C742B6E722E682B2E333532382A6E722E7465787453697A652A312E312C7B616C69676E3A';
wwv_flow_imp.g_varchar2_table(620) := '2263656E746572227D292C692E73657454657874436F6C6F7228302C302C3029297D297D656C73657B766172206C723D4574286D2C452C6F293B696628216C722972657475726E3B78286D2C6C722E776D6D2C6C722E686D6D2C66756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(621) := '2C74297B692E616464496D616765286C722E646174612C22504E47222C652C742C6C722E776D6D2C6C722E686D6D2C766F696420302C224641535422297D297D656C73657B7661722061723D7574286D2C45293B6966282161722972657475726E3B7661';
wwv_flow_imp.g_varchar2_table(622) := '722069723D6374286D2C6172292C73723D226A7067223D3D3D61722E6578743F224A504547223A22504E47222C75723D52286D2C452C6D2E736F757263653F50286D2C45295B305D3A6E756C6C293B78286D2C69722E772C69722E682C66756E6374696F';
wwv_flow_imp.g_varchar2_table(623) := '6E28652C74297B692E616464496D6167652861722E646174612C73722C652C742C69722E772C69722E68292C75722626692E6C696E6B28652C742C69722E772C69722E682C7B75726C3A75727D297D297D7D292C412E746F3D692E696E7465726E616C2E';
wwv_flow_imp.g_varchar2_table(624) := '6765744E756D6265724F66506167657328297D292C532E666F72456163682866756E6374696F6E2874297B76617220723D437428652C742E637478293B69662872297B692E736574466F6E74282268656C766574696361222C22626F6C6422292C692E73';
wwv_flow_imp.g_varchar2_table(625) := '6574466F6E7453697A6528313030293B766172206E3D547428722C692E67657454657874576964746828722E74657874292C732C75292C6F3D722E616E676C652A4D6174682E50492F3138302C613D6C28722E636F6C6F72293B692E736574466F6E7453';
wwv_flow_imp.g_varchar2_table(626) := '697A65286E293B666F722876617220633D692E67657454657874576964746828722E74657874292C663D2E333532382A6E2A2E372C643D732F322D632F322A4D6174682E636F73286F292B662F322A4D6174682E73696E286F292C683D752F322B632F32';
wwv_flow_imp.g_varchar2_table(627) := '2A4D6174682E73696E286F292B662F322A4D6174682E636F73286F292C703D742E66726F6D3B703C3D742E746F3B702B2B29692E736574506167652870292C692E736176654772617068696373537461746528292C692E736574475374617465286E6577';
wwv_flow_imp.g_varchar2_table(628) := '20692E475374617465287B6F7061636974793A722E6F7061636974797D29292C692E73657454657874436F6C6F7228615B305D2C615B315D2C615B325D292C692E7465787428722E746578742C642C682C7B616E676C653A722E616E676C657D292C692E';
wwv_flow_imp.g_varchar2_table(629) := '726573746F72654772617068696373537461746528293B692E73657454657874436F6C6F7228302C302C30297D7D293B76617220453D652E666F6F7465722C433D692E696E7465726E616C2E6765744E756D6265724F66506167657328292C543D745B30';
wwv_flow_imp.g_varchar2_table(630) := '5D7C7C7B533A7B7D2C543A7B7D7D3B69662845297B666F722876617220413D313B413C3D433B412B2B297B692E736574506167652841292C692E736574466F6E74282268656C766574696361222C226E6F726D616C22292C692E736574466F6E7453697A';
wwv_flow_imp.g_varchar2_table(631) := '6528452E73697A657C7C37293B766172207A3D6C286F2E6D75746564293B692E73657454657874436F6C6F72287A5B305D2C7A5B315D2C7A5B325D293B766172206B3D66756E6374696F6E2865297B72657475726E204D28652C54292E7265706C616365';
wwv_flow_imp.g_varchar2_table(632) := '28227B504147457D222C41292E7265706C61636528227B50414745537D222C43297D3B696628452E6C656674297B766172204E3D692E73706C697454657874546F53697A65286B28452E6C656674292C2E37382A73293B692E74657874284E2C632C752D';
wwv_flow_imp.g_varchar2_table(633) := '342D284E2E6C656E6774682D31292A28452E73697A657C7C37292A2E34297D452E72696768742626692E74657874286B28452E7269676874292C732D632C752D352C7B616C69676E3A227269676874227D297D692E73657454657874436F6C6F7228302C';
wwv_flow_imp.g_varchar2_table(634) := '302C30297D72657475726E20652E7469746C652626692E73657450726F70657274696573287B7469746C653A4D28652E7469746C652C54297D292C66756E6374696F6E2865297B76617220743D652E696E7465726E616C2E6163726F666F726D506C7567';
wwv_flow_imp.g_varchar2_table(635) := '696E2C723D742626742E6163726F466F726D44696374696F6E617279526F6F743B696628722626722E4669656C64732626722E4669656C64732E6C656E677468262621722E5F5F6E72297B766172206E3D223C3C202F54797065202F466F6E74202F5375';
wwv_flow_imp.g_varchar2_table(636) := '6274797065202F5479706531202F42617365466F6E74202F48656C766574696361202F456E636F64696E67202F57696E416E7369456E636F64696E67203E3E222C6F3D652E696E7465726E616C2E676574466F6E74282268656C766574696361222C226E';
wwv_flow_imp.g_varchar2_table(637) := '6F726D616C22292E69643B722E44413D222F48656C7620222B28652E5F5F6E72466F726D53697A657C7C39292B2220546620302067222C4F626A6563742E646566696E6550726F706572747928722C224452222C7B656E756D657261626C653A21302C63';
wwv_flow_imp.g_varchar2_table(638) := '6F6E666967757261626C653A21312C76616C75653A223C3C202F466F6E74203C3C202F48656C7620222B6E2B286F26262248656C7622213D3D6F3F22202F222B6F2B2220222B6E3A2222292B22202F5A614462203C3C202F54797065202F466F6E74202F';
wwv_flow_imp.g_varchar2_table(639) := '53756274797065202F5479706531202F42617365466F6E74202F5A61706644696E6762617473203E3E203E3E203E3E227D292C4F626A6563742E646566696E6550726F706572747928722C224E656564417070656172616E636573222C7B656E756D6572';
wwv_flow_imp.g_varchar2_table(640) := '61626C653A21302C636F6E666967757261626C653A21312C76616C75653A2274727565227D292C722E5F5F6E723D21307D7D2869292C50726F6D6973652E7265736F6C766528692E6F7574707574282261727261796275666665722229297D66756E6374';
wwv_flow_imp.g_varchar2_table(641) := '696F6E206B742865297B72657475726E20537472696E6728652E6C6162656C7C7C652E6E616D65292E7265706C616365282F5C732B2F672C222022292E73756273747228302C3332297D66756E6374696F6E204D7428652C742C72297B766172206E3D7B';
wwv_flow_imp.g_varchar2_table(642) := '7374796C653A227468696E222C636F6C6F723A7B617267623A61286765297D7D3B652E66696C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A61287065297D7D2C652E626F7264';
wwv_flow_imp.g_varchar2_table(643) := '65723D7B746F703A6E2C6C6566743A6E2C626F74746F6D3A6E2C72696768743A6E7D2C652E70726F74656374696F6E3D7B6C6F636B65643A2121742E726561644F6E6C797D2C652E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E';
wwv_flow_imp.g_varchar2_table(644) := '313F22746F70223A226D6964646C65222C686F72697A6F6E74616C3A22636865636B626F78223D3D3D742E696E7075743F2263656E746572223A226C656674222C77726170546578743A226D756C74696C696E65223D3D3D742E696E7075747D2C226368';
wwv_flow_imp.g_varchar2_table(645) := '65636B626F78223D3D3D742E696E7075743F28652E76616C75653D742E636865636B65643F6D653A76652C652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21312C666F726D756C61653A5B2722E2';
wwv_flow_imp.g_varchar2_table(646) := '98902CE2989222275D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A6B742874292C6572726F723A22456C696A6120E29890206F20E298922E227D293A28652E76616C75653D22223D3D3D742E76616C75653F6E756C6C';
wwv_flow_imp.g_varchar2_table(647) := '3A742E76616C75652C652E6E756D466D743D2240222C226C697374223D3D3D742E696E7075743F652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B7228742E6F7074';
wwv_flow_imp.g_varchar2_table(648) := '696F6E73295D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A6B742874292C6572726F723A22456C696A6120756E2076616C6F72206465206C61206C697374612E227D3A742E6D61784C656E677468262628652E646174';
wwv_flow_imp.g_varchar2_table(649) := '6156616C69646174696F6E3D7B747970653A22746578744C656E677468222C6F70657261746F723A226C6573735468616E4F72457175616C222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B742E6D61784C656E6774685D2C73686F7745';
wwv_flow_imp.g_varchar2_table(650) := '72726F724D6573736167653A21302C6572726F725469746C653A6B742874292C6572726F723A224DC3A178696D6F20222B742E6D61784C656E6774682B2220636172616374657265732E227D29292C652E6E616D653D742E6E616D657D66756E6374696F';
wwv_flow_imp.g_varchar2_table(651) := '6E204E7428652C742C722C6E297B766172206C3D6E65772077696E646F772E457863656C4A532E576F726B626F6F6B2C693D74742865292C733D7B7D2C753D786528652C6E292C633D776528292C663D5B5D2C6D3D7B77733A6E756C6C2C6E3A302C7265';
wwv_flow_imp.g_varchar2_table(652) := '663A7B7D7D3B6C2E63726561746F723D226E6F76615265706F7274223B76617220763D652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C73782E73686565744E616D657C7C225265706F72746522';
wwv_flow_imp.g_varchar2_table(653) := '7D5D2C623D716528652C22786C737822292C773D652E706167657C7C7B7D2C783D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A6128692E7072696D617279297D7D3B66756E637469';
wwv_flow_imp.g_varchar2_table(654) := '6F6E20452865297B666F722876617220743D682865292E7265706C616365282F5B5C5B5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C723D742C6E3D323B735B722E746F4C6F7765724361736528295D3B29723D742E7375';
wwv_flow_imp.g_varchar2_table(655) := '6273747228302C33312D537472696E67286E292E6C656E6774682D31292B225F222B6E2C6E2B2B3B72657475726E20735B722E746F4C6F7765724361736528295D3D21302C727D66756E6374696F6E20432865297B72657475726E7B747970653A227061';
wwv_flow_imp.g_varchar2_table(656) := '747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A612865297D7D7D66756E6374696F6E20542865297B76617220743D7B7374796C653A227468696E222C636F6C6F723A7B617267623A6128657C7C4E65297D7D';
wwv_flow_imp.g_varchar2_table(657) := '3B72657475726E7B746F703A742C6C6566743A742C626F74746F6D3A742C72696768743A747D7D66756E6374696F6E20412865297B76617220743D652E6A6F696E28222C22293B696628742E6C656E6774683C3D3235302626212F5B2C225D2F2E746573';
wwv_flow_imp.g_varchar2_table(658) := '7428652E6A6F696E28222229292972657475726E2722272B742B2722273B6966286D2E7265665B745D2972657475726E206D2E7265665B745D3B6D2E77737C7C286D2E77733D6C2E616464576F726B7368656574284528226E725F6C697374617322292C';
wwv_flow_imp.g_varchar2_table(659) := '7B73746174653A2268696464656E227D29293B76617220723D2B2B6D2E6E3B652E666F72456163682866756E6374696F6E28652C74297B6D2E77732E67657443656C6C28742B312C72292E76616C75653D657D293B766172206E3D6D2E77732E67657443';
wwv_flow_imp.g_varchar2_table(660) := '6F6C756D6E2872292E6C65747465723B72657475726E206D2E7265665B745D3D2227222B6D2E77732E6E616D652B22272124222B6E2B2224313A24222B6E2B2224222B652E6C656E6774682C6D2E7265665B745D7D72657475726E20742E666F72456163';
wwv_flow_imp.g_varchar2_table(661) := '682866756E6374696F6E28722C6E297B76617220733D742E6C656E6774683E313F225F222B286E2B31293A22223B762E666F72456163682866756E6374696F6E286E297B76617220683D4D286E2E6E616D652C72293B62652626742E6C656E6774683E31';
wwv_flow_imp.g_varchar2_table(662) := '262628683D4D286E2E6D657267654E616D657C7C28762E6C656E6774683E313F227B444F432E444F435F4B45597D20222B6E2E6E616D653A227B444F432E444F435F4B45597D22292C7229293B766172206D3D6C2E616464576F726B7368656574284528';
wwv_flow_imp.g_varchar2_table(663) := '68292C7B7061676553657475703A7B6F7269656E746174696F6E3A772E6F7269656E746174696F6E7C7C22706F727472616974222C706170657253697A653A226C6567616C223D3D3D772E73697A653F353A226134223D3D3D772E73697A653F393A312C';
wwv_flow_imp.g_varchar2_table(664) := '666974546F506167653A21302C666974546F57696474683A312C666974546F4865696768743A307D7D292C7A3D6E2E73656374696F6E733F6E2E73656374696F6E732E6D61702866756E6374696F6E2865297B72657475726E226E756D626572223D3D74';
wwv_flow_imp.g_varchar2_table(665) := '7970656F6620653F625B655D3A622E66696C7465722866756E6374696F6E2874297B72657475726E20742E69643D3D3D657D295B305D7D292E66696C74657228426F6F6C65616E293A623B7A3D4A287A2E66696C7465722866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(666) := '72657475726E20657428652C72297D29292E66696C7465722866756E6374696F6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662822786C737822293E3D30292626657428652C72297D293B766172';
wwv_flow_imp.g_varchar2_table(667) := '204E3D342C493D312C443D7B7D2C553D302C563D6E756C6C2C583D6E756C6C2C73653D21312C68653D66756E6374696F6E2865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E22636F6C756D6E6173223D';
wwv_flow_imp.g_varchar2_table(668) := '3D3D742E747970653F4D6174682E6D617828652C516528742C22786C7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B686528742E73656373292B317D2C2D3129293A22677275706F223D3D3D742E';
wwv_flow_imp.g_varchar2_table(669) := '747970653F4D6174682E6D617828652C6865284A6528742C22786C7378222C722929293A4D6174682E6D617828652C227461626C61223D3D3D742E747970653F4728742C722C5028742C7229292E6C656E6774683A226669636861223D3D3D742E747970';
wwv_flow_imp.g_varchar2_table(670) := '653F322A28742E636F6C756D6E737C7C33293A22666F726D756C6172696F223D3D3D742E747970653F322A28742E636F6C756D6E737C7C32293A227461726A65746173223D3D3D742E747970653F596528742C722C69292E6E3A22746578746F223D3D3D';
wwv_flow_imp.g_varchar2_table(671) := '742E747970657C7C22616C65727461223D3D3D742E747970653F343A32297D2C32297D3B66756E6374696F6E20706528652C74297B76617220723D537472696E67286E756C6C3D3D743F22223A74292E6C656E6774683B445B652B3D67655D3D4D617468';
wwv_flow_imp.g_varchar2_table(672) := '2E6D696E2836302C4D6174682E6D617828445B655D7C7C382C722B3229297D7A2E666F72456163682866756E6374696F6E2865297B22636F6C756D6E6173223D3D3D652E747970652626284E3D4D6174682E6D6178284E2C516528652C22786C7378222C';
wwv_flow_imp.g_varchar2_table(673) := '722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B686528742E73656373292B317D2C2D312929292C227461626C61223D3D3D652E74797065262628552B2B2C4E3D4D6174682E6D6178284E2C4728652C722C50';
wwv_flow_imp.g_varchar2_table(674) := '28652C7229292E6C656E67746829292C226669636861223D3D3D652E747970652626284E3D4D6174682E6D6178284E2C322A28652E636F6C756D6E737C7C332929292C22666F726D756C6172696F223D3D3D652E747970652626284E3D4D6174682E6D61';
wwv_flow_imp.g_varchar2_table(675) := '78284E2C322A28652E636F6C756D6E737C7C322929292C227461726A65746173223D3D3D652E747970652626284E3D4D6174682E6D6178284E2C596528652C722C69292E6E29292C22677275706F223D3D3D652E747970652626284E3D4D6174682E6D61';
wwv_flow_imp.g_varchar2_table(676) := '78284E2C6865284A6528652C22786C7378222C72292929297D293B7661722067653D302C6D653D21313B66756E6374696F6E20766528652C74297B72657475726E206D2E67657443656C6C28652C742B6765297D66756E6374696F6E20626528652C742C';
wwv_flow_imp.g_varchar2_table(677) := '722C6E297B6D2E6D6572676543656C6C7328652C742B67652C722C6E2B6765297D66756E6374696F6E20776528652C74297B76617220723D6D2E676574526F772865293B722E6865696768743D4D6174682E6D617828722E6865696768747C7C302C7429';
wwv_flow_imp.g_varchar2_table(678) := '7D66756E6374696F6E20786528652C742C722C6E2C6F297B76617220613D6C2E616464496D616765287B6261736536343A652E646174612C657874656E73696F6E3A226A7067223D3D3D652E6578743F226A706567223A22706E67227D293B6D2E616464';
wwv_flow_imp.g_varchar2_table(679) := '496D61676528612C7B746C3A7B636F6C3A67652C726F773A492D317D2C6578743A7B77696474683A332E37382A742C6865696768743A332E37382A727D2C68797065726C696E6B733A6F3F7B68797065726C696E6B3A6F2C746F6F6C7469703A6F7D3A76';
wwv_flow_imp.g_varchar2_table(680) := '6F696420307D292C492B3D4D6174682E6365696C28332E37382A722F3230292B286E3F303A31297D66756E6374696F6E20536528652C742C722C6E297B626528492C312C492C4E293B766172206F3D766528492C31293B6F2E76616C75653D652C6F2E66';
wwv_flow_imp.g_varchar2_table(681) := '696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6E2626776528492C6D653F4D6174682E6D6178286E2C31352A4D6174682E6365696C28537472696E67';
wwv_flow_imp.g_varchar2_table(682) := '28657C7C2222292E6C656E6774682F4D6174682E6D61782831362C392A4E2929293A6E292C492B2B7D7A2E666F72456163682866756E6374696F6E2074286E297B76617220753D6E2E747970653B69662822636F6C756D6E6173223D3D3D75297B766172';
wwv_flow_imp.g_varchar2_table(683) := '20663D492C683D492C763D67652C623D4E2C773D302C453D6D653B72657475726E206D653D21302C5165286E2C22786C7378222C722C313030292E666F72456163682866756E6374696F6E2865297B76617220723D686528652E73656373293B67653D76';
wwv_flow_imp.g_varchar2_table(684) := '2B772C4E3D722C493D662C652E736563732E666F72456163682874292C683D4D6174682E6D617828682C49292C772B3D722B317D292C67653D762C4E3D622C6D653D452C766F696428493D68297D69662822677275706F223D3D3D75297B766172204A3D';
wwv_flow_imp.g_varchar2_table(685) := '722C45653D733B72657475726E204B65286E2C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C733D45652B652E7375663B766172206F3D4A65286E2C22786C7378222C72292C6C3D493B6966286F2E6C656E6774687C7C6E';
wwv_flow_imp.g_varchar2_table(686) := '2E7469746C65297B6E2E7469746C6526265365284D286E2E7469746C652C72292C43286E2E7469746C6546696C6C7C7C692E7072696D617279292C7B626F6C643A21302C636F6C6F723A7B617267623A61286E2E7469746C65436F6C6F727C7C692E6865';
wwv_flow_imp.g_varchar2_table(687) := '616454657874297D7D2C3230292C6F2E666F72456163682874293B76617220753D4D6174682E6D6178286C2C492D31293B6966286E2E66696C6C29666F722876617220633D6C3B633C3D753B632B2B29666F722876617220663D313B663C3D4E3B662B2B';
wwv_flow_imp.g_varchar2_table(688) := '297B76617220643D766528632C66293B642E66696C6C2626227061747465726E223D3D3D642E66696C6C2E747970657C7C28642E66696C6C3D43286E2E66696C6C29297D6966286E2E626F7264657229666F722876617220683D7B7374796C653A227468';
wwv_flow_imp.g_varchar2_table(689) := '696E222C636F6C6F723A7B617267623A61286E2E626F72646572436F6C6F727C7C4E65297D7D2C703D6C3B703C3D753B702B2B29666F722876617220673D313B673C3D4E3B672B2B29696628703D3D3D6C7C7C703D3D3D757C7C313D3D3D677C7C673D3D';
wwv_flow_imp.g_varchar2_table(690) := '3D4E297B766172206D3D766528702C67292C763D59286D2E626F726465727C7C7B7D293B703D3D3D6C262628762E746F703D68292C703D3D3D75262628762E626F74746F6D3D68292C313D3D3D67262628762E6C6566743D68292C673D3D3D4E26262876';
wwv_flow_imp.g_varchar2_table(691) := '2E72696768743D68292C6D2E626F726465723D767D493D752B312B28303D3D3D6E2E6761703F303A31297D7D292C723D4A2C766F696428733D4565297D69662822686561646572223D3D3D75297B7661722043653D5665286E2C69292C54653D6E2E6669';
wwv_flow_imp.g_varchar2_table(692) := '6C6C3F432843652E66696C6C293A782C41653D7B617267623A612843652E636F6C6F72297D2C7A653D7B626F6C643A21302C73697A653A43652E73697A652C636F6C6F723A41657D2C6B653D7B73697A653A6E2E7375627469746C653F43652E73756253';
wwv_flow_imp.g_varchar2_table(693) := '697A653A43652E726967687453697A652C636F6C6F723A41657D3B6E2E666F6E742626287A652E6E616D653D6B652E6E616D653D43652E666F6E745B315D292C5365284D286E2E7469746C652C72292C54652C7A652C4D6174682E6D61782832362C4D61';
wwv_flow_imp.g_varchar2_table(694) := '74682E726F756E6428312E382A43652E73697A652929292C286E2E72696768747C7C6E2E7375627469746C652926265365285B4D286E2E7375627469746C652C72292C4D286E2E72696768742C72295D2E66696C74657228426F6F6C65616E292E6A6F69';
wwv_flow_imp.g_varchar2_table(695) := '6E28222020207C20202022292C54652C6B652C4D6174682E6D61782831362C4D6174682E726F756E6428312E382A6B652E73697A652929292C492B2B7D656C73652069662822746578746F223D3D3D75295F286E2C72292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(696) := '74696F6E2874297B626528492C312C492C4E293B76617220723D766528492C31292C6F3D4228742C7B666F6E743A6E2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F722C6C696E6B3A692E6C696E6B7D';
wwv_flow_imp.g_varchar2_table(697) := '293B722E76616C75653D7B72696368546578743A6F2E6D61702866756E6374696F6E2865297B72657475726E7B746578743A652E742C666F6E743A7B626F6C643A212821652E622626216E2E626F6C64292C6974616C69633A212821652E692626216E2E';
wwv_flow_imp.g_varchar2_table(698) := '6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F696420302C6E616D653A4C5B652E665D5B315D2C636F6C6F723A652E633F7B617267623A6128652E63297D3A766F696420302C73697A653A';
wwv_flow_imp.g_varchar2_table(699) := '6E2E73697A657C7C31307D7D7D297D3B766172206C3D6F2E66696C7465722866756E6374696F6E2865297B72657475726E20652E687D295B305D3B6C262628722E76616C75653D7B746578743A722E76616C75652C68797065726C696E6B3A6C2E687D29';
wwv_flow_imp.g_varchar2_table(700) := '2C722E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22746F70222C686F72697A6F6E74616C3A226A757374696679223D3D3D6E2E616C69676E3F226A757374696679223A6E2E616C69676E7C7C226C656674227D2C77';
wwv_flow_imp.g_varchar2_table(701) := '6528492C4D6174682E6D61782831352C31352A4D6174682E6365696C28742E6C656E6774682F286D653F4D6174682E6D61782831362C392A4E293A313430292929292C492B2B7D293B656C736520696628226573706163696F223D3D3D7529492B2B3B65';
wwv_flow_imp.g_varchar2_table(702) := '6C73652069662822696D6167656E223D3D3D75297B766172204D653D7574286E2C72293B6966284D65297B7661722046653D6374286E2C4D65293B7865284D652C46652E772C46652E682C21312C52286E2C722C6E2E736F757263653F50286E2C72295B';
wwv_flow_imp.g_varchar2_table(703) := '305D3A6E756C6C29297D7D656C736520696628226772616669636F223D3D3D75297B766172206A653D4574286E2C722C69293B6A6526267865286A652C6A652E776D6D2C6A652E686D6D297D656C73652069662822636F6469676F223D3D3D75297B7661';
wwv_flow_imp.g_varchar2_table(704) := '72204C653D7974286E2C72293B6966284C65297B7661722052653D7874284C65293B69662878652852652C52652E776D6D2C52652E686D6D2C4C652E6C6162656C292C4C652E6C6162656C297B766172205F653D766528492C31293B5F652E76616C7565';
wwv_flow_imp.g_varchar2_table(705) := '3D4C652E746578742C5F652E666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A4C652E7465787453697A657D2C492B3D327D7D7D656C7365206966282273616C746F223D3D3D7529492B2B3B656C736520696628226669636861';
wwv_flow_imp.g_varchar2_table(706) := '223D3D3D75297B7661722047653D50286E2C72295B305D7C7C7B7D2C57653D6E2E636F6C756D6E737C7C332C48653D313B4F6528286E2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C';
wwv_flow_imp.g_varchar2_table(707) := '7C4628652E7768656E2C722C4765297D292C5765292E666F72456163682866756E6374696F6E28652C74297B743E302626492B2B3B766172206C3D652E736F6D652866756E6374696F6E2865297B72657475726E21652E656D707479262622746F70223D';
wwv_flow_imp.g_varchar2_table(708) := '3D3D446528652E662C6E292E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220743D652E663B48653D312B322A652E636F6C3B76617220732C753D446528742C6E292C633D48652B322A65';
wwv_flow_imp.g_varchar2_table(709) := '2E7370616E2D312C663D6E756C6C2C683D4D28742E6C6162656C2C722C4765293B696628226C656674223D3D3D752E706F73297B696628663D766528492C4865292C733D766528492C48652B31292C662E76616C75653D426528682C75292C662E666F6E';
wwv_flow_imp.g_varchar2_table(710) := '743D6E2E6C6162656C436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A61286E2E6C6162656C436F6C6F72297D7D3A7B626F6C643A21307D2C6E2E6C6162656C46696C6C262628662E66696C6C3D43286E2E6C6162656C46696C6C2929';
wwv_flow_imp.g_varchar2_table(711) := '2C6E2E76616C7565436F6C6F72262628732E666F6E743D7B636F6C6F723A7B617267623A61286E2E76616C7565436F6C6F72297D7D292C6E2E67726964262628662E626F726465723D732E626F726465723D54286E2E626F72646572436F6C6F72292C66';
wwv_flow_imp.g_varchar2_table(712) := '2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D292C28652E7370616E3E317C7C6C29262628626528492C48652B312C6C3F492B313A492C63292C6E2E677269642929666F722876617220703D48';
wwv_flow_imp.g_varchar2_table(713) := '652B323B703C3D633B702B2B29766528492C70292E626F726465723D54286E2E626F72646572436F6C6F72293B6C262628626528492C48652C492B312C4865292C662E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170';
wwv_flow_imp.g_varchar2_table(714) := '546578743A21307D292C752E7374796C65642626556528662C752C2131297D656C73657B766172206D3D22746F70223D3D3D752E706F7326266C3F492B313A492C763D226E6F6E65223D3D3D752E706F7326266C3F492B313A6D3B69662822746F70223D';
wwv_flow_imp.g_varchar2_table(715) := '3D3D752E706F73297B28663D766528492C486529292E76616C75653D426528682C75292C633E48652626626528492C48652C492C63292C6E2E67726964262628662E626F726465723D54286E2E626F72646572436F6C6F7229293B76617220623D496528';
wwv_flow_imp.g_varchar2_table(716) := '742C722C4765293B556528662C752C21302C622626622E616C69676E297D733D7665286D2C4865292C28633E48657C7C763E6D2926266265286D2C48652C762C63292C6E2E76616C7565436F6C6F72262628732E666F6E743D7B636F6C6F723A7B617267';
wwv_flow_imp.g_varchar2_table(717) := '623A61286E2E76616C7565436F6C6F72297D7D292C6E2E67726964262628732E626F726465723D54286E2E626F72646572436F6C6F7229297D76617220773D2F5E5C7B5B5E7D7C5D2B5C7D242F2E7465737428742E76616C75657C7C222229262621742E';
wwv_flow_imp.g_varchar2_table(718) := '6D61703F6B28722C742E76616C75652E736C69636528312C2D31292C4765293A6E756C6C3B6F2877292626216728742E666D74293F28732E76616C75653D772C226D6F6E6579223D3D3D742E666D743F732E6E756D466D743D22232C2323302E3030223A';
wwv_flow_imp.g_varchar2_table(719) := '5328742E666D7429262628732E6E756D466D743D7928742E666D7429292C732E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A2264617465223D3D3D742E666D742626642877293F28732E76616C75653D642877292C732E';
wwv_flow_imp.g_varchar2_table(720) := '6E756D466D743D2264642F6D6D2F79797979222C732E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A732E76616C75653D646528742C722C4765293B76617220783D5228742C722C4765293B78262628732E76616C75653D';
wwv_flow_imp.g_varchar2_table(721) := '7B746578743A537472696E6728646528742C722C476529292C68797065726C696E6B3A787D2C732E666F6E743D7B756E6465726C696E653A21302C636F6C6F723A7B617267623A6128692E6C696E6B297D7D292C6E2E67726964262628732E616C69676E';
wwv_flow_imp.g_varchar2_table(722) := '6D656E743D7B686F72697A6F6E74616C3A226C656674222C766572746963616C3A226D6964646C65222C77726170546578743A21307D293B76617220453D496528742C722C4765293B69662845297B696628452E626F6C647C7C452E636F6C6F72297B76';
wwv_flow_imp.g_varchar2_table(723) := '617220413D7B7D3B4F626A6563742E6B65797328732E666F6E747C7C7B7D292E666F72456163682866756E6374696F6E2865297B415B655D3D732E666F6E745B655D7D292C452E626F6C64262628412E626F6C643D2130292C452E636F6C6F7226262841';
wwv_flow_imp.g_varchar2_table(724) := '2E636F6C6F723D7B617267623A6128452E636F6C6F72297D292C732E666F6E743D417D696628452E616C69676E297B766172207A3D7B7D3B4F626A6563742E6B65797328732E616C69676E6D656E747C7C7B7D292E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(725) := '6E2865297B7A5B655D3D732E616C69676E6D656E745B655D7D292C7A2E686F72697A6F6E74616C3D452E616C69676E2C732E616C69676E6D656E743D7A7D452E66696C6C262628732E66696C6C3D4328452E66696C6C29297D226C656674223D3D3D752E';
wwv_flow_imp.g_varchar2_table(726) := '706F733F2870652848652C68292C313D3D3D652E7370616E262670652848652B312C646528742C722C47652929293A313D3D3D652E7370616E262670652848652B312C537472696E6728646528742C722C476529292E73756273747228302C343029297D';
wwv_flow_imp.g_varchar2_table(727) := '7D292C6C2626492B2B7D292C492B3D327D656C736520696628227461726A65746173223D3D3D7529666F72287661722024653D5965286E2C722C69292C71653D303B71653C24652E6974656D732E6C656E6774683B71652B3D24652E6E297B766172205A';
wwv_flow_imp.g_varchar2_table(728) := '653D313B24652E6974656D732E736C6963652871652C71652B24652E6E292E666F72456163682866756E6374696F6E28652C74297B76617220723D766528492C742B31292C6E3D766528492B312C742B31292C6F3D24652E616363656E743F7B6C656674';
wwv_flow_imp.g_varchar2_table(729) := '3A7B7374796C653A22746869636B222C636F6C6F723A7B617267623A612824652E616363656E74297D7D7D3A7B7D3B722E76616C75653D652E6C6162656C2C722E666F6E743D7B73697A653A24652E6C6162656C53697A652B312C636F6C6F723A7B6172';
wwv_flow_imp.g_varchar2_table(730) := '67623A612824652E6C6162656C436F6C6F72297D7D2C6E2E76616C75653D652E76616C75652C6E2E666F6E743D7B626F6C643A21302C73697A653A24652E73697A652C636F6C6F723A7B617267623A6128652E636F6C6F727C7C24652E76616C7565436F';
wwv_flow_imp.g_varchar2_table(731) := '6C6F72297D7D2C5B722C6E5D2E666F72456163682866756E6374696F6E2865297B652E66696C6C3D432824652E66696C6C292C652E626F726465723D6F2C652E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C696E64656E743A';
wwv_flow_imp.g_varchar2_table(732) := '312C77726170546578743A21307D7D292C706528742B312C652E6C6162656C292C706528742B312C537472696E6728652E76616C7565292E73756273747228302C3430292B2220202020202022292C5A653D4D6174682E6D6178285A652C4D6174682E63';
wwv_flow_imp.g_varchar2_table(733) := '65696C28537472696E6728652E76616C7565292E6C656E6774682F343029297D292C776528492C3136292C776528492B312C4D6174682E726F756E6428312E372A24652E73697A65292A5A65292C492B3D337D656C73652069662822666F726D756C6172';
wwv_flow_imp.g_varchar2_table(734) := '696F223D3D3D75297B7661722058653D6E2E636F6C756D6E737C7C322C65743D312C74743D7965286E2C722C73293B4F652874742C5865292E666F72456163682866756E6374696F6E28652C74297B743E302626492B2B3B76617220723D652E736F6D65';
wwv_flow_imp.g_varchar2_table(735) := '2866756E6374696F6E2865297B72657475726E21652E656D707479262622746F70223D3D3D652E662E6C61622E706F737D293B652E666F72456163682866756E6374696F6E2865297B69662821652E656D707479297B76617220743D652E662C6E3D742E';
wwv_flow_imp.g_varchar2_table(736) := '6C61623B65743D312B322A652E636F6C2C6328742E6E616D65293B766172206F3D65742B322A652E7370616E2D312C6C3D22636865636B626F78223D3D3D742E696E7075743F22223A742E76616C75652E6C656E6774683E32303F742E76616C75653A6E';
wwv_flow_imp.g_varchar2_table(737) := '6577204172726179283231292E6A6F696E28227822293B696628226C656674223D3D3D6E2E706F73297B76617220613D766528492C6574292C693D766528492C65742B31293B72657475726E20612E76616C75653D426528742E6C6162656C2C6E292C61';
wwv_flow_imp.g_varchar2_table(738) := '2E666F6E743D7B626F6C643A21307D2C612E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65227D2C28652E7370616E3E317C7C72292626626528492C65742B312C723F492B313A492C6F292C';
wwv_flow_imp.g_varchar2_table(739) := '722626626528492C65742C492B312C6574292C6E2E7374796C65642626556528612C6E2C2131292C4D7428692C742C41292C742E6C696E65733E312626776528723F492B313A492C31352A742E6C696E6573292C70652865742C742E6C6162656C292C76';
wwv_flow_imp.g_varchar2_table(740) := '6F696428313D3D3D652E7370616E262670652865742B312C6C29297D76617220733D22746F70223D3D3D6E2E706F732626723F492B313A492C753D226E6F6E65223D3D3D6E2E706F732626723F492B313A733B69662822746F70223D3D3D6E2E706F7329';
wwv_flow_imp.g_varchar2_table(741) := '7B76617220663D766528492C6574293B662E76616C75653D426528742E6C6162656C2C6E292C6F3E65742626626528492C65742C492C6F292C556528662C6E2C2130297D286F3E65747C7C753E73292626626528732C65742C752C6F292C4D7428766528';
wwv_flow_imp.g_varchar2_table(742) := '732C6574292C742C41292C742E6C696E65733E312626776528752C31352A742E6C696E6573292C313D3D3D652E7370616E262670652865742B312C6C297D7D292C722626492B2B7D292C74742E6C656E67746826262873653D21302C492B3D32297D656C';
wwv_flow_imp.g_varchar2_table(743) := '73652069662822616C65727461223D3D3D752950286E2C72292E66696C7465722866756E6374696F6E2865297B72657475726E2046286E2E7768656E2C722C65297D292E736C69636528302C6E2E656163683F3939393A31292E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(744) := '6E6374696F6E2865297B5365284D286E2E746578742C722C65292C43284F286E2E636F6C6F722C722C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C492B2B3B656C736520696628227461626C61223D3D3D75297B766172';
wwv_flow_imp.g_varchar2_table(745) := '2072743D50286E2C72293B6966282172742E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B766172206E743D47286E2C722C7274293B6966286E2E7469746C65297B626528492C312C';
wwv_flow_imp.g_varchar2_table(746) := '492C6E742E6C656E677468293B766172206F743D766528492C31293B6F742E76616C75653D4D286E2E7469746C652C72292C6F742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6128692E6865616454657874297D7D2C6F742E6669';
wwv_flow_imp.g_varchar2_table(747) := '6C6C3D782C492B2B7D766172206C743D493B6966286E2E67726F757073297B7661722061743D313B57286E2C6E74292E666F72456163682866756E6374696F6E2865297B652E636F6C733E31262621652E6761702626626528492C61742C492C61742B65';
wwv_flow_imp.g_varchar2_table(748) := '2E636F6C732D31293B76617220743D766528492C6174293B696628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B626528492C61742B722C492B312C61742B72293B766172206F3D766528492C61742B72293B6F2E76';
wwv_flow_imp.g_varchar2_table(749) := '616C75653D6E745B652E66726F6D2B725D2E6C6162656C2C6F2E66696C6C3D782C6F2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6128692E6865616454657874297D7D2C6F2E616C69676E6D656E743D7B686F72697A6F6E74616C';
wwv_flow_imp.g_varchar2_table(750) := '3A5065286E745B652E66726F6D2B725D2C6E292C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C70652861742B722C6E745B652E66726F6D2B725D2E6C6162656C297D61742B3D652E636F6C737D656C736520742E76616C';
wwv_flow_imp.g_varchar2_table(751) := '75653D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D782C742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6128692E6865616454657874297D7D2C742E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E7465';
wwv_flow_imp.g_varchar2_table(752) := '72222C766572746963616C3A226D6964646C65227D2C61742B3D652E636F6C737D292C492B2B7D7661722069743D492C73743D7B7D3B6966286E2E67726F757073262657286E2C6E74292E666F72456163682866756E6374696F6E2865297B696628652E';
wwv_flow_imp.g_varchar2_table(753) := '67617029666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B2973745B745D3D317D292C6E742E666F72456163682866756E6374696F6E28652C74297B6966282173745B745D297B76617220723D766528492C742B';
wwv_flow_imp.g_varchar2_table(754) := '31293B722E76616C75653D652E6C6162656C2C722E66696C6C3D782C722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6128692E6865616454657874297D7D2C722E616C69676E6D656E743D7B686F72697A6F6E74616C3A50652865';
wwv_flow_imp.g_varchar2_table(755) := '2C6E292C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C706528742B312C652E6C6162656C297D7D292C492B2B2C2172742E6C656E6774682972657475726E20626528492C312C492C6E742E6C656E677468292C76652849';
wwv_flow_imp.g_varchar2_table(756) := '2C31292E76616C75653D4D286E2E656D707479546578742C72292C766528492C31292E666F6E743D7B6974616C69633A21307D2C766F696428492B3D32293B7661722066743D492C64743D6365286E2C7274292C68743D7565286E292C70743D6E756C6C';
wwv_flow_imp.g_varchar2_table(757) := '2C67743D66756E6374696F6E28652C742C722C6F2C6C2C732C75297B76617220633D6165286E742C742C722C6F292C663D6E652874292C683D66756E6374696F6E2865297B72657475726E20652E66696C6C3D4328692E746F74616C73292C652E666F6E';
wwv_flow_imp.g_varchar2_table(758) := '743D6E2E746F74616C73436F6C6F723F7B626F6C643A21302C636F6C6F723A7B617267623A61286E2E746F74616C73436F6C6F72297D7D3A7B626F6C643A21307D2C657D3B28632E61743E317C7C303D3D3D632E6174292626626528652C312C652C632E';
wwv_flow_imp.g_varchar2_table(759) := '61747C7C6E742E6C656E677468293B76617220673D6828766528652C3129293B72657475726E20672E76616C75653D6F2C672E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D2C303D3D3D632E61742626652B2B2C6E742E666F';
wwv_flow_imp.g_varchar2_table(760) := '72456163682866756E6374696F6E286E2C6F297B69662821286F3C632E617429297B76617220613D6828766528652C6F2B3129292C693D6E2E636F6C3F726528742C6E2E636F6C293A6E756C6C3B69662869297B76617220673D6D2E676574436F6C756D';
wwv_flow_imp.g_varchar2_table(761) := '6E286F2B312B6765292E6C65747465722C763D672B6C2B223A222B672B732C623D6C6528722C692E636F6C2C692E666E292C773D226D696E22213D3D692E666E2626226D617822213D3D692E666E7C7C6E756C6C3D3D3D627C7C6F652862293F6E756C6C';
wwv_flow_imp.g_varchar2_table(762) := '3A642862292C783D6E756C6C3D3D623F6E756C6C3A777C7C286F652862293F4D6174682E726F756E64283130302A4E756D626572286229292F3130303A537472696E67286229293B612E76616C75653D7B666F726D756C613A28753F22535542544F5441';
wwv_flow_imp.g_varchar2_table(763) := '4C28222B4B5B692E666E5D2B222C223A515B692E666E5D2B222822292B762B2229222C726573756C743A787D3B76617220453D22636F756E74223D3D3D692E666E3F22232C232330223A773F2264642F6D6D2F79797979223A53286E2E666D74293F7928';
wwv_flow_imp.g_varchar2_table(764) := '6E2E666D74293A22232C2323302E3030223B612E6E756D466D743D66262665655B692E666E5D3F2722272B65655B692E666E5D2B272022272B453A452C612E616C69676E6D656E743D7B686F72697A6F6E74616C3A227269676874227D2C6E756C6C3D3D';
wwv_flow_imp.g_varchar2_table(765) := '3D787C7C777C7C7065286F2B312C6F652878293F7028782C53286E2E666D7429262622636F756E7422213D3D692E666E3F6E2E666D743A226D6F6E657922293A78297D7D7D292C652B317D3B64742E666F72456163682866756E6374696F6E2865297B69';
wwv_flow_imp.g_varchar2_table(766) := '66282268656164223D3D3D652E6B297B626528492C312C492C6E742E6C656E677468293B76617220743D766528492C31293B72657475726E20742E76616C75653D6665286E2C652C72292C742E666F6E743D7B626F6C643A21307D2C742E66696C6C3D43';
wwv_flow_imp.g_varchar2_table(767) := '28692E67726F7570292C766F696420492B2B7D69662822737562223D3D3D652E6B2972657475726E20493D677428492C68742C652E726F77732C6665286E2C652C72292C70742C492D312C2130292C766F69642870743D6E756C6C293B6E756C6C3D3D3D';
wwv_flow_imp.g_varchar2_table(768) := '707426262870743D49293B76617220733D652E722C753D652E692C633D71286E2C6E74292C663D6A286E2E726F775374796C652C722C73293B6E742E666F72456163682866756E6374696F6E28652C74297B76617220683D766528492C742B31292C763D';
wwv_flow_imp.g_varchar2_table(769) := '4828652C732C72293B696628652E63656C6C297B76617220623D5A28652C732C722C69292C773D742B312B67653B696628682E76616C75653D6E756C6C2C28652E76616C69676E7C7C6329262628682E616C69676E6D656E743D7B686F72697A6F6E7461';
wwv_flow_imp.g_varchar2_table(770) := '6C3A652E616C69676E2C766572746963616C3A652E76616C69676E7C7C637D292C7525323D3D3126262131213D3D6E2E7A65627261262628682E66696C6C3D4328692E7A6562726129292C62297B76617220783D6C2E616464496D616765287B62617365';
wwv_flow_imp.g_varchar2_table(771) := '36343A622E696D2E646174612C657874656E73696F6E3A226A7067223D3D3D622E696D2E6578743F226A706567223A22706E67227D292C453D5228652C722C73293B6D2E616464496D61676528782C7B746C3A7B636F6C3A772D312B2E30382C726F773A';
wwv_flow_imp.g_varchar2_table(772) := '492D312B2E30387D2C6578743A7B77696474683A332E37382A622E772C6865696768743A332E37382A622E687D2C68797065726C696E6B733A453F7B68797065726C696E6B3A452C746F6F6C7469703A457D3A766F696420307D292C776528492C322E38';
wwv_flow_imp.g_varchar2_table(773) := '33352A622E682B34292C445B775D3D4D6174682E6D696E2836302C4D6174682E6D617828445B775D7C7C382C4D6174682E6365696C28332E37382A622E772F37292B3229297D7D656C73657B76617220543B652E69734E756D26266F2876293F28682E76';
wwv_flow_imp.g_varchar2_table(774) := '616C75653D762C682E6E756D466D743D5328543D652E666D74293F792854293A22696E74223D3D3D543F22232C232330223A226D6F6E6579223D3D3D547C7C2F5E6E756D2F2E7465737428547C7C2222293F22232C2323302E222B6E6577204172726179';
wwv_flow_imp.g_varchar2_table(775) := '28312A2828547C7C2222292E73706C697428223A22295B315D7C7C32292B31292E6A6F696E28223022293A2247656E6572616C22293A226461746522213D3D652E666D742626224441544522213D3D28722E545B537472696E67286E2E736F7572636529';
wwv_flow_imp.g_varchar2_table(776) := '2E746F55707065724361736528295D7C7C7B7D295B652E636F6C5D7C7C21642876293F682E76616C75653D6E756C6C3D3D763F6E756C6C3A6728652E666D7429262621652E6D61703F7028762C652E666D74293A537472696E672876293A28682E76616C';
wwv_flow_imp.g_varchar2_table(777) := '75653D642876292C682E6E756D466D743D2264642F6D6D2F7979797922292C682E616C69676E6D656E743D652E76616C69676E7C7C633F7B686F72697A6F6E74616C3A652E616C69676E2C766572746963616C3A652E76616C69676E7C7C637D3A7B686F';
wwv_flow_imp.g_varchar2_table(778) := '72697A6F6E74616C3A652E616C69676E7D3B76617220413D6A28652E63656C6C5374796C652C722C73297C7C663B412626412E66696C6C3F682E66696C6C3D4328412E66696C6C293A7525323D3D3126262131213D3D6E2E7A65627261262628682E6669';
wwv_flow_imp.g_varchar2_table(779) := '6C6C3D4328692E7A6562726129293B766172207A3D7B7D3B28652E626F6C647C7C412626412E626F6C64292626287A2E626F6C643D2130292C28412626412E636F6C6F727C7C652E636F6C6F72292626287A2E636F6C6F723D7B617267623A6128412626';
wwv_flow_imp.g_varchar2_table(780) := '412E636F6C6F727C7C652E636F6C6F72297D292C287A2E626F6C647C7C7A2E636F6C6F7229262628682E666F6E743D7A293B766172206B3D5228652C722C73293B6B26266E756C6C213D7626262222213D3D76262628682E76616C75653D7B746578743A';
wwv_flow_imp.g_varchar2_table(781) := '537472696E67282428652C732C7229292C68797065726C696E6B3A6B7D2C682E666F6E743D7B626F6C643A7A2E626F6C642C756E6465726C696E653A21302C636F6C6F723A7A2E636F6C6F727C7C7B617267623A6128692E6C696E6B297D7D292C706528';
wwv_flow_imp.g_varchar2_table(782) := '742B312C652E69734E756D3F7028762C652E666D74293A76297D7D292C492B2B7D293B766172206D743D492D312C76743D7465286E2E746F74616C73293B69662876742E6C656E677468262628493D677428492C76742C72742C6965286E2C722C727429';
wwv_flow_imp.g_varchar2_table(783) := '2C66742C492D312C21216E2E627265616B427929292C6E2E6772696429666F72287661722062743D54286E2E626F72646572436F6C6F72292C77743D6C743B77743C493B77742B2B29666F72287661722053743D313B53743C3D6E742E6C656E6774683B';
wwv_flow_imp.g_varchar2_table(784) := '53742B2B2976652877742C5374292E626F726465723D62743B31213D3D557C7C6E2E627265616B42797C7C6D657C7C28583D7B66726F6D3A7B726F773A69742C636F6C756D6E3A317D2C746F3A7B726F773A6D742C636F6C756D6E3A6E742E6C656E6774';
wwv_flow_imp.g_varchar2_table(785) := '687D7D2C7A2E696E6465784F66286E293C3D31262628563D697429292C492B2B7D7D292C4F626A6563742E6B6579732844292E666F72456163682866756E6374696F6E2865297B6D2E676574436F6C756D6E282B65292E77696474683D445B655D7D292C';
wwv_flow_imp.g_varchar2_table(786) := '582626286D2E6175746F46696C7465723D58292C562626286D2E76696577733D5B7B73746174653A2266726F7A656E222C7953706C69743A567D5D292C73652626752E70726F746563742626662E70757368286D2E70726F7465637428752E7061737377';
wwv_flow_imp.g_varchar2_table(787) := '6F72642C7B73656C6563744C6F636B656443656C6C733A21302C73656C656374556E6C6F636B656443656C6C733A21302C666F726D6174436F6C756D6E733A21302C666F726D6174526F77733A21307D29292C652E666F6F7465722626286D2E68656164';
wwv_flow_imp.g_varchar2_table(788) := '6572466F6F7465722E6F6464466F6F7465723D22264C2638222B4D28652E666F6F7465722E6C6566742C72292E7265706C616365282F262F672C22262622292E73756273747228302C323030292B222652263850C3A167696E6120265020646520264E22';
wwv_flow_imp.g_varchar2_table(789) := '297D297D292C4565286529262666756E6374696F6E2865297B76617220743D652E646566696E65644E616D65732C723D7426264F626A6563742E6765744F776E50726F706572747944657363726970746F72284F626A6563742E67657450726F746F7479';
wwv_flow_imp.g_varchar2_table(790) := '70654F662874292C226D6F64656C22293B722626722E676574262621742E5F5F6E722626284F626A6563742E646566696E6550726F706572747928742C226D6F64656C222C7B636F6E666967757261626C653A21302C6765743A66756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(791) := '7B72657475726E20722E6765742E63616C6C2874686973292E6D61702866756E6374696F6E2865297B72657475726E7B6E616D653A652E6E616D652C72616E6765733A652E72616E6765732E6D61702866756E6374696F6E2865297B76617220743D2F5E';
wwv_flow_imp.g_varchar2_table(792) := '285B5E27215D2B2921282E2B29242F2E657865632865293B72657475726E20743F2227222B745B315D2B222721222B745B325D3A657D297D7D297D2C7365743A66756E6374696F6E2865297B722E7365742E63616C6C28746869732C65297D7D292C742E';
wwv_flow_imp.g_varchar2_table(793) := '5F5F6E723D2130297D286C292C662E6C656E6774683F50726F6D6973652E616C6C2866292E7468656E2866756E6374696F6E28297B72657475726E206C2E786C73782E777269746542756666657228297D293A6C2E786C73782E77726974654275666665';
wwv_flow_imp.g_varchar2_table(794) := '7228297D7661722046743D7B6C65747465723A5B31323234302C31353834305D2C6C6567616C3A5B31323234302C32303136305D2C61343A5B31313930362C31363833385D7D3B66756E6374696F6E20507428652C742C72297B766172206E3D77696E64';
wwv_flow_imp.g_varchar2_table(795) := '6F772E646F63782C6F3D5B5D2C6C3D4D6174682E726F756E6428322A28652E73697A657C7C3729292C613D6928722E6D75746564293B66756E6374696F6E20732865297B76617220723D4D28652C74292E73706C6974282F285C7B50414745533F5C7D29';
wwv_flow_imp.g_varchar2_table(796) := '2F292C6F3D5B5D3B72657475726E20722E666F72456163682866756E6374696F6E2865297B227B504147457D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E4355525245';
wwv_flow_imp.g_varchar2_table(797) := '4E545D2C73697A653A6C2C636F6C6F723A617D29293A227B50414745537D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E544F54414C5F50414745535D2C73697A653A6C';
wwv_flow_imp.g_varchar2_table(798) := '2C636F6C6F723A617D29293A6526266F2E70757368286E6577206E2E5465787452756E287B746578743A652C73697A653A6C2C636F6C6F723A617D29297D292C6F7D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772';
wwv_flow_imp.g_varchar2_table(799) := '617068287B6368696C6472656E3A7328652E6C656674297D29292C652E726967687426266F2E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E';
wwv_flow_imp.g_varchar2_table(800) := '3A7328652E7269676874297D29292C6F2E6C656E6774683F6F3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D7D766172204F743D22E29FA64E52463A223B66756E6374696F6E206A742865297B72657475726E205374';
wwv_flow_imp.g_varchar2_table(801) := '72696E672865292E7265706C616365282F262F672C2226616D703B22292E7265706C616365282F3C2F672C22266C743B22292E7265706C616365282F3E2F672C222667743B22292E7265706C616365282F222F672C222671756F743B22297D66756E6374';
wwv_flow_imp.g_varchar2_table(802) := '696F6E204C7428652C74297B696628653D652E7265706C616365282F3C773A646F63756D656E7450726F74656374696F6E5B5E3E5D2A5C2F3E2F672C2222292C21742E70726F746563742972657475726E20653B76617220723D273C773A646F63756D65';
wwv_flow_imp.g_varchar2_table(803) := '6E7450726F74656374696F6E20773A656469743D22666F726D732220773A656E666F7263656D656E743D223122273B696628742E70617373776F7264297B766172206E3D66756E6374696F6E2865297B76617220743D6E65772055696E74384172726179';
wwv_flow_imp.g_varchar2_table(804) := '2865292C723D22756E646566696E656422213D747970656F662077696E646F7726262877696E646F772E63727970746F7C7C77696E646F772E6D7343727970746F293B696628722626722E67657452616E646F6D56616C75657329722E67657452616E64';
wwv_flow_imp.g_varchar2_table(805) := '6F6D56616C7565732874293B656C736520666F7228766172206E3D303B6E3C653B6E2B2B29745B6E5D3D4D6174682E666C6F6F72283235362A4D6174682E72616E646F6D2829293B72657475726E20747D283136292C6F3D3165353B722B3D2720773A63';
wwv_flow_imp.g_varchar2_table(806) := '7279707450726F7669646572547970653D227273614145532220773A6372797074416C676F726974686D436C6173733D22686173682220773A6372797074416C676F726974686D547970653D2274797065416E792220773A6372797074416C676F726974';
wwv_flow_imp.g_varchar2_table(807) := '686D5369643D2231342220773A63727970745370696E436F756E743D22272B6F2B272220773A686173683D22272B6174284D6528742E70617373776F72642C6E2C6F29292B272220773A73616C743D22272B6174286E292B2722277D722B3D222F3E223B';
wwv_flow_imp.g_varchar2_table(808) := '766172206C3D5B223C773A6576656E416E644F646448656164657273222C223C773A636F6D706174222C223C2F773A73657474696E67733E225D2E6D61702866756E6374696F6E2874297B72657475726E20652E696E6465784F662874297D292E66696C';
wwv_flow_imp.g_varchar2_table(809) := '7465722866756E6374696F6E2865297B72657475726E20653E3D307D295B305D3B72657475726E20652E73756273747228302C6C292B722B652E737562737472286C297D66756E6374696F6E20497428652C742C72297B72657475726E20722E70726F74';
wwv_flow_imp.g_varchar2_table(810) := '6563742626722E70617373776F726426264D6528722E70617373776F72642C6E65772055696E74384172726179283136292C30292C77696E646F772E4A535A69702E6C6F61644173796E632865292E7468656E2866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(811) := '726E2050726F6D6973652E616C6C285B652E66696C652822776F72642F646F63756D656E742E786D6C22292E6173796E632822737472696E6722292C652E66696C652822776F72642F73657474696E67732E786D6C22292E6173796E632822737472696E';
wwv_flow_imp.g_varchar2_table(812) := '6722295D292E7468656E2866756E6374696F6E286E297B766172206F3D302C6C3D6E65772052656745787028273C773A723E283C773A7250723E283F3A283F213C2F773A7250723E295B5C5C735C5C535D292A3C2F773A7250723E293F3C773A7420786D';
wwv_flow_imp.g_varchar2_table(813) := '6C3A73706163653D227072657365727665223EE29FA64E52463A285C5C642B29E29FA73C2F773A743E3C2F773A723E272C226722292C613D6E5B305D2E7265706C616365286C2C66756E6374696F6E28652C722C6E297B72657475726E206F2B2B2C6675';
wwv_flow_imp.g_varchar2_table(814) := '6E6374696F6E28652C742C72297B766172206E3D273C773A616C69617320773A76616C3D22272B6A7428652E6C6162656C7C7C652E6E616D65292B27222F3E3C773A74616720773A76616C3D22272B6A7428652E6E616D65292B27222F3E3C773A696420';
wwv_flow_imp.g_varchar2_table(815) := '773A76616C3D22272B742B27222F3E272B28652E726561644F6E6C793F273C773A6C6F636B20773A76616C3D22736474436F6E74656E744C6F636B6564222F3E273A2222293B69662822636865636B626F78223D3D3D652E696E707574297B766172206F';
wwv_flow_imp.g_varchar2_table(816) := '3D722E7265706C616365282F3C773A72466F6E74735B5E3E5D2A5C2F3E2F2C2222292E7265706C61636528223C773A7250723E222C273C773A7250723E3C773A72466F6E747320773A61736369693D224D5320476F746869632220773A65617374417369';
wwv_flow_imp.g_varchar2_table(817) := '613D224D5320476F746869632220773A68416E73693D224D5320476F746869632220773A63733D224D5320476F74686963222F3E27293B72657475726E223C773A7364743E3C773A73647450723E222B6F2B6E2B273C7731343A636865636B626F783E3C';
wwv_flow_imp.g_varchar2_table(818) := '7731343A636865636B6564207731343A76616C3D22272B28652E636865636B65643F313A30292B27222F3E3C7731343A636865636B65645374617465207731343A76616C3D223236313222207731343A666F6E743D224D5320476F74686963222F3E3C77';
wwv_flow_imp.g_varchar2_table(819) := '31343A756E636865636B65645374617465207731343A76616C3D223236313022207731343A666F6E743D224D5320476F74686963222F3E3C2F7731343A636865636B626F783E3C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E27';
wwv_flow_imp.g_varchar2_table(820) := '2B6F2B223C773A743E222B28652E636865636B65643F6D653A7665292B223C2F773A743E3C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D766172206C3D21652E76616C75652C613D652E76616C75657C7C652E706C616365';
wwv_flow_imp.g_varchar2_table(821) := '686F6C6465727C7C28226C697374223D3D3D652E696E7075743F22456C696A6120756E20656C656D656E746F2E223A6E65772041727261792839292E6A6F696E2822E280822229293B72657475726E223C773A7364743E3C773A73647450723E222B722B';
wwv_flow_imp.g_varchar2_table(822) := '6E2B286C3F223C773A73686F77696E67506C634864722F3E223A2222292B28226C697374223D3D3D652E696E7075743F223C773A64726F70446F776E4C6973743E222B652E6F7074696F6E732E6D61702866756E6374696F6E2865297B72657475726E27';
wwv_flow_imp.g_varchar2_table(823) := '3C773A6C6973744974656D20773A646973706C6179546578743D22272B6A742865292B272220773A76616C75653D22272B6A742865292B27222F3E277D292E6A6F696E282222292B223C2F773A64726F70446F776E4C6973743E223A223C773A74657874';
wwv_flow_imp.g_varchar2_table(824) := '222B28226D756C74696C696E65223D3D3D652E696E7075743F2720773A6D756C74694C696E653D223122273A2222292B222F3E22292B223C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E222B722B537472696E672861292E7370';
wwv_flow_imp.g_varchar2_table(825) := '6C6974282F5C723F5C6E2F292E6D61702866756E6374696F6E2865297B72657475726E273C773A7420786D6C3A73706163653D227072657365727665223E272B6A742865292B223C2F773A743E227D292E6A6F696E28223C773A62722F3E22292B223C2F';
wwv_flow_imp.g_varchar2_table(826) := '773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D28745B2B6E5D2C3165332B4E756D626572286E292C727C7C223C773A7250723E3C2F773A7250723E22297D293B6966286F213D3D742E6C656E677468297468726F77206E657720';
wwv_flow_imp.g_varchar2_table(827) := '4572726F722822576F72643A206E6F207365207075646965726F6E20636F6C6F63617220746F646F73206C6F732063616D706F732064656C20666F726D756C6172696F2028222B6F2B2220646520222B742E6C656E6774682B22292E22293B7265747572';
wwv_flow_imp.g_varchar2_table(828) := '6E20652E66696C652822776F72642F646F63756D656E742E786D6C222C61292C652E66696C652822776F72642F73657474696E67732E786D6C222C4C74286E5B315D2C7229292C652E67656E65726174654173796E63287B747970653A22617272617962';
wwv_flow_imp.g_varchar2_table(829) := '7566666572222C636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D297D297D297D66756E6374696F6E20527428652C742C72297B766172206E3D77696E646F772E646F6378';
wwv_flow_imp.g_varchar2_table(830) := '2C6F3D74742865292C6C3D652E706167657C7C7B7D2C613D5B5D2C733D776528292C753D46745B6C2E73697A657C7C226C6574746572225D7C7C46742E6C65747465722C633D226C616E647363617065223D3D3D6C2E6F7269656E746174696F6E2C663D';
wwv_flow_imp.g_varchar2_table(831) := '4D6174682E726F756E642835362E372A286C2E6D617267696E7C7C31322E3729292C643D28633F755B315D3A755B305D292D322A662C683D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A2246464646';
wwv_flow_imp.g_varchar2_table(832) := '4646227D2C703D7B746F703A682C626F74746F6D3A682C6C6566743A682C72696768743A682C696E73696465486F72697A6F6E74616C3A682C696E73696465566572746963616C3A687D2C673D7B7374796C653A6E2E426F726465725374796C652E5349';
wwv_flow_imp.g_varchar2_table(833) := '4E474C452C73697A653A322C636F6C6F723A22424643394434227D2C6D3D7B746F703A672C626F74746F6D3A672C6C6566743A672C72696768743A672C696E73696465486F72697A6F6E74616C3A672C696E73696465566572746963616C3A677D3B6675';
wwv_flow_imp.g_varchar2_table(834) := '6E6374696F6E20762865297B69662821652972657475726E206D3B76617220743D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A692865297D3B72657475726E7B746F703A742C626F74746F6D3A';
wwv_flow_imp.g_varchar2_table(835) := '742C6C6566743A742C72696768743A742C696E73696465486F72697A6F6E74616C3A742C696E73696465566572746963616C3A747D7D76617220623D4D6174682E726F756E6428322A286F2E666F6E7453697A657C7C3729293B66756E6374696F6E2077';
wwv_flow_imp.g_varchar2_table(836) := '28652C74297B72657475726E20743D747C7C7B7D2C6E6577206E2E5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C756E646572';
wwv_flow_imp.g_varchar2_table(837) := '6C696E653A742E756E6465726C696E653F7B7D3A766F696420302C73697A653A742E73697A657C7C622C636F6C6F723A742E636F6C6F723F6928742E636F6C6F72293A766F696420302C666F6E743A742E666F6E747C7C2243616C69627269227D297D66';
wwv_flow_imp.g_varchar2_table(838) := '756E6374696F6E207928652C74297B76617220723D7728652C743D747C7C7B7D293B696628742E6C696E6B26262222213D3D537472696E67286E756C6C3D3D653F22223A6529297B766172206C3D592874293B6C2E756E6465726C696E653D21302C6C2E';
wwv_flow_imp.g_varchar2_table(839) := '636F6C6F723D742E6C696E6B436F6C6F727C7C742E636F6C6F727C7C6F2E6C696E6B2C723D6E6577206E2E45787465726E616C48797065726C696E6B287B6C696E6B3A742E6C696E6B2C6368696C6472656E3A5B7728652C6C295D7D297D72657475726E';
wwv_flow_imp.g_varchar2_table(840) := '206E6577206E2E506172616772617068287B6368696C6472656E3A5B725D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A227269676874223D3D3D742E616C69676E3F6E2E416C69676E6D656E74547970';
wwv_flow_imp.g_varchar2_table(841) := '652E52494748543A2263656E746572223D3D3D742E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546547D297D66756E6374696F6E207828652C74297B76617220723D766F696420';
wwv_flow_imp.g_varchar2_table(842) := '30213D3D28743D747C7C7B7D292E7061643F742E7061643A33303B72657475726E206E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B7928652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B746F703A';
wwv_flow_imp.g_varchar2_table(843) := '722C626F74746F6D3A722C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A742E6D6964646C657C7C226D6964646C65223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E43454E5445523A22626F74';
wwv_flow_imp.g_varchar2_table(844) := '746F6D223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E424F54544F4D3A22746F70223D3D3D742E76616C69676E3F6E2E566572746963616C416C69676E2E544F503A766F696420302C73686164696E673A742E66696C6C3F7B74';
wwv_flow_imp.g_varchar2_table(845) := '7970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928742E66696C6C297D3A766F696420307D297D66756E6374696F6E205328297B72657475726E206E6577206E2E506172616772617068287B63';
wwv_flow_imp.g_varchar2_table(846) := '68696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D66756E6374696F6E204528652C742C72297B72657475726E206E6577206E2E506172616772617068287B6368696C6472656E3A5B7728652C7B62';
wwv_flow_imp.g_varchar2_table(847) := '6F6C643A742E626F6C642C73697A653A742E73697A653F4D6174682E726F756E6428322A742E73697A65293A31342C636F6C6F723A742E636F6C6F727D295D2C73706163696E673A7B6265666F72653A302C61667465723A32307D2C616C69676E6D656E';
wwv_flow_imp.g_varchar2_table(848) := '743A227269676874223D3D3D723F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D723F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C73686164696E67';
wwv_flow_imp.g_varchar2_table(849) := '3A742E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928742E66696C6C297D3A766F696420307D297D66756E6374696F6E204328652C742C722C6F2C6C2C61297B76617220';
wwv_flow_imp.g_varchar2_table(850) := '693D6E6577206E2E496D61676552756E287B747970653A226A7067223D3D3D652E6578743F226A7067223A22706E67222C646174613A652E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A7429';
wwv_flow_imp.g_varchar2_table(851) := '2C6865696768743A4D6174682E726F756E6428332E37382A72297D7D293B72657475726E206E6577206E2E506172616772617068287B616C69676E6D656E743A227269676874223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74547970652E5249';
wwv_flow_imp.g_varchar2_table(852) := '4748543A2263656E746572223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C73706163696E673A7B61667465723A766F69642030213D3D6C3F6C3A4D6174682E';
wwv_flow_imp.g_varchar2_table(853) := '726F756E642835362E372A28766F69642030213D3D6F2E6761703F6F2E6761703A3329297D2C6368696C6472656E3A5B613F6E6577206E2E45787465726E616C48797065726C696E6B287B6C696E6B3A612C6368696C6472656E3A5B695D7D293A695D7D';
wwv_flow_imp.g_varchar2_table(854) := '297D76617220543D28633F755B315D3A755B305D292F35362E372C413D28633F755B305D3A755B315D292F35362E373B66756E6374696F6E207A2874297B76617220722C6F3D437428652C74293B696628216F2972657475726E206E756C6C3B7472797B';
wwv_flow_imp.g_varchar2_table(855) := '723D66756E6374696F6E28652C742C72297B766172206E3D372E35362C6F3D6874284D6174682E726F756E6428742A6E292C4D6174682E726F756E6428722A6E29292C6C3D6F2E676574436F6E746578742822326422292C613D2248656C766574696361';
wwv_flow_imp.g_varchar2_table(856) := '2C20417269616C2C2073616E732D7365726966223B6C2E666F6E743D22626F6C64203236362E37313638707820222B613B76617220693D547428652C6C2E6D6561737572655465787428652E74657874292E77696474682F6E2C742C72293B6C2E666F6E';
wwv_flow_imp.g_varchar2_table(857) := '743D22626F6C6420222B2E333532382A692A6E2B22707820222B612C6C2E7472616E736C617465286F2E77696474682F322C6F2E6865696768742F32292C6C2E726F74617465282D652E616E676C652A4D6174682E50492F313830292C6C2E676C6F6261';
wwv_flow_imp.g_varchar2_table(858) := '6C416C7068613D652E6F7061636974792C6C2E66696C6C5374796C653D652E636F6C6F722C6C2E74657874416C69676E3D2263656E746572222C6C2E74657874426173656C696E653D226D6964646C65222C6C2E66696C6C5465787428652E746578742C';
wwv_flow_imp.g_varchar2_table(859) := '302C30293B76617220733D6474286F2E746F4461746155524C2822696D6167652F706E6722292C6F2E77696474682C6F2E686569676874293B72657475726E20732E776D6D3D742C732E686D6D3D722C737D286F2C542C41297D63617463682865297B72';
wwv_flow_imp.g_varchar2_table(860) := '657475726E206E756C6C7D72657475726E206E6577206E2E486561646572287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B6E6577206E2E496D61676552756E287B747970653A22706E67222C64617461';
wwv_flow_imp.g_varchar2_table(861) := '3A722E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A54292C6865696768743A4D6174682E726F756E6428332E37382A41297D2C666C6F6174696E673A7B686F72697A6F6E74616C506F736974';
wwv_flow_imp.g_varchar2_table(862) := '696F6E3A7B72656C61746976653A6E2E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6E2E486F72697A6F6E74616C506F736974696F6E416C69676E2E43454E5445527D2C766572746963616C';
wwv_flow_imp.g_varchar2_table(863) := '506F736974696F6E3A7B72656C61746976653A6E2E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6E2E566572746963616C506F736974696F6E416C69676E2E43454E5445527D2C626568696E6444';
wwv_flow_imp.g_varchar2_table(864) := '6F63756D656E743A21302C616C6C6F774F7665726C61703A21302C777261703A7B747970653A6E2E546578745772617070696E67547970652E4E4F4E457D7D7D295D7D295D7D297D766172206B3D742E6D61702866756E6374696F6E28722C6C297B7661';
wwv_flow_imp.g_varchar2_table(865) := '7220683D5B5D2C673D742E6C656E6774683E313F225F222B286C2B31293A22223B716528652C22646F6378222C72292E666F72456163682866756E6374696F6E2074286C297B76617220753D6C2E747970653B69662822636F6C756D6E6173223D3D3D75';
wwv_flow_imp.g_varchar2_table(866) := '297B76617220633D5165286C2C22646F6378222C722C642F35362E37293B69662821632E6C656E6774682972657475726E3B76617220663D682C6D3D642C543D4D6174682E726F756E642835362E372A28766F69642030213D3D6C2E636F6C4761703F4E';
wwv_flow_imp.g_varchar2_table(867) := '756D626572286C2E636F6C476170293A3429292C413D5B5D2C7A3D5B5D3B72657475726E20632E666F72456163682866756E6374696F6E28652C72297B766172206F3D723D3D3D632E6C656E6774682D312C6C3D4D6174682E726F756E642835362E372A';
wwv_flow_imp.g_varchar2_table(868) := '652E77293B683D5B5D2C643D6C2C652E736563732E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774682D315D696E7374616E63656F66206E2E5061726167726170687C7C682E70757368287928222229292C412E7075736828';
wwv_flow_imp.g_varchar2_table(869) := '6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A682C77696474683A7B73697A653A6C2B286F3F303A54292C747970653A6E2E5769647468547970652E4458417D2C6D617267696E733A7B746F703A302C626F74746F6D3A302C6C656674';
wwv_flow_imp.g_varchar2_table(870) := '3A302C72696768743A6F3F303A547D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E544F507D29292C7A2E70757368286C2B286F3F303A5429297D292C643D6D2C766F696428683D66292E70757368286E6577206E2E5461';
wwv_flow_imp.g_varchar2_table(871) := '626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A417D295D2C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E57696474';
wwv_flow_imp.g_varchar2_table(872) := '68733A7A2C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D69662822677275706F223D3D3D75297B766172206B3D722C4E3D672C493D682C443D642C553D4D6174682E726F756E';
wwv_flow_imp.g_varchar2_table(873) := '642835362E372A28766F69642030213D3D6C2E70616464696E673F4E756D626572286C2E70616464696E67293A6C2E626F726465727C7C6C2E66696C6C3F333A3029292C483D6C2E626F726465723F76286C2E626F72646572436F6C6F727C7C4E65293A';
wwv_flow_imp.g_varchar2_table(874) := '703B72657475726E204B65286C2C72292E666F72456163682866756E6374696F6E2865297B723D652E6374782C673D4E2B652E7375663B76617220613D4A65286C2C22646F6378222C72293B696628612E6C656E6774687C7C6C2E7469746C65297B683D';
wwv_flow_imp.g_varchar2_table(875) := '5B5D2C643D4D6174682E6D6178283630302C442D322A55292C612E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774682D315D696E7374616E63656F66206E2E5061726167726170687C7C682E70757368287928222229293B76';
wwv_flow_imp.g_varchar2_table(876) := '617220733D5B5D3B6C2E7469746C652626732E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B78284D286C2E7469746C652C72292C7B626F6C643A21302C73697A653A4D6174682E726F75';
wwv_flow_imp.g_varchar2_table(877) := '6E6428322A286C2E7469746C6553697A657C7C286F2E666F6E7453697A657C7C37292B3229292C636F6C6F723A6C2E7469746C65436F6C6F727C7C6F2E68656164546578742C66696C6C3A6C2E7469746C6546696C6C7C7C6F2E7072696D6172792C7061';
wwv_flow_imp.g_varchar2_table(878) := '643A36307D295D7D29292C732E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A2131213D3D6C2E6B656570546F6765746865722C6368696C6472656E3A5B6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A';
wwv_flow_imp.g_varchar2_table(879) := '682C6D617267696E733A7B746F703A552C626F74746F6D3A552C6C6566743A552C72696768743A557D2C73686164696E673A6C2E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C';
wwv_flow_imp.g_varchar2_table(880) := '3A69286C2E66696C6C297D3A766F696420307D295D7D29292C643D442C28683D49292E70757368286E6577206E2E5461626C65287B726F77733A732C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C75';
wwv_flow_imp.g_varchar2_table(881) := '6D6E5769647468733A5B645D2C626F72646572733A482C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D7D292C683D492C643D442C723D6B2C766F696428673D4E297D69662822686561646572223D3D3D';
wwv_flow_imp.g_varchar2_table(882) := '75297B76617220563D5665286C2C6F292C593D6C2E666F6E743F562E666F6E745B315D3A766F696420302C583D5B6E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78284D286C2E7469746C652C72292C7B626F6C643A21302C73697A65';
wwv_flow_imp.g_varchar2_table(883) := '3A4D6174682E726F756E6428322A562E73697A65292C636F6C6F723A562E636F6C6F722C66696C6C3A562E66696C6C2C666F6E743A597D292C78284D286C2E72696768742C72292C7B73697A653A4D6174682E726F756E6428322A562E72696768745369';
wwv_flow_imp.g_varchar2_table(884) := '7A65292C636F6C6F723A562E636F6C6F722C66696C6C3A562E66696C6C2C616C69676E3A227269676874222C666F6E743A592C6D6964646C653A21216C2E726967687453697A657D295D7D295D3B6C2E7375627469746C652626582E70757368286E6577';
wwv_flow_imp.g_varchar2_table(885) := '206E2E5461626C65526F77287B6368696C6472656E3A5B78284D286C2E7375627469746C652C72292C7B73697A653A4D6174682E726F756E6428322A562E73756253697A65292C636F6C6F723A562E636F6C6F722C66696C6C3A562E66696C6C2C737061';
wwv_flow_imp.g_varchar2_table(886) := '6E3A322C666F6E743A597D295D7D29292C682E70757368286E6577206E2E5461626C65287B726F77733A582C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B4D6174682E72';
wwv_flow_imp.g_varchar2_table(887) := '6F756E64282E372A64292C4D6174682E726F756E64282E332A64295D2C626F72646572733A707D292C532829297D656C73652069662822746578746F223D3D3D75297B766172204A3D7B72696768743A6E2E416C69676E6D656E74547970652E52494748';
wwv_flow_imp.g_varchar2_table(888) := '542C63656E7465723A6E2E416C69676E6D656E74547970652E43454E5445522C6A7573746966793A6E2E416C69676E6D656E74547970652E4A55535449464945447D3B5F286C2C72292E666F72456163682866756E6374696F6E2874297B682E70757368';
wwv_flow_imp.g_varchar2_table(889) := '286E6577206E2E506172616772617068287B616C69676E6D656E743A4A5B6C2E616C69676E5D7C7C6E2E416C69676E6D656E74547970652E4C4546542C696E64656E743A6C2E696E64656E743F7B6C6566743A4D6174682E726F756E642835362E372A6C';
wwv_flow_imp.g_varchar2_table(890) := '2E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A766F69642030213D3D6C2E7061726167726170684761703F4D6174682E726F756E642835362E372A6C2E706172616772617068476170293A3132302C6C696E653A4D6174';
wwv_flow_imp.g_varchar2_table(891) := '682E726F756E64283234302A286C2E6C696E654865696768747C7C312E313529297D2C6368696C6472656E3A4228742C7B666F6E743A6C2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A6C2E636F6C6F722C6C696E6B';
wwv_flow_imp.g_varchar2_table(892) := '3A6F2E6C696E6B7D292E7265647563652866756E6374696F6E28652C74297B76617220723D6E6577206E2E5465787452756E287B746578743A742E742C626F6C643A212821742E622626216C2E626F6C64292C6974616C6963733A212821742E69262621';
wwv_flow_imp.g_varchar2_table(893) := '6C2E6974616C6963292C73697A653A322A286C2E73697A657C7C3130292C756E6465726C696E653A742E753F7B7D3A766F696420302C737472696B653A2121742E732C636F6C6F723A742E633F6928742E63293A766F696420302C666F6E743A4C5B742E';
wwv_flow_imp.g_varchar2_table(894) := '665D5B315D7D293B72657475726E20742E683F652E6C6173742626652E6C6173742E683D3D3D742E683F28652E6C6173742E72756E732E707573682872292C65293A28652E6C6173743D7B683A742E682C72756E733A5B725D7D2C652E7075736828652E';
wwv_flow_imp.g_varchar2_table(895) := '6C617374292C65293A28652E707573682872292C652E6C6173743D6E756C6C2C65297D2C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652E72756E733F6E6577206E2E45787465726E616C48797065726C696E6B287B6C696E6B3A';
wwv_flow_imp.g_varchar2_table(896) := '652E682C6368696C6472656E3A652E72756E737D293A657D297D29297D297D656C736520696628226573706163696F223D3D3D7529682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6166';
wwv_flow_imp.g_varchar2_table(897) := '7465723A4D6174682E726F756E642835362E372A286C2E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D75297B696628766F696420303D3D3D6C2E7831297B766172204B3D4D6174682E726F756E642835362E372A';
wwv_flow_imp.g_varchar2_table(898) := '286C2E77696474687C7C3029292C513D4B3F4D6174682E6D617828302C4D6174682E726F756E642828642D4B292F3229293A303B682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B616674';
wwv_flow_imp.g_varchar2_table(899) := '65723A4D6174682E726F756E642835362E372A28766F69642030213D3D6C2E6761703F6C2E6761703A3229297D2C696E64656E743A2263656E746572223D3D3D6C2E616C69676E3F7B6C6566743A512C72696768743A517D3A227269676874223D3D3D6C';
wwv_flow_imp.g_varchar2_table(900) := '2E616C69676E3F7B6C6566743A322A517D3A7B72696768743A322A517D2C626F726465723A7B626F74746F6D3A7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A4D6174682E6D617828322C4D6174682E726F756E6428';
wwv_flow_imp.g_varchar2_table(901) := '32302A286C2E746869636B6E6573737C7C2E332929292C636F6C6F723A69286C2E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C73652069662822696D6167656E223D3D3D75297B7661722065653D7574286C2C72';
wwv_flow_imp.g_varchar2_table(902) := '293B6966286565297B7661722072653D6374286C2C6565293B682E7075736828432865652C72652E772C72652E682C6C2C766F696420302C52286C2C722C6C2E736F757263653F50286C2C72295B305D3A6E756C6C2929297D7D656C7365206966282267';
wwv_flow_imp.g_varchar2_table(903) := '72616669636F223D3D3D75297B766172206E653D4574286C2C722C6F293B6E652626682E707573682843286E652C6E652E776D6D2C6E652E686D6D2C6C29297D656C73652069662822636F6469676F223D3D3D75297B766172206F653D7974286C2C7229';
wwv_flow_imp.g_varchar2_table(904) := '3B6966286F65297B766172206C653D7874286F65293B682E707573682843286C652C6C652E776D6D2C6C652E686D6D2C6C2C6F652E6C6162656C3F303A766F6964203029292C6F652E6C6162656C2626682E70757368286E6577206E2E50617261677261';
wwv_flow_imp.g_varchar2_table(905) := '7068287B616C69676E6D656E743A227269676874223D3D3D6C2E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6C2E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C';
wwv_flow_imp.g_varchar2_table(906) := '69676E6D656E74547970652E4C4546542C696E64656E743A227269676874223D3D3D6C2E616C69676E7C7C2263656E746572223D3D3D6C2E616C69676E3F766F696420303A7B6C6566743A4D6174682E6D617828302C4D6174682E726F756E6428286C65';
wwv_flow_imp.g_varchar2_table(907) := '2E776D6D2D6F652E746578742E6C656E6774682A6F652E7465787453697A652A2E333532382A2E36292F322A35362E3729297D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D6C2E6761703F6C';
wwv_flow_imp.g_varchar2_table(908) := '2E6761703A3329297D2C6368696C6472656E3A5B6E6577206E2E5465787452756E287B746578743A6F652E746578742C666F6E743A22436F7572696572204E6577222C73697A653A322A6F652E7465787453697A652C636F6C6F723A69286F652E636F6C';
wwv_flow_imp.g_varchar2_table(909) := '6F72297D295D7D29297D7D656C7365206966282273616C746F223D3D3D7529682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B6E6577206E2E50616765427265616B5D7D29293B656C73652069662822666963686122';
wwv_flow_imp.g_varchar2_table(910) := '3D3D3D75297B7661722073653D50286C2C72295B305D7C7C7B7D2C68653D6C2E636F6C756D6E737C7C332C6D653D5B5D2C76653D5B5D3B6966284F6528286C2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B7265747572';
wwv_flow_imp.g_varchar2_table(911) := '6E21652E7768656E7C7C4628652E7768656E2C722C7365297D292C6865292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E6374696F6E2865297B76617220743D652E662C613D21216C2E677269642C733D613F3630';
wwv_flow_imp.g_varchar2_table(912) := '3A766F696420303B696628652E656D707479297B76617220753D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D3B76652E70757368286E6577206E2E5461626C6543656C6C287B';
wwv_flow_imp.g_varchar2_table(913) := '6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C756D6E5370616E3A322A652E7370616E2C626F72646572733A613F7B746F703A752C626F74746F6D3A752C6C6566743A752C7269676874';
wwv_flow_imp.g_varchar2_table(914) := '3A757D3A766F696420307D29297D656C73657B76617220632C663D446528742C6C292C643D4D28742E6C6162656C2C722C7365293B696628226C65667422213D3D662E706F73297B76617220683D496528742C722C7365292C703D5B5D2C673D613F3630';
wwv_flow_imp.g_varchar2_table(915) := '3A33303B72657475726E22746F70223D3D3D662E706F732626702E70757368284528426528642C66292C662C662E616C69676E7C7C682626682E616C69676E7C7C226C6566742229292C702E70757368287928646528742C722C7365292C7B73697A653A';
wwv_flow_imp.g_varchar2_table(916) := '31372C636F6C6F723A682626682E636F6C6F727C7C6C2E76616C7565436F6C6F722C626F6C643A683F682E626F6C643A766F696420302C616C69676E3A683F682E616C69676E3A766F696420302C6C696E6B3A5228742C722C7365292C6C696E6B436F6C';
wwv_flow_imp.g_varchar2_table(917) := '6F723A682626682E636F6C6F727C7C6F2E6C696E6B7D29292C766F69642076652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A702C636F6C756D6E5370616E3A322A652E7370616E2C6D617267696E733A7B746F703A67';
wwv_flow_imp.g_varchar2_table(918) := '2C626F74746F6D3A672C6C6566743A36302C72696768743A36307D2C766572746963616C416C69676E3A613F6E2E566572746963616C416C69676E2E43454E5445523A766F696420302C73686164696E673A682626682E66696C6C3F7B747970653A6E2E';
wwv_flow_imp.g_varchar2_table(919) := '53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6928682E66696C6C297D3A766F696420307D29297D76652E70757368287828426528642C66292C662E7374796C65643F7B626F6C643A662E626F6C642C73697A';
wwv_flow_imp.g_varchar2_table(920) := '653A662E73697A653F4D6174682E726F756E6428322A662E73697A65293A31372C66696C6C3A662E66696C6C2C636F6C6F723A662E636F6C6F722C616C69676E3A662E616C69676E2C7061643A732C6D6964646C653A617D3A7B626F6C643A21302C7369';
wwv_flow_imp.g_varchar2_table(921) := '7A653A31372C66696C6C3A6C2E6C6162656C46696C6C2C636F6C6F723A6C2E6C6162656C436F6C6F722C7061643A732C6D6964646C653A617D292C28633D496528742C722C7365292C7828646528742C722C7365292C7B73697A653A31372C636F6C6F72';
wwv_flow_imp.g_varchar2_table(922) := '3A632626632E636F6C6F727C7C6C2E76616C7565436F6C6F722C7061643A732C6D6964646C653A612C626F6C643A633F632E626F6C643A766F696420302C616C69676E3A633F632E616C69676E3A766F696420302C66696C6C3A633F632E66696C6C3A76';
wwv_flow_imp.g_varchar2_table(923) := '6F696420302C6C696E6B3A5228742C722C7365292C6C696E6B436F6C6F723A632626632E636F6C6F727C7C6F2E6C696E6B2C7370616E3A652E7370616E3E313F322A652E7370616E2D313A766F696420307D2929297D7D293B666F722876617220743D32';
wwv_flow_imp.g_varchar2_table(924) := '2A4C652865293B743C322A68653B742B2B2976652E70757368287828222229293B6D652E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A76657D29292C76653D5B5D7D292C6D652E6C656E677468297B7661722062653D5B5D';
wwv_flow_imp.g_varchar2_table(925) := '3B6966286C2E677269647C7C41727261792E69734172726179286C2E6C6162656C57696474687329297B666F72287661722077653D5B5D2C78653D302C53653D303B53653C68653B53652B2B2977652E70757368284D6174682E726F756E642835362E37';
wwv_flow_imp.g_varchar2_table(926) := '2A4665286C2C53652929292C78652B3D77655B53655D3B7661722045653D4D6174682E6D6178283630302C4D6174682E726F756E642828642D7865292F686529293B666F722853653D303B53653C68653B53652B2B2962652E707573682877655B53655D';
wwv_flow_imp.g_varchar2_table(927) := '2C4565297D656C736520666F72287661722043653D303B43653C322A68653B43652B2B2962652E70757368284D6174682E726F756E6428642F28322A68652929293B682E70757368286E6577206E2E5461626C65287B726F77733A6D652C77696474683A';
wwv_flow_imp.g_varchar2_table(928) := '7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A62652C626F72646572733A6C2E677269643F76286C2E626F72646572436F6C6F727C7C4E65293A702C6C61796F75743A6C2E677269643F6E2E';
wwv_flow_imp.g_varchar2_table(929) := '5461626C654C61796F7574547970652E46495845443A766F696420307D292C532829297D7D656C736520696628227461726A65746173223D3D3D75297B7661722054653D5965286C2C722C6F293B6966282154652E6974656D732E6C656E677468297265';
wwv_flow_imp.g_varchar2_table(930) := '7475726E3B666F72287661722041653D4D6174682E726F756E642835362E372A54652E63617264476170292C7A653D4D6174682E666C6F6F722828642D41652A2854652E6E2D3129292F54652E6E292C6B653D5B5D2C4D653D5B5D2C6A653D303B6A653C';
wwv_flow_imp.g_varchar2_table(931) := '54652E6E3B6A652B2B296A6526264D652E70757368284165292C4D652E70757368287A65293B666F72287661722052653D7B7374796C653A6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C5565';
wwv_flow_imp.g_varchar2_table(932) := '3D303B55653C54652E6974656D732E6C656E6774683B55652B3D54652E6E297B666F7228766172205F653D5B5D2C47653D303B47653C54652E6E3B47652B2B297B7661722057653D54652E6974656D735B55652B47655D3B476526265F652E7075736828';
wwv_flow_imp.g_varchar2_table(933) := '6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F72646572733A7B746F703A52652C626F74746F6D3A52652C6C6566743A52652C72696768743A52657D7D29292C57653F5F652E70757368286E6577206E2E5461';
wwv_flow_imp.g_varchar2_table(934) := '626C6543656C6C287B6368696C6472656E3A5B792857652E6C6162656C2C7B73697A653A322A54652E6C6162656C53697A652C636F6C6F723A54652E6C6162656C436F6C6F727D292C6E6577206E2E506172616772617068287B6368696C6472656E3A5B';
wwv_flow_imp.g_varchar2_table(935) := '772857652E76616C75652C7B626F6C643A21302C73697A653A322A54652E73697A652C636F6C6F723A57652E636F6C6F727C7C54652E76616C7565436F6C6F727D295D2C73706163696E673A7B6265666F72653A34302C61667465723A307D7D295D2C6D';
wwv_flow_imp.g_varchar2_table(936) := '617267696E733A7B746F703A3130302C626F74746F6D3A3130302C6C6566743A3136302C72696768743A3130307D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E43454E5445522C73686164696E673A7B747970653A6E2E';
wwv_flow_imp.g_varchar2_table(937) := '53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A692854652E66696C6C297D2C626F72646572733A7B746F703A52652C626F74746F6D3A52652C72696768743A52652C6C6566743A54652E616363656E743F7B73';
wwv_flow_imp.g_varchar2_table(938) := '74796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A32342C636F6C6F723A692854652E616363656E74297D3A52657D7D29293A5F652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222';
wwv_flow_imp.g_varchar2_table(939) := '295D2C626F72646572733A7B746F703A52652C626F74746F6D3A52652C6C6566743A52652C72696768743A52657D7D29297D6B652E6C656E67746826266B652E70757368286E6577206E2E5461626C65526F77287B6865696768743A7B76616C75653A41';
wwv_flow_imp.g_varchar2_table(940) := '652C72756C653A6E2E48656967687452756C652E45584143547D2C6368696C6472656E3A4D652E6D61702866756E6374696F6E28297B72657475726E206E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B79282222295D2C626F726465';
wwv_flow_imp.g_varchar2_table(941) := '72733A7B746F703A52652C626F74746F6D3A52652C6C6566743A52652C72696768743A52657D7D297D297D29292C6B652E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5F657D29297D682E';
wwv_flow_imp.g_varchar2_table(942) := '70757368286E6577206E2E5461626C65287B726F77733A6B652C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A4D652C626F72646572733A702C6C61796F75743A6E2E546162';
wwv_flow_imp.g_varchar2_table(943) := '6C654C61796F7574547970652E46495845447D292C532829297D656C73652069662822666F726D756C6172696F223D3D3D75297B7661722048653D6C2E636F6C756D6E737C7C322C24653D5B5D2C71653D5B5D2C5A653D312C58653D7965286C2C722C67';
wwv_flow_imp.g_varchar2_table(944) := '292C65743D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A342C636F6C6F723A69286765297D3B6966284F652858652C4865292E666F72456163682866756E6374696F6E2865297B652E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(945) := '74696F6E2865297B76617220743D652E663B696628652E656D7074792971652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D2C636F6C75';
wwv_flow_imp.g_varchar2_table(946) := '6D6E5370616E3A322A652E7370616E7D29293B656C73657B7328742E6E616D65293B76617220723D612E6C656E6774683B612E707573682874292C5A653D4D6174682E6D6178285A652C742E6C696E6573293B766172206F3D742E6C696E65733E313F6E';
wwv_flow_imp.g_varchar2_table(947) := '2E566572746963616C416C69676E2E544F503A6E2E566572746963616C416C69676E2E43454E5445522C6C3D742E6C61623B696628226C65667422213D3D6C2E706F73297B76617220753D6E6577206E2E5461626C65287B77696474683A7B73697A653A';
wwv_flow_imp.g_varchar2_table(948) := '3130302C747970653A6E2E5769647468547970652E50455243454E544147457D2C626F72646572733A702C726F77733A5B6E6577206E2E5461626C65526F77287B6865696768743A742E6C696E65733E313F7B76616C75653A4D6174682E726F756E6428';
wwv_flow_imp.g_varchar2_table(949) := '3233302A742E6C696E65732B3630292C72756C653A6E2E48656967687452756C652E41544C454153547D3A766F696420302C6368696C6472656E3A5B6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E50617261677261';
wwv_flow_imp.g_varchar2_table(950) := '7068287B6368696C6472656E3A5B77284F742B722B22E29FA7222C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C766572746963616C416C69676E3A6F2C6D617267696E733A7B746F703A3430';
wwv_flow_imp.g_varchar2_table(951) := '2C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A65742C626F74746F6D3A65742C6C6566743A65742C72696768743A65747D2C73686164696E673A7B747970653A6E2E53686164696E6754797065';
wwv_flow_imp.g_varchar2_table(952) := '2E434C4541522C636F6C6F723A226175746F222C66696C6C3A69287065297D7D295D7D295D7D292C633D22746F70223D3D3D6C2E706F733F5B4528426528742E6C6162656C2C6C292C6C2C6C2E616C69676E7C7C226C65667422295D3A5B5D3B72657475';
wwv_flow_imp.g_varchar2_table(953) := '726E20632E7075736828752C6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A302C61667465723A302C6C696E653A3132302C6C696E6552756C653A6E2E4C696E6552756C65547970652E';
wwv_flow_imp.g_varchar2_table(954) := '45584143547D7D29292C766F69642071652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A632C636F6C756D6E5370616E3A322A652E7370616E2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E';
wwv_flow_imp.g_varchar2_table(955) := '2E544F502C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D29297D71652E70757368286E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6C2E7374796C65643F79284265';
wwv_flow_imp.g_varchar2_table(956) := '28742E6C6162656C2C6C292C7B626F6C643A6C2E626F6C642C73697A653A6C2E73697A653F4D6174682E726F756E6428322A6C2E73697A65293A31372C636F6C6F723A6C2E636F6C6F722C616C69676E3A6C2E616C69676E7D293A7928742E6C6162656C';
wwv_flow_imp.g_varchar2_table(957) := '2C7B626F6C643A21302C73697A653A31377D295D2C766572746963616C416C69676E3A6F2C73686164696E673A6C2E7374796C656426266C2E66696C6C3F7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F22';
wwv_flow_imp.g_varchar2_table(958) := '2C66696C6C3A69286C2E66696C6C297D3A766F696420302C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D292C6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577';
wwv_flow_imp.g_varchar2_table(959) := '206E2E506172616772617068287B6368696C6472656E3A5B77284F742B722B22E29FA7222C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C636F6C756D6E5370616E3A652E7370616E3E313F32';
wwv_flow_imp.g_varchar2_table(960) := '2A652E7370616E2D313A766F696420302C766572746963616C416C69676E3A6F2C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A65742C626F74746F6D3A';
wwv_flow_imp.g_varchar2_table(961) := '65742C6C6566743A65742C72696768743A65747D2C73686164696E673A7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A69287065297D7D29297D7D293B666F722876617220743D322A4C65';
wwv_flow_imp.g_varchar2_table(962) := '2865293B743C322A48653B742B2B2971652E70757368287828222229293B24652E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A71652C63616E7453706C69743A21302C6865696768743A5A653E313F7B76616C75653A4D61';
wwv_flow_imp.g_varchar2_table(963) := '74682E726F756E64283233302A5A652B313230292C72756C653A6E2E48656967687452756C652E41544C454153547D3A766F696420307D29292C71653D5B5D2C5A653D317D292C24652E6C656E677468297B7661722074743D5B5D2C72743D4D6174682E';
wwv_flow_imp.g_varchar2_table(964) := '726F756E642835362E372A286C2E6C6162656C57696474687C7C333229292C6E743D4D6174682E6D6178283630302C4D6174682E726F756E642828642D72742A4865292F486529293B72742A48652B3630302A48653E6426262872743D6E743D4D617468';
wwv_flow_imp.g_varchar2_table(965) := '2E726F756E6428642F28322A48652929293B666F7228766172206F743D303B6F743C48653B6F742B2B2974742E707573682872742C6E74293B682E70757368286E6577206E2E5461626C65287B726F77733A24652C77696474683A7B73697A653A642C74';
wwv_flow_imp.g_varchar2_table(966) := '7970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A74742C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C532829297D7D656C73652069662822616C657274';
wwv_flow_imp.g_varchar2_table(967) := '61223D3D3D752950286C2C72292E66696C7465722866756E6374696F6E2865297B72657475726E2046286C2E7768656E2C722C65297D292E736C69636528302C6C2E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B682E';
wwv_flow_imp.g_varchar2_table(968) := '70757368286E6577206E2E5461626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B6368696C6472656E3A5B78284D286C2E746578742C722C65292C7B626F6C643A21302C73697A653A31372C66696C6C3A4F286C2E636F6C6F722C722C';
wwv_flow_imp.g_varchar2_table(969) := '65297C7C2223453645434632227D295D7D295D2C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A707D292C532829297D293B656C736520696628';
wwv_flow_imp.g_varchar2_table(970) := '227461626C61223D3D3D75297B766172206C743D50286C2C72293B696628216C742E6C656E67746826262131213D3D6C2E68696465456D7074792626216C2E656D707479546578742972657475726E3B7661722061743D47286C2C722C6C74292C69743D';
wwv_flow_imp.g_varchar2_table(971) := '5B5D3B6C2E7469746C65262669742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A5B78284D286C2E7469746C652C72292C7B626F6C643A21302C636F6C6F723A6F2E68656164546578';
wwv_flow_imp.g_varchar2_table(972) := '742C66696C6C3A6F2E7072696D6172792C7370616E3A61742E6C656E6774682C73697A653A622B327D295D7D29292C6C2E67726F757073262669742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C';
wwv_flow_imp.g_varchar2_table(973) := '6472656E3A57286C2C6174292E6D61702866756E6374696F6E2865297B72657475726E207828652E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A226365';
wwv_flow_imp.g_varchar2_table(974) := '6E746572222C7370616E3A652E636F6C737D297D297D29292C69742E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A61742E6D61702866756E6374696F6E2865297B72657475726E2078';
wwv_flow_imp.g_varchar2_table(975) := '28652E6C6162656C2C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A506528652C6C297D297D297D29292C6C742E6C656E6774687C7C69742E70757368286E6577206E2E5461626C';
wwv_flow_imp.g_varchar2_table(976) := '65526F77287B6368696C6472656E3A5B78284D286C2E656D707479546578742C72292C7B6974616C69633A21302C7370616E3A61742E6C656E6774687D295D7D29293B7661722073743D7565286C292C66743D7B7D2C64743D71286C2C6174292C68743D';
wwv_flow_imp.g_varchar2_table(977) := '66756E6374696F6E2865297B76617220743D7828652E746578742C7B626F6C643A21302C616C69676E3A226C656674222C66696C6C3A6F2E746F74616C732C7370616E3A652E61747C7C61742E6C656E6774682C636F6C6F723A6C2E746F74616C73436F';
wwv_flow_imp.g_varchar2_table(978) := '6C6F727D292C723D652E63656C6C732E736C69636528652E6174292E6D61702866756E6374696F6E2865297B72657475726E207828652C7B626F6C643A21302C616C69676E3A227269676874222C66696C6C3A6F2E746F74616C732C636F6C6F723A6C2E';
wwv_flow_imp.g_varchar2_table(979) := '746F74616C73436F6C6F727D297D293B72657475726E20303D3D3D652E61743F5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D7D292C6E6577206E2E5461626C65526F77287B63616E7453706C';
wwv_flow_imp.g_varchar2_table(980) := '69743A21302C6368696C6472656E3A727D295D3A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D2E636F6E6361742872297D295D7D3B6365286C2C6C74292E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(981) := '6F6E2865297B696628226865616422213D3D652E6B296966282273756222213D3D652E6B297B76617220743D652E722C613D652E692C733D6A286C2E726F775374796C652C722C74293B69742E70757368286E6577206E2E5461626C65526F77287B6361';
wwv_flow_imp.g_varchar2_table(982) := '6E7453706C69743A21302C6368696C6472656E3A61742E6D61702866756E6374696F6E28652C75297B76617220632C662C643D6A28652E63656C6C5374796C652C722C74297C7C737C7C7B7D3B696628652E63656C6C297B76617220683D5A28652C742C';
wwv_flow_imp.g_varchar2_table(983) := '722C6F292C703D642E66696C6C7C7C286125323D3D3126262131213D3D6C2E7A656272613F6F2E7A656272613A6E756C6C293B6826262866745B755D3D4D6174682E6D61782866745B755D7C7C302C682E7729293B76617220673D652E76616C69676E7C';
wwv_flow_imp.g_varchar2_table(984) := '7C64743B72657475726E206E6577206E2E5461626C6543656C6C287B766572746963616C416C69676E3A22746F70223D3D3D673F6E2E566572746963616C416C69676E2E544F503A22626F74746F6D223D3D3D673F6E2E566572746963616C416C69676E';
wwv_flow_imp.g_varchar2_table(985) := '2E424F54544F4D3A6E2E566572746963616C416C69676E2E43454E5445522C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A703F7B747970653A6E2E53686164696E67';
wwv_flow_imp.g_varchar2_table(986) := '547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A692870297D3A766F696420302C6368696C6472656E3A5B6E6577206E2E506172616772617068287B73706163696E673A7B6265666F72653A302C61667465723A307D2C616C6967';
wwv_flow_imp.g_varchar2_table(987) := '6E6D656E743A227269676874223D3D3D652E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A226C656674223D3D3D652E616C69676E3F6E2E416C69676E6D656E74547970652E4C4546543A6E2E416C69676E6D656E74547970652E';
wwv_flow_imp.g_varchar2_table(988) := '43454E5445522C6368696C6472656E3A683F5B28633D6E6577206E2E496D61676552756E287B747970653A226A7067223D3D3D682E696D2E6578743F226A7067223A22706E67222C646174613A682E696D2E6275662C7472616E73666F726D6174696F6E';
wwv_flow_imp.g_varchar2_table(989) := '3A7B77696474683A4D6174682E726F756E6428332E37382A682E77292C6865696768743A4D6174682E726F756E6428332E37382A682E68297D7D292C663D5228652C722C74292C663F6E6577206E2E45787465726E616C48797065726C696E6B287B6C69';
wwv_flow_imp.g_varchar2_table(990) := '6E6B3A662C6368696C6472656E3A5B635D7D293A63295D3A5B5D7D295D7D297D72657475726E2078282428652C742C72292C7B76616C69676E3A652E76616C69676E7C7C64742C616C69676E3A652E616C69676E2C626F6C643A652E626F6C647C7C642E';
wwv_flow_imp.g_varchar2_table(991) := '626F6C642C636F6C6F723A642E636F6C6F727C7C652E636F6C6F722C6C696E6B3A5228652C722C74292C6C696E6B436F6C6F723A642E636F6C6F727C7C652E636F6C6F727C7C6F2E6C696E6B2C66696C6C3A642E66696C6C7C7C286125323D3D31262621';
wwv_flow_imp.g_varchar2_table(992) := '31213D3D6C2E7A656272613F6F2E7A656272613A6E756C6C297D297D297D29297D656C73652068742861652861742C73742C652E726F77732C6665286C2C652C722929292E666F72456163682866756E6374696F6E2865297B69742E707573682865297D';
wwv_flow_imp.g_varchar2_table(993) := '293B656C73652069742E70757368286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B78286665286C2C652C72292C7B626F6C643A21302C66696C6C3A6F2E67726F75702C7370616E3A61742E6C656E67';
wwv_flow_imp.g_varchar2_table(994) := '74687D295D7D29297D292C7465286C2E746F74616C73292E6C656E67746826266C742E6C656E677468262668742861652861742C7465286C2E746F74616C73292C6C742C6965286C2C722C6C742929292E666F72456163682866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(995) := '7B69742E707573682865297D293B7661722070743D61742E6D61702866756E6374696F6E28652C74297B72657475726E20652E77696474683F652E77696474682F32303A66745B745D3F4D6174682E6D617828312C2866745B745D2B34292F3230293A31';
wwv_flow_imp.g_varchar2_table(996) := '7D292C67743D70742E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C6D743D70742E6D61702866756E6374696F6E2865297B72657475726E204D6174682E666C6F6F7228642A652F6774297D293B682E707573';
wwv_flow_imp.g_varchar2_table(997) := '68286E6577206E2E5461626C65287B726F77733A69742C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A6D742C626F72646572733A21313D3D3D6C2E677269643F703A76286C';
wwv_flow_imp.g_varchar2_table(998) := '2E677269643F6C2E626F72646572436F6C6F727C7C4E653A6E756C6C297D292C532829297D7D293B766172206D3D652E666F6F7465722C543D7A2872293B72657475726E7B686561646572733A543F7B64656661756C743A547D3A766F696420302C7072';
wwv_flow_imp.g_varchar2_table(999) := '6F706572746965733A7B706167653A7B73697A653A7B77696474683A755B305D2C6865696768743A755B315D2C6F7269656E746174696F6E3A633F6E2E506167654F7269656E746174696F6E2E4C414E4453434150453A6E2E506167654F7269656E7461';
wwv_flow_imp.g_varchar2_table(1000) := '74696F6E2E504F5254524149547D2C6D617267696E3A7B746F703A662C626F74746F6D3A662C6C6566743A662C72696768743A667D7D7D2C666F6F746572733A6D3F7B64656661756C743A6E6577206E2E466F6F746572287B6368696C6472656E3A5074';
wwv_flow_imp.g_varchar2_table(1001) := '286D2C722C6F297D297D3A766F696420302C6368696C6472656E3A682E6C656E6774683F683A5B79282222295D7D7D292C4E3D6E6577206E2E446F63756D656E74287B63726561746F723A226E6F76615265706F7274222C7469746C653A4D28652E7469';
wwv_flow_imp.g_varchar2_table(1002) := '746C657C7C22222C745B305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A6B7D292C493D6E2E5061636B65722E746F426C6F623F6E2E5061636B65722E746F426C6F62284E292E7468656E2866756E6374696F6E2865297B72657475726E';
wwv_flow_imp.g_varchar2_table(1003) := '20652E61727261794275666665723F652E617272617942756666657228293A657D293A6E2E5061636B65722E746F427566666572284E293B72657475726E20612E6C656E6774683F492E7468656E2866756E6374696F6E2874297B72657475726E204974';
wwv_flow_imp.g_varchar2_table(1004) := '28742C612C786528652C7229297D293A497D7661722044743D7B7D3B66756E6374696F6E2055742865297B76617220743D652E73706C697428227C22292C723D745B305D2E7472696D28292C6E3D745B315D3F745B315D2E7472696D28293A6E756C6C3B';
wwv_flow_imp.g_varchar2_table(1005) := '72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E223D3D3D722972657475726E20653B666F7228766172206F3D722E73706C697428222E22292C6C3D742626742E73636F70654C6973743F742E73636F70654C6973742E736C69';
wwv_flow_imp.g_varchar2_table(1006) := '636528292E7265766572736528293A5B655D2C613D303B613C6C2E6C656E6774683B612B2B297B666F722876617220693D6C5B615D2C733D21302C753D303B753C6F2E6C656E6774683B752B2B297B69662841727261792E697341727261792869292626';
wwv_flow_imp.g_varchar2_table(1007) := '753E30262628693D695B305D292C6E756C6C3D3D697C7C226F626A65637422213D747970656F6620697C7C21286F5B755D696E206929297B733D21313B627265616B7D693D695B6F5B755D5D7D696628732972657475726E206E26262141727261792E69';
wwv_flow_imp.g_varchar2_table(1008) := '7341727261792869293F7028692C6E293A697D7D7D7D66756E6374696F6E20427428652C74297B76617220723D6E65772077696E646F772E50697A5A69702865292C6E3D6E657728302C77696E646F772E646F637874656D706C617465722928722C7B70';
wwv_flow_imp.g_varchar2_table(1009) := '61726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A55742C6E756C6C4765747465723A66756E6374696F6E28297B72657475726E22227D7D293B72657475726E206E2E72656E6465722866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(1010) := '297B76617220742C723D7B7D3B666F72287420696E20652E706172616D737C7C7B7D29725B745D3D652E706172616D735B745D3B666F72287420696E20652E646F637C7C7B7D29725B745D3D652E646F635B745D3B666F72287420696E20652E5329725B';
wwv_flow_imp.g_varchar2_table(1011) := '745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D7528292C722E544F4441593D6328292C727D287429292C50726F6D6973652E7265736F6C7665286E';
wwv_flow_imp.g_varchar2_table(1012) := '2E6765745A697028292E67656E6572617465287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445227D29297D66756E6374696F6E205F742865297B76617220743D7B7D2C723D7B7D3B72657475726E20';
wwv_flow_imp.g_varchar2_table(1013) := '4F626A6563742E6B65797328657C7C7B7D292E666F72456163682866756E6374696F6E286E297B766172206F3D655B6E5D2C6C3D6F2E636F6C737C7C5B5D3B725B6E5D3D7B7D2C6C2E666F72456163682866756E6374696F6E2865297B725B6E5D5B652E';
wwv_flow_imp.g_varchar2_table(1014) := '6E616D655D3D652E747970657D292C745B6E5D3D286F2E726F77737C7C5B5D292E6D61702866756E6374696F6E2865297B76617220743D7B7D3B72657475726E206C2E666F72456163682866756E6374696F6E28722C6E297B745B722E6E616D655D3D65';
wwv_flow_imp.g_varchar2_table(1015) := '5B6E5D7D292C747D297D292C7B533A742C543A727D7D66756E6374696F6E20477428652C74297B76617220723D652E532E444F43533B69662821722972657475726E5B7B533A652E532C543A652E542C646F633A7B7D2C706172616D733A747D5D3B7661';
wwv_flow_imp.g_varchar2_table(1016) := '72206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B69662822444F435322213D3D7426264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E6361';
wwv_flow_imp.g_varchar2_table(1017) := '6C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B745D3D7B7D3B652E535B745D2E666F72456163682866756E6374696F6E2865297B76617220743D537472696E6728652E444F435F4B4559293B28725B745D3D725B745D7C7C5B';
wwv_flow_imp.g_varchar2_table(1018) := '5D292E707573682865297D297D7D292C722E6D61702866756E6374696F6E2872297B766172206F3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B6F5B745D3D6E5B745D3F6E5B74';
wwv_flow_imp.g_varchar2_table(1019) := '5D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B745D7D292C6F2E444F43533D5B725D2C7B533A6F2C543A652E542C646F633A722C706172616D733A747D7D297D66756E6374696F6E2057742865297B76617220743D646F63756D';
wwv_flow_imp.g_varchar2_table(1020) := '656E742E676574456C656D656E744279496428226E722D6176616E636522293B653F28747C7C2828743D646F63756D656E742E637265617465456C656D656E7428226469762229292E69643D226E722D6176616E6365222C742E73657441747472696275';
wwv_flow_imp.g_varchar2_table(1021) := '74652822726F6C65222C2273746174757322292C742E7374796C652E637373546578743D22706F736974696F6E3A66697865643B72696768743A323470783B626F74746F6D3A323470783B7A2D696E6465783A313030303B70616464696E673A31347078';
wwv_flow_imp.g_varchar2_table(1022) := '20313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A653A313370783B626F782D736861646F773A30203870782032347078207267626128302C302C';
wwv_flow_imp.g_varchar2_table(1023) := '302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287429292C742E696E6E657248544D4C3D273C7370616E20636C6173733D2266612066612D7370696E6E65722066612D616E69';
wwv_flow_imp.g_varchar2_table(1024) := '6D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B263C3E225D2F672C66756E6374696F6E2865297B72657475726E7B2226223A2226616D703B';
wwv_flow_imp.g_varchar2_table(1025) := '222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B655D7D29293A742626742E72656D6F766528297D66756E6374696F6E20487428652C74297B69662865262621652E636C6F736564297472797B6966282266';
wwv_flow_imp.g_varchar2_table(1026) := '756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F616465724D73672977696E646F772E636F744C6F616465724D736728652C74293B656C73657B76617220723D652E646F63756D656E742E676574456C656D656E74427949642822';
wwv_flow_imp.g_varchar2_table(1027) := '6D736722293B72262628722E74657874436F6E74656E743D74297D7D63617463682865297B7D7D66756E6374696F6E20247428652C74297B7472797B77696E646F772E617065782626617065782E6576656E742626617065782E6576656E742E74726967';
wwv_flow_imp.g_varchar2_table(1028) := '67657228646F63756D656E742C226E6F76617265706F72742D222B652C74297D63617463682865297B7D7D66756E6374696F6E2056742865297B77696E646F772E617065782626617065782E6D6573736167653F617065782E6D6573736167652E616C65';
wwv_flow_imp.g_varchar2_table(1029) := '72742865293A77696E646F772E616C6572742865297D66756E6374696F6E2059742865297B77696E646F772E617065782626617065782E6D6573736167652626617065782E6D6573736167652E73686F7750616765537563636573732865297D76617220';
wwv_flow_imp.g_varchar2_table(1030) := '71743D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E73707265616473686565746D6C2E7368656574222C64';
wwv_flow_imp.g_varchar2_table(1031) := '6F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F726470726F63657373696E676D6C2E646F63756D656E74227D2C5A743D7B7064663A22706466222C786C73783A2278';
wwv_flow_imp.g_varchar2_table(1032) := '6C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E20587428652C742C72297B766172206E3D4D28652E66696C654E616D657C7C227265706F727465222C74292C6F3D5A745B725D';
wwv_flow_imp.g_varchar2_table(1033) := '3B72657475726E2068286E3D6E2E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C222229292B222E222B6F7D66756E6374696F6E204A7428652C742C722C6E297B72657475726E22706466223D3D3D653F7A7428742C722C6E';
wwv_flow_imp.g_varchar2_table(1034) := '2E686F6F6B73293A22786C7378223D3D3D653F4E7428742C722C722E6C656E6774682C6E293A22646F6378223D3D3D653F527428742C722C6E293A22646F63782D74656D706C617465223D3D3D653F286F3D6E2E74656D706C61746555726C2C6F3F286F';
wwv_flow_imp.g_varchar2_table(1035) := '3D6F74286F292C44745B6F5D3F50726F6D6973652E7265736F6C76652844745B6F5D293A6665746368286F2C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B2974';
wwv_flow_imp.g_varchar2_table(1036) := '68726F77206E6577204572726F7228224E6F207365207075646F20646573636172676172206C6120706C616E74696C6C612028222B652E7374617475732B222922293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E';
wwv_flow_imp.g_varchar2_table(1037) := '6374696F6E2865297B72657475726E2044745B6F5D3D652C657D29293A50726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C612055524C206465206C6120706C616E74696C6C6120576F72642028617472696275746F20';
wwv_flow_imp.g_varchar2_table(1038) := '22506C616E74696C6C6120576F726422292E272929292E7468656E2866756E6374696F6E2865297B72657475726E20427428652C725B305D297D293A50726F6D6973652E72656A656374286E6577204572726F722822466F726D61746F206E6F20736F70';
wwv_flow_imp.g_varchar2_table(1039) := '6F727461646F3A20222B6529293B766172206F7D66756E6374696F6E204B7428652C74297B76617220722C6E3D747228652E6C61796F7574292C6F3D7B7D3B666F72287220696E2065296F5B725D3D655B725D3B72657475726E206F2E6C61796F75743D';
wwv_flow_imp.g_varchar2_table(1040) := '6E2C6974286E292E7468656E2866756E6374696F6E28297B72657475726E2066756E6374696F6E28652C74297B76617220723D747228652E6C61796F7574292C6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F';
wwv_flow_imp.g_varchar2_table(1041) := '6378225D3A5B652E666F726D61747C7C22706466225D2C6F3D5F742874292C6C3D4774286F2C652E706172616D737C7C7B7D292C613D652E6F75747075747C7C2266696C65223B696628216C2E6C656E6774682972657475726E2050726F6D6973652E72';
wwv_flow_imp.g_varchar2_table(1042) := '656A656374286E6577204572726F7228652E656D7074794D6573736167657C7C722E656D7074794D6573736167657C7C224E6F20686179206461746F7320706172612067656E6572617220656C207265706F7274652E2229293B696628722E6261746368';
wwv_flow_imp.g_varchar2_table(1043) := '2626722E62617463682E6D6178446F637326266C2E6C656E6774683E722E62617463682E6D6178446F63732972657475726E2050726F6D6973652E72656A656374286E6577204572726F722822456C206C6F74652073757065726120656C206DC3A17869';
wwv_flow_imp.g_varchar2_table(1044) := '6D6F20646520222B722E62617463682E6D6178446F63732B2220646F63756D656E746F732E2229293B6966282266696C65223D3D3D612626313D3D3D6C2E6C656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D612626313D3D';
wwv_flow_imp.g_varchar2_table(1045) := '3D6E2E6C656E677468262622646F63782D74656D706C61746522213D3D6E5B305D297B76617220693D6E5B305D3B72657475726E204A7428692C722C6C2C65292E7468656E2866756E6374696F6E2874297B766172206E3D587428722C6C5B305D2C6929';
wwv_flow_imp.g_varchar2_table(1046) := '3B6966286C2E6C656E6774683E31297B76617220613D722E6261746368262628722E62617463682E6D657267654E616D657C7C722E62617463682E7A69704E616D65297C7C722E66696C654E616D657C7C227265706F727465223B6E3D5874287B66696C';
wwv_flow_imp.g_varchar2_table(1047) := '654E616D653A537472696E672861292E7265706C616365282F5C2E7A6970242F692C2222297D2C7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C69297D72657475726E7B6B696E643A692C646174';
wwv_flow_imp.g_varchar2_table(1048) := '613A742C6E616D653A6E2C636F756E743A6C2E6C656E6774687D7D297D76617220732C753D6E65772077696E646F772E4A535A69702C633D302C663D302C643D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C703D7B7D3B66';
wwv_flow_imp.g_varchar2_table(1049) := '6F72287320696E20652E706172616D737C7C7B7D29705B735D3D652E706172616D735B735D3B702E464F524D41544F3D6E2E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F72';
wwv_flow_imp.g_varchar2_table(1050) := '64222C22646F63782D74656D706C617465223A22776F7264227D5B6E5B305D5D3B76617220673D7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A707D2C6D3D7B7D3B66756E6374696F6E207628652C74297B666F722876617220723D';
wwv_flow_imp.g_varchar2_table(1051) := '652C6E3D323B6D5B722E746F4C6F7765724361736528295D3B29723D652E7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B6E2B22243122292C6E2B2B3B6D5B722E746F4C6F7765724361736528295D3D21302C752E66696C6528722C7429';
wwv_flow_imp.g_varchar2_table(1052) := '2C632B2B7D76617220623D50726F6D6973652E7265736F6C766528292C773D722E62617463682626722E62617463682E73756D6D6172793B772626227A6970223D3D3D61262628623D6E2E66696C7465722866756E6374696F6E2865297B72657475726E';
wwv_flow_imp.g_varchar2_table(1053) := '22646F63782D74656D706C61746522213D3D657D292E7265647563652866756E6374696F6E28742C6E297B72657475726E20742E7468656E2866756E6374696F6E28297B76617220743D772E6C61796F75747C7C7B706167653A722E706167652C666F6F';
wwv_flow_imp.g_varchar2_table(1054) := '7465723A772E666F6F7465727C7C722E666F6F7465722C73656374696F6E733A772E73656374696F6E732C786C73783A772E786C73782C66696C654E616D653A772E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E6669';
wwv_flow_imp.g_varchar2_table(1055) := '6C654E616D653D772E66696C654E616D657C7C2230305F726573756D656E22292C4A74286E2C742C5B675D2C65292E7468656E2866756E6374696F6E2865297B7628587428742C672C6E292C65297D297D297D2C6229293B72657475726E20622E746865';
wwv_flow_imp.g_varchar2_table(1056) := '6E2866756E6374696F6E28297B72657475726E206E65772050726F6D6973652866756E6374696F6E28742C6F297B66756E6374696F6E206128297B666F722876617220693D4D6174682E6D696E28662B642C6C2E6C656E677468292C733D50726F6D6973';
wwv_flow_imp.g_varchar2_table(1057) := '652E7265736F6C766528293B663C693B662B2B292866756E6374696F6E2874297B6E2E666F72456163682866756E6374696F6E286E297B733D732E7468656E2866756E6374696F6E28297B72657475726E204A74286E2C722C5B745D2C65292E7468656E';
wwv_flow_imp.g_varchar2_table(1058) := '2866756E6374696F6E2865297B7628587428722C742C6E292C65297D297D297D297D29286C5B665D293B732E7468656E2866756E6374696F6E28297B652E6F6E50726F67726573732626652E6F6E50726F677265737328662C6C2E6C656E677468292C66';
wwv_flow_imp.g_varchar2_table(1059) := '3C6C2E6C656E6774683F73657454696D656F757428612C30293A28652E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C63292C752E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C';
wwv_flow_imp.g_varchar2_table(1060) := '636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374696F6E2865297B766172206E3D4D28722E62617463682626722E62617463682E7A69704E61';
wwv_flow_imp.g_varchar2_table(1061) := '6D657C7C227265706F727465732E7A6970222C67293B74287B6B696E643A227A6970222C646174613A652C6E616D653A68282F5C2E7A6970242F692E74657374286E293F6E3A6E2B222E7A697022292C636F756E743A6C2E6C656E6774682C66696C6573';
wwv_flow_imp.g_varchar2_table(1062) := '3A637D297D2C6F29297D2C6F297D73657454696D656F757428612C30297D297D297D286F2C74297D297D66756E6374696F6E2051742865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(1063) := '74696F6E2865297B6526262822636F6469676F223D3D3D652E747970652626227172223D3D3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292626742E696E6465784F6628227172636F646522293C302626742E70';
wwv_flow_imp.g_varchar2_table(1064) := '75736828227172636F646522292C226772616669636F223D3D3D652E747970652626742E696E6465784F66282263686172746A7322293C302626742E70757368282263686172746A7322292C22666F726D756C6172696F223D3D3D652E74797065262674';
wwv_flow_imp.g_varchar2_table(1065) := '2E696E6465784F6628226A737A697022293C302626742E7075736828226A737A697022292C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F72456163682872292C585B652E747970655D2626722828652E6669';
wwv_flow_imp.g_varchar2_table(1066) := '656C64737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E626C6F636B7D29292C22677275706F223D3D3D652E7479706526267228652E73656374696F6E73292C227461626C61223D3D3D652E747970652626722828';
wwv_flow_imp.g_varchar2_table(1067) := '652E636F6C756D6E737C7C5B5D292E6D61702866756E6374696F6E2865297B72657475726E20652626652E63656C6C7D2929297D297D7228652E73656374696F6E73293B766172206E3D652E62617463682626652E62617463682E73756D6D6172793B72';
wwv_flow_imp.g_varchar2_table(1068) := '657475726E206E26262872286E2E73656374696F6E73292C6E2E6C61796F7574262672286E2E6C61796F75742E73656374696F6E7329292C747D66756E6374696F6E20657228652C74297B69662822737472696E67223D3D747970656F66206526262240';
wwv_flow_imp.g_varchar2_table(1069) := '223D3D3D652E6368617241742830292626742626766F69642030213D3D745B652E7375627374722831295D2972657475726E20657228745B652E7375627374722831295D2C74293B69662841727261792E697341727261792865292972657475726E2065';
wwv_flow_imp.g_varchar2_table(1070) := '2E7265647563652866756E6374696F6E28652C72297B766172206E3D22737472696E67223D3D747970656F66207226262240223D3D3D722E636861724174283029262674262641727261792E6973417272617928745B722E7375627374722831295D292C';
wwv_flow_imp.g_varchar2_table(1071) := '6F3D657228722C74293B72657475726E206E3F652E636F6E636174286F293A652E636F6E636174285B6F5D297D2C5B5D293B696628652626226F626A656374223D3D747970656F662065297B76617220723D7B7D3B72657475726E204F626A6563742E6B';
wwv_flow_imp.g_varchar2_table(1072) := '6579732865292E666F72456163682866756E6374696F6E286E297B725B6E5D3D2264656673223D3D3D6E3F655B6E5D3A657228655B6E5D2C74297D292C727D72657475726E20657D66756E6374696F6E2074722865297B76617220743B69662865262622';
wwv_flow_imp.g_varchar2_table(1073) := '6F626A656374223D3D747970656F66206529743D653B656C73657B76617220723D537472696E6728657C7C2222292E7472696D28293B696628227B223D3D3D722E63686172417428302929743D4A534F4E2E70617273652872293B656C73652069662821';
wwv_flow_imp.g_varchar2_table(1074) := '28743D722E73706C697428222E22292E7265647563652866756E6374696F6E28652C74297B72657475726E20653F655B745D3A766F696420307D2C77696E646F772929297468726F77206E6577204572726F7228224E6F20736520656E636F6E7472C3B3';
wwv_flow_imp.g_varchar2_table(1075) := '20656C2064697365C3B16F3A20222B72297D72657475726E20657228742C742E64656673297D66756E6374696F6E2072722865297B69662865297B69662841727261792E697341727261792865297C7C22737472696E6722213D747970656F6620657C7C';
wwv_flow_imp.g_varchar2_table(1076) := '2F5B232E5C5B5D2F2E746573742865292972657475726E20653B76617220743D652E73706C697428222C22292E6D61702866756E6374696F6E2865297B72657475726E20652E7472696D28297D292E66696C74657228426F6F6C65616E293B7265747572';
wwv_flow_imp.g_varchar2_table(1077) := '6E20742E6C656E6774683F743A766F696420307D7D66756E6374696F6E206E722865297B766172206E2C6F3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D';
wwv_flow_imp.g_varchar2_table(1078) := '2C6C3D313D3D3D6F2E6C656E677468262622706466223D3D3D6F5B305D2626227A697022213D3D652E6F7574707574262622646F776E6C6F616422213D3D652E706466416374696F6E2C613D6C26262131213D3D652E6C6F616465723F66756E6374696F';
wwv_flow_imp.g_varchar2_table(1079) := '6E2865297B76617220743D77696E646F772E6F70656E2822222C225F626C616E6B22293B69662821742972657475726E206E756C6C3B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F61646572297472797B77696E';
wwv_flow_imp.g_varchar2_table(1080) := '646F772E636F744C6F616465722874293B76617220723D742E646F63756D656E742E676574456C656D656E747342795461674E616D652822683122295B305D3B72262628722E74657874436F6E74656E743D2247656E6572616E646F207265706F727465';
wwv_flow_imp.g_varchar2_table(1081) := '22297D63617463682865297B7D656C736520742E646F63756D656E742E777269746528273C21646F63747970652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C7469746C653E47656E6572616E64';
wwv_flow_imp.g_varchar2_table(1082) := '6F207265706F727465E280A63C2F7469746C653E3C7374796C653E626F64797B6D617267696E3A303B6865696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E';
wwv_flow_imp.g_varchar2_table(1083) := '743A63656E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D73657269663B6261636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B77';
wwv_flow_imp.g_varchar2_table(1084) := '696474683A353670783B6865696768743A353670783B626F726465723A35707820736F6C696420236436653065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A';
wwv_flow_imp.g_varchar2_table(1085) := '72203173206C696E65617220696E66696E6974653B6D617267696E3A30206175746F20313870787D406B65796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B';
wwv_flow_imp.g_varchar2_table(1086) := '6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A233562366237627D3C2F7374796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C6831';
wwv_flow_imp.g_varchar2_table(1087) := '3E47656E6572616E646F207265706F7274653C2F68313E3C702069643D226D7367223E3C2F703E3C2F6469763E3C2F626F64793E3C2F68746D6C3E27292C742E646F63756D656E742E636C6F736528293B72657475726E20487428742C65292C747D2865';
wwv_flow_imp.g_varchar2_table(1088) := '2E6D6573736167657C7C22436F6E73756C74616E646F206461746F73E280A622293A6E756C6C2C693D77696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E73686F775370696E6E657228293A6E756C6C2C733D227265736F';
wwv_flow_imp.g_varchar2_table(1089) := '6C766572223D3D3D652E6F726967696E262621652E646174612C753D227175657279223D3D3D652E6F726967696E262621652E646174613B696628217326262175297472797B6E3D747228652E6C61796F7574297D63617463682865297B72657475726E';
wwv_flow_imp.g_varchar2_table(1090) := '20692626692E72656D6F766528292C612626612E636C6F736528292C5674282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765292C50726F6D6973652E72656A6563742865297D76617220633D7B6C61796F75743A6E2C666F';
wwv_flow_imp.g_varchar2_table(1091) := '726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D706C61746555726C2C686F6F6B733A652E686F6F6B737C7C7B7D2C666F726D5061';
wwv_flow_imp.g_varchar2_table(1092) := '7373776F72643A652E666F726D50617373776F72647D3B247428227374617274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C7265706F72743A733F652E7265706F72743A766F696420307D293B76617220663D';
wwv_flow_imp.g_varchar2_table(1093) := '722866756E6374696F6E28652C72297B766172206E3D5B5D3B72657475726E20652E666F72456163682866756E6374696F6E2865297B28745B655D7C7C5B5D292E666F72456163682866756E6374696F6E2865297B6E2E696E6465784F662865293C3026';
wwv_flow_imp.g_varchar2_table(1094) := '266E2E707573682865297D297D292C7226266E2E7075736828226A737A697022292C6E7D286F2C226D6572676522213D3D652E6F7574707574292E636F6E63617428737C7C753F5B5D3A5174286E2929292C643D652E646174613F50726F6D6973652E72';
wwv_flow_imp.g_varchar2_table(1095) := '65736F6C7665287B646174613A652E646174617D293A6E65772050726F6D6973652866756E6374696F6E28742C72297B766172206E3D7B7830313A4A534F4E2E737472696E6769667928632E706172616D73292C7830323A227A6970223D3D3D652E6F75';
wwv_flow_imp.g_varchar2_table(1096) := '747075743F2259223A224E222C706167654974656D733A727228652E6974656D73297D3B69662873297B696628766F696420303D3D3D652E7265706F72747C7C6E756C6C3D3D3D652E7265706F72747C7C22223D3D3D652E7265706F7274297265747572';
wwv_flow_imp.g_varchar2_table(1097) := '6E20766F69642072286E6577204572726F722822496E646971756520656C207265706F72746520612067656E657261722028646174612D7265706F7274292E2229293B6E2E7830333D537472696E6728652E7265706F7274297D617065782E7365727665';
wwv_flow_imp.g_varchar2_table(1098) := '722E706C7567696E28652E616A61784964656E7469666965722C6E2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B652626652E6F6B3F742865293A72286E6577204572726F7228652626652E6D73677C7C22';
wwv_flow_imp.g_varchar2_table(1099) := '4572726F7220616C206F6274656E6572206C6F73206461746F732E2229297D2C66756E6374696F6E28652C742C6E297B72286E6577204572726F7228224572726F7220646520636F6D756E6963616369C3B36E3A20222B286E7C7C742929297D297D293B';
wwv_flow_imp.g_varchar2_table(1100) := '72657475726E2050726F6D6973652E616C6C285B642C665D292E7468656E2866756E6374696F6E2874297B766172206F3D745B305D2C6C3D50726F6D6973652E7265736F6C766528293B69662873297B7472797B6E3D7472286F2E6C61796F7574297D63';
wwv_flow_imp.g_varchar2_table(1101) := '617463682865297B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D632E6C61796F75743D6E2C6F2E706172616D73262628632E706172616D733D6F2E706172616D73292C6F2E';
wwv_flow_imp.g_varchar2_table(1102) := '74656D706C61746555726C262628632E74656D706C61746555726C3D6F2E74656D706C61746555726C292C6C3D72285174286E29297D656C73652069662875297B76617220613D6F2E6C61796F75747C7C652E6C61796F75743B6966282161297468726F';
wwv_flow_imp.g_varchar2_table(1103) := '77206E6577204572726F72282246616C746120656C2064697365C3B16F3A206C6120636F6E73756C74612064656C207265706F727465206E6F206465766F6C7669C3B3204C41594F5554207920656C20617472696275746F2044697365C3B16F20657374';
wwv_flow_imp.g_varchar2_table(1104) := 'C3A120766163C3AD6F2E22293B7472797B6E3D74722861297D63617463682865297B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D632E6C61796F75743D6E2C6F2E74656D70';
wwv_flow_imp.g_varchar2_table(1105) := '6C61746555726C262628632E74656D706C61746555726C3D6F2E74656D706C61746555726C292C6C3D72285174286E29297D72657475726E206C2E7468656E2866756E6374696F6E28297B72657475726E206F2E646174617D297D292E7468656E286675';
wwv_flow_imp.g_varchar2_table(1106) := '6E6374696F6E2874297B69262628692E72656D6F766528292C693D6E756C6C293B76617220723D652E7472616E73666F726D2626652E7472616E73666F726D2874297C7C743B72657475726E20487428612C2241726D616E646F20656C20646F63756D65';
wwv_flow_imp.g_varchar2_table(1107) := '6E746FE280A622292C632E6F6E50726F67726573733D66756E6374696F6E28652C74297B2D313D3D3D653F57742822436F6D7072696D69656E646F20222B742B22206172636869766F73E280A622293A285774282247656E6572616E646F20222B652B22';
wwv_flow_imp.g_varchar2_table(1108) := '20646520222B742B22E280A622292C2474282270726F6772657373222C7B646F6E653A652C746F74616C3A747D29297D2C4B7428632C72297D292E7468656E2866756E6374696F6E2874297B76617220723D652E736176657C7C632E6C61796F75742626';
wwv_flow_imp.g_varchar2_table(1109) := '632E6C61796F75742E736176653B69662821727C7C21722E70726F636573732972657475726E20743B6966282177696E646F772E617065787C7C21617065782E736572766572297468726F77206E6577204572726F7228224775617264617220656E2065';
wwv_flow_imp.g_varchar2_table(1110) := '6C207365727669646F7220726571756965726520415045582E22293B72657475726E20577428224775617264616E646F20656E20656C207365727669646F72E280A622292C66756E6374696F6E28652C742C72297B766172206E3D227A6970223D3D3D65';
wwv_flow_imp.g_varchar2_table(1111) := '2E6B696E643F226170706C69636174696F6E2F7A6970223A71745B652E6B696E645D7C7C71742E646F63782C6F3D652E6461746120696E7374616E63656F6620426C6F623F652E646174613A6E657720426C6F62285B652E646174615D2C7B747970653A';
wwv_flow_imp.g_varchar2_table(1112) := '6E7D293B72657475726E206E65772050726F6D6973652866756E6374696F6E286C2C61297B76617220693D6E65772046696C655265616465723B692E6F6E6572726F723D66756E6374696F6E28297B61286E6577204572726F7228224E6F207365207075';
wwv_flow_imp.g_varchar2_table(1113) := '646F206C65657220656C206172636869766F2067656E657261646F2E2229297D2C692E6F6E6C6F61643D66756E6374696F6E28297B766172206F2C733D537472696E6728692E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F';
wwv_flow_imp.g_varchar2_table(1114) := '2C2222292C753D5B5D3B666F72286F3D303B6F3C732E6C656E6774683B6F2B3D33653429752E7075736828732E737562737472286F2C33653429293B617065782E7365727665722E70726F6365737328742E70726F636573732C7B7830313A652E6E616D';
wwv_flow_imp.g_varchar2_table(1115) := '652C7830323A6E2C7830333A766F696420303D3D3D722E7265706F72743F22223A537472696E6728722E7265706F7274292C7830343A4A534F4E2E737472696E6769667928722E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A757D';
wwv_flow_imp.g_varchar2_table(1116) := '2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B65262621313D3D3D652E6F6B3F61286E6577204572726F7228652E6D73677C7C22456C207365727669646F72206E6F206775617264C3B320656C20646F6375';
wwv_flow_imp.g_varchar2_table(1117) := '6D656E746F2E2229293A6C28657C7C7B7D297D2C66756E6374696F6E28652C742C72297B61286E6577204572726F7228224E6F207365207075646F206775617264617220656E20656C207365727669646F723A20222B28727C7C742929297D297D2C692E';
wwv_flow_imp.g_varchar2_table(1118) := '7265616441734461746155524C286F297D297D28742C722C7B7265706F72743A652E7265706F72742C706172616D733A632E706172616D737D292E7468656E2866756E6374696F6E2865297B72657475726E20742E73617665643D652C742E6F6E6C793D';
wwv_flow_imp.g_varchar2_table(1119) := '226F6E6C79223D3D3D722E6D6F64652C247428227361766564222C7B6E616D653A742E6E616D652C6B696E643A742E6B696E642C726573706F6E73653A657D292C747D297D292E7468656E2866756E6374696F6E2865297B696628577428292C652E6F6E';
wwv_flow_imp.g_varchar2_table(1120) := '6C7929612626612E636C6F736528292C597428652E73617665642626652E73617665642E6D73677C7C22446F63756D656E746F20677561726461646F3A20222B652E6E616D65293B656C73652069662822706466223D3D3D652E6B696E6426266C297B76';
wwv_flow_imp.g_varchar2_table(1121) := '617220743D55524C2E6372656174654F626A65637455524C286E657720426C6F62285B652E646174615D2C7B747970653A71742E7064667D29293B61262621612E636C6F7365643F612E6C6F636174696F6E2E687265663D743A77696E646F772E6F7065';
wwv_flow_imp.g_varchar2_table(1122) := '6E28742C225F626C616E6B22297D656C736520612626612E636C6F736528292C723D652E646174612C6E3D652E6E616D652C6F3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A71745B652E6B696E645D7C7C71742E';
wwv_flow_imp.g_varchar2_table(1123) := '646F63782C693D7220696E7374616E63656F6620426C6F623F723A6E657720426C6F62285B725D2C7B747970653A6F7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D292C28733D646F63756D656E742E637265617465456C656D';
wwv_flow_imp.g_varchar2_table(1124) := '656E742822612229292E687265663D55524C2E6372656174654F626A65637455524C2869292C732E646F776E6C6F61643D6E2C646F63756D656E742E626F64792E617070656E644368696C642873292C732E636C69636B28292C73657454696D656F7574';
wwv_flow_imp.g_varchar2_table(1125) := '2866756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C28732E68726566292C732E72656D6F766528297D2C346533292C227A6970223D3D3D652E6B696E642626597428225A49502067656E657261646F3A20222B652E66696C6573';
wwv_flow_imp.g_varchar2_table(1126) := '2B22206172636869766F7320646520222B652E636F756E742B2220646F63756D656E746F732E22293B76617220722C6E2C6F2C692C733B72657475726E2024742822656E64222C7B6E616D653A652E6E616D652C636F756E743A652E636F756E742C6669';
wwv_flow_imp.g_varchar2_table(1127) := '6C65733A652E66696C65737D292C657D292E63617463682866756E6374696F6E2865297B7468726F7720692626692E72656D6F766528292C577428292C61262621612E636C6F7365642626612E636C6F736528292C77696E646F772E636F6E736F6C6526';
wwv_flow_imp.g_varchar2_table(1128) := '26636F6E736F6C652E6572726F722865292C247428226572726F72222C7B6D6573736167653A652E6D6573736167657D292C567428652E6D6573736167657C7C224E6F207365207075646F2067656E6572617220656C207265706F7274652E22292C657D';
wwv_flow_imp.g_varchar2_table(1129) := '297D766172206F723D21312C6C723D6E756C6C3B72657475726E22756E646566696E656422213D747970656F6620646F63756D656E742626646F63756D656E742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E74';
wwv_flow_imp.g_varchar2_table(1130) := '4C697374656E65722822636C69636B222C66756E6374696F6E2865297B6C723D652E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D';
wwv_flow_imp.g_varchar2_table(1131) := '2C5B646174612D666F726D61745D22297C7C652E7461726765747D2C2130292C7B76657273696F6E3A22312E32322E30222C6C6962733A652C72756E3A6E722C64613A66756E6374696F6E2865297B76617220743D746869732626746869732E61637469';
wwv_flow_imp.g_varchar2_table(1132) := '6F6E3F746869733A7B7D2C723D742E616374696F6E7C7C7B7D2C6E3D742E74726967676572696E67456C656D656E747C7C6C722C6F3D742E62726F777365724576656E743B6966286F26266F2E70726576656E7444656661756C7426266F2E7072657665';
wwv_flow_imp.g_varchar2_table(1133) := '6E7444656661756C7428292C216F72297B766172206C3D652626226F626A656374223D3D747970656F6620653F653A7B7D2C613D2266756E6374696F6E223D3D747970656F6620653F653A6C2E696E69742C693D7B7D2C733D6E26266E2E646174617365';
wwv_flow_imp.g_varchar2_table(1134) := '747C7C7B7D2C753D6C2E7265706F72742C633D6C2E6F75747075747C7C722E61747472696275746530337C7C2266696C65222C663D6C2E666F726D61747C7C722E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732873292E66';
wwv_flow_imp.g_varchar2_table(1135) := '6F72456163682866756E6374696F6E2865297B226F757470757422213D3D653F22666F726D617422213D3D653F227265706F727422213D3D653F695B652E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528';
wwv_flow_imp.g_varchar2_table(1136) := '295D3D735B655D3A753D735B655D3A663D735B655D3A633D735B655D7D293B76617220643D7B6C61796F75743A6C2E6C61796F75747C7C722E61747472696275746530312C666F726D61743A662C6F75747075743A632C6974656D733A6C2E6974656D73';
wwv_flow_imp.g_varchar2_table(1137) := '7C7C722E61747472696275746530347C7C22222C706466416374696F6E3A6C2E706466416374696F6E7C7C722E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A6C2E74656D706C61746555726C7C7C722E617474726962';
wwv_flow_imp.g_varchar2_table(1138) := '75746530362C6D6573736167653A6C2E6D6573736167657C7C722E61747472696275746530372C706172616D733A692C616A61784964656E7469666965723A6C2E616A61784964656E7469666965727C7C722E616A61784964656E7469666965722C6F72';
wwv_flow_imp.g_varchar2_table(1139) := '6967696E3A6C2E6F726967696E7C7C2261747472696275746573222C7265706F72743A752C736176653A6C2E736176657D3B6966282266756E6374696F6E223D3D747970656F662061297B76617220683D612864293B69662821313D3D3D682972657475';
wwv_flow_imp.g_varchar2_table(1140) := '726E3B643D687C7C647D6F723D21302C6E722864292E7468656E2866756E6374696F6E28297B6F723D21317D2C66756E6374696F6E28297B6F723D21317D297D7D2C6275696C643A4B742C656E737572653A722C6C61796F75744C6962733A51742C5F69';
wwv_flow_imp.g_varchar2_table(1141) := '6E7465726E616C733A7B494D473A72742C696D6744696D733A6C742C74706C3A4D2C636F6E643A462C666D743A702C6E6F726D616C697A653A5F742C636F6E74657874733A47742C636F64653132383A77742C706E67313A76742C6C61796F75744C6962';
wwv_flow_imp.g_varchar2_table(1142) := '733A51742C7368613531323A54652C776F72644C65676163794B65793A6B652C776F7264486173683A4D652C666F726D4E616D653A62657D7D7D28293B';
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
