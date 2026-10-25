
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
,p_default_application_id=>116
,p_default_id_offset=>0
,p_default_owner=>'WKSP_AQS'
);
end;
/

prompt APPLICATION 116 - Cotizador
--
-- Application Export:
--   Application:     116
--   Name:            Cotizador
--   Exported By:     WKSP_AQS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 32000000000000001
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
 p_id=>wwv_flow_imp.id(32000000000000001)
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
,p_version_identifier=>'1.11.0'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>19
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000019)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
,p_help_text=>unistr('<p><b>Atributos</b>: las fuentes SQL y el dise\00F1o se configuran en esta acci\00F3n.</p><p><b>Resolver</b>: el navegador solo env\00EDa el ID del reporte (<code>data-report</code> u <code>o.report</code> en Initialization Code) y los par\00E1metros; una funci\00F3n PL/SQL valida el acceso y devuelve fuentes y dise\00F1o. Nunca se acepta SQL desde el navegador.</p>')
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000061)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_display_sequence=>10
,p_display_value=>unistr('Atributos (fuentes y dise\00F1o aqu\00ED)')
,p_return_value=>'attributes'
,p_apexlang_name=>'atributos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000062)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_display_sequence=>20
,p_display_value=>unistr('Resolver (funci\00F3n PL/SQL por ID de reporte)')
,p_return_value=>'resolver'
,p_apexlang_name=>'resolver'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000020)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>unistr('Funci\00F3n <code>f(p_id in varchar2, p_params in clob) return clob</code> que devuelve <code>{ "sources": "--@X ...", "layout": {...}, "params": {...}, "types": {"P": "text|number|date"} }</code>. Debe validar rol y par\00E1metros. Ver docs/API.md.')
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000013)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
 p_id=>wwv_flow_imp.id(32000000000000032)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>20
,p_display_value=>'Excel (.xlsx con estilos)'
,p_return_value=>'xlsx'
,p_apexlang_name=>'excelXlsxConEstilos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000031)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>10
,p_display_value=>'PDF'
,p_return_value=>'pdf'
,p_apexlang_name=>'pdf'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000035)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>50
,p_display_value=>'Todos (PDF + Excel + Word)'
,p_return_value=>'all'
,p_apexlang_name=>'todosPdfExcelWord'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000034)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>40
,p_display_value=>'Word desde plantilla'
,p_return_value=>'docx-template'
,p_apexlang_name=>'wordDesdePlantilla'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000033)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000013)
,p_display_sequence=>30
,p_display_value=>'Word (.docx)'
,p_return_value=>'docx'
,p_apexlang_name=>'wordDocx'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000015)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
 p_id=>wwv_flow_imp.id(32000000000000012)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'resolver'
,p_help_text=>unistr('Dise\00F1o en JSON (o el nombre de una variable JavaScript global con el dise\00F1o). Secciones: header, ficha, tabla, alerta, texto, salto. Plantillas {COL}, {FUENTE.COL}, {DOC.COL}, {ITEM.P1_X}, {NOW}, {PAGE}/{PAGES}; formatos {COL|money}, |int, |num:3, |p')
||'ct, |date, |upper. Reutilice bloques con "defs" y "@NOMBRE". Para Excel use "xlsx.sheets"; para lotes "batch" (zipName, summary, chunkSize, maxDocs).'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000018)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
 p_id=>wwv_flow_imp.id(32000000000000014)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
 p_id=>wwv_flow_imp.id(32000000000000041)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000014)
,p_display_sequence=>10
,p_display_value=>'Archivo (ZIP si hay varios documentos)'
,p_return_value=>'file'
,p_apexlang_name=>'archivoZipSiHayVariosDocumentos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000043)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000014)
,p_display_sequence=>30
,p_display_value=>'Un solo archivo con todos los documentos'
,p_return_value=>'merge'
,p_apexlang_name=>'unSoloArchivoConTodosLosDocumentos'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000042)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000014)
,p_display_sequence=>20
,p_display_value=>'ZIP: un archivo por documento + resumen'
,p_return_value=>'zip'
,p_apexlang_name=>'zipUnArchivoPorDocumentoResumen'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000016)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
 p_id=>wwv_flow_imp.id(32000000000000051)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000016)
,p_display_sequence=>10
,p_display_value=>unistr('Abrir en una pesta\00F1a nueva (con pantalla de espera)')
,p_return_value=>'open'
,p_apexlang_name=>'abrirEnUnaPestaaNuevaConPantallaDeEspera'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(32000000000000052)
,p_plugin_attribute_id=>wwv_flow_imp.id(32000000000000016)
,p_display_sequence=>20
,p_display_value=>'Descargar'
,p_return_value=>'download'
,p_apexlang_name=>'descargar'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(32000000000000011)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
,p_depending_on_attribute_id=>wwv_flow_imp.id(32000000000000019)
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
 p_id=>wwv_flow_imp.id(32000000000000017)
,p_plugin_id=>wwv_flow_imp.id(32000000000000001)
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
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E31312E30202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C';
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
wwv_flow_imp.g_varchar2_table(20) := '28742C72297B72657475726E20742E7468656E2866756E6374696F6E28297B72657475726E20655B725D2E6F6B28293F6E756C6C3A28743D6E6528655B725D2E75726C292C6E65772050726F6D6973652866756E6374696F6E28652C72297B766172206E';
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
wwv_flow_imp.g_varchar2_table(40) := '283130302A4D6174682E616273286529292C6F3D4D6174682E666C6F6F72286E2F313030292C613D6E253130302C693D78286F293B69662874297B2F284D494C4CC3934E7C4D494C4C4F4E45537C42494C4CC3934E7C42494C4C4F4E455329242F2E7465';
wwv_flow_imp.g_varchar2_table(41) := '7374286929262628692B3D2220444522293B766172206C3D537472696E672874292E746F55707065724361736528292E73706C697428222F22293B692B3D2220222B28313D3D3D6F26266C2E6C656E6774683E313F6C5B305D3A6C5B6C2E6C656E677468';
wwv_flow_imp.g_varchar2_table(42) := '2D315D297D656C736520693D692E7265706C616365282FC39A4E242F2C22554E4F22292E7265706C616365282F20554E247C5E554E242F2C66756E6374696F6E2865297B72657475726E20652B224F227D293B72657475726E28723F224D454E4F532022';
wwv_flow_imp.g_varchar2_table(43) := '3A2222292B692B2220434F4E20222B28613C31303F2230223A2222292B612B222F313030227D284E756D6265722865292C722E736C6963652831292E6A6F696E28223A2229293A537472696E672865297D66756E6374696F6E20672865297B7265747572';
wwv_flow_imp.g_varchar2_table(44) := '6E2F5E2875707065727C6C6F7765727C796E7C6C657472617329283A7C24292F2E7465737428657C7C2222297D766172206D3D5B22222C22554E222C22444F53222C2254524553222C2243554154524F222C2243494E434F222C2253454953222C225349';
wwv_flow_imp.g_varchar2_table(45) := '455445222C224F43484F222C224E55455645222C224449455A222C224F4E4345222C22444F4345222C225452454345222C224341544F524345222C225155494E4345222C22444945434953C3894953222C2244494543495349455445222C224449454349';
wwv_flow_imp.g_varchar2_table(46) := '4F43484F222C2244494543494E55455645222C225645494E5445222C225645494E5449C39A4E222C225645494E544944C39353222C225645494E54495452C38953222C225645494E544943554154524F222C225645494E544943494E434F222C22564549';
wwv_flow_imp.g_varchar2_table(47) := '4E544953C3894953222C225645494E54495349455445222C225645494E54494F43484F222C225645494E54494E55455645225D2C763D5B22222C22222C22222C22545245494E5441222C2243554152454E5441222C2243494E4355454E5441222C225345';
wwv_flow_imp.g_varchar2_table(48) := '53454E5441222C22534554454E5441222C224F4348454E5441222C224E4F56454E5441225D2C623D5B22222C224349454E544F222C22444F534349454E544F53222C22545245534349454E544F53222C2243554154524F4349454E544F53222C22515549';
wwv_flow_imp.g_varchar2_table(49) := '4E49454E544F53222C22534549534349454E544F53222C22534554454349454E544F53222C224F43484F4349454E544F53222C224E4F56454349454E544F53225D3B66756E6374696F6E20772865297B6966283130303D3D3D652972657475726E224349';
wwv_flow_imp.g_varchar2_table(50) := '454E223B76617220743D4D6174682E666C6F6F7228652F313030292C723D65253130302C6E3D5B5D3B72657475726E207426266E2E7075736828625B745D292C7226266E2E7075736828723C33303F6D5B725D3A765B4D6174682E666C6F6F7228722F31';
wwv_flow_imp.g_varchar2_table(51) := '30295D2B28722531303F22205920222B6D5B722531305D3A222229292C6E2E6A6F696E28222022297D66756E6374696F6E20782865297B696628303D3D3D652972657475726E224345524F223B76617220743D5B5D3B5B5B316531322C2242494C4CC393';
wwv_flow_imp.g_varchar2_table(52) := '4E222C2242494C4C4F4E4553225D2C5B3165362C224D494C4CC3934E222C224D494C4C4F4E4553225D5D2E666F72456163682866756E6374696F6E2872297B766172206E3D4D6174682E666C6F6F7228652F725B305D293B6E262628742E707573682831';
wwv_flow_imp.g_varchar2_table(53) := '3D3D3D6E3F22554E20222B725B315D3A78286E292B2220222B725B325D292C652D3D6E2A725B305D297D293B76617220723D4D6174682E666C6F6F7228652F316533292C6E3D65253165333B72657475726E20722626742E7075736828313D3D3D723F22';
wwv_flow_imp.g_varchar2_table(54) := '4D494C223A772872292B22204D494C22292C6E2626742E707573682877286E29292C742E6A6F696E28222022297D66756E6374696F6E207928652C742C72297B766172206E3D537472696E672874292E746F55707065724361736528292C6F3D6E2E696E';
wwv_flow_imp.g_varchar2_table(55) := '6465784F6628222E22293B6966286F3E30297B76617220613D6E2E73756273747228302C6F292C693D6E2E737562737472286F2B31293B69662822444F43223D3D3D612972657475726E20652E646F633F652E646F635B695D3A766F696420303B696628';
wwv_flow_imp.g_varchar2_table(56) := '22504152414D223D3D3D612972657475726E20652E706172616D733F652E706172616D735B695D3A766F696420303B696628224954454D223D3D3D612972657475726E2066756E6374696F6E2865297B7472797B72657475726E2077696E646F772E6170';
wwv_flow_imp.g_varchar2_table(57) := '65782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D63617463682865297B72657475726E22227D7D2869293B766172206C3D28652E535B615D7C7C5B5D295B305D3B72657475726E206C3F6C5B695D3A';
wwv_flow_imp.g_varchar2_table(58) := '766F696420307D72657475726E224E4F57223D3D3D6E3F7328293A22544F444159223D3D3D6E3F6328293A2250414745223D3D3D6E7C7C225041474553223D3D3D6E3F227B222B6E2B227D223A7226264F626A6563742E70726F746F747970652E686173';
wwv_flow_imp.g_varchar2_table(59) := '4F776E50726F70657274792E63616C6C28722C6E293F725B6E5D3A652E646F6326264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F652E646F635B6E5D3A652E706172616D733F652E';
wwv_flow_imp.g_varchar2_table(60) := '706172616D735B6E5D3A766F696420307D66756E6374696F6E204528652C742C72297B72657475726E206E756C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D7A302D395F24232E5D2B29283F3A5C7C285B41';
wwv_flow_imp.g_varchar2_table(61) := '2D5A612D7A302D393A2FC381C389C38DC393C39AC391C39CC3A1C3A9C3ADC3B3C3BAC3B1C3BC5D2B29293F5C7D2F672C66756E6374696F6E28652C6E2C6F297B76617220613D7928742C6E2C72293B72657475726E206E756C6C3D3D613F22223A702861';
wwv_flow_imp.g_varchar2_table(62) := '2C6F297D297D66756E6374696F6E205428652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E657865632865293B69';
wwv_flow_imp.g_varchar2_table(63) := '6628216E2972657475726E21313B766172206F3D7928742C6E5B325D2C72293B696628216E5B335D297B76617220613D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E223D3D3D6F293B72657475726E206E5B315D3F21613A617D';
wwv_flow_imp.g_varchar2_table(64) := '76617220692C6C3D28693D28693D6E5B345D292E7472696D28292C2F5E272E2A27242F2E746573742869297C7C2F5E222E2A22242F2E746573742869293F692E736C69636528312C2D31293A226E756C6C223D3D3D693F6E756C6C3A22223D3D3D697C7C';
wwv_flow_imp.g_varchar2_table(65) := '69734E614E284E756D626572286929293F766F696420303A4E756D626572286929293B766F696420303D3D3D6C2626286C3D7928742C6E5B345D2E7472696D28292C7229293B76617220753D6E756C6C3D3D6F7C7C22223D3D3D6F3F6E756C6C3D3D3D6C';
wwv_flow_imp.g_varchar2_table(66) := '7C7C22223D3D3D6C3A537472696E67286F293D3D3D537472696E67286C293B737769746368286E5B335D297B63617365223D3D223A72657475726E20753B6361736522213D223A72657475726E21753B63617365223E223A72657475726E204E756D6265';
wwv_flow_imp.g_varchar2_table(67) := '72286F293E4E756D626572286C293B63617365223C223A72657475726E204E756D626572286F293C4E756D626572286C293B63617365223E3D223A72657475726E204E756D626572286F293E3D4E756D626572286C293B63617365223C3D223A72657475';
wwv_flow_imp.g_varchar2_table(68) := '726E204E756D626572286F293C3D4E756D626572286C297D72657475726E21317D66756E6374696F6E205328652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C282266756E6374696F6E223D3D747970656F6620653F212165';
wwv_flow_imp.g_varchar2_table(69) := '28722C74293A537472696E672865292E73706C697428227C7C22292E736F6D652866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E65766572792866756E6374696F6E2865297B72657475726E205428652C742C72297D';
wwv_flow_imp.g_varchar2_table(70) := '297D29297D66756E6374696F6E204328652C74297B76617220723D742E535B537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C7465722866756E63';
wwv_flow_imp.g_varchar2_table(71) := '74696F6E2872297B72657475726E205328652E66696C7465722C742C72297D293A727D66756E6374696F6E204128652C742C72297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F6620652972657475726E20';
wwv_flow_imp.g_varchar2_table(72) := '653B766172206E3D7928742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E204E28652C742C72297B766172206E3D6E756C6C3B7265747572';
wwv_flow_imp.g_varchar2_table(73) := '6E28657C7C5B5D292E736F6D652866756E6374696F6E2865297B72657475726E21215328652E7768656E2C742C72292626286E3D652C2130297D292C6E7D766172207A3D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D';
wwv_flow_imp.g_varchar2_table(74) := '2C617269616C3A5B2268656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75';
wwv_flow_imp.g_varchar2_table(75) := '726965723A5B22636F7572696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E205028652C74297B76617220722C6E3D5B5D2C6F3D7B623A21312C693A';
wwv_flow_imp.g_varchar2_table(76) := '21312C753A21312C733A21317D2C613D5B28743D747C7C7B7D292E666F6E747C7C2268656C766574696361225D2C693D5B742E636F6C6F727C7C6E756C6C5D2C6C3D22222C753D303B66756E6374696F6E207328297B76617220653B6C2626286E2E7075';
wwv_flow_imp.g_varchar2_table(77) := '7368287B743A6C2C623A6F2E622C693A6F2E692C753A6F2E752C733A6F2E732C663A28653D615B612E6C656E6774682D315D2C653D537472696E6728657C7C2268656C76657469636122292E746F4C6F7765724361736528292C7A5B655D3F653A226865';
wwv_flow_imp.g_varchar2_table(78) := '6C76657469636122292C633A695B692E6C656E6774682D315D7D292C6C3D2222297D666F7228653D537472696E67286E756C6C3D3D653F22223A65293B753C652E6C656E6774683B297B76617220633D652E7375627374722875293B225C5C223D3D3D63';
wwv_flow_imp.g_varchar2_table(79) := '2E6368617241742830292626632E6C656E6774683E313F286C2B3D632E6368617241742831292C752B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286329293F287328292C612E7075736828725B315D292C752B3D72';
wwv_flow_imp.g_varchar2_table(80) := '5B305D2E6C656E677468293A225B2F665D22213D3D632E73756273747228302C34293F28723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286329293F287328292C692E7075736828725B315D292C752B3D725B30';
wwv_flow_imp.g_varchar2_table(81) := '5D2E6C656E677468293A225B2F635D22213D3D632E73756273747228302C34293F222A2A2A22213D3D632E73756273747228302C33293F222A2A22213D3D632E73756273747228302C32293F227E7E22213D3D632E73756273747228302C32293F222B2B';
wwv_flow_imp.g_varchar2_table(82) := '22213D3D632E73756273747228302C32293F222A22213D3D632E6368617241742830293F286C2B3D632E6368617241742830292C752B2B293A287328292C6F2E693D216F2E692C752B3D31293A287328292C6F2E753D216F2E752C752B3D32293A287328';
wwv_flow_imp.g_varchar2_table(83) := '292C6F2E733D216F2E732C752B3D32293A287328292C6F2E623D216F2E622C752B3D32293A287328292C6F2E623D216F2E622C6F2E693D216F2E692C752B3D33293A287328292C692E6C656E6774683E312626692E706F7028292C752B3D34293A287328';
wwv_flow_imp.g_varchar2_table(84) := '292C612E6C656E6774683E312626612E706F7028292C752B3D34297D72657475726E207328292C6E7D66756E6374696F6E204D28652C74297B76617220723D652E736F757263653F4328652C74295B305D3A6E756C6C3B72657475726E2841727261792E';
wwv_flow_imp.g_varchar2_table(85) := '6973417272617928652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C697428225C6E2229292E6D61702866756E6374696F6E2865297B72657475726E204528652C742C72';
wwv_flow_imp.g_varchar2_table(86) := '297D297D66756E6374696F6E206B28652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D742E545B6E5D7C7C7B7D2C693D652E636F6C756D6E733B72657475726E20692626692E';
wwv_flow_imp.g_varchar2_table(87) := '6C656E6774687C7C28693D4F626A6563742E6B6579732861292E66696C7465722866756E6374696F6E2865297B72657475726E22444F435F4B455922213D3D657D292E6D61702866756E6374696F6E2865297B72657475726E7B636F6C3A657D7D29292C';
wwv_flow_imp.g_varchar2_table(88) := '28693D692E66696C7465722866756E6374696F6E2865297B72657475726E22737472696E67223D3D747970656F6620657C7C21652E7768656E7C7C5328652E7768656E2C742C6E756C6C297D29292E6D61702866756E6374696F6E2865297B7661722074';
wwv_flow_imp.g_varchar2_table(89) := '3D28653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C292E746F55707065724361736528293A6E756C6C2C6E3D743F615B745D3A6E756C6C2C693D652E666D743B72657475726E20';
wwv_flow_imp.g_varchar2_table(90) := '697C7C224E554D42455222213D3D6E7C7C652E76616C75657C7C28693D722E736F6D652866756E6374696F6E2865297B72657475726E206F28655B745D2926264D6174682E726F756E6428655B745D29213D3D655B745D7D293F226D6F6E6579223A6E75';
wwv_flow_imp.g_varchar2_table(91) := '6C6C292C7B636F6C3A742C76616C75653A652E76616C75652C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628747C7C2222292C666D743A692C6D61703A652E6D61702C626F6C643A2121652E626F6C642C7769647468';
wwv_flow_imp.g_varchar2_table(92) := '3A652E77696474682C616C69676E3A652E616C69676E7C7C28672869293F226C656674223A224E554D424552223D3D3D6E7C7C226D6F6E6579223D3D3D697C7C22696E74223D3D3D697C7C226E756D223D3D3D693F227269676874223A2244415445223D';
wwv_flow_imp.g_varchar2_table(93) := '3D3D6E7C7C2264617465223D3D3D693F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63656C6C5374796C652C636F6C6F723A652E636F6C6F722C69734E756D3A2167286929262628224E554D424552223D3D3D6E262621652E';
wwv_flow_imp.g_varchar2_table(94) := '6D6170262621652E76616C75657C7C226D6F6E6579223D3D3D697C7C22696E74223D3D3D697C7C2F5E6E756D2F2E7465737428697C7C222229297D7D297D66756E6374696F6E204628652C74297B76617220723D5B5D2C6E3D303B72657475726E28652E';
wwv_flow_imp.g_varchar2_table(95) := '67726F7570737C7C5B5D292E666F72456163682866756E6374696F6E2865297B766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E677468262628722E70757368';
wwv_flow_imp.g_varchar2_table(96) := '287B6C6162656C3A652E6C6162656C7C7C22222C636F6C733A6F2C66726F6D3A6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C733A742E6C656E6774682D';
wwv_flow_imp.g_varchar2_table(97) := '6E2C66726F6D3A6E2C6761703A21307D292C727D66756E6374696F6E204928652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E204528652E76616C75652C722C74293B766172206E3D745B652E636F6C5D3B7265747572';
wwv_flow_imp.g_varchar2_table(98) := '6E20652E6D617026266E756C6C213D6E2626766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E204F28652C742C72297B766172206E3D4928652C742C72293B72657475726E20652E6D61702626766F69642030';
wwv_flow_imp.g_varchar2_table(99) := '213D3D652E6D61705B745B652E636F6C5D5D3F537472696E67286E293A70286E2C652E666D74297D766172206A3D7B73756D3A392C6176673A312C6D696E3A352C6D61783A342C636F756E743A337D2C523D7B73756D3A2253554D222C6176673A224156';
wwv_flow_imp.g_varchar2_table(100) := '4552414745222C6D696E3A224D494E222C6D61783A224D4158222C636F756E743A22434F554E5441227D2C443D7B6176673A2250726F6D2E222C6D696E3A224DC3AD6E2E222C6D61783A224DC3A1782E222C636F756E743A2243616E742E227D3B66756E';
wwv_flow_imp.g_varchar2_table(101) := '6374696F6E20552865297B72657475726E2841727261792E697341727261792865293F653A5B5D292E6D61702866756E6374696F6E2865297B76617220743D652626226F626A656374223D3D747970656F6620653F653A7B636F6C3A657D2C723D537472';
wwv_flow_imp.g_varchar2_table(102) := '696E6728742E666E7C7C2273756D22292E746F4C6F7765724361736528293B72657475726E7B636F6C3A537472696E6728742E636F6C7C7C2222292E746F55707065724361736528292C666E3A6A5B725D3F723A2273756D227D7D292E66696C74657228';
wwv_flow_imp.g_varchar2_table(103) := '66756E6374696F6E2865297B72657475726E20652E636F6C7D297D66756E6374696F6E204C28652C74297B666F722876617220723D303B723C652E6C656E6774683B722B2B29696628655B725D2E636F6C3D3D3D742972657475726E20655B725D3B7265';
wwv_flow_imp.g_varchar2_table(104) := '7475726E206E756C6C7D66756E6374696F6E20422865297B72657475726E20652E736F6D652866756E6374696F6E2865297B72657475726E2273756D22213D3D652E666E7D297D66756E6374696F6E20472865297B72657475726E206F2865297C7C2273';
wwv_flow_imp.g_varchar2_table(105) := '7472696E67223D3D747970656F66206526262222213D3D652E7472696D282926262169734E614E284E756D626572286529297D66756E6374696F6E205728652C742C72297B766172206E3D652E6D61702866756E6374696F6E2865297B72657475726E20';
wwv_flow_imp.g_varchar2_table(106) := '655B745D7D292E66696C7465722866756E6374696F6E2865297B72657475726E206E756C6C213D6526262222213D3D657D293B69662822636F756E74223D3D3D722972657475726E206E2E6C656E6774683B6966282273756D223D3D3D727C7C22617667';
wwv_flow_imp.g_varchar2_table(107) := '223D3D3D72297B766172206F3D6E2E66696C7465722847292E6D6170284E756D626572292C613D6F2E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30293B72657475726E2273756D223D3D3D723F613A6F2E6C656E';
wwv_flow_imp.g_varchar2_table(108) := '6774683F612F6F2E6C656E6774683A6E756C6C7D76617220693D6E756C6C2C6C3D6E756C6C3B72657475726E206E2E666F72456163682866756E6374696F6E2865297B76617220743D472865293F6E756C6C3A642865292C6E3D472865293F4E756D6265';
wwv_flow_imp.g_varchar2_table(109) := '722865293A743F742E67657454696D6528293A537472696E672865293B286E756C6C3D3D3D6C7C7C28226D696E223D3D3D723F6E3C6C3A6E3E6C2929262628693D652C6C3D6E297D292C697D66756E6374696F6E205F28652C742C722C6E297B76617220';
wwv_flow_imp.g_varchar2_table(110) := '6F3D422874292C613D2D312C693D652E6D61702866756E6374696F6E28652C6E297B76617220693D652E636F6C3F4C28742C652E636F6C293A6E756C6C3B72657475726E20692626613C30262628613D6E292C693F66756E6374696F6E28652C742C722C';
wwv_flow_imp.g_varchar2_table(111) := '6E297B766172206F2C613D5728722C742E636F6C2C742E666E293B72657475726E286F3D6E756C6C3D3D613F22223A22636F756E74223D3D3D742E666E3F7028612C22696E7422293A226D696E223D3D3D742E666E7C7C226D6178223D3D3D742E666E3F';
wwv_flow_imp.g_varchar2_table(112) := '472861293F7028612C652E666D747C7C226D6F6E657922293A7028612C652E666D74293A22617667223D3D3D742E666E3F7028612C652E666D74262622696E7422213D3D652E666D743F652E666D743A226D6F6E657922293A7028612C652E666D747C7C';
wwv_flow_imp.g_varchar2_table(113) := '226D6F6E657922292926266E2626445B742E666E5D3F445B742E666E5D2B2220222B6F3A6F7D28652C692C722C6F293A22227D293B72657475726E7B61743A613C303F652E6C656E6774683A612C63656C6C733A692C746578743A6E7D7D66756E637469';
wwv_flow_imp.g_varchar2_table(114) := '6F6E204828652C742C72297B72657475726E204528652E746F74616C734C6162656C7C7C22546F74616C6573222C742C7B434F554E543A722E6C656E6774687D297D66756E6374696F6E205928652C74297B76617220723D7B636F6E74656E743A652E74';
wwv_flow_imp.g_varchar2_table(115) := '6578742C636F6C5370616E3A652E61747C7C742C7374796C65733A7B68616C69676E3A226C656674227D7D3B72657475726E20303D3D3D652E61743F5B5B725D2C652E63656C6C732E736C69636528295D3A5B5B725D2E636F6E63617428652E63656C6C';
wwv_flow_imp.g_varchar2_table(116) := '732E736C69636528652E617429295D7D66756E6374696F6E20712865297B72657475726E21313D3D3D652E627265616B546F74616C733F5B5D3A552841727261792E6973417272617928652E627265616B546F74616C73293F652E627265616B546F7461';
wwv_flow_imp.g_varchar2_table(117) := '6C733A652E746F74616C73297D66756E6374696F6E205628652C74297B69662821652E627265616B42797C7C21742E6C656E6774682972657475726E20742E6D61702866756E6374696F6E28652C74297B72657475726E7B6B3A22726F77222C723A652C';
wwv_flow_imp.g_varchar2_table(118) := '693A747D7D293B76617220723D537472696E6728652E627265616B4279292E746F55707065724361736528292C6E3D5B5D2C6F3D6E756C6C2C613D302C693D712865292E6C656E6774683E303B66756E6374696F6E206C28297B6F26266926266E2E7075';
wwv_flow_imp.g_varchar2_table(119) := '7368287B6B3A22737562222C723A6F2E722C726F77733A6F2E726F77737D297D72657475726E20742E666F72456163682866756E6374696F6E2874297B76617220693D537472696E67286E756C6C3D3D3D745B725D7C7C766F696420303D3D3D745B725D';
wwv_flow_imp.g_varchar2_table(120) := '3F22223A745B725D293B6F26266F2E6B65793D3D3D697C7C286C28292C6F3D7B6B65793A692C723A742C726F77733A5B5D7D2C2131213D3D652E627265616B5469746C6526266E2E70757368287B6B3A2268656164222C723A742C726F77733A6F2E726F';
wwv_flow_imp.g_varchar2_table(121) := '77737D29292C6F2E726F77732E707573682874292C6E2E70757368287B6B3A22726F77222C723A742C693A612B2B7D297D292C6C28292C6E7D66756E6374696F6E202428652C742C72297B766172206E2C6F3D7B7D2C613D537472696E6728652E627265';
wwv_flow_imp.g_varchar2_table(122) := '616B4279292E746F55707065724361736528293B666F72286E20696E20742E72296F5B6E5D3D742E725B6E5D3B6F2E434F554E543D742E726F77732E6C656E6774683B76617220693D2268656164223D3D3D742E6B3F652E627265616B5469746C653A65';
wwv_flow_imp.g_varchar2_table(123) := '2E627265616B4C6162656C3B72657475726E206E756C6C213D6926262130213D3D697C7C28693D2268656164223D3D3D742E6B3F227B222B612B227D223A22537562746F74616C207B222B612B227D22292C4528692C722C6F297D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(124) := '5A28652C742C72297B696628652E6D6170297B766172206E3D7928742C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C2222292E73706C697428227C22295B305D2C72293B72657475726E20766F69642030213D3D652E';
wwv_flow_imp.g_varchar2_table(125) := '6D61705B6E5D3F652E6D61705B6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E7D7C5D2B5C7D242F2E74657374286F7C7C2222293F70287928742C6F2E736C6963652831';
wwv_flow_imp.g_varchar2_table(126) := '2C2D31292C72292C652E666D74293A45286F2C742C72297D66756E6374696F6E205828652C742C72297B72657475726E28652E73656374696F6E737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E2821652E666F726D6174';
wwv_flow_imp.g_varchar2_table(127) := '737C7C652E666F726D6174732E696E6465784F662874293E3D302926262821727C7C5128652C7229297D297D766172204A3D7B66696368613A312C746578746F3A312C696D6167656E3A312C636F6469676F3A312C616C657274613A312C6C696E65613A';
wwv_flow_imp.g_varchar2_table(128) := '312C7461626C613A312C6772616669636F3A312C6573706163696F3A317D3B66756E6374696F6E204B28652C742C722C6E297B766172206F3D2841727261792E6973417272617928652E636F6C73293F652E636F6C733A5B5D292E736C69636528302C33';
wwv_flow_imp.g_varchar2_table(129) := '292C613D6F2E6C656E6774683B69662821612972657475726E5B5D3B76617220693D6F2E6D61702866756E6374696F6E28742C72297B766172206E3D4E756D6265722828652E7769647468737C7C5B5D295B725D293B72657475726E206E3E303F6E3A31';
wwv_flow_imp.g_varchar2_table(130) := '30302F617D292C6C3D692E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C753D766F69642030213D3D652E636F6C4761703F4E756D62657228652E636F6C476170293A342C733D6E2D752A28612D31292C633D';
wwv_flow_imp.g_varchar2_table(131) := '303B72657475726E206F2E6D61702866756E6374696F6E28652C6E297B766172206F3D732A695B6E5D2F6C2C613D2841727261792E697341727261792865293F653A5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E206526264A';
wwv_flow_imp.g_varchar2_table(132) := '5B652E747970655D26262821652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D302926265128652C72297D292E6D61702866756E6374696F6E2865297B72657475726E2066756E6374696F6E28652C74297B7661722072';
wwv_flow_imp.g_varchar2_table(133) := '2C6E3D7B7D3B666F72287220696E2065294F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652C72292626286E5B725D3D655B725D293B6966285B2278222C2279222C227831222C227931222C227832222C22';
wwv_flow_imp.g_varchar2_table(134) := '7932225D2E666F72456163682866756E6374696F6E2865297B64656C657465206E5B655D7D292C22696D6167656E223D3D3D6E2E747970652626286E2E5F6D6178573D74292C226772616669636F223D3D3D6E2E74797065297B766172206F3D6E2E7769';
wwv_flow_imp.g_varchar2_table(135) := '6474687C7C3132302C613D6E2E6865696768747C7C37303B6F3E742626286E2E77696474683D742C6E2E6865696768743D612A742F6F297D72657475726E22636F6469676F223D3D3D6E2E74797065262628227172223D3D3D537472696E67286E2E6B69';
wwv_flow_imp.g_varchar2_table(136) := '6E647C7C22717222292E746F4C6F7765724361736528292626286E2E73697A657C7C3330293E742626286E2E73697A653D74292C6E2E776964746826266E2E77696474683E742626286E2E77696474683D7429292C28226C696E6561223D3D3D6E2E7479';
wwv_flow_imp.g_varchar2_table(137) := '70657C7C22746578746F223D3D3D6E2E747970652926266E2E776964746826266E2E77696474683E742626286E2E77696474683D74292C6E7D28652C6F297D292C663D7B783A632C773A6F2C736563733A617D3B72657475726E20632B3D6F2B752C667D';
wwv_flow_imp.g_varchar2_table(138) := '297D66756E6374696F6E205128652C74297B72657475726E22616C65727461223D3D3D652E747970657C7C21652E7768656E7C7C5328652E7768656E2C742C6E756C6C297D66756E6374696F6E2065652865297B76617220742C723D7B7D3B666F722874';
wwv_flow_imp.g_varchar2_table(139) := '20696E206E29725B745D3D6E5B745D3B766172206F3D652E706167652626652E706167652E7468656D657C7C7B7D3B666F72287420696E206F29725B745D3D6F5B745D3B72657475726E20727D7661722074653D7B7D2C72653D7B7D3B66756E6374696F';
wwv_flow_imp.g_varchar2_table(140) := '6E206E652865297B76617220743D77696E646F772E617065782626617065782E656E767C7C7B7D3B72657475726E20537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C2222292E';
wwv_flow_imp.g_varchar2_table(141) := '7265706C6163652822234150505F494D4147455323222C742E4150505F46494C45537C7C2222292E7265706C616365282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C6163652822';
wwv_flow_imp.g_varchar2_table(142) := '23494D4147455F50524546495823222C742E415045585F46494C45537C7C2222297D66756E6374696F6E206F652865297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B315D297265';
wwv_flow_imp.g_varchar2_table(143) := '7475726E7B773A28745B31365D3C3C32347C745B31375D3C3C31367C745B31385D3C3C387C745B31395D293E3E3E302C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22706E6722';
wwv_flow_imp.g_varchar2_table(144) := '7D3B6966283235353D3D3D745B305D26263231363D3D3D745B315D29666F722876617220723D323B723C742E6C656E6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B335D3B69';
wwv_flow_imp.g_varchar2_table(145) := '66286E3E3D31393226266E3C3D3230372626313936213D3D6E2626323030213D3D6E2626323034213D3D6E2972657475726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A7067227D3B';
wwv_flow_imp.g_varchar2_table(146) := '722B3D322B6F7D656C736520722B2B3B7468726F77206E6577204572726F722822466F726D61746F20646520696D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E2061652865297B666F';
wwv_flow_imp.g_varchar2_table(147) := '722876617220743D6E65772055696E743841727261792865292C723D22222C6E3D303B6E3C742E6C656E6774683B6E2B3D333237363829722B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E737562617272617928';
wwv_flow_imp.g_varchar2_table(148) := '6E2C6E2B333237363829293B72657475726E2062746F612872297D66756E6374696F6E20696528652C74297B696628652E6669656C64297B76617220723D2828652E736F757263653F4328652C74295B305D3A742E646F63297C7C7B7D295B537472696E';
wwv_flow_imp.g_varchar2_table(149) := '6728652E6669656C64292E746F55707065724361736528295D3B7472797B72657475726E20723F66756E6374696F6E2865297B76617220743D537472696E672865292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C6163';
wwv_flow_imp.g_varchar2_table(150) := '65282F5C732B2F672C2222293B69662821742972657475726E206E756C6C3B76617220723D226236343A222B742E6C656E6774682B223A222B742E73756273747228302C3634292B742E737562737472282D3634293B69662874655B725D297265747572';
wwv_flow_imp.g_varchar2_table(151) := '6E2074655B725D3B666F7228766172206E3D61746F622874292C6F3D6E65772055696E74384172726179286E2E6C656E677468292C613D303B613C6E2E6C656E6774683B612B2B296F5B615D3D6E2E63686172436F646541742861293B76617220693D6F';
wwv_flow_imp.g_varchar2_table(152) := '65286F2E627566666572293B72657475726E2074655B725D3D7B6275663A6F2E6275666665722C773A692E772C683A692E682C6578743A692E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D692E6578743F226A706567';
wwv_flow_imp.g_varchar2_table(153) := '223A22706E6722292B223B6261736536342C222B747D2C74655B725D7D2872293A6E756C6C7D63617463682874297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D6167';
wwv_flow_imp.g_varchar2_table(154) := '656E20696E76C3A16C69646120656E20222B652E6669656C642C74292C6E756C6C7D7D72657475726E2074655B6E6528652E75726C295D7C7C6E756C6C7D66756E6374696F6E206C6528652C74297B76617220723D652E77696474687C7C34302C6E3D65';
wwv_flow_imp.g_varchar2_table(155) := '2E6865696768747C7C722A742E682F742E773B72657475726E21652E77696474682626652E686569676874262628723D6E2A742E772F742E68292C652E5F6D6178572626723E652E5F6D6178572626286E3D6E2A652E5F6D6178572F722C723D652E5F6D';
wwv_flow_imp.g_varchar2_table(156) := '617857292C7B773A722C683A6E7D7D66756E6374696F6E2075652865297B666F722876617220743D61746F622865292C723D6E65772055696E7438417272617928742E6C656E677468292C6E3D303B6E3C742E6C656E6774683B6E2B2B29725B6E5D3D74';
wwv_flow_imp.g_varchar2_table(157) := '2E63686172436F64654174286E293B72657475726E20722E6275666665727D66756E6374696F6E20736528652C742C72297B72657475726E7B6275663A756528652E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C222229292C646174613A65';
wwv_flow_imp.g_varchar2_table(158) := '2C773A742C683A722C6578743A22706E67227D7D66756E6374696F6E20636528652C74297B69662822756E646566696E6564223D3D747970656F6620646F63756D656E747C7C21646F63756D656E742E637265617465456C656D656E74297468726F7720';
wwv_flow_imp.g_varchar2_table(159) := '6E6577204572726F722822536520726571756965726520756E206E6176656761646F72202863616E7661732920706172612067656E65726172206772C3A16669636F732E22293B76617220723D646F63756D656E742E637265617465456C656D656E7428';
wwv_flow_imp.g_varchar2_table(160) := '2263616E76617322293B72657475726E20722E77696474683D652C722E6865696768743D742C727D7661722066653D6E756C6C3B66756E6374696F6E2064652865297B72657475726E5B653E3E3E3234263235352C653E3E3E3136263235352C653E3E3E';
wwv_flow_imp.g_varchar2_table(161) := '38263235352C32353526655D7D66756E6374696F6E20686528652C74297B76617220723D5B652E63686172436F646541742830292C652E63686172436F646541742831292C652E63686172436F646541742832292C652E63686172436F64654174283329';
wwv_flow_imp.g_varchar2_table(162) := '5D2C6E3D6E65772055696E7438417272617928342B742E6C656E677468293B6E2E73657428722C30292C6E2E73657428742C34293B766172206F3D6E65772055696E743841727261792831322B742E6C656E677468293B72657475726E206F2E73657428';
wwv_flow_imp.g_varchar2_table(163) := '646528742E6C656E677468292C30292C6F2E736574286E2C34292C6F2E7365742864652866756E6374696F6E2865297B696628216665297B66653D5B5D3B666F722876617220743D303B743C3235363B742B2B297B666F722876617220723D742C6E3D30';
wwv_flow_imp.g_varchar2_table(164) := '3B6E3C383B6E2B2B29723D3126723F333938383239323338345E723E3E3E313A723E3E3E313B66655B745D3D723E3E3E307D7D666F7228766172206F3D343239343936373239352C613D303B613C652E6C656E6774683B612B2B296F3D66655B32353526';
wwv_flow_imp.g_varchar2_table(165) := '286F5E655B615D295D5E6F3E3E3E383B72657475726E28343239343936373239355E6F293E3E3E307D286E29292C382B742E6C656E677468292C6F7D66756E6374696F6E20706528652C742C722C6E297B766172206F2C692C6C3D4D6174682E6365696C';
wwv_flow_imp.g_varchar2_table(166) := '28652F38292B312C753D6E65772055696E74384172726179286C2A74293B666F7228693D303B693C743B692B2B29666F72286F3D303B6F3C653B6F2B2B2972286F2C6929262628755B692A6C2B312B286F3E3E33295D7C3D3132383E3E2837266F29293B';
wwv_flow_imp.g_varchar2_table(167) := '76617220732C633D4D6174682E6365696C28752E6C656E6774682F3635353335292C663D6E65772055696E7438417272617928322B752E6C656E6774682B352A632B34292C643D322C683D312C703D303B666F7228665B305D3D3132302C665B315D3D31';
wwv_flow_imp.g_varchar2_table(168) := '2C733D303B733C633B732B2B297B76617220673D36353533352A732C6D3D4D6174682E6D696E2836353533352C752E6C656E6774682D67293B665B642B2B5D3D733D3D3D632D313F313A302C665B642B2B5D3D323535266D2C665B642B2B5D3D6D3E3E38';
wwv_flow_imp.g_varchar2_table(169) := '2C665B642B2B5D3D323535267E6D2C665B642B2B5D3D7E6D3E3E38263235352C662E73657428752E737562617272617928672C672B6D292C64292C642B3D6D7D666F7228733D303B733C752E6C656E6774683B732B2B29703D28702B28683D28682B755B';
wwv_flow_imp.g_varchar2_table(170) := '735D2925363535323129292536353532313B662E7365742864652828703C3C31367C68293E3E3E30292C64293B76617220763D6E65772055696E74384172726179283133292C623D61286E7C7C222330303030303022293B762E7365742864652865292C';
wwv_flow_imp.g_varchar2_table(171) := '30292C762E7365742864652874292C34292C765B385D3D312C765B395D3D333B76617220773D5B6E65772055696E74384172726179285B3133372C38302C37382C37312C31332C31302C32362C31305D292C6865282249484452222C76292C6865282250';
wwv_flow_imp.g_varchar2_table(172) := '4C5445222C6E65772055696E74384172726179285B3235352C3235352C3235352C625B305D2C625B315D2C625B325D5D29292C6865282249444154222C66292C6865282249454E44222C6E65772055696E74384172726179283029295D2C783D772E7265';
wwv_flow_imp.g_varchar2_table(173) := '647563652866756E6374696F6E28652C74297B72657475726E20652B742E6C656E6774687D2C30292C793D6E65772055696E743841727261792878292C453D303B72657475726E20772E666F72456163682866756E6374696F6E2865297B792E73657428';
wwv_flow_imp.g_varchar2_table(174) := '652C45292C452B3D652E6C656E6774687D292C7B6275663A792E6275666665722C646174613A22646174613A696D6167652F706E673B6261736536342C222B616528792E627566666572292C773A652C683A742C6578743A22706E67227D7D7661722067';
wwv_flow_imp.g_varchar2_table(175) := '653D2232313232323220323232313232203232323232312031323132323320313231333232203133313232322031323232313320313232333132203133323231322032323132313320323231333132203233313231322031313232333220313232313332';
wwv_flow_imp.g_varchar2_table(176) := '20313232323331203131333232322031323331323220313233323231203232333231312032323131333220323231323331203231333231322032323331313220333132313331203331313232322033323131323220333231323231203331323231322033';
wwv_flow_imp.g_varchar2_table(177) := '32323131322033323232313120323132313233203231323332312032333231323120313131333233203133313132332031333133323120313132333133203133323131332031333233313120323131333133203233313131332032333133313120313132';
wwv_flow_imp.g_varchar2_table(178) := '31333320313132333331203133323133312031313331323320313133333231203133333132312033313331323120323131333331203233313133312032313331313320323133333131203231333133312033313131323320333131333231203333313132';
wwv_flow_imp.g_varchar2_table(179) := '31203331323131332033313233313120333332313131203331343131312032323134313120343331313131203131313232342031313134323220313231313234203132313432312031343131323220313431323231203131323231342031313234313220';
wwv_flow_imp.g_varchar2_table(180) := '31323231313420313232343131203134323131322031343232313120323431323131203232313131342034313331313120323431313132203133343131312031313132343220313231313432203132313234312031313432313220313234313132203132';
wwv_flow_imp.g_varchar2_table(181) := '34323131203431313231322034323131313220343231323131203231323134312032313431323120343132313231203131313134332031313133343120313331313431203131343131332031313433313120343131313133203431313331312031313331';
wwv_flow_imp.g_varchar2_table(182) := '34312031313431333120333131313431203431313133312032313134313220323131323134203231313233322032333331313132222E73706C697428222022293B66756E6374696F6E206D652865297B653D537472696E672865292E7265706C61636528';
wwv_flow_imp.g_varchar2_table(183) := '2F5B5E5C7832302D5C7837455D2F672C223F22293B666F722876617220742C723D5B5D2C6E3D2F285C647B342C7D297C285B5E5C645D2B7C5C647B312C337D292F673B743D6E2E657865632865293B29696628745B315D7C7C2F5E5C642B242F2E746573';
wwv_flow_imp.g_varchar2_table(184) := '742865292626652E6C656E67746825323D3D30297B766172206F3D745B305D2C613D6F2E6C656E6774682D6F2E6C656E67746825323B722E70757368287B7365743A2243222C743A6F2E73756273747228302C61297D292C613C6F2E6C656E6774682626';
wwv_flow_imp.g_varchar2_table(185) := '722E70757368287B7365743A2242222C743A6F2E7375627374722861297D297D656C736520722E70757368287B7365743A2242222C743A745B305D7D293B76617220693D5B5D2C6C3D6E756C6C3B722E666F72456163682866756E6374696F6E2865297B';
wwv_flow_imp.g_varchar2_table(186) := '6966286E756C6C3D3D3D6C3F692E70757368282243223D3D3D652E7365743F3130353A313034293A6C213D3D652E7365742626692E70757368282243223D3D3D652E7365743F39393A313030292C6C3D652E7365742C2243223D3D3D652E73657429666F';
wwv_flow_imp.g_varchar2_table(187) := '722876617220743D303B743C652E742E6C656E6774683B742B3D3229692E70757368282B652E742E73756273747228742C3229293B656C736520666F722876617220723D303B723C652E742E6C656E6774683B722B2B29692E7075736828652E742E6368';
wwv_flow_imp.g_varchar2_table(188) := '6172436F646541742872292D3332297D293B666F722876617220753D695B305D2C733D313B733C692E6C656E6774683B732B2B29752B3D732A695B735D3B692E707573682875253130332C313036293B76617220633D5B5D3B72657475726E20692E666F';
wwv_flow_imp.g_varchar2_table(189) := '72456163682866756E6374696F6E2865297B67655B655D2E73706C6974282222292E666F72456163682866756E6374696F6E28652C74297B666F722876617220723D303B723C2B653B722B2B29632E70757368287425323D3D30297D297D292C637D6675';
wwv_flow_imp.g_varchar2_table(190) := '6E6374696F6E20766528652C74297B76617220723D652E736F757263653F4328652C74295B305D3A6E756C6C3B696628652E736F75726365262621722972657475726E206E756C6C3B766172206E3D4528652E76616C75652C742C72293B696628216E29';
wwv_flow_imp.g_varchar2_table(191) := '72657475726E206E756C6C3B766172206F3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292C613D652E636F6C6F727C7C2223303030303030223B696628227172223D3D3D6F297B76617220693D66756E6374696F';
wwv_flow_imp.g_varchar2_table(192) := '6E28652C74297B76617220723D77696E646F772E7172636F64653B6966282172297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD612064652063C3B36469676F732051522E22293B722E73747269';
wwv_flow_imp.g_varchar2_table(193) := '6E67546F427974657346756E63732626722E737472696E67546F427974657346756E63735B225554462D38225D262628722E737472696E67546F42797465733D722E737472696E67546F427974657346756E63735B225554462D38225D293B766172206E';
wwv_flow_imp.g_varchar2_table(194) := '3D7228302C537472696E6728747C7C224D22292E746F5570706572436173652829293B72657475726E206E2E6164644461746128537472696E67286529292C6E2E6D616B6528292C7B6E3A6E2E6765744D6F64756C65436F756E7428292C6461726B3A66';
wwv_flow_imp.g_varchar2_table(195) := '756E6374696F6E28652C74297B72657475726E206E2E69734461726B28742C65297D7D7D286E2C652E656363292C6C3D652E73697A657C7C33303B72657475726E7B6B696E643A227172222C746578743A6E2C636F6C733A692E6E2C726F77733A692E6E';
wwv_flow_imp.g_varchar2_table(196) := '2C6461726B3A692E6461726B2C773A6C2C683A6C2C636F6C6F723A612C71756965743A327D7D69662822636F6465313238223D3D3D6F297B76617220753D6D65286E292C733D652E77696474687C7C4D6174682E6D696E2839302C2E33332A752E6C656E';
wwv_flow_imp.g_varchar2_table(197) := '677468293B72657475726E7B6B696E643A22626172222C746578743A6E2C636F6C733A752E6C656E6774682C726F77733A312C6461726B3A66756E6374696F6E2865297B72657475726E20755B655D7D2C773A732C683A652E6865696768747C7C31322C';
wwv_flow_imp.g_varchar2_table(198) := '636F6C6F723A612C71756965743A382C6C6162656C3A2131213D3D652E73686F77546578742C7465787453697A653A652E7465787453697A657C7C387D7D7468726F77206E6577204572726F7228225469706F2064652063C3B36469676F206E6F20736F';
wwv_flow_imp.g_varchar2_table(199) := '706F727461646F3A20222B6F2B222028757365207172206F20636F6465313238292E22297D66756E6374696F6E2062652865297B76617220743D652E71756965742C723D227172223D3D3D652E6B696E643F383A332C6E3D28652E636F6C732B322A7429';
wwv_flow_imp.g_varchar2_table(200) := '2A722C6F3D7065286E2C227172223D3D3D652E6B696E643F6E3A4D6174682E6D617828382C4D6174682E726F756E6428652E682F652E772A652E636F6C732A7229292C66756E6374696F6E286E2C6F297B76617220613D4D6174682E666C6F6F72286E2F';
wwv_flow_imp.g_varchar2_table(201) := '72292D742C693D227172223D3D3D652E6B696E643F4D6174682E666C6F6F72286F2F72292D743A303B72657475726E20613E3D302626693E3D302626613C652E636F6C732626693C652E726F77732626652E6461726B28612C69297D2C652E636F6C6F72';
wwv_flow_imp.g_varchar2_table(202) := '293B72657475726E206F2E776D6D3D652E772A28652E636F6C732B322A74292F652E636F6C732C6F2E686D6D3D227172223D3D3D652E6B696E643F6F2E776D6D3A652E682C6F7D7661722077653D5B2223314634453739222C2223453037423339222C22';
wwv_flow_imp.g_varchar2_table(203) := '23324538423537222C2223433033393242222C2223374433433938222C2223313641303835222C2223443441433044222C2223354436443745222C2223413034303030222C2223323837344136225D3B66756E6374696F6E20786528652C742C72297B76';
wwv_flow_imp.g_varchar2_table(204) := '6172206E3D77696E646F772E43686172743B696628216E297468726F77206E6577204572726F7228224E6F2073652063617267C3B3206C61206C6962726572C3AD61206465206772C3A16669636F73202843686172742E6A73292E22293B766172206F3D';
wwv_flow_imp.g_varchar2_table(205) := '4328652C74293B696628216F2E6C656E6774682972657475726E206E756C6C3B76617220693D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C6C3D742E545B695D7C7C7B7D2C753D4F626A6563742E6B65797328';
wwv_flow_imp.g_varchar2_table(206) := '6C292C733D652E63617465676F72793F537472696E6728652E63617465676F7279292E746F55707065724361736528293A752E66696C7465722866756E6374696F6E2865297B72657475726E224E554D42455222213D3D6C5B655D262622444F435F4B45';
wwv_flow_imp.g_varchar2_table(207) := '5922213D3D657D295B305D7C7C755B305D2C633D28652E7365726965732626652E7365726965732E6C656E6774683F652E7365726965733A752E66696C7465722866756E6374696F6E2865297B72657475726E224E554D424552223D3D3D6C5B655D2626';
wwv_flow_imp.g_varchar2_table(208) := '65213D3D73262622444F435F4B455922213D3D657D29292E6D61702866756E6374696F6E2865297B72657475726E20653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A652C7B636F6C3A537472696E6728652E636F6C292E746F55';
wwv_flow_imp.g_varchar2_table(209) := '707065724361736528292C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A6628652E636F6C292C636F6C6F723A652E636F6C6F727D7D292C643D652E63686172747C7C22626172222C683D22706965223D3D3D647C7C2264';
wwv_flow_imp.g_varchar2_table(210) := '6F7567686E7574223D3D3D642C673D31312E33343B68262628633D632E736C69636528302C3129293B766172206D3D652E77696474687C7C3132302C763D652E6865696768747C7C37302C623D6365284D6174682E726F756E64286D2A67292C4D617468';
wwv_flow_imp.g_varchar2_table(211) := '2E726F756E6428762A6729292C773D66756E6374696F6E2865297B72657475726E2E333532382A652A677D2C783D652E73697A657C7C382C793D2248656C7665746963612C20417269616C2C2073616E732D7365726966222C543D7B66616D696C793A79';
wwv_flow_imp.g_varchar2_table(212) := '2C73697A653A772878297D2C533D652E636F6C6F72732626652E636F6C6F72732E6C656E6774683F652E636F6C6F72733A5B722E7072696D6172795D2E636F6E6361742877652E736C696365283129292C413D66756E6374696F6E2874297B7265747572';
wwv_flow_imp.g_varchar2_table(213) := '6E207028742C652E666D747C7C284D6174682E726F756E642874293D3D3D743F22696E74223A226E756D3A322229297D2C4E3D6F2E6D61702866756E6374696F6E2874297B76617220723D745B735D3B72657475726E206E756C6C3D3D723F22223A652E';
wwv_flow_imp.g_varchar2_table(214) := '63617465676F7279466D743F7028722C652E63617465676F7279466D74293A537472696E672872297D292C7A3D632E6D61702866756E6374696F6E28722C6E297B76617220693D722E636F6C6F727C7C535B6E25532E6C656E6774685D2C6C3D7B6C6162';
wwv_flow_imp.g_varchar2_table(215) := '656C3A4528722E6C6162656C2C74292C646174613A6F2E6D61702866756E6374696F6E2865297B76617220743D655B722E636F6C5D3B72657475726E206E756C6C3D3D747C7C22223D3D3D743F6E756C6C3A4E756D6265722874297D297D3B7265747572';
wwv_flow_imp.g_varchar2_table(216) := '6E20683F286C2E6261636B67726F756E64436F6C6F723D6F2E6D61702866756E6374696F6E28652C74297B72657475726E20535B7425532E6C656E6774685D7D292C6C2E626F72646572436F6C6F723D2223464646464646222C6C2E626F726465725769';
wwv_flow_imp.g_varchar2_table(217) := '6474683D77282E3829293A226C696E65223D3D3D647C7C2261726561223D3D3D643F286C2E626F72646572436F6C6F723D692C6C2E6261636B67726F756E64436F6C6F723D2261726561223D3D3D643F66756E6374696F6E28652C74297B76617220723D';
wwv_flow_imp.g_varchar2_table(218) := '612865293B72657475726E227267626128222B725B305D2B222C222B725B315D2B222C222B725B325D2B222C222B742B2229227D28692C2E3235293A692C6C2E66696C6C3D2261726561223D3D3D642C6C2E626F7264657257696474683D7728312E3429';
wwv_flow_imp.g_varchar2_table(219) := '2C6C2E706F696E745261646975733D7728312E35292C6C2E706F696E744261636B67726F756E64436F6C6F723D692C6C2E74656E73696F6E3D652E736D6F6F74683F2E33353A30293A286C2E6261636B67726F756E64436F6C6F723D692C6C2E626F7264';
wwv_flow_imp.g_varchar2_table(220) := '657257696474683D30292C6C7D292C503D7B666F6E743A542C636F6C6F723A2223343434343434227D2C4D3D7B7D3B6966282168297B766172206B3D7B626567696E41745A65726F3A2131213D3D652E626567696E41745A65726F2C737461636B65643A';
wwv_flow_imp.g_varchar2_table(221) := '2121652E737461636B65642C67726163653A652E76616C7565733F2268626172223D3D3D643F22323525223A22313225223A302C677269643A7B636F6C6F723A2223453345374543222C6C696E6557696474683A77282E34297D2C626F726465723A7B64';
wwv_flow_imp.g_varchar2_table(222) := '6973706C61793A21317D2C7469636B733A7B666F6E743A542C636F6C6F723A2223343434343434222C63616C6C6261636B3A66756E6374696F6E2865297B72657475726E20412865297D7D7D2C463D7B737461636B65643A2121652E737461636B65642C';
wwv_flow_imp.g_varchar2_table(223) := '677269643A7B646973706C61793A21317D2C7469636B733A507D3B4D3D2268626172223D3D3D643F7B783A6B2C793A467D3A7B783A462C793A6B7D7D76617220493D766F69642030213D3D652E6C6567656E643F2121652E6C6567656E643A687C7C632E';
wwv_flow_imp.g_varchar2_table(224) := '6C656E6774683E312C4F3D6E6577206E28622E676574436F6E746578742822326422292C7B747970653A683F643A2268626172223D3D3D643F22626172223A2261726561223D3D3D643F226C696E65223A642C646174613A7B6C6162656C733A4E2C6461';
wwv_flow_imp.g_varchar2_table(225) := '7461736574733A7A7D2C706C6174666F726D3A6E2E4261736963506C6174666F726D2C6F7074696F6E733A7B726573706F6E736976653A21312C616E696D6174696F6E3A21312C646576696365506978656C526174696F3A312C696E646578417869733A';
wwv_flow_imp.g_varchar2_table(226) := '2268626172223D3D3D643F2279223A2278222C6C61796F75743A7B70616464696E673A772834297D2C7363616C65733A4D2C706C7567696E733A7B6C6567656E643A7B646973706C61793A492C706F736974696F6E3A652E6C6567656E64506F73697469';
wwv_flow_imp.g_varchar2_table(227) := '6F6E7C7C28683F227269676874223A22626F74746F6D22292C6C6162656C733A7B666F6E743A542C636F6C6F723A2223333333333333222C626F7857696474683A772837292C626F784865696768743A772837297D7D2C7469746C653A7B646973706C61';
wwv_flow_imp.g_varchar2_table(228) := '793A2121652E7469746C652C746578743A4528652E7469746C652C74292C636F6C6F723A2223323232323232222C666F6E743A7B66616D696C793A792C73697A653A7728782B32292C7765696768743A22626F6C64227D2C70616464696E673A7B626F74';
wwv_flow_imp.g_varchar2_table(229) := '746F6D3A772834297D7D2C746F6F6C7469703A7B656E61626C65643A21317D7D7D2C706C7567696E733A5B7B69643A226E72466F6E646F222C6265666F7265447261773A66756E6374696F6E2865297B76617220743D652E6374783B742E736176652829';
wwv_flow_imp.g_varchar2_table(230) := '2C742E66696C6C5374796C653D2223464646464646222C742E66696C6C5265637428302C302C652E77696474682C652E686569676874292C742E726573746F726528297D7D2C7B69643A226E7256616C6F726573222C6166746572446174617365747344';
wwv_flow_imp.g_varchar2_table(231) := '7261773A66756E6374696F6E2874297B696628652E76616C756573297B76617220723D742E6374783B722E7361766528292C722E666F6E743D22626F6C6420222B7728782D2E35292B22707820222B792C742E646174612E64617461736574732E666F72';
wwv_flow_imp.g_varchar2_table(232) := '456163682866756E6374696F6E286E2C6F297B696628742E69734461746173657456697369626C65286F29297B76617220613D6E2E646174612E7265647563652866756E6374696F6E28652C74297B72657475726E20652B28747C7C30297D2C30293B74';
wwv_flow_imp.g_varchar2_table(233) := '2E676574446174617365744D657461286F292E646174612E666F72456163682866756E6374696F6E28742C6F297B76617220693D6E2E646174615B6F5D3B6966286E756C6C213D69297B766172206C3D22706374223D3D3D652E76616C7565733F702861';
wwv_flow_imp.g_varchar2_table(234) := '3F3130302A692F613A302C226E756D3A3122292B2225223A412869293B69662868297B76617220753D742E746F6F6C746970506F736974696F6E28293B722E66696C6C5374796C653D2223464646464646222C722E74657874416C69676E3D2263656E74';
wwv_flow_imp.g_varchar2_table(235) := '6572222C722E74657874426173656C696E653D226D6964646C65222C722E66696C6C54657874286C2C752E782C752E79297D656C73652268626172223D3D3D643F28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D';
wwv_flow_imp.g_varchar2_table(236) := '226C656674222C722E74657874426173656C696E653D226D6964646C65222C722E66696C6C54657874286C2C742E782B7728312E35292C742E7929293A28722E66696C6C5374796C653D2223333333333333222C722E74657874416C69676E3D2263656E';
wwv_flow_imp.g_varchar2_table(237) := '746572222C722E74657874426173656C696E653D22626F74746F6D222C722E66696C6C54657874286C2C742E782C742E792D7728312E352929297D7D297D7D292C722E726573746F726528297D7D7D5D7D292C6A3D622E746F4461746155524C2822696D';
wwv_flow_imp.g_varchar2_table(238) := '6167652F706E6722293B4F2E64657374726F7928293B76617220523D7365286A2C622E77696474682C622E686569676874293B72657475726E20522E776D6D3D6D2C522E686D6D3D762C527D66756E6374696F6E20796528652C74297B76617220723D65';
wwv_flow_imp.g_varchar2_table(239) := '2E77617465726D61726B3B69662821727C7C226F626A656374223D3D747970656F6620722626215328722E7768656E2C742C742E646F63292972657475726E206E756C6C3B22737472696E67223D3D747970656F662072262628723D7B746578743A727D';
wwv_flow_imp.g_varchar2_table(240) := '293B766172206E3D4528722E746578742C742C742E646F63293B72657475726E206E3F7B746578743A6E2C636F6C6F723A722E636F6C6F727C7C2223433030303030222C6F7061636974793A766F69642030213D3D722E6F7061636974793F722E6F7061';
wwv_flow_imp.g_varchar2_table(241) := '636974793A2E31322C616E676C653A766F69642030213D3D722E616E676C653F722E616E676C653A34352C73697A653A722E73697A657D3A6E756C6C7D66756E6374696F6E20456528652C742C722C6E297B696628652E73697A652972657475726E2065';
wwv_flow_imp.g_varchar2_table(242) := '2E73697A653B766172206F3D652E616E676C65253138303D3D303F2E382A723A2E362A4D6174682E7371727428722A722B6E2A6E293B72657475726E204D6174682E6D61782832302C4D6174682E6D696E283136302C3130302A6F2F7429297D66756E63';
wwv_flow_imp.g_varchar2_table(243) := '74696F6E20546528652C742C72297B766172206E3D652E706167657C7C7B7D2C6F3D65652865292C693D6F2E666F6E7453697A652C6C3D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E7461';
wwv_flow_imp.g_varchar2_table(244) := '74696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572222C636F6D70726573733A21307D292C753D6C2E696E7465726E616C2E7061676553697A652E676574576964746828292C733D';
wwv_flow_imp.g_varchar2_table(245) := '6C2E696E7465726E616C2E7061676553697A652E67657448656967687428292C633D6E2E6D617267696E7C7C382C663D61286F2E7072696D617279292C643D61286F2E6865616454657874292C683D61286F2E7A65627261292C703D61286F2E746F7461';
wwv_flow_imp.g_varchar2_table(246) := '6C73292C673D632C6D3D21302C763D632C623D633B66756E6374696F6E207728297B72657475726E206C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A677D66756E6374696F6E20782865297B673D7728';
wwv_flow_imp.g_varchar2_table(247) := '292B28657C7C32297D66756E6374696F6E207928652C742C722C6E297B766172206F3D766F69642030213D3D652E783F652E783A227269676874223D3D3D652E616C69676E3F752D622D743A2263656E746572223D3D3D652E616C69676E3F762B28752D';
wwv_flow_imp.g_varchar2_table(248) := '762D622D74292F323A763B766F696420303D3D3D652E793F2828673D4D6174682E6D617828672C77282929292B723E732D632D31302626286C2E6164645061676528292C673D63292C6E286F2C67292C672B3D722B28766F69642030213D3D652E676170';
wwv_flow_imp.g_varchar2_table(249) := '3F652E6761703A33292C6C2E6C6173744175746F5461626C653D7B66696E616C593A677D293A6E286F2C652E79297D76617220543D5B5D3B742E666F72456163682866756E6374696F6E2874297B6D7C7C6C2E6164645061676528292C6D3D21312C673D';
wwv_flow_imp.g_varchar2_table(250) := '632C6C2E6C6173744175746F5461626C653D6E756C6C3B76617220493D7B6374783A742C66726F6D3A6C2E696E7465726E616C2E6765744E756D6265724F66506167657328297D3B542E707573682849292C5828652C22706466222C74292E666F724561';
wwv_flow_imp.g_varchar2_table(251) := '63682866756E6374696F6E206D2854297B76617220493D542E747970653B69662822686561646572223D3D3D49297B766172206A3D542E7375627469746C653F32303A31363B72657475726E206C2E73657446696C6C436F6C6F7228665B305D2C665B31';
wwv_flow_imp.g_varchar2_table(252) := '5D2C665B325D292C6C2E7265637428302C302C752C6A2C224622292C6C2E73657454657874436F6C6F7228645B305D2C645B315D2C645B325D292C6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C6C2E736574466F6E745369';
wwv_flow_imp.g_varchar2_table(253) := '7A6528542E73697A657C7C3134292C6C2E74657874284528542E7469746C652C74292C632C31302E352C7B6D617857696474683A2E372A757D292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C2E736574466F6E74';
wwv_flow_imp.g_varchar2_table(254) := '53697A652839292C542E726967687426266C2E74657874284528542E72696768742C74292C752D632C31302E352C7B616C69676E3A227269676874227D292C542E7375627469746C6526266C2E74657874284528542E7375627469746C652C74292C632C';
wwv_flow_imp.g_varchar2_table(255) := '31362E35292C6C2E73657454657874436F6C6F7228302C302C30292C673D6A2B342C766F6964286C2E6C6173744175746F5461626C653D6E756C6C297D69662822746578746F223D3D3D49297B76617220523D766F69642030213D3D542E792C443D672C';
wwv_flow_imp.g_varchar2_table(256) := '4C3D6C2E6C6173744175746F5461626C652C423D542E73697A657C7C31302C473D2E333532382A422A28542E6C696E654865696768747C7C312E3335292C573D28766F69642030213D3D542E783F542E783A76292B28542E696E64656E747C7C30292C58';
wwv_flow_imp.g_varchar2_table(257) := '3D542E77696474687C7C752D622D572C4A3D542E616C69676E7C7C226C656674222C513D6128542E636F6C6F727C7C222330303030303022292C65653D66756E6374696F6E2865297B72657475726E28652E627C7C542E626F6C6429262628652E697C7C';
wwv_flow_imp.g_varchar2_table(258) := '542E6974616C6963293F22626F6C646974616C6963223A652E627C7C542E626F6C643F22626F6C64223A652E697C7C542E6974616C69633F226974616C6963223A226E6F726D616C227D2C74653D542E666F6E747C7C652E706167652626652E70616765';
wwv_flow_imp.g_varchar2_table(259) := '2E666F6E747C7C2268656C766574696361223B72657475726E206C2E736574466F6E7453697A652842292C6C2E73657454657874436F6C6F7228515B305D2C515B315D2C515B325D292C673D523F542E793A4D6174682E6D617828672C6C2E6C61737441';
wwv_flow_imp.g_varchar2_table(260) := '75746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A67292C4D28542C74292E666F72456163682866756E6374696F6E2865297B76617220743D5B5D3B5028652C7B666F6E743A74652C636F6C6F723A542E636F6C6F727D292E';
wwv_flow_imp.g_varchar2_table(261) := '666F72456163682866756E6374696F6E2865297B652E742E73706C6974282F28202B292F292E666F72456163682866756E6374696F6E2872297B2222213D3D722626742E70757368287B743A722C66616D3A7A5B652E665D5B305D2C663A65652865292C';
wwv_flow_imp.g_varchar2_table(262) := '73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E633F6128652E63293A517D297D297D293B76617220723D5B5D2C6E3D5B5D2C6F3D303B666F7228742E666F72456163682866756E6374696F6E2865297B7661722074';
wwv_flow_imp.g_varchar2_table(263) := '3D66756E6374696F6E2865297B6C2E736574466F6E7428652E66616D2C652E66293B666F722876617220743D302C723D652E66616D2B652E662B422C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B766172206F3D722B652E742E636861724174';
wwv_flow_imp.g_varchar2_table(264) := '286E293B766F696420303D3D3D72655B6F5D26262872655B6F5D3D6C2E67657454657874576964746828652E742E636861724174286E2929292C742B3D72655B6F5D7D72657475726E20747D2865293B69662821652E737026266F2B743E5826266E2E6C';
wwv_flow_imp.g_varchar2_table(265) := '656E677468297B666F72283B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F7D292C6E3D5B5D2C6F3D307D652E73702626216E2E6C656E6774687C7C2865';
wwv_flow_imp.g_varchar2_table(266) := '2E773D742C6E2E707573682865292C6F2B3D74297D293B6E2E6C656E67746826266E5B6E2E6C656E6774682D315D2E73703B296F2D3D6E2E706F7028292E773B722E70757368287B77733A6E2C773A6F2C6C6173743A21307D292C652E7472696D28293F';
wwv_flow_imp.g_varchar2_table(267) := '28722E666F72456163682866756E6374696F6E2865297B21522626672B473E732D632D31302626286C2E6164645061676528292C673D63293B76617220743D652E77732E66696C7465722866756E6374696F6E2865297B72657475726E20652E73707D29';
wwv_flow_imp.g_varchar2_table(268) := '2E6C656E6774682C723D226A757374696679223D3D3D4A262621652E6C6173742626743F28582D652E77292F743A302C6E3D227269676874223D3D3D4A3F572B582D652E773A2263656E746572223D3D3D4A3F572B28582D652E77292F323A572C6F3D67';
wwv_flow_imp.g_varchar2_table(269) := '2B2E37352A473B652E77732E666F72456163682866756E6374696F6E2865297B76617220743D652E772B28652E73703F723A30293B6C2E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C6C2E7365744472617743';
wwv_flow_imp.g_varchar2_table(270) := '6F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C6C2E7365744C696E655769647468282E3031322A42292C652E73707C7C286C2E736574466F6E7428652E66616D2C652E66292C6C2E7465787428652E742C6E2C6F29292C652E752626';
wwv_flow_imp.g_varchar2_table(271) := '6C2E6C696E65286E2C6F2B2E30362A422C6E2B742C6F2B2E30362A42292C652E7326266C2E6C696E65286E2C6F2D2E31312A422C6E2B742C6F2D2E31312A42292C6E2B3D747D292C672B3D477D292C672B3D766F69642030213D3D542E70617261677261';
wwv_flow_imp.g_varchar2_table(272) := '70684761703F542E7061726167726170684761703A2E352A47293A672B3D477D292C6C2E73657454657874436F6C6F7228302C302C30292C766F696428523F28673D442C6C2E6C6173744175746F5461626C653D4C293A6C2E6C6173744175746F546162';
wwv_flow_imp.g_varchar2_table(273) := '6C653D7B66696E616C593A677D297D696628226C696E6561223D3D3D49297B766172206E653D6128542E636F6C6F727C7C222330303030303022293B6966286C2E73657444726177436F6C6F72286E655B305D2C6E655B315D2C6E655B325D292C6C2E73';
wwv_flow_imp.g_varchar2_table(274) := '65744C696E65576964746828542E746869636B6E6573737C7C2E33292C766F69642030213D3D542E78312972657475726E20766F6964206C2E6C696E6528542E78312C542E79312C766F69642030213D3D542E78323F542E78323A542E78312C766F6964';
wwv_flow_imp.g_varchar2_table(275) := '2030213D3D542E79323F542E79323A542E7931293B673D4D6174682E6D617828672C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A67292B28542E6761704265666F72657C7C30293B766172206F653D';
wwv_flow_imp.g_varchar2_table(276) := '542E77696474687C7C752D762D622C61653D2263656E746572223D3D3D542E616C69676E3F762B28752D762D622D6F65292F323A227269676874223D3D3D542E616C69676E3F752D622D6F653A763B72657475726E206C2E6C696E652861652C672C6165';
wwv_flow_imp.g_varchar2_table(277) := '2B6F652C67292C672B3D766F69642030213D3D542E6761703F542E6761703A322C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226573706163696F223D3D3D492972657475726E20673D4D6174682E6D6178';
wwv_flow_imp.g_varchar2_table(278) := '28672C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A67292B28542E6865696768747C7C36292C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A677D293B69662822696D6167';
wwv_flow_imp.g_varchar2_table(279) := '656E22213D3D4929696628226772616669636F22213D3D492969662822636F6469676F22213D3D49297B6966282273616C746F223D3D3D492972657475726E206C2E6164645061676528292C673D632C766F6964286C2E6C6173744175746F5461626C65';
wwv_flow_imp.g_varchar2_table(280) := '3D7B66696E616C593A637D293B69662822636F6C756D6E6173223D3D3D49297B7661722075653D762C73653D623B696628212854653D4B28542C22706466222C742C752D762D6229292E6C656E6774682972657475726E3B7661722063653D66756E6374';
wwv_flow_imp.g_varchar2_table(281) := '696F6E2865297B763D75652B652E782C623D752D2875652B652E782B652E77297D2C66653D6C2C64653D302C68653D21302C70653D4D6174682E6D617828672C772829293B69662854652E666F72456163682866756E6374696F6E2865297B6C3D6E6577';
wwv_flow_imp.g_varchar2_table(282) := '2077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572227D292C6365286529';
wwv_flow_imp.g_varchar2_table(283) := '2C673D632C6C2E6C6173744175746F5461626C653D6E756C6C2C652E736563732E666F7245616368286D292C6C2E696E7465726E616C2E6765744E756D6265724F66506167657328293E3126262868653D2131292C64653D4D6174682E6D61782864652C';
wwv_flow_imp.g_varchar2_table(284) := '4D6174682E6D617828672C772829292D63297D292C763D75652C623D73652C673D70652C286C3D6665292E6C6173744175746F5461626C653D7B66696E616C593A70657D2C2168652972657475726E20766F69642054652E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(285) := '74696F6E2865297B652E736563732E666F7245616368286D297D293B672B64653E732D632D31302626286C2E6164645061676528292C673D63293B7661722067653D672C6D653D673B72657475726E2054652E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(286) := '65297B63652865292C673D67652C6C2E6C6173744175746F5461626C653D7B66696E616C593A67657D2C652E736563732E666F7245616368286D292C6D653D4D6174682E6D6178286D652C672C772829297D292C763D75652C623D73652C673D6D652B28';
wwv_flow_imp.g_varchar2_table(287) := '766F69642030213D3D542E6761703F542E6761703A31292C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A677D297D696628226669636861223D3D3D49297B7661722062653D4328542C74295B305D7C7C7B7D2C77653D542E63';
wwv_flow_imp.g_varchar2_table(288) := '6F6C756D6E737C7C332C79653D5B5D2C45653D5B5D2C54653D7B7D3B69662828542E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E2865297B72657475726E21652E7768656E7C7C5328652E7768656E2C742C6265297D292E666F72';
wwv_flow_imp.g_varchar2_table(289) := '456163682866756E6374696F6E2865297B45652E70757368284528652E6C6162656C2C742C6265292C5A28652C742C626529292C45652E6C656E6774683D3D3D322A776526262879652E70757368284565292C45653D5B5D297D292C45652E6C656E6774';
wwv_flow_imp.g_varchar2_table(290) := '68297B666F72283B45652E6C656E6774683C322A77653B2945652E70757368282222293B79652E70757368284565297D666F72287661722053653D303B53653C322A77653B53652B3D322954655B53655D3D7B666F6E745374796C653A22626F6C64222C';
wwv_flow_imp.g_varchar2_table(291) := '63656C6C57696474683A542E6C6162656C57696474687C7C33327D3B72657475726E206C2E6175746F5461626C65287B7374617274593A672C626F64793A79652C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A';
wwv_flow_imp.g_varchar2_table(292) := '627D2C7374796C65733A7B666F6E7453697A653A542E73697A657C7C382E352C63656C6C50616464696E673A2E397D2C636F6C756D6E5374796C65733A54657D292C766F696420782832297D69662822616C6572746122213D3D49297B69662822746162';
wwv_flow_imp.g_varchar2_table(293) := '6C61223D3D3D49297B7661722043653D4328542C74293B6966282143652E6C656E67746826262131213D3D542E68696465456D707479262621542E656D707479546578742972657475726E3B7661722041653D6B28542C742C4365292C4E653D5B5D2C7A';
wwv_flow_imp.g_varchar2_table(294) := '653D7B7D3B696628542E7469746C6526264E652E70757368285B7B636F6E74656E743A4528542E7469746C652C74292C636F6C5370616E3A41652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E7453697A653A692B31';
wwv_flow_imp.g_varchar2_table(295) := '7D7D5D292C542E67726F757073297B7661722050653D5B5D2C4D653D5B5D2C6B653D7B68616C69676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B4628542C4165292E666F72456163682866756E6374696F6E2865297B666F7228';
wwv_flow_imp.g_varchar2_table(296) := '76617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B29652E6761703F50652E70757368287B636F6E74656E743A41655B745D2E6C6162656C2C726F775370616E3A322C7374796C65733A6B657D293A4D652E70757368284165';
wwv_flow_imp.g_varchar2_table(297) := '5B745D2E6C6162656C293B652E6761707C7C50652E70757368287B636F6E74656E743A652E6C6162656C2C636F6C5370616E3A652E636F6C732C7374796C65733A6B657D297D292C4E652E707573682850652C4D65297D656C7365204E652E7075736828';
wwv_flow_imp.g_varchar2_table(298) := '41652E6D61702866756E6374696F6E2865297B72657475726E20652E6C6162656C7D29293B41652E666F72456163682866756E6374696F6E28652C74297B7A655B745D3D7B68616C69676E3A652E616C69676E7D2C652E636F6C6F722626287A655B745D';
wwv_flow_imp.g_varchar2_table(299) := '2E74657874436F6C6F723D6128652E636F6C6F7229292C652E626F6C642626287A655B745D2E666F6E745374796C653D22626F6C6422292C652E77696474682626287A655B745D2E63656C6C57696474683D652E7769647468297D293B7661722046653D';
wwv_flow_imp.g_varchar2_table(300) := '5628542C4365292C49653D712854292C4F653D61286F2E67726F7570292C6A653D5B5D3B79653D43652E6C656E6774683F5B5D3A5B5B7B636F6E74656E743A4528542E656D707479546578742C74292C636F6C5370616E3A41652E6C656E6774682C7374';
wwv_flow_imp.g_varchar2_table(301) := '796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A226974616C6963227D7D5D5D3B43652E6C656E677468262646652E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B2972657475726E20';
wwv_flow_imp.g_varchar2_table(302) := '79652E70757368285B7B636F6E74656E743A2428542C652C74292C636F6C5370616E3A41652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A22626F6C64222C66696C6C436F6C6F723A4F657D7D5D29';
wwv_flow_imp.g_varchar2_table(303) := '2C766F6964206A652E707573682865293B2273756222213D3D652E6B3F2879652E707573682841652E6D61702866756E6374696F6E2872297B72657475726E204F28722C652E722C74297D29292C6A652E70757368286529293A59285F2841652C49652C';
wwv_flow_imp.g_varchar2_table(304) := '652E726F77732C2428542C652C7429292C41652E6C656E677468292E666F72456163682866756E6374696F6E2874297B79652E707573682874292C6A652E707573682865297D297D293B7661722052653D6E756C6C2C44653D5528542E746F74616C7329';
wwv_flow_imp.g_varchar2_table(305) := '3B44652E6C656E677468262643652E6C656E67746826262852653D59285F2841652C44652C43652C4828542C742C436529292C41652E6C656E67746829292C6C2E6175746F5461626C65287B7374617274593A672C6D617267696E3A7B6C6566743A762C';
wwv_flow_imp.g_varchar2_table(306) := '72696768743A627D2C686561643A4E652C626F64793A79652C666F6F743A52657C7C766F696420302C73686F77486561643A21313D3D3D542E7265706561744865616465723F22666972737450616765223A22657665727950616765222C73686F77466F';
wwv_flow_imp.g_varchar2_table(307) := '6F743A226C61737450616765222C7374796C65733A7B666F6E7453697A653A542E73697A657C7C692C63656C6C50616464696E673A2E387D2C686561645374796C65733A7B66696C6C436F6C6F723A662C74657874436F6C6F723A642C68616C69676E3A';
wwv_flow_imp.g_varchar2_table(308) := '2263656E746572222C666F6E7453697A653A542E73697A657C7C697D2C666F6F745374796C65733A7B66696C6C436F6C6F723A702C74657874436F6C6F723A302C666F6E745374796C653A22626F6C64222C68616C69676E3A227269676874227D2C616C';
wwv_flow_imp.g_varchar2_table(309) := '7465726E617465526F775374796C65733A542E627265616B42793F7B7D3A7B66696C6C436F6C6F723A687D2C636F6C756D6E5374796C65733A7A652C646964506172736543656C6C3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73';
wwv_flow_imp.g_varchar2_table(310) := '656374696F6E262643652E6C656E677468297B766172206E3D6A655B652E726F772E696E6465785D3B6966286E2626226865616422213D3D6E2E6B297B69662822737562223D3D3D6E2E6B2972657475726E20652E63656C6C2E7374796C65732E66696C';
wwv_flow_imp.g_varchar2_table(311) := '6C436F6C6F723D702C766F696428652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C6422293B766172206F3D6E2E722C693D41655B652E636F6C756D6E2E696E6465785D3B542E627265616B4279262628652E63656C6C2E7374796C';
wwv_flow_imp.g_varchar2_table(312) := '65732E66696C6C436F6C6F723D6E2E6925323D3D3126262131213D3D542E7A656272613F683A5B3235352C3235352C3235355D293B766172206C3D4E28542E726F775374796C652C742C6F293B6C2626286C2E66696C6C262628652E63656C6C2E737479';
wwv_flow_imp.g_varchar2_table(313) := '6C65732E66696C6C436F6C6F723D61286C2E66696C6C29292C6C2E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D61286C2E636F6C6F7229292C6C2E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374';
wwv_flow_imp.g_varchar2_table(314) := '796C653D22626F6C642229293B76617220753D6926264E28692E63656C6C5374796C652C742C6F293B75262628752E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D6128752E66696C6C29292C752E636F6C6F7226262865';
wwv_flow_imp.g_varchar2_table(315) := '2E63656C6C2E7374796C65732E74657874436F6C6F723D6128752E636F6C6F7229292C752E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229292C722626722E70646643656C6C2626722E70646643656C6C';
wwv_flow_imp.g_varchar2_table(316) := '28652C6F2C692C542C74297D7D7D7D292C7828542E6761707C7C33297D7D656C7365204328542C74292E66696C7465722866756E6374696F6E2865297B72657475726E205328542E7768656E2C742C65297D292E736C69636528302C542E656163683F39';
wwv_flow_imp.g_varchar2_table(317) := '39393A31292E666F72456163682866756E6374696F6E2865297B6C2E6175746F5461626C65287B7374617274593A672C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A762C72696768743A627D2C626F64793A5B5B4528542E746578';
wwv_flow_imp.g_varchar2_table(318) := '742C742C65295D5D2C7374796C65733A7B666F6E7453697A653A542E73697A657C7C382C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A61284128542E636F6C6F722C742C65297C7C222345';
wwv_flow_imp.g_varchar2_table(319) := '364543463222297D7D292C782831297D297D656C73657B7661722055653D766528542C74293B6966282155652972657475726E3B766172204C653D55652E6C6162656C3F2E333532382A55652E7465787453697A652A312E343A303B7928542C55652E77';
wwv_flow_imp.g_varchar2_table(320) := '2C55652E682B4C652C66756E6374696F6E28652C74297B76617220723D55652E772F55652E636F6C732C6E3D55652E682F55652E726F77732C6F3D612855652E636F6C6F72293B6C2E73657446696C6C436F6C6F72286F5B305D2C6F5B315D2C6F5B325D';
wwv_flow_imp.g_varchar2_table(321) := '293B666F722876617220693D303B693C55652E726F77733B692B2B29666F722876617220753D303B753C55652E636F6C733B752B2B2969662855652E6461726B28752C6929297B666F722876617220733D753B752B313C55652E636F6C73262655652E64';
wwv_flow_imp.g_varchar2_table(322) := '61726B28752B312C69293B29752B2B3B6C2E7265637428652B732A722C742B692A6E2C28752D732B31292A722C6E2B28693C55652E726F77732D313F2E30323A30292C224622297D55652E6C6162656C2626286C2E736574466F6E742822636F75726965';
wwv_flow_imp.g_varchar2_table(323) := '72222C226E6F726D616C22292C6C2E736574466F6E7453697A652855652E7465787453697A65292C6C2E73657454657874436F6C6F72286F5B305D2C6F5B315D2C6F5B325D292C6C2E746578742855652E746578742C652B55652E772F322C742B55652E';
wwv_flow_imp.g_varchar2_table(324) := '682B2E333532382A55652E7465787453697A652A312E312C7B616C69676E3A2263656E746572227D292C6C2E73657454657874436F6C6F7228302C302C3029297D297D656C73657B7661722042653D786528542C742C6F293B6966282142652972657475';
wwv_flow_imp.g_varchar2_table(325) := '726E3B7928542C42652E776D6D2C42652E686D6D2C66756E6374696F6E28652C74297B6C2E616464496D6167652842652E646174612C22504E47222C652C742C42652E776D6D2C42652E686D6D2C766F696420302C224641535422297D297D656C73657B';
wwv_flow_imp.g_varchar2_table(326) := '7661722047653D696528542C74293B6966282147652972657475726E3B7661722057653D6C6528542C4765292C5F653D226A7067223D3D3D47652E6578743F224A504547223A22504E47223B7928542C57652E772C57652E682C66756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(327) := '2C74297B6C2E616464496D6167652847652E646174612C5F652C652C742C57652E772C57652E68297D297D7D292C492E746F3D6C2E696E7465726E616C2E6765744E756D6265724F66506167657328297D292C542E666F72456163682866756E6374696F';
wwv_flow_imp.g_varchar2_table(328) := '6E2874297B76617220723D796528652C742E637478293B69662872297B6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C6C2E736574466F6E7453697A6528313030293B766172206E3D456528722C6C2E676574546578745769';
wwv_flow_imp.g_varchar2_table(329) := '64746828722E74657874292C752C73292C6F3D722E616E676C652A4D6174682E50492F3138302C693D6128722E636F6C6F72293B6C2E736574466F6E7453697A65286E293B666F722876617220633D6C2E67657454657874576964746828722E74657874';
wwv_flow_imp.g_varchar2_table(330) := '292C663D2E333532382A6E2A2E372C643D752F322D632F322A4D6174682E636F73286F292B662F322A4D6174682E73696E286F292C683D732F322B632F322A4D6174682E73696E286F292B662F322A4D6174682E636F73286F292C703D742E66726F6D3B';
wwv_flow_imp.g_varchar2_table(331) := '703C3D742E746F3B702B2B296C2E736574506167652870292C6C2E736176654772617068696373537461746528292C6C2E736574475374617465286E6577206C2E475374617465287B6F7061636974793A722E6F7061636974797D29292C6C2E73657454';
wwv_flow_imp.g_varchar2_table(332) := '657874436F6C6F7228695B305D2C695B315D2C695B325D292C6C2E7465787428722E746578742C642C682C7B616E676C653A722E616E676C657D292C6C2E726573746F72654772617068696373537461746528293B6C2E73657454657874436F6C6F7228';
wwv_flow_imp.g_varchar2_table(333) := '302C302C30297D7D293B76617220493D652E666F6F7465722C6A3D6C2E696E7465726E616C2E6765744E756D6265724F66506167657328292C523D745B305D7C7C7B533A7B7D2C543A7B7D7D3B69662849297B666F722876617220443D313B443C3D6A3B';
wwv_flow_imp.g_varchar2_table(334) := '442B2B297B6C2E736574506167652844292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C2E736574466F6E7453697A6528492E73697A657C7C37293B766172204C3D61286F2E6D75746564293B6C2E736574546578';
wwv_flow_imp.g_varchar2_table(335) := '74436F6C6F72284C5B305D2C4C5B315D2C4C5B325D293B76617220423D66756E6374696F6E2865297B72657475726E204528652C52292E7265706C61636528227B504147457D222C44292E7265706C61636528227B50414745537D222C6A297D3B696628';
wwv_flow_imp.g_varchar2_table(336) := '492E6C656674297B76617220473D6C2E73706C697454657874546F53697A65284228492E6C656674292C2E37382A75293B6C2E7465787428472C632C732D342D28472E6C656E6774682D31292A28492E73697A657C7C37292A2E34297D492E7269676874';
wwv_flow_imp.g_varchar2_table(337) := '26266C2E74657874284228492E7269676874292C752D632C732D352C7B616C69676E3A227269676874227D297D6C2E73657454657874436F6C6F7228302C302C30297D72657475726E20652E7469746C6526266C2E73657450726F70657274696573287B';
wwv_flow_imp.g_varchar2_table(338) := '7469746C653A4528652E7469746C652C52297D292C50726F6D6973652E7265736F6C7665286C2E6F7574707574282261727261796275666665722229297D66756E6374696F6E20536528652C742C72297B766172206E3D6E65772077696E646F772E4578';
wwv_flow_imp.g_varchar2_table(339) := '63656C4A532E576F726B626F6F6B2C613D65652865292C6C3D7B7D3B6E2E63726561746F723D226E6F76615265706F7274223B76617220753D652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C73';
wwv_flow_imp.g_varchar2_table(340) := '782E73686565744E616D657C7C225265706F727465227D5D2C733D5828652C22786C737822292C633D652E706167657C7C7B7D2C663D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A';
wwv_flow_imp.g_varchar2_table(341) := '6928612E7072696D617279297D7D3B66756E6374696F6E206D2865297B72657475726E7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A692865297D7D7D72657475726E20742E666F72';
wwv_flow_imp.g_varchar2_table(342) := '456163682866756E6374696F6E2872297B752E666F72456163682866756E6374696F6E2876297B76617220623D4528762E6E616D652C72293B75652626742E6C656E6774683E31262628623D4528762E6D657267654E616D657C7C28752E6C656E677468';
wwv_flow_imp.g_varchar2_table(343) := '3E313F227B444F432E444F435F4B45597D20222B762E6E616D653A227B444F432E444F435F4B45597D22292C7229293B76617220773D6E2E616464576F726B73686565742866756E6374696F6E2865297B666F722876617220743D682865292E7265706C';
wwv_flow_imp.g_varchar2_table(344) := '616365282F5B5C5B5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C723D742C6E3D323B6C5B722E746F4C6F7765724361736528295D3B29723D742E73756273747228302C33312D537472696E67286E292E6C656E6774682D';
wwv_flow_imp.g_varchar2_table(345) := '31292B225F222B6E2C6E2B2B3B72657475726E206C5B722E746F4C6F7765724361736528295D3D21302C727D2862292C7B7061676553657475703A7B6F7269656E746174696F6E3A632E6F7269656E746174696F6E7C7C22706F727472616974222C7061';
wwv_flow_imp.g_varchar2_table(346) := '70657253697A653A226C6567616C223D3D3D632E73697A653F353A226134223D3D3D632E73697A653F393A312C666974546F506167653A21302C666974546F57696474683A312C666974546F4865696768743A307D7D292C783D762E73656374696F6E73';
wwv_flow_imp.g_varchar2_table(347) := '3F762E73656374696F6E732E6D61702866756E6374696F6E2865297B72657475726E226E756D626572223D3D747970656F6620653F735B655D3A732E66696C7465722866756E6374696F6E2874297B72657475726E20742E69643D3D3D657D295B305D7D';
wwv_flow_imp.g_varchar2_table(348) := '292E66696C74657228426F6F6C65616E293A733B783D782E66696C7465722866756E6374696F6E2865297B72657475726E205128652C72297D293B76617220543D342C4F3D312C593D7B7D2C583D302C4A3D6E756C6C2C65653D6E756C6C2C74653D6675';
wwv_flow_imp.g_varchar2_table(349) := '6E6374696F6E2865297B72657475726E20652E7265647563652866756E6374696F6E28652C74297B72657475726E204D6174682E6D617828652C227461626C61223D3D3D742E747970653F6B28742C722C4328742C7229292E6C656E6774683A22666963';
wwv_flow_imp.g_varchar2_table(350) := '6861223D3D3D742E747970653F322A28742E636F6C756D6E737C7C33293A22746578746F223D3D3D742E747970657C7C22616C65727461223D3D3D742E747970653F343A32297D2C32297D3B66756E6374696F6E20726528652C74297B76617220723D53';
wwv_flow_imp.g_varchar2_table(351) := '7472696E67286E756C6C3D3D743F22223A74292E6C656E6774683B595B652B3D6E655D3D4D6174682E6D696E2836302C4D6174682E6D617828595B655D7C7C382C722B3229297D782E666F72456163682866756E6374696F6E2865297B22636F6C756D6E';
wwv_flow_imp.g_varchar2_table(352) := '6173223D3D3D652E74797065262628543D4D6174682E6D617828542C4B28652C22786C7378222C722C313030292E7265647563652866756E6374696F6E28652C74297B72657475726E20652B746528742E73656373292B317D2C2D312929292C22746162';
wwv_flow_imp.g_varchar2_table(353) := '6C61223D3D3D652E74797065262628582B2B2C543D4D6174682E6D617828542C6B28652C722C4328652C7229292E6C656E67746829292C226669636861223D3D3D652E74797065262628543D4D6174682E6D617828542C322A28652E636F6C756D6E737C';
wwv_flow_imp.g_varchar2_table(354) := '7C332929297D293B766172206E653D302C6F653D21313B66756E6374696F6E20616528652C74297B72657475726E20772E67657443656C6C28652C742B6E65297D66756E6374696F6E20756528652C742C722C6E297B772E6D6572676543656C6C732865';
wwv_flow_imp.g_varchar2_table(355) := '2C742B6E652C722C6E2B6E65297D66756E6374696F6E20736528652C74297B76617220723D772E676574526F772865293B722E6865696768743D4D6174682E6D617828722E6865696768747C7C302C74297D66756E6374696F6E20636528652C742C722C';
wwv_flow_imp.g_varchar2_table(356) := '6F297B76617220613D6E2E616464496D616765287B6261736536343A652E646174612C657874656E73696F6E3A226A7067223D3D3D652E6578743F226A706567223A22706E67227D293B772E616464496D61676528612C7B746C3A7B636F6C3A6E652C72';
wwv_flow_imp.g_varchar2_table(357) := '6F773A4F2D317D2C6578743A7B77696474683A332E37382A742C6865696768743A332E37382A727D7D292C4F2B3D4D6174682E6365696C28332E37382A722F3230292B286F3F303A31297D66756E6374696F6E20666528652C742C722C6E297B7565284F';
wwv_flow_imp.g_varchar2_table(358) := '2C312C4F2C54293B766172206F3D6165284F2C31293B6F2E76616C75653D652C6F2E66696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6E2626736528';
wwv_flow_imp.g_varchar2_table(359) := '4F2C6F653F4D6174682E6D6178286E2C31352A4D6174682E6365696C28537472696E6728657C7C2222292E6C656E6774682F4D6174682E6D61782831362C392A542929293A6E292C4F2B2B7D782E666F72456163682866756E6374696F6E2074286E297B';
wwv_flow_imp.g_varchar2_table(360) := '766172206C3D6E2E747970653B69662822636F6C756D6E6173223D3D3D6C297B76617220753D4F2C733D4F2C633D6E652C683D542C763D303B72657475726E206F653D21302C4B286E2C22786C7378222C722C313030292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(361) := '74696F6E2865297B76617220723D746528652E73656373293B6E653D632B762C543D722C4F3D752C652E736563732E666F72456163682874292C733D4D6174682E6D617828732C4F292C762B3D722B317D292C6E653D632C543D682C6F653D21312C766F';
wwv_flow_imp.g_varchar2_table(362) := '6964284F3D73297D69662822686561646572223D3D3D6C2966652845286E2E7469746C652C72292C662C7B626F6C643A21302C73697A653A31342C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C3236292C286E2E72696768747C';
wwv_flow_imp.g_varchar2_table(363) := '7C6E2E7375627469746C652926266665285B45286E2E7375627469746C652C72292C45286E2E72696768742C72295D2E66696C74657228426F6F6C65616E292E6A6F696E28222020207C20202022292C662C7B73697A653A392C636F6C6F723A7B617267';
wwv_flow_imp.g_varchar2_table(364) := '623A6928612E6865616454657874297D7D2C3136292C4F2B2B3B656C73652069662822746578746F223D3D3D6C294D286E2C72292E666F72456163682866756E6374696F6E2874297B7565284F2C312C4F2C54293B76617220723D6165284F2C31293B72';
wwv_flow_imp.g_varchar2_table(365) := '2E76616C75653D7B72696368546578743A5028742C7B666F6E743A6E2E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A6E2E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E7B746578743A65';
wwv_flow_imp.g_varchar2_table(366) := '2E742C666F6E743A7B626F6C643A212821652E622626216E2E626F6C64292C6974616C69633A212821652E692626216E2E6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F696420302C6E61';
wwv_flow_imp.g_varchar2_table(367) := '6D653A7A5B652E665D5B315D2C636F6C6F723A652E633F7B617267623A6928652E63297D3A766F696420302C73697A653A6E2E73697A657C7C31307D7D7D297D2C722E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22';
wwv_flow_imp.g_varchar2_table(368) := '746F70222C686F72697A6F6E74616C3A226A757374696679223D3D3D6E2E616C69676E3F226A757374696679223A6E2E616C69676E7C7C226C656674227D2C7365284F2C4D6174682E6D61782831352C31352A4D6174682E6365696C28742E6C656E6774';
wwv_flow_imp.g_varchar2_table(369) := '682F286F653F4D6174682E6D61782831362C392A54293A313430292929292C4F2B2B7D293B656C736520696628226573706163696F223D3D3D6C294F2B2B3B656C73652069662822696D6167656E223D3D3D6C297B76617220623D6965286E2C72293B69';
wwv_flow_imp.g_varchar2_table(370) := '662862297B76617220593D6C65286E2C62293B636528622C592E772C592E68297D7D656C736520696628226772616669636F223D3D3D6C297B76617220513D7865286E2C722C61293B512626636528512C512E776D6D2C512E686D6D297D656C73652069';
wwv_flow_imp.g_varchar2_table(371) := '662822636F6469676F223D3D3D6C297B7661722064653D7665286E2C72293B6966286465297B7661722068653D6265286465293B69662863652868652C68652E776D6D2C68652E686D6D2C64652E6C6162656C292C64652E6C6162656C297B7661722070';
wwv_flow_imp.g_varchar2_table(372) := '653D6165284F2C31293B70652E76616C75653D64652E746578742C70652E666F6E743D7B6E616D653A22436F7572696572204E6577222C73697A653A64652E7465787453697A657D2C4F2B3D327D7D7D656C7365206966282273616C746F223D3D3D6C29';
wwv_flow_imp.g_varchar2_table(373) := '4F2B2B3B656C736520696628226669636861223D3D3D6C297B7661722067653D43286E2C72295B305D7C7C7B7D2C6D653D6E2E636F6C756D6E737C7C332C77653D313B286E2E6669656C64737C7C5B5D292E66696C7465722866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(374) := '7B72657475726E21652E7768656E7C7C5328652E7768656E2C722C6765297D292E666F72456163682866756E6374696F6E28652C74297B743E30262674256D653D3D3D302626284F2B2B2C77653D31293B766172206E3D6165284F2C7765292C613D6165';
wwv_flow_imp.g_varchar2_table(375) := '284F2C77652B31292C693D4528652E6C6162656C2C722C6765293B6E2E76616C75653D692C6E2E666F6E743D7B626F6C643A21307D3B766172206C3D2F5E5C7B5B5E7D7C5D2B5C7D242F2E7465737428652E76616C75657C7C222229262621652E6D6170';
wwv_flow_imp.g_varchar2_table(376) := '3F7928722C652E76616C75652E736C69636528312C2D31292C6765293A6E756C6C3B6F286C292626216728652E666D74293F28612E76616C75653D6C2C226D6F6E6579223D3D3D652E666D74262628612E6E756D466D743D22232C2323302E303022292C';
wwv_flow_imp.g_varchar2_table(377) := '612E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D293A2264617465223D3D3D652E666D74262664286C293F28612E76616C75653D64286C292C612E6E756D466D743D2264642F6D6D2F79797979222C612E616C69676E6D656E';
wwv_flow_imp.g_varchar2_table(378) := '743D7B686F72697A6F6E74616C3A226C656674227D293A612E76616C75653D5A28652C722C6765292C72652877652C69292C72652877652B312C5A28652C722C676529292C77652B3D327D292C4F2B3D327D656C73652069662822616C65727461223D3D';
wwv_flow_imp.g_varchar2_table(379) := '3D6C2943286E2C72292E66696C7465722866756E6374696F6E2865297B72657475726E2053286E2E7768656E2C722C65297D292E736C69636528302C6E2E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B66652845286E';
wwv_flow_imp.g_varchar2_table(380) := '2E746578742C722C65292C6D2841286E2E636F6C6F722C722C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D292C4F2B2B3B656C736520696628227461626C61223D3D3D6C297B7661722079653D43286E2C72293B6966282179';
wwv_flow_imp.g_varchar2_table(381) := '652E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B7661722045653D6B286E2C722C7965293B6966286E2E7469746C65297B7565284F2C312C4F2C45652E6C656E677468293B766172';
wwv_flow_imp.g_varchar2_table(382) := '2054653D6165284F2C31293B54652E76616C75653D45286E2E7469746C652C72292C54652E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C54652E66696C6C3D662C4F2B2B7D6966286E2E6772';
wwv_flow_imp.g_varchar2_table(383) := '6F757073297B7661722053653D313B46286E2C4565292E666F72456163682866756E6374696F6E2865297B652E636F6C733E31262621652E67617026267565284F2C53652C4F2C53652B652E636F6C732D31293B76617220743D6165284F2C5365293B69';
wwv_flow_imp.g_varchar2_table(384) := '6628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B7565284F2C53652B722C4F2B312C53652B72293B766172206E3D6165284F2C53652B72293B6E2E76616C75653D45655B652E66726F6D2B725D2E6C6162656C2C6E';
wwv_flow_imp.g_varchar2_table(385) := '2E66696C6C3D662C6E2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C6E2E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C';
wwv_flow_imp.g_varchar2_table(386) := '65222C77726170546578743A21307D2C72652853652B722C45655B652E66726F6D2B725D2E6C6162656C297D53652B3D652E636F6C737D656C736520742E76616C75653D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D662C742E666F6E743D7B62';
wwv_flow_imp.g_varchar2_table(387) := '6F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C742E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65227D2C53652B3D652E636F6C737D292C';
wwv_flow_imp.g_varchar2_table(388) := '4F2B2B7D7661722043653D4F2C41653D7B7D3B6966286E2E67726F757073262646286E2C4565292E666F72456163682866756E6374696F6E2865297B696628652E67617029666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C';
wwv_flow_imp.g_varchar2_table(389) := '733B742B2B2941655B745D3D317D292C45652E666F72456163682866756E6374696F6E28652C74297B6966282141655B745D297B76617220723D6165284F2C742B31293B722E76616C75653D652E6C6162656C2C722E66696C6C3D662C722E666F6E743D';
wwv_flow_imp.g_varchar2_table(390) := '7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C722E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65222C77726170546578743A21307D';
wwv_flow_imp.g_varchar2_table(391) := '2C726528742B312C652E6C6162656C297D7D292C4F2B2B2C2179652E6C656E6774682972657475726E207565284F2C312C4F2C45652E6C656E677468292C6165284F2C31292E76616C75653D45286E2E656D707479546578742C72292C6165284F2C3129';
wwv_flow_imp.g_varchar2_table(392) := '2E666F6E743D7B6974616C69633A21307D2C766F6964284F2B3D32293B766172204E653D4F2C7A653D56286E2C7965292C50653D71286E292C4D653D6E756C6C2C6B653D66756E6374696F6E28652C742C722C6E2C6F2C692C6C297B76617220753D5F28';
wwv_flow_imp.g_varchar2_table(393) := '45652C742C722C6E292C733D422874292C633D66756E6374696F6E2865297B72657475726E20652E66696C6C3D6D28612E746F74616C73292C652E666F6E743D7B626F6C643A21307D2C657D3B28752E61743E317C7C303D3D3D752E6174292626756528';
wwv_flow_imp.g_varchar2_table(394) := '652C312C652C752E61747C7C45652E6C656E677468293B76617220663D6328616528652C3129293B72657475726E20662E76616C75653D6E2C662E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C656674227D2C303D3D3D752E6174262665';
wwv_flow_imp.g_varchar2_table(395) := '2B2B2C45652E666F72456163682866756E6374696F6E286E2C61297B6966282128613C752E617429297B76617220663D6328616528652C612B3129292C683D6E2E636F6C3F4C28742C6E2E636F6C293A6E756C6C3B69662868297B76617220673D772E67';
wwv_flow_imp.g_varchar2_table(396) := '6574436F6C756D6E28612B312B6E65292E6C65747465722C6D3D672B6F2B223A222B672B692C763D5728722C682E636F6C2C682E666E292C623D226D696E22213D3D682E666E2626226D617822213D3D682E666E7C7C6E756C6C3D3D3D767C7C47287629';
wwv_flow_imp.g_varchar2_table(397) := '3F6E756C6C3A642876292C783D6E756C6C3D3D763F6E756C6C3A627C7C28472876293F4D6174682E726F756E64283130302A4E756D626572287629292F3130303A537472696E67287629293B662E76616C75653D7B666F726D756C613A286C3F22535542';
wwv_flow_imp.g_varchar2_table(398) := '544F54414C28222B6A5B682E666E5D2B222C223A525B682E666E5D2B222822292B6D2B2229222C726573756C743A787D3B76617220793D22636F756E74223D3D3D682E666E3F22232C232330223A623F2264642F6D6D2F79797979223A22232C2323302E';
wwv_flow_imp.g_varchar2_table(399) := '3030223B662E6E756D466D743D732626445B682E666E5D3F2722272B445B682E666E5D2B272022272B793A792C662E616C69676E6D656E743D7B686F72697A6F6E74616C3A227269676874227D2C6E756C6C3D3D3D787C7C627C7C726528612B312C4728';
wwv_flow_imp.g_varchar2_table(400) := '78293F7028782C226D6F6E657922293A78297D7D7D292C652B317D3B7A652E666F72456163682866756E6374696F6E2865297B6966282268656164223D3D3D652E6B297B7565284F2C312C4F2C45652E6C656E677468293B76617220743D6165284F2C31';
wwv_flow_imp.g_varchar2_table(401) := '293B72657475726E20742E76616C75653D24286E2C652C72292C742E666F6E743D7B626F6C643A21307D2C742E66696C6C3D6D28612E67726F7570292C766F6964204F2B2B7D69662822737562223D3D3D652E6B2972657475726E204F3D6B65284F2C50';
wwv_flow_imp.g_varchar2_table(402) := '652C652E726F77732C24286E2C652C72292C4D652C4F2D312C2130292C766F6964284D653D6E756C6C293B6E756C6C3D3D3D4D652626284D653D4F293B766172206C3D652E722C753D652E692C733D4E286E2E726F775374796C652C722C6C293B45652E';
wwv_flow_imp.g_varchar2_table(403) := '666F72456163682866756E6374696F6E28652C74297B76617220633D6165284F2C742B31292C663D4928652C6C2C72293B652E69734E756D26266F2866293F28632E76616C75653D662C632E6E756D466D743D22696E74223D3D3D652E666D743F22232C';
wwv_flow_imp.g_varchar2_table(404) := '232330223A226D6F6E6579223D3D3D652E666D747C7C2F5E6E756D2F2E7465737428652E666D747C7C2222293F22232C2323302E222B6E657720417272617928312A2828652E666D747C7C2222292E73706C697428223A22295B315D7C7C32292B31292E';
wwv_flow_imp.g_varchar2_table(405) := '6A6F696E28223022293A2247656E6572616C22293A226461746522213D3D652E666D742626224441544522213D3D28722E545B537472696E67286E2E736F75726365292E746F55707065724361736528295D7C7C7B7D295B652E636F6C5D7C7C21642866';
wwv_flow_imp.g_varchar2_table(406) := '293F632E76616C75653D6E756C6C3D3D663F6E756C6C3A6728652E666D7429262621652E6D61703F7028662C652E666D74293A537472696E672866293A28632E76616C75653D642866292C632E6E756D466D743D2264642F6D6D2F7979797922292C632E';
wwv_flow_imp.g_varchar2_table(407) := '616C69676E6D656E743D7B686F72697A6F6E74616C3A652E616C69676E7D3B76617220683D4E28652E63656C6C5374796C652C722C6C297C7C733B682626682E66696C6C3F632E66696C6C3D6D28682E66696C6C293A7525323D3D3126262131213D3D6E';
wwv_flow_imp.g_varchar2_table(408) := '2E7A65627261262628632E66696C6C3D6D28612E7A6562726129293B76617220763D7B7D3B28652E626F6C647C7C682626682E626F6C6429262628762E626F6C643D2130292C28682626682E636F6C6F727C7C652E636F6C6F7229262628762E636F6C6F';
wwv_flow_imp.g_varchar2_table(409) := '723D7B617267623A6928682626682E636F6C6F727C7C652E636F6C6F72297D292C28762E626F6C647C7C762E636F6C6F7229262628632E666F6E743D76292C726528742B312C652E69734E756D3F7028662C652E666D74293A66297D292C4F2B2B7D293B';
wwv_flow_imp.g_varchar2_table(410) := '7661722046653D4F2D312C49653D55286E2E746F74616C73293B49652E6C656E6774682626284F3D6B65284F2C49652C79652C48286E2C722C7965292C4E652C4F2D312C21216E2E627265616B427929292C31213D3D587C7C6E2E627265616B42797C7C';
wwv_flow_imp.g_varchar2_table(411) := '6F657C7C2865653D7B66726F6D3A7B726F773A43652C636F6C756D6E3A317D2C746F3A7B726F773A46652C636F6C756D6E3A45652E6C656E6774687D7D2C782E696E6465784F66286E293C3D312626284A3D436529292C4F2B2B7D7D292C4F626A656374';
wwv_flow_imp.g_varchar2_table(412) := '2E6B6579732859292E666F72456163682866756E6374696F6E2865297B772E676574436F6C756D6E282B65292E77696474683D595B655D7D292C6565262628772E6175746F46696C7465723D6565292C4A262628772E76696577733D5B7B73746174653A';
wwv_flow_imp.g_varchar2_table(413) := '2266726F7A656E222C7953706C69743A4A7D5D292C652E666F6F746572262628772E686561646572466F6F7465722E6F6464466F6F7465723D22264C2638222B4528652E666F6F7465722E6C6566742C72292E7265706C616365282F262F672C22262622';
wwv_flow_imp.g_varchar2_table(414) := '292E73756273747228302C323030292B222652263850C3A167696E6120265020646520264E22297D297D292C6E2E786C73782E777269746542756666657228297D7661722043653D7B6C65747465723A5B31323234302C31353834305D2C6C6567616C3A';
wwv_flow_imp.g_varchar2_table(415) := '5B31323234302C32303136305D2C61343A5B31313930362C31363833385D7D3B66756E6374696F6E20416528652C742C72297B766172206E3D77696E646F772E646F63782C6F3D5B5D2C613D4D6174682E726F756E6428322A28652E73697A657C7C3729';
wwv_flow_imp.g_varchar2_table(416) := '292C693D6C28722E6D75746564293B66756E6374696F6E20752865297B76617220723D4528652C74292E73706C6974282F285C7B50414745533F5C7D292F292C6F3D5B5D3B72657475726E20722E666F72456163682866756E6374696F6E2865297B227B';
wwv_flow_imp.g_varchar2_table(417) := '504147457D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E43555252454E545D2C73697A653A612C636F6C6F723A697D29293A227B50414745537D223D3D3D653F6F2E70';
wwv_flow_imp.g_varchar2_table(418) := '757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E544F54414C5F50414745535D2C73697A653A612C636F6C6F723A697D29293A6526266F2E70757368286E6577206E2E5465787452756E287B7465';
wwv_flow_imp.g_varchar2_table(419) := '78743A652C73697A653A612C636F6C6F723A697D29297D292C6F7D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A7528652E6C656674297D29292C652E726967687426266F2E70';
wwv_flow_imp.g_varchar2_table(420) := '757368286E6577206E2E506172616772617068287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E3A7528652E7269676874297D29292C6F2E6C656E6774683F6F3A5B6E6577206E2E506172616772';
wwv_flow_imp.g_varchar2_table(421) := '617068287B6368696C6472656E3A5B5D7D295D7D66756E6374696F6E204E6528652C74297B76617220723D77696E646F772E646F63782C6E3D65652865292C6F3D652E706167657C7C7B7D2C613D43655B6F2E73697A657C7C226C6574746572225D7C7C';
wwv_flow_imp.g_varchar2_table(422) := '43652E6C65747465722C693D226C616E647363617065223D3D3D6F2E6F7269656E746174696F6E2C753D4D6174682E726F756E642835362E372A286F2E6D617267696E7C7C31322E3729292C733D28693F615B315D3A615B305D292D322A752C633D7B73';
wwv_flow_imp.g_varchar2_table(423) := '74796C653A722E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A22464646464646227D2C663D7B746F703A632C626F74746F6D3A632C6C6566743A632C72696768743A632C696E73696465486F72697A6F6E74616C3A632C69';
wwv_flow_imp.g_varchar2_table(424) := '6E73696465566572746963616C3A637D2C643D7B7374796C653A722E426F726465725374796C652E53494E474C452C73697A653A322C636F6C6F723A22424643394434227D2C683D7B746F703A642C626F74746F6D3A642C6C6566743A642C7269676874';
wwv_flow_imp.g_varchar2_table(425) := '3A642C696E73696465486F72697A6F6E74616C3A642C696E73696465566572746963616C3A647D2C703D4D6174682E726F756E6428322A286E2E666F6E7453697A657C7C3729293B66756E6374696F6E206728652C74297B72657475726E20743D747C7C';
wwv_flow_imp.g_varchar2_table(426) := '7B7D2C6E657720722E5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C73697A653A742E73697A657C7C702C636F6C6F723A742E';
wwv_flow_imp.g_varchar2_table(427) := '636F6C6F723F6C28742E636F6C6F72293A766F696420302C666F6E743A2243616C69627269227D297D66756E6374696F6E206D28652C74297B72657475726E20743D747C7C7B7D2C6E657720722E506172616772617068287B6368696C6472656E3A5B67';
wwv_flow_imp.g_varchar2_table(428) := '28652C74295D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E743A227269676874223D3D3D742E616C69676E3F722E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D742E616C69';
wwv_flow_imp.g_varchar2_table(429) := '676E3F722E416C69676E6D656E74547970652E43454E5445523A722E416C69676E6D656E74547970652E4C4546547D297D66756E6374696F6E207628652C74297B72657475726E20743D747C7C7B7D2C6E657720722E5461626C6543656C6C287B636869';
wwv_flow_imp.g_varchar2_table(430) := '6C6472656E3A5B6D28652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A742E66696C6C3F7B747970653A722E';
wwv_flow_imp.g_varchar2_table(431) := '53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6C28742E66696C6C297D3A766F696420307D297D66756E6374696F6E206228297B72657475726E206E657720722E506172616772617068287B6368696C647265';
wwv_flow_imp.g_varchar2_table(432) := '6E3A5B5D2C73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D66756E6374696F6E207728652C742C6E2C6F2C61297B72657475726E206E657720722E506172616772617068287B616C69676E6D656E743A227269676874223D';
wwv_flow_imp.g_varchar2_table(433) := '3D3D6F2E616C69676E3F722E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D6F2E616C69676E3F722E416C69676E6D656E74547970652E43454E5445523A722E416C69676E6D656E74547970652E4C4546542C7370616369';
wwv_flow_imp.g_varchar2_table(434) := '6E673A7B61667465723A766F69642030213D3D613F613A4D6174682E726F756E642835362E372A28766F69642030213D3D6F2E6761703F6F2E6761703A3329297D2C6368696C6472656E3A5B6E657720722E496D61676552756E287B747970653A226A70';
wwv_flow_imp.g_varchar2_table(435) := '67223D3D3D652E6578743F226A7067223A22706E67222C646174613A652E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A74292C6865696768743A4D6174682E726F756E6428332E37382A6E29';
wwv_flow_imp.g_varchar2_table(436) := '7D7D295D7D297D76617220783D28693F615B315D3A615B305D292F35362E372C793D28693F615B305D3A615B315D292F35362E373B66756E6374696F6E20542874297B766172206E2C6F3D796528652C74293B696628216F2972657475726E206E756C6C';
wwv_flow_imp.g_varchar2_table(437) := '3B7472797B6E3D66756E6374696F6E28652C742C72297B766172206E3D372E35362C6F3D6365284D6174682E726F756E6428742A6E292C4D6174682E726F756E6428722A6E29292C613D6F2E676574436F6E746578742822326422292C693D2248656C76';
wwv_flow_imp.g_varchar2_table(438) := '65746963612C20417269616C2C2073616E732D7365726966223B612E666F6E743D22626F6C64203236362E37313638707820222B693B766172206C3D456528652C612E6D6561737572655465787428652E74657874292E77696474682F6E2C742C72293B';
wwv_flow_imp.g_varchar2_table(439) := '612E666F6E743D22626F6C6420222B2E333532382A6C2A6E2B22707820222B692C612E7472616E736C617465286F2E77696474682F322C6F2E6865696768742F32292C612E726F74617465282D652E616E676C652A4D6174682E50492F313830292C612E';
wwv_flow_imp.g_varchar2_table(440) := '676C6F62616C416C7068613D652E6F7061636974792C612E66696C6C5374796C653D652E636F6C6F722C612E74657874416C69676E3D2263656E746572222C612E74657874426173656C696E653D226D6964646C65222C612E66696C6C5465787428652E';
wwv_flow_imp.g_varchar2_table(441) := '746578742C302C30293B76617220753D7365286F2E746F4461746155524C2822696D6167652F706E6722292C6F2E77696474682C6F2E686569676874293B72657475726E20752E776D6D3D742C752E686D6D3D722C757D286F2C782C79297D6361746368';
wwv_flow_imp.g_varchar2_table(442) := '2865297B72657475726E206E756C6C7D72657475726E206E657720722E486561646572287B6368696C6472656E3A5B6E657720722E506172616772617068287B6368696C6472656E3A5B6E657720722E496D61676552756E287B747970653A22706E6722';
wwv_flow_imp.g_varchar2_table(443) := '2C646174613A6E2E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A78292C6865696768743A4D6174682E726F756E6428332E37382A79297D2C666C6F6174696E673A7B686F72697A6F6E74616C';
wwv_flow_imp.g_varchar2_table(444) := '506F736974696F6E3A7B72656C61746976653A722E486F72697A6F6E74616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A722E486F72697A6F6E74616C506F736974696F6E416C69676E2E43454E5445527D2C766572';
wwv_flow_imp.g_varchar2_table(445) := '746963616C506F736974696F6E3A7B72656C61746976653A722E566572746963616C506F736974696F6E52656C617469766546726F6D2E504147452C616C69676E3A722E566572746963616C506F736974696F6E416C69676E2E43454E5445527D2C6265';
wwv_flow_imp.g_varchar2_table(446) := '68696E64446F63756D656E743A21302C616C6C6F774F7665726C61703A21302C777261703A7B747970653A722E546578745772617070696E67547970652E4E4F4E457D7D7D295D7D295D7D297D76617220493D742E6D61702866756E6374696F6E287429';
wwv_flow_imp.g_varchar2_table(447) := '7B766172206F3D5B5D3B5828652C22646F6378222C74292E666F72456163682866756E6374696F6E20612869297B76617220753D692E747970653B69662822636F6C756D6E6173223D3D3D75297B76617220633D4B28692C22646F6378222C742C732F35';
wwv_flow_imp.g_varchar2_table(448) := '362E37293B69662821632E6C656E6774682972657475726E3B76617220643D6F2C673D732C783D4D6174682E726F756E642835362E372A28766F69642030213D3D692E636F6C4761703F4E756D62657228692E636F6C476170293A3429292C793D5B5D2C';
wwv_flow_imp.g_varchar2_table(449) := '543D5B5D3B72657475726E20632E666F72456163682866756E6374696F6E28652C74297B766172206E3D743D3D3D632E6C656E6774682D312C693D4D6174682E726F756E642835362E372A652E77293B6F3D5B5D2C733D692C652E736563732E666F7245';
wwv_flow_imp.g_varchar2_table(450) := '6163682861292C6F2E6C656E67746826266F5B6F2E6C656E6774682D315D696E7374616E63656F6620722E5061726167726170687C7C6F2E70757368286D28222229292C792E70757368286E657720722E5461626C6543656C6C287B6368696C6472656E';
wwv_flow_imp.g_varchar2_table(451) := '3A6F2C77696474683A7B73697A653A692B286E3F303A78292C747970653A722E5769647468547970652E4458417D2C6D617267696E733A7B746F703A302C626F74746F6D3A302C6C6566743A302C72696768743A6E3F303A787D2C766572746963616C41';
wwv_flow_imp.g_varchar2_table(452) := '6C69676E3A722E566572746963616C416C69676E2E544F507D29292C542E7075736828692B286E3F303A7829297D292C733D672C766F6964286F3D64292E70757368286E657720722E5461626C65287B726F77733A5B6E657720722E5461626C65526F77';
wwv_flow_imp.g_varchar2_table(453) := '287B63616E7453706C69743A21302C6368696C6472656E3A797D295D2C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C636F6C756D6E5769647468733A542C626F72646572733A662C6C61796F75743A722E54';
wwv_flow_imp.g_varchar2_table(454) := '61626C654C61796F7574547970652E46495845447D292C622829297D69662822686561646572223D3D3D75297B76617220493D5B6E657720722E5461626C65526F77287B6368696C6472656E3A5B76284528692E7469746C652C74292C7B626F6C643A21';
wwv_flow_imp.g_varchar2_table(455) := '302C73697A653A32382C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172797D292C76284528692E72696768742C74292C7B73697A653A31382C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C';
wwv_flow_imp.g_varchar2_table(456) := '616C69676E3A227269676874227D295D7D295D3B692E7375627469746C652626492E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A5B76284528692E7375627469746C652C74292C7B73697A653A31382C636F6C6F723A6E2E';
wwv_flow_imp.g_varchar2_table(457) := '68656164546578742C66696C6C3A6E2E7072696D6172792C7370616E3A327D295D7D29292C6F2E70757368286E657720722E5461626C65287B726F77733A492C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C';
wwv_flow_imp.g_varchar2_table(458) := '636F6C756D6E5769647468733A5B4D6174682E726F756E64282E372A73292C4D6174682E726F756E64282E332A73295D2C626F72646572733A667D292C622829297D656C73652069662822746578746F223D3D3D75297B766172206A3D7B72696768743A';
wwv_flow_imp.g_varchar2_table(459) := '722E416C69676E6D656E74547970652E52494748542C63656E7465723A722E416C69676E6D656E74547970652E43454E5445522C6A7573746966793A722E416C69676E6D656E74547970652E4A55535449464945447D3B4D28692C74292E666F72456163';
wwv_flow_imp.g_varchar2_table(460) := '682866756E6374696F6E2874297B6F2E70757368286E657720722E506172616772617068287B616C69676E6D656E743A6A5B692E616C69676E5D7C7C722E416C69676E6D656E74547970652E4C4546542C696E64656E743A692E696E64656E743F7B6C65';
wwv_flow_imp.g_varchar2_table(461) := '66743A4D6174682E726F756E642835362E372A692E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A766F69642030213D3D692E7061726167726170684761703F4D6174682E726F756E642835362E372A692E706172616772';
wwv_flow_imp.g_varchar2_table(462) := '617068476170293A3132302C6C696E653A4D6174682E726F756E64283234302A28692E6C696E654865696768747C7C312E313529297D2C6368696C6472656E3A5028742C7B666F6E743A692E666F6E747C7C652E706167652626652E706167652E666F6E';
wwv_flow_imp.g_varchar2_table(463) := '742C636F6C6F723A692E636F6C6F727D292E6D61702866756E6374696F6E2865297B72657475726E206E657720722E5465787452756E287B746578743A652E742C626F6C643A212821652E62262621692E626F6C64292C6974616C6963733A212821652E';
wwv_flow_imp.g_varchar2_table(464) := '69262621692E6974616C6963292C73697A653A322A28692E73697A657C7C3130292C756E6465726C696E653A652E753F7B7D3A766F696420302C737472696B653A2121652E732C636F6C6F723A652E633F6C28652E63293A766F696420302C666F6E743A';
wwv_flow_imp.g_varchar2_table(465) := '7A5B652E665D5B315D7D297D297D29297D297D656C736520696628226573706163696F223D3D3D75296F2E70757368286E657720722E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F75';
wwv_flow_imp.g_varchar2_table(466) := '6E642835362E372A28692E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D75297B696628766F696420303D3D3D692E7831297B76617220523D4D6174682E726F756E642835362E372A28692E77696474687C7C3029';
wwv_flow_imp.g_varchar2_table(467) := '292C443D523F4D6174682E6D617828302C4D6174682E726F756E642828732D52292F3229293A303B6F2E70757368286E657720722E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E';
wwv_flow_imp.g_varchar2_table(468) := '642835362E372A28766F69642030213D3D692E6761703F692E6761703A3229297D2C696E64656E743A2263656E746572223D3D3D692E616C69676E3F7B6C6566743A442C72696768743A447D3A227269676874223D3D3D692E616C69676E3F7B6C656674';
wwv_flow_imp.g_varchar2_table(469) := '3A322A447D3A7B72696768743A322A447D2C626F726465723A7B626F74746F6D3A7B7374796C653A722E426F726465725374796C652E53494E474C452C73697A653A4D6174682E6D617828322C4D6174682E726F756E642832302A28692E746869636B6E';
wwv_flow_imp.g_varchar2_table(470) := '6573737C7C2E332929292C636F6C6F723A6C28692E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29297D7D656C73652069662822696D6167656E223D3D3D75297B766172204C3D696528692C74293B6966284C297B7661722042';
wwv_flow_imp.g_varchar2_table(471) := '3D6C6528692C4C293B6F2E707573682877284C2C422E772C422E682C6929297D7D656C736520696628226772616669636F223D3D3D75297B76617220473D786528692C742C6E293B4726266F2E70757368287728472C472E776D6D2C472E686D6D2C6929';
wwv_flow_imp.g_varchar2_table(472) := '297D656C73652069662822636F6469676F223D3D3D75297B76617220573D766528692C74293B69662857297B76617220593D62652857293B6F2E70757368287728592C592E776D6D2C592E686D6D2C692C572E6C6162656C3F303A766F6964203029292C';
wwv_flow_imp.g_varchar2_table(473) := '572E6C6162656C26266F2E70757368286E657720722E506172616772617068287B616C69676E6D656E743A227269676874223D3D3D692E616C69676E3F722E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D692E616C6967';
wwv_flow_imp.g_varchar2_table(474) := '6E3F722E416C69676E6D656E74547970652E43454E5445523A722E416C69676E6D656E74547970652E4C4546542C696E64656E743A227269676874223D3D3D692E616C69676E7C7C2263656E746572223D3D3D692E616C69676E3F766F696420303A7B6C';
wwv_flow_imp.g_varchar2_table(475) := '6566743A4D6174682E6D617828302C4D6174682E726F756E642828592E776D6D2D572E746578742E6C656E6774682A572E7465787453697A652A2E333532382A2E36292F322A35362E3729297D2C73706163696E673A7B61667465723A4D6174682E726F';
wwv_flow_imp.g_varchar2_table(476) := '756E642835362E372A28766F69642030213D3D692E6761703F692E6761703A3329297D2C6368696C6472656E3A5B6E657720722E5465787452756E287B746578743A572E746578742C666F6E743A22436F7572696572204E6577222C73697A653A322A57';
wwv_flow_imp.g_varchar2_table(477) := '2E7465787453697A652C636F6C6F723A6C28572E636F6C6F72297D295D7D29297D7D656C7365206966282273616C746F223D3D3D75296F2E70757368286E657720722E506172616772617068287B6368696C6472656E3A5B6E657720722E506167654272';
wwv_flow_imp.g_varchar2_table(478) := '65616B5D7D29293B656C736520696628226669636861223D3D3D75297B76617220583D4328692C74295B305D7C7C7B7D2C4A3D692E636F6C756D6E737C7C332C513D5B5D2C65653D5B5D3B69662828692E6669656C64737C7C5B5D292E66696C74657228';
wwv_flow_imp.g_varchar2_table(479) := '66756E6374696F6E2865297B72657475726E21652E7768656E7C7C5328652E7768656E2C742C58297D292E666F72456163682866756E6374696F6E2865297B65652E707573682876284528652E6C6162656C2C742C58292C7B626F6C643A21302C73697A';
wwv_flow_imp.g_varchar2_table(480) := '653A31377D292C76285A28652C742C58292C7B73697A653A31377D29292C65652E6C656E6774683D3D3D322A4A262628512E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A65657D29292C65653D5B5D297D292C65652E6C65';
wwv_flow_imp.g_varchar2_table(481) := '6E677468297B666F72283B65652E6C656E6774683C322A4A3B2965652E70757368287628222229293B512E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A65657D29297D696628512E6C656E677468297B666F722876617220';
wwv_flow_imp.g_varchar2_table(482) := '74653D5B5D2C72653D303B72653C322A4A3B72652B2B2974652E70757368284D6174682E726F756E6428732F28322A4A2929293B6F2E70757368286E657720722E5461626C65287B726F77733A512C77696474683A7B73697A653A732C747970653A722E';
wwv_flow_imp.g_varchar2_table(483) := '5769647468547970652E4458417D2C636F6C756D6E5769647468733A74652C626F72646572733A667D292C622829297D7D656C73652069662822616C65727461223D3D3D75294328692C74292E66696C7465722866756E6374696F6E2865297B72657475';
wwv_flow_imp.g_varchar2_table(484) := '726E205328692E7768656E2C742C65297D292E736C69636528302C692E656163683F3939393A31292E666F72456163682866756E6374696F6E2865297B6F2E70757368286E657720722E5461626C65287B726F77733A5B6E657720722E5461626C65526F';
wwv_flow_imp.g_varchar2_table(485) := '77287B6368696C6472656E3A5B76284528692E746578742C742C65292C7B626F6C643A21302C73697A653A31372C66696C6C3A4128692E636F6C6F722C742C65297C7C2223453645434632227D295D7D295D2C77696474683A7B73697A653A732C747970';
wwv_flow_imp.g_varchar2_table(486) := '653A722E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B735D2C626F72646572733A667D292C622829297D293B656C736520696628227461626C61223D3D3D75297B766172206E653D4328692C74293B696628216E652E6C656E';
wwv_flow_imp.g_varchar2_table(487) := '67746826262131213D3D692E68696465456D707479262621692E656D707479546578742972657475726E3B766172206F653D6B28692C742C6E65292C61653D5B5D3B692E7469746C65262661652E70757368286E657720722E5461626C65526F77287B74';
wwv_flow_imp.g_varchar2_table(488) := '61626C654865616465723A21302C6368696C6472656E3A5B76284528692E7469746C652C74292C7B626F6C643A21302C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C7370616E3A6F652E6C656E6774682C73697A653A';
wwv_flow_imp.g_varchar2_table(489) := '702B327D295D7D29292C692E67726F757073262661652E70757368286E657720722E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A4628692C6F65292E6D61702866756E6374696F6E2865297B72657475726E2076';
wwv_flow_imp.g_varchar2_table(490) := '28652E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C616C69676E3A2263656E746572222C7370616E3A652E636F6C737D297D297D29292C61652E70757368286E657720';
wwv_flow_imp.g_varchar2_table(491) := '722E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A6F652E6D61702866756E6374696F6E2865297B72657475726E207628652E6C6162656C2C7B626F6C643A21302C636F6C6F723A6E2E68656164546578742C6669';
wwv_flow_imp.g_varchar2_table(492) := '6C6C3A6E2E7072696D6172792C616C69676E3A2263656E746572227D297D297D29292C6E652E6C656E6774687C7C61652E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A5B76284528692E656D707479546578742C74292C7B';
wwv_flow_imp.g_varchar2_table(493) := '6974616C69633A21302C7370616E3A6F652E6C656E6774687D295D7D29293B7661722075653D712869292C73653D66756E6374696F6E2865297B76617220743D7628652E746578742C7B626F6C643A21302C616C69676E3A226C656674222C66696C6C3A';
wwv_flow_imp.g_varchar2_table(494) := '6E2E746F74616C732C7370616E3A652E61747C7C6F652E6C656E6774687D292C6F3D652E63656C6C732E736C69636528652E6174292E6D61702866756E6374696F6E2865297B72657475726E207628652C7B626F6C643A21302C616C69676E3A22726967';
wwv_flow_imp.g_varchar2_table(495) := '6874222C66696C6C3A6E2E746F74616C737D297D293B72657475726E20303D3D3D652E61743F5B6E657720722E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D7D292C6E657720722E5461626C65526F77287B63';
wwv_flow_imp.g_varchar2_table(496) := '616E7453706C69743A21302C6368696C6472656E3A6F7D295D3A5B6E657720722E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A5B745D2E636F6E636174286F297D295D7D3B5628692C6E65292E666F72456163682866';
wwv_flow_imp.g_varchar2_table(497) := '756E6374696F6E2865297B696628226865616422213D3D652E6B296966282273756222213D3D652E6B297B766172206F3D652E722C613D652E692C6C3D4E28692E726F775374796C652C742C6F293B61652E70757368286E657720722E5461626C65526F';
wwv_flow_imp.g_varchar2_table(498) := '77287B63616E7453706C69743A21302C6368696C6472656E3A6F652E6D61702866756E6374696F6E2865297B76617220723D4E28652E63656C6C5374796C652C742C6F297C7C6C7C7C7B7D3B72657475726E2076284F28652C6F2C74292C7B616C69676E';
wwv_flow_imp.g_varchar2_table(499) := '3A652E616C69676E2C626F6C643A652E626F6C647C7C722E626F6C642C636F6C6F723A722E636F6C6F727C7C652E636F6C6F722C66696C6C3A722E66696C6C7C7C286125323D3D3126262131213D3D692E7A656272613F6E2E7A656272613A6E756C6C29';
wwv_flow_imp.g_varchar2_table(500) := '7D297D297D29297D656C7365207365285F286F652C75652C652E726F77732C2428692C652C742929292E666F72456163682866756E6374696F6E2865297B61652E707573682865297D293B656C73652061652E70757368286E657720722E5461626C6552';
wwv_flow_imp.g_varchar2_table(501) := '6F77287B63616E7453706C69743A21302C6368696C6472656E3A5B76282428692C652C74292C7B626F6C643A21302C66696C6C3A6E2E67726F75702C7370616E3A6F652E6C656E6774687D295D7D29297D292C5528692E746F74616C73292E6C656E6774';
wwv_flow_imp.g_varchar2_table(502) := '6826266E652E6C656E67746826267365285F286F652C5528692E746F74616C73292C6E652C4828692C742C6E652929292E666F72456163682866756E6374696F6E2865297B61652E707573682865297D293B7661722063653D6F652E6D61702866756E63';
wwv_flow_imp.g_varchar2_table(503) := '74696F6E2865297B72657475726E20652E77696474683F652E77696474682F32303A317D292C66653D63652E7265647563652866756E6374696F6E28652C74297B72657475726E20652B747D2C30292C64653D63652E6D61702866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(504) := '297B72657475726E204D6174682E666C6F6F7228732A652F6665297D293B6F2E70757368286E657720722E5461626C65287B726F77733A61652C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C636F6C756D6E';
wwv_flow_imp.g_varchar2_table(505) := '5769647468733A64652C626F72646572733A687D292C622829297D7D293B76617220633D652E666F6F7465722C643D542874293B72657475726E7B686561646572733A643F7B64656661756C743A647D3A766F696420302C70726F706572746965733A7B';
wwv_flow_imp.g_varchar2_table(506) := '706167653A7B73697A653A7B77696474683A615B305D2C6865696768743A615B315D2C6F7269656E746174696F6E3A693F722E506167654F7269656E746174696F6E2E4C414E4453434150453A722E506167654F7269656E746174696F6E2E504F525452';
wwv_flow_imp.g_varchar2_table(507) := '4149547D2C6D617267696E3A7B746F703A752C626F74746F6D3A752C6C6566743A752C72696768743A757D7D7D2C666F6F746572733A633F7B64656661756C743A6E657720722E466F6F746572287B6368696C6472656E3A416528632C742C6E297D297D';
wwv_flow_imp.g_varchar2_table(508) := '3A766F696420302C6368696C6472656E3A6F2E6C656E6774683F6F3A5B6D282222295D7D7D292C6A3D6E657720722E446F63756D656E74287B63726561746F723A226E6F76615265706F7274222C7469746C653A4528652E7469746C657C7C22222C745B';
wwv_flow_imp.g_varchar2_table(509) := '305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A497D293B72657475726E20722E5061636B65722E746F426C6F623F722E5061636B65722E746F426C6F62286A292E7468656E2866756E6374696F6E2865297B72657475726E20652E6172';
wwv_flow_imp.g_varchar2_table(510) := '7261794275666665723F652E617272617942756666657228293A657D293A722E5061636B65722E746F427566666572286A297D766172207A653D7B7D3B66756E6374696F6E2050652865297B76617220743D652E73706C697428227C22292C723D745B30';
wwv_flow_imp.g_varchar2_table(511) := '5D2E7472696D28292C6E3D745B315D3F745B315D2E7472696D28293A6E756C6C3B72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E223D3D3D722972657475726E20653B666F7228766172206F3D722E73706C697428222E2229';
wwv_flow_imp.g_varchar2_table(512) := '2C613D742626742E73636F70654C6973743F742E73636F70654C6973742E736C69636528292E7265766572736528293A5B655D2C693D303B693C612E6C656E6774683B692B2B297B666F7228766172206C3D615B695D2C753D21302C733D303B733C6F2E';
wwv_flow_imp.g_varchar2_table(513) := '6C656E6774683B732B2B297B69662841727261792E69734172726179286C292626733E302626286C3D6C5B305D292C6E756C6C3D3D6C7C7C226F626A65637422213D747970656F66206C7C7C21286F5B735D696E206C29297B753D21313B627265616B7D';
wwv_flow_imp.g_varchar2_table(514) := '6C3D6C5B6F5B735D5D7D696628752972657475726E206E26262141727261792E69734172726179286C293F70286C2C6E293A6C7D7D7D7D66756E6374696F6E204D6528652C74297B76617220723D6E65772077696E646F772E50697A5A69702865292C6E';
wwv_flow_imp.g_varchar2_table(515) := '3D6E657728302C77696E646F772E646F637874656D706C617465722928722C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A50652C6E756C6C4765747465723A66756E6374696F6E28297B7265747572';
wwv_flow_imp.g_varchar2_table(516) := '6E22227D7D293B72657475726E206E2E72656E6465722866756E6374696F6E2865297B76617220742C723D7B7D3B666F72287420696E20652E706172616D737C7C7B7D29725B745D3D652E706172616D735B745D3B666F72287420696E20652E646F637C';
wwv_flow_imp.g_varchar2_table(517) := '7C7B7D29725B745D3D652E646F635B745D3B666F72287420696E20652E5329725B745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D7328292C722E54';
wwv_flow_imp.g_varchar2_table(518) := '4F4441593D6328292C727D287429292C50726F6D6973652E7265736F6C7665286E2E6765745A697028292E67656E6572617465287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445227D29297D66756E';
wwv_flow_imp.g_varchar2_table(519) := '6374696F6E206B652865297B76617220743D7B7D2C723D7B7D3B72657475726E204F626A6563742E6B65797328657C7C7B7D292E666F72456163682866756E6374696F6E286E297B766172206F3D655B6E5D2C613D6F2E636F6C737C7C5B5D3B725B6E5D';
wwv_flow_imp.g_varchar2_table(520) := '3D7B7D2C612E666F72456163682866756E6374696F6E2865297B725B6E5D5B652E6E616D655D3D652E747970657D292C745B6E5D3D286F2E726F77737C7C5B5D292E6D61702866756E6374696F6E2865297B76617220743D7B7D3B72657475726E20612E';
wwv_flow_imp.g_varchar2_table(521) := '666F72456163682866756E6374696F6E28722C6E297B745B722E6E616D655D3D655B6E5D7D292C747D297D292C7B533A742C543A727D7D66756E6374696F6E20466528652C74297B76617220723D652E532E444F43533B69662821722972657475726E5B';
wwv_flow_imp.g_varchar2_table(522) := '7B533A652E532C543A652E542C646F633A7B7D2C706172616D733A747D5D3B766172206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F72456163682866756E6374696F6E2874297B69662822444F435322213D3D7426264F';
wwv_flow_imp.g_varchar2_table(523) := '626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B745D3D7B7D3B652E535B745D2E666F72456163682866756E6374696F6E2865297B76617220';
wwv_flow_imp.g_varchar2_table(524) := '743D537472696E6728652E444F435F4B4559293B28725B745D3D725B745D7C7C5B5D292E707573682865297D297D7D292C722E6D61702866756E6374696F6E2872297B766172206F3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E';
wwv_flow_imp.g_varchar2_table(525) := '666F72456163682866756E6374696F6E2874297B6F5B745D3D6E5B745D3F6E5B745D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B745D7D292C6F2E444F43533D5B725D2C7B533A6F2C543A652E542C646F633A722C706172616D';
wwv_flow_imp.g_varchar2_table(526) := '733A747D7D297D66756E6374696F6E2049652865297B76617220743D646F63756D656E742E676574456C656D656E744279496428226E722D6176616E636522293B653F28747C7C2828743D646F63756D656E742E637265617465456C656D656E74282264';
wwv_flow_imp.g_varchar2_table(527) := '69762229292E69643D226E722D6176616E6365222C742E7365744174747269627574652822726F6C65222C2273746174757322292C742E7374796C652E637373546578743D22706F736974696F6E3A66697865643B72696768743A323470783B626F7474';
wwv_flow_imp.g_varchar2_table(528) := '6F6D3A323470783B7A2D696E6465783A313030303B70616464696E673A3134707820313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A653A313370';
wwv_flow_imp.g_varchar2_table(529) := '783B626F782D736861646F773A30203870782032347078207267626128302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287429292C742E696E6E657248544D4C3D27';
wwv_flow_imp.g_varchar2_table(530) := '3C7370616E20636C6173733D2266612066612D7370696E6E65722066612D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B263C3E22';
wwv_flow_imp.g_varchar2_table(531) := '5D2F672C66756E6374696F6E2865297B72657475726E7B2226223A2226616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B655D7D29293A742626742E72656D6F766528297D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(532) := '4F6528652C74297B69662865262621652E636C6F736564297472797B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F616465724D73672977696E646F772E636F744C6F616465724D736728652C74293B656C73657B';
wwv_flow_imp.g_varchar2_table(533) := '76617220723D652E646F63756D656E742E676574456C656D656E744279496428226D736722293B72262628722E74657874436F6E74656E743D74297D7D63617463682865297B7D7D66756E6374696F6E206A6528652C74297B7472797B77696E646F772E';
wwv_flow_imp.g_varchar2_table(534) := '617065782626617065782E6576656E742626617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C74297D63617463682865297B7D7D66756E6374696F6E2052652865297B77696E646F772E6170';
wwv_flow_imp.g_varchar2_table(535) := '65782626617065782E6D6573736167653F617065782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D66756E6374696F6E2044652865297B77696E646F772E617065782626617065782E6D6573736167652626617065';
wwv_flow_imp.g_varchar2_table(536) := '782E6D6573736167652E73686F7750616765537563636573732865297D7661722055653D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F666669';
wwv_flow_imp.g_varchar2_table(537) := '6365646F63756D656E742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F726470726F63657373696E676D6C';
wwv_flow_imp.g_varchar2_table(538) := '2E646F63756D656E74227D2C4C653D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E20426528652C742C72297B766172206E3D45';
wwv_flow_imp.g_varchar2_table(539) := '28652E66696C654E616D657C7C227265706F727465222C74292C6F3D4C655B725D3B72657475726E2068286E3D6E2E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C222229292B222E222B6F7D66756E6374696F6E20476528';
wwv_flow_imp.g_varchar2_table(540) := '652C742C722C6E297B72657475726E22706466223D3D3D653F546528742C722C6E2E686F6F6B73293A22786C7378223D3D3D653F536528742C722C722E6C656E677468293A22646F6378223D3D3D653F4E6528742C72293A22646F63782D74656D706C61';
wwv_flow_imp.g_varchar2_table(541) := '7465223D3D3D653F286F3D6E2E74656D706C61746555726C2C6F3F286F3D6E65286F292C7A655B6F5D3F50726F6D6973652E7265736F6C7665287A655B6F5D293A6665746368286F2C7B63726564656E7469616C733A2273616D652D6F726967696E227D';
wwv_flow_imp.g_varchar2_table(542) := '292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20646573636172676172206C6120706C616E74696C6C612028222B652E7374617475732B222922293B72657475';
wwv_flow_imp.g_varchar2_table(543) := '726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B72657475726E207A655B6F5D3D652C657D29293A50726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C612055524C206465';
wwv_flow_imp.g_varchar2_table(544) := '206C6120706C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C6120576F726422292E272929292E7468656E2866756E6374696F6E2865297B72657475726E204D6528652C725B305D297D293A50726F6D6973652E72656A';
wwv_flow_imp.g_varchar2_table(545) := '656374286E6577204572726F722822466F726D61746F206E6F20736F706F727461646F3A20222B6529293B766172206F7D66756E6374696F6E20576528652C74297B76617220722C6E2C6F3D596528652E6C61796F7574292C613D7B7D3B666F72287220';
wwv_flow_imp.g_varchar2_table(546) := '696E206529615B725D3D655B725D3B72657475726E20612E6C61796F75743D6F2C286E3D6F2C50726F6D6973652E616C6C2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F7245616368';
wwv_flow_imp.g_varchar2_table(547) := '2866756E6374696F6E2865297B65262622696D6167656E223D3D3D652E747970652626652E75726C262621652E6669656C642626742E7075736828652E75726C292C65262622636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B';
wwv_flow_imp.g_varchar2_table(548) := '5D292E666F72456163682872297D297D72657475726E207228652E73656374696F6E73292C652E62617463682626652E62617463682E73756D6D6172792626287228652E62617463682E73756D6D6172792E73656374696F6E73292C652E62617463682E';
wwv_flow_imp.g_varchar2_table(549) := '73756D6D6172792E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F75742E73656374696F6E7329292C747D286E292E6D61702866756E6374696F6E2865297B76617220743D6E652865293B72657475726E2074655B745D3F6E';
wwv_flow_imp.g_varchar2_table(550) := '756C6C3A666574636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F206361726761';
wwv_flow_imp.g_varchar2_table(551) := '72206C6120696D6167656E20222B742B222028222B652E7374617475732B222922293B72657475726E20652E617272617942756666657228297D292E7468656E2866756E6374696F6E2865297B76617220723D6F652865293B74655B745D3D7B6275663A';
wwv_flow_imp.g_varchar2_table(552) := '652C773A722E772C683A722E682C6578743A722E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D722E6578743F226A706567223A22706E6722292B223B6261736536342C222B61652865297D7D297D2929292E7468656E';
wwv_flow_imp.g_varchar2_table(553) := '2866756E6374696F6E28297B72657475726E2066756E6374696F6E28652C74297B76617220723D596528652E6C61796F7574292C6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D';
wwv_flow_imp.g_varchar2_table(554) := '61747C7C22706466225D2C6F3D6B652874292C613D4665286F2C652E706172616D737C7C7B7D292C693D652E6F75747075747C7C2266696C65223B69662821612E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572';
wwv_flow_imp.g_varchar2_table(555) := '726F7228652E656D7074794D6573736167657C7C722E656D7074794D6573736167657C7C224E6F20686179206461746F7320706172612067656E6572617220656C207265706F7274652E2229293B696628722E62617463682626722E62617463682E6D61';
wwv_flow_imp.g_varchar2_table(556) := '78446F63732626612E6C656E6774683E722E62617463682E6D6178446F63732972657475726E2050726F6D6973652E72656A656374286E6577204572726F722822456C206C6F74652073757065726120656C206DC3A178696D6F20646520222B722E6261';
wwv_flow_imp.g_varchar2_table(557) := '7463682E6D6178446F63732B2220646F63756D656E746F732E2229293B6966282266696C65223D3D3D692626313D3D3D612E6C656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D692626313D3D3D6E2E6C656E677468262622';
wwv_flow_imp.g_varchar2_table(558) := '646F63782D74656D706C61746522213D3D6E5B305D297B766172206C3D6E5B305D3B72657475726E204765286C2C722C612C65292E7468656E2866756E6374696F6E2874297B766172206E3D426528722C615B305D2C6C293B696628612E6C656E677468';
wwv_flow_imp.g_varchar2_table(559) := '3E31297B76617220693D722E6261746368262628722E62617463682E6D657267654E616D657C7C722E62617463682E7A69704E616D65297C7C722E66696C654E616D657C7C227265706F727465223B6E3D4265287B66696C654E616D653A537472696E67';
wwv_flow_imp.g_varchar2_table(560) := '2869292E7265706C616365282F5C2E7A6970242F692C2222297D2C7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C6C297D72657475726E7B6B696E643A6C2C646174613A742C6E616D653A6E2C63';
wwv_flow_imp.g_varchar2_table(561) := '6F756E743A612E6C656E6774687D7D297D76617220752C733D6E65772077696E646F772E4A535A69702C633D302C663D302C643D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C703D7B7D3B666F72287520696E20652E7061';
wwv_flow_imp.g_varchar2_table(562) := '72616D737C7C7B7D29705B755D3D652E706172616D735B755D3B702E464F524D41544F3D6E2E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74656D';
wwv_flow_imp.g_varchar2_table(563) := '706C617465223A22776F7264227D5B6E5B305D5D3B76617220673D7B533A6F2E532C543A6F2E542C646F633A7B7D2C706172616D733A707D2C6D3D7B7D3B66756E6374696F6E207628652C74297B666F722876617220723D652C6E3D323B6D5B722E746F';
wwv_flow_imp.g_varchar2_table(564) := '4C6F7765724361736528295D3B29723D652E7265706C616365282F285C2E5B5E2E5D2B29242F2C225F222B6E2B22243122292C6E2B2B3B6D5B722E746F4C6F7765724361736528295D3D21302C732E66696C6528722C74292C632B2B7D76617220623D50';
wwv_flow_imp.g_varchar2_table(565) := '726F6D6973652E7265736F6C766528292C773D722E62617463682626722E62617463682E73756D6D6172793B772626227A6970223D3D3D69262628623D6E2E66696C7465722866756E6374696F6E2865297B72657475726E22646F63782D74656D706C61';
wwv_flow_imp.g_varchar2_table(566) := '746522213D3D657D292E7265647563652866756E6374696F6E28742C6E297B72657475726E20742E7468656E2866756E6374696F6E28297B76617220743D772E6C61796F75747C7C7B706167653A722E706167652C666F6F7465723A772E666F6F746572';
wwv_flow_imp.g_varchar2_table(567) := '7C7C722E666F6F7465722C73656374696F6E733A772E73656374696F6E732C786C73783A772E786C73782C66696C654E616D653A772E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E66696C654E616D653D772E66696C';
wwv_flow_imp.g_varchar2_table(568) := '654E616D657C7C2230305F726573756D656E22292C4765286E2C742C5B675D2C65292E7468656E2866756E6374696F6E2865297B7628426528742C672C6E292C65297D297D297D2C6229293B72657475726E20622E7468656E2866756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(569) := '7B72657475726E206E65772050726F6D6973652866756E6374696F6E28742C6F297B66756E6374696F6E206928297B666F7228766172206C3D4D6174682E6D696E28662B642C612E6C656E677468292C753D50726F6D6973652E7265736F6C766528293B';
wwv_flow_imp.g_varchar2_table(570) := '663C6C3B662B2B292866756E6374696F6E2874297B6E2E666F72456163682866756E6374696F6E286E297B753D752E7468656E2866756E6374696F6E28297B72657475726E204765286E2C722C5B745D2C65292E7468656E2866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(571) := '7B7628426528722C742C6E292C65297D297D297D297D2928615B665D293B752E7468656E2866756E6374696F6E28297B652E6F6E50726F67726573732626652E6F6E50726F677265737328662C612E6C656E677468292C663C612E6C656E6774683F7365';
wwv_flow_imp.g_varchar2_table(572) := '7454696D656F757428692C30293A28652E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C63292C732E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D7072657373696F6E3A';
wwv_flow_imp.g_varchar2_table(573) := '224445464C415445222C636F6D7072657373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E2866756E6374696F6E2865297B766172206E3D4528722E62617463682626722E62617463682E7A69704E616D657C7C227265706F727465';
wwv_flow_imp.g_varchar2_table(574) := '732E7A6970222C67293B74287B6B696E643A227A6970222C646174613A652C6E616D653A68282F5C2E7A6970242F692E74657374286E293F6E3A6E2B222E7A697022292C636F756E743A612E6C656E6774682C66696C65733A637D297D2C6F29297D2C6F';
wwv_flow_imp.g_varchar2_table(575) := '297D73657454696D656F757428692C30297D297D297D28612C74297D297D66756E6374696F6E205F652865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D292E666F72456163682866756E6374696F6E2865297B65262628';
wwv_flow_imp.g_varchar2_table(576) := '22636F6469676F223D3D3D652E747970652626227172223D3D3D537472696E6728652E6B696E647C7C22717222292E746F4C6F7765724361736528292626742E696E6465784F6628227172636F646522293C302626742E7075736828227172636F646522';
wwv_flow_imp.g_varchar2_table(577) := '292C226772616669636F223D3D3D652E747970652626742E696E6465784F66282263686172746A7322293C302626742E70757368282263686172746A7322292C22636F6C756D6E6173223D3D3D652E74797065262628652E636F6C737C7C5B5D292E666F';
wwv_flow_imp.g_varchar2_table(578) := '7245616368287229297D297D7228652E73656374696F6E73293B766172206E3D652E62617463682626652E62617463682E73756D6D6172793B72657475726E206E26262872286E2E73656374696F6E73292C6E2E6C61796F7574262672286E2E6C61796F';
wwv_flow_imp.g_varchar2_table(579) := '75742E73656374696F6E7329292C747D66756E6374696F6E20486528652C74297B69662822737472696E67223D3D747970656F66206526262240223D3D3D652E6368617241742830292626742626766F69642030213D3D745B652E737562737472283129';
wwv_flow_imp.g_varchar2_table(580) := '5D2972657475726E20486528745B652E7375627374722831295D2C74293B69662841727261792E697341727261792865292972657475726E20652E7265647563652866756E6374696F6E28652C72297B766172206E3D22737472696E67223D3D74797065';
wwv_flow_imp.g_varchar2_table(581) := '6F66207226262240223D3D3D722E636861724174283029262674262641727261792E6973417272617928745B722E7375627374722831295D292C6F3D486528722C74293B72657475726E206E3F652E636F6E636174286F293A652E636F6E636174285B6F';
wwv_flow_imp.g_varchar2_table(582) := '5D297D2C5B5D293B696628652626226F626A656374223D3D747970656F662065297B76617220723D7B7D3B72657475726E204F626A6563742E6B6579732865292E666F72456163682866756E6374696F6E286E297B725B6E5D3D2264656673223D3D3D6E';
wwv_flow_imp.g_varchar2_table(583) := '3F655B6E5D3A486528655B6E5D2C74297D292C727D72657475726E20657D66756E6374696F6E2059652865297B76617220743B696628652626226F626A656374223D3D747970656F66206529743D653B656C73657B76617220723D537472696E6728657C';
wwv_flow_imp.g_varchar2_table(584) := '7C2222292E7472696D28293B696628227B223D3D3D722E63686172417428302929743D4A534F4E2E70617273652872293B656C7365206966282128743D722E73706C697428222E22292E7265647563652866756E6374696F6E28652C74297B7265747572';
wwv_flow_imp.g_varchar2_table(585) := '6E20653F655B745D3A766F696420307D2C77696E646F772929297468726F77206E6577204572726F7228224E6F20736520656E636F6E7472C3B320656C2064697365C3B16F3A20222B72297D72657475726E20486528742C742E64656673297D66756E63';
wwv_flow_imp.g_varchar2_table(586) := '74696F6E2071652865297B69662865297B69662841727261792E697341727261792865297C7C22737472696E6722213D747970656F6620657C7C2F5B232E5C5B5D2F2E746573742865292972657475726E20653B76617220743D652E73706C697428222C';
wwv_flow_imp.g_varchar2_table(587) := '22292E6D61702866756E6374696F6E2865297B72657475726E20652E7472696D28297D292E66696C74657228426F6F6C65616E293B72657475726E20742E6C656E6774683F743A766F696420307D7D66756E6374696F6E2056652865297B766172206E2C';
wwv_flow_imp.g_varchar2_table(588) := '6F3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C613D313D3D3D6F2E6C656E677468262622706466223D3D3D6F5B305D2626227A697022213D3D652E6F';
wwv_flow_imp.g_varchar2_table(589) := '7574707574262622646F776E6C6F616422213D3D652E706466416374696F6E2C693D6126262131213D3D652E6C6F616465723F66756E6374696F6E2865297B76617220743D77696E646F772E6F70656E2822222C225F626C616E6B22293B696628217429';
wwv_flow_imp.g_varchar2_table(590) := '72657475726E206E756C6C3B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F61646572297472797B77696E646F772E636F744C6F616465722874293B76617220723D742E646F63756D656E742E676574456C656D65';
wwv_flow_imp.g_varchar2_table(591) := '6E747342795461674E616D652822683122295B305D3B72262628722E74657874436F6E74656E743D2247656E6572616E646F207265706F72746522297D63617463682865297B7D656C736520742E646F63756D656E742E777269746528273C21646F6374';
wwv_flow_imp.g_varchar2_table(592) := '7970652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C7469746C653E47656E6572616E646F207265706F727465E280A63C2F7469746C653E3C7374796C653E626F64797B6D617267696E3A303B68';
wwv_flow_imp.g_varchar2_table(593) := '65696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D73657269663B';
wwv_flow_imp.g_varchar2_table(594) := '6261636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B77696474683A353670783B6865696768743A353670783B626F726465723A35707820736F6C696420236436';
wwv_flow_imp.g_varchar2_table(595) := '653065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A72203173206C696E65617220696E66696E6974653B6D617267696E3A30206175746F20313870787D406B';
wwv_flow_imp.g_varchar2_table(596) := '65796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B6D617267696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A233562366237627D3C2F';
wwv_flow_imp.g_varchar2_table(597) := '7374796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C68313E47656E6572616E646F207265706F7274653C2F68313E3C702069643D226D7367223E3C2F703E3C2F64';
wwv_flow_imp.g_varchar2_table(598) := '69763E3C2F626F64793E3C2F68746D6C3E27292C742E646F63756D656E742E636C6F736528293B72657475726E204F6528742C65292C747D28652E6D6573736167657C7C22436F6E73756C74616E646F206461746F73E280A622293A6E756C6C2C6C3D77';
wwv_flow_imp.g_varchar2_table(599) := '696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E73686F775370696E6E657228293A6E756C6C2C753D227265736F6C766572223D3D3D652E6F726967696E262621652E646174613B6966282175297472797B6E3D59652865';
wwv_flow_imp.g_varchar2_table(600) := '2E6C61796F7574297D63617463682865297B72657475726E206C26266C2E72656D6F766528292C692626692E636C6F736528292C5265282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765292C50726F6D6973652E72656A65';
wwv_flow_imp.g_varchar2_table(601) := '63742865297D76617220733D7B6C61796F75743A6E2C666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D706C61746555726C2C';
wwv_flow_imp.g_varchar2_table(602) := '686F6F6B733A652E686F6F6B737C7C7B7D7D3B6A6528227374617274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C7265706F72743A753F652E7265706F72743A766F696420307D293B76617220633D72286675';
wwv_flow_imp.g_varchar2_table(603) := '6E6374696F6E28652C72297B766172206E3D5B5D3B72657475726E20652E666F72456163682866756E6374696F6E2865297B28745B655D7C7C5B5D292E666F72456163682866756E6374696F6E2865297B6E2E696E6465784F662865293C3026266E2E70';
wwv_flow_imp.g_varchar2_table(604) := '7573682865297D297D292C7226266E2E7075736828226A737A697022292C6E7D286F2C226D6572676522213D3D652E6F7574707574292E636F6E63617428753F5B5D3A5F65286E2929292C663D652E646174613F50726F6D6973652E7265736F6C766528';
wwv_flow_imp.g_varchar2_table(605) := '7B646174613A652E646174617D293A6E65772050726F6D6973652866756E6374696F6E28742C72297B766172206E3D7B7830313A4A534F4E2E737472696E6769667928732E706172616D73292C7830323A227A6970223D3D3D652E6F75747075743F2259';
wwv_flow_imp.g_varchar2_table(606) := '223A224E222C706167654974656D733A716528652E6974656D73297D3B69662875297B696628766F696420303D3D3D652E7265706F72747C7C6E756C6C3D3D3D652E7265706F72747C7C22223D3D3D652E7265706F72742972657475726E20766F696420';
wwv_flow_imp.g_varchar2_table(607) := '72286E6577204572726F722822496E646971756520656C207265706F72746520612067656E657261722028646174612D7265706F7274292E2229293B6E2E7830333D537472696E6728652E7265706F7274297D617065782E7365727665722E706C756769';
wwv_flow_imp.g_varchar2_table(608) := '6E28652E616A61784964656E7469666965722C6E2C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B652626652E6F6B3F742865293A72286E6577204572726F7228652626652E6D73677C7C224572726F722061';
wwv_flow_imp.g_varchar2_table(609) := '6C206F6274656E6572206C6F73206461746F732E2229297D2C66756E6374696F6E28652C742C6E297B72286E6577204572726F7228224572726F7220646520636F6D756E6963616369C3B36E3A20222B286E7C7C742929297D297D293B72657475726E20';
wwv_flow_imp.g_varchar2_table(610) := '50726F6D6973652E616C6C285B662C635D292E7468656E2866756E6374696F6E2865297B76617220743D655B305D2C6F3D50726F6D6973652E7265736F6C766528293B69662875297B7472797B6E3D596528742E6C61796F7574297D6361746368286529';
wwv_flow_imp.g_varchar2_table(611) := '7B7468726F77206E6577204572726F72282244697365C3B16F20696E76C3A16C69646F3A20222B652E6D657373616765297D732E6C61796F75743D6E2C742E706172616D73262628732E706172616D733D742E706172616D73292C742E74656D706C6174';
wwv_flow_imp.g_varchar2_table(612) := '6555726C262628732E74656D706C61746555726C3D742E74656D706C61746555726C292C6F3D72285F65286E29297D72657475726E206F2E7468656E2866756E6374696F6E28297B72657475726E20742E646174617D297D292E7468656E2866756E6374';
wwv_flow_imp.g_varchar2_table(613) := '696F6E2874297B6C2626286C2E72656D6F766528292C6C3D6E756C6C293B76617220723D652E7472616E73666F726D2626652E7472616E73666F726D2874297C7C743B72657475726E204F6528692C2241726D616E646F20656C20646F63756D656E746F';
wwv_flow_imp.g_varchar2_table(614) := 'E280A622292C732E6F6E50726F67726573733D66756E6374696F6E28652C74297B2D313D3D3D653F49652822436F6D7072696D69656E646F20222B742B22206172636869766F73E280A622293A284965282247656E6572616E646F20222B652B22206465';
wwv_flow_imp.g_varchar2_table(615) := '20222B742B22E280A622292C6A65282270726F6772657373222C7B646F6E653A652C746F74616C3A747D29297D2C576528732C72297D292E7468656E2866756E6374696F6E2874297B76617220723D652E736176657C7C732E6C61796F75742626732E6C';
wwv_flow_imp.g_varchar2_table(616) := '61796F75742E736176653B69662821727C7C21722E70726F636573732972657475726E20743B6966282177696E646F772E617065787C7C21617065782E736572766572297468726F77206E6577204572726F7228224775617264617220656E20656C2073';
wwv_flow_imp.g_varchar2_table(617) := '65727669646F7220726571756965726520415045582E22293B72657475726E20496528224775617264616E646F20656E20656C207365727669646F72E280A622292C66756E6374696F6E28652C742C72297B766172206E3D227A6970223D3D3D652E6B69';
wwv_flow_imp.g_varchar2_table(618) := '6E643F226170706C69636174696F6E2F7A6970223A55655B652E6B696E645D7C7C55652E646F63782C6F3D652E6461746120696E7374616E63656F6620426C6F623F652E646174613A6E657720426C6F62285B652E646174615D2C7B747970653A6E7D29';
wwv_flow_imp.g_varchar2_table(619) := '3B72657475726E206E65772050726F6D6973652866756E6374696F6E28612C69297B766172206C3D6E65772046696C655265616465723B6C2E6F6E6572726F723D66756E6374696F6E28297B69286E6577204572726F7228224E6F207365207075646F20';
wwv_flow_imp.g_varchar2_table(620) := '6C65657220656C206172636869766F2067656E657261646F2E2229297D2C6C2E6F6E6C6F61643D66756E6374696F6E28297B766172206F2C753D537472696E67286C2E726573756C74292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222';
wwv_flow_imp.g_varchar2_table(621) := '292C733D5B5D3B666F72286F3D303B6F3C752E6C656E6774683B6F2B3D33653429732E7075736828752E737562737472286F2C33653429293B617065782E7365727665722E70726F6365737328742E70726F636573732C7B7830313A652E6E616D652C78';
wwv_flow_imp.g_varchar2_table(622) := '30323A6E2C7830333A766F696420303D3D3D722E7265706F72743F22223A537472696E6728722E7265706F7274292C7830343A4A534F4E2E737472696E6769667928722E706172616D737C7C7B7D292C7830353A652E6B696E642C6630313A737D2C7B64';
wwv_flow_imp.g_varchar2_table(623) := '617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2865297B65262621313D3D3D652E6F6B3F69286E6577204572726F7228652E6D73677C7C22456C207365727669646F72206E6F206775617264C3B320656C20646F63756D656E';
wwv_flow_imp.g_varchar2_table(624) := '746F2E2229293A6128657C7C7B7D297D2C66756E6374696F6E28652C742C72297B69286E6577204572726F7228224E6F207365207075646F206775617264617220656E20656C207365727669646F723A20222B28727C7C742929297D297D2C6C2E726561';
wwv_flow_imp.g_varchar2_table(625) := '6441734461746155524C286F297D297D28742C722C7B7265706F72743A652E7265706F72742C706172616D733A732E706172616D737D292E7468656E2866756E6374696F6E2865297B72657475726E20742E73617665643D652C742E6F6E6C793D226F6E';
wwv_flow_imp.g_varchar2_table(626) := '6C79223D3D3D722E6D6F64652C6A6528227361766564222C7B6E616D653A742E6E616D652C6B696E643A742E6B696E642C726573706F6E73653A657D292C747D297D292E7468656E2866756E6374696F6E2865297B696628496528292C652E6F6E6C7929';
wwv_flow_imp.g_varchar2_table(627) := '692626692E636C6F736528292C446528652E73617665642626652E73617665642E6D73677C7C22446F63756D656E746F20677561726461646F3A20222B652E6E616D65293B656C73652069662822706466223D3D3D652E6B696E64262661297B76617220';
wwv_flow_imp.g_varchar2_table(628) := '743D55524C2E6372656174654F626A65637455524C286E657720426C6F62285B652E646174615D2C7B747970653A55652E7064667D29293B69262621692E636C6F7365643F692E6C6F636174696F6E2E687265663D743A77696E646F772E6F70656E2874';
wwv_flow_imp.g_varchar2_table(629) := '2C225F626C616E6B22297D656C736520692626692E636C6F736528292C723D652E646174612C6E3D652E6E616D652C6F3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A55655B652E6B696E645D7C7C55652E646F63';
wwv_flow_imp.g_varchar2_table(630) := '782C6C3D7220696E7374616E63656F6620426C6F623F723A6E657720426C6F62285B725D2C7B747970653A6F7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D292C28753D646F63756D656E742E637265617465456C656D656E74';
wwv_flow_imp.g_varchar2_table(631) := '2822612229292E687265663D55524C2E6372656174654F626A65637455524C286C292C752E646F776E6C6F61643D6E2C646F63756D656E742E626F64792E617070656E644368696C642875292C752E636C69636B28292C73657454696D656F7574286675';
wwv_flow_imp.g_varchar2_table(632) := '6E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C28752E68726566292C752E72656D6F766528297D2C346533292C227A6970223D3D3D652E6B696E642626446528225A49502067656E657261646F3A20222B652E66696C65732B2220';
wwv_flow_imp.g_varchar2_table(633) := '6172636869766F7320646520222B652E636F756E742B2220646F63756D656E746F732E22293B76617220722C6E2C6F2C6C2C753B72657475726E206A652822656E64222C7B6E616D653A652E6E616D652C636F756E743A652E636F756E742C66696C6573';
wwv_flow_imp.g_varchar2_table(634) := '3A652E66696C65737D292C657D292E63617463682866756E6374696F6E2865297B7468726F77206C26266C2E72656D6F766528292C496528292C69262621692E636C6F7365642626692E636C6F736528292C77696E646F772E636F6E736F6C652626636F';
wwv_flow_imp.g_varchar2_table(635) := '6E736F6C652E6572726F722865292C6A6528226572726F72222C7B6D6573736167653A652E6D6573736167657D292C526528652E6D6573736167657C7C224E6F207365207075646F2067656E6572617220656C207265706F7274652E22292C657D297D76';
wwv_flow_imp.g_varchar2_table(636) := '61722024653D21312C5A653D6E756C6C3B72657475726E22756E646566696E656422213D747970656F6620646F63756D656E742626646F63756D656E742E6164644576656E744C697374656E65722626646F63756D656E742E6164644576656E744C6973';
wwv_flow_imp.g_varchar2_table(637) := '74656E65722822636C69636B222C66756E6374696F6E2865297B5A653D652E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C627574746F6E2C5B646174612D6F75747075745D2C5B64';
wwv_flow_imp.g_varchar2_table(638) := '6174612D666F726D61745D22297C7C652E7461726765747D2C2130292C7B76657273696F6E3A22312E31312E30222C6C6962733A652C72756E3A56652C64613A66756E6374696F6E2865297B76617220743D746869732626746869732E616374696F6E3F';
wwv_flow_imp.g_varchar2_table(639) := '746869733A7B7D2C723D742E616374696F6E7C7C7B7D2C6E3D742E74726967676572696E67456C656D656E747C7C5A652C6F3D742E62726F777365724576656E743B6966286F26266F2E70726576656E7444656661756C7426266F2E70726576656E7444';
wwv_flow_imp.g_varchar2_table(640) := '656661756C7428292C212465297B76617220613D652626226F626A656374223D3D747970656F6620653F653A7B7D2C693D2266756E6374696F6E223D3D747970656F6620653F653A612E696E69742C6C3D7B7D2C753D6E26266E2E646174617365747C7C';
wwv_flow_imp.g_varchar2_table(641) := '7B7D2C733D612E7265706F72742C633D612E6F75747075747C7C722E61747472696275746530337C7C2266696C65222C663D612E666F726D61747C7C722E61747472696275746530327C7C22706466223B4F626A6563742E6B6579732875292E666F7245';
wwv_flow_imp.g_varchar2_table(642) := '6163682866756E6374696F6E2865297B226F757470757422213D3D653F22666F726D617422213D3D653F227265706F727422213D3D653F6C5B652E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D';
wwv_flow_imp.g_varchar2_table(643) := '755B655D3A733D755B655D3A663D755B655D3A633D755B655D7D293B76617220643D7B6C61796F75743A612E6C61796F75747C7C722E61747472696275746530312C666F726D61743A662C6F75747075743A632C6974656D733A612E6974656D737C7C72';
wwv_flow_imp.g_varchar2_table(644) := '2E61747472696275746530347C7C22222C706466416374696F6E3A612E706466416374696F6E7C7C722E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A612E74656D706C61746555726C7C7C722E617474726962757465';
wwv_flow_imp.g_varchar2_table(645) := '30362C6D6573736167653A612E6D6573736167657C7C722E61747472696275746530372C706172616D733A6C2C616A61784964656E7469666965723A612E616A61784964656E7469666965727C7C722E616A61784964656E7469666965722C6F72696769';
wwv_flow_imp.g_varchar2_table(646) := '6E3A612E6F726967696E7C7C2261747472696275746573222C7265706F72743A732C736176653A612E736176657D3B6966282266756E6374696F6E223D3D747970656F662069297B76617220683D692864293B69662821313D3D3D682972657475726E3B';
wwv_flow_imp.g_varchar2_table(647) := '643D687C7C647D24653D21302C56652864292E7468656E2866756E6374696F6E28297B24653D21317D2C66756E6374696F6E28297B24653D21317D297D7D2C6275696C643A57652C656E737572653A722C6C61796F75744C6962733A5F652C5F696E7465';
wwv_flow_imp.g_varchar2_table(648) := '726E616C733A7B494D473A74652C696D6744696D733A6F652C74706C3A452C636F6E643A532C666D743A702C6E6F726D616C697A653A6B652C636F6E74657874733A46652C636F64653132383A6D652C706E67313A70652C6C61796F75744C6962733A5F';
wwv_flow_imp.g_varchar2_table(649) := '657D7D7D28293B';
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
