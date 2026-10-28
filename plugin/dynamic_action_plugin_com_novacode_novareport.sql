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
'procedure nr_write_json(p_sources in clob, p_params in varchar2, p_summary in boolean,',
'                        p_res in json_object_t default null) is',
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
'begin',
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
,p_help_text=>unistr('<p>Genera reportes PDF, Excel con estilos y Word desde fuentes SQL y un dise\00F1o JSON. Modo lote: un archivo por documento dentro de un ZIP, con resumen opcional. Librer\00EDas (jsPDF, autotable, ExcelJS, docx, docxtemplater, JSZip) se cargan bajo demanda.')
||'</p>'
,p_version_identifier=>'1.12.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>20
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175479)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'format'
,p_prompt=>'Formato'
,p_apexlang_name=>'formato'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'pdf'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>unistr('Formato a generar. Puede sobrescribirse con <code>data-format</code> en el elemento que dispara la acci\00F3n.')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175498)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>20
,p_display_value=>'Excel (.xlsx con estilos)'
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
,p_display_value=>'Todos (PDF + Excel + Word)'
,p_return_value=>'all'
,p_apexlang_name=>'todosPdfExcelWord'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175500)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175479)
,p_display_sequence=>40
,p_display_value=>'Word desde plantilla'
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
,p_prompt=>unistr('\00CDtems a enviar')
,p_apexlang_name=>'temsAEnviar'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>unistr('\00CDtems cuyo valor actual de pantalla se env\00EDa antes de ejecutar las consultas.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175478)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'layout'
,p_prompt=>unistr('Dise\00F1o (JSON)')
,p_apexlang_name=>'diseoJson'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>true
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>unistr('Dise\00F1o en JSON (o el nombre de una variable JavaScript global con el dise\00F1o). Secciones: header, ficha, tabla, alerta, texto, salto. Plantillas {COL}, {FUENTE.COL}, {DOC.COL}, {ITEM.P1_X}, {NOW}, {PAGE}/{PAGES}; formatos {COL|money}, |int, |num:3, |p')
||'ct, |date, |upper. Reutilice bloques con "defs" y "@NOMBRE". Para Excel use "xlsx.sheets"; para lotes "batch" (zipName, summary, chunkSize, maxDocs).'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175484)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'message'
,p_prompt=>'Mensaje de espera'
,p_apexlang_name=>'mensajeDeEspera'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Consultando datos...'
,p_max_length=>200
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175485)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>5
,p_static_id=>'origin'
,p_prompt=>'Origen'
,p_apexlang_name=>'origen'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'attributes'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>unistr('<p><b>Atributos</b>: las fuentes SQL y el dise\00F1o se configuran en esta acci\00F3n.</p><p><b>Resolver</b>: el navegador solo env\00EDa el ID del reporte (<code>data-report</code> u <code>o.report</code> en Initialization Code) y los par\00E1metros; una funci\00F3n PL')
||unistr('/SQL valida el acceso y devuelve fuentes y dise\00F1o. Nunca se acepta SQL desde el navegador.</p>')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175527)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_display_sequence=>10
,p_display_value=>unistr('Atributos (fuentes y dise\00F1o aqu\00ED)')
,p_return_value=>'attributes'
,p_apexlang_name=>'atributos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175528)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_display_sequence=>20
,p_display_value=>unistr('Resolver (funci\00F3n PL/SQL por ID de reporte)')
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
,p_prompt=>'Salida'
,p_apexlang_name=>'salida'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'file'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>unistr('Puede sobrescribirse con <code>data-output</code> en el elemento (p. ej. un bot\00F3n con data-output="zip").')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175507)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175480)
,p_display_sequence=>10
,p_display_value=>'Archivo (ZIP si hay varios documentos)'
,p_return_value=>'file'
,p_apexlang_name=>'archivoZipSiHayVariosDocumentos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175509)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175480)
,p_display_sequence=>30
,p_display_value=>'Un solo archivo con todos los documentos'
,p_return_value=>'merge'
,p_apexlang_name=>'unSoloArchivoConTodosLosDocumentos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175508)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175480)
,p_display_sequence=>20
,p_display_value=>'ZIP: un archivo por documento + resumen'
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
,p_prompt=>'PDF de un documento'
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
,p_display_value=>unistr('Abrir en una pesta\00F1a nueva (con pantalla de espera)')
,p_return_value=>'open'
,p_apexlang_name=>'abrirEnUnaPestaaNuevaConPantallaDeEspera'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(71250679706175518)
,p_plugin_attribute_id=>wwv_flow_imp.id(71250679706175482)
,p_display_sequence=>20
,p_display_value=>'Descargar'
,p_return_value=>'download'
,p_apexlang_name=>'descargar'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175486)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>6
,p_static_id=>'resolver'
,p_prompt=>unistr('Funci\00F3n resolver')
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
,p_help_text=>unistr('Funci\00F3n <code>f(p_id in varchar2, p_params in clob) return clob</code> que devuelve <code>{ "sources": "--@X ...", "layout": {...}, "params": {...}, "types": {"P": "text|number|date"} }</code>. Debe validar rol y par\00E1metros. Ver docs/API.md.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175477)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'sources'
,p_prompt=>'Fuentes SQL'
,p_apexlang_name=>'fuentesSql'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>true
,p_display_length=>80
,p_max_length=>4000
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(71250679706175485)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('Una o varias consultas. Cada una inicia con una l\00EDnea <code>--@NOMBRE</code> (agregue <code>summary</code> para que solo se ejecute en descargas ZIP con resumen).'),
'<ul><li><b>DOCS</b> (opcional): una fila por documento; columna <code>DOC_KEY</code> obligatoria.</li>',
unistr('<li>Las dem\00E1s fuentes con columna <code>DOC_KEY</code> se reparten por documento; sin ella, se comparten.</li>'),
unistr('<li>Los \00EDtems de APEX se enlazan solos (:P1_X). Otros binds (:DET) toman su valor de los atributos <code>data-*</code> del elemento que dispara la acci\00F3n (data-det) o quedan en NULL.</li></ul>')))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(71250679706175483)
,p_plugin_id=>wwv_flow_imp.id(71250679706175467)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'template_url'
,p_prompt=>'Plantilla Word (URL)'
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
,p_help_text=>'URL del .docx con marcadores {CAMPO}, {FUENTE.CAMPO}, bucles {#FUENTE}...{/FUENTE} y formatos {CAMPO|money}. Ej.: #APP_FILES#plantillas/carta.docx'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E31322E30202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C';
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
wwv_flow_imp.g_varchar2_table(20) := '28742C72297B72657475726E20742E7468656E2866756E6374696F6E28297B72657475726E20655B725D2E6F6B28293F6E756C6C3A28743D786528655B725D2E75726C292C6E65772050726F6D6973652866756E6374696F6E28652C72297B766172206E';
wwv_flow_imp.g_varchar2_table(21) := '3D77696E646F772E646566696E653B77696E646F772E646566696E653D766F696420303B766172206F3D646F63756D656E742E637265617465456C656D656E74282273637269707422293B6F2E7372633D742C6F2E6F6E6C6F61643D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(22) := '28297B77696E646F772E646566696E653D6E2C6528297D2C6F2E6F6E6572726F723D66756E6374696F6E28297B77696E646F772E646566696E653D6E2C72286E6577204572726F7228224E6F207365207075646F20636172676172206C61206C69627265';
wwv_flow_imp.g_varchar2_table(23) := '72C3AD613A20222B7429297D2C646F63756D656E742E686561642E617070656E644368696C64286F297D29293B76617220747D297D2C50726F6D6973652E7265736F6C76652829297D766172206E3D7B7072696D6172793A2223314634453739222C6865';
wwv_flow_imp.g_varchar2_table(24) := '6164546578743A2223464646464646222C7A656272613A2223463546374641222C746F74616C733A2223453645434632222C746578743A2223303030303030222C6D757465643A2223373837383738222C666F6E7453697A653A372C67726F75703A2223';
wwv_flow_imp.g_varchar2_table(25) := '444345364630227D3B66756E6374696F6E206F2865297B72657475726E226E756D626572223D3D747970656F66206526262169734E614E2865297D66756E6374696F6E20612865297B72657475726E20333D3D3D28653D537472696E6728657C7C222330';
wwv_flow_imp.g_varchar2_table(26) := '303030303022292E7265706C616365282223222C222229292E6C656E677468262628653D652E7265706C616365282F282E292F672C22243124312229292C5B7061727365496E7428652E73756273747228302C32292C3136292C7061727365496E742865';
wwv_flow_imp.g_varchar2_table(27) := '2E73756273747228322C32292C3136292C7061727365496E7428652E73756273747228342C32292C3136295D7D66756E6374696F6E20692865297B72657475726E224646222B537472696E6728657C7C222330303030303022292E7265706C6163652822';
wwv_flow_imp.g_varchar2_table(28) := '23222C2222292E746F55707065724361736528297D66756E6374696F6E206C2865297B72657475726E20537472696E6728657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E6374696F';
wwv_flow_imp.g_varchar2_table(29) := '6E20752865297B72657475726E28653C31303F2230223A2222292B657D66756E6374696F6E207328297B76617220653D6E657720446174653B72657475726E207528652E676574446174652829292B222F222B7528652E6765744D6F6E746828292B3129';
wwv_flow_imp.g_varchar2_table(30) := '2B222F222B652E67657446756C6C5965617228292B2220222B7528652E676574486F7572732829292B223A222B7528652E6765744D696E757465732829297D66756E6374696F6E206328297B72657475726E207328292E73756273747228302C3130297D';
wwv_flow_imp.g_varchar2_table(31) := '66756E6374696F6E20662865297B76617220743D537472696E672865292E746F4C6F7765724361736528292E7265706C616365282F5F2F672C222022293B72657475726E20742E6368617241742830292E746F55707065724361736528292B742E736C69';
wwv_flow_imp.g_varchar2_table(32) := '63652831297D66756E6374696F6E20642865297B76617220743D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D29242F2E6578656328537472696E6728657C7C222229293B72657475726E20743F6E6577204461746528446174652E55';
wwv_flow_imp.g_varchar2_table(33) := '5443282B745B335D2C2B745B325D2D312C2B745B315D29293A6E756C6C7D66756E6374696F6E20682865297B72657475726E20537472696E6728657C7C226172636869766F22292E7265706C616365282F5B5C5C5C2F3A2A3F223C3E7C5D2B2F672C225F';
wwv_flow_imp.g_varchar2_table(34) := '22292E7472696D28297D66756E6374696F6E207028652C74297B6966286E756C6C3D3D657C7C22223D3D3D652972657475726E22223B69662821742972657475726E20537472696E672865293B76617220723D742E73706C697428223A22292C6E3D725B';
wwv_flow_imp.g_varchar2_table(35) := '305D3B696628226D6F6E6579223D3D3D6E7C7C226E756D223D3D3D6E297B766172206F3D766F69642030213D3D725B315D3F2B725B315D3A322C613D4E756D6265722865293B72657475726E2069734E614E2861293F537472696E672865293A612E746F';
wwv_flow_imp.g_varchar2_table(36) := '4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A6F2C6D6178696D756D4672616374696F6E4469676974733A6F7D297D72657475726E22696E74223D3D3D6E3F69734E614E284E756D626572';
wwv_flow_imp.g_varchar2_table(37) := '286529293F537472696E672865293A4D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D555322293A22706374223D3D3D6E3F7028652C226E756D3A222B28725B315D7C7C3229292B2225223A227570';
wwv_flow_imp.g_varchar2_table(38) := '706572223D3D3D6E3F537472696E672865292E746F55707065724361736528293A226C6F776572223D3D3D6E3F537472696E672865292E746F4C6F7765724361736528293A22796E223D3D3D6E3F2259223D3D3D657C7C2253223D3D3D653F2253C3AD22';
wwv_flow_imp.g_varchar2_table(39) := '3A224E223D3D3D653F224E6F223A537472696E672865293A226C6574726173223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A66756E6374696F6E28652C74297B76617220723D653C302C6E3D4D6174682E726F756E64';
wwv_flow_imp.g_varchar2_table(40) := '283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C613D6E253130302C693D79286F293B69662874297B2F284D494C4CC3934E7C4D494C4C4F4E45537C42494C4CC3934E7C42494C4C4F4E455329242F2E7465';
wwv_flow_imp.g_varchar2_table(41) := '7374286929262628692B3D2220444522293B766172206C3D537472696E672874292E746F55707065724361736528292E73706C697428222F22293B692B3D2220222B28313D3D3D6F26266C2E6C656E6774683E313F6C5B305D3A6C5B6C2E6C656E677468';
wwv_flow_imp.g_varchar2_table(42) := '2D315D297D656C736520693D692E7265706C616365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E2865297B72657475726E20652B224F227D293B72657475726E28723F224D454E4F532022';
wwv_flow_imp.g_varchar2_table(43) := '3A2222292B692B2220434F4E20222B28613C31303F2230223A2222292B612B222F313030227D284E756D6265722865292C722E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E6374696F6E206D2865297B7265747572';
wwv_flow_imp.g_varchar2_table(44) := '6E2F5E2875707065727C6C6F7765727C796E7C6C657472617329283A7C24292F2E7465737428657C7C2222297D76617220673D5B22222C22554E222C22444F53222C2254524553222C2243554154524F222C2243494E434F222C2253454953222C225349';
wwv_flow_imp.g_varchar2_table(45) := '455445222C224F43484F222C224E55455645222C224449455A222C224F4E4345222C22444F4345222C225452454345222C224341544F524345222C225155494E4345222C22444945434953C3894953222C2244494543495349455445222C224449454349';
wwv_flow_imp.g_varchar2_table(46) := '4F43484F222C2244494543494E55455645222C225645494E5445222C225645494E5449C39A4E222C225645494E544944C39353222C225645494E54495452C38953222C225645494E544943554154524F222C225645494E544943494E434F222C22564549';
wwv_flow_imp.g_varchar2_table(47) := '4E544953C3894953222C225645494E54495349455445222C225645494E54494F43484F222C225645494E54494E55455645225D2C763D5B22222C22222C22222C22545245494E5441222C2243554152454E5441222C2243494E4355454E5441222C225345';
wwv_flow_imp.g_varchar2_table(48) := '53454E5441222C22534554454E5441222C224F4348454E5441222C224E4F56454E5441225D2C773D5B22222C224349454E544F222C22444F534349454E544F53222C22545245534349454E544F53222C2243554154524F4349454E544F53222C22515549';
wwv_flow_imp.g_varchar2_table(49) := '4E49454E544F53222C22534549534349454E544F53222C22534554454349454E544F53222C224F43484F4349454E544F53222C224E4F56454349454E544F53225D3B66756E6374696F6E20622865297B6966283130303D3D3D652972657475726E224349';
wwv_flow_imp.g_varchar2_table(50) := '454E223B76617220743D4D6174682E666C6F6F7228652F313030292C723D65253130302C6E3D5B5D3B72657475726E207426266E2E7075736828775B745D292C7226266E2E7075736828723C33303F675B725D3A765B4D6174682E666C6F6F7228722F31';
wwv_flow_imp.g_varchar2_table(51) := '30295D2B28722531303F22205920222B675B722531305D3A222229292C6E2E6A6F696E28222022297D66756E6374696F6E20792865297B696628303D3D3D652972657475726E224345524F223B76617220743D5B5D3B5B5B316531322C2242494C4CC393';
wwv_flow_imp.g_varchar2_table(52) := '4E222C2242494C4C4F4E4553225D2C5B3165362C224D494C4CC3934E222C224D494C4C4F4E4553225D5D2E666F72456163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E707573682831';
wwv_flow_imp.g_varchar2_table(53) := '3D3D3D6E3F22554E20222B725B315D3A79286E292B2220222B725B325D292C652D3D6E2A725B305D297D293B76617220723D4D6174682E666C6F6F7228652F316533292C6E3D65253165333B72657475726E20722626742E7075736828313D3D3D723F22';
wwv_flow_imp.g_varchar2_table(54) := '4D494C223A622872292B22204D494C22292C6E2626742E707573682862286E29292C742E6A6F696E28222022297D66756E6374696F6E207828652C742C72297B766172206E3D537472696E672874292E746F55707065724361736528292C6F3D6E2E696E';
wwv_flow_imp.g_varchar2_table(55) := '6465784F6628222E22293B6966286F3E30297B76617220613D6E2E73756273747228302C6F292C693D6E2E737562737472286F2B31293B69662822444F43223D3D3D612972657475726E20652E646F633F652E646F635B695D3A766F696420303B696628';
wwv_flow_imp.g_varchar2_table(56) := '22504152414D223D3D3D612972657475726E20652E706172616D733F652E706172616D735B695D3A766F696420303B696628224954454D223D3D3D612972657475726E2066756E6374696F6E2865297B7472797B72657475726E2077696E646F772E6170';
wwv_flow_imp.g_varchar2_table(57) := '65782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D63617463682865297B72657475726E22227D7D2869293B766172206C3D28652E535B615D7C7C5B5D295B305D3B72657475726E206C3F6C5B695D3A';
wwv_flow_imp.g_varchar2_table(58) := '766F696420307D72657475726E224E4F57223D3D3D6E3F7328293A22544F444159223D3D3D6E3F6328293A2250414745223D3D3D6E7C7C225041474553223D3D3D6E3F227B222B6E2B227D223A7226264F626A6563742E70726F746F747970652E686173';
wwv_flow_imp.g_varchar2_table(59) := '4F776E50726F70657274792E63616C6C28722C6E293F725B6E5D3A652E646F6326264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F652E646F635B6E5D3A652E706172616D733F652E';
wwv_flow_imp.g_varchar2_table(60) := '706172616D735B6E5D3A766F696420307D66756E6374696F6E204528652C742C72297B72657475726E206E756C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C285B41';
wwv_flow_imp.g_varchar2_table(61) := '2D5A612D7A302D393A2FC381C389C38DC393C39AC391C39CC3A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B29293F5C7D2F672C66756E6374696F6E28652C6E2C6F297B76617220613D7828742C6E2C72293B72657475726E206E756C6C3D3D613F22223A702861';
wwv_flow_imp.g_varchar2_table(62) := '2C6F297D297D66756E6374696F6E205428652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E657865632865293B69';
wwv_flow_imp.g_varchar2_table(63) := '6628216E2972657475726E21313B766172206F3D7828742C6E5B325D2C72293B696628216E5B335D297B76617220613D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E223D3D3D6F293B72657475726E206E5B315D3F21613A617D';
wwv_flow_imp.g_varchar2_table(64) := '76617220692C6C3D28693D28693D6E5B345D292E7472696D28292C2F5E272E2A27242F2E746573742869297C7C2F5E222E2A22242F2E746573742869293F692E736C69636528312C2D31293A226E756C6C223D3D3D693F6E756C6C3A22223D3D3D697C7C';
wwv_flow_imp.g_varchar2_table(65) := '69734E614E284E756D626572286929293F766F696420303A4E756D626572286929293B766F696420303D3D3D6C2626286C3D7828742C6E5B345D2E7472696D28292C7229293B76617220753D6E756C6C3D3D6F7C7C22223D3D3D6F3F6E756C6C3D3D3D6C';
wwv_flow_imp.g_varchar2_table(66) := '7C7C22223D3D3D6C3A537472696E67286F293D3D3D537472696E67286C293B737769746368286E5B335D297B63617365223D3D223A72657475726E20753B6361736522213D223A72657475726E21753B63617365223E223A72657475726E204E756D6265';
wwv_flow_imp.g_varchar2_table(67) := '72286F293E4E756D626572286C293B63617365223C223A72657475726E204E756D626572286F293C4E756D626572286C293B63617365223E3D223A72657475726E204E756D626572286F293E3D4E756D626572286C293B63617365223C3D223A72657475';
wwv_flow_imp.g_varchar2_table(68) := '726E204E756D626572286F293C3D4E756D626572286C297D72657475726E21317D66756E6374696F6E205328652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C282266756E6374696F6E223D3D747970656F6620653F212165';
wwv_flow_imp.g_varchar2_table(69) := '28722C74293A537472696E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E65766572792866756E6374696F6E2865297B72657475726E205428652C742C72297D';
wwv_flow_imp.g_varchar2_table(70) := '297D29297D66756E6374696F6E204128652C74297B76617220723D742E535B537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C7465722866756E63';
wwv_flow_imp.g_varchar2_table(71) := '74696F6E2872297B72657475726E205328652E66696C7465722C742C72297D293A727D66756E6374696F6E204328652C742C72297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F6620652972657475726E20';
wwv_flow_imp.g_varchar2_table(72) := '653B766172206E3D7828742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E204E28652C742C72297B766172206E3D6E756C6C3B7265747572';
wwv_flow_imp.g_varchar2_table(73) := '6E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E21215328652E7768656E2C742C72292626286E3D652C2130297D292C6E7D76617220503D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D';
wwv_flow_imp.g_varchar2_table(74) := '2C617269616C3A5B2268656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75';
wwv_flow_imp.g_varchar2_table(75) := '726965723A5B22636F7572696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E207A28652C74297B76617220722C6E3D5B5D2C6F3D7B623A21312C693A';
wwv_flow_imp.g_varchar2_table(76) := '21312C753A21312C733A21317D2C613D5B28743D747C7C7B7D292E666F6E747C7C2268656C766574696361225D2C693D5B742E636F6C6F727C7C6E756C6C5D2C6C3D22222C753D303B66756E6374696F6E207328297B76617220653B6C2626286E2E7075';
wwv_flow_imp.g_varchar2_table(77) := '7368287B743A6C2C623A6F2E622C693A6F2E692C753A6F2E752C733A6F2E732C663A28653D615B612E6C656E6774682D315D2C653D537472696E6728657C7C2268656C76657469636122292E746F4C6F7765724361736528292C505B655D3F653A226865';
wwv_flow_imp.g_varchar2_table(78) := '6C76657469636122292C633A695B692E6C656E6774682D315D7D292C6C3D2222297D666F7228653D537472696E67286E756C6C3D3D653F22223A65293B753C652E6C656E6774683B297B76617220633D652E7375627374722875293B225C5C223D3D3D63';
wwv_flow_imp.g_varchar2_table(79) := '2E6368617241742830292626632E6C656E6774683E313F286C2B3D632E6368617241742831292C752B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286329293F287328292C612E7075736828725B315D292C752B3D72';
wwv_flow_imp.g_varchar2_table(80) := '5B305D2E6C656E677468293A225B2F665D22213D3D632E73756273747228302C34293F28723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286329293F287328292C692E7075736828725B315D292C752B3D725B30';
wwv_flow_imp.g_varchar2_table(81) := '5D2E6C656E677468293A225B2F635D22213D3D632E73756273747228302C34293F222A2A2A22213D3D632E73756273747228302C33293F222A2A22213D3D632E73756273747228302C32293F227E7E22213D3D632E73756273747228302C32293F222B2B';
wwv_flow_imp.g_varchar2_table(82) := '22213D3D632E73756273747228302C32293F222A22213D3D632E6368617241742830293F286C2B3D632E6368617241742830292C752B2B293A287328292C6F2E693D216F2E692C752B3D31293A287328292C6F2E753D216F2E752C752B3D32293A287328';
wwv_flow_imp.g_varchar2_table(83) := '292C6F2E733D216F2E732C752B3D32293A287328292C6F2E623D216F2E622C752B3D32293A287328292C6F2E623D216F2E622C6F2E693D216F2E692C752B3D33293A287328292C692E6C656E6774683E312626692E706F7028292C752B3D34293A287328';
wwv_flow_imp.g_varchar2_table(84) := '292C612E6C656E6774683E312626612E706F7028292C752B3D34297D72657475726E207328292C6E7D66756E6374696F6E206B28652C74297B76617220723D652E736F757263653F4128652C74295B305D3A6E756C6C3B72657475726E2841727261792E';
wwv_flow_imp.g_varchar2_table(85) := '6973417272617928652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C697428225C6E2229292E6D61702866756E6374696F6E2865297B72657475726E204528652C742C72';
wwv_flow_imp.g_varchar2_table(86) := '297D297D66756E6374696F6E204D28652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D742E545B6E5D7C7C7B7D2C693D652E636F6C756D6E733B72657475726E20692626692E';
wwv_flow_imp.g_varchar2_table(87) := '6C656E6774687C7C28693D4F626A6563742E6B6579732861292E66696C7465722866756E6374696F6E2865297B72657475726E22444F435F4B455922213D3D657D292E6D61702866756E6374696F6E2865297B72657475726E7B636F6C3A657D7D29292C';
wwv_flow_imp.g_varchar2_table(88) := '28693D692E66696C7465722866756E6374696F6E2865297B72657475726E22737472696E67223D3D747970656F6620657C7C21652E7768656E7C7C5328652E7768656E2C742C6E756C6C297D29292E6D61702866756E6374696F6E2865297B7661722074';
wwv_flow_imp.g_varchar2_table(89) := '3D28653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C292E746F55707065724361736528293A6E756C6C2C6E3D743F615B745D3A6E756C6C2C693D652E666D743B72657475726E20';
wwv_flow_imp.g_varchar2_table(90) := '697C7C224E554D42455222213D3D6E7C7C652E76616C75657C7C28693D722E736F6D652866756E6374696F6E2865297B72657475726E206F28655B745D2926264D6174682E726F756E6428655B745D29213D3D655B745D7D293F226D6F6E6579223A6E75';
wwv_flow_imp.g_varchar2_table(91) := '6C6C292C7B636F6C3A742C76616C75653A652E76616C75652C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628747C7C2222292C666D743A692C6D61703A652E6D61702C626F6C643A2121652E626F6C642C7769647468';
wwv_flow_imp.g_varchar2_table(92) := '3A652E77696474682C616C69676E3A652E616C69676E7C7C286D2869293F226C656674223A224E554D424552223D3D3D6E7C7C226D6F6E6579223D3D3D697C7C22696E74223D3D3D697C7C226E756D223D3D3D693F227269676874223A2244415445223D';
wwv_flow_imp.g_varchar2_table(93) := '3D3D6E7C7C2264617465223D3D3D693F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63656C6C5374796C652C636F6C6F723A652E636F6C6F722C69734E756D3A216D286929262628224E554D424552223D3D3D6E262621652E';
wwv_flow_imp.g_varchar2_table(94) := '6D6170262621652E76616C75657C7C226D6F6E6579223D3D3D697C7C22696E74223D3D3D697C7C2F5E6E756D2F2E7465737428697C7C222229297D7D297D66756E6374696F6E204628652C74297B76617220723D5B5D2C6E3D303B72657475726E28652E';
wwv_flow_imp.g_varchar2_table(95) := '67726F7570737C7C5B5D292E666F72456163682866756E6374696F6E2865297B766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E677468262628722E70757368';
wwv_flow_imp.g_varchar2_table(96) := '287B6C6162656C3A652E6C6162656C7C7C22222C636F6C733A6F2C66726F6D3A6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C733A742E6C656E6774682D';
wwv_flow_imp.g_varchar2_table(97) := '6E2C66726F6D3A6E2C6761703A21307D292C727D66756E6374696F6E204F28652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E204528652E76616C75652C722C74293B766172206E3D745B652E636F6C5D3B7265747572';
wwv_flow_imp.g_varchar2_table(98) := '6E20652E6D617026266E756C6C213D6E2626766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E206A28652C742C72297B766172206E3D4F28652C742C72293B72657475726E20652E6D61702626766F69642030';
wwv_flow_imp.g_varchar2_table(99) := '213D3D652E6D61705B745B652E636F6C5D5D3F537472696E67286E293A70286E2C652E666D74297D76617220493D7B73756D3A392C6176673A312C6D696E3A352C6D61783A342C636F756E743A337D2C523D7B73756D3A2253554D222C6176673A224156';
wwv_flow_imp.g_varchar2_table(100) := '4552414745222C6D696E3A224D494E222C6D61783A224D4158222C636F756E743A22434F554E5441227D2C4C3D7B6176673A2250726F6D2E222C6D696E3A224DC3AD6E2E222C6D61783A224DC3A1782E222C636F756E743A2243616E742E227D3B66756E';
wwv_flow_imp.g_varchar2_table(101) := '6374696F6E20442865297B72657475726E2841727261792E697341727261792865293F653A5B5D292E6D61702866756E6374696F6E2865297B76617220743D652626226F626A656374223D3D747970656F6620653F653A7B636F6C3A657D2C723D537472';
wwv_flow_imp.g_varchar2_table(102) := '696E6728742E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475726E7B636F6C3A537472696E6728742E636F6C7C7C2222292E746F55707065724361736528292C666E3A495B725D3F723A2273756D227D7D292E66696C74657228';
wwv_flow_imp.g_varchar2_table(103) := '66756E6374696F6E2865297B72657475726E20652E636F6C7D297D66756E6374696F6E205528652C74297B666F722876617220723D303B723C652E6C656E6774683B722B2B29696628655B725D2E636F6C3D3D3D742972657475726E20655B725D3B7265';
wwv_flow_imp.g_varchar2_table(104) := '7475726E206E756C6C7D66756E6374696F6E20422865297B72657475726E20652E736F6D652866756E6374696F6E2865297B72657475726E2273756D22213D3D652E666E7D297D66756E6374696F6E205F2865297B72657475726E206F2865297C7C2273';
wwv_flow_imp.g_varchar2_table(105) := '7472696E67223D3D747970656F66206526262222213D3D652E7472696D282926262169734E614E284E756D626572286529297D66756E6374696F6E204728652C742C72297B766172206E3D652E6D61702866756E6374696F6E2865297B72657475726E20';
wwv_flow_imp.g_varchar2_table(106) := '655B745D7D292E66696C7465722866756E6374696F6E2865297B72657475726E206E756C6C213D6526262222213D3D657D293B69662822636F756E74223D3D3D722972657475726E206E2E6C656E6774683B6966282273756D223D3D3D727C7C22617667';
wwv_flow_imp.g_varchar2_table(107) := '223D3D3D72297B766172206F3D6E2E66696C746572285F292E6D6170284E756D626572292C613D6F2E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30293B72657475726E2273756D223D3D3D723F613A6F2E6C656E';
wwv_flow_imp.g_varchar2_table(108) := '6774683F612F6F2E6C656E6774683A6E756C6C7D76617220693D6E756C6C2C6C3D6E756C6C3B72657475726E206E2E666F72456163682866756E6374696F6E2865297B76617220743D5F2865293F6E756C6C3A642865292C6E3D5F2865293F4E756D6265';
wwv_flow_imp.g_varchar2_table(109) := '722865293A743F742E67657454696D6528293A537472696E672865293B286E756C6C3D3D3D6C7C7C28226D696E223D3D3D723F6E3C6C3A6E3E6C2929262628693D652C6C3D6E297D292C697D66756E6374696F6E205728652C742C722C6E297B76617220';
wwv_flow_imp.g_varchar2_table(110) := '6F3D422874292C613D2D312C693D652E6D61702866756E6374696F6E28652C6E297B76617220693D652E636F6C3F5528742C652E636F6C293A6E756C6C3B72657475726E20692626613C30262628613D6E292C693F66756E6374696F6E28652C742C722C';
wwv_flow_imp.g_varchar2_table(111) := '6E297B766172206F2C613D4728722C742E636F6C2C742E666E293B72657475726E286F3D6E756C6C3D3D613F22223A22636F756E74223D3D3D742E666E3F7028612C22696E7422293A226D696E223D3D3D742E666E7C7C226D6178223D3D3D742E666E3F';
wwv_flow_imp.g_varchar2_table(112) := '5F2861293F7028612C652E666D747C7C226D6F6E657922293A7028612C652E666D74293A22617667223D3D3D742E666E3F7028612C652E666D74262622696E7422213D3D652E666D743F652E666D743A226D6F6E657922293A7028612C652E666D747C7C';
wwv_flow_imp.g_varchar2_table(113) := '226D6F6E657922292926266E26264C5B742E666E5D3F4C5B742E666E5D2B2220222B6F3A6F7D28652C692C722C6F293A22227D293B72657475726E7B61743A613C303F652E6C656E6774683A612C63656C6C733A692C746578743A6E7D7D66756E637469';
wwv_flow_imp.g_varchar2_table(114) := '6F6E204828652C742C72297B72657475726E204528652E746F74616C734C6162656C7C7C22546F74616C6573222C742C7B434F554E543A722E6C656E6774687D297D66756E6374696F6E202428652C74297B76617220723D7B636F6E74656E743A652E74';
wwv_flow_imp.g_varchar2_table(115) := '6578742C636F6C5370616E3A652E61747C7C742C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E20303D3D3D652E61743F5B5B725D2C652E63656C6C732E736C69636528295D3A5B5B725D2E636F6E63617428652E63656C6C';
wwv_flow_imp.g_varchar2_table(116) := '732E736C69636528652E617429295D7D66756E6374696F6E20562865297B72657475726E21313D3D3D652E627265616B546F74616C733F5B5D3A442841727261792E6973417272617928652E627265616B546F74616C73293F652E627265616B546F7461';
wwv_flow_imp.g_varchar2_table(117) := '6C733A652E746F74616C73297D66756E6374696F6E207128652C74297B69662821652E627265616B42797C7C21742E6C656E6774682972657475726E20742E6D61702866756E6374696F6E28652C74297B72657475726E7B6B3A22726F77222C723A652C';
wwv_flow_imp.g_varchar2_table(118) := '693A747D7D293B76617220723D537472696E6728652E627265616B4279292E746F55707065724361736528292C6E3D5B5D2C6F3D6E756C6C2C613D302C693D562865292E6C656E6774683E303B66756E6374696F6E206C28297B6F26266926266E2E7075';
wwv_flow_imp.g_varchar2_table(119) := '7368287B6B3A22737562222C723A6F2E722C726F77733A6F2E726F77737D297D72657475726E20742E666F72456163682866756E6374696F6E2874297B76617220693D537472696E67286E756C6C3D3D3D745B725D7C7C766F696420303D3D3D745B725D';
wwv_flow_imp.g_varchar2_table(120) := '3F22223A745B725D293B6F26266F2E6B65793D3D3D697C7C286C28292C6F3D7B6B65793A692C723A742C726F77733A5B5D7D2C2131213D3D652E627265616B5469746C6526266E2E70757368287B6B3A2268656164222C723A742C726F77733A6F2E726F';
wwv_flow_imp.g_varchar2_table(121) := '77737D29292C6F2E726F77732E707573682874292C6E2E70757368287B6B3A22726F77222C723A742C693A612B2B7D297D292C6C28292C6E7D66756E6374696F6E205928652C742C72297B766172206E2C6F3D7B7D2C613D537472696E6728652E627265';
wwv_flow_imp.g_varchar2_table(122) := '616B4279292E746F55707065724361736528293B666F72286E20696E20742E72296F5B6E5D3D742E725B6E5D3B6F2E434F554E543D742E726F77732E6C656E6774683B76617220693D2268656164223D3D3D742E6B3F652E627265616B5469746C653A65';
wwv_flow_imp.g_varchar2_table(123) := '2E627265616B4C6162656C3B72657475726E206E756C6C213D6926262130213D3D697C7C28693D2268656164223D3D3D742E6B3F227B222B612B227D223A22537562746F74616C207B222B612B227D22292C4528692C722C6F297D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(124) := '5A28652C742C72297B696628652E6D6170297B766172206E3D7828742C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C2222292E73706C697428227C22295B305D2C72293B72657475726E20766F69642030213D3D652E';
wwv_flow_imp.g_varchar2_table(125) := '6D61705B6E5D3F652E6D61705B6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E7D7C5D2B5C7D242F2E74657374286F7C7C2222293F70287828742C6F2E736C6963652831';
wwv_flow_imp.g_varchar2_table(126) := '2C2D31292C72292C652E666D74293A45286F2C742C72297D76617220583D7B746578743A312C6D756C74696C696E653A312C6C6973743A312C636865636B626F783A317D2C4A3D2223463246364641222C4B3D2223424643394434222C513D22E2989222';
wwv_flow_imp.g_varchar2_table(127) := '2C65653D22E29890223B66756E6374696F6E2074652865297B76617220743D537472696E67286E756C6C3D3D653F22223A65293B696628212F5E5B412D5A612D7A5F5D5B412D5A612D7A302D395F5D7B302C33397D242F2E746573742874297C7C2F5E5B';
wwv_flow_imp.g_varchar2_table(128) := '412D5A612D7A5D7B312C337D5B302D395D2B242F2E746573742874297C7C2F5E5B527243635D242F2E746573742874297C7C2F5E5B52725D5B302D395D2A5B43635D5B302D395D2A242F2E74657374287429297468726F77206E6577204572726F722827';
wwv_flow_imp.g_varchar2_table(129) := '4E6F6D6272652064652063616D706F20696E76C3A16C69646F3A2022272B742B27222E20557365206C65747261732C206EC3BA6D65726F732079205F202868617374612034302C2073696E206573706163696F73206E692070756E746F73292079207175';
wwv_flow_imp.g_varchar2_table(130) := '65206E6F20706172657A636120756E612063656C646120646520457863656C202841312C2052314331292E27293B72657475726E20747D66756E6374696F6E20726528297B76617220653D7B7D3B72657475726E2066756E6374696F6E2874297B766172';
wwv_flow_imp.g_varchar2_table(131) := '20723D742E746F4C6F7765724361736528293B696628655B725D297468726F77206E6577204572726F7228274E6F6D6272652064652063616D706F20726570657469646F20656E20656C20646F63756D656E746F3A2022272B742B27222E27293B726574';
wwv_flow_imp.g_varchar2_table(132) := '75726E20655B725D3D312C747D7D66756E6374696F6E206E652865297B72657475726E21303D3D3D657C7C2F5E28737C73697C73C3AD7C797C7965737C317C787C747275657C6F6E29242F692E7465737428537472696E67286E756C6C3D3D653F22223A';
wwv_flow_imp.g_varchar2_table(133) := '65292E7472696D2829297D66756E6374696F6E206F6528652C742C72297B766172206E3D4128652C74295B305D7C7C7B7D3B72657475726E28652E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E20652626';
wwv_flow_imp.g_varchar2_table(134) := '2821652E7768656E7C7C5328652E7768656E2C742C6E29297D292E6D61702866756E6374696F6E2865297B766172206F3D537472696E6728652E696E7075747C7C227465787422292E746F4C6F7765724361736528293B69662821585B6F5D297468726F';
wwv_flow_imp.g_varchar2_table(135) := '77206E6577204572726F7228275469706F2064652063616D706F206E6F20736F706F727461646F3A2022272B652E696E7075742B27222028746578742C206D756C74696C696E652C206C6973742C20636865636B626F78292E27293B76617220613D7465';
wwv_flow_imp.g_varchar2_table(136) := '28652E6E616D65292B28727C7C2222292C693D766F696420303D3D3D652E76616C75657C7C6E756C6C3D3D3D652E76616C75653F22223A537472696E67285A28652C742C6E29292C6C3D226C697374223D3D3D6F3F66756E6374696F6E28652C74297B76';
wwv_flow_imp.g_varchar2_table(137) := '617220723D5B5D3B66756E6374696F6E206E2865297B2222213D3D28653D537472696E67286E756C6C3D3D653F22223A6529292626722E696E6465784F662865293C302626722E707573682865297D6966282841727261792E6973417272617928652E6F';
wwv_flow_imp.g_varchar2_table(138) := '7074696F6E73293F652E6F7074696F6E733A5B5D292E666F7245616368286E292C652E6F7074696F6E7346726F6D297B766172206F3D537472696E6728652E6F7074696F6E7346726F6D292E73706C697428222E22292C613D6F5B315D3F6F5B315D2E74';
wwv_flow_imp.g_varchar2_table(139) := '6F55707065724361736528293A6E756C6C3B41287B736F757263653A6F5B305D7D2C74292E666F72456163682866756E6374696F6E2865297B6E28613F655B615D3A655B4F626A6563742E6B6579732865295B305D5D297D297D72657475726E20727D28';
wwv_flow_imp.g_varchar2_table(140) := '652C74293A5B5D3B696628226C697374223D3D3D6F2626216C2E6C656E677468297468726F77206E6577204572726F722827456C2063616D706F2022272B612B272220657320756E61206C697374612073696E206F7063696F6E657320286F7074696F6E';
wwv_flow_imp.g_varchar2_table(141) := '732075206F7074696F6E7346726F6D292E27293B76617220753D282274657874223D3D3D6F7C7C226D756C74696C696E65223D3D3D6F2926264E756D62657228652E6D61784C656E677468293E303F4D6174682E666C6F6F72284E756D62657228652E6D';
wwv_flow_imp.g_varchar2_table(142) := '61784C656E67746829293A303B72657475726E226D756C74696C696E6522213D3D6F262628693D692E7265706C616365282F5C723F5C6E2F672C22202229292C226C697374223D3D3D6F26266C2E696E6465784F662869293C30262628693D2222292C75';
wwv_flow_imp.g_varchar2_table(143) := '262628693D692E73756273747228302C7529292C7B6C6162656C3A4528652E6C6162656C2C742C6E292C6E616D653A612C696E7075743A6F2C6F7074696F6E733A6C2C76616C75653A22636865636B626F78223D3D3D6F3F22223A692C636865636B6564';
wwv_flow_imp.g_varchar2_table(144) := '3A22636865636B626F78223D3D3D6F26266E652869292C6D61784C656E6774683A752C726561644F6E6C793A21303D3D3D652E726561644F6E6C792C6C696E65733A226D756C74696C696E65223D3D3D6F3F4D6174682E6D617828322C4D6174682E6D69';
wwv_flow_imp.g_varchar2_table(145) := '6E2832302C4E756D62657228652E6C696E6573297C7C3329293A312C706C616365686F6C6465723A652E706C616365686F6C6465723F4528652E706C616365686F6C6465722C742C6E293A22227D7D297D66756E6374696F6E20616528652C74297B7661';
wwv_flow_imp.g_varchar2_table(146) := '7220723D652E666F726D7C7C7B7D2C6E3D742626766F69642030213D3D742E666F726D50617373776F726426266E756C6C213D3D742E666F726D50617373776F72643F742E666F726D50617373776F72643A722E70617373776F72643B72657475726E7B';
wwv_flow_imp.g_varchar2_table(147) := '70726F746563743A2131213D3D722E70726F746563742C70617373776F72643A6E3F537472696E67286E293A22227D7D66756E6374696F6E2069652865297B72657475726E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E';
wwv_flow_imp.g_varchar2_table(148) := '206526262822666F726D756C6172696F223D3D3D652E747970657C7C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E736F6D6528696529297D297D66756E6374696F6E206C652865297B76617220743D652626652E';
wwv_flow_imp.g_varchar2_table(149) := '62617463682626652E62617463682E73756D6D6172793B72657475726E20696528652626652E73656374696F6E73297C7C212821747C7C2128696528742E73656374696F6E73297C7C742E6C61796F75742626696528742E6C61796F75742E7365637469';
wwv_flow_imp.g_varchar2_table(150) := '6F6E732929297D7661722075653D5B313131363335323430382C333630393736373435382C313839393434373434312C3630323839313732352C333034393332333437312C333936343438343339392C333932313030393537332C323137333239353534';
wwv_flow_imp.g_varchar2_table(151) := '382C3936313938373136332C343038313632383437322C313530383937303939332C333035333833343236352C323435333633353734382C323933373637313537392C323837303736333232312C333636343630393536302C333632343338313038302C';
wwv_flow_imp.g_varchar2_table(152) := '323733343838333339342C3331303539383430312C313136343939363534322C3630373232353237382C313332333631303736342C313432363838313938372C333539303330343939342C313932353037383338382C343036383138323338332C323136';
wwv_flow_imp.g_varchar2_table(153) := '323037383230362C3939313333363131332C323631343838383130332C3633333830333331372C333234383232323538302C333437393737343836382C333833353339303430312C323636363631333435382C343032323232343737342C393434373131';
wwv_flow_imp.g_varchar2_table(154) := '3133392C3236343334373037382C323334313236323737332C3630343830373632382C323030373830303933332C3737303235353938332C313439353939303930312C313234393135303132322C313835363433313233352C313535353038313639322C';
wwv_flow_imp.g_varchar2_table(155) := '333137353231383133322C313939363036343938362C323139383935303833372C323535343232303838322C333939393731393333392C323832313833343334392C3736363738343031362C323935323939363830382C323536363539343837392C3332';
wwv_flow_imp.g_varchar2_table(156) := '31303331333637312C333230333333373935362C333333363537313839312C313033343435373032362C333538343532383731312C323436363934383930312C3131333932363939332C333735383332363338332C3333383234313839352C3136383731';
wwv_flow_imp.g_varchar2_table(157) := '373933362C3636363330373230352C313138383137393936342C3737333532393931322C313534363034353733342C313239343735373337322C313532323830353438352C313339363138323239312C323634333833333832332C313639353138333730';
wwv_flow_imp.g_varchar2_table(158) := '302C323334333532373339302C313938363636313035312C313031343437373438302C323137373032363335302C313230363735393134322C323435363935363033372C3334343037373632372C323733303438353932312C313239303836333436302C';
wwv_flow_imp.g_varchar2_table(159) := '323832303330323431312C333135383435343237332C333235393733303830302C333530353935323635372C333334353736343737312C3130363231373030382C333531363036353831372C333630363030383334342C333630303335323830342C3134';
wwv_flow_imp.g_varchar2_table(160) := '33323732353737362C343039343537313930392C313436373033313539342C3237353432333334342C3835313136393732302C3433303232373733342C333130303832333735322C3530363934383631362C313336333235383139352C36353930363035';
wwv_flow_imp.g_varchar2_table(161) := '35362C333735303638353539332C3838333939373837372C333738353035303238302C3935383133393537312C333331383330373432372C313332323832323231382C333831323732333430332C313533373030323036332C323030333033343939352C';
wwv_flow_imp.g_varchar2_table(162) := '313734373837333737392C333630323033363839392C313935353536323232322C313537353939303031322C323032343130343831352C313132353539323932382C323232373733303435322C323731363930343330362C323336313835323432342C34';
wwv_flow_imp.g_varchar2_table(163) := '34323737363034342C323432383433363437342C3539333639383334342C323735363733343138372C333733333131303234392C333230343033313437392C323939393335313537332C333332393332353239382C333831353932303432372C33333931';
wwv_flow_imp.g_varchar2_table(164) := '3536393631342C333932383338333930302C333531353236373237312C3536363238303731312C333934303138373630362C333435343036393533342C343131383633303237312C343030303233393939322C3131363431383437342C31393134313338';
wwv_flow_imp.g_varchar2_table(165) := '3535342C3137343239323432312C323733313035353237302C3238393338303335362C333230333939333030362C3436303339333236392C3332303632303331352C3638353437313733332C3538373439363833362C3835323134323937312C31303836';
wwv_flow_imp.g_varchar2_table(166) := '3739323835312C313031373033363239382C3336353534333130302C313132363030303538302C323631383239373637362C313238383033333437302C333430393835353135382C313530313530353934382C343233343530393836362C313630373136';
wwv_flow_imp.g_varchar2_table(167) := '373931352C3938373136373436382C313831363430323331362C313234363138393539315D3B66756E6374696F6E2073652865297B76617220742C722C6E3D5B313737393033333730332C343038393233353732302C333134343133343237372C323232';
wwv_flow_imp.g_varchar2_table(168) := '373837333539352C313031333930343234322C343237313137353732332C323737333438303736322C313539353735303132392C313335393839333131392C323931373536353133372C323630303832323932342C3732353531313139392C3532383733';
wwv_flow_imp.g_varchar2_table(169) := '343633352C343231353338393534372C313534313435393232352C3332373033333230395D2C6F3D652E6C656E6774682C613D6F2B31372B3132373E3E373C3C372C693D6E65772055696E743841727261792861292C6C3D6E657720496E743332417272';
wwv_flow_imp.g_varchar2_table(170) := '617928313630293B692E7365742865292C695B6F5D3D3132383B76617220753D382A6F3B695B612D315D3D32353526752C695B612D325D3D753E3E3E38263235352C695B612D335D3D753E3E3E3136263235352C695B612D345D3D753E3E3E3234263235';
wwv_flow_imp.g_varchar2_table(171) := '352C695B612D355D3D323535264D6174682E666C6F6F7228752F34323934393637323936293B666F722876617220733D343239343936373239362C633D303B633C613B632B3D313238297B666F7228743D303B743C33323B742B2B29723D632B342A742C';
wwv_flow_imp.g_varchar2_table(172) := '6C5B745D3D695B725D3C3C32347C695B722B315D3C3C31367C695B722B325D3C3C387C695B722B335D3B666F7228743D33323B743C3136303B742B3D32297B76617220663D6C5B742D33305D2C643D6C5B742D32395D2C683D6C5B742D345D2C703D6C5B';
wwv_flow_imp.g_varchar2_table(173) := '742D335D2C6D3D28663E3E3E317C643C3C3331295E28663E3E3E387C643C3C3234295E663E3E3E372C673D28683E3E3E31397C703C3C3133295E28703E3E3E32397C683C3C33295E683E3E3E362C763D28703E3E3E31397C683C3C3133295E28683E3E3E';
wwv_flow_imp.g_varchar2_table(174) := '32397C703C3C33295E28703E3E3E367C683C3C3236292C773D282828643E3E3E317C663C3C3331295E28643E3E3E387C663C3C3234295E28643E3E3E377C663C3C323529293E3E3E30292B286C5B742D31335D3E3E3E30292B28763E3E3E30292B286C5B';
wwv_flow_imp.g_varchar2_table(175) := '742D33315D3E3E3E30292C623D6D2B6C5B742D31345D2B672B6C5B742D33325D2B4D6174682E666C6F6F7228772F73297C303B6C5B745D3D622C6C5B742B315D3D307C777D76617220793D6E5B305D2C783D6E5B315D2C453D6E5B325D2C543D6E5B335D';
wwv_flow_imp.g_varchar2_table(176) := '2C533D6E5B345D2C413D6E5B355D2C433D6E5B365D2C4E3D6E5B375D2C503D6E5B385D2C7A3D6E5B395D2C6B3D6E5B31305D2C4D3D6E5B31315D2C463D6E5B31325D2C4F3D6E5B31335D2C6A3D6E5B31345D2C493D6E5B31355D3B666F7228743D303B74';
wwv_flow_imp.g_varchar2_table(177) := '3C3136303B742B3D32297B76617220523D28503E3E3E31347C7A3C3C3138295E28503E3E3E31387C7A3C3C3134295E287A3E3E3E397C503C3C3233292C4C3D50266B5E7E5026462C443D28493E3E3E30292B2828287A3E3E3E31347C503C3C3138295E28';
wwv_flow_imp.g_varchar2_table(178) := '7A3E3E3E31387C503C3C3134295E28503E3E3E397C7A3C3C323329293E3E3E30292B28287A264D5E7E7A264F293E3E3E30292B2875655B742B315D3E3E3E30292B286C5B742B315D3E3E3E30292C553D6A2B522B4C2B75655B745D2B6C5B745D2B4D6174';
wwv_flow_imp.g_varchar2_table(179) := '682E666C6F6F7228442F73297C303B447C3D303B76617220423D282828783E3E3E32387C793C3C34295E28793E3E3E327C783C3C3330295E28793E3E3E377C783C3C323529293E3E3E30292B28287826545E7826415E542641293E3E3E30292C5F3D2828';
wwv_flow_imp.g_varchar2_table(180) := '793E3E3E32387C783C3C34295E28783E3E3E327C793C3C3330295E28783E3E3E377C793C3C323529292B287926455E7926535E452653292B4D6174682E666C6F6F7228422F73297C303B427C3D302C6A3D462C493D4F2C463D6B2C4F3D4D2C6B3D502C4D';
wwv_flow_imp.g_varchar2_table(181) := '3D7A3B76617220473D284E3E3E3E30292B28443E3E3E30293B503D432B552B4D6174682E666C6F6F7228472F73297C302C7A3D307C472C433D532C4E3D412C533D452C413D542C453D792C543D782C473D28443E3E3E30292B28423E3E3E30292C793D55';
wwv_flow_imp.g_varchar2_table(182) := '2B5F2B4D6174682E666C6F6F7228472F73297C302C783D307C477D76617220573D5B792C782C452C542C532C412C432C4E2C502C7A2C6B2C4D2C462C4F2C6A2C495D3B666F7228743D303B743C31363B742B3D32297B76617220483D286E5B742B315D3E';
wwv_flow_imp.g_varchar2_table(183) := '3E3E30292B28575B742B315D3E3E3E30293B6E5B745D3D6E5B745D2B575B745D2B4D6174682E666C6F6F7228482F73297C302C6E5B742B315D3D307C487D7D76617220243D6E65772055696E74384172726179283634293B666F7228743D303B743C3136';
wwv_flow_imp.g_varchar2_table(184) := '3B742B2B29245B342A745D3D6E5B745D3E3E3E32342C245B342A742B315D3D6E5B745D3E3E3E3136263235352C245B342A742B325D3D6E5B745D3E3E3E38263235352C245B342A742B335D3D323535266E5B745D3B72657475726E20247D766172206365';
wwv_flow_imp.g_varchar2_table(185) := '3D5B35373834302C373433392C35323338302C33333938342C343336342C333630302C36313930322C31323630362C363235382C35373635372C35343238372C33343034312C31303235322C34333337302C32303136335D2C66653D5B5B34343739362C';
wwv_flow_imp.g_varchar2_table(186) := '31393932392C33393835382C31303035332C32303130362C34303231322C31303736315D2C5B33313538352C36333137302C36343933332C36303236372C35303933352C34303339392C31313139395D2C5B31373736332C33353532362C313435332C32';
wwv_flow_imp.g_varchar2_table(187) := '3930362C353831322C31313632342C32333234385D2C5B3838352C313737302C333534302C373038302C31343136302C32383332302C35363634305D2C5B35353336392C34313133392C32303830372C34313631342C32313832312C34333634322C3137';
wwv_flow_imp.g_varchar2_table(188) := '3632315D2C5B32383438352C35363937302C34343334312C31393031392C33383033382C31343630352C32393231305D2C5B36303139352C35303739312C34303137352C31303735312C32313530322C34333030342C32343533375D2C5B31383338372C';
wwv_flow_imp.g_varchar2_table(189) := '33363737342C333934392C373839382C31353739362C33313539322C36333138345D2C5B34373230312C32343830332C34393630362C33373830352C31343230332C32383430362C35363831325D2C5B31373832342C33353634382C313639372C333339';
wwv_flow_imp.g_varchar2_table(190) := '342C363738382C31333537362C32373135325D2C5B34333630312C31373533392C33353037382C3535372C313131342C323232382C343435365D2C5B33303338382C36303737362C35313935332C33343234332C373037392C31343135382C3238333136';
wwv_flow_imp.g_varchar2_table(191) := '5D2C5B31343132382C32383235362C35363531322C34333432352C31373235312C33343530322C373539375D2C5B31333130352C32363231302C35323432302C33353234312C3838332C313736362C333533325D2C5B343132392C383235382C31363531';
wwv_flow_imp.g_varchar2_table(192) := '362C33333033322C343635372C393331342C31383632385D5D3B66756E6374696F6E2064652865297B76617220742C722C6E3D5B5D2C6F3D66756E6374696F6E2865297B72657475726E28653C31363F2230223A2222292B652E746F537472696E672831';
wwv_flow_imp.g_varchar2_table(193) := '36292E746F55707065724361736528297D3B666F7228743D303B743C652E6C656E6774683B742B2B297B76617220613D652E63686172436F646541742874293B6E2E707573682832353526617C7C613E3E3826323535297D76617220693D63655B6E2E6C';
wwv_flow_imp.g_varchar2_table(194) := '656E6774682D315D2C6C3D31352D6E2E6C656E6774682C753D303B666F7228743D303B743C6E2E6C656E6774683B742B2B297B76617220733D6E5B745D2C633D66655B6C2B2B5D3B666F7228723D303B723C373B722B2B29312673262628695E3D635B72';
wwv_flow_imp.g_varchar2_table(195) := '5D292C733E3E3D317D66756E6374696F6E20662865297B72657475726E20653E3E313426317C653C3C312633323736377D666F7228743D6E2E6C656E6774682D313B743E3D303B742D2D29753D662875295E6E5B745D3B72657475726E206F2832353526';
wwv_flow_imp.g_varchar2_table(196) := '28753D662875295E6E2E6C656E6774685E353238313129292B6F28753E3E3826323535292B6F283235352669292B6F28693E3E3826323535297D66756E6374696F6E20686528652C742C72297B696628212F5E5B5C7832302D5C7837455D7B312C31357D';
wwv_flow_imp.g_varchar2_table(197) := '242F2E74657374286529297468726F77206E6577204572726F7228224C6120636F6E7472617365C3B1612064652070726F7465636369C3B36E20646520576F72642061646D69746520646520312061203135206361726163746572657320415343494920';
wwv_flow_imp.g_varchar2_table(198) := '2873696E2074696C646573206E6920C3B1292E22293B766172206E2C6F3D64652865292C613D6E65772055696E7438417272617928742E6C656E6774682B322A6F2E6C656E677468293B666F7228612E7365742874292C6E3D303B6E3C6F2E6C656E6774';
wwv_flow_imp.g_varchar2_table(199) := '683B6E2B2B29615B742E6C656E6774682B322A6E5D3D6F2E63686172436F64654174286E293B76617220693D73652861292C6C3D6E65772055696E74384172726179283638293B666F72286E3D303B6E3C723B6E2B2B296C2E7365742869292C6C5B3634';
wwv_flow_imp.g_varchar2_table(200) := '5D3D323535266E2C6C5B36355D3D6E3E3E3E38263235352C6C5B36365D3D6E3E3E3E3136263235352C6C5B36375D3D6E3E3E3E3234263235352C693D7365286C293B72657475726E20697D66756E6374696F6E20706528652C742C72297B72657475726E';
wwv_flow_imp.g_varchar2_table(201) := '28652E73656374696F6E737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E2821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D302926262821727C7C766528652C7229297D297D766172';
wwv_flow_imp.g_varchar2_table(202) := '206D653D7B66696368613A312C666F726D756C6172696F3A312C746578746F3A312C696D6167656E3A312C636F6469676F3A312C616C657274613A312C6C696E65613A312C7461626C613A312C6772616669636F3A312C6573706163696F3A317D3B6675';
wwv_flow_imp.g_varchar2_table(203) := '6E6374696F6E20676528652C742C722C6E297B766172206F3D2841727261792E6973417272617928652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33292C613D6F2E6C656E6774683B69662821612972657475726E5B5D3B76617220';
wwv_flow_imp.g_varchar2_table(204) := '693D6F2E6D61702866756E6374696F6E28742C72297B766172206E3D4E756D6265722828652E7769647468737C7C5B5D295B725D293B72657475726E206E3E303F6E3A3130302F617D292C6C3D692E7265647563652866756E6374696F6E28652C74297B';
wwv_flow_imp.g_varchar2_table(205) := '72657475726E20652B747D2C30292C753D766F69642030213D3D652E636F6C4761703F4E756D62657228652E636F6C476170293A342C733D6E2D752A28612D31292C633D303B72657475726E206F2E6D61702866756E6374696F6E28652C6E297B766172';
wwv_flow_imp.g_varchar2_table(206) := '206F3D732A695B6E5D2F6C2C613D2841727261792E697341727261792865293F653A5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526266D655B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174';
wwv_flow_imp.g_varchar2_table(207) := '732E696E6465784F662874293E3D30292626766528652C72297D292E6D61702866756E6374696F6E2865297B72657475726E2066756E6374696F6E28652C74297B76617220722C6E3D7B7D3B666F72287220696E2065294F626A6563742E70726F746F74';
wwv_flow_imp.g_varchar2_table(208) := '7970652E6861734F776E50726F70657274792E63616C6C28652C72292626286E5B725D3D655B725D293B6966285B2278222C2279222C227831222C227931222C227832222C227932225D2E666F72456163682866756E6374696F6E2865297B64656C6574';
wwv_flow_imp.g_varchar2_table(209) := '65206E5B655D7D292C22696D6167656E223D3D3D6E2E747970652626286E2E5F6D6178573D74292C226772616669636F223D3D3D6E2E74797065297B766172206F3D6E2E77696474687C7C3132302C613D6E2E6865696768747C7C37303B6F3E74262628';
wwv_flow_imp.g_varchar2_table(210) := '6E2E77696474683D742C6E2E6865696768743D612A742F6F297D72657475726E22636F6469676F223D3D3D6E2E74797065262628227172223D3D3D537472696E67286E2E6B696E647C7C22717222292E746F4C6F7765724361736528292626286E2E7369';
wwv_flow_imp.g_varchar2_table(211) := '7A657C7C3330293E742626286E2E73697A653D74292C6E2E776964746826266E2E77696474683E742626286E2E77696474683D7429292C28226C696E6561223D3D3D6E2E747970657C7C22746578746F223D3D3D6E2E747970652926266E2E7769647468';
wwv_flow_imp.g_varchar2_table(212) := '26266E2E77696474683E742626286E2E77696474683D74292C6E7D28652C6F297D292C663D7B783A632C773A6F2C736563733A617D3B72657475726E20632B3D6F2B752C667D297D66756E6374696F6E20766528652C74297B72657475726E22616C6572';
wwv_flow_imp.g_varchar2_table(213) := '7461223D3D3D652E747970657C7C21652E7768656E7C7C5328652E7768656E2C742C6E756C6C297D66756E6374696F6E2077652865297B76617220742C723D7B7D3B666F72287420696E206E29725B745D3D6E5B745D3B766172206F3D652E7061676526';
wwv_flow_imp.g_varchar2_table(214) := '26652E706167652E7468656D657C7C7B7D3B666F72287420696E206F29725B745D3D6F5B745D3B72657475726E20727D7661722062653D7B7D2C79653D7B7D3B66756E6374696F6E2078652865297B76617220743D77696E646F772E6170657826266170';
wwv_flow_imp.g_varchar2_table(215) := '65782E656E767C7C7B7D3B72657475726E20537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C2222292E7265706C6163652822234150505F494D4147455323222C742E4150505F';
wwv_flow_imp.g_varchar2_table(216) := '46494C45537C7C2222292E7265706C616365282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C616365282223494D4147455F50524546495823222C742E415045585F46494C45537C';
wwv_flow_imp.g_varchar2_table(217) := '7C2222297D66756E6374696F6E2045652865297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B315D2972657475726E7B773A28745B31365D3C3C32347C745B31375D3C3C31367C74';
wwv_flow_imp.g_varchar2_table(218) := '5B31385D3C3C387C745B31395D293E3E3E302C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22706E67227D3B6966283235353D3D3D745B305D26263231363D3D3D745B315D2966';
wwv_flow_imp.g_varchar2_table(219) := '6F722876617220723D323B723C742E6C656E6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B335D3B6966286E3E3D31393226266E3C3D3230372626313936213D3D6E26263230';
wwv_flow_imp.g_varchar2_table(220) := '30213D3D6E2626323034213D3D6E2972657475726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A7067227D3B722B3D322B6F7D656C736520722B2B3B7468726F77206E657720457272';
wwv_flow_imp.g_varchar2_table(221) := '6F722822466F726D61746F20646520696D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E2054652865297B666F722876617220743D6E65772055696E743841727261792865292C723D22';
wwv_flow_imp.g_varchar2_table(222) := '222C6E3D303B6E3C742E6C656E6774683B6E2B3D333237363829722B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E7375626172726179286E2C6E2B333237363829293B72657475726E2062746F612872297D6675';
wwv_flow_imp.g_varchar2_table(223) := '6E6374696F6E20536528652C74297B696628652E6669656C64297B76617220723D2828652E736F757263653F4128652C74295B305D3A742E646F63297C7C7B7D295B537472696E6728652E6669656C64292E746F55707065724361736528295D3B747279';
wwv_flow_imp.g_varchar2_table(224) := '7B72657475726E20723F66756E6374696F6E2865297B76617220743D537472696E672865292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C2222293B69662821742972657475726E206E756C';
wwv_flow_imp.g_varchar2_table(225) := '6C3B76617220723D226236343A222B742E6C656E6774682B223A222B742E73756273747228302C3634292B742E737562737472282D3634293B69662862655B725D2972657475726E2062655B725D3B666F7228766172206E3D61746F622874292C6F3D6E';
wwv_flow_imp.g_varchar2_table(226) := '65772055696E74384172726179286E2E6C656E677468292C613D303B613C6E2E6C656E6774683B612B2B296F5B615D3D6E2E63686172436F646541742861293B76617220693D4565286F2E627566666572293B72657475726E2062655B725D3D7B627566';
wwv_flow_imp.g_varchar2_table(227) := '3A6F2E6275666665722C773A692E772C683A692E682C6578743A692E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D692E6578743F226A706567223A22706E6722292B223B6261736536342C222B747D2C62655B725D7D';
wwv_flow_imp.g_varchar2_table(228) := '2872293A6E756C6C7D63617463682874297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D6167656E20696E76C3A16C69646120656E20222B652E6669656C642C74292C';
wwv_flow_imp.g_varchar2_table(229) := '6E756C6C7D7D72657475726E2062655B786528652E75726C295D7C7C6E756C6C7D66756E6374696F6E20416528652C74297B76617220723D652E77696474687C7C34302C6E3D652E6865696768747C7C722A742E682F742E773B72657475726E21652E77';
wwv_flow_imp.g_varchar2_table(230) := '696474682626652E686569676874262628723D6E2A742E772F742E68292C652E5F6D6178572626723E652E5F6D6178572626286E3D6E2A652E5F6D6178572F722C723D652E5F6D617857292C7B773A722C683A6E7D7D66756E6374696F6E204365286529';
wwv_flow_imp.g_varchar2_table(231) := '7B666F722876617220743D61746F622865292C723D6E65772055696E7438417272617928742E6C656E677468292C6E3D303B6E3C742E6C656E6774683B6E2B2B29725B6E5D3D742E63686172436F64654174286E293B72657475726E20722E6275666665';
wwv_flow_imp.g_varchar2_table(232) := '727D66756E6374696F6E204E6528652C742C72297B72657475726E7B6275663A436528652E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C222229292C646174613A652C773A742C683A722C6578743A22706E67227D7D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(233) := '506528652C74297B69662822756E646566696E6564223D3D747970656F6620646F63756D656E747C7C21646F63756D656E742E637265617465456C656D656E74297468726F77206E6577204572726F722822536520726571756965726520756E206E6176';
wwv_flow_imp.g_varchar2_table(234) := '656761646F72202863616E7661732920706172612067656E65726172206772C3A16669636F732E22293B76617220723D646F63756D656E742E637265617465456C656D656E74282263616E76617322293B72657475726E20722E77696474683D652C722E';
wwv_flow_imp.g_varchar2_table(235) := '6865696768743D742C727D766172207A653D6E756C6C3B66756E6374696F6E206B652865297B72657475726E5B653E3E3E3234263235352C653E3E3E3136263235352C653E3E3E38263235352C32353526655D7D66756E6374696F6E204D6528652C7429';
wwv_flow_imp.g_varchar2_table(236) := '7B76617220723D5B652E63686172436F646541742830292C652E63686172436F646541742831292C652E63686172436F646541742832292C652E63686172436F646541742833295D2C6E3D6E65772055696E7438417272617928342B742E6C656E677468';
wwv_flow_imp.g_varchar2_table(237) := '293B6E2E73657428722C30292C6E2E73657428742C34293B766172206F3D6E65772055696E743841727261792831322B742E6C656E677468293B72657475726E206F2E736574286B6528742E6C656E677468292C30292C6F2E736574286E2C34292C6F2E';
wwv_flow_imp.g_varchar2_table(238) := '736574286B652866756E6374696F6E2865297B696628217A65297B7A653D5B5D3B666F722876617220743D303B743C3235363B742B2B297B666F722876617220723D742C6E3D303B6E3C383B6E2B2B29723D3126723F333938383239323338345E723E3E';
wwv_flow_imp.g_varchar2_table(239) := '3E313A723E3E3E313B7A655B745D3D723E3E3E307D7D666F7228766172206F3D343239343936373239352C613D303B613C652E6C656E6774683B612B2B296F3D7A655B32353526286F5E655B615D295D5E6F3E3E3E383B72657475726E28343239343936';
wwv_flow_imp.g_varchar2_table(240) := '373239355E6F293E3E3E307D286E29292C382B742E6C656E677468292C6F7D66756E6374696F6E20466528652C742C722C6E297B766172206F2C692C6C3D4D6174682E6365696C28652F38292B312C753D6E65772055696E74384172726179286C2A7429';
wwv_flow_imp.g_varchar2_table(241) := '3B666F7228693D303B693C743B692B2B29666F72286F3D303B6F3C653B6F2B2B2972286F2C6929262628755B692A6C2B312B286F3E3E33295D7C3D3132383E3E2837266F29293B76617220732C633D4D6174682E6365696C28752E6C656E6774682F3635';
wwv_flow_imp.g_varchar2_table(242) := '353335292C663D6E65772055696E7438417272617928322B752E6C656E6774682B352A632B34292C643D322C683D312C703D303B666F7228665B305D3D3132302C665B315D3D312C733D303B733C633B732B2B297B766172206D3D36353533352A732C67';
wwv_flow_imp.g_varchar2_table(243) := '3D4D6174682E6D696E2836353533352C752E6C656E6774682D6D293B665B642B2B5D3D733D3D3D632D313F313A302C665B642B2B5D3D32353526672C665B642B2B5D3D673E3E382C665B642B2B5D3D323535267E672C665B642B2B5D3D7E673E3E382632';
wwv_flow_imp.g_varchar2_table(244) := '35352C662E73657428752E7375626172726179286D2C6D2B67292C64292C642B3D677D666F7228733D303B733C752E6C656E6774683B732B2B29703D28702B28683D28682B755B735D2925363535323129292536353532313B662E736574286B65282870';
wwv_flow_imp.g_varchar2_table(245) := '3C3C31367C68293E3E3E30292C64293B76617220763D6E65772055696E74384172726179283133292C773D61286E7C7C222330303030303022293B762E736574286B652865292C30292C762E736574286B652874292C34292C765B385D3D312C765B395D';
wwv_flow_imp.g_varchar2_table(246) := '3D333B76617220623D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31332C31302C32362C31305D292C4D65282249484452222C76292C4D652822504C5445222C6E65772055696E74384172726179285B3235352C3235352C';
wwv_flow_imp.g_varchar2_table(247) := '3235352C775B305D2C775B315D2C775B325D5D29292C4D65282249444154222C66292C4D65282249454E44222C6E65772055696E74384172726179283029295D2C793D622E7265647563652866756E6374696F6E28652C74297B72657475726E20652B74';
wwv_flow_imp.g_varchar2_table(248) := '2E6C656E6774687D2C30292C783D6E65772055696E743841727261792879292C453D303B72657475726E20622E666F72456163682866756E6374696F6E2865297B782E73657428652C45292C452B3D652E6C656E6774687D292C7B6275663A782E627566';
wwv_flow_imp.g_varchar2_table(249) := '6665722C646174613A22646174613A696D6167652F706E673B6261736536342C222B546528782E627566666572292C773A652C683A742C6578743A22706E67227D7D766172204F653D223231323232322032323231323220323232323231203132313232';
wwv_flow_imp.g_varchar2_table(250) := '33203132313332322031333132323220313232323133203132323331322031333232313220323231323133203232313331322032333132313220313132323332203132323133322031323232333120313133323232203132333132322031323332323120';
wwv_flow_imp.g_varchar2_table(251) := '32323332313120323231313332203232313233312032313332313220323233313132203331323133312033313132323220333231313232203332313232312033313232313220333232313132203332323231312032313231323320323132333231203233';
wwv_flow_imp.g_varchar2_table(252) := '32313231203131313332332031333131323320313331333231203131323331332031333231313320313332333131203231313331332032333131313320323331333131203131323133332031313233333120313332313331203131333132332031313333';
wwv_flow_imp.g_varchar2_table(253) := '32312031333331323120333133313231203231313333312032333131333120323133313133203231333331312032313331333120333131313233203331313332312033333131323120333132313133203331323331312033333231313120333134313131';
wwv_flow_imp.g_varchar2_table(254) := '20323231343131203433313131312031313132323420313131343232203132313132342031323134323120313431313232203134313232312031313232313420313132343132203132323131342031323234313120313432313132203134323231312032';
wwv_flow_imp.g_varchar2_table(255) := '34313231312032323131313420343133313131203234313131322031333431313120313131323432203132313134322031323132343120313134323132203132343131322031323432313120343131323132203432313131322034323132313120323132';
wwv_flow_imp.g_varchar2_table(256) := '31343120323134313231203431323132312031313131343320313131333431203133313134312031313431313320313134333131203431313131332034313133313120313133313431203131343133312033313131343120343131313331203231313431';
wwv_flow_imp.g_varchar2_table(257) := '3220323131323134203231313233322032333331313132222E73706C697428222022293B66756E6374696F6E206A652865297B653D537472696E672865292E7265706C616365282F5B5E5C7832302D5C7837455D2F672C223F22293B666F722876617220';
wwv_flow_imp.g_varchar2_table(258) := '742C723D5B5D2C6E3D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B743D6E2E657865632865293B29696628745B315D7C7C2F5E5C642B242F2E746573742865292626652E6C656E67746825323D3D30297B766172206F3D745B';
wwv_flow_imp.g_varchar2_table(259) := '305D2C613D6F2E6C656E6774682D6F2E6C656E67746825323B722E70757368287B7365743A2243222C743A6F2E73756273747228302C61297D292C613C6F2E6C656E6774682626722E70757368287B7365743A2242222C743A6F2E737562737472286129';
wwv_flow_imp.g_varchar2_table(260) := '7D297D656C736520722E70757368287B7365743A2242222C743A745B305D7D293B76617220693D5B5D2C6C3D6E756C6C3B722E666F72456163682866756E6374696F6E2865297B6966286E756C6C3D3D3D6C3F692E70757368282243223D3D3D652E7365';
wwv_flow_imp.g_varchar2_table(261) := '743F3130353A313034293A6C213D3D652E7365742626692E70757368282243223D3D3D652E7365743F39393A313030292C6C3D652E7365742C2243223D3D3D652E73657429666F722876617220743D303B743C652E742E6C656E6774683B742B3D322969';
wwv_flow_imp.g_varchar2_table(262) := '2E70757368282B652E742E73756273747228742C3229293B656C736520666F722876617220723D303B723C652E742E6C656E6774683B722B2B29692E7075736828652E742E63686172436F646541742872292D3332297D293B666F722876617220753D69';
wwv_flow_imp.g_varchar2_table(263) := '5B305D2C733D313B733C692E6C656E6774683B732B2B29752B3D732A695B735D3B692E707573682875253130332C313036293B76617220633D5B5D3B72657475726E20692E666F72456163682866756E6374696F6E2865297B4F655B655D2E73706C6974';
wwv_flow_imp.g_varchar2_table(264) := '282222292E666F72456163682866756E6374696F6E28652C74297B666F722876617220723D303B723C2B653B722B2B29632E70757368287425323D3D30297D297D292C637D66756E6374696F6E20496528652C74297B76617220723D652E736F75726365';
wwv_flow_imp.g_varchar2_table(265) := '3F4128652C74295B305D3A6E756C6C3B696628652E736F75726365262621722972657475726E206E756C6C3B766172206E3D4528652E76616C75652C742C72293B696628216E2972657475726E206E756C6C3B766172206F3D537472696E6728652E6B69';
wwv_flow_imp.g_varchar2_table(266) := '6E647C7C22717222292E746F4C6F7765724361736528292C613D652E636F6C6F727C7C2223303030303030223B696628227172223D3D3D6F297B76617220693D66756E6374696F6E28652C74297B76617220723D77696E646F772E7172636F64653B6966';
wwv_flow_imp.g_varchar2_table(267) := '282172297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD612064652063C3B36469676F732051522E22293B722E737472696E67546F427974657346756E63732626722E737472696E67546F427974';
wwv_flow_imp.g_varchar2_table(268) := '657346756E63735B225554462D38225D262628722E737472696E67546F42797465733D722E737472696E67546F427974657346756E63735B225554462D38225D293B766172206E3D7228302C537472696E6728747C7C224D22292E746F55707065724361';
wwv_flow_imp.g_varchar2_table(269) := '73652829293B72657475726E206E2E6164644461746128537472696E67286529292C6E2E6D616B6528292C7B6E3A6E2E6765744D6F64756C65436F756E7428292C6461726B3A66756E6374696F6E28652C74297B72657475726E206E2E69734461726B28';
wwv_flow_imp.g_varchar2_table(270) := '742C65297D7D7D286E2C652E656363292C6C3D652E73697A657C7C33303B72657475726E7B6B696E643A227172222C746578743A6E2C636F6C733A692E6E2C726F77733A692E6E2C6461726B3A692E6461726B2C773A6C2C683A6C2C636F6C6F723A612C';
wwv_flow_imp.g_varchar2_table(271) := '71756965743A327D7D69662822636F6465313238223D3D3D6F297B76617220753D6A65286E292C733D652E77696474687C7C4D6174682E6D696E2839302C2E33332A752E6C656E677468293B72657475726E7B6B696E643A22626172222C746578743A6E';
wwv_flow_imp.g_varchar2_table(272) := '2C636F6C733A752E6C656E6774682C726F77733A312C6461726B3A66756E6374696F6E2865297B72657475726E20755B655D7D2C773A732C683A652E6865696768747C7C31322C636F6C6F723A612C71756965743A382C6C6162656C3A2131213D3D652E';
wwv_flow_imp.g_varchar2_table(273) := '73686F77546578742C7465787453697A653A652E7465787453697A657C7C387D7D7468726F77206E6577204572726F7228225469706F2064652063C3B36469676F206E6F20736F706F727461646F3A20222B6F2B222028757365207172206F20636F6465';
wwv_flow_imp.g_varchar2_table(274) := '313238292E22297D66756E6374696F6E2052652865297B76617220743D652E71756965742C723D227172223D3D3D652E6B696E643F383A332C6E3D28652E636F6C732B322A74292A722C6F3D4665286E2C227172223D3D3D652E6B696E643F6E3A4D6174';
wwv_flow_imp.g_varchar2_table(275) := '682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E636F6C732A7229292C66756E6374696F6E286E2C6F297B76617220613D4D6174682E666C6F6F72286E2F72292D742C693D227172223D3D3D652E6B696E643F4D6174682E666C6F';
wwv_flow_imp.g_varchar2_table(276) := '6F72286F2F72292D743A303B72657475726E20613E3D302626693E3D302626613C652E636F6C732626693C652E726F77732626652E6461726B28612C69297D2C652E636F6C6F72293B72657475726E206F2E776D6D3D652E772A28652E636F6C732B322A';
wwv_flow_imp.g_varchar2_table(277) := '74292F652E636F6C732C6F2E686D6D3D227172223D3D3D652E6B696E643F6F2E776D6D3A652E682C6F7D766172204C653D5B2223314634453739222C2223453037423339222C2223324538423537222C2223433033393242222C2223374433433938222C';
wwv_flow_imp.g_varchar2_table(278) := '2223313641303835222C2223443441433044222C2223354436443745222C2223413034303030222C2223323837344136225D3B66756E6374696F6E20446528652C742C72297B766172206E3D77696E646F772E43686172743B696628216E297468726F77';
wwv_flow_imp.g_varchar2_table(279) := '206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD61206465206772C3A16669636F73202843686172742E6A73292E22293B766172206F3D4128652C74293B696628216F2E6C656E6774682972657475726E206E75';
wwv_flow_imp.g_varchar2_table(280) := '6C6C3B76617220693D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6C3D742E545B695D7C7C7B7D2C753D4F626A6563742E6B657973286C292C733D652E63617465676F72793F537472696E6728652E63617465';
wwv_flow_imp.g_varchar2_table(281) := '676F7279292E746F55707065724361736528293A752E66696C7465722866756E6374696F6E2865297B72657475726E224E554D42455222213D3D6C5B655D262622444F435F4B455922213D3D657D295B305D7C7C755B305D2C633D28652E736572696573';
wwv_flow_imp.g_varchar2_table(282) := '2626652E7365726965732E6C656E6774683F652E7365726965733A752E66696C7465722866756E6374696F6E2865297B72657475726E224E554D424552223D3D3D6C5B655D262665213D3D73262622444F435F4B455922213D3D657D29292E6D61702866';
wwv_flow_imp.g_varchar2_table(283) := '756E6374696F6E2865297B72657475726E20653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A652C7B636F6C3A537472696E6728652E636F6C292E746F55707065724361736528292C6C6162656C3A766F69642030213D3D652E6C';
wwv_flow_imp.g_varchar2_table(284) := '6162656C3F652E6C6162656C3A6628652E636F6C292C636F6C6F723A652E636F6C6F727D7D292C643D652E63686172747C7C22626172222C683D22706965223D3D3D647C7C22646F7567686E7574223D3D3D642C6D3D31312E33343B68262628633D632E';
wwv_flow_imp.g_varchar2_table(285) := '736C69636528302C3129293B76617220673D652E77696474687C7C3132302C763D652E6865696768747C7C37302C773D5065284D6174682E726F756E6428672A6D292C4D6174682E726F756E6428762A6D29292C623D66756E6374696F6E2865297B7265';
wwv_flow_imp.g_varchar2_table(286) := '7475726E2E333532382A652A6D7D2C793D652E73697A657C7C382C783D2248656C7665746963612C20417269616C2C2073616E732D7365726966222C543D7B66616D696C793A782C73697A653A622879297D2C533D652E636F6C6F72732626652E636F6C';
wwv_flow_imp.g_varchar2_table(287) := '6F72732E6C656E6774683F652E636F6C6F72733A5B722E7072696D6172795D2E636F6E636174284C652E736C696365283129292C433D66756E6374696F6E2874297B72657475726E207028742C652E666D747C7C284D6174682E726F756E642874293D3D';
wwv_flow_imp.g_varchar2_table(288) := '3D743F22696E74223A226E756D3A322229297D2C4E3D6F2E6D61702866756E6374696F6E2874297B76617220723D745B735D3B72657475726E206E756C6C3D3D723F22223A652E63617465676F7279466D743F7028722C652E63617465676F7279466D74';
wwv_flow_imp.g_varchar2_table(289) := '293A537472696E672872297D292C503D632E6D61702866756E6374696F6E28722C6E297B76617220693D722E636F6C6F727C7C535B6E25532E6C656E6774685D2C6C3D7B6C6162656C3A4528722E6C6162656C2C74292C646174613A6F2E6D6170286675';
wwv_flow_imp.g_varchar2_table(290) := '6E6374696F6E2865297B76617220743D655B722E636F6C5D3B72657475726E206E756C6C3D3D747C7C22223D3D3D743F6E756C6C3A4E756D6265722874297D297D3B72657475726E20683F286C2E6261636B67726F756E64436F6C6F723D6F2E6D617028';
wwv_flow_imp.g_varchar2_table(291) := '66756E6374696F6E28652C74297B72657475726E20535B7425532E6C656E6774685D7D292C6C2E626F72646572436F6C6F723D2223464646464646222C6C2E626F7264657257696474683D62282E3829293A226C696E65223D3D3D647C7C226172656122';
wwv_flow_imp.g_varchar2_table(292) := '3D3D3D643F286C2E626F72646572436F6C6F723D692C6C2E6261636B67726F756E64436F6C6F723D2261726561223D3D3D643F66756E6374696F6E28652C74297B76617220723D612865293B72657475726E227267626128222B725B305D2B222C222B72';
wwv_flow_imp.g_varchar2_table(293) := '5B315D2B222C222B725B325D2B222C222B742B2229227D28692C2E3235293A692C6C2E66696C6C3D2261726561223D3D3D642C6C2E626F7264657257696474683D6228312E34292C6C2E706F696E745261646975733D6228312E35292C6C2E706F696E74';
wwv_flow_imp.g_varchar2_table(294) := '4261636B67726F756E64436F6C6F723D692C6C2E74656E73696F6E3D652E736D6F6F74683F2E33353A30293A286C2E6261636B67726F756E64436F6C6F723D692C6C2E626F7264657257696474683D30292C6C7D292C7A3D7B666F6E743A542C636F6C6F';
wwv_flow_imp.g_varchar2_table(295) := '723A2223343434343434227D2C6B3D7B7D3B6966282168297B766172204D3D7B626567696E41745A65726F3A2131213D3D652E626567696E41745A65726F2C737461636B65643A2121652E737461636B65642C67726163653A652E76616C7565733F2268';
wwv_flow_imp.g_varchar2_table(296) := '626172223D3D3D643F22323525223A22313225223A302C677269643A7B636F6C6F723A2223453345374543222C6C696E6557696474683A62282E34297D2C626F726465723A7B646973706C61793A21317D2C7469636B733A7B666F6E743A542C636F6C6F';
wwv_flow_imp.g_varchar2_table(297) := '723A2223343434343434222C63616C6C6261636B3A66756E6374696F6E2865297B72657475726E20432865297D7D7D2C463D7B737461636B65643A2121652E737461636B65642C677269643A7B646973706C61793A21317D2C7469636B733A7A7D3B6B3D';
wwv_flow_imp.g_varchar2_table(298) := '2268626172223D3D3D643F7B783A4D2C793A467D3A7B783A462C793A4D7D7D766172204F3D766F69642030213D3D652E6C6567656E643F2121652E6C6567656E643A687C7C632E6C656E6774683E312C6A3D6E6577206E28772E676574436F6E74657874';
wwv_flow_imp.g_varchar2_table(299) := '2822326422292C7B747970653A683F643A2268626172223D3D3D643F22626172223A2261726561223D3D3D643F226C696E65223A642C646174613A7B6C6162656C733A4E2C64617461736574733A507D2C706C6174666F726D3A6E2E4261736963506C61';
wwv_flow_imp.g_varchar2_table(300) := '74666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C616E696D6174696F6E3A21312C646576696365506978656C526174696F3A312C696E646578417869733A2268626172223D3D3D643F2279223A2278222C6C61796F75743A7B7061';
wwv_flow_imp.g_varchar2_table(301) := '6464696E673A622834297D2C7363616C65733A6B2C706C7567696E733A7B6C6567656E643A7B646973706C61793A4F2C706F736974696F6E3A652E6C6567656E64506F736974696F6E7C7C28683F227269676874223A22626F74746F6D22292C6C616265';
wwv_flow_imp.g_varchar2_table(302) := '6C733A7B666F6E743A542C636F6C6F723A2223333333333333222C626F7857696474683A622837292C626F784865696768743A622837297D7D2C7469746C653A7B646973706C61793A2121652E7469746C652C746578743A4528652E7469746C652C7429';
wwv_flow_imp.g_varchar2_table(303) := '2C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C793A782C73697A653A6228792B32292C7765696768743A22626F6C64227D2C70616464696E673A7B626F74746F6D3A622834297D7D2C746F6F6C7469703A7B656E61626C65643A21';
wwv_flow_imp.g_varchar2_table(304) := '317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C6265666F7265447261773A66756E6374696F6E2865297B76617220743D652E6374783B742E7361766528292C742E66696C6C5374796C653D2223464646464646222C742E66696C6C';
wwv_flow_imp.g_varchar2_table(305) := '5265637428302C302C652E77696474682C652E686569676874292C742E726573746F726528297D7D2C7B69643A226E7256616C6F726573222C61667465724461746173657473447261773A66756E6374696F6E2874297B696628652E76616C756573297B';
wwv_flow_imp.g_varchar2_table(306) := '76617220723D742E6374783B722E7361766528292C722E666F6E743D22626F6C6420222B6228792D2E35292B22707820222B782C742E646174612E64617461736574732E666F72456163682866756E6374696F6E286E2C6F297B696628742E6973446174';
wwv_flow_imp.g_varchar2_table(307) := '6173657456697369626C65286F29297B76617220613D6E2E646174612E7265647563652866756E6374696F6E28652C74297B72657475726E20652B28747C7C30297D2C30293B742E676574446174617365744D657461286F292E646174612E666F724561';
wwv_flow_imp.g_varchar2_table(308) := '63682866756E6374696F6E28742C6F297B76617220693D6E2E646174615B6F5D3B6966286E756C6C213D69297B766172206C3D22706374223D3D3D652E76616C7565733F7028613F3130302A692F613A302C226E756D3A3122292B2225223A432869293B';
wwv_flow_imp.g_varchar2_table(309) := '69662868297B76617220753D742E746F6F6C746970506F736974696F6E28293B722E66696C6C5374796C653D2223464646464646222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D226D6964646C65222C72';
wwv_flow_imp.g_varchar2_table(310) := '2E66696C6C54657874286C2C752E782C752E79297D656C73652268626172223D3D3D643F28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D226C656674222C722E74657874426173656C696E653D226D6964646C65';
wwv_flow_imp.g_varchar2_table(311) := '222C722E66696C6C54657874286C2C742E782B6228312E35292C742E7929293A28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D2263656E746572222C722E74657874426173656C696E653D22626F74746F6D222C';
wwv_flow_imp.g_varchar2_table(312) := '722E66696C6C54657874286C2C742E782C742E792D6228312E352929297D7D297D7D292C722E726573746F726528297D7D7D5D7D292C493D772E746F4461746155524C2822696D6167652F706E6722293B6A2E64657374726F7928293B76617220523D4E';
wwv_flow_imp.g_varchar2_table(313) := '6528492C772E77696474682C772E686569676874293B72657475726E20522E776D6D3D672C522E686D6D3D762C527D66756E6374696F6E20556528652C74297B76617220723D652E77617465726D61726B3B69662821727C7C226F626A656374223D3D74';
wwv_flow_imp.g_varchar2_table(314) := '7970656F6620722626215328722E7768656E2C742C742E646F63292972657475726E206E756C6C3B22737472696E67223D3D747970656F662072262628723D7B746578743A727D293B766172206E3D4528722E746578742C742C742E646F63293B726574';
wwv_flow_imp.g_varchar2_table(315) := '75726E206E3F7B746578743A6E2C636F6C6F723A722E636F6C6F727C7C2223433030303030222C6F7061636974793A766F69642030213D3D722E6F7061636974793F722E6F7061636974793A2E31322C616E676C653A766F69642030213D3D722E616E67';
wwv_flow_imp.g_varchar2_table(316) := '6C653F722E616E676C653A34352C73697A653A722E73697A657D3A6E756C6C7D66756E6374696F6E20426528652C742C722C6E297B696628652E73697A652972657475726E20652E73697A653B766172206F3D652E616E676C65253138303D3D303F2E38';
wwv_flow_imp.g_varchar2_table(317) := '2A723A2E362A4D6174682E7371727428722A722B6E2A6E293B72657475726E204D6174682E6D61782832302C4D6174682E6D696E283136302C3130302A6F2F7429297D66756E6374696F6E205F6528652C742C72297B766172206E3D652E706167657C7C';
wwv_flow_imp.g_varchar2_table(318) := '7B7D2C6F3D77652865292C693D6F2E666F6E7453697A652C6C3D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F';
wwv_flow_imp.g_varchar2_table(319) := '726D61743A6E2E73697A657C7C226C6574746572222C636F6D70726573733A216C652865297D292C753D6C2E696E7465726E616C2E7061676553697A652E676574576964746828292C733D6C2E696E7465726E616C2E7061676553697A652E6765744865';
wwv_flow_imp.g_varchar2_table(320) := '6967687428292C633D6E2E6D617267696E7C7C382C663D61286F2E7072696D617279292C643D61286F2E6865616454657874292C683D61286F2E7A65627261292C703D61286F2E746F74616C73292C6D3D632C673D21302C763D632C773D633B66756E63';
wwv_flow_imp.g_varchar2_table(321) := '74696F6E206228297B72657475726E206C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A6D7D66756E6374696F6E20792865297B6D3D6228292B28657C7C32297D66756E6374696F6E207828652C742C72';
wwv_flow_imp.g_varchar2_table(322) := '2C6E297B766172206F3D766F69642030213D3D652E783F652E783A227269676874223D3D3D652E616C69676E3F752D772D743A2263656E746572223D3D3D652E616C69676E3F762B28752D762D772D74292F323A763B766F696420303D3D3D652E793F28';
wwv_flow_imp.g_varchar2_table(323) := '286D3D4D6174682E6D6178286D2C62282929292B723E732D632D31302626286C2E6164645061676528292C6D3D63292C6E286F2C6D292C6D2B3D722B28766F69642030213D3D652E6761703F652E6761703A33292C6C2E6C6173744175746F5461626C65';
wwv_flow_imp.g_varchar2_table(324) := '3D7B66696E616C593A6D7D293A6E286F2C652E79297D76617220543D5B5D3B742E666F72456163682866756E6374696F6E284F2C49297B76617220523D742E6C656E6774683E313F225F222B28492B31293A22223B677C7C6C2E6164645061676528292C';
wwv_flow_imp.g_varchar2_table(325) := '673D21312C6D3D632C6C2E6C6173744175746F5461626C653D6E756C6C3B766172204C3D7B6374783A4F2C66726F6D3A6C2E696E7465726E616C2E6765744E756D6265724F66506167657328297D3B542E70757368284C292C706528652C22706466222C';
wwv_flow_imp.g_varchar2_table(326) := '4F292E666F72456163682866756E6374696F6E20742867297B76617220543D672E747970653B69662822686561646572223D3D3D54297B76617220493D672E7375627469746C653F32303A31363B72657475726E206C2E73657446696C6C436F6C6F7228';
wwv_flow_imp.g_varchar2_table(327) := '665B305D2C665B315D2C665B325D292C6C2E7265637428302C302C752C492C224622292C6C2E73657454657874436F6C6F7228645B305D2C645B315D2C645B325D292C6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C6C2E73';
wwv_flow_imp.g_varchar2_table(328) := '6574466F6E7453697A6528672E73697A657C7C3134292C6C2E74657874284528672E7469746C652C4F292C632C31302E352C7B6D617857696474683A2E372A757D292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C';
wwv_flow_imp.g_varchar2_table(329) := '2E736574466F6E7453697A652839292C672E726967687426266C2E74657874284528672E72696768742C4F292C752D632C31302E352C7B616C69676E3A227269676874227D292C672E7375627469746C6526266C2E74657874284528672E737562746974';
wwv_flow_imp.g_varchar2_table(330) := '6C652C4F292C632C31362E35292C6C2E73657454657874436F6C6F7228302C302C30292C6D3D492B342C766F6964286C2E6C6173744175746F5461626C653D6E756C6C297D69662822746578746F223D3D3D54297B766172204C3D766F69642030213D3D';
wwv_flow_imp.g_varchar2_table(331) := '672E792C553D6D2C423D6C2E6C6173744175746F5461626C652C5F3D672E73697A657C7C31302C473D2E333532382A5F2A28672E6C696E654865696768747C7C312E3335292C583D28766F69642030213D3D672E783F672E783A76292B28672E696E6465';
wwv_flow_imp.g_varchar2_table(332) := '6E747C7C30292C513D672E77696474687C7C752D772D582C65653D672E616C69676E7C7C226C656674222C74653D6128672E636F6C6F727C7C222330303030303022292C6E653D66756E6374696F6E2865297B72657475726E28652E627C7C672E626F6C';
wwv_flow_imp.g_varchar2_table(333) := '6429262628652E697C7C672E6974616C6963293F22626F6C646974616C6963223A652E627C7C672E626F6C643F22626F6C64223A652E697C7C672E6974616C69633F226974616C6963223A226E6F726D616C227D2C61653D672E666F6E747C7C652E7061';
wwv_flow_imp.g_varchar2_table(334) := '67652626652E706167652E666F6E747C7C2268656C766574696361223B72657475726E206C2E736574466F6E7453697A65285F292C6C2E73657454657874436F6C6F722874655B305D2C74655B315D2C74655B325D292C6D3D4C3F672E793A4D6174682E';
wwv_flow_imp.g_varchar2_table(335) := '6D6178286D2C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A6D292C6B28672C4F292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B7A28652C7B666F6E743A61652C636F6C';
wwv_flow_imp.g_varchar2_table(336) := '6F723A672E636F6C6F727D292E666F72456163682866756E6374696F6E2865297B652E742E73706C6974282F28202B292F292E666F72456163682866756E6374696F6E2872297B2222213D3D722626742E70757368287B743A722C66616D3A505B652E66';
wwv_flow_imp.g_varchar2_table(337) := '5D5B305D2C663A6E652865292C73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E633F6128652E63293A74657D297D297D293B76617220723D5B5D2C6E3D5B5D2C6F3D303B666F7228742E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(338) := '6374696F6E2865297B76617220743D66756E6374696F6E2865297B6C2E736574466F6E7428652E66616D2C652E66293B666F722876617220743D302C723D652E66616D2B652E662B5F2C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B76617220';
wwv_flow_imp.g_varchar2_table(339) := '6F3D722B652E742E636861724174286E293B766F696420303D3D3D79655B6F5D26262879655B6F5D3D6C2E67657454657874576964746828652E742E636861724174286E2929292C742B3D79655B6F5D7D72657475726E20747D2865293B69662821652E';
wwv_flow_imp.g_varchar2_table(340) := '737026266F2B743E5126266E2E6C656E677468297B666F72283B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F7D292C6E3D5B5D2C6F3D307D652E737026';
wwv_flow_imp.g_varchar2_table(341) := '26216E2E6C656E6774687C7C28652E773D742C6E2E707573682865292C6F2B3D74297D293B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F2C6C6173743A';
wwv_flow_imp.g_varchar2_table(342) := '21307D292C652E7472696D28293F28722E666F72456163682866756E6374696F6E2865297B214C26266D2B473E732D632D31302626286C2E6164645061676528292C6D3D63293B76617220743D652E77732E66696C7465722866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(343) := '7B72657475726E20652E73707D292E6C656E6774682C723D226A757374696679223D3D3D6565262621652E6C6173742626743F28512D652E77292F743A302C6E3D227269676874223D3D3D65653F582B512D652E773A2263656E746572223D3D3D65653F';
wwv_flow_imp.g_varchar2_table(344) := '582B28512D652E77292F323A582C6F3D6D2B2E37352A473B652E77732E666F72456163682866756E6374696F6E2865297B76617220743D652E772B28652E73703F723A30293B6C2E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C65';
wwv_flow_imp.g_varchar2_table(345) := '2E635B325D292C6C2E73657444726177436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C6C2E7365744C696E655769647468282E3031322A5F292C652E73707C7C286C2E736574466F6E7428652E66616D2C652E66292C6C2E746578';
wwv_flow_imp.g_varchar2_table(346) := '7428652E742C6E2C6F29292C652E7526266C2E6C696E65286E2C6F2B2E30362A5F2C6E2B742C6F2B2E30362A5F292C652E7326266C2E6C696E65286E2C6F2D2E31312A5F2C6E2B742C6F2D2E31312A5F292C6E2B3D747D292C6D2B3D477D292C6D2B3D76';
wwv_flow_imp.g_varchar2_table(347) := '6F69642030213D3D672E7061726167726170684761703F672E7061726167726170684761703A2E352A47293A6D2B3D477D292C6C2E73657454657874436F6C6F7228302C302C30292C766F6964284C3F286D3D552C6C2E6C6173744175746F5461626C65';
wwv_flow_imp.g_varchar2_table(348) := '3D42293A6C2E6C6173744175746F5461626C653D7B66696E616C593A6D7D297D696628226C696E6561223D3D3D54297B7661722069653D6128672E636F6C6F727C7C222330303030303022293B6966286C2E73657444726177436F6C6F722869655B305D';
wwv_flow_imp.g_varchar2_table(349) := '2C69655B315D2C69655B325D292C6C2E7365744C696E65576964746828672E746869636B6E6573737C7C2E33292C766F69642030213D3D672E78312972657475726E20766F6964206C2E6C696E6528672E78312C672E79312C766F69642030213D3D672E';
wwv_flow_imp.g_varchar2_table(350) := '78323F672E78323A672E78312C766F69642030213D3D672E79323F672E79323A672E7931293B6D3D4D6174682E6D6178286D2C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A6D292B28672E67617042';
wwv_flow_imp.g_varchar2_table(351) := '65666F72657C7C30293B766172206C653D672E77696474687C7C752D762D772C75653D2263656E746572223D3D3D672E616C69676E3F762B28752D762D772D6C65292F323A227269676874223D3D3D672E616C69676E3F752D772D6C653A763B72657475';
wwv_flow_imp.g_varchar2_table(352) := '726E206C2E6C696E652875652C6D2C75652B6C652C6D292C6D2B3D766F69642030213D3D672E6761703F672E6761703A322C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A6D7D297D696628226573706163696F223D3D3D5429';
wwv_flow_imp.g_varchar2_table(353) := '72657475726E206D3D4D6174682E6D6178286D2C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A6D292B28672E6865696768747C7C36292C766F6964286C2E6C6173744175746F5461626C653D7B6669';
wwv_flow_imp.g_varchar2_table(354) := '6E616C593A6D7D293B69662822696D6167656E22213D3D5429696628226772616669636F22213D3D542969662822636F6469676F22213D3D54297B6966282273616C746F223D3D3D542972657475726E206C2E6164645061676528292C6D3D632C766F69';
wwv_flow_imp.g_varchar2_table(355) := '64286C2E6C6173744175746F5461626C653D7B66696E616C593A637D293B69662822636F6C756D6E6173223D3D3D54297B7661722073653D762C63653D773B696628212843653D676528672C22706466222C4F2C752D762D7729292E6C656E6774682972';
wwv_flow_imp.g_varchar2_table(356) := '657475726E3B7661722066653D66756E6374696F6E2865297B763D73652B652E782C773D752D2873652B652E782B652E77297D2C64653D6C2C68653D302C70653D21302C6D653D4D6174682E6D6178286D2C622829293B69662843652E666F7245616368';
wwv_flow_imp.g_varchar2_table(357) := '2866756E6374696F6E2865297B6C3D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A65';
wwv_flow_imp.g_varchar2_table(358) := '7C7C226C6574746572227D292C66652865292C6D3D632C6C2E6C6173744175746F5461626C653D6E756C6C2C652E736563732E666F72456163682874292C6C2E696E7465726E616C2E6765744E756D6265724F66506167657328293E3126262870653D21';
wwv_flow_imp.g_varchar2_table(359) := '31292C68653D4D6174682E6D61782868652C4D6174682E6D6178286D2C622829292D63297D292C763D73652C773D63652C6D3D6D652C286C3D6465292E6C6173744175746F5461626C653D7B66696E616C593A6D657D2C2170652972657475726E20766F';
wwv_flow_imp.g_varchar2_table(360) := '69642043652E666F72456163682866756E6374696F6E2865297B652E736563732E666F72456163682874297D293B6D2B68653E732D632D31302626286C2E6164645061676528292C6D3D63293B7661722076653D6D2C77653D6D3B72657475726E204365';
wwv_flow_imp.g_varchar2_table(361) := '2E666F72456163682866756E6374696F6E2865297B66652865292C6D3D76652C6C2E6C6173744175746F5461626C653D7B66696E616C593A76657D2C652E736563732E666F72456163682874292C77653D4D6174682E6D61782877652C6D2C622829297D';
wwv_flow_imp.g_varchar2_table(362) := '292C763D73652C773D63652C6D3D77652B28766F69642030213D3D672E6761703F672E6761703A31292C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A6D7D297D696628226669636861223D3D3D54297B7661722062653D4128';
wwv_flow_imp.g_varchar2_table(363) := '672C4F295B305D7C7C7B7D2C78653D672E636F6C756D6E737C7C332C45653D5B5D2C54653D5B5D2C43653D7B7D3B69662828672E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5328';
wwv_flow_imp.g_varchar2_table(364) := '652E7768656E2C4F2C6265297D292E666F72456163682866756E6374696F6E2865297B54652E70757368284528652E6C6162656C2C4F2C6265292C5A28652C4F2C626529292C54652E6C656E6774683D3D3D322A786526262845652E7075736828546529';
wwv_flow_imp.g_varchar2_table(365) := '2C54653D5B5D297D292C54652E6C656E677468297B666F72283B54652E6C656E6774683C322A78653B2954652E70757368282222293B45652E70757368285465297D666F7228766172204E653D303B4E653C322A78653B4E652B3D322943655B4E655D3D';
wwv_flow_imp.g_varchar2_table(366) := '7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A672E6C6162656C57696474687C7C33327D3B72657475726E206C2E6175746F5461626C65287B7374617274593A6D2C626F64793A45652C7468656D653A22706C61696E222C6D6172';
wwv_flow_imp.g_varchar2_table(367) := '67696E3A7B6C6566743A762C72696768743A777D2C7374796C65733A7B666F6E7453697A653A672E73697A657C7C382E352C63656C6C50616464696E673A2E397D2C636F6C756D6E5374796C65733A43657D292C766F696420792832297D69662822666F';
wwv_flow_imp.g_varchar2_table(368) := '726D756C6172696F223D3D3D54297B6C2E5F5F6E72466F726D7C7C286C2E5F5F6E72466F726D3D72652829293B7661722050653D6F6528672C4F2C52292C7A653D672E636F6C756D6E737C7C322C6B653D5B5D2C4D653D5B5D2C46653D7B7D2C4F653D7B';
wwv_flow_imp.g_varchar2_table(369) := '7D2C6A653D672E73697A657C7C382E353B69662850652E666F72456163682866756E6374696F6E2865297B6C2E5F5F6E72466F726D28652E6E616D65292C46655B6B652E6C656E6774682B223A222B284D652E6C656E6774682B31295D3D652C4D652E70';
wwv_flow_imp.g_varchar2_table(370) := '75736828652E6C6162656C2C2222292C4D652E6C656E6774683D3D3D322A7A652626286B652E70757368284D65292C4D653D5B5D297D292C4D652E6C656E677468297B666F72283B4D652E6C656E6774683C322A7A653B294D652E70757368282222293B';
wwv_flow_imp.g_varchar2_table(371) := '6B652E70757368284D65297D696628216B652E6C656E6774682972657475726E3B666F72287661722052653D303B52653C322A7A653B52652B3D32294F655B52655D3D7B666F6E745374796C653A22626F6C64222C63656C6C57696474683A672E6C6162';
wwv_flow_imp.g_varchar2_table(372) := '656C57696474687C7C33327D3B766172204C653D2E333532382A6A652A312E333B72657475726E206C2E6175746F5461626C65287B7374617274593A6D2C626F64793A6B652C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72';
wwv_flow_imp.g_varchar2_table(373) := '696768743A777D2C726F7750616765427265616B3A2261766F6964222C7374796C65733A7B666F6E7453697A653A6A652C63656C6C50616464696E673A312E322C76616C69676E3A226D6964646C65227D2C636F6C756D6E5374796C65733A4F652C6469';
wwv_flow_imp.g_varchar2_table(374) := '64506172736543656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E262646655B652E726F772E696E6465782B223A222B652E636F6C756D6E2E696E6465785D3B74262628652E63656C6C2E7374796C65';
wwv_flow_imp.g_varchar2_table(375) := '732E6D696E43656C6C4865696768743D742E6C696E65732A4C652B33297D2C6469644472617743656C6C3A66756E6374696F6E2865297B76617220743D22626F6479223D3D3D652E73656374696F6E262646655B652E726F772E696E6465782B223A222B';
wwv_flow_imp.g_varchar2_table(376) := '652E636F6C756D6E2E696E6465785D3B74262666756E6374696F6E28652C742C722C6E297B766172206F2C693D77696E646F772E6A737064662C6C3D722E782B2E362C753D722E792B2E362C733D722E77696474682D312E322C633D722E686569676874';
wwv_flow_imp.g_varchar2_table(377) := '2D312E322C663D61284A292C643D61284B293B69662822636865636B626F78223D3D3D742E696E707574297B76617220683D4D6174682E6D696E28632C342E35293B752B3D28632D68292F322C733D682C633D687D652E73657444726177436F6C6F7228';
wwv_flow_imp.g_varchar2_table(378) := '645B305D2C645B315D2C645B325D292C652E73657446696C6C436F6C6F7228665B305D2C665B315D2C665B325D292C652E7365744C696E655769647468282E32292C652E72656374286C2C752C732C632C22464422292C652E73657444726177436F6C6F';
wwv_flow_imp.g_varchar2_table(379) := '7228302C302C30292C22636865636B626F78223D3D3D742E696E7075743F28286F3D6E657720692E4163726F466F726D436865636B426F78292E617070656172616E636553746174653D742E636865636B65643F224F6E223A224F6666222C6F2E76616C';
wwv_flow_imp.g_varchar2_table(380) := '75653D742E636865636B65643F224F6E223A224F666622293A226C697374223D3D3D742E696E7075743F28286F3D6E657720692E4163726F466F726D436F6D626F426F78292E7365744F7074696F6E7328742E6F7074696F6E73292C6F2E656469743D21';
wwv_flow_imp.g_varchar2_table(381) := '312C742E76616C75652626286F2E76616C75653D742E76616C756529293A28286F3D6E657720692E4163726F466F726D546578744669656C64292E6D756C74696C696E653D226D756C74696C696E65223D3D3D742E696E7075742C742E6D61784C656E67';
wwv_flow_imp.g_varchar2_table(382) := '74682626286F2E6D61784C656E6774683D742E6D61784C656E677468292C742E76616C75652626286F2E76616C75653D742E76616C756529292C6F2E6669656C644E616D653D742E6E616D652C6F2E526563743D5B6C2C752C732C635D2C22636865636B';
wwv_flow_imp.g_varchar2_table(383) := '626F7822213D3D742E696E7075742626286F2E666F6E7453697A653D6E2C652E5F5F6E72466F726D53697A657C7C28652E5F5F6E72466F726D53697A653D6E29292C742E726561644F6E6C792626286F2E726561644F6E6C793D2130292C652E61646446';
wwv_flow_imp.g_varchar2_table(384) := '69656C64286F297D286C2C742C652E63656C6C2C6A65297D7D292C766F696420792832297D69662822616C6572746122213D3D54297B696628227461626C61223D3D3D54297B7661722055653D4128672C4F293B6966282155652E6C656E677468262621';
wwv_flow_imp.g_varchar2_table(385) := '31213D3D672E68696465456D707479262621672E656D707479546578742972657475726E3B7661722042653D4D28672C4F2C5565292C5F653D5B5D2C47653D7B7D3B696628672E7469746C6526265F652E70757368285B7B636F6E74656E743A4528672E';
wwv_flow_imp.g_varchar2_table(386) := '7469746C652C4F292C636F6C5370616E3A42652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E7453697A653A692B317D7D5D292C672E67726F757073297B7661722057653D5B5D2C48653D5B5D2C24653D7B68616C69';
wwv_flow_imp.g_varchar2_table(387) := '676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B4628672C4265292E666F72456163682866756E6374696F6E2865297B666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B29652E6761703F';
wwv_flow_imp.g_varchar2_table(388) := '57652E70757368287B636F6E74656E743A42655B745D2E6C6162656C2C726F775370616E3A322C7374796C65733A24657D293A48652E707573682842655B745D2E6C6162656C293B652E6761707C7C57652E70757368287B636F6E74656E743A652E6C61';
wwv_flow_imp.g_varchar2_table(389) := '62656C2C636F6C5370616E3A652E636F6C732C7374796C65733A24657D297D292C5F652E707573682857652C4865297D656C7365205F652E707573682842652E6D61702866756E6374696F6E2865297B72657475726E20652E6C6162656C7D29293B4265';
wwv_flow_imp.g_varchar2_table(390) := '2E666F72456163682866756E6374696F6E28652C74297B47655B745D3D7B68616C69676E3A652E616C69676E7D2C652E636F6C6F7226262847655B745D2E74657874436F6C6F723D6128652E636F6C6F7229292C652E626F6C6426262847655B745D2E66';
wwv_flow_imp.g_varchar2_table(391) := '6F6E745374796C653D22626F6C6422292C652E776964746826262847655B745D2E63656C6C57696474683D652E7769647468297D293B7661722056653D7128672C5565292C71653D562867292C59653D61286F2E67726F7570292C5A653D5B5D3B45653D';
wwv_flow_imp.g_varchar2_table(392) := '55652E6C656E6774683F5B5D3A5B5B7B636F6E74656E743A4528672E656D707479546578742C4F292C636F6C5370616E3A42652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A226974616C6963227D';
wwv_flow_imp.g_varchar2_table(393) := '7D5D5D3B55652E6C656E677468262656652E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B2972657475726E2045652E70757368285B7B636F6E74656E743A5928672C652C4F292C636F6C5370616E3A42652E6C';
wwv_flow_imp.g_varchar2_table(394) := '656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A59657D7D5D292C766F6964205A652E707573682865293B2273756222213D3D652E6B3F2845652E707573682842';
wwv_flow_imp.g_varchar2_table(395) := '652E6D61702866756E6374696F6E2874297B72657475726E206A28742C652E722C4F297D29292C5A652E70757368286529293A2428572842652C71652C652E726F77732C5928672C652C4F29292C42652E6C656E677468292E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(396) := '6374696F6E2874297B45652E707573682874292C5A652E707573682865297D297D293B7661722058653D6E756C6C2C4A653D4428672E746F74616C73293B4A652E6C656E677468262655652E6C656E67746826262858653D2428572842652C4A652C5565';
wwv_flow_imp.g_varchar2_table(397) := '2C4828672C4F2C556529292C42652E6C656E67746829292C6C2E6175746F5461626C65287B7374617274593A6D2C6D617267696E3A7B6C6566743A762C72696768743A777D2C686561643A5F652C626F64793A45652C666F6F743A58657C7C766F696420';
wwv_flow_imp.g_varchar2_table(398) := '302C73686F77486561643A21313D3D3D672E7265706561744865616465723F22666972737450616765223A22657665727950616765222C73686F77466F6F743A226C61737450616765222C7374796C65733A7B666F6E7453697A653A672E73697A657C7C';
wwv_flow_imp.g_varchar2_table(399) := '692C63656C6C50616464696E673A2E387D2C686561645374796C65733A7B66696C6C436F6C6F723A662C74657874436F6C6F723A642C68616C69676E3A2263656E746572222C666F6E7453697A653A672E73697A657C7C697D2C666F6F745374796C6573';
wwv_flow_imp.g_varchar2_table(400) := '3A7B66696C6C436F6C6F723A702C74657874436F6C6F723A302C666F6E745374796C653A22626F6C64222C68616C69676E3A227269676874227D2C616C7465726E617465526F775374796C65733A672E627265616B42793F7B7D3A7B66696C6C436F6C6F';
wwv_flow_imp.g_varchar2_table(401) := '723A687D2C636F6C756D6E5374796C65733A47652C646964506172736543656C6C3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F6E262655652E6C656E677468297B76617220743D5A655B652E726F772E696E646578';
wwv_flow_imp.g_varchar2_table(402) := '5D3B696628742626226865616422213D3D742E6B297B69662822737562223D3D3D742E6B2972657475726E20652E63656C6C2E7374796C65732E66696C6C436F6C6F723D702C766F696428652E63656C6C2E7374796C65732E666F6E745374796C653D22';
wwv_flow_imp.g_varchar2_table(403) := '626F6C6422293B766172206E3D742E722C6F3D42655B652E636F6C756D6E2E696E6465785D3B672E627265616B4279262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D742E6925323D3D3126262131213D3D672E7A656272613F683A5B';
wwv_flow_imp.g_varchar2_table(404) := '3235352C3235352C3235355D293B76617220693D4E28672E726F775374796C652C4F2C6E293B69262628692E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D6128692E66696C6C29292C692E636F6C6F72262628652E6365';
wwv_flow_imp.g_varchar2_table(405) := '6C6C2E7374796C65732E74657874436F6C6F723D6128692E636F6C6F7229292C692E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B766172206C3D6F26264E286F2E63656C6C5374796C652C4F2C6E';
wwv_flow_imp.g_varchar2_table(406) := '293B6C2626286C2E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D61286C2E66696C6C29292C6C2E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D61286C2E636F6C6F7229292C6C2E626F';
wwv_flow_imp.g_varchar2_table(407) := '6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229292C722626722E70646643656C6C2626722E70646643656C6C28652C6E2C6F2C672C4F297D7D7D7D292C7928672E6761707C7C33297D7D656C7365204128672C';
wwv_flow_imp.g_varchar2_table(408) := '4F292E66696C7465722866756E6374696F6E2865297B72657475726E205328672E7768656E2C4F2C65297D292E736C69636528302C672E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B6C2E6175746F5461626C65287B';
wwv_flow_imp.g_varchar2_table(409) := '7374617274593A6D2C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A777D2C626F64793A5B5B4528672E746578742C4F2C65295D5D2C7374796C65733A7B666F6E7453697A653A672E73697A657C7C382C666F6E';
wwv_flow_imp.g_varchar2_table(410) := '745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A61284328672E636F6C6F722C4F2C65297C7C222345364543463222297D7D292C792831297D297D656C73657B766172204B653D496528672C4F293B69';
wwv_flow_imp.g_varchar2_table(411) := '6628214B652972657475726E3B7661722051653D4B652E6C6162656C3F2E333532382A4B652E7465787453697A652A312E343A303B7828672C4B652E772C4B652E682B51652C66756E6374696F6E28652C74297B76617220723D4B652E772F4B652E636F';
wwv_flow_imp.g_varchar2_table(412) := '6C732C6E3D4B652E682F4B652E726F77732C6F3D61284B652E636F6C6F72293B6C2E73657446696C6C436F6C6F72286F5B305D2C6F5B315D2C6F5B325D293B666F722876617220693D303B693C4B652E726F77733B692B2B29666F722876617220753D30';
wwv_flow_imp.g_varchar2_table(413) := '3B753C4B652E636F6C733B752B2B296966284B652E6461726B28752C6929297B666F722876617220733D753B752B313C4B652E636F6C7326264B652E6461726B28752B312C69293B29752B2B3B6C2E7265637428652B732A722C742B692A6E2C28752D73';
wwv_flow_imp.g_varchar2_table(414) := '2B31292A722C6E2B28693C4B652E726F77732D313F2E30323A30292C224622297D4B652E6C6162656C2626286C2E736574466F6E742822636F7572696572222C226E6F726D616C22292C6C2E736574466F6E7453697A65284B652E7465787453697A6529';
wwv_flow_imp.g_varchar2_table(415) := '2C6C2E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C6C2E74657874284B652E746578742C652B4B652E772F322C742B4B652E682B2E333532382A4B652E7465787453697A652A312E312C7B616C69676E3A2263656E74657222';
wwv_flow_imp.g_varchar2_table(416) := '7D292C6C2E73657454657874436F6C6F7228302C302C3029297D297D656C73657B7661722065743D446528672C4F2C6F293B6966282165742972657475726E3B7828672C65742E776D6D2C65742E686D6D2C66756E6374696F6E28652C74297B6C2E6164';
wwv_flow_imp.g_varchar2_table(417) := '64496D6167652865742E646174612C22504E47222C652C742C65742E776D6D2C65742E686D6D2C766F696420302C224641535422297D297D656C73657B7661722074743D536528672C4F293B6966282174742972657475726E3B7661722072743D416528';
wwv_flow_imp.g_varchar2_table(418) := '672C7474292C6E743D226A7067223D3D3D74742E6578743F224A504547223A22504E47223B7828672C72742E772C72742E682C66756E6374696F6E28652C74297B6C2E616464496D6167652874742E646174612C6E742C652C742C72742E772C72742E68';
wwv_flow_imp.g_varchar2_table(419) := '297D297D7D292C4C2E746F3D6C2E696E7465726E616C2E6765744E756D6265724F66506167657328297D292C542E666F72456163682866756E6374696F6E2874297B76617220723D556528652C742E637478293B69662872297B6C2E736574466F6E7428';
wwv_flow_imp.g_varchar2_table(420) := '2268656C766574696361222C22626F6C6422292C6C2E736574466F6E7453697A6528313030293B766172206E3D426528722C6C2E67657454657874576964746828722E74657874292C752C73292C6F3D722E616E676C652A4D6174682E50492F3138302C';
wwv_flow_imp.g_varchar2_table(421) := '693D6128722E636F6C6F72293B6C2E736574466F6E7453697A65286E293B666F722876617220633D6C2E67657454657874576964746828722E74657874292C663D2E333532382A6E2A2E372C643D752F322D632F322A4D6174682E636F73286F292B662F';
wwv_flow_imp.g_varchar2_table(422) := '322A4D6174682E73696E286F292C683D732F322B632F322A4D6174682E73696E286F292B662F322A4D6174682E636F73286F292C703D742E66726F6D3B703C3D742E746F3B702B2B296C2E736574506167652870292C6C2E736176654772617068696373';
wwv_flow_imp.g_varchar2_table(423) := '537461746528292C6C2E736574475374617465286E6577206C2E475374617465287B6F7061636974793A722E6F7061636974797D29292C6C2E73657454657874436F6C6F7228695B305D2C695B315D2C695B325D292C6C2E7465787428722E746578742C';
wwv_flow_imp.g_varchar2_table(424) := '642C682C7B616E676C653A722E616E676C657D292C6C2E726573746F72654772617068696373537461746528293B6C2E73657454657874436F6C6F7228302C302C30297D7D293B766172204F3D652E666F6F7465722C493D6C2E696E7465726E616C2E67';
wwv_flow_imp.g_varchar2_table(425) := '65744E756D6265724F66506167657328292C523D745B305D7C7C7B533A7B7D2C543A7B7D7D3B6966284F297B666F7228766172204C3D313B4C3C3D493B4C2B2B297B6C2E73657450616765284C292C6C2E736574466F6E74282268656C76657469636122';
wwv_flow_imp.g_varchar2_table(426) := '2C226E6F726D616C22292C6C2E736574466F6E7453697A65284F2E73697A657C7C37293B76617220553D61286F2E6D75746564293B6C2E73657454657874436F6C6F7228555B305D2C555B315D2C555B325D293B76617220423D66756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(427) := '297B72657475726E204528652C52292E7265706C61636528227B504147457D222C4C292E7265706C61636528227B50414745537D222C49297D3B6966284F2E6C656674297B766172205F3D6C2E73706C697454657874546F53697A652842284F2E6C6566';
wwv_flow_imp.g_varchar2_table(428) := '74292C2E37382A75293B6C2E74657874285F2C632C732D342D285F2E6C656E6774682D31292A284F2E73697A657C7C37292A2E34297D4F2E726967687426266C2E746578742842284F2E7269676874292C752D632C732D352C7B616C69676E3A22726967';
wwv_flow_imp.g_varchar2_table(429) := '6874227D297D6C2E73657454657874436F6C6F7228302C302C30297D72657475726E20652E7469746C6526266C2E73657450726F70657274696573287B7469746C653A4528652E7469746C652C52297D292C66756E6374696F6E2865297B76617220743D';
wwv_flow_imp.g_varchar2_table(430) := '652E696E7465726E616C2E6163726F666F726D506C7567696E2C723D742626742E6163726F466F726D44696374696F6E617279526F6F743B696628722626722E4669656C64732626722E4669656C64732E6C656E677468262621722E5F5F6E72297B7661';
wwv_flow_imp.g_varchar2_table(431) := '72206E3D223C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F48656C766574696361202F456E636F64696E67202F57696E416E7369456E636F64696E67203E3E222C6F3D652E696E7465726E616C';
wwv_flow_imp.g_varchar2_table(432) := '2E676574466F6E74282268656C766574696361222C226E6F726D616C22292E69643B722E44413D222F48656C7620222B28652E5F5F6E72466F726D53697A657C7C39292B2220546620302067222C4F626A6563742E646566696E6550726F706572747928';
wwv_flow_imp.g_varchar2_table(433) := '722C224452222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A223C3C202F466F6E74203C3C202F48656C7620222B6E2B286F26262248656C7622213D3D6F3F22202F222B6F2B2220222B6E3A2222292B22';
wwv_flow_imp.g_varchar2_table(434) := '202F5A614462203C3C202F54797065202F466F6E74202F53756274797065202F5479706531202F42617365466F6E74202F5A61706644696E6762617473203E3E203E3E203E3E227D292C4F626A6563742E646566696E6550726F706572747928722C224E';
wwv_flow_imp.g_varchar2_table(435) := '656564417070656172616E636573222C7B656E756D657261626C653A21302C636F6E666967757261626C653A21312C76616C75653A2274727565227D292C722E5F5F6E723D21307D7D286C292C50726F6D6973652E7265736F6C7665286C2E6F75747075';
wwv_flow_imp.g_varchar2_table(436) := '74282261727261796275666665722229297D66756E6374696F6E2047652865297B72657475726E20537472696E6728652E6C6162656C7C7C652E6E616D65292E7265706C616365282F5C732B2F672C222022292E73756273747228302C3332297D66756E';
wwv_flow_imp.g_varchar2_table(437) := '6374696F6E20576528652C742C722C6E297B76617220613D6E65772077696E646F772E457863656C4A532E576F726B626F6F6B2C6C3D77652865292C753D7B7D2C733D616528652C6E292C633D726528292C663D5B5D2C673D7B77733A6E756C6C2C6E3A';
wwv_flow_imp.g_varchar2_table(438) := '302C7265663A7B7D7D3B612E63726561746F723D226E6F76615265706F7274223B76617220763D652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C73782E73686565744E616D657C7C225265706F';
wwv_flow_imp.g_varchar2_table(439) := '727465227D5D2C773D706528652C22786C737822292C623D652E706167657C7C7B7D2C793D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A69286C2E7072696D617279297D7D3B6675';
wwv_flow_imp.g_varchar2_table(440) := '6E6374696F6E20542865297B666F722876617220743D682865292E7265706C616365282F5B5C5B5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C723D742C6E3D323B755B722E746F4C6F7765724361736528295D3B29723D';
wwv_flow_imp.g_varchar2_table(441) := '742E73756273747228302C33312D537472696E67286E292E6C656E6774682D31292B225F222B6E2C6E2B2B3B72657475726E20755B722E746F4C6F7765724361736528295D3D21302C727D66756E6374696F6E206A2865297B72657475726E7B74797065';
wwv_flow_imp.g_varchar2_table(442) := '3A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A692865297D7D7D66756E6374696F6E20242865297B76617220743D652E6A6F696E28222C22293B696628742E6C656E6774683C3D3235302626212F';
wwv_flow_imp.g_varchar2_table(443) := '5B2C225D2F2E7465737428652E6A6F696E28222229292972657475726E2722272B742B2722273B696628672E7265665B745D2972657475726E20672E7265665B745D3B672E77737C7C28672E77733D612E616464576F726B7368656574285428226E725F';
wwv_flow_imp.g_varchar2_table(444) := '6C697374617322292C7B73746174653A2268696464656E227D29293B76617220723D2B2B672E6E3B652E666F72456163682866756E6374696F6E28652C74297B672E77732E67657443656C6C28742B312C72292E76616C75653D657D293B766172206E3D';
wwv_flow_imp.g_varchar2_table(445) := '672E77732E676574436F6C756D6E2872292E6C65747465723B72657475726E20672E7265665B745D3D2227222B672E77732E6E616D652B22272124222B6E2B2224313A24222B6E2B2224222B652E6C656E6774682C672E7265665B745D7D72657475726E';
wwv_flow_imp.g_varchar2_table(446) := '20742E666F72456163682866756E6374696F6E28722C6E297B76617220753D742E6C656E6774683E313F225F222B286E2B31293A22223B762E666F72456163682866756E6374696F6E286E297B76617220683D45286E2E6E616D652C72293B7065262674';
wwv_flow_imp.g_varchar2_table(447) := '2E6C656E6774683E31262628683D45286E2E6D657267654E616D657C7C28762E6C656E6774683E313F227B444F432E444F435F4B45597D20222B6E2E6E616D653A227B444F432E444F435F4B45597D22292C7229293B76617220673D612E616464576F72';
wwv_flow_imp.g_varchar2_table(448) := '6B736865657428542868292C7B7061676553657475703A7B6F7269656E746174696F6E3A622E6F7269656E746174696F6E7C7C22706F727472616974222C706170657253697A653A226C6567616C223D3D3D622E73697A653F353A226134223D3D3D622E';
wwv_flow_imp.g_varchar2_table(449) := '73697A653F393A312C666974546F506167653A21302C666974546F57696474683A312C666974546F4865696768743A307D7D292C583D6E2E73656374696F6E733F6E2E73656374696F6E732E6D61702866756E6374696F6E2865297B72657475726E226E';
wwv_flow_imp.g_varchar2_table(450) := '756D626572223D3D747970656F6620653F775B655D3A772E66696C7465722866756E6374696F6E2874297B72657475726E20742E69643D3D3D657D295B305D7D292E66696C74657228426F6F6C65616E293A773B583D582E66696C7465722866756E6374';
wwv_flow_imp.g_varchar2_table(451) := '696F6E2865297B72657475726E20766528652C72297D293B7661722074653D342C72653D312C6E653D7B7D2C61653D302C69653D6E756C6C2C6C653D6E756C6C2C75653D21312C73653D66756E6374696F6E2865297B72657475726E20652E7265647563';
wwv_flow_imp.g_varchar2_table(452) := '652866756E6374696F6E28652C74297B72657475726E204D6174682E6D617828652C227461626C61223D3D3D742E747970653F4D28742C722C4128742C7229292E6C656E6774683A226669636861223D3D3D742E747970653F322A28742E636F6C756D6E';
wwv_flow_imp.g_varchar2_table(453) := '737C7C33293A22666F726D756C6172696F223D3D3D742E747970653F322A28742E636F6C756D6E737C7C32293A22746578746F223D3D3D742E747970657C7C22616C65727461223D3D3D742E747970653F343A32297D2C32297D3B66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(454) := '636528652C74297B76617220723D537472696E67286E756C6C3D3D743F22223A74292E6C656E6774683B6E655B652B3D66655D3D4D6174682E6D696E2836302C4D6174682E6D6178286E655B655D7C7C382C722B3229297D582E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(455) := '6E6374696F6E2865297B22636F6C756D6E6173223D3D3D652E7479706526262874653D4D6174682E6D61782874652C676528652C22786C7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B73652874';
wwv_flow_imp.g_varchar2_table(456) := '2E73656373292B317D2C2D312929292C227461626C61223D3D3D652E7479706526262861652B2B2C74653D4D6174682E6D61782874652C4D28652C722C4128652C7229292E6C656E67746829292C226669636861223D3D3D652E7479706526262874653D';
wwv_flow_imp.g_varchar2_table(457) := '4D6174682E6D61782874652C322A28652E636F6C756D6E737C7C332929292C22666F726D756C6172696F223D3D3D652E7479706526262874653D4D6174682E6D61782874652C322A28652E636F6C756D6E737C7C322929297D293B7661722066653D302C';
wwv_flow_imp.g_varchar2_table(458) := '64653D21313B66756E6374696F6E20686528652C74297B72657475726E20672E67657443656C6C28652C742B6665297D66756E6374696F6E20706528652C742C722C6E297B672E6D6572676543656C6C7328652C742B66652C722C6E2B6665297D66756E';
wwv_flow_imp.g_varchar2_table(459) := '6374696F6E206D6528652C74297B76617220723D672E676574526F772865293B722E6865696768743D4D6174682E6D617828722E6865696768747C7C302C74297D66756E6374696F6E20776528652C742C722C6E297B766172206F3D612E616464496D61';
wwv_flow_imp.g_varchar2_table(460) := '6765287B6261736536343A652E646174612C657874656E73696F6E3A226A7067223D3D3D652E6578743F226A706567223A22706E67227D293B672E616464496D616765286F2C7B746C3A7B636F6C3A66652C726F773A72652D317D2C6578743A7B776964';
wwv_flow_imp.g_varchar2_table(461) := '74683A332E37382A742C6865696768743A332E37382A727D7D292C72652B3D4D6174682E6365696C28332E37382A722F3230292B286E3F303A31297D66756E6374696F6E20626528652C742C722C6E297B70652872652C312C72652C7465293B76617220';
wwv_flow_imp.g_varchar2_table(462) := '6F3D68652872652C31293B6F2E76616C75653D652C6F2E66696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6E26266D652872652C64653F4D6174682E';
wwv_flow_imp.g_varchar2_table(463) := '6D6178286E2C31352A4D6174682E6365696C28537472696E6728657C7C2222292E6C656E6774682F4D6174682E6D61782831362C392A74652929293A6E292C72652B2B7D582E666F72456163682866756E6374696F6E2074286E297B76617220613D6E2E';
wwv_flow_imp.g_varchar2_table(464) := '747970653B69662822636F6C756D6E6173223D3D3D61297B76617220733D72652C663D72652C683D66652C763D74652C773D303B72657475726E2064653D21302C6765286E2C22786C7378222C722C313030292E666F72456163682866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(465) := '2865297B76617220723D736528652E73656373293B66653D682B772C74653D722C72653D732C652E736563732E666F72456163682874292C663D4D6174682E6D617828662C7265292C772B3D722B317D292C66653D682C74653D762C64653D21312C766F';
wwv_flow_imp.g_varchar2_table(466) := '69642872653D66297D69662822686561646572223D3D3D612962652845286E2E7469746C652C72292C792C7B626F6C643A21302C73697A653A31342C636F6C6F723A7B617267623A69286C2E6865616454657874297D7D2C3236292C286E2E7269676874';
wwv_flow_imp.g_varchar2_table(467) := '7C7C6E2E7375627469746C652926266265285B45286E2E7375627469746C652C72292C45286E2E72696768742C72295D2E66696C74657228426F6F6C65616E292E6A6F696E28222020207C20202022292C792C7B73697A653A392C636F6C6F723A7B6172';
wwv_flow_imp.g_varchar2_table(468) := '67623A69286C2E6865616454657874297D7D2C3136292C72652B2B3B656C73652069662822746578746F223D3D3D61296B286E2C72292E666F72456163682866756E6374696F6E2874297B70652872652C312C72652C7465293B76617220723D68652872';
wwv_flow_imp.g_varchar2_table(469) := '652C31293B722E76616C75653D7B72696368546578743A7A28742C7B666F6E743A6E2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E7B';
wwv_flow_imp.g_varchar2_table(470) := '746578743A652E742C666F6E743A7B626F6C643A212821652E622626216E2E626F6C64292C6974616C69633A212821652E692626216E2E6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F69';
wwv_flow_imp.g_varchar2_table(471) := '6420302C6E616D653A505B652E665D5B315D2C636F6C6F723A652E633F7B617267623A6928652E63297D3A766F696420302C73697A653A6E2E73697A657C7C31307D7D7D297D2C722E616C69676E6D656E743D7B77726170546578743A21302C76657274';
wwv_flow_imp.g_varchar2_table(472) := '6963616C3A22746F70222C686F72697A6F6E74616C3A226A757374696679223D3D3D6E2E616C69676E3F226A757374696679223A6E2E616C69676E7C7C226C656674227D2C6D652872652C4D6174682E6D61782831352C31352A4D6174682E6365696C28';
wwv_flow_imp.g_varchar2_table(473) := '742E6C656E6774682F2864653F4D6174682E6D61782831362C392A7465293A313430292929292C72652B2B7D293B656C736520696628226573706163696F223D3D3D612972652B2B3B656C73652069662822696D6167656E223D3D3D61297B7661722062';
wwv_flow_imp.g_varchar2_table(474) := '3D5365286E2C72293B69662862297B76617220543D4165286E2C62293B776528622C542E772C542E68297D7D656C736520696628226772616669636F223D3D3D61297B766172206E653D4465286E2C722C6C293B6E6526267765286E652C6E652E776D6D';
wwv_flow_imp.g_varchar2_table(475) := '2C6E652E686D6D297D656C73652069662822636F6469676F223D3D3D61297B7661722076653D4965286E2C72293B6966287665297B7661722079653D5265287665293B69662877652879652C79652E776D6D2C79652E686D6D2C76652E6C6162656C292C';
wwv_flow_imp.g_varchar2_table(476) := '76652E6C6162656C297B7661722078653D68652872652C31293B78652E76616C75653D76652E746578742C78652E666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A76652E7465787453697A657D2C72652B3D327D7D7D656C73';
wwv_flow_imp.g_varchar2_table(477) := '65206966282273616C746F223D3D3D612972652B2B3B656C736520696628226669636861223D3D3D61297B7661722045653D41286E2C72295B305D7C7C7B7D2C54653D6E2E636F6C756D6E737C7C332C43653D313B286E2E6669656C64737C7C5B5D292E';
wwv_flow_imp.g_varchar2_table(478) := '66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5328652E7768656E2C722C4565297D292E666F72456163682866756E6374696F6E28652C74297B743E302626742554653D3D3D3026262872652B2B2C43653D31293B';
wwv_flow_imp.g_varchar2_table(479) := '766172206E3D68652872652C4365292C613D68652872652C43652B31292C693D4528652E6C6162656C2C722C4565293B6E2E76616C75653D692C6E2E666F6E743D7B626F6C643A21307D3B766172206C3D2F5E5C7B5B5E7D7C5D2B5C7D242F2E74657374';
wwv_flow_imp.g_varchar2_table(480) := '28652E76616C75657C7C222229262621652E6D61703F7828722C652E76616C75652E736C69636528312C2D31292C4565293A6E756C6C3B6F286C292626216D28652E666D74293F28612E76616C75653D6C2C226D6F6E6579223D3D3D652E666D74262628';
wwv_flow_imp.g_varchar2_table(481) := '612E6E756D466D743D22232C2323302E303022292C612E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A2264617465223D3D3D652E666D74262664286C293F28612E76616C75653D64286C292C612E6E756D466D743D2264';
wwv_flow_imp.g_varchar2_table(482) := '642F6D6D2F79797979222C612E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A612E76616C75653D5A28652C722C4565292C63652843652C69292C63652843652B312C5A28652C722C456529292C43652B3D327D292C7265';
wwv_flow_imp.g_varchar2_table(483) := '2B3D327D656C73652069662822666F726D756C6172696F223D3D3D61297B766172204E653D6E2E636F6C756D6E737C7C322C50653D312C7A653D6F65286E2C722C75293B7A652E666F72456163682866756E6374696F6E28652C74297B743E3026267425';
wwv_flow_imp.g_varchar2_table(484) := '4E653D3D3D3026262872652B2B2C50653D31292C6328652E6E616D65293B76617220723D68652872652C5065292C6E3D68652872652C50652B31293B722E76616C75653D652E6C6162656C2C722E666F6E743D7B626F6C643A21307D2C722E616C69676E';
wwv_flow_imp.g_varchar2_table(485) := '6D656E743D7B766572746963616C3A652E6C696E65733E313F22746F70223A226D6964646C65227D2C66756E6374696F6E28652C742C72297B766172206E3D7B7374796C653A227468696E222C636F6C6F723A7B617267623A69284B297D7D3B652E6669';
wwv_flow_imp.g_varchar2_table(486) := '6C6C3D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A69284A297D7D2C652E626F726465723D7B746F703A6E2C6C6566743A6E2C626F74746F6D3A6E2C72696768743A6E7D2C652E70';
wwv_flow_imp.g_varchar2_table(487) := '726F74656374696F6E3D7B6C6F636B65643A2121742E726561644F6E6C797D2C652E616C69676E6D656E743D7B766572746963616C3A742E6C696E65733E313F22746F70223A226D6964646C65222C686F72697A6F6E74616C3A22636865636B626F7822';
wwv_flow_imp.g_varchar2_table(488) := '3D3D3D742E696E7075743F2263656E746572223A226C656674222C77726170546578743A226D756C74696C696E65223D3D3D742E696E7075747D2C22636865636B626F78223D3D3D742E696E7075743F28652E76616C75653D742E636865636B65643F51';
wwv_flow_imp.g_varchar2_table(489) := '3A65652C652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21312C666F726D756C61653A5B2722E298902CE2989222275D2C73686F774572726F724D6573736167653A21302C6572726F725469746C';
wwv_flow_imp.g_varchar2_table(490) := '653A47652874292C6572726F723A22456C696A6120E29890206F20E298922E227D293A28652E76616C75653D22223D3D3D742E76616C75653F6E756C6C3A742E76616C75652C652E6E756D466D743D2240222C226C697374223D3D3D742E696E7075743F';
wwv_flow_imp.g_varchar2_table(491) := '652E6461746156616C69646174696F6E3D7B747970653A226C697374222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B7228742E6F7074696F6E73295D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A47';
wwv_flow_imp.g_varchar2_table(492) := '652874292C6572726F723A22456C696A6120756E2076616C6F72206465206C61206C697374612E227D3A742E6D61784C656E677468262628652E6461746156616C69646174696F6E3D7B747970653A22746578744C656E677468222C6F70657261746F72';
wwv_flow_imp.g_varchar2_table(493) := '3A226C6573735468616E4F72457175616C222C616C6C6F77426C616E6B3A21302C666F726D756C61653A5B742E6D61784C656E6774685D2C73686F774572726F724D6573736167653A21302C6572726F725469746C653A47652874292C6572726F723A22';
wwv_flow_imp.g_varchar2_table(494) := '4DC3A178696D6F20222B742E6D61784C656E6774682B2220636172616374657265732E227D29292C652E6E616D653D742E6E616D657D286E2C652C24292C652E6C696E65733E3126266D652872652C31352A652E6C696E6573292C63652850652C652E6C';
wwv_flow_imp.g_varchar2_table(495) := '6162656C292C63652850652B312C22636865636B626F78223D3D3D652E696E7075743F22223A652E76616C75652E6C656E6774683E32303F652E76616C75653A6E6577204172726179283231292E6A6F696E2822782229292C50652B3D327D292C7A652E';
wwv_flow_imp.g_varchar2_table(496) := '6C656E67746826262875653D21302C72652B3D32297D656C73652069662822616C65727461223D3D3D612941286E2C72292E66696C7465722866756E6374696F6E2865297B72657475726E2053286E2E7768656E2C722C65297D292E736C69636528302C';
wwv_flow_imp.g_varchar2_table(497) := '6E2E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B62652845286E2E746578742C722C65292C6A2843286E2E636F6C6F722C722C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C72652B2B';
wwv_flow_imp.g_varchar2_table(498) := '3B656C736520696628227461626C61223D3D3D61297B766172206B653D41286E2C72293B696628216B652E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B766172204D653D4D286E2C';
wwv_flow_imp.g_varchar2_table(499) := '722C6B65293B6966286E2E7469746C65297B70652872652C312C72652C4D652E6C656E677468293B7661722046653D68652872652C31293B46652E76616C75653D45286E2E7469746C652C72292C46652E666F6E743D7B626F6C643A21302C636F6C6F72';
wwv_flow_imp.g_varchar2_table(500) := '3A7B617267623A69286C2E6865616454657874297D7D2C46652E66696C6C3D792C72652B2B7D6966286E2E67726F757073297B766172204F653D313B46286E2C4D65292E666F72456163682866756E6374696F6E2865297B652E636F6C733E3126262165';
wwv_flow_imp.g_varchar2_table(501) := '2E676170262670652872652C4F652C72652C4F652B652E636F6C732D31293B76617220743D68652872652C4F65293B696628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B70652872652C4F652B722C72652B312C4F';
wwv_flow_imp.g_varchar2_table(502) := '652B72293B766172206E3D68652872652C4F652B72293B6E2E76616C75653D4D655B652E66726F6D2B725D2E6C6162656C2C6E2E66696C6C3D792C6E2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A69286C2E686561645465787429';
wwv_flow_imp.g_varchar2_table(503) := '7D7D2C6E2E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6365284F652B722C4D655B652E66726F6D2B725D2E6C6162656C297D4F652B3D65';
wwv_flow_imp.g_varchar2_table(504) := '2E636F6C737D656C736520742E76616C75653D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D792C742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A69286C2E6865616454657874297D7D2C742E616C69676E6D656E743D7B68';
wwv_flow_imp.g_varchar2_table(505) := '6F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65227D2C4F652B3D652E636F6C737D292C72652B2B7D766172206A653D72652C4C653D7B7D3B6966286E2E67726F757073262646286E2C4D65292E666F7245616368';
wwv_flow_imp.g_varchar2_table(506) := '2866756E6374696F6E2865297B696628652E67617029666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B294C655B745D3D317D292C4D652E666F72456163682866756E6374696F6E28652C74297B696628214C65';
wwv_flow_imp.g_varchar2_table(507) := '5B745D297B76617220723D68652872652C742B31293B722E76616C75653D652E6C6162656C2C722E66696C6C3D792C722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A69286C2E6865616454657874297D7D2C722E616C69676E6D65';
wwv_flow_imp.g_varchar2_table(508) := '6E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65222C77726170546578743A21307D2C636528742B312C652E6C6162656C297D7D292C72652B2B2C216B652E6C656E6774682972657475726E20706528';
wwv_flow_imp.g_varchar2_table(509) := '72652C312C72652C4D652E6C656E677468292C68652872652C31292E76616C75653D45286E2E656D707479546578742C72292C68652872652C31292E666F6E743D7B6974616C69633A21307D2C766F69642872652B3D32293B7661722055653D72652C42';
wwv_flow_imp.g_varchar2_table(510) := '653D71286E2C6B65292C5F653D56286E292C57653D6E756C6C2C48653D66756E6374696F6E28652C742C722C6E2C6F2C612C69297B76617220753D57284D652C742C722C6E292C733D422874292C633D66756E6374696F6E2865297B72657475726E2065';
wwv_flow_imp.g_varchar2_table(511) := '2E66696C6C3D6A286C2E746F74616C73292C652E666F6E743D7B626F6C643A21307D2C657D3B28752E61743E317C7C303D3D3D752E6174292626706528652C312C652C752E61747C7C4D652E6C656E677468293B76617220663D6328686528652C312929';
wwv_flow_imp.g_varchar2_table(512) := '3B72657475726E20662E76616C75653D6E2C662E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D2C303D3D3D752E61742626652B2B2C4D652E666F72456163682866756E6374696F6E286E2C6C297B69662821286C3C752E6174';
wwv_flow_imp.g_varchar2_table(513) := '29297B76617220663D6328686528652C6C2B3129292C683D6E2E636F6C3F5528742C6E2E636F6C293A6E756C6C3B69662868297B766172206D3D672E676574436F6C756D6E286C2B312B6665292E6C65747465722C763D6D2B6F2B223A222B6D2B612C77';
wwv_flow_imp.g_varchar2_table(514) := '3D4728722C682E636F6C2C682E666E292C623D226D696E22213D3D682E666E2626226D617822213D3D682E666E7C7C6E756C6C3D3D3D777C7C5F2877293F6E756C6C3A642877292C793D6E756C6C3D3D773F6E756C6C3A627C7C285F2877293F4D617468';
wwv_flow_imp.g_varchar2_table(515) := '2E726F756E64283130302A4E756D626572287729292F3130303A537472696E67287729293B662E76616C75653D7B666F726D756C613A28693F22535542544F54414C28222B495B682E666E5D2B222C223A525B682E666E5D2B222822292B762B2229222C';
wwv_flow_imp.g_varchar2_table(516) := '726573756C743A797D3B76617220783D22636F756E74223D3D3D682E666E3F22232C232330223A623F2264642F6D6D2F79797979223A22232C2323302E3030223B662E6E756D466D743D7326264C5B682E666E5D3F2722272B4C5B682E666E5D2B272022';
wwv_flow_imp.g_varchar2_table(517) := '272B783A782C662E616C69676E6D656E743D7B686F72697A6F6E74616C3A227269676874227D2C6E756C6C3D3D3D797C7C627C7C6365286C2B312C5F2879293F7028792C226D6F6E657922293A79297D7D7D292C652B317D3B42652E666F724561636828';
wwv_flow_imp.g_varchar2_table(518) := '66756E6374696F6E2865297B6966282268656164223D3D3D652E6B297B70652872652C312C72652C4D652E6C656E677468293B76617220743D68652872652C31293B72657475726E20742E76616C75653D59286E2C652C72292C742E666F6E743D7B626F';
wwv_flow_imp.g_varchar2_table(519) := '6C643A21307D2C742E66696C6C3D6A286C2E67726F7570292C766F69642072652B2B7D69662822737562223D3D3D652E6B2972657475726E2072653D48652872652C5F652C652E726F77732C59286E2C652C72292C57652C72652D312C2130292C766F69';
wwv_flow_imp.g_varchar2_table(520) := '642857653D6E756C6C293B6E756C6C3D3D3D576526262857653D7265293B76617220613D652E722C753D652E692C733D4E286E2E726F775374796C652C722C61293B4D652E666F72456163682866756E6374696F6E28652C74297B76617220633D686528';
wwv_flow_imp.g_varchar2_table(521) := '72652C742B31292C663D4F28652C612C72293B652E69734E756D26266F2866293F28632E76616C75653D662C632E6E756D466D743D22696E74223D3D3D652E666D743F22232C232330223A226D6F6E6579223D3D3D652E666D747C7C2F5E6E756D2F2E74';
wwv_flow_imp.g_varchar2_table(522) := '65737428652E666D747C7C2222293F22232C2323302E222B6E657720417272617928312A2828652E666D747C7C2222292E73706C697428223A22295B315D7C7C32292B31292E6A6F696E28223022293A2247656E6572616C22293A226461746522213D3D';
wwv_flow_imp.g_varchar2_table(523) := '652E666D742626224441544522213D3D28722E545B537472696E67286E2E736F75726365292E746F55707065724361736528295D7C7C7B7D295B652E636F6C5D7C7C21642866293F632E76616C75653D6E756C6C3D3D663F6E756C6C3A6D28652E666D74';
wwv_flow_imp.g_varchar2_table(524) := '29262621652E6D61703F7028662C652E666D74293A537472696E672866293A28632E76616C75653D642866292C632E6E756D466D743D2264642F6D6D2F7979797922292C632E616C69676E6D656E743D7B686F72697A6F6E74616C3A652E616C69676E7D';
wwv_flow_imp.g_varchar2_table(525) := '3B76617220683D4E28652E63656C6C5374796C652C722C61297C7C733B682626682E66696C6C3F632E66696C6C3D6A28682E66696C6C293A7525323D3D3126262131213D3D6E2E7A65627261262628632E66696C6C3D6A286C2E7A6562726129293B7661';
wwv_flow_imp.g_varchar2_table(526) := '7220673D7B7D3B28652E626F6C647C7C682626682E626F6C6429262628672E626F6C643D2130292C28682626682E636F6C6F727C7C652E636F6C6F7229262628672E636F6C6F723D7B617267623A6928682626682E636F6C6F727C7C652E636F6C6F7229';
wwv_flow_imp.g_varchar2_table(527) := '7D292C28672E626F6C647C7C672E636F6C6F7229262628632E666F6E743D67292C636528742B312C652E69734E756D3F7028662C652E666D74293A66297D292C72652B2B7D293B7661722024653D72652D312C56653D44286E2E746F74616C73293B5665';
wwv_flow_imp.g_varchar2_table(528) := '2E6C656E67746826262872653D48652872652C56652C6B652C48286E2C722C6B65292C55652C72652D312C21216E2E627265616B427929292C31213D3D61657C7C6E2E627265616B42797C7C64657C7C286C653D7B66726F6D3A7B726F773A6A652C636F';
wwv_flow_imp.g_varchar2_table(529) := '6C756D6E3A317D2C746F3A7B726F773A24652C636F6C756D6E3A4D652E6C656E6774687D7D2C582E696E6465784F66286E293C3D3126262869653D6A6529292C72652B2B7D7D292C4F626A6563742E6B657973286E65292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(530) := '74696F6E2865297B672E676574436F6C756D6E282B65292E77696474683D6E655B655D7D292C6C65262628672E6175746F46696C7465723D6C65292C6965262628672E76696577733D5B7B73746174653A2266726F7A656E222C7953706C69743A69657D';
wwv_flow_imp.g_varchar2_table(531) := '5D292C75652626732E70726F746563742626662E7075736828672E70726F7465637428732E70617373776F72642C7B73656C6563744C6F636B656443656C6C733A21302C73656C656374556E6C6F636B656443656C6C733A21302C666F726D6174436F6C';
wwv_flow_imp.g_varchar2_table(532) := '756D6E733A21302C666F726D6174526F77733A21307D29292C652E666F6F746572262628672E686561646572466F6F7465722E6F6464466F6F7465723D22264C2638222B4528652E666F6F7465722E6C6566742C72292E7265706C616365282F262F672C';
wwv_flow_imp.g_varchar2_table(533) := '22262622292E73756273747228302C323030292B222652263850C3A167696E6120265020646520264E22297D297D292C6C65286529262666756E6374696F6E2865297B76617220743D652E646566696E65644E616D65732C723D7426264F626A6563742E';
wwv_flow_imp.g_varchar2_table(534) := '6765744F776E50726F706572747944657363726970746F72284F626A6563742E67657450726F746F747970654F662874292C226D6F64656C22293B722626722E676574262621742E5F5F6E722626284F626A6563742E646566696E6550726F7065727479';
wwv_flow_imp.g_varchar2_table(535) := '28742C226D6F64656C222C7B636F6E666967757261626C653A21302C6765743A66756E6374696F6E28297B72657475726E20722E6765742E63616C6C2874686973292E6D61702866756E6374696F6E2865297B72657475726E7B6E616D653A652E6E616D';
wwv_flow_imp.g_varchar2_table(536) := '652C72616E6765733A652E72616E6765732E6D61702866756E6374696F6E2865297B76617220743D2F5E285B5E27215D2B2921282E2B29242F2E657865632865293B72657475726E20743F2227222B745B315D2B222721222B745B325D3A657D297D7D29';
wwv_flow_imp.g_varchar2_table(537) := '7D2C7365743A66756E6374696F6E2865297B722E7365742E63616C6C28746869732C65297D7D292C742E5F5F6E723D2130297D2861292C662E6C656E6774683F50726F6D6973652E616C6C2866292E7468656E2866756E6374696F6E28297B7265747572';
wwv_flow_imp.g_varchar2_table(538) := '6E20612E786C73782E777269746542756666657228297D293A612E786C73782E777269746542756666657228297D7661722048653D7B6C65747465723A5B31323234302C31353834305D2C6C6567616C3A5B31323234302C32303136305D2C61343A5B31';
wwv_flow_imp.g_varchar2_table(539) := '313930362C31363833385D7D3B66756E6374696F6E20246528652C742C72297B766172206E3D77696E646F772E646F63782C6F3D5B5D2C613D4D6174682E726F756E6428322A28652E73697A657C7C3729292C693D6C28722E6D75746564293B66756E63';
wwv_flow_imp.g_varchar2_table(540) := '74696F6E20752865297B76617220723D4528652C74292E73706C6974282F285C7B50414745533F5C7D292F292C6F3D5B5D3B72657475726E20722E666F72456163682866756E6374696F6E2865297B227B504147457D223D3D3D653F6F2E70757368286E';
wwv_flow_imp.g_varchar2_table(541) := '6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E43555252454E545D2C73697A653A612C636F6C6F723A697D29293A227B50414745537D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B';
wwv_flow_imp.g_varchar2_table(542) := '6368696C6472656E3A5B6E2E506167654E756D6265722E544F54414C5F50414745535D2C73697A653A612C636F6C6F723A697D29293A6526266F2E70757368286E6577206E2E5465787452756E287B746578743A652C73697A653A612C636F6C6F723A69';
wwv_flow_imp.g_varchar2_table(543) := '7D29297D292C6F7D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A7528652E6C656674297D29292C652E726967687426266F2E70757368286E6577206E2E506172616772617068';
wwv_flow_imp.g_varchar2_table(544) := '287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E3A7528652E7269676874297D29292C6F2E6C656E6774683F6F3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B5D7D295D';
wwv_flow_imp.g_varchar2_table(545) := '7D66756E6374696F6E20566528652C742C72297B766172206E3D77696E646F772E646F63782C6F3D77652865292C613D652E706167657C7C7B7D2C693D5B5D2C753D726528292C733D48655B612E73697A657C7C226C6574746572225D7C7C48652E6C65';
wwv_flow_imp.g_varchar2_table(546) := '747465722C633D226C616E647363617065223D3D3D612E6F7269656E746174696F6E2C663D4D6174682E726F756E642835362E372A28612E6D617267696E7C7C31322E3729292C643D28633F735B315D3A735B305D292D322A662C683D7B7374796C653A';
wwv_flow_imp.g_varchar2_table(547) := '6E2E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C703D7B746F703A682C626F74746F6D3A682C6C6566743A682C72696768743A682C696E73696465486F72697A6F6E74616C3A682C696E73696465';
wwv_flow_imp.g_varchar2_table(548) := '566572746963616C3A687D2C6D3D7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A22424643394434227D2C673D7B746F703A6D2C626F74746F6D3A6D2C6C6566743A6D2C72696768743A6D2C696E';
wwv_flow_imp.g_varchar2_table(549) := '73696465486F72697A6F6E74616C3A6D2C696E73696465566572746963616C3A6D7D2C763D4D6174682E726F756E6428322A286F2E666F6E7453697A657C7C3729293B66756E6374696F6E207728652C74297B72657475726E20743D747C7C7B7D2C6E65';
wwv_flow_imp.g_varchar2_table(550) := '77206E2E5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C73697A653A742E73697A657C7C762C636F6C6F723A742E636F6C6F72';
wwv_flow_imp.g_varchar2_table(551) := '3F6C28742E636F6C6F72293A766F696420302C666F6E743A2243616C69627269227D297D66756E6374696F6E206228652C74297B72657475726E20743D747C7C7B7D2C6E6577206E2E506172616772617068287B6368696C6472656E3A5B7728652C7429';
wwv_flow_imp.g_varchar2_table(552) := '5D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A227269676874223D3D3D742E616C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D742E616C69676E3F6E2E';
wwv_flow_imp.g_varchar2_table(553) := '416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546547D297D66756E6374696F6E207928652C74297B72657475726E20743D747C7C7B7D2C6E6577206E2E5461626C6543656C6C287B6368696C6472656E';
wwv_flow_imp.g_varchar2_table(554) := '3A5B6228652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A742E66696C6C3F7B747970653A6E2E5368616469';
wwv_flow_imp.g_varchar2_table(555) := '6E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6C28742E66696C6C297D3A766F696420307D297D66756E6374696F6E207828297B72657475726E206E6577206E2E506172616772617068287B6368696C6472656E3A5B5D2C';
wwv_flow_imp.g_varchar2_table(556) := '73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D66756E6374696F6E205428652C742C722C6F2C61297B72657475726E206E6577206E2E506172616772617068287B616C69676E6D656E743A227269676874223D3D3D6F2E61';
wwv_flow_imp.g_varchar2_table(557) := '6C69676E3F6E2E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6F2E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C73706163696E673A7B61';
wwv_flow_imp.g_varchar2_table(558) := '667465723A766F69642030213D3D613F613A4D6174682E726F756E642835362E372A28766F69642030213D3D6F2E6761703F6F2E6761703A3329297D2C6368696C6472656E3A5B6E6577206E2E496D61676552756E287B747970653A226A7067223D3D3D';
wwv_flow_imp.g_varchar2_table(559) := '652E6578743F226A7067223A22706E67222C646174613A652E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A74292C6865696768743A4D6174682E726F756E6428332E37382A72297D7D295D7D';
wwv_flow_imp.g_varchar2_table(560) := '297D766172204F3D28633F735B315D3A735B305D292F35362E372C493D28633F735B305D3A735B315D292F35362E373B66756E6374696F6E20522874297B76617220722C6F3D556528652C74293B696628216F2972657475726E206E756C6C3B7472797B';
wwv_flow_imp.g_varchar2_table(561) := '723D66756E6374696F6E28652C742C72297B766172206E3D372E35362C6F3D5065284D6174682E726F756E6428742A6E292C4D6174682E726F756E6428722A6E29292C613D6F2E676574436F6E746578742822326422292C693D2248656C766574696361';
wwv_flow_imp.g_varchar2_table(562) := '2C20417269616C2C2073616E732D7365726966223B612E666F6E743D22626F6C64203236362E37313638707820222B693B766172206C3D426528652C612E6D6561737572655465787428652E74657874292E77696474682F6E2C742C72293B612E666F6E';
wwv_flow_imp.g_varchar2_table(563) := '743D22626F6C6420222B2E333532382A6C2A6E2B22707820222B692C612E7472616E736C617465286F2E77696474682F322C6F2E6865696768742F32292C612E726F74617465282D652E616E676C652A4D6174682E50492F313830292C612E676C6F6261';
wwv_flow_imp.g_varchar2_table(564) := '6C416C7068613D652E6F7061636974792C612E66696C6C5374796C653D652E636F6C6F722C612E74657874416C69676E3D2263656E746572222C612E74657874426173656C696E653D226D6964646C65222C612E66696C6C5465787428652E746578742C';
wwv_flow_imp.g_varchar2_table(565) := '302C30293B76617220753D4E65286F2E746F4461746155524C2822696D6167652F706E6722292C6F2E77696474682C6F2E686569676874293B72657475726E20752E776D6D3D742C752E686D6D3D722C757D286F2C4F2C49297D63617463682865297B72';
wwv_flow_imp.g_varchar2_table(566) := '657475726E206E756C6C7D72657475726E206E6577206E2E486561646572287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B6E6577206E2E496D61676552756E287B747970653A22706E67222C64617461';
wwv_flow_imp.g_varchar2_table(567) := '3A722E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A4F292C6865696768743A4D6174682E726F756E6428332E37382A49297D2C666C6F6174696E673A7B686F72697A6F6E74616C506F736974';
wwv_flow_imp.g_varchar2_table(568) := '696F6E3A7B72656C61746976653A6E2E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6E2E486F72697A6F6E74616C506F736974696F6E416C69676E2E43454E5445527D2C766572746963616C';
wwv_flow_imp.g_varchar2_table(569) := '506F736974696F6E3A7B72656C61746976653A6E2E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A6E2E566572746963616C506F736974696F6E416C69676E2E43454E5445527D2C626568696E6444';
wwv_flow_imp.g_varchar2_table(570) := '6F63756D656E743A21302C616C6C6F774F7665726C61703A21302C777261703A7B747970653A6E2E546578745772617070696E67547970652E4E4F4E457D7D7D295D7D295D7D297D766172204C3D742E6D61702866756E6374696F6E28722C61297B7661';
wwv_flow_imp.g_varchar2_table(571) := '7220683D5B5D2C6D3D742E6C656E6774683E313F225F222B28612B31293A22223B706528652C22646F6378222C72292E666F72456163682866756E6374696F6E20742861297B76617220733D612E747970653B69662822636F6C756D6E6173223D3D3D73';
wwv_flow_imp.g_varchar2_table(572) := '297B76617220633D676528612C22646F6378222C722C642F35362E37293B69662821632E6C656E6774682972657475726E3B76617220663D682C4F3D642C493D4D6174682E726F756E642835362E372A28766F69642030213D3D612E636F6C4761703F4E';
wwv_flow_imp.g_varchar2_table(573) := '756D62657228612E636F6C476170293A3429292C523D5B5D2C4C3D5B5D3B72657475726E20632E666F72456163682866756E6374696F6E28652C72297B766172206F3D723D3D3D632E6C656E6774682D312C613D4D6174682E726F756E642835362E372A';
wwv_flow_imp.g_varchar2_table(574) := '652E77293B683D5B5D2C643D612C652E736563732E666F72456163682874292C682E6C656E6774682626685B682E6C656E6774682D315D696E7374616E63656F66206E2E5061726167726170687C7C682E70757368286228222229292C522E7075736828';
wwv_flow_imp.g_varchar2_table(575) := '6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A682C77696474683A7B73697A653A612B286F3F303A49292C747970653A6E2E5769647468547970652E4458417D2C6D617267696E733A7B746F703A302C626F74746F6D3A302C6C656674';
wwv_flow_imp.g_varchar2_table(576) := '3A302C72696768743A6F3F303A497D2C766572746963616C416C69676E3A6E2E566572746963616C416C69676E2E544F507D29292C4C2E7075736828612B286F3F303A4929297D292C643D4F2C766F696428683D66292E70757368286E6577206E2E5461';
wwv_flow_imp.g_varchar2_table(577) := '626C65287B726F77733A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A527D295D2C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E57696474';
wwv_flow_imp.g_varchar2_table(578) := '68733A4C2C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C782829297D69662822686561646572223D3D3D73297B76617220553D5B6E6577206E2E5461626C65526F77287B6368696C647265';
wwv_flow_imp.g_varchar2_table(579) := '6E3A5B79284528612E7469746C652C72292C7B626F6C643A21302C73697A653A32382C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172797D292C79284528612E72696768742C72292C7B73697A653A31382C636F6C6F723A6F';
wwv_flow_imp.g_varchar2_table(580) := '2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A227269676874227D295D7D295D3B612E7375627469746C652626552E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A5B79284528612E73756274';
wwv_flow_imp.g_varchar2_table(581) := '69746C652C72292C7B73697A653A31382C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C7370616E3A327D295D7D29292C682E70757368286E6577206E2E5461626C65287B726F77733A552C77696474683A7B73697A65';
wwv_flow_imp.g_varchar2_table(582) := '3A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B4D6174682E726F756E64282E372A64292C4D6174682E726F756E64282E332A64295D2C626F72646572733A707D292C782829297D656C73652069662822';
wwv_flow_imp.g_varchar2_table(583) := '746578746F223D3D3D73297B76617220423D7B72696768743A6E2E416C69676E6D656E74547970652E52494748542C63656E7465723A6E2E416C69676E6D656E74547970652E43454E5445522C6A7573746966793A6E2E416C69676E6D656E7454797065';
wwv_flow_imp.g_varchar2_table(584) := '2E4A55535449464945447D3B6B28612C72292E666F72456163682866756E6374696F6E2874297B682E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A425B612E616C69676E5D7C7C6E2E416C69676E6D656E7454797065';
wwv_flow_imp.g_varchar2_table(585) := '2E4C4546542C696E64656E743A612E696E64656E743F7B6C6566743A4D6174682E726F756E642835362E372A612E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A766F69642030213D3D612E706172616772617068476170';
wwv_flow_imp.g_varchar2_table(586) := '3F4D6174682E726F756E642835362E372A612E706172616772617068476170293A3132302C6C696E653A4D6174682E726F756E64283234302A28612E6C696E654865696768747C7C312E313529297D2C6368696C6472656E3A7A28742C7B666F6E743A61';
wwv_flow_imp.g_varchar2_table(587) := '2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A612E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E206E6577206E2E5465787452756E287B746578743A652E742C626F6C643A212821652E';
wwv_flow_imp.g_varchar2_table(588) := '62262621612E626F6C64292C6974616C6963733A212821652E69262621612E6974616C6963292C73697A653A322A28612E73697A657C7C3130292C756E6465726C696E653A652E753F7B7D3A766F696420302C737472696B653A2121652E732C636F6C6F';
wwv_flow_imp.g_varchar2_table(589) := '723A652E633F6C28652E63293A766F696420302C666F6E743A505B652E665D5B315D7D297D297D29297D297D656C736520696628226573706163696F223D3D3D7329682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B';
wwv_flow_imp.g_varchar2_table(590) := '5D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28612E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D73297B696628766F696420303D3D3D612E7831297B766172205F3D4D6174';
wwv_flow_imp.g_varchar2_table(591) := '682E726F756E642835362E372A28612E77696474687C7C3029292C473D5F3F4D6174682E6D617828302C4D6174682E726F756E642828642D5F292F3229293A303B682E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A5B5D';
wwv_flow_imp.g_varchar2_table(592) := '2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3229297D2C696E64656E743A2263656E746572223D3D3D612E616C69676E3F7B6C6566743A472C72696768743A47';
wwv_flow_imp.g_varchar2_table(593) := '7D3A227269676874223D3D3D612E616C69676E3F7B6C6566743A322A477D3A7B72696768743A322A477D2C626F726465723A7B626F74746F6D3A7B7374796C653A6E2E426F726465725374796C652E53494E474C452C73697A653A4D6174682E6D617828';
wwv_flow_imp.g_varchar2_table(594) := '322C4D6174682E726F756E642832302A28612E746869636B6E6573737C7C2E332929292C636F6C6F723A6C28612E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C73652069662822696D6167656E223D3D3D73297B';
wwv_flow_imp.g_varchar2_table(595) := '76617220243D536528612C72293B69662824297B76617220583D416528612C24293B682E70757368285428242C582E772C582E682C6129297D7D656C736520696628226772616669636F223D3D3D73297B76617220513D446528612C722C6F293B512626';
wwv_flow_imp.g_varchar2_table(596) := '682E70757368285428512C512E776D6D2C512E686D6D2C6129297D656C73652069662822636F6469676F223D3D3D73297B7661722065653D496528612C72293B6966286565297B7661722074653D5265286565293B682E7075736828542874652C74652E';
wwv_flow_imp.g_varchar2_table(597) := '776D6D2C74652E686D6D2C612C65652E6C6162656C3F303A766F6964203029292C65652E6C6162656C2626682E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A227269676874223D3D3D612E616C69676E3F6E2E416C69';
wwv_flow_imp.g_varchar2_table(598) := '676E6D656E74547970652E52494748543A2263656E746572223D3D3D612E616C69676E3F6E2E416C69676E6D656E74547970652E43454E5445523A6E2E416C69676E6D656E74547970652E4C4546542C696E64656E743A227269676874223D3D3D612E61';
wwv_flow_imp.g_varchar2_table(599) := '6C69676E7C7C2263656E746572223D3D3D612E616C69676E3F766F696420303A7B6C6566743A4D6174682E6D617828302C4D6174682E726F756E64282874652E776D6D2D65652E746578742E6C656E6774682A65652E7465787453697A652A2E33353238';
wwv_flow_imp.g_varchar2_table(600) := '2A2E36292F322A35362E3729297D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3329297D2C6368696C6472656E3A5B6E6577206E2E5465787452756E287B7465';
wwv_flow_imp.g_varchar2_table(601) := '78743A65652E746578742C666F6E743A22436F7572696572204E6577222C73697A653A322A65652E7465787453697A652C636F6C6F723A6C2865652E636F6C6F72297D295D7D29297D7D656C7365206966282273616C746F223D3D3D7329682E70757368';
wwv_flow_imp.g_varchar2_table(602) := '286E6577206E2E506172616772617068287B6368696C6472656E3A5B6E6577206E2E50616765427265616B5D7D29293B656C736520696628226669636861223D3D3D73297B7661722072653D4128612C72295B305D7C7C7B7D2C6E653D612E636F6C756D';
wwv_flow_imp.g_varchar2_table(603) := '6E737C7C332C61653D5B5D2C69653D5B5D3B69662828612E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5328652E7768656E2C722C7265297D292E666F72456163682866756E6374';
wwv_flow_imp.g_varchar2_table(604) := '696F6E2865297B69652E707573682879284528652E6C6162656C2C722C7265292C7B626F6C643A21302C73697A653A31377D292C79285A28652C722C7265292C7B73697A653A31377D29292C69652E6C656E6774683D3D3D322A6E6526262861652E7075';
wwv_flow_imp.g_varchar2_table(605) := '7368286E6577206E2E5461626C65526F77287B6368696C6472656E3A69657D29292C69653D5B5D297D292C69652E6C656E677468297B666F72283B69652E6C656E6774683C322A6E653B2969652E70757368287928222229293B61652E70757368286E65';
wwv_flow_imp.g_varchar2_table(606) := '77206E2E5461626C65526F77287B6368696C6472656E3A69657D29297D69662861652E6C656E677468297B666F7228766172206C653D5B5D2C75653D303B75653C322A6E653B75652B2B296C652E70757368284D6174682E726F756E6428642F28322A6E';
wwv_flow_imp.g_varchar2_table(607) := '652929293B682E70757368286E6577206E2E5461626C65287B726F77733A61652C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A6C652C626F72646572733A707D292C782829';
wwv_flow_imp.g_varchar2_table(608) := '297D7D656C73652069662822666F726D756C6172696F223D3D3D73297B7661722073653D612E636F6C756D6E737C7C322C63653D5B5D2C66653D5B5D2C64653D312C68653D6F6528612C722C6D292C70653D7B7374796C653A6E2E426F72646572537479';
wwv_flow_imp.g_varchar2_table(609) := '6C652E53494E474C452C73697A653A342C636F6C6F723A6C284B297D2C6D653D66756E6374696F6E28297B63652E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A66652C63616E7453706C69743A21302C6865696768743A64';
wwv_flow_imp.g_varchar2_table(610) := '653E313F7B76616C75653A4D6174682E726F756E64283233302A64652B313230292C72756C653A6E2E48656967687452756C652E41544C454153547D3A766F696420307D29292C66653D5B5D2C64653D317D3B69662868652E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(611) := '6374696F6E2865297B7528652E6E616D65293B76617220743D692E6C656E6774683B692E707573682865292C64653D4D6174682E6D61782864652C652E6C696E6573292C66652E70757368286E6577206E2E5461626C6543656C6C287B6368696C647265';
wwv_flow_imp.g_varchar2_table(612) := '6E3A5B6228652E6C6162656C2C7B626F6C643A21302C73697A653A31377D295D2C766572746963616C416C69676E3A652E6C696E65733E313F6E2E566572746963616C416C69676E2E544F503A6E2E566572746963616C416C69676E2E43454E5445522C';
wwv_flow_imp.g_varchar2_table(613) := '6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D7D292C6E6577206E2E5461626C6543656C6C287B6368696C6472656E3A5B6E6577206E2E506172616772617068287B6368696C6472656E3A5B';
wwv_flow_imp.g_varchar2_table(614) := '772871652B742B59652C7B73697A653A31377D295D2C73706163696E673A7B6265666F72653A302C61667465723A307D7D295D2C766572746963616C416C69676E3A652E6C696E65733E313F6E2E566572746963616C416C69676E2E544F503A6E2E5665';
wwv_flow_imp.g_varchar2_table(615) := '72746963616C416C69676E2E43454E5445522C6D617267696E733A7B746F703A34302C626F74746F6D3A34302C6C6566743A36302C72696768743A36307D2C626F72646572733A7B746F703A70652C626F74746F6D3A70652C6C6566743A70652C726967';
wwv_flow_imp.g_varchar2_table(616) := '68743A70657D2C73686164696E673A7B747970653A6E2E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6C284A297D7D29292C66652E6C656E6774683D3D3D322A736526266D6528297D292C66652E6C656E67';
wwv_flow_imp.g_varchar2_table(617) := '7468297B666F72283B66652E6C656E6774683C322A73653B2966652E70757368287928222229293B6D6528297D69662863652E6C656E677468297B7661722076653D5B5D2C77653D4D6174682E726F756E642835362E372A28612E6C6162656C57696474';
wwv_flow_imp.g_varchar2_table(618) := '687C7C333229292C62653D4D6174682E6D6178283630302C4D6174682E726F756E642828642D77652A7365292F736529293B77652A73652B3630302A73653E6426262862653D77653D4D6174682E726F756E6428642F28322A73652929293B666F722876';
wwv_flow_imp.g_varchar2_table(619) := '61722079653D303B79653C73653B79652B2B2976652E707573682877652C6265293B682E70757368286E6577206E2E5461626C65287B726F77733A63652C77696474683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F';
wwv_flow_imp.g_varchar2_table(620) := '6C756D6E5769647468733A76652C626F72646572733A702C6C61796F75743A6E2E5461626C654C61796F7574547970652E46495845447D292C782829297D7D656C73652069662822616C65727461223D3D3D73294128612C72292E66696C746572286675';
wwv_flow_imp.g_varchar2_table(621) := '6E6374696F6E2865297B72657475726E205328612E7768656E2C722C65297D292E736C69636528302C612E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B682E70757368286E6577206E2E5461626C65287B726F77733A';
wwv_flow_imp.g_varchar2_table(622) := '5B6E6577206E2E5461626C65526F77287B6368696C6472656E3A5B79284528612E746578742C722C65292C7B626F6C643A21302C73697A653A31372C66696C6C3A4328612E636F6C6F722C722C65297C7C2223453645434632227D295D7D295D2C776964';
wwv_flow_imp.g_varchar2_table(623) := '74683A7B73697A653A642C747970653A6E2E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B645D2C626F72646572733A707D292C782829297D293B656C736520696628227461626C61223D3D3D73297B7661722078653D412861';
wwv_flow_imp.g_varchar2_table(624) := '2C72293B6966282178652E6C656E67746826262131213D3D612E68696465456D707479262621612E656D707479546578742972657475726E3B7661722045653D4D28612C722C7865292C54653D5B5D3B612E7469746C65262654652E70757368286E6577';
wwv_flow_imp.g_varchar2_table(625) := '206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A5B79284528612E7469746C652C72292C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C7370616E3A45';
wwv_flow_imp.g_varchar2_table(626) := '652E6C656E6774682C73697A653A762B327D295D7D29292C612E67726F757073262654652E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A4628612C4565292E6D61702866756E637469';
wwv_flow_imp.g_varchar2_table(627) := '6F6E2865297B72657475726E207928652E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A2263656E746572222C7370616E3A652E636F6C737D297D297D29';
wwv_flow_imp.g_varchar2_table(628) := '292C54652E70757368286E6577206E2E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A45652E6D61702866756E6374696F6E2865297B72657475726E207928652E6C6162656C2C7B626F6C643A21302C636F6C6F72';
wwv_flow_imp.g_varchar2_table(629) := '3A6F2E68656164546578742C66696C6C3A6F2E7072696D6172792C616C69676E3A2263656E746572227D297D297D29292C78652E6C656E6774687C7C54652E70757368286E6577206E2E5461626C65526F77287B6368696C6472656E3A5B79284528612E';
wwv_flow_imp.g_varchar2_table(630) := '656D707479546578742C72292C7B6974616C69633A21302C7370616E3A45652E6C656E6774687D295D7D29293B7661722043653D562861292C4E653D66756E6374696F6E2865297B76617220743D7928652E746578742C7B626F6C643A21302C616C6967';
wwv_flow_imp.g_varchar2_table(631) := '6E3A226C656674222C66696C6C3A6F2E746F74616C732C7370616E3A652E61747C7C45652E6C656E6774687D292C723D652E63656C6C732E736C69636528652E6174292E6D61702866756E6374696F6E2865297B72657475726E207928652C7B626F6C64';
wwv_flow_imp.g_varchar2_table(632) := '3A21302C616C69676E3A227269676874222C66696C6C3A6F2E746F74616C737D297D293B72657475726E20303D3D3D652E61743F5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D7D292C6E6577';
wwv_flow_imp.g_varchar2_table(633) := '206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A727D295D3A5B6E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D2E636F6E6361742872297D295D7D3B712861';
wwv_flow_imp.g_varchar2_table(634) := '2C7865292E666F72456163682866756E6374696F6E2865297B696628226865616422213D3D652E6B296966282273756222213D3D652E6B297B76617220743D652E722C693D652E692C6C3D4E28612E726F775374796C652C722C74293B54652E70757368';
wwv_flow_imp.g_varchar2_table(635) := '286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A45652E6D61702866756E6374696F6E2865297B766172206E3D4E28652E63656C6C5374796C652C722C74297C7C6C7C7C7B7D3B72657475726E2079286A';
wwv_flow_imp.g_varchar2_table(636) := '28652C742C72292C7B616C69676E3A652E616C69676E2C626F6C643A652E626F6C647C7C6E2E626F6C642C636F6C6F723A6E2E636F6C6F727C7C652E636F6C6F722C66696C6C3A6E2E66696C6C7C7C286925323D3D3126262131213D3D612E7A65627261';
wwv_flow_imp.g_varchar2_table(637) := '3F6F2E7A656272613A6E756C6C297D297D297D29297D656C7365204E6528572845652C43652C652E726F77732C5928612C652C722929292E666F72456163682866756E6374696F6E2865297B54652E707573682865297D293B656C73652054652E707573';
wwv_flow_imp.g_varchar2_table(638) := '68286E6577206E2E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B79285928612C652C72292C7B626F6C643A21302C66696C6C3A6F2E67726F75702C7370616E3A45652E6C656E6774687D295D7D29297D292C442861';
wwv_flow_imp.g_varchar2_table(639) := '2E746F74616C73292E6C656E677468262678652E6C656E67746826264E6528572845652C4428612E746F74616C73292C78652C4828612C722C78652929292E666F72456163682866756E6374696F6E2865297B54652E707573682865297D293B76617220';
wwv_flow_imp.g_varchar2_table(640) := '50653D45652E6D61702866756E6374696F6E2865297B72657475726E20652E77696474683F652E77696474682F32303A317D292C7A653D50652E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C6B653D50652E';
wwv_flow_imp.g_varchar2_table(641) := '6D61702866756E6374696F6E2865297B72657475726E204D6174682E666C6F6F7228642A652F7A65297D293B682E70757368286E6577206E2E5461626C65287B726F77733A54652C77696474683A7B73697A653A642C747970653A6E2E57696474685479';
wwv_flow_imp.g_varchar2_table(642) := '70652E4458417D2C636F6C756D6E5769647468733A6B652C626F72646572733A677D292C782829297D7D293B766172204F3D652E666F6F7465722C493D522872293B72657475726E7B686561646572733A493F7B64656661756C743A497D3A766F696420';
wwv_flow_imp.g_varchar2_table(643) := '302C70726F706572746965733A7B706167653A7B73697A653A7B77696474683A735B305D2C6865696768743A735B315D2C6F7269656E746174696F6E3A633F6E2E506167654F7269656E746174696F6E2E4C414E4453434150453A6E2E506167654F7269';
wwv_flow_imp.g_varchar2_table(644) := '656E746174696F6E2E504F5254524149547D2C6D617267696E3A7B746F703A662C626F74746F6D3A662C6C6566743A662C72696768743A667D7D7D2C666F6F746572733A4F3F7B64656661756C743A6E6577206E2E466F6F746572287B6368696C647265';
wwv_flow_imp.g_varchar2_table(645) := '6E3A2465284F2C722C6F297D297D3A766F696420302C6368696C6472656E3A682E6C656E6774683F683A5B62282222295D7D7D292C553D6E6577206E2E446F63756D656E74287B63726561746F723A226E6F76615265706F7274222C7469746C653A4528';
wwv_flow_imp.g_varchar2_table(646) := '652E7469746C657C7C22222C745B305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A4C7D292C423D6E2E5061636B65722E746F426C6F623F6E2E5061636B65722E746F426C6F622855292E7468656E2866756E6374696F6E2865297B7265';
wwv_flow_imp.g_varchar2_table(647) := '7475726E20652E61727261794275666665723F652E617272617942756666657228293A657D293A6E2E5061636B65722E746F4275666665722855293B72657475726E20692E6C656E6774683F422E7468656E2866756E6374696F6E2874297B7265747572';
wwv_flow_imp.g_varchar2_table(648) := '6E2066756E6374696F6E28652C742C72297B722E70726F746563742626722E70617373776F72642626686528722E70617373776F72642C6E65772055696E74384172726179283136292C30293B72657475726E2077696E646F772E4A535A69702E6C6F61';
wwv_flow_imp.g_varchar2_table(649) := '644173796E632865292E7468656E2866756E6374696F6E2865297B72657475726E2050726F6D6973652E616C6C285B652E66696C652822776F72642F646F63756D656E742E786D6C22292E6173796E632822737472696E6722292C652E66696C65282277';
wwv_flow_imp.g_varchar2_table(650) := '6F72642F73657474696E67732E786D6C22292E6173796E632822737472696E6722295D292E7468656E2866756E6374696F6E286E297B766172206F3D302C613D6E65772052656745787028273C773A723E283C773A7250723E283F3A283F213C2F773A72';
wwv_flow_imp.g_varchar2_table(651) := '50723E295B5C5C735C5C535D292A3C2F773A7250723E293F3C773A7420786D6C3A73706163653D227072657365727665223E272B71652B22285C5C642B29222B59652B223C2F773A743E3C2F773A723E222C226722292C693D6E5B305D2E7265706C6163';
wwv_flow_imp.g_varchar2_table(652) := '6528612C66756E6374696F6E28652C722C6E297B72657475726E206F2B2B2C66756E6374696F6E28652C742C72297B766172206E3D273C773A616C69617320773A76616C3D22272B5A6528652E6C6162656C7C7C652E6E616D65292B27222F3E3C773A74';
wwv_flow_imp.g_varchar2_table(653) := '616720773A76616C3D22272B5A6528652E6E616D65292B27222F3E3C773A696420773A76616C3D22272B742B27222F3E272B28652E726561644F6E6C793F273C773A6C6F636B20773A76616C3D22736474436F6E74656E744C6F636B6564222F3E273A22';
wwv_flow_imp.g_varchar2_table(654) := '22293B69662822636865636B626F78223D3D3D652E696E707574297B766172206F3D273C773A72466F6E747320773A61736369693D224D5320476F746869632220773A65617374417369613D224D5320476F746869632220773A68416E73693D224D5320';
wwv_flow_imp.g_varchar2_table(655) := '476F746869632220773A63733D224D5320476F74686963222F3E272C613D722E7265706C616365282F3C773A72466F6E74735B5E3E5D2A5C2F3E2F2C2222292E7265706C61636528223C773A7250723E222C223C773A7250723E222B6F293B7265747572';
wwv_flow_imp.g_varchar2_table(656) := '6E223C773A7364743E3C773A73647450723E222B612B6E2B273C7731343A636865636B626F783E3C7731343A636865636B6564207731343A76616C3D22272B28652E636865636B65643F313A30292B27222F3E3C7731343A636865636B65645374617465';
wwv_flow_imp.g_varchar2_table(657) := '207731343A76616C3D223236313222207731343A666F6E743D224D5320476F74686963222F3E3C7731343A756E636865636B65645374617465207731343A76616C3D223236313022207731343A666F6E743D224D5320476F74686963222F3E3C2F773134';
wwv_flow_imp.g_varchar2_table(658) := '3A636865636B626F783E3C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E272B612B223C773A743E222B28652E636865636B65643F513A6565292B223C2F773A743E3C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A';
wwv_flow_imp.g_varchar2_table(659) := '7364743E227D76617220693D21652E76616C75652C6C3D652E76616C75657C7C652E706C616365686F6C6465727C7C28226C697374223D3D3D652E696E7075743F22456C696A6120756E20656C656D656E746F2E223A22E28082E28082E28082E28082E2';
wwv_flow_imp.g_varchar2_table(660) := '8082E28082E28082E2808222292C753D226C697374223D3D3D652E696E7075743F223C773A64726F70446F776E4C6973743E222B652E6F7074696F6E732E6D61702866756E6374696F6E2865297B72657475726E273C773A6C6973744974656D20773A64';
wwv_flow_imp.g_varchar2_table(661) := '6973706C6179546578743D22272B5A652865292B272220773A76616C75653D22272B5A652865292B27222F3E277D292E6A6F696E282222292B223C2F773A64726F70446F776E4C6973743E223A223C773A74657874222B28226D756C74696C696E65223D';
wwv_flow_imp.g_varchar2_table(662) := '3D3D652E696E7075743F2720773A6D756C74694C696E653D223122273A2222292B222F3E222C733D537472696E67286C292E73706C6974282F5C723F5C6E2F292E6D61702866756E6374696F6E2865297B72657475726E273C773A7420786D6C3A737061';
wwv_flow_imp.g_varchar2_table(663) := '63653D227072657365727665223E272B5A652865292B223C2F773A743E227D292E6A6F696E28223C773A62722F3E22293B72657475726E223C773A7364743E3C773A73647450723E222B722B6E2B28693F223C773A73686F77696E67506C634864722F3E';
wwv_flow_imp.g_varchar2_table(664) := '223A2222292B752B223C2F773A73647450723E3C773A736474436F6E74656E743E3C773A723E222B722B732B223C2F773A723E3C2F773A736474436F6E74656E743E3C2F773A7364743E227D28745B2B6E5D2C3165332B4E756D626572286E292C727C7C';
wwv_flow_imp.g_varchar2_table(665) := '223C773A7250723E3C2F773A7250723E22297D293B6966286F213D3D742E6C656E677468297468726F77206E6577204572726F722822576F72643A206E6F207365207075646965726F6E20636F6C6F63617220746F646F73206C6F732063616D706F7320';
wwv_flow_imp.g_varchar2_table(666) := '64656C20666F726D756C6172696F2028222B6F2B2220646520222B742E6C656E6774682B22292E22293B72657475726E20652E66696C652822776F72642F646F63756D656E742E786D6C222C69292C652E66696C652822776F72642F73657474696E6773';
wwv_flow_imp.g_varchar2_table(667) := '2E786D6C222C66756E6374696F6E28652C74297B696628653D652E7265706C616365282F3C773A646F63756D656E7450726F74656374696F6E5B5E3E5D2A5C2F3E2F672C2222292C21742E70726F746563742972657475726E20653B76617220723D273C';
wwv_flow_imp.g_varchar2_table(668) := '773A646F63756D656E7450726F74656374696F6E20773A656469743D22666F726D732220773A656E666F7263656D656E743D223122273B696628742E70617373776F7264297B766172206E3D66756E6374696F6E2865297B76617220743D6E6577205569';
wwv_flow_imp.g_varchar2_table(669) := '6E743841727261792865292C723D22756E646566696E656422213D747970656F662077696E646F7726262877696E646F772E63727970746F7C7C77696E646F772E6D7343727970746F293B696628722626722E67657452616E646F6D56616C7565732972';
wwv_flow_imp.g_varchar2_table(670) := '2E67657452616E646F6D56616C7565732874293B656C736520666F7228766172206E3D303B6E3C653B6E2B2B29745B6E5D3D4D6174682E666C6F6F72283235362A4D6174682E72616E646F6D2829293B72657475726E20747D283136292C6F3D3165353B';
wwv_flow_imp.g_varchar2_table(671) := '722B3D2720773A637279707450726F7669646572547970653D227273614145532220773A6372797074416C676F726974686D436C6173733D22686173682220773A6372797074416C676F726974686D547970653D2274797065416E792220773A63727970';
wwv_flow_imp.g_varchar2_table(672) := '74416C676F726974686D5369643D2231342220773A63727970745370696E436F756E743D22272B6F2B272220773A686173683D22272B546528686528742E70617373776F72642C6E2C6F29292B272220773A73616C743D22272B5465286E292B2722277D';
wwv_flow_imp.g_varchar2_table(673) := '722B3D222F3E223B76617220613D5B223C773A6576656E416E644F646448656164657273222C223C773A636F6D706174222C223C2F773A73657474696E67733E225D2E6D61702866756E6374696F6E2874297B72657475726E20652E696E6465784F6628';
wwv_flow_imp.g_varchar2_table(674) := '74297D292E66696C7465722866756E6374696F6E2865297B72657475726E20653E3D307D295B305D3B72657475726E20652E73756273747228302C61292B722B652E7375627374722861297D286E5B315D2C7229292C652E67656E65726174654173796E';
wwv_flow_imp.g_varchar2_table(675) := '63287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D297D297D297D28742C692C616528652C7229297D293A427D766172';
wwv_flow_imp.g_varchar2_table(676) := '2071653D22E29FA64E52463A222C59653D22E29FA7223B66756E6374696F6E205A652865297B72657475726E20537472696E672865292E7265706C616365282F262F672C2226616D703B22292E7265706C616365282F3C2F672C22266C743B22292E7265';
wwv_flow_imp.g_varchar2_table(677) := '706C616365282F3E2F672C222667743B22292E7265706C616365282F222F672C222671756F743B22297D7661722058653D7B7D3B66756E6374696F6E204A652865297B76617220743D652E73706C697428227C22292C723D745B305D2E7472696D28292C';
wwv_flow_imp.g_varchar2_table(678) := '6E3D745B315D3F745B315D2E7472696D28293A6E756C6C3B72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E223D3D3D722972657475726E20653B666F7228766172206F3D722E73706C697428222E22292C613D742626742E73';
wwv_flow_imp.g_varchar2_table(679) := '636F70654C6973743F742E73636F70654C6973742E736C69636528292E7265766572736528293A5B655D2C693D303B693C612E6C656E6774683B692B2B297B666F7228766172206C3D615B695D2C753D21302C733D303B733C6F2E6C656E6774683B732B';
wwv_flow_imp.g_varchar2_table(680) := '2B297B69662841727261792E69734172726179286C292626733E302626286C3D6C5B305D292C6E756C6C3D3D6C7C7C226F626A65637422213D747970656F66206C7C7C21286F5B735D696E206C29297B753D21313B627265616B7D6C3D6C5B6F5B735D5D';
wwv_flow_imp.g_varchar2_table(681) := '7D696628752972657475726E206E26262141727261792E69734172726179286C293F70286C2C6E293A6C7D7D7D7D66756E6374696F6E204B6528652C74297B76617220723D6E65772077696E646F772E50697A5A69702865292C6E3D6E657728302C7769';
wwv_flow_imp.g_varchar2_table(682) := '6E646F772E646F637874656D706C617465722928722C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A4A652C6E756C6C4765747465723A66756E6374696F6E28297B72657475726E22227D7D293B7265';
wwv_flow_imp.g_varchar2_table(683) := '7475726E206E2E72656E6465722866756E6374696F6E2865297B76617220742C723D7B7D3B666F72287420696E20652E706172616D737C7C7B7D29725B745D3D652E706172616D735B745D3B666F72287420696E20652E646F637C7C7B7D29725B745D3D';
wwv_flow_imp.g_varchar2_table(684) := '652E646F635B745D3B666F72287420696E20652E5329725B745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D7328292C722E544F4441593D6328292C';
wwv_flow_imp.g_varchar2_table(685) := '727D287429292C50726F6D6973652E7265736F6C7665286E2E6765745A697028292E67656E6572617465287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445227D29297D66756E6374696F6E20516528';
wwv_flow_imp.g_varchar2_table(686) := '65297B76617220743D7B7D2C723D7B7D3B72657475726E204F626A6563742E6B65797328657C7C7B7D292E666F72456163682866756E6374696F6E286E297B766172206F3D655B6E5D2C613D6F2E636F6C737C7C5B5D3B725B6E5D3D7B7D2C612E666F72';
wwv_flow_imp.g_varchar2_table(687) := '456163682866756E6374696F6E2865297B725B6E5D5B652E6E616D655D3D652E747970657D292C745B6E5D3D286F2E726F77737C7C5B5D292E6D61702866756E6374696F6E2865297B76617220743D7B7D3B72657475726E20612E666F72456163682866';
wwv_flow_imp.g_varchar2_table(688) := '756E6374696F6E28722C6E297B745B722E6E616D655D3D655B6E5D7D292C747D297D292C7B533A742C543A727D7D66756E6374696F6E20657428652C74297B76617220723D652E532E444F43533B69662821722972657475726E5B7B533A652E532C543A';
wwv_flow_imp.g_varchar2_table(689) := '652E542C646F633A7B7D2C706172616D733A747D5D3B766172206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B69662822444F435322213D3D7426264F626A6563742E70726F';
wwv_flow_imp.g_varchar2_table(690) := '746F747970652E6861734F776E50726F70657274792E63616C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B745D3D7B7D3B652E535B745D2E666F72456163682866756E6374696F6E2865297B76617220743D537472696E6728';
wwv_flow_imp.g_varchar2_table(691) := '652E444F435F4B4559293B28725B745D3D725B745D7C7C5B5D292E707573682865297D297D7D292C722E6D61702866756E6374696F6E2872297B766172206F3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866';
wwv_flow_imp.g_varchar2_table(692) := '756E6374696F6E2874297B6F5B745D3D6E5B745D3F6E5B745D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B745D7D292C6F2E444F43533D5B725D2C7B533A6F2C543A652E542C646F633A722C706172616D733A747D7D297D6675';
wwv_flow_imp.g_varchar2_table(693) := '6E6374696F6E2074742865297B76617220743D646F63756D656E742E676574456C656D656E744279496428226E722D6176616E636522293B653F28747C7C2828743D646F63756D656E742E637265617465456C656D656E7428226469762229292E69643D';
wwv_flow_imp.g_varchar2_table(694) := '226E722D6176616E6365222C742E7365744174747269627574652822726F6C65222C2273746174757322292C742E7374796C652E637373546578743D22706F736974696F6E3A66697865643B72696768743A323470783B626F74746F6D3A323470783B7A';
wwv_flow_imp.g_varchar2_table(695) := '2D696E6465783A313030303B70616464696E673A3134707820313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A653A313370783B626F782D736861';
wwv_flow_imp.g_varchar2_table(696) := '646F773A30203870782032347078207267626128302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287429292C742E696E6E657248544D4C3D273C7370616E20636C61';
wwv_flow_imp.g_varchar2_table(697) := '73733D2266612066612D7370696E6E65722066612D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B263C3E225D2F672C66756E6374';
wwv_flow_imp.g_varchar2_table(698) := '696F6E2865297B72657475726E7B2226223A2226616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B655D7D29293A742626742E72656D6F766528297D66756E6374696F6E20727428652C74297B69';
wwv_flow_imp.g_varchar2_table(699) := '662865262621652E636C6F736564297472797B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F616465724D73672977696E646F772E636F744C6F616465724D736728652C74293B656C73657B76617220723D652E64';
wwv_flow_imp.g_varchar2_table(700) := '6F63756D656E742E676574456C656D656E744279496428226D736722293B72262628722E74657874436F6E74656E743D74297D7D63617463682865297B7D7D66756E6374696F6E206E7428652C74297B7472797B77696E646F772E617065782626617065';
wwv_flow_imp.g_varchar2_table(701) := '782E6576656E742626617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C74297D63617463682865297B7D7D66756E6374696F6E206F742865297B77696E646F772E617065782626617065782E';
wwv_flow_imp.g_varchar2_table(702) := '6D6573736167653F617065782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D66756E6374696F6E2061742865297B77696E646F772E617065782626617065782E6D6573736167652626617065782E6D657373616765';
wwv_flow_imp.g_varchar2_table(703) := '2E73686F7750616765537563636573732865297D7661722069743D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E';
wwv_flow_imp.g_varchar2_table(704) := '742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F726470726F63657373696E676D6C2E646F63756D656E74';
wwv_flow_imp.g_varchar2_table(705) := '227D2C6C743D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E20757428652C742C72297B766172206E3D4528652E66696C654E61';
wwv_flow_imp.g_varchar2_table(706) := '6D657C7C227265706F727465222C74292C6F3D6C745B725D3B72657475726E2068286E3D6E2E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C222229292B222E222B6F7D66756E6374696F6E20737428652C742C722C6E297B';
wwv_flow_imp.g_varchar2_table(707) := '72657475726E22706466223D3D3D653F5F6528742C722C6E2E686F6F6B73293A22786C7378223D3D3D653F576528742C722C722E6C656E6774682C6E293A22646F6378223D3D3D653F566528742C722C6E293A22646F63782D74656D706C617465223D3D';
wwv_flow_imp.g_varchar2_table(708) := '3D653F286F3D6E2E74656D706C61746555726C2C6F3F286F3D7865286F292C58655B6F5D3F50726F6D6973652E7265736F6C76652858655B6F5D293A6665746368286F2C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E746865';
wwv_flow_imp.g_varchar2_table(709) := '6E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20646573636172676172206C6120706C616E74696C6C612028222B652E7374617475732B222922293B72657475726E20652E';
wwv_flow_imp.g_varchar2_table(710) := '617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B72657475726E2058655B6F5D3D652C657D29293A50726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C612055524C206465206C612070';
wwv_flow_imp.g_varchar2_table(711) := '6C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C6120576F726422292E272929292E7468656E2866756E6374696F6E2865297B72657475726E204B6528652C725B305D297D293A50726F6D6973652E72656A656374286E';
wwv_flow_imp.g_varchar2_table(712) := '6577204572726F722822466F726D61746F206E6F20736F706F727461646F3A20222B6529293B766172206F7D66756E6374696F6E20637428652C74297B76617220722C6E2C6F3D687428652E6C61796F7574292C613D7B7D3B666F72287220696E206529';
wwv_flow_imp.g_varchar2_table(713) := '615B725D3D655B725D3B72657475726E20612E6C61796F75743D6F2C286E3D6F2C50726F6D6973652E616C6C2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(714) := '74696F6E2865297B65262622696D6167656E223D3D3D652E747970652626652E75726C262621652E6669656C642626742E7075736828652E75726C292C65262622636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F';
wwv_flow_imp.g_varchar2_table(715) := '72456163682872297D297D72657475726E207228652E73656374696F6E73292C652E62617463682626652E62617463682E73756D6D6172792626287228652E62617463682E73756D6D6172792E73656374696F6E73292C652E62617463682E73756D6D61';
wwv_flow_imp.g_varchar2_table(716) := '72792E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F75742E73656374696F6E7329292C747D286E292E6D61702866756E6374696F6E2865297B76617220743D78652865293B72657475726E2062655B745D3F6E756C6C3A66';
wwv_flow_imp.g_varchar2_table(717) := '6574636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20636172676172206C6120';
wwv_flow_imp.g_varchar2_table(718) := '696D6167656E20222B742B222028222B652E7374617475732B222922293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B76617220723D45652865293B62655B745D3D7B6275663A652C773A72';
wwv_flow_imp.g_varchar2_table(719) := '2E772C683A722E682C6578743A722E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D722E6578743F226A706567223A22706E6722292B223B6261736536342C222B54652865297D7D297D2929292E7468656E2866756E63';
wwv_flow_imp.g_varchar2_table(720) := '74696F6E28297B72657475726E2066756E6374696F6E28652C74297B76617220723D687428652E6C61796F7574292C6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22';
wwv_flow_imp.g_varchar2_table(721) := '706466225D2C6F3D51652874292C613D6574286F2C652E706172616D737C7C7B7D292C693D652E6F75747075747C7C2266696C65223B69662821612E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F722865';
wwv_flow_imp.g_varchar2_table(722) := '2E656D7074794D6573736167657C7C722E656D7074794D6573736167657C7C224E6F20686179206461746F7320706172612067656E6572617220656C207265706F7274652E2229293B696628722E62617463682626722E62617463682E6D6178446F6373';
wwv_flow_imp.g_varchar2_table(723) := '2626612E6C656E6774683E722E62617463682E6D6178446F63732972657475726E2050726F6D6973652E72656A656374286E6577204572726F722822456C206C6F74652073757065726120656C206DC3A178696D6F20646520222B722E62617463682E6D';
wwv_flow_imp.g_varchar2_table(724) := '6178446F63732B2220646F63756D656E746F732E2229293B6966282266696C65223D3D3D692626313D3D3D612E6C656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D692626313D3D3D6E2E6C656E677468262622646F63782D';
wwv_flow_imp.g_varchar2_table(725) := '74656D706C61746522213D3D6E5B305D297B766172206C3D6E5B305D3B72657475726E207374286C2C722C612C65292E7468656E2866756E6374696F6E2874297B766172206E3D757428722C615B305D2C6C293B696628612E6C656E6774683E31297B76';
wwv_flow_imp.g_varchar2_table(726) := '617220693D722E6261746368262628722E62617463682E6D657267654E616D657C7C722E62617463682E7A69704E616D65297C7C722E66696C654E616D657C7C227265706F727465223B6E3D7574287B66696C654E616D653A537472696E672869292E72';
wwv_flow_imp.g_varchar2_table(727) := '65706C616365282F5C2E7A6970242F692C2222297D2C7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C6C297D72657475726E7B6B696E643A6C2C646174613A742C6E616D653A6E2C636F756E743A';
wwv_flow_imp.g_varchar2_table(728) := '612E6C656E6774687D7D297D76617220752C733D6E65772077696E646F772E4A535A69702C633D302C663D302C643D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C703D7B7D3B666F72287520696E20652E706172616D737C';
wwv_flow_imp.g_varchar2_table(729) := '7C7B7D29705B755D3D652E706172616D735B755D3B702E464F524D41544F3D6E2E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74656D706C617465';
wwv_flow_imp.g_varchar2_table(730) := '223A22776F7264227D5B6E5B305D5D3B766172206D3D7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A707D2C673D7B7D3B66756E6374696F6E207628652C74297B666F722876617220723D652C6E3D323B675B722E746F4C6F776572';
wwv_flow_imp.g_varchar2_table(731) := '4361736528295D3B29723D652E7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B6E2B22243122292C6E2B2B3B675B722E746F4C6F7765724361736528295D3D21302C732E66696C6528722C74292C632B2B7D76617220773D50726F6D6973';
wwv_flow_imp.g_varchar2_table(732) := '652E7265736F6C766528292C623D722E62617463682626722E62617463682E73756D6D6172793B622626227A6970223D3D3D69262628773D6E2E66696C7465722866756E6374696F6E2865297B72657475726E22646F63782D74656D706C61746522213D';
wwv_flow_imp.g_varchar2_table(733) := '3D657D292E7265647563652866756E6374696F6E28742C6E297B72657475726E20742E7468656E2866756E6374696F6E28297B76617220743D622E6C61796F75747C7C7B706167653A722E706167652C666F6F7465723A622E666F6F7465727C7C722E66';
wwv_flow_imp.g_varchar2_table(734) := '6F6F7465722C73656374696F6E733A622E73656374696F6E732C786C73783A622E786C73782C66696C654E616D653A622E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E66696C654E616D653D622E66696C654E616D65';
wwv_flow_imp.g_varchar2_table(735) := '7C7C2230305F726573756D656E22292C7374286E2C742C5B6D5D2C65292E7468656E2866756E6374696F6E2865297B7628757428742C6D2C6E292C65297D297D297D2C7729293B72657475726E20772E7468656E2866756E6374696F6E28297B72657475';
wwv_flow_imp.g_varchar2_table(736) := '726E206E65772050726F6D6973652866756E6374696F6E28742C6F297B66756E6374696F6E206928297B666F7228766172206C3D4D6174682E6D696E28662B642C612E6C656E677468292C753D50726F6D6973652E7265736F6C766528293B663C6C3B66';
wwv_flow_imp.g_varchar2_table(737) := '2B2B292866756E6374696F6E2874297B6E2E666F72456163682866756E6374696F6E286E297B753D752E7468656E2866756E6374696F6E28297B72657475726E207374286E2C722C5B745D2C65292E7468656E2866756E6374696F6E2865297B76287574';
wwv_flow_imp.g_varchar2_table(738) := '28722C742C6E292C65297D297D297D297D2928615B665D293B752E7468656E2866756E6374696F6E28297B652E6F6E50726F67726573732626652E6F6E50726F677265737328662C612E6C656E677468292C663C612E6C656E6774683F73657454696D65';
wwv_flow_imp.g_varchar2_table(739) := '6F757428692C30293A28652E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C63292C732E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D7072657373696F6E3A224445464C';
wwv_flow_imp.g_varchar2_table(740) := '415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374696F6E2865297B766172206E3D4528722E62617463682626722E62617463682E7A69704E616D657C7C227265706F727465732E7A6970';
wwv_flow_imp.g_varchar2_table(741) := '222C6D293B74287B6B696E643A227A6970222C646174613A652C6E616D653A68282F5C2E7A6970242F692E74657374286E293F6E3A6E2B222E7A697022292C636F756E743A612E6C656E6774682C66696C65733A637D297D2C6F29297D2C6F297D736574';
wwv_flow_imp.g_varchar2_table(742) := '54696D656F757428692C30297D297D297D28612C74297D297D66756E6374696F6E2066742865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B6526262822636F6469';
wwv_flow_imp.g_varchar2_table(743) := '676F223D3D3D652E747970652626227172223D3D3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292626742E696E6465784F6628227172636F646522293C302626742E7075736828227172636F646522292C226772';
wwv_flow_imp.g_varchar2_table(744) := '616669636F223D3D3D652E747970652626742E696E6465784F66282263686172746A7322293C302626742E70757368282263686172746A7322292C22666F726D756C6172696F223D3D3D652E747970652626742E696E6465784F6628226A737A69702229';
wwv_flow_imp.g_varchar2_table(745) := '3C302626742E7075736828226A737A697022292C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F7245616368287229297D297D7228652E73656374696F6E73293B766172206E3D652E62617463682626652E62';
wwv_flow_imp.g_varchar2_table(746) := '617463682E73756D6D6172793B72657475726E206E26262872286E2E73656374696F6E73292C6E2E6C61796F7574262672286E2E6C61796F75742E73656374696F6E7329292C747D66756E6374696F6E20647428652C74297B69662822737472696E6722';
wwv_flow_imp.g_varchar2_table(747) := '3D3D747970656F66206526262240223D3D3D652E6368617241742830292626742626766F69642030213D3D745B652E7375627374722831295D2972657475726E20647428745B652E7375627374722831295D2C74293B69662841727261792E6973417272';
wwv_flow_imp.g_varchar2_table(748) := '61792865292972657475726E20652E7265647563652866756E6374696F6E28652C72297B766172206E3D22737472696E67223D3D747970656F66207226262240223D3D3D722E636861724174283029262674262641727261792E6973417272617928745B';
wwv_flow_imp.g_varchar2_table(749) := '722E7375627374722831295D292C6F3D647428722C74293B72657475726E206E3F652E636F6E636174286F293A652E636F6E636174285B6F5D297D2C5B5D293B696628652626226F626A656374223D3D747970656F662065297B76617220723D7B7D3B72';
wwv_flow_imp.g_varchar2_table(750) := '657475726E204F626A6563742E6B6579732865292E666F72456163682866756E6374696F6E286E297B725B6E5D3D2264656673223D3D3D6E3F655B6E5D3A647428655B6E5D2C74297D292C727D72657475726E20657D66756E6374696F6E206874286529';
wwv_flow_imp.g_varchar2_table(751) := '7B76617220743B696628652626226F626A656374223D3D747970656F66206529743D653B656C73657B76617220723D537472696E6728657C7C2222292E7472696D28293B696628227B223D3D3D722E63686172417428302929743D4A534F4E2E70617273';
wwv_flow_imp.g_varchar2_table(752) := '652872293B656C7365206966282128743D722E73706C697428222E22292E7265647563652866756E6374696F6E28652C74297B72657475726E20653F655B745D3A766F696420307D2C77696E646F772929297468726F77206E6577204572726F7228224E';
wwv_flow_imp.g_varchar2_table(753) := '6F20736520656E636F6E7472C3B320656C2064697365C3B16F3A20222B72297D72657475726E20647428742C742E64656673297D66756E6374696F6E2070742865297B69662865297B69662841727261792E697341727261792865297C7C22737472696E';
wwv_flow_imp.g_varchar2_table(754) := '6722213D747970656F6620657C7C2F5B232E5C5B5D2F2E746573742865292972657475726E20653B76617220743D652E73706C697428222C22292E6D61702866756E6374696F6E2865297B72657475726E20652E7472696D28297D292E66696C74657228';
wwv_flow_imp.g_varchar2_table(755) := '426F6F6C65616E293B72657475726E20742E6C656E6774683F743A766F696420307D7D66756E6374696F6E206D742865297B766172206E2C6F3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E';
wwv_flow_imp.g_varchar2_table(756) := '666F726D61747C7C22706466225D2C613D313D3D3D6F2E6C656E677468262622706466223D3D3D6F5B305D2626227A697022213D3D652E6F7574707574262622646F776E6C6F616422213D3D652E706466416374696F6E2C693D6126262131213D3D652E';
wwv_flow_imp.g_varchar2_table(757) := '6C6F616465723F66756E6374696F6E2865297B76617220743D77696E646F772E6F70656E2822222C225F626C616E6B22293B69662821742972657475726E206E756C6C3B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F74';
wwv_flow_imp.g_varchar2_table(758) := '4C6F61646572297472797B77696E646F772E636F744C6F616465722874293B76617220723D742E646F63756D656E742E676574456C656D656E747342795461674E616D652822683122295B305D3B72262628722E74657874436F6E74656E743D2247656E';
wwv_flow_imp.g_varchar2_table(759) := '6572616E646F207265706F72746522297D63617463682865297B7D656C736520742E646F63756D656E742E777269746528273C21646F63747970652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C';
wwv_flow_imp.g_varchar2_table(760) := '7469746C653E47656E6572616E646F207265706F727465E280A63C2F7469746C653E3C7374796C653E626F64797B6D617267696E3A303B6865696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B';
wwv_flow_imp.g_varchar2_table(761) := '6A7573746966792D636F6E74656E743A63656E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D73657269663B6261636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69';
wwv_flow_imp.g_varchar2_table(762) := '676E3A63656E7465727D2E737B77696474683A353670783B6865696768743A353670783B626F726465723A35707820736F6C696420236436653065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A';
wwv_flow_imp.g_varchar2_table(763) := '3530253B616E696D6174696F6E3A72203173206C696E65617220696E66696E6974653B6D617267696E3A30206175746F20313870787D406B65796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B66';
wwv_flow_imp.g_varchar2_table(764) := '6F6E742D73697A653A323070783B6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A233562366237627D3C2F7374796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C617373';
wwv_flow_imp.g_varchar2_table(765) := '3D2273223E3C2F6469763E3C68313E47656E6572616E646F207265706F7274653C2F68313E3C702069643D226D7367223E3C2F703E3C2F6469763E3C2F626F64793E3C2F68746D6C3E27292C742E646F63756D656E742E636C6F736528293B7265747572';
wwv_flow_imp.g_varchar2_table(766) := '6E20727428742C65292C747D28652E6D6573736167657C7C22436F6E73756C74616E646F206461746F73E280A622293A6E756C6C2C6C3D77696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E73686F775370696E6E657228';
wwv_flow_imp.g_varchar2_table(767) := '293A6E756C6C2C753D227265736F6C766572223D3D3D652E6F726967696E262621652E646174613B6966282175297472797B6E3D687428652E6C61796F7574297D63617463682865297B72657475726E206C26266C2E72656D6F766528292C692626692E';
wwv_flow_imp.g_varchar2_table(768) := '636C6F736528292C6F74282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765292C50726F6D6973652E72656A6563742865297D76617220733D7B6C61796F75743A6E2C666F726D61743A652E666F726D61742C6F7574707574';
wwv_flow_imp.g_varchar2_table(769) := '3A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D706C61746555726C2C686F6F6B733A652E686F6F6B737C7C7B7D2C666F726D50617373776F72643A652E666F726D50617373776F72';
wwv_flow_imp.g_varchar2_table(770) := '647D3B6E7428227374617274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C7265706F72743A753F652E7265706F72743A766F696420307D293B76617220633D722866756E6374696F6E28652C72297B76617220';
wwv_flow_imp.g_varchar2_table(771) := '6E3D5B5D3B72657475726E20652E666F72456163682866756E6374696F6E2865297B28745B655D7C7C5B5D292E666F72456163682866756E6374696F6E2865297B6E2E696E6465784F662865293C3026266E2E707573682865297D297D292C7226266E2E';
wwv_flow_imp.g_varchar2_table(772) := '7075736828226A737A697022292C6E7D286F2C226D6572676522213D3D652E6F7574707574292E636F6E63617428753F5B5D3A6674286E2929292C663D652E646174613F50726F6D6973652E7265736F6C7665287B646174613A652E646174617D293A6E';
wwv_flow_imp.g_varchar2_table(773) := '65772050726F6D6973652866756E6374696F6E28742C72297B766172206E3D7B7830313A4A534F4E2E737472696E6769667928732E706172616D73292C7830323A227A6970223D3D3D652E6F75747075743F2259223A224E222C706167654974656D733A';
wwv_flow_imp.g_varchar2_table(774) := '707428652E6974656D73297D3B69662875297B696628766F696420303D3D3D652E7265706F72747C7C6E756C6C3D3D3D652E7265706F72747C7C22223D3D3D652E7265706F72742972657475726E20766F69642072286E6577204572726F722822496E64';
wwv_flow_imp.g_varchar2_table(775) := '6971756520656C207265706F72746520612067656E657261722028646174612D7265706F7274292E2229293B6E2E7830333D537472696E6728652E7265706F7274297D617065782E7365727665722E706C7567696E28652E616A61784964656E74696669';
wwv_flow_imp.g_varchar2_table(776) := '65722C6E2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B652626652E6F6B3F742865293A72286E6577204572726F7228652626652E6D73677C7C224572726F7220616C206F6274656E6572206C6F73206461';
wwv_flow_imp.g_varchar2_table(777) := '746F732E2229297D2C66756E6374696F6E28652C742C6E297B72286E6577204572726F7228224572726F7220646520636F6D756E6963616369C3B36E3A20222B286E7C7C742929297D297D293B72657475726E2050726F6D6973652E616C6C285B662C63';
wwv_flow_imp.g_varchar2_table(778) := '5D292E7468656E2866756E6374696F6E2865297B76617220743D655B305D2C6F3D50726F6D6973652E7265736F6C766528293B69662875297B7472797B6E3D687428742E6C61796F7574297D63617463682865297B7468726F77206E6577204572726F72';
wwv_flow_imp.g_varchar2_table(779) := '282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D732E6C61796F75743D6E2C742E706172616D73262628732E706172616D733D742E706172616D73292C742E74656D706C61746555726C262628732E74656D706C6174';
wwv_flow_imp.g_varchar2_table(780) := '6555726C3D742E74656D706C61746555726C292C6F3D72286674286E29297D72657475726E206F2E7468656E2866756E6374696F6E28297B72657475726E20742E646174617D297D292E7468656E2866756E6374696F6E2874297B6C2626286C2E72656D';
wwv_flow_imp.g_varchar2_table(781) := '6F766528292C6C3D6E756C6C293B76617220723D652E7472616E73666F726D2626652E7472616E73666F726D2874297C7C743B72657475726E20727428692C2241726D616E646F20656C20646F63756D656E746FE280A622292C732E6F6E50726F677265';
wwv_flow_imp.g_varchar2_table(782) := '73733D66756E6374696F6E28652C74297B2D313D3D3D653F74742822436F6D7072696D69656E646F20222B742B22206172636869766F73E280A622293A287474282247656E6572616E646F20222B652B2220646520222B742B22E280A622292C6E742822';
wwv_flow_imp.g_varchar2_table(783) := '70726F6772657373222C7B646F6E653A652C746F74616C3A747D29297D2C637428732C72297D292E7468656E2866756E6374696F6E2874297B76617220723D652E736176657C7C732E6C61796F75742626732E6C61796F75742E736176653B6966282172';
wwv_flow_imp.g_varchar2_table(784) := '7C7C21722E70726F636573732972657475726E20743B6966282177696E646F772E617065787C7C21617065782E736572766572297468726F77206E6577204572726F7228224775617264617220656E20656C207365727669646F72207265717569657265';
wwv_flow_imp.g_varchar2_table(785) := '20415045582E22293B72657475726E20747428224775617264616E646F20656E20656C207365727669646F72E280A622292C66756E6374696F6E28652C742C72297B766172206E3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F';
wwv_flow_imp.g_varchar2_table(786) := '7A6970223A69745B652E6B696E645D7C7C69742E646F63782C6F3D652E6461746120696E7374616E63656F6620426C6F623F652E646174613A6E657720426C6F62285B652E646174615D2C7B747970653A6E7D293B72657475726E206E65772050726F6D';
wwv_flow_imp.g_varchar2_table(787) := '6973652866756E6374696F6E28612C69297B766172206C3D6E65772046696C655265616465723B6C2E6F6E6572726F723D66756E6374696F6E28297B69286E6577204572726F7228224E6F207365207075646F206C65657220656C206172636869766F20';
wwv_flow_imp.g_varchar2_table(788) := '67656E657261646F2E2229297D2C6C2E6F6E6C6F61643D66756E6374696F6E28297B766172206F2C753D537472696E67286C2E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292C733D5B5D3B666F72286F3D303B6F';
wwv_flow_imp.g_varchar2_table(789) := '3C752E6C656E6774683B6F2B3D33653429732E7075736828752E737562737472286F2C33653429293B617065782E7365727665722E70726F6365737328742E70726F636573732C7B7830313A652E6E616D652C7830323A6E2C7830333A766F696420303D';
wwv_flow_imp.g_varchar2_table(790) := '3D3D722E7265706F72743F22223A537472696E6728722E7265706F7274292C7830343A4A534F4E2E737472696E6769667928722E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A737D2C7B64617461547970653A226A736F6E227D29';
wwv_flow_imp.g_varchar2_table(791) := '2E7468656E2866756E6374696F6E2865297B65262621313D3D3D652E6F6B3F69286E6577204572726F7228652E6D73677C7C22456C207365727669646F72206E6F206775617264C3B320656C20646F63756D656E746F2E2229293A6128657C7C7B7D297D';
wwv_flow_imp.g_varchar2_table(792) := '2C66756E6374696F6E28652C742C72297B69286E6577204572726F7228224E6F207365207075646F206775617264617220656E20656C207365727669646F723A20222B28727C7C742929297D297D2C6C2E7265616441734461746155524C286F297D297D';
wwv_flow_imp.g_varchar2_table(793) := '28742C722C7B7265706F72743A652E7265706F72742C706172616D733A732E706172616D737D292E7468656E2866756E6374696F6E2865297B72657475726E20742E73617665643D652C742E6F6E6C793D226F6E6C79223D3D3D722E6D6F64652C6E7428';
wwv_flow_imp.g_varchar2_table(794) := '227361766564222C7B6E616D653A742E6E616D652C6B696E643A742E6B696E642C726573706F6E73653A657D292C747D297D292E7468656E2866756E6374696F6E2865297B696628747428292C652E6F6E6C7929692626692E636C6F736528292C617428';
wwv_flow_imp.g_varchar2_table(795) := '652E73617665642626652E73617665642E6D73677C7C22446F63756D656E746F20677561726461646F3A20222B652E6E616D65293B656C73652069662822706466223D3D3D652E6B696E64262661297B76617220743D55524C2E6372656174654F626A65';
wwv_flow_imp.g_varchar2_table(796) := '637455524C286E657720426C6F62285B652E646174615D2C7B747970653A69742E7064667D29293B69262621692E636C6F7365643F692E6C6F636174696F6E2E687265663D743A77696E646F772E6F70656E28742C225F626C616E6B22297D656C736520';
wwv_flow_imp.g_varchar2_table(797) := '692626692E636C6F736528292C723D652E646174612C6E3D652E6E616D652C6F3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A69745B652E6B696E645D7C7C69742E646F63782C6C3D7220696E7374616E63656F66';
wwv_flow_imp.g_varchar2_table(798) := '20426C6F623F723A6E657720426C6F62285B725D2C7B747970653A6F7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D292C28753D646F63756D656E742E637265617465456C656D656E742822612229292E687265663D55524C2E';
wwv_flow_imp.g_varchar2_table(799) := '6372656174654F626A65637455524C286C292C752E646F776E6C6F61643D6E2C646F63756D656E742E626F64792E617070656E644368696C642875292C752E636C69636B28292C73657454696D656F75742866756E6374696F6E28297B55524C2E726576';
wwv_flow_imp.g_varchar2_table(800) := '6F6B654F626A65637455524C28752E68726566292C752E72656D6F766528297D2C346533292C227A6970223D3D3D652E6B696E642626617428225A49502067656E657261646F3A20222B652E66696C65732B22206172636869766F7320646520222B652E';
wwv_flow_imp.g_varchar2_table(801) := '636F756E742B2220646F63756D656E746F732E22293B76617220722C6E2C6F2C6C2C753B72657475726E206E742822656E64222C7B6E616D653A652E6E616D652C636F756E743A652E636F756E742C66696C65733A652E66696C65737D292C657D292E63';
wwv_flow_imp.g_varchar2_table(802) := '617463682866756E6374696F6E2865297B7468726F77206C26266C2E72656D6F766528292C747428292C69262621692E636C6F7365642626692E636C6F736528292C77696E646F772E636F6E736F6C652626636F6E736F6C652E6572726F722865292C6E';
wwv_flow_imp.g_varchar2_table(803) := '7428226572726F72222C7B6D6573736167653A652E6D6573736167657D292C6F7428652E6D6573736167657C7C224E6F207365207075646F2067656E6572617220656C207265706F7274652E22292C657D297D7661722067743D21312C76743D6E756C6C';
wwv_flow_imp.g_varchar2_table(804) := '3B72657475726E22756E646566696E656422213D747970656F6620646F63756D656E742626646F63756D656E742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C6675';
wwv_flow_imp.g_varchar2_table(805) := '6E6374696F6E2865297B76743D652E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D2C5B646174612D666F726D61745D22297C7C65';
wwv_flow_imp.g_varchar2_table(806) := '2E7461726765747D2C2130292C7B76657273696F6E3A22312E31322E30222C6C6962733A652C72756E3A6D742C64613A66756E6374696F6E2865297B76617220743D746869732626746869732E616374696F6E3F746869733A7B7D2C723D742E61637469';
wwv_flow_imp.g_varchar2_table(807) := '6F6E7C7C7B7D2C6E3D742E74726967676572696E67456C656D656E747C7C76742C6F3D742E62726F777365724576656E743B6966286F26266F2E70726576656E7444656661756C7426266F2E70726576656E7444656661756C7428292C216774297B7661';
wwv_flow_imp.g_varchar2_table(808) := '7220613D652626226F626A656374223D3D747970656F6620653F653A7B7D2C693D2266756E6374696F6E223D3D747970656F6620653F653A612E696E69742C6C3D7B7D2C753D6E26266E2E646174617365747C7C7B7D2C733D612E7265706F72742C633D';
wwv_flow_imp.g_varchar2_table(809) := '612E6F75747075747C7C722E61747472696275746530337C7C2266696C65222C663D612E666F726D61747C7C722E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732875292E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(810) := '226F757470757422213D3D653F22666F726D617422213D3D653F227265706F727422213D3D653F6C5B652E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D755B655D3A733D755B655D3A663D755B';
wwv_flow_imp.g_varchar2_table(811) := '655D3A633D755B655D7D293B76617220643D7B6C61796F75743A612E6C61796F75747C7C722E61747472696275746530312C666F726D61743A662C6F75747075743A632C6974656D733A612E6974656D737C7C722E61747472696275746530347C7C2222';
wwv_flow_imp.g_varchar2_table(812) := '2C706466416374696F6E3A612E706466416374696F6E7C7C722E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A612E74656D706C61746555726C7C7C722E61747472696275746530362C6D6573736167653A612E6D6573';
wwv_flow_imp.g_varchar2_table(813) := '736167657C7C722E61747472696275746530372C706172616D733A6C2C616A61784964656E7469666965723A612E616A61784964656E7469666965727C7C722E616A61784964656E7469666965722C6F726967696E3A612E6F726967696E7C7C22617474';
wwv_flow_imp.g_varchar2_table(814) := '72696275746573222C7265706F72743A732C736176653A612E736176657D3B6966282266756E6374696F6E223D3D747970656F662069297B76617220683D692864293B69662821313D3D3D682972657475726E3B643D687C7C647D67743D21302C6D7428';
wwv_flow_imp.g_varchar2_table(815) := '64292E7468656E2866756E6374696F6E28297B67743D21317D2C66756E6374696F6E28297B67743D21317D297D7D2C6275696C643A63742C656E737572653A722C6C61796F75744C6962733A66742C5F696E7465726E616C733A7B494D473A62652C696D';
wwv_flow_imp.g_varchar2_table(816) := '6744696D733A45652C74706C3A452C636F6E643A532C666D743A702C6E6F726D616C697A653A51652C636F6E74657874733A65742C636F64653132383A6A652C706E67313A46652C6C61796F75744C6962733A66742C7368613531323A73652C776F7264';
wwv_flow_imp.g_varchar2_table(817) := '4C65676163794B65793A64652C776F7264486173683A68652C666F726D4E616D653A74657D7D7D28293B';
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
