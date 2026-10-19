
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
'procedure nr_write_json(p_sources in varchar2, p_params in varchar2, p_summary in boolean) is',
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
'begin',
'    if p_params is not null then',
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
'                if not nr_is_item(l_bind) then',
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
'                     p_auto_bind_items => true);',
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
'begin',
'    apex_json.initialize_clob_output;',
'    begin',
'        nr_write_json(p_sources => p_dynamic_action.attributes.get_varchar2(''sources''),',
'                      p_params  => apex_application.g_x01,',
'                      p_summary => apex_application.g_x02 = ''Y'');',
'        l_out := apex_json.get_clob_output;',
'        apex_json.free_output;',
'    exception',
'        when others then',
'            apex_json.free_output;',
'            apex_json.initialize_clob_output;',
'            apex_json.open_object;',
'            apex_json.write(''ok'', false);',
'            apex_json.write(''msg'', regexp_replace(sqlerrm, ''^ORA-\d+: '', ''''));',
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
,p_version_identifier=>'1.6.1'
,p_about_url=>'https://github.com/danielramirezasyn/novareport'
,p_files_version=>11
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
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A206E6F76615265706F727420312E362E31202D205265706F7274657320504446202F20457863656C202F20576F72642070617261204F7261636C6520415045580A202A2068747470733A2F2F6769746875622E636F6D2F64616E69656C72';
wwv_flow_imp.g_varchar2_table(2) := '616D6972657A6173796E2F6E6F76617265706F7274202D204C6963656E636961204D49540A202A204E6F7661436F6465202D20706C7567696E20646520416363695C75303066336E2044696E5C75303065316D69636120434F4D2E4E4F5641434F44452E';
wwv_flow_imp.g_varchar2_table(3) := '4E4F56415245504F52540A202A0A202A204D6F746F72206465206C61796F75743A20756E206D69736D6F20646973655C75303066316F20284A534F4E29207920756E6173206D69736D6173206675656E7465732053514C2067656E6572616E0A202A2050';
wwv_flow_imp.g_varchar2_table(4) := '444620286A73504446202B206175746F7461626C65292C20457863656C20636F6E20657374696C6F732028457863656C4A53292C20576F72642028646F637829206F20576F72642064657364650A202A20706C616E74696C6C612028646F637874656D70';
wwv_flow_imp.g_varchar2_table(5) := '6C61746572292E204D6F646F206C6F74653A20756E206172636869766F20706F7220646F63756D656E746F20656E20756E205A495020284A535A6970292E0A202A2F0A77696E646F772E6E6F76615265706F72743D66756E6374696F6E28297B22757365';
wwv_flow_imp.g_varchar2_table(6) := '20737472696374223B76617220653D7B6A737064663A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737064662F342E322E312F6A737064662E756D642E6D696E2E6A73222C6F6B3A';
wwv_flow_imp.g_varchar2_table(7) := '66756E6374696F6E28297B72657475726E21282177696E646F772E6A737064667C7C2177696E646F772E6A737064662E6A73504446297D7D2C6175746F7461626C653A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F';
wwv_flow_imp.g_varchar2_table(8) := '6D2F616A61782F6C6962732F6A737064662D6175746F7461626C652F332E382E342F6A737064662E706C7567696E2E6175746F7461626C652E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21212877696E646F772E6A73706466';
wwv_flow_imp.g_varchar2_table(9) := '262677696E646F772E6A737064662E6A73504446262677696E646F772E6A737064662E6A735044462E4150492E6175746F5461626C65297D7D2C657863656C6A733A7B75726C3A2268747470733A2F2F63646E6A732E636C6F7564666C6172652E636F6D';
wwv_flow_imp.g_varchar2_table(10) := '2F616A61782F6C6962732F657863656C6A732F342E342E302F657863656C6A732E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E457863656C4A537D7D2C6A737A69703A7B75726C3A2268747470733A2F2F';
wwv_flow_imp.g_varchar2_table(11) := '63646E6A732E636C6F7564666C6172652E636F6D2F616A61782F6C6962732F6A737A69702F332E31302E312F6A737A69702E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E4A535A69707D7D2C646F63783A';
wwv_flow_imp.g_varchar2_table(12) := '7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637840392E352E312F646973742F696E6465782E696966652E6A73222C6F6B3A66756E6374696F6E28297B72657475726E21282177696E646F772E646F6378';
wwv_flow_imp.g_varchar2_table(13) := '7C7C2177696E646F772E646F63782E446F63756D656E74297D7D2C70697A7A69703A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F70697A7A697040332E312E382F646973742F70697A7A69702E6D696E2E6A73';
wwv_flow_imp.g_varchar2_table(14) := '222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E50697A5A69707D7D2C646F637874656D706C617465723A7B75726C3A2268747470733A2F2F63646E2E6A7364656C6976722E6E65742F6E706D2F646F637874656D706C6174';
wwv_flow_imp.g_varchar2_table(15) := '657240332E36302E302F6275696C642F646F637874656D706C617465722E6D696E2E6A73222C6F6B3A66756E6374696F6E28297B72657475726E212177696E646F772E646F637874656D706C617465727D7D7D2C743D7B7064663A5B226A73706466222C';
wwv_flow_imp.g_varchar2_table(16) := '226175746F7461626C65225D2C786C73783A5B22657863656C6A73225D2C646F63783A5B22646F6378225D2C22646F63782D74656D706C617465223A5B2270697A7A6970222C22646F637874656D706C61746572225D2C7A69703A5B226A737A6970225D';
wwv_flow_imp.g_varchar2_table(17) := '7D3B66756E6374696F6E20722874297B72657475726E20742E726564756365282866756E6374696F6E28742C72297B72657475726E20742E7468656E282866756E6374696F6E28297B72657475726E20655B725D2E6F6B28293F6E756C6C3A28743D4F28';
wwv_flow_imp.g_varchar2_table(18) := '655B725D2E75726C292C6E65772050726F6D697365282866756E6374696F6E28652C72297B766172206E3D77696E646F772E646566696E653B77696E646F772E646566696E653D766F696420303B766172206F3D646F63756D656E742E63726561746545';
wwv_flow_imp.g_varchar2_table(19) := '6C656D656E74282273637269707422293B6F2E7372633D742C6F2E6F6E6C6F61643D66756E6374696F6E28297B77696E646F772E646566696E653D6E2C6528297D2C6F2E6F6E6572726F723D66756E6374696F6E28297B77696E646F772E646566696E65';
wwv_flow_imp.g_varchar2_table(20) := '3D6E2C72286E6577204572726F7228224E6F207365207075646F20636172676172206C61206C69627265725C7530306564613A20222B7429297D2C646F63756D656E742E686561642E617070656E644368696C64286F297D2929293B76617220747D2929';
wwv_flow_imp.g_varchar2_table(21) := '7D292C50726F6D6973652E7265736F6C76652829297D766172206E3D7B7072696D6172793A2223314634453739222C68656164546578743A2223464646464646222C7A656272613A2223463546374641222C746F74616C733A2223453645434632222C74';
wwv_flow_imp.g_varchar2_table(22) := '6578743A2223303030303030222C6D757465643A2223373837383738222C666F6E7453697A653A377D3B66756E6374696F6E206F2865297B72657475726E226E756D626572223D3D747970656F66206526262169734E614E2865297D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(23) := '20612865297B72657475726E20333D3D3D28653D537472696E6728657C7C222330303030303022292E7265706C616365282223222C222229292E6C656E677468262628653D652E7265706C616365282F282E292F672C22243124312229292C5B70617273';
wwv_flow_imp.g_varchar2_table(24) := '65496E7428652E73756273747228302C32292C3136292C7061727365496E7428652E73756273747228322C32292C3136292C7061727365496E7428652E73756273747228342C32292C3136295D7D66756E6374696F6E20692865297B72657475726E2246';
wwv_flow_imp.g_varchar2_table(25) := '46222B537472696E6728657C7C222330303030303022292E7265706C616365282223222C2222292E746F55707065724361736528297D66756E6374696F6E206C2865297B72657475726E20537472696E6728657C7C222330303030303022292E7265706C';
wwv_flow_imp.g_varchar2_table(26) := '616365282223222C2222292E746F55707065724361736528297D66756E6374696F6E20752865297B72657475726E28653C31303F2230223A2222292B657D66756E6374696F6E207328297B76617220653D6E657720446174653B72657475726E20752865';
wwv_flow_imp.g_varchar2_table(27) := '2E676574446174652829292B222F222B7528652E6765744D6F6E746828292B31292B222F222B652E67657446756C6C5965617228292B2220222B7528652E676574486F7572732829292B223A222B7528652E6765744D696E757465732829297D66756E63';
wwv_flow_imp.g_varchar2_table(28) := '74696F6E206328297B72657475726E207328292E73756273747228302C3130297D66756E6374696F6E20662865297B76617220743D2F5E285C647B327D295C2F285C647B327D295C2F285C647B347D29242F2E6578656328537472696E6728657C7C2222';
wwv_flow_imp.g_varchar2_table(29) := '29293B72657475726E20743F6E6577204461746528446174652E555443282B745B335D2C2B745B325D2D312C2B745B315D29293A6E756C6C7D66756E6374696F6E20702865297B72657475726E20537472696E6728657C7C226172636869766F22292E72';
wwv_flow_imp.g_varchar2_table(30) := '65706C616365282F5B5C5C5C2F3A2A3F223C3E7C5D2B2F672C225F22292E7472696D28297D66756E6374696F6E206428652C74297B6966286E756C6C3D3D657C7C22223D3D3D652972657475726E22223B69662821742972657475726E20537472696E67';
wwv_flow_imp.g_varchar2_table(31) := '2865293B76617220723D742E73706C697428223A22292C6E3D725B305D3B696628226D6F6E6579223D3D3D6E7C7C226E756D223D3D3D6E297B766172206F3D766F69642030213D3D725B315D3F2B725B315D3A322C613D4E756D6265722865293B726574';
wwv_flow_imp.g_varchar2_table(32) := '75726E2069734E614E2861293F537472696E672865293A612E746F4C6F63616C65537472696E672822656E2D5553222C7B6D696E696D756D4672616374696F6E4469676974733A6F2C6D6178696D756D4672616374696F6E4469676974733A6F7D297D72';
wwv_flow_imp.g_varchar2_table(33) := '657475726E22696E74223D3D3D6E3F69734E614E284E756D626572286529293F537472696E672865293A4D6174682E726F756E64284E756D626572286529292E746F4C6F63616C65537472696E672822656E2D555322293A22706374223D3D3D6E3F6428';
wwv_flow_imp.g_varchar2_table(34) := '652C226E756D3A222B28725B315D7C7C3229292B2225223A227570706572223D3D3D6E3F537472696E672865292E746F55707065724361736528293A226C6F776572223D3D3D6E3F537472696E672865292E746F4C6F7765724361736528293A22796E22';
wwv_flow_imp.g_varchar2_table(35) := '3D3D3D6E3F2259223D3D3D657C7C2253223D3D3D653F22535C7530306564223A224E223D3D3D653F224E6F223A537472696E672865293A537472696E672865297D66756E6374696F6E206828652C742C72297B766172206E3D537472696E672874292E74';
wwv_flow_imp.g_varchar2_table(36) := '6F55707065724361736528292C6F3D6E2E696E6465784F6628222E22293B6966286F3E30297B76617220613D6E2E73756273747228302C6F292C693D6E2E737562737472286F2B31293B69662822444F43223D3D3D612972657475726E20652E646F633F';
wwv_flow_imp.g_varchar2_table(37) := '652E646F635B695D3A766F696420303B69662822504152414D223D3D3D612972657475726E20652E706172616D733F652E706172616D735B695D3A766F696420303B696628224954454D223D3D3D612972657475726E2066756E6374696F6E2865297B74';
wwv_flow_imp.g_varchar2_table(38) := '72797B72657475726E2077696E646F772E617065782626617065782E6974656D3F617065782E6974656D2865292E67657456616C756528293A22227D63617463682865297B72657475726E22227D7D2869293B766172206C3D28652E535B615D7C7C5B5D';
wwv_flow_imp.g_varchar2_table(39) := '295B305D3B72657475726E206C3F6C5B695D3A766F696420307D72657475726E224E4F57223D3D3D6E3F7328293A22544F444159223D3D3D6E3F6328293A2250414745223D3D3D6E7C7C225041474553223D3D3D6E3F227B222B6E2B227D223A7226264F';
wwv_flow_imp.g_varchar2_table(40) := '626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28722C6E293F725B6E5D3A652E646F6326264F626A6563742E70726F746F747970652E6861734F776E50726F70657274792E63616C6C28652E646F632C6E293F65';
wwv_flow_imp.g_varchar2_table(41) := '2E646F635B6E5D3A652E706172616D733F652E706172616D735B6E5D3A766F696420307D66756E6374696F6E206D28652C742C72297B72657475726E206E756C6C3D3D653F22223A537472696E672865292E7265706C616365282F5C7B285B412D5A612D';
wwv_flow_imp.g_varchar2_table(42) := '7A302D395F24232E5D2B29283F3A5C7C285B412D5A612D7A302D393A5D2B29293F5C7D2F672C2866756E6374696F6E28652C6E2C6F297B76617220613D6828742C6E2C72293B72657475726E206E756C6C3D3D613F22223A6428612C6F297D29297D6675';
wwv_flow_imp.g_varchar2_table(43) := '6E6374696F6E206728652C742C72297B766172206E3D2F5E5C732A28213F295C732A285B412D5A612D7A302D395F24232E5D2B295C732A283D3D7C213D7C3E3D7C3C3D7C3E7C3C293F5C732A282E2A29242F2E657865632865293B696628216E29726574';
wwv_flow_imp.g_varchar2_table(44) := '75726E21313B766172206F3D6828742C6E5B325D2C72293B696628216E5B335D297B76617220613D21286E756C6C3D3D6F7C7C22223D3D3D6F7C7C303D3D3D6F7C7C224E223D3D3D6F293B72657475726E206E5B315D3F21613A617D76617220692C6C3D';
wwv_flow_imp.g_varchar2_table(45) := '28693D28693D6E5B345D292E7472696D28292C2F5E272E2A27242F2E746573742869297C7C2F5E222E2A22242F2E746573742869293F692E736C69636528312C2D31293A226E756C6C223D3D3D693F6E756C6C3A22223D3D3D697C7C69734E614E284E75';
wwv_flow_imp.g_varchar2_table(46) := '6D626572286929293F766F696420303A4E756D626572286929293B766F696420303D3D3D6C2626286C3D6828742C6E5B345D2E7472696D28292C7229293B76617220753D6E756C6C3D3D6F7C7C22223D3D3D6F3F6E756C6C3D3D3D6C7C7C22223D3D3D6C';
wwv_flow_imp.g_varchar2_table(47) := '3A537472696E67286F293D3D3D537472696E67286C293B737769746368286E5B335D297B63617365223D3D223A72657475726E20753B6361736522213D223A72657475726E21753B63617365223E223A72657475726E204E756D626572286F293E4E756D';
wwv_flow_imp.g_varchar2_table(48) := '626572286C293B63617365223C223A72657475726E204E756D626572286F293C4E756D626572286C293B63617365223E3D223A72657475726E204E756D626572286F293E3D4E756D626572286C293B63617365223C3D223A72657475726E204E756D6265';
wwv_flow_imp.g_varchar2_table(49) := '72286F293C3D4E756D626572286C297D72657475726E21317D66756E6374696F6E207628652C742C72297B72657475726E206E756C6C3D3D657C7C22223D3D3D657C7C282266756E6374696F6E223D3D747970656F6620653F21216528722C74293A5374';
wwv_flow_imp.g_varchar2_table(50) := '72696E672865292E73706C697428227C7C22292E736F6D65282866756E6374696F6E2865297B72657475726E20652E73706C69742822262622292E6576657279282866756E6374696F6E2865297B72657475726E206728652C742C72297D29297D292929';
wwv_flow_imp.g_varchar2_table(51) := '7D66756E6374696F6E206228652C74297B76617220723D742E535B537472696E6728652E736F757263657C7C2222292E746F55707065724361736528295D7C7C5B5D3B72657475726E20652E66696C7465723F722E66696C746572282866756E6374696F';
wwv_flow_imp.g_varchar2_table(52) := '6E2872297B72657475726E207628652E66696C7465722C742C72297D29293A727D66756E6374696F6E207728652C742C72297B69662821652972657475726E206E756C6C3B69662822737472696E67223D3D747970656F6620652972657475726E20653B';
wwv_flow_imp.g_varchar2_table(53) := '766172206E3D6828742C652E62792C72293B72657475726E20652E76616C7565732626652E76616C7565735B6E5D7C7C652E64656661756C747C7C6E756C6C7D66756E6374696F6E207828652C742C72297B766172206E3D6E756C6C3B72657475726E28';
wwv_flow_imp.g_varchar2_table(54) := '657C7C5B5D292E736F6D65282866756E6374696F6E2865297B72657475726E21217628652E7768656E2C742C72292626286E3D652C2130297D29292C6E7D76617220793D7B68656C7665746963613A5B2268656C766574696361222C22417269616C225D';
wwv_flow_imp.g_varchar2_table(55) := '2C617269616C3A5B2268656C766574696361222C22417269616C225D2C74696D65733A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C73657269663A5B2274696D6573222C2254696D6573204E657720526F6D616E225D2C636F75';
wwv_flow_imp.g_varchar2_table(56) := '726965723A5B22636F7572696572222C22436F7572696572204E6577225D2C6D6F6E6F3A5B22636F7572696572222C22436F7572696572204E6577225D7D3B66756E6374696F6E205428652C74297B76617220722C6E3D5B5D2C6F3D7B623A21312C693A';
wwv_flow_imp.g_varchar2_table(57) := '21312C753A21312C733A21317D2C613D5B28743D747C7C7B7D292E666F6E747C7C2268656C766574696361225D2C693D5B742E636F6C6F727C7C6E756C6C5D2C6C3D22222C753D303B66756E6374696F6E207328297B76617220653B6C2626286E2E7075';
wwv_flow_imp.g_varchar2_table(58) := '7368287B743A6C2C623A6F2E622C693A6F2E692C753A6F2E752C733A6F2E732C663A28653D615B612E6C656E6774682D315D2C653D537472696E6728657C7C2268656C76657469636122292E746F4C6F7765724361736528292C795B655D3F653A226865';
wwv_flow_imp.g_varchar2_table(59) := '6C76657469636122292C633A695B692E6C656E6774682D315D7D292C6C3D2222297D666F7228653D537472696E67286E756C6C3D3D653F22223A65293B753C652E6C656E6774683B297B76617220633D652E7375627374722875293B225C5C223D3D3D63';
wwv_flow_imp.g_varchar2_table(60) := '2E6368617241742830292626632E6C656E6774683E313F286C2B3D632E6368617241742831292C752B3D32293A28723D2F5E5C5B663D285B412D5A612D7A5D2B295C5D2F2E65786563286329293F287328292C612E7075736828725B315D292C752B3D72';
wwv_flow_imp.g_varchar2_table(61) := '5B305D2E6C656E677468293A225B2F665D22213D3D632E73756273747228302C34293F28723D2F5E5C5B633D28235B302D39412D46612D665D7B332C367D295C5D2F2E65786563286329293F287328292C692E7075736828725B315D292C752B3D725B30';
wwv_flow_imp.g_varchar2_table(62) := '5D2E6C656E677468293A225B2F635D22213D3D632E73756273747228302C34293F222A2A2A22213D3D632E73756273747228302C33293F222A2A22213D3D632E73756273747228302C32293F227E7E22213D3D632E73756273747228302C32293F222B2B';
wwv_flow_imp.g_varchar2_table(63) := '22213D3D632E73756273747228302C32293F222A22213D3D632E6368617241742830293F286C2B3D632E6368617241742830292C752B2B293A287328292C6F2E693D216F2E692C752B3D31293A287328292C6F2E753D216F2E752C752B3D32293A287328';
wwv_flow_imp.g_varchar2_table(64) := '292C6F2E733D216F2E732C752B3D32293A287328292C6F2E623D216F2E622C752B3D32293A287328292C6F2E623D216F2E622C6F2E693D216F2E692C752B3D33293A287328292C692E6C656E6774683E312626692E706F7028292C752B3D34293A287328';
wwv_flow_imp.g_varchar2_table(65) := '292C612E6C656E6774683E312626612E706F7028292C752B3D34297D72657475726E207328292C6E7D66756E6374696F6E205328652C74297B76617220723D652E736F757263653F6228652C74295B305D3A6E756C6C3B72657475726E2841727261792E';
wwv_flow_imp.g_varchar2_table(66) := '6973417272617928652E74657874293F652E746578743A537472696E6728766F696420303D3D3D652E746578743F22223A652E74657874292E73706C697428225C6E2229292E6D6170282866756E6374696F6E2865297B72657475726E206D28652C742C';
wwv_flow_imp.g_varchar2_table(67) := '72297D29297D66756E6374696F6E204528652C742C72297B766172206E3D537472696E6728652E736F757263657C7C2222292E746F55707065724361736528292C613D742E545B6E5D7C7C7B7D2C693D652E636F6C756D6E733B72657475726E20692626';
wwv_flow_imp.g_varchar2_table(68) := '692E6C656E6774687C7C28693D4F626A6563742E6B6579732861292E66696C746572282866756E6374696F6E2865297B72657475726E22444F435F4B455922213D3D657D29292E6D6170282866756E6374696F6E2865297B72657475726E7B636F6C3A65';
wwv_flow_imp.g_varchar2_table(69) := '7D7D2929292C692E6D6170282866756E6374696F6E2865297B76617220742C6E2C693D28653D22737472696E67223D3D747970656F6620653F7B636F6C3A657D3A65292E636F6C3F537472696E6728652E636F6C292E746F55707065724361736528293A';
wwv_flow_imp.g_varchar2_table(70) := '6E756C6C2C6C3D693F615B695D3A6E756C6C2C753D652E666D743B72657475726E20757C7C224E554D42455222213D3D6C7C7C652E76616C75657C7C28753D722E736F6D65282866756E6374696F6E2865297B72657475726E206F28655B695D2926264D';
wwv_flow_imp.g_varchar2_table(71) := '6174682E726F756E6428655B695D29213D3D655B695D7D29293F226D6F6E6579223A6E756C6C292C7B636F6C3A692C76616C75653A652E76616C75652C6C6162656C3A766F69642030213D3D652E6C6162656C3F652E6C6162656C3A28743D697C7C2222';
wwv_flow_imp.g_varchar2_table(72) := '2C6E3D537472696E672874292E746F4C6F7765724361736528292E7265706C616365282F5F2F672C222022292C6E2E6368617241742830292E746F55707065724361736528292B6E2E736C696365283129292C666D743A752C6D61703A652E6D61702C62';
wwv_flow_imp.g_varchar2_table(73) := '6F6C643A2121652E626F6C642C77696474683A652E77696474682C616C69676E3A652E616C69676E7C7C28224E554D424552223D3D3D6C7C7C226D6F6E6579223D3D3D757C7C22696E74223D3D3D757C7C226E756D223D3D3D753F227269676874223A22';
wwv_flow_imp.g_varchar2_table(74) := '44415445223D3D3D6C7C7C2264617465223D3D3D753F2263656E746572223A226C65667422292C63656C6C5374796C653A652E63656C6C5374796C652C636F6C6F723A652E636F6C6F722C69734E756D3A224E554D424552223D3D3D6C262621652E6D61';
wwv_flow_imp.g_varchar2_table(75) := '70262621652E76616C75657C7C226D6F6E6579223D3D3D757C7C22696E74223D3D3D757C7C2F5E6E756D2F2E7465737428757C7C2222297D7D29297D66756E6374696F6E207A28652C74297B76617220723D5B5D2C6E3D303B72657475726E28652E6772';
wwv_flow_imp.g_varchar2_table(76) := '6F7570737C7C5B5D292E666F7245616368282866756E6374696F6E2865297B766172206F3D4D6174682E6D617828312C4D6174682E6D696E28652E636F6C737C7C312C742E6C656E6774682D6E29293B6E3C742E6C656E677468262628722E7075736828';
wwv_flow_imp.g_varchar2_table(77) := '7B6C6162656C3A652E6C6162656C7C7C22222C636F6C733A6F2C66726F6D3A6E2C6761703A21652E6C6162656C7D292C6E2B3D6F297D29292C6E3C742E6C656E6774682626722E70757368287B6C6162656C3A22222C636F6C733A742E6C656E6774682D';
wwv_flow_imp.g_varchar2_table(78) := '6E2C66726F6D3A6E2C6761703A21307D292C727D66756E6374696F6E204128652C742C72297B696628766F69642030213D3D652E76616C75652972657475726E206D28652E76616C75652C722C74293B766172206E3D745B652E636F6C5D3B7265747572';
wwv_flow_imp.g_varchar2_table(79) := '6E20652E6D617026266E756C6C213D6E2626766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A6E7D66756E6374696F6E204328652C742C72297B766172206E3D4128652C742C72293B72657475726E20652E6D61702626766F69642030';
wwv_flow_imp.g_varchar2_table(80) := '213D3D652E6D61705B745B652E636F6C5D5D3F537472696E67286E293A64286E2C652E666D74297D66756E6374696F6E205028652C74297B72657475726E20652E726564756365282866756E6374696F6E28652C72297B72657475726E20652B284E756D';
wwv_flow_imp.g_varchar2_table(81) := '62657228725B745D297C7C30297D292C30297D66756E6374696F6E206A28652C742C72297B696628652E6D6170297B766172206E3D6828742C537472696E6728652E76616C7565292E7265706C616365282F5B7B7D5D2F672C2222292E73706C69742822';
wwv_flow_imp.g_varchar2_table(82) := '7C22295B305D2C72293B72657475726E20766F69642030213D3D652E6D61705B6E5D3F652E6D61705B6E5D3A537472696E67286E7C7C2222297D766172206F3D652E76616C75653B72657475726E20652E666D7426262F5E5C7B5B5E7D7C5D2B5C7D242F';
wwv_flow_imp.g_varchar2_table(83) := '2E74657374286F7C7C2222293F64286828742C6F2E736C69636528312C2D31292C72292C652E666D74293A6D286F2C742C72297D66756E6374696F6E204E28652C74297B72657475726E28652E73656374696F6E737C7C5B5D292E66696C746572282866';
wwv_flow_imp.g_varchar2_table(84) := '756E6374696F6E2865297B72657475726E21652E666F726D6174737C7C652E666F726D6174732E696E6465784F662874293E3D307D29297D66756E6374696F6E20462865297B76617220742C723D7B7D3B666F72287420696E206E29725B745D3D6E5B74';
wwv_flow_imp.g_varchar2_table(85) := '5D3B766172206F3D652E706167652626652E706167652E7468656D657C7C7B7D3B666F72287420696E206F29725B745D3D6F5B745D3B72657475726E20727D76617220523D7B7D2C4D3D7B7D3B66756E6374696F6E204F2865297B76617220743D77696E';
wwv_flow_imp.g_varchar2_table(86) := '646F772E617065782626617065782E656E767C7C7B7D3B72657475726E20537472696E6728657C7C2222292E7265706C6163652822234150505F46494C455323222C742E4150505F46494C45537C7C2222292E7265706C6163652822234150505F494D41';
wwv_flow_imp.g_varchar2_table(87) := '47455323222C742E4150505F46494C45537C7C2222292E7265706C616365282223574F524B53504143455F46494C455323222C742E574F524B53504143455F46494C45537C7C2222292E7265706C616365282223494D4147455F50524546495823222C74';
wwv_flow_imp.g_varchar2_table(88) := '2E415045585F46494C45537C7C2222297D66756E6374696F6E206B2865297B76617220743D6E65772055696E743841727261792865293B6966283133373D3D3D745B305D262638303D3D3D745B315D2972657475726E7B773A28745B31365D3C3C32347C';
wwv_flow_imp.g_varchar2_table(89) := '745B31375D3C3C31367C745B31385D3C3C387C745B31395D293E3E3E302C683A28745B32305D3C3C32347C745B32315D3C3C31367C745B32325D3C3C387C745B32335D293E3E3E302C6578743A22706E67227D3B6966283235353D3D3D745B305D262632';
wwv_flow_imp.g_varchar2_table(90) := '31363D3D3D745B315D29666F722876617220723D323B723C742E6C656E6774683B296966283235353D3D3D745B725D297B766172206E3D745B722B315D2C6F3D745B722B325D3C3C387C745B722B335D3B6966286E3E3D31393226266E3C3D3230372626';
wwv_flow_imp.g_varchar2_table(91) := '313936213D3D6E2626323030213D3D6E2626323034213D3D6E2972657475726E7B683A745B722B355D3C3C387C745B722B365D2C773A745B722B375D3C3C387C745B722B385D2C6578743A226A7067227D3B722B3D322B6F7D656C736520722B2B3B7468';
wwv_flow_imp.g_varchar2_table(92) := '726F77206E6577204572726F722822466F726D61746F20646520696D6167656E206E6F20736F706F727461646F202875736520504E47206F204A5047292E22297D66756E6374696F6E20442865297B666F722876617220743D6E65772055696E74384172';
wwv_flow_imp.g_varchar2_table(93) := '7261792865292C723D22222C6E3D303B6E3C742E6C656E6774683B6E2B3D333237363829722B3D537472696E672E66726F6D43686172436F64652E6170706C79286E756C6C2C742E7375626172726179286E2C6E2B333237363829293B72657475726E20';
wwv_flow_imp.g_varchar2_table(94) := '62746F612872297D66756E6374696F6E204C28652C74297B696628652E6669656C64297B76617220723D2828652E736F757263653F6228652C74295B305D3A742E646F63297C7C7B7D295B537472696E6728652E6669656C64292E746F55707065724361';
wwv_flow_imp.g_varchar2_table(95) := '736528295D3B7472797B72657475726E20723F66756E6374696F6E2865297B76617220743D537472696E672865292E7265706C616365282F5E646174613A5B5E2C5D2A2C2F2C2222292E7265706C616365282F5C732B2F672C2222293B69662821742972';
wwv_flow_imp.g_varchar2_table(96) := '657475726E206E756C6C3B76617220723D226236343A222B742E6C656E6774682B223A222B742E73756273747228302C3634292B742E737562737472282D3634293B696628525B725D2972657475726E20525B725D3B666F7228766172206E3D61746F62';
wwv_flow_imp.g_varchar2_table(97) := '2874292C6F3D6E65772055696E74384172726179286E2E6C656E677468292C613D303B613C6E2E6C656E6774683B612B2B296F5B615D3D6E2E63686172436F646541742861293B76617220693D6B286F2E627566666572293B72657475726E20525B725D';
wwv_flow_imp.g_varchar2_table(98) := '3D7B6275663A6F2E6275666665722C773A692E772C683A692E682C6578743A692E6578742C646174613A22646174613A696D6167652F222B28226A7067223D3D3D692E6578743F226A706567223A22706E6722292B223B6261736536342C222B747D2C52';
wwv_flow_imp.g_varchar2_table(99) := '5B725D7D2872293A6E756C6C7D63617463682874297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28226E6F76615265706F72743A20696D6167656E20696E765C75303065316C69646120656E20222B652E66';
wwv_flow_imp.g_varchar2_table(100) := '69656C642C74292C6E756C6C7D7D72657475726E20525B4F28652E75726C295D7C7C6E756C6C7D66756E6374696F6E205528652C74297B76617220723D652E77696474687C7C34302C6E3D652E6865696768747C7C722A742E682F742E773B7265747572';
wwv_flow_imp.g_varchar2_table(101) := '6E21652E77696474682626652E686569676874262628723D6E2A742E772F742E68292C7B773A722C683A6E7D7D66756E6374696F6E204928652C742C72297B766172206E3D652E706167657C7C7B7D2C6F3D462865292C693D6F2E666F6E7453697A652C';
wwv_flow_imp.g_varchar2_table(102) := '6C3D6E65772077696E646F772E6A737064662E6A73504446287B6F7269656E746174696F6E3A6E2E6F7269656E746174696F6E7C7C22706F727472616974222C756E69743A226D6D222C666F726D61743A6E2E73697A657C7C226C6574746572222C636F';
wwv_flow_imp.g_varchar2_table(103) := '6D70726573733A21307D292C753D6C2E696E7465726E616C2E7061676553697A652E676574576964746828292C733D6C2E696E7465726E616C2E7061676553697A652E67657448656967687428292C633D6E2E6D617267696E7C7C382C663D61286F2E70';
wwv_flow_imp.g_varchar2_table(104) := '72696D617279292C703D61286F2E6865616454657874292C683D61286F2E7A65627261292C673D61286F2E746F74616C73292C413D632C523D21303B66756E6374696F6E204F2865297B413D286C2E6C6173744175746F5461626C653F6C2E6C61737441';
wwv_flow_imp.g_varchar2_table(105) := '75746F5461626C652E66696E616C593A41292B28657C7C32297D742E666F7245616368282866756E6374696F6E2874297B527C7C6C2E6164645061676528292C523D21312C413D632C6C2E6C6173744175746F5461626C653D6E756C6C2C4E28652C2270';
wwv_flow_imp.g_varchar2_table(106) := '646622292E666F7245616368282866756E6374696F6E286E297B766172206F3D6E2E747970653B69662822686561646572223D3D3D6F297B766172204E3D6E2E7375627469746C653F32303A31363B72657475726E206C2E73657446696C6C436F6C6F72';
wwv_flow_imp.g_varchar2_table(107) := '28665B305D2C665B315D2C665B325D292C6C2E7265637428302C302C752C4E2C224622292C6C2E73657454657874436F6C6F7228705B305D2C705B315D2C705B325D292C6C2E736574466F6E74282268656C766574696361222C22626F6C6422292C6C2E';
wwv_flow_imp.g_varchar2_table(108) := '736574466F6E7453697A65286E2E73697A657C7C3134292C6C2E74657874286D286E2E7469746C652C74292C632C31302E352C7B6D617857696474683A2E372A757D292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C';
wwv_flow_imp.g_varchar2_table(109) := '6C2E736574466F6E7453697A652839292C6E2E726967687426266C2E74657874286D286E2E72696768742C74292C752D632C31302E352C7B616C69676E3A227269676874227D292C6E2E7375627469746C6526266C2E74657874286D286E2E7375627469';
wwv_flow_imp.g_varchar2_table(110) := '746C652C74292C632C31362E35292C6C2E73657454657874436F6C6F7228302C302C30292C413D4E2B342C766F6964286C2E6C6173744175746F5461626C653D6E756C6C297D69662822746578746F223D3D3D6F297B76617220463D766F69642030213D';
wwv_flow_imp.g_varchar2_table(111) := '3D6E2E792C523D412C6B3D6C2E6C6173744175746F5461626C652C443D6E2E73697A657C7C31302C493D2E333532382A442A286E2E6C696E654865696768747C7C312E3335292C473D28766F69642030213D3D6E2E783F6E2E783A63292B286E2E696E64';
wwv_flow_imp.g_varchar2_table(112) := '656E747C7C30292C5F3D6E2E77696474687C7C752D632D472C423D6E2E616C69676E7C7C226C656674222C573D61286E2E636F6C6F727C7C222330303030303022292C593D66756E6374696F6E2865297B72657475726E28652E627C7C6E2E626F6C6429';
wwv_flow_imp.g_varchar2_table(113) := '262628652E697C7C6E2E6974616C6963293F22626F6C646974616C6963223A652E627C7C6E2E626F6C643F22626F6C64223A652E697C7C6E2E6974616C69633F226974616C6963223A226E6F726D616C227D2C483D6E2E666F6E747C7C652E7061676526';
wwv_flow_imp.g_varchar2_table(114) := '26652E706167652E666F6E747C7C2268656C766574696361223B72657475726E206C2E736574466F6E7453697A652844292C6C2E73657454657874436F6C6F7228575B305D2C575B315D2C575B325D292C413D463F6E2E793A4D6174682E6D617828412C';
wwv_flow_imp.g_varchar2_table(115) := '6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A41292C53286E2C74292E666F7245616368282866756E6374696F6E2865297B76617220743D5B5D3B5428652C7B666F6E743A482C636F6C6F723A6E2E63';
wwv_flow_imp.g_varchar2_table(116) := '6F6C6F727D292E666F7245616368282866756E6374696F6E2865297B652E742E73706C6974282F28202B292F292E666F7245616368282866756E6374696F6E2872297B2222213D3D722626742E70757368287B743A722C66616D3A795B652E665D5B305D';
wwv_flow_imp.g_varchar2_table(117) := '2C663A592865292C73703A2F5E202B242F2E746573742872292C753A652E752C733A652E732C633A652E633F6128652E63293A577D297D29297D29293B76617220723D5B5D2C6F3D5B5D2C693D303B666F7228742E666F7245616368282866756E637469';
wwv_flow_imp.g_varchar2_table(118) := '6F6E2865297B76617220743D66756E6374696F6E2865297B6C2E736574466F6E7428652E66616D2C652E66293B666F722876617220743D302C723D652E66616D2B652E662B442C6E3D303B6E3C652E742E6C656E6774683B6E2B2B297B766172206F3D72';
wwv_flow_imp.g_varchar2_table(119) := '2B652E742E636861724174286E293B766F696420303D3D3D4D5B6F5D2626284D5B6F5D3D6C2E67657454657874576964746828652E742E636861724174286E2929292C742B3D4D5B6F5D7D72657475726E20747D2865293B69662821652E73702626692B';
wwv_flow_imp.g_varchar2_table(120) := '743E5F26266F2E6C656E677468297B666F72283B6F2E6C656E67746826266F5B6F2E6C656E6774682D315D2E73703B29692D3D6F2E706F7028292E773B722E70757368287B77733A6F2C773A697D292C6F3D5B5D2C693D307D652E73702626216F2E6C65';
wwv_flow_imp.g_varchar2_table(121) := '6E6774687C7C28652E773D742C6F2E707573682865292C692B3D74297D29293B6F2E6C656E67746826266F5B6F2E6C656E6774682D315D2E73703B29692D3D6F2E706F7028292E773B722E70757368287B77733A6F2C773A692C6C6173743A21307D292C';
wwv_flow_imp.g_varchar2_table(122) := '652E7472696D28293F28722E666F7245616368282866756E6374696F6E2865297B21462626412B493E732D632D31302626286C2E6164645061676528292C413D63293B76617220743D652E77732E66696C746572282866756E6374696F6E2865297B7265';
wwv_flow_imp.g_varchar2_table(123) := '7475726E20652E73707D29292E6C656E6774682C723D226A757374696679223D3D3D42262621652E6C6173742626743F285F2D652E77292F743A302C6E3D227269676874223D3D3D423F472B5F2D652E773A2263656E746572223D3D3D423F472B285F2D';
wwv_flow_imp.g_varchar2_table(124) := '652E77292F323A472C6F3D412B2E37352A493B652E77732E666F7245616368282866756E6374696F6E2865297B76617220743D652E772B28652E73703F723A30293B6C2E73657454657874436F6C6F7228652E635B305D2C652E635B315D2C652E635B32';
wwv_flow_imp.g_varchar2_table(125) := '5D292C6C2E73657444726177436F6C6F7228652E635B305D2C652E635B315D2C652E635B325D292C6C2E7365744C696E655769647468282E3031322A44292C652E73707C7C286C2E736574466F6E7428652E66616D2C652E66292C6C2E7465787428652E';
wwv_flow_imp.g_varchar2_table(126) := '742C6E2C6F29292C652E7526266C2E6C696E65286E2C6F2B2E30362A442C6E2B742C6F2B2E30362A44292C652E7326266C2E6C696E65286E2C6F2D2E31312A442C6E2B742C6F2D2E31312A44292C6E2B3D747D29292C412B3D497D29292C412B3D766F69';
wwv_flow_imp.g_varchar2_table(127) := '642030213D3D6E2E7061726167726170684761703F6E2E7061726167726170684761703A2E352A49293A412B3D497D29292C6C2E73657454657874436F6C6F7228302C302C30292C766F696428463F28413D522C6C2E6C6173744175746F5461626C653D';
wwv_flow_imp.g_varchar2_table(128) := '6B293A6C2E6C6173744175746F5461626C653D7B66696E616C593A417D297D696628226C696E6561223D3D3D6F297B76617220243D61286E2E636F6C6F727C7C222330303030303022293B6966286C2E73657444726177436F6C6F7228245B305D2C245B';
wwv_flow_imp.g_varchar2_table(129) := '315D2C245B325D292C6C2E7365744C696E655769647468286E2E746869636B6E6573737C7C2E33292C766F69642030213D3D6E2E78312972657475726E20766F6964206C2E6C696E65286E2E78312C6E2E79312C766F69642030213D3D6E2E78323F6E2E';
wwv_flow_imp.g_varchar2_table(130) := '78323A6E2E78312C766F69642030213D3D6E2E79323F6E2E79323A6E2E7931293B413D4D6174682E6D617828412C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A41292B286E2E6761704265666F7265';
wwv_flow_imp.g_varchar2_table(131) := '7C7C30293B766172205A3D6E2E77696474687C7C752D322A632C4A3D2263656E746572223D3D3D6E2E616C69676E3F28752D5A292F323A227269676874223D3D3D6E2E616C69676E3F752D632D5A3A633B72657475726E206C2E6C696E65284A2C412C4A';
wwv_flow_imp.g_varchar2_table(132) := '2B5A2C41292C412B3D766F69642030213D3D6E2E6761703F6E2E6761703A322C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A417D297D696628226573706163696F223D3D3D6F2972657475726E20413D4D6174682E6D617828';
wwv_flow_imp.g_varchar2_table(133) := '412C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A41292B286E2E6865696768747C7C36292C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A417D293B69662822696D616765';
wwv_flow_imp.g_varchar2_table(134) := '6E223D3D3D6F297B766172204B3D4C286E2C74293B696628214B2972657475726E3B76617220583D55286E2C4B292C563D226A7067223D3D3D4B2E6578743F224A504547223A22504E47222C713D766F69642030213D3D6E2E783F6E2E783A2272696768';
wwv_flow_imp.g_varchar2_table(135) := '74223D3D3D6E2E616C69676E3F752D632D582E773A2263656E746572223D3D3D6E2E616C69676E3F28752D582E77292F323A633B72657475726E20766F69642030213D3D6E2E793F766F6964206C2E616464496D616765284B2E646174612C562C712C6E';
wwv_flow_imp.g_varchar2_table(136) := '2E792C582E772C582E68293A2828413D4D6174682E6D617828412C6C2E6C6173744175746F5461626C653F6C2E6C6173744175746F5461626C652E66696E616C593A4129292B582E683E732D632D31302626286C2E6164645061676528292C413D63292C';
wwv_flow_imp.g_varchar2_table(137) := '6C2E616464496D616765284B2E646174612C562C712C412C582E772C582E68292C412B3D582E682B28766F69642030213D3D6E2E6761703F6E2E6761703A33292C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A417D29297D69';
wwv_flow_imp.g_varchar2_table(138) := '66282273616C746F223D3D3D6F2972657475726E206C2E6164645061676528292C413D632C766F6964286C2E6C6173744175746F5461626C653D7B66696E616C593A637D293B696628226669636861223D3D3D6F297B76617220513D62286E2C74295B30';
wwv_flow_imp.g_varchar2_table(139) := '5D7C7C7B7D2C65653D6E2E636F6C756D6E737C7C332C74653D5B5D2C72653D5B5D2C6E653D7B7D3B696628286E2E6669656C64737C7C5B5D292E66696C746572282866756E6374696F6E2865297B72657475726E21652E7768656E7C7C7628652E776865';
wwv_flow_imp.g_varchar2_table(140) := '6E2C742C51297D29292E666F7245616368282866756E6374696F6E2865297B72652E70757368286D28652E6C6162656C2C742C51292C6A28652C742C5129292C72652E6C656E6774683D3D3D322A656526262874652E70757368287265292C72653D5B5D';
wwv_flow_imp.g_varchar2_table(141) := '297D29292C72652E6C656E677468297B666F72283B72652E6C656E6774683C322A65653B2972652E70757368282222293B74652E70757368287265297D666F7228766172206F653D303B6F653C322A65653B6F652B3D32296E655B6F655D3D7B666F6E74';
wwv_flow_imp.g_varchar2_table(142) := '5374796C653A22626F6C64222C63656C6C57696474683A6E2E6C6162656C57696474687C7C33327D3B72657475726E206C2E6175746F5461626C65287B7374617274593A412C626F64793A74652C7468656D653A22706C61696E222C6D617267696E3A7B';
wwv_flow_imp.g_varchar2_table(143) := '6C6566743A632C72696768743A637D2C7374796C65733A7B666F6E7453697A653A6E2E73697A657C7C382E352C63656C6C50616464696E673A2E397D2C636F6C756D6E5374796C65733A6E657D292C766F6964204F2832297D69662822616C6572746122';
wwv_flow_imp.g_varchar2_table(144) := '213D3D6F297B696628227461626C61223D3D3D6F297B7661722061653D62286E2C74293B6966282161652E6C656E67746826262131213D3D6E2E68696465456D7074792626216E2E656D707479546578742972657475726E3B7661722069653D45286E2C';
wwv_flow_imp.g_varchar2_table(145) := '742C6165292C6C653D5B5D2C75653D7B7D3B6966286E2E7469746C6526266C652E70757368285B7B636F6E74656E743A6D286E2E7469746C652C74292C636F6C5370616E3A69652E6C656E6774682C7374796C65733A7B68616C69676E3A226C65667422';
wwv_flow_imp.g_varchar2_table(146) := '2C666F6E7453697A653A692B317D7D5D292C6E2E67726F757073297B7661722073653D5B5D2C63653D5B5D2C66653D7B68616C69676E3A2263656E746572222C76616C69676E3A226D6964646C65227D3B7A286E2C6965292E666F724561636828286675';
wwv_flow_imp.g_varchar2_table(147) := '6E6374696F6E2865297B666F722876617220743D652E66726F6D3B743C652E66726F6D2B652E636F6C733B742B2B29652E6761703F73652E70757368287B636F6E74656E743A69655B745D2E6C6162656C2C726F775370616E3A322C7374796C65733A66';
wwv_flow_imp.g_varchar2_table(148) := '657D293A63652E707573682869655B745D2E6C6162656C293B652E6761707C7C73652E70757368287B636F6E74656E743A652E6C6162656C2C636F6C5370616E3A652E636F6C732C7374796C65733A66657D297D29292C6C652E707573682873652C6365';
wwv_flow_imp.g_varchar2_table(149) := '297D656C7365206C652E707573682869652E6D6170282866756E6374696F6E2865297B72657475726E20652E6C6162656C7D2929293B69652E666F7245616368282866756E6374696F6E28652C74297B75655B745D3D7B68616C69676E3A652E616C6967';
wwv_flow_imp.g_varchar2_table(150) := '6E7D2C652E636F6C6F7226262875655B745D2E74657874436F6C6F723D6128652E636F6C6F7229292C652E626F6C6426262875655B745D2E666F6E745374796C653D22626F6C6422292C652E776964746826262875655B745D2E63656C6C57696474683D';
wwv_flow_imp.g_varchar2_table(151) := '652E7769647468297D29293B74653D61652E6C656E6774683F61652E6D6170282866756E6374696F6E2865297B72657475726E2069652E6D6170282866756E6374696F6E2872297B72657475726E204328722C652C74297D29297D29293A5B5B7B636F6E';
wwv_flow_imp.g_varchar2_table(152) := '74656E743A6D286E2E656D707479546578742C74292C636F6C5370616E3A69652E6C656E6774682C7374796C65733A7B68616C69676E3A226C656674222C666F6E745374796C653A226974616C6963227D7D5D5D3B7661722070653D6E756C6C3B696628';
wwv_flow_imp.g_varchar2_table(153) := '6E2E746F74616C73262661652E6C656E677468297B7661722064653D6E2E746F74616C732E6D6170282866756E6374696F6E2865297B72657475726E20537472696E672865292E746F55707065724361736528297D29292C68653D21313B70653D5B6965';
wwv_flow_imp.g_varchar2_table(154) := '2E6D6170282866756E6374696F6E2865297B72657475726E20652E636F6C262664652E696E6465784F6628652E636F6C293E3D303F6428502861652C652E636F6C292C652E666D747C7C226D6F6E657922293A68657C7C652E636F6C262664652E696E64';
wwv_flow_imp.g_varchar2_table(155) := '65784F6628652E636F6C293E3D303F22223A2868653D21302C6E2E746F74616C734C6162656C7C7C22546F74616C657322297D29295D7D6C2E6175746F5461626C65287B7374617274593A412C6D617267696E3A7B6C6566743A632C72696768743A637D';
wwv_flow_imp.g_varchar2_table(156) := '2C686561643A6C652C626F64793A74652C666F6F743A70657C7C766F696420302C73686F77486561643A21313D3D3D6E2E7265706561744865616465723F22666972737450616765223A22657665727950616765222C73686F77466F6F743A226C617374';
wwv_flow_imp.g_varchar2_table(157) := '50616765222C7374796C65733A7B666F6E7453697A653A6E2E73697A657C7C692C63656C6C50616464696E673A2E387D2C686561645374796C65733A7B66696C6C436F6C6F723A662C74657874436F6C6F723A702C68616C69676E3A2263656E74657222';
wwv_flow_imp.g_varchar2_table(158) := '2C666F6E7453697A653A6E2E73697A657C7C697D2C666F6F745374796C65733A7B66696C6C436F6C6F723A672C74657874436F6C6F723A302C666F6E745374796C653A22626F6C64222C68616C69676E3A227269676874227D2C616C7465726E61746552';
wwv_flow_imp.g_varchar2_table(159) := '6F775374796C65733A7B66696C6C436F6C6F723A687D2C636F6C756D6E5374796C65733A75652C646964506172736543656C6C3A66756E6374696F6E2865297B69662822626F6479223D3D3D652E73656374696F6E262661652E6C656E677468297B7661';
wwv_flow_imp.g_varchar2_table(160) := '72206F3D61655B652E726F772E696E6465785D2C693D69655B652E636F6C756D6E2E696E6465785D2C6C3D78286E2E726F775374796C652C742C6F293B6C2626286C2E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D6128';
wwv_flow_imp.g_varchar2_table(161) := '6C2E66696C6C29292C6C2E636F6C6F72262628652E63656C6C2E7374796C65732E74657874436F6C6F723D61286C2E636F6C6F7229292C6C2E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229293B766172';
wwv_flow_imp.g_varchar2_table(162) := '20753D6926267828692E63656C6C5374796C652C742C6F293B75262628752E66696C6C262628652E63656C6C2E7374796C65732E66696C6C436F6C6F723D6128752E66696C6C29292C752E636F6C6F72262628652E63656C6C2E7374796C65732E746578';
wwv_flow_imp.g_varchar2_table(163) := '74436F6C6F723D6128752E636F6C6F7229292C752E626F6C64262628652E63656C6C2E7374796C65732E666F6E745374796C653D22626F6C642229292C722626722E70646643656C6C2626722E70646643656C6C28652C6F2C692C6E2C74297D7D7D292C';
wwv_flow_imp.g_varchar2_table(164) := '4F286E2E6761707C7C33297D7D656C73652062286E2C74292E66696C746572282866756E6374696F6E2865297B72657475726E2076286E2E7768656E2C742C65297D29292E736C69636528302C6E2E656163683F3939393A31292E666F72456163682828';
wwv_flow_imp.g_varchar2_table(165) := '66756E6374696F6E2865297B6C2E6175746F5461626C65287B7374617274593A412C7468656D653A22706C61696E222C6D617267696E3A7B6C6566743A632C72696768743A637D2C626F64793A5B5B6D286E2E746578742C742C65295D5D2C7374796C65';
wwv_flow_imp.g_varchar2_table(166) := '733A7B666F6E7453697A653A6E2E73697A657C7C382C666F6E745374796C653A22626F6C64222C63656C6C50616464696E673A312E342C66696C6C436F6C6F723A612877286E2E636F6C6F722C742C65297C7C222345364543463222297D7D292C4F2831';
wwv_flow_imp.g_varchar2_table(167) := '297D29297D29297D29293B766172206B3D652E666F6F7465722C443D6C2E696E7465726E616C2E6765744E756D6265724F66506167657328292C493D745B305D7C7C7B533A7B7D2C543A7B7D7D3B6966286B297B666F722876617220473D313B473C3D44';
wwv_flow_imp.g_varchar2_table(168) := '3B472B2B297B6C2E736574506167652847292C6C2E736574466F6E74282268656C766574696361222C226E6F726D616C22292C6C2E736574466F6E7453697A65286B2E73697A657C7C37293B766172205F3D61286F2E6D75746564293B6C2E7365745465';
wwv_flow_imp.g_varchar2_table(169) := '7874436F6C6F72285F5B305D2C5F5B315D2C5F5B325D293B76617220423D66756E6374696F6E2865297B72657475726E206D28652C49292E7265706C61636528227B504147457D222C47292E7265706C61636528227B50414745537D222C44297D3B6966';
wwv_flow_imp.g_varchar2_table(170) := '286B2E6C656674297B76617220573D6C2E73706C697454657874546F53697A652842286B2E6C656674292C2E37382A75293B6C2E7465787428572C632C732D342D28572E6C656E6774682D31292A286B2E73697A657C7C37292A2E34297D6B2E72696768';
wwv_flow_imp.g_varchar2_table(171) := '7426266C2E746578742842286B2E7269676874292C752D632C732D352C7B616C69676E3A227269676874227D297D6C2E73657454657874436F6C6F7228302C302C30297D72657475726E20652E7469746C6526266C2E73657450726F7065727469657328';
wwv_flow_imp.g_varchar2_table(172) := '7B7469746C653A6D28652E7469746C652C49297D292C50726F6D6973652E7265736F6C7665286C2E6F7574707574282261727261796275666665722229297D66756E6374696F6E204728652C742C72297B766172206E3D6E65772077696E646F772E4578';
wwv_flow_imp.g_varchar2_table(173) := '63656C4A532E576F726B626F6F6B2C613D462865292C6C3D7B7D3B6E2E63726561746F723D226E6F76615265706F7274223B76617220753D652E786C73782626652E786C73782E7368656574737C7C5B7B6E616D653A652E786C73782626652E786C7378';
wwv_flow_imp.g_varchar2_table(174) := '2E73686565744E616D657C7C225265706F727465227D5D2C733D4E28652C22786C737822292C633D652E706167657C7C7B7D2C673D7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A69';
wwv_flow_imp.g_varchar2_table(175) := '28612E7072696D617279297D7D3B66756E6374696F6E20432865297B72657475726E7B747970653A227061747465726E222C7061747465726E3A22736F6C6964222C6667436F6C6F723A7B617267623A692865297D7D7D72657475726E20742E666F7245';
wwv_flow_imp.g_varchar2_table(176) := '616368282866756E6374696F6E284E297B752E666F7245616368282866756E6374696F6E2846297B76617220523D6D28462E6E616D652C4E293B722626742E6C656E6774683E31262628523D6D28462E6D657267654E616D657C7C28752E6C656E677468';
wwv_flow_imp.g_varchar2_table(177) := '3E313F227B444F432E444F435F4B45597D20222B462E6E616D653A227B444F432E444F435F4B45597D22292C4E29293B766172204D3D6E2E616464576F726B73686565742866756E6374696F6E2865297B666F722876617220743D702865292E7265706C';
wwv_flow_imp.g_varchar2_table(178) := '616365282F5B5C5B5C5D5D2F672C2222292E73756273747228302C3331297C7C22486F6A61222C723D742C6E3D323B6C5B722E746F4C6F7765724361736528295D3B29723D742E73756273747228302C33312D537472696E67286E292E6C656E6774682D';
wwv_flow_imp.g_varchar2_table(179) := '31292B225F222B6E2C6E2B2B3B72657475726E206C5B722E746F4C6F7765724361736528295D3D21302C727D2852292C7B7061676553657475703A7B6F7269656E746174696F6E3A632E6F7269656E746174696F6E7C7C22706F727472616974222C7061';
wwv_flow_imp.g_varchar2_table(180) := '70657253697A653A226C6567616C223D3D3D632E73697A653F353A226134223D3D3D632E73697A653F393A312C666974546F506167653A21302C666974546F57696474683A312C666974546F4865696768743A307D7D292C4F3D462E73656374696F6E73';
wwv_flow_imp.g_varchar2_table(181) := '3F462E73656374696F6E732E6D6170282866756E6374696F6E2865297B72657475726E226E756D626572223D3D747970656F6620653F735B655D3A732E66696C746572282866756E6374696F6E2874297B72657475726E20742E69643D3D3D657D29295B';
wwv_flow_imp.g_varchar2_table(182) := '305D7D29292E66696C74657228426F6F6C65616E293A732C6B3D342C443D312C493D7B7D2C473D302C5F3D6E756C6C2C423D6E756C6C3B66756E6374696F6E205728652C74297B76617220723D537472696E67286E756C6C3D3D743F22223A74292E6C65';
wwv_flow_imp.g_varchar2_table(183) := '6E6774683B495B655D3D4D6174682E6D696E2836302C4D6174682E6D617828495B655D7C7C382C722B3229297D66756E6374696F6E205928652C742C722C6E297B4D2E6D6572676543656C6C7328442C312C442C6B293B766172206F3D4D2E6765744365';
wwv_flow_imp.g_varchar2_table(184) := '6C6C28442C31293B6F2E76616C75653D652C6F2E66696C6C3D742C6F2E666F6E743D722C6F2E616C69676E6D656E743D7B766572746963616C3A226D6964646C65222C77726170546578743A21307D2C6E2626284D2E676574526F772844292E68656967';
wwv_flow_imp.g_varchar2_table(185) := '68743D6E292C442B2B7D4F2E666F7245616368282866756E6374696F6E2865297B227461626C61223D3D3D652E74797065262628472B2B2C6B3D4D6174682E6D6178286B2C4528652C4E2C6228652C4E29292E6C656E67746829292C226669636861223D';
wwv_flow_imp.g_varchar2_table(186) := '3D3D652E747970652626286B3D4D6174682E6D6178286B2C322A28652E636F6C756D6E737C7C332929297D29292C4F2E666F7245616368282866756E6374696F6E2874297B76617220723D742E747970653B69662822686561646572223D3D3D72295928';
wwv_flow_imp.g_varchar2_table(187) := '6D28742E7469746C652C4E292C672C7B626F6C643A21302C73697A653A31342C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C3236292C28742E72696768747C7C742E7375627469746C6529262659285B6D28742E737562746974';
wwv_flow_imp.g_varchar2_table(188) := '6C652C4E292C6D28742E72696768742C4E295D2E66696C74657228426F6F6C65616E292E6A6F696E28222020207C20202022292C672C7B73697A653A392C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C3136292C442B2B3B656C';
wwv_flow_imp.g_varchar2_table(189) := '73652069662822746578746F223D3D3D72295328742C4E292E666F7245616368282866756E6374696F6E2872297B4D2E6D6572676543656C6C7328442C312C442C6B293B766172206E3D4D2E67657443656C6C28442C31293B6E2E76616C75653D7B7269';
wwv_flow_imp.g_varchar2_table(190) := '6368546578743A5428722C7B666F6E743A742E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A742E636F6C6F727D292E6D6170282866756E6374696F6E2865297B72657475726E7B746578743A652E742C666F6E743A7B';
wwv_flow_imp.g_varchar2_table(191) := '626F6C643A212821652E62262621742E626F6C64292C6974616C69633A212821652E69262621742E6974616C6963292C756E6465726C696E653A652E757C7C766F696420302C737472696B653A652E737C7C766F696420302C6E616D653A795B652E665D';
wwv_flow_imp.g_varchar2_table(192) := '5B315D2C636F6C6F723A652E633F7B617267623A6928652E63297D3A766F696420302C73697A653A742E73697A657C7C31307D7D7D29297D2C6E2E616C69676E6D656E743D7B77726170546578743A21302C766572746963616C3A22746F70222C686F72';
wwv_flow_imp.g_varchar2_table(193) := '697A6F6E74616C3A226A757374696679223D3D3D742E616C69676E3F226A757374696679223A742E616C69676E7C7C226C656674227D2C4D2E676574526F772844292E6865696768743D4D6174682E6D61782831352C31352A4D6174682E6365696C2872';
wwv_flow_imp.g_varchar2_table(194) := '2E6C656E6774682F31343029292C442B2B7D29293B656C736520696628226573706163696F223D3D3D7229442B2B3B656C73652069662822696D6167656E223D3D3D72297B766172206C3D4C28742C4E293B6966286C297B76617220753D5528742C6C29';
wwv_flow_imp.g_varchar2_table(195) := '2C733D6E2E616464496D616765287B6261736536343A6C2E646174612C657874656E73696F6E3A226A7067223D3D3D6C2E6578743F226A706567223A22706E67227D293B4D2E616464496D61676528732C7B746C3A7B636F6C3A302C726F773A442D317D';
wwv_flow_imp.g_varchar2_table(196) := '2C6578743A7B77696474683A332E37382A752E772C6865696768743A332E37382A752E687D7D292C442B3D4D6174682E6365696C28332E37382A752E682F3230292B317D7D656C7365206966282273616C746F223D3D3D7229442B2B3B656C7365206966';
wwv_flow_imp.g_varchar2_table(197) := '28226669636861223D3D3D72297B76617220633D6228742C4E295B305D7C7C7B7D2C703D742E636F6C756D6E737C7C332C463D313B28742E6669656C64737C7C5B5D292E66696C746572282866756E6374696F6E2865297B72657475726E21652E776865';
wwv_flow_imp.g_varchar2_table(198) := '6E7C7C7628652E7768656E2C4E2C63297D29292E666F7245616368282866756E6374696F6E28652C74297B743E3026267425703D3D30262628442B2B2C463D31293B76617220723D4D2E67657443656C6C28442C46292C6E3D4D2E67657443656C6C2844';
wwv_flow_imp.g_varchar2_table(199) := '2C462B31292C613D6D28652E6C6162656C2C4E2C63293B722E76616C75653D612C722E666F6E743D7B626F6C643A21307D3B76617220693D2F5E5C7B5B5E7D7C5D2B5C7D242F2E7465737428652E76616C75657C7C222229262621652E6D61703F68284E';
wwv_flow_imp.g_varchar2_table(200) := '2C652E76616C75652E736C69636528312C2D31292C63293A6E756C6C3B6F2869293F286E2E76616C75653D692C226D6F6E6579223D3D3D652E666D742626286E2E6E756D466D743D22232C2323302E303022292C6E2E616C69676E6D656E743D7B686F72';
wwv_flow_imp.g_varchar2_table(201) := '697A6F6E74616C3A226C656674227D293A2264617465223D3D3D652E666D742626662869293F286E2E76616C75653D662869292C6E2E6E756D466D743D2264642F6D6D2F79797979222C6E2E616C69676E6D656E743D7B686F72697A6F6E74616C3A226C';
wwv_flow_imp.g_varchar2_table(202) := '656674227D293A6E2E76616C75653D6A28652C4E2C63292C5728462C61292C5728462B312C6A28652C4E2C6329292C462B3D327D29292C442B3D327D656C73652069662822616C65727461223D3D3D72296228742C4E292E66696C746572282866756E63';
wwv_flow_imp.g_varchar2_table(203) := '74696F6E2865297B72657475726E207628742E7768656E2C4E2C65297D29292E736C69636528302C742E656163683F3939393A31292E666F7245616368282866756E6374696F6E2865297B59286D28742E746578742C4E2C65292C43287728742E636F6C';
wwv_flow_imp.g_varchar2_table(204) := '6F722C4E2C65297C7C222345364543463222292C7B626F6C643A21307D2C3330297D29292C442B2B3B656C736520696628227461626C61223D3D3D72297B76617220523D6228742C4E293B69662821522E6C656E67746826262131213D3D742E68696465';
wwv_flow_imp.g_varchar2_table(205) := '456D707479262621742E656D707479546578742972657475726E3B76617220493D4528742C4E2C52293B696628742E7469746C65297B4D2E6D6572676543656C6C7328442C312C442C492E6C656E677468293B76617220483D4D2E67657443656C6C2844';
wwv_flow_imp.g_varchar2_table(206) := '2C31293B482E76616C75653D6D28742E7469746C652C4E292C482E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C482E66696C6C3D672C442B2B7D696628742E67726F757073297B7661722024';
wwv_flow_imp.g_varchar2_table(207) := '3D313B7A28742C49292E666F7245616368282866756E6374696F6E2865297B652E636F6C733E31262621652E67617026264D2E6D6572676543656C6C7328442C242C442C242B652E636F6C732D31293B76617220743D4D2E67657443656C6C28442C2429';
wwv_flow_imp.g_varchar2_table(208) := '3B696628652E676170297B666F722876617220723D303B723C652E636F6C733B722B2B297B4D2E6D6572676543656C6C7328442C242B722C442B312C242B72293B766172206E3D4D2E67657443656C6C28442C242B72293B6E2E76616C75653D495B652E';
wwv_flow_imp.g_varchar2_table(209) := '66726F6D2B725D2E6C6162656C2C6E2E66696C6C3D672C6E2E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C6E2E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C';
wwv_flow_imp.g_varchar2_table(210) := '766572746963616C3A226D6964646C65222C77726170546578743A21307D2C5728242B722C495B652E66726F6D2B725D2E6C6162656C297D242B3D652E636F6C737D656C736520742E76616C75653D652E6C6162656C7C7C6E756C6C2C742E66696C6C3D';
wwv_flow_imp.g_varchar2_table(211) := '672C742E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C742E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C65227D2C242B';
wwv_flow_imp.g_varchar2_table(212) := '3D652E636F6C737D29292C442B2B7D766172205A3D442C4A3D7B7D3B696628742E67726F75707326267A28742C49292E666F7245616368282866756E6374696F6E2865297B696628652E67617029666F722876617220743D652E66726F6D3B743C652E66';
wwv_flow_imp.g_varchar2_table(213) := '726F6D2B652E636F6C733B742B2B294A5B745D3D317D29292C492E666F7245616368282866756E6374696F6E28652C74297B696628214A5B745D297B76617220723D4D2E67657443656C6C28442C742B31293B722E76616C75653D652E6C6162656C2C72';
wwv_flow_imp.g_varchar2_table(214) := '2E66696C6C3D672C722E666F6E743D7B626F6C643A21302C636F6C6F723A7B617267623A6928612E6865616454657874297D7D2C722E616C69676E6D656E743D7B686F72697A6F6E74616C3A2263656E746572222C766572746963616C3A226D6964646C';
wwv_flow_imp.g_varchar2_table(215) := '65222C77726170546578743A21307D2C5728742B312C652E6C6162656C297D7D29292C442B2B2C21522E6C656E6774682972657475726E204D2E6D6572676543656C6C7328442C312C442C492E6C656E677468292C4D2E67657443656C6C28442C31292E';
wwv_flow_imp.g_varchar2_table(216) := '76616C75653D6D28742E656D707479546578742C4E292C4D2E67657443656C6C28442C31292E666F6E743D7B6974616C69633A21307D2C766F696428442B3D32293B766172204B3D443B696628522E666F7245616368282866756E6374696F6E28652C72';
wwv_flow_imp.g_varchar2_table(217) := '297B766172206E3D7828742E726F775374796C652C4E2C65293B492E666F7245616368282866756E6374696F6E286C2C75297B76617220733D4D2E67657443656C6C28442C752B31292C633D41286C2C652C4E293B6C2E69734E756D26266F2863293F28';
wwv_flow_imp.g_varchar2_table(218) := '732E76616C75653D632C732E6E756D466D743D22696E74223D3D3D6C2E666D743F22232C232330223A226D6F6E6579223D3D3D6C2E666D747C7C2F5E6E756D2F2E74657374286C2E666D747C7C2222293F22232C2323302E222B6E657720417272617928';
wwv_flow_imp.g_varchar2_table(219) := '312A28286C2E666D747C7C2222292E73706C697428223A22295B315D7C7C32292B31292E6A6F696E28223022293A2247656E6572616C22293A226461746522213D3D6C2E666D742626224441544522213D3D284E2E545B537472696E6728742E736F7572';
wwv_flow_imp.g_varchar2_table(220) := '6365292E746F55707065724361736528295D7C7C7B7D295B6C2E636F6C5D7C7C21662863293F732E76616C75653D6E756C6C3D3D633F6E756C6C3A537472696E672863293A28732E76616C75653D662863292C732E6E756D466D743D2264642F6D6D2F79';
wwv_flow_imp.g_varchar2_table(221) := '79797922292C732E616C69676E6D656E743D7B686F72697A6F6E74616C3A6C2E616C69676E7D3B76617220703D78286C2E63656C6C5374796C652C4E2C65297C7C6E3B702626702E66696C6C3F732E66696C6C3D4328702E66696C6C293A7225323D3D31';
wwv_flow_imp.g_varchar2_table(222) := '26262131213D3D742E7A65627261262628732E66696C6C3D4328612E7A6562726129293B76617220683D7B7D3B286C2E626F6C647C7C702626702E626F6C6429262628682E626F6C643D2130292C28702626702E636F6C6F727C7C6C2E636F6C6F722926';
wwv_flow_imp.g_varchar2_table(223) := '2628682E636F6C6F723D7B617267623A6928702626702E636F6C6F727C7C6C2E636F6C6F72297D292C28682E626F6C647C7C682E636F6C6F7229262628732E666F6E743D68292C5728752B312C6C2E69734E756D3F6428632C6C2E666D74293A63297D29';
wwv_flow_imp.g_varchar2_table(224) := '292C442B2B7D29292C742E746F74616C73297B76617220583D742E746F74616C732E6D6170282866756E6374696F6E2865297B72657475726E20537472696E672865292E746F55707065724361736528297D29292C563D21313B492E666F724561636828';
wwv_flow_imp.g_varchar2_table(225) := '2866756E6374696F6E28652C72297B766172206E3D4D2E67657443656C6C28442C722B31292C6F3D4D2E676574436F6C756D6E28722B31292E6C65747465723B652E636F6C2626582E696E6465784F6628652E636F6C293E3D303F286E2E76616C75653D';
wwv_flow_imp.g_varchar2_table(226) := '7B666F726D756C613A2253554D28222B6F2B4B2B223A222B6F2B28442D31292B2229222C726573756C743A4D6174682E726F756E64283130302A5028522C652E636F6C29292F3130307D2C6E2E6E756D466D743D22232C2323302E303022293A567C7C28';
wwv_flow_imp.g_varchar2_table(227) := '563D21302C6E2E76616C75653D742E746F74616C734C6162656C7C7C22546F74616C657322292C6E2E66696C6C3D4328612E746F74616C73292C6E2E666F6E743D7B626F6C643A21307D7D29292C442B2B7D313D3D3D47262628423D7B66726F6D3A7B72';
wwv_flow_imp.g_varchar2_table(228) := '6F773A5A2C636F6C756D6E3A317D2C746F3A7B726F773A442D312D28742E746F74616C733F313A30292C636F6C756D6E3A492E6C656E6774687D7D2C4F2E696E6465784F662874293C3D312626285F3D5A29292C442B2B7D7D29292C4F626A6563742E6B';
wwv_flow_imp.g_varchar2_table(229) := '6579732849292E666F7245616368282866756E6374696F6E2865297B4D2E676574436F6C756D6E282B65292E77696474683D495B655D7D29292C422626284D2E6175746F46696C7465723D42292C5F2626284D2E76696577733D5B7B73746174653A2266';
wwv_flow_imp.g_varchar2_table(230) := '726F7A656E222C7953706C69743A5F7D5D292C652E666F6F7465722626284D2E686561646572466F6F7465722E6F6464466F6F7465723D22264C2638222B6D28652E666F6F7465722E6C6566742C4E292E7265706C616365282F262F672C22262622292E';
wwv_flow_imp.g_varchar2_table(231) := '73756273747228302C323030292B2226522638505C753030653167696E6120265020646520264E22297D29297D29292C6E2E786C73782E777269746542756666657228297D766172205F3D7B6C65747465723A5B31323234302C31353834305D2C6C6567';
wwv_flow_imp.g_varchar2_table(232) := '616C3A5B31323234302C32303136305D2C61343A5B31313930362C31363833385D7D3B66756E6374696F6E204228652C742C72297B766172206E3D77696E646F772E646F63782C6F3D5B5D2C613D4D6174682E726F756E6428322A28652E73697A657C7C';
wwv_flow_imp.g_varchar2_table(233) := '3729292C693D6C28722E6D75746564293B66756E6374696F6E20752865297B76617220723D6D28652C74292E73706C6974282F285C7B50414745533F5C7D292F292C6F3D5B5D3B72657475726E20722E666F7245616368282866756E6374696F6E286529';
wwv_flow_imp.g_varchar2_table(234) := '7B227B504147457D223D3D3D653F6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E43555252454E545D2C73697A653A612C636F6C6F723A697D29293A227B50414745537D223D3D3D653F';
wwv_flow_imp.g_varchar2_table(235) := '6F2E70757368286E6577206E2E5465787452756E287B6368696C6472656E3A5B6E2E506167654E756D6265722E544F54414C5F50414745535D2C73697A653A612C636F6C6F723A697D29293A6526266F2E70757368286E6577206E2E5465787452756E28';
wwv_flow_imp.g_varchar2_table(236) := '7B746578743A652C73697A653A612C636F6C6F723A697D29297D29292C6F7D72657475726E20652E6C65667426266F2E70757368286E6577206E2E506172616772617068287B6368696C6472656E3A7528652E6C656674297D29292C652E726967687426';
wwv_flow_imp.g_varchar2_table(237) := '266F2E70757368286E6577206E2E506172616772617068287B616C69676E6D656E743A6E2E416C69676E6D656E74547970652E52494748542C6368696C6472656E3A7528652E7269676874297D29292C6F2E6C656E6774683F6F3A5B6E6577206E2E5061';
wwv_flow_imp.g_varchar2_table(238) := '72616772617068287B6368696C6472656E3A5B5D7D295D7D76617220573D7B7D3B66756E6374696F6E20592865297B76617220743D652E73706C697428227C22292C723D745B305D2E7472696D28292C6E3D745B315D3F745B315D2E7472696D28293A6E';
wwv_flow_imp.g_varchar2_table(239) := '756C6C3B72657475726E7B6765743A66756E6374696F6E28652C74297B696628222E223D3D3D722972657475726E20653B666F7228766172206F3D722E73706C697428222E22292C613D742626742E73636F70654C6973743F742E73636F70654C697374';
wwv_flow_imp.g_varchar2_table(240) := '2E736C69636528292E7265766572736528293A5B655D2C693D303B693C612E6C656E6774683B692B2B297B666F7228766172206C3D615B695D2C753D21302C733D303B733C6F2E6C656E6774683B732B2B297B69662841727261792E6973417272617928';
wwv_flow_imp.g_varchar2_table(241) := '6C292626733E302626286C3D6C5B305D292C6E756C6C3D3D6C7C7C226F626A65637422213D747970656F66206C7C7C21286F5B735D696E206C29297B753D21313B627265616B7D6C3D6C5B6F5B735D5D7D696628752972657475726E206E262621417272';
wwv_flow_imp.g_varchar2_table(242) := '61792E69734172726179286C293F64286C2C6E293A6C7D7D7D7D66756E6374696F6E204828652C74297B76617220723D6E65772077696E646F772E50697A5A69702865292C6E3D6E657728302C77696E646F772E646F637874656D706C61746572292872';
wwv_flow_imp.g_varchar2_table(243) := '2C7B7061726167726170684C6F6F703A21302C6C696E65627265616B733A21302C7061727365723A592C6E756C6C4765747465723A66756E6374696F6E28297B72657475726E22227D7D293B72657475726E206E2E72656E6465722866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(244) := '2865297B76617220742C723D7B7D3B666F72287420696E20652E706172616D737C7C7B7D29725B745D3D652E706172616D735B745D3B666F72287420696E20652E646F637C7C7B7D29725B745D3D652E646F635B745D3B666F72287420696E20652E5329';
wwv_flow_imp.g_varchar2_table(245) := '725B745D3D652E535B745D3B72657475726E20722E444F433D652E646F637C7C7B7D2C722E504152414D3D652E706172616D737C7C7B7D2C722E4E4F573D7328292C722E544F4441593D6328292C727D287429292C50726F6D6973652E7265736F6C7665';
wwv_flow_imp.g_varchar2_table(246) := '286E2E6765745A697028292E67656E6572617465287B747970653A226172726179627566666572222C636F6D7072657373696F6E3A224445464C415445227D29297D66756E6374696F6E20242865297B76617220743D7B7D2C723D7B7D3B72657475726E';
wwv_flow_imp.g_varchar2_table(247) := '204F626A6563742E6B65797328657C7C7B7D292E666F7245616368282866756E6374696F6E286E297B766172206F3D655B6E5D2C613D6F2E636F6C737C7C5B5D3B725B6E5D3D7B7D2C612E666F7245616368282866756E6374696F6E2865297B725B6E5D';
wwv_flow_imp.g_varchar2_table(248) := '5B652E6E616D655D3D652E747970657D29292C745B6E5D3D286F2E726F77737C7C5B5D292E6D6170282866756E6374696F6E2865297B76617220743D7B7D3B72657475726E20612E666F7245616368282866756E6374696F6E28722C6E297B745B722E6E';
wwv_flow_imp.g_varchar2_table(249) := '616D655D3D655B6E5D7D29292C747D29297D29292C7B533A742C543A727D7D66756E6374696F6E205A28652C74297B76617220723D652E532E444F43533B69662821722972657475726E5B7B533A652E532C543A652E542C646F633A7B7D2C706172616D';
wwv_flow_imp.g_varchar2_table(250) := '733A747D5D3B766172206E3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F7245616368282866756E6374696F6E2874297B69662822444F435322213D3D7426264F626A6563742E70726F746F747970652E6861734F776E5072';
wwv_flow_imp.g_varchar2_table(251) := '6F70657274792E63616C6C28652E545B745D2C22444F435F4B45592229297B76617220723D6E5B745D3D7B7D3B652E535B745D2E666F7245616368282866756E6374696F6E2865297B76617220743D537472696E6728652E444F435F4B4559293B28725B';
wwv_flow_imp.g_varchar2_table(252) := '745D3D725B745D7C7C5B5D292E707573682865297D29297D7D29292C722E6D6170282866756E6374696F6E2872297B766172206F3D7B7D3B72657475726E204F626A6563742E6B65797328652E53292E666F7245616368282866756E6374696F6E287429';
wwv_flow_imp.g_varchar2_table(253) := '7B6F5B745D3D6E5B745D3F6E5B745D5B537472696E6728722E444F435F4B4559295D7C7C5B5D3A652E535B745D7D29292C6F2E444F43533D5B725D2C7B533A6F2C543A652E542C646F633A722C706172616D733A747D7D29297D66756E6374696F6E204A';
wwv_flow_imp.g_varchar2_table(254) := '2865297B76617220743D646F63756D656E742E676574456C656D656E744279496428226E722D6176616E636522293B653F28747C7C2828743D646F63756D656E742E637265617465456C656D656E7428226469762229292E69643D226E722D6176616E63';
wwv_flow_imp.g_varchar2_table(255) := '65222C742E7365744174747269627574652822726F6C65222C2273746174757322292C742E7374796C652E637373546578743D22706F736974696F6E3A66697865643B72696768743A323470783B626F74746F6D3A323470783B7A2D696E6465783A3130';
wwv_flow_imp.g_varchar2_table(256) := '30303B70616464696E673A3134707820313870783B626F726465722D7261646975733A3870783B6261636B67726F756E643A233166346537393B636F6C6F723A236666663B666F6E742D73697A653A313370783B626F782D736861646F773A3020387078';
wwv_flow_imp.g_varchar2_table(257) := '2032347078207267626128302C302C302C2E3235293B6D61782D77696474683A3336307078222C646F63756D656E742E626F64792E617070656E644368696C64287429292C742E696E6E657248544D4C3D273C7370616E20636C6173733D226661206661';
wwv_flow_imp.g_varchar2_table(258) := '2D7370696E6E65722066612D616E696D2D7370696E2220617269612D68696464656E3D2274727565223E3C2F7370616E3E266E6273703B20272B537472696E672865292E7265706C616365282F5B263C3E225D2F672C2866756E6374696F6E2865297B72';
wwv_flow_imp.g_varchar2_table(259) := '657475726E7B2226223A2226616D703B222C223C223A22266C743B222C223E223A222667743B222C2722273A222671756F743B227D5B655D7D2929293A742626742E72656D6F766528297D66756E6374696F6E204B28652C74297B69662865262621652E';
wwv_flow_imp.g_varchar2_table(260) := '636C6F736564297472797B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F616465724D73672977696E646F772E636F744C6F616465724D736728652C74293B656C73657B76617220723D652E646F63756D656E742E';
wwv_flow_imp.g_varchar2_table(261) := '676574456C656D656E744279496428226D736722293B72262628722E74657874436F6E74656E743D74297D7D63617463682865297B7D7D66756E6374696F6E205828652C74297B7472797B77696E646F772E617065782626617065782E6576656E742626';
wwv_flow_imp.g_varchar2_table(262) := '617065782E6576656E742E7472696767657228646F63756D656E742C226E6F76617265706F72742D222B652C74297D63617463682865297B7D7D66756E6374696F6E20562865297B77696E646F772E617065782626617065782E6D6573736167653F6170';
wwv_flow_imp.g_varchar2_table(263) := '65782E6D6573736167652E616C6572742865293A77696E646F772E616C6572742865297D76617220713D7B7064663A226170706C69636174696F6E2F706466222C786C73783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174';
wwv_flow_imp.g_varchar2_table(264) := '732D6F6666696365646F63756D656E742E73707265616473686565746D6C2E7368656574222C646F63783A226170706C69636174696F6E2F766E642E6F70656E786D6C666F726D6174732D6F6666696365646F63756D656E742E776F726470726F636573';
wwv_flow_imp.g_varchar2_table(265) := '73696E676D6C2E646F63756D656E74227D2C513D7B7064663A22706466222C786C73783A22786C7378222C646F63783A22646F6378222C22646F63782D74656D706C617465223A22646F6378227D3B66756E6374696F6E20656528652C742C72297B7661';
wwv_flow_imp.g_varchar2_table(266) := '72206E3D6D28652E66696C654E616D657C7C227265706F727465222C74292C6F3D515B725D3B72657475726E2070286E3D6E2E7265706C616365282F5C2E287064667C786C73787C646F637829242F692C222229292B222E222B6F7D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(267) := '20746528652C742C722C6E297B72657475726E22706466223D3D3D653F4928742C722C6E2E686F6F6B73293A22786C7378223D3D3D653F4728742C722C722E6C656E6774683E31293A22646F6378223D3D3D653F66756E6374696F6E28652C74297B7661';
wwv_flow_imp.g_varchar2_table(268) := '7220723D77696E646F772E646F63782C6E3D462865292C6F3D652E706167657C7C7B7D2C613D5F5B6F2E73697A657C7C226C6574746572225D7C7C5F2E6C65747465722C693D226C616E647363617065223D3D3D6F2E6F7269656E746174696F6E2C753D';
wwv_flow_imp.g_varchar2_table(269) := '4D6174682E726F756E642835362E372A286F2E6D617267696E7C7C31322E3729292C733D28693F615B315D3A615B305D292D322A752C633D7B7374796C653A722E426F726465725374796C652E4E4F4E452C73697A653A302C636F6C6F723A2246464646';
wwv_flow_imp.g_varchar2_table(270) := '4646227D2C663D7B746F703A632C626F74746F6D3A632C6C6566743A632C72696768743A632C696E73696465486F72697A6F6E74616C3A632C696E73696465566572746963616C3A637D2C703D7B7374796C653A722E426F726465725374796C652E5349';
wwv_flow_imp.g_varchar2_table(271) := '4E474C452C73697A653A322C636F6C6F723A22424643394434227D2C683D7B746F703A702C626F74746F6D3A702C6C6566743A702C72696768743A702C696E73696465486F72697A6F6E74616C3A702C696E73696465566572746963616C3A707D2C673D';
wwv_flow_imp.g_varchar2_table(272) := '4D6174682E726F756E6428322A286E2E666F6E7453697A657C7C3729293B66756E6374696F6E204128652C74297B72657475726E20743D747C7C7B7D2C6E657720722E5465787452756E287B746578743A537472696E67286E756C6C3D3D653F22223A65';
wwv_flow_imp.g_varchar2_table(273) := '292C626F6C643A2121742E626F6C642C6974616C6963733A2121742E6974616C69632C73697A653A742E73697A657C7C672C636F6C6F723A742E636F6C6F723F6C28742E636F6C6F72293A766F696420302C666F6E743A2243616C69627269227D297D66';
wwv_flow_imp.g_varchar2_table(274) := '756E6374696F6E205228652C74297B72657475726E20743D747C7C7B7D2C6E657720722E506172616772617068287B6368696C6472656E3A5B4128652C74295D2C73706163696E673A7B6265666F72653A302C61667465723A307D2C616C69676E6D656E';
wwv_flow_imp.g_varchar2_table(275) := '743A227269676874223D3D3D742E616C69676E3F722E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D742E616C69676E3F722E416C69676E6D656E74547970652E43454E5445523A722E416C69676E6D656E74547970652E';
wwv_flow_imp.g_varchar2_table(276) := '4C4546547D297D66756E6374696F6E204D28652C74297B72657475726E20743D747C7C7B7D2C6E657720722E5461626C6543656C6C287B6368696C6472656E3A5B5228652C74295D2C636F6C756D6E5370616E3A742E7370616E2C6D617267696E733A7B';
wwv_flow_imp.g_varchar2_table(277) := '746F703A33302C626F74746F6D3A33302C6C6566743A36302C72696768743A36307D2C73686164696E673A742E66696C6C3F7B747970653A722E53686164696E67547970652E434C4541522C636F6C6F723A226175746F222C66696C6C3A6C28742E6669';
wwv_flow_imp.g_varchar2_table(278) := '6C6C297D3A766F696420307D297D66756E6374696F6E204F28297B72657475726E206E657720722E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B6265666F72653A36302C61667465723A36307D7D297D766172206B3D';
wwv_flow_imp.g_varchar2_table(279) := '742E6D6170282866756E6374696F6E2874297B766172206F3D5B5D3B4E28652C22646F637822292E666F7245616368282866756E6374696F6E2861297B76617220693D612E747970653B69662822686561646572223D3D3D69297B76617220753D5B6E65';
wwv_flow_imp.g_varchar2_table(280) := '7720722E5461626C65526F77287B6368696C6472656E3A5B4D286D28612E7469746C652C74292C7B626F6C643A21302C73697A653A32382C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172797D292C4D286D28612E72696768';
wwv_flow_imp.g_varchar2_table(281) := '742C74292C7B73697A653A31382C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C616C69676E3A227269676874227D295D7D295D3B612E7375627469746C652626752E70757368286E657720722E5461626C65526F7728';
wwv_flow_imp.g_varchar2_table(282) := '7B6368696C6472656E3A5B4D286D28612E7375627469746C652C74292C7B73697A653A31382C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C7370616E3A327D295D7D29292C6F2E70757368286E657720722E5461626C';
wwv_flow_imp.g_varchar2_table(283) := '65287B726F77733A752C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B4D6174682E726F756E64282E372A73292C4D6174682E726F756E64282E332A73295D2C626F726465';
wwv_flow_imp.g_varchar2_table(284) := '72733A667D292C4F2829297D656C73652069662822746578746F223D3D3D69297B76617220633D7B72696768743A722E416C69676E6D656E74547970652E52494748542C63656E7465723A722E416C69676E6D656E74547970652E43454E5445522C6A75';
wwv_flow_imp.g_varchar2_table(285) := '73746966793A722E416C69676E6D656E74547970652E4A55535449464945447D3B5328612C74292E666F7245616368282866756E6374696F6E2874297B6F2E70757368286E657720722E506172616772617068287B616C69676E6D656E743A635B612E61';
wwv_flow_imp.g_varchar2_table(286) := '6C69676E5D7C7C722E416C69676E6D656E74547970652E4C4546542C696E64656E743A612E696E64656E743F7B6C6566743A4D6174682E726F756E642835362E372A612E696E64656E74297D3A766F696420302C73706163696E673A7B61667465723A76';
wwv_flow_imp.g_varchar2_table(287) := '6F69642030213D3D612E7061726167726170684761703F4D6174682E726F756E642835362E372A612E706172616772617068476170293A3132302C6C696E653A4D6174682E726F756E64283234302A28612E6C696E654865696768747C7C312E31352929';
wwv_flow_imp.g_varchar2_table(288) := '7D2C6368696C6472656E3A5428742C7B666F6E743A612E666F6E747C7C652E706167652626652E706167652E666F6E742C636F6C6F723A612E636F6C6F727D292E6D6170282866756E6374696F6E2865297B72657475726E206E657720722E5465787452';
wwv_flow_imp.g_varchar2_table(289) := '756E287B746578743A652E742C626F6C643A212821652E62262621612E626F6C64292C6974616C6963733A212821652E69262621612E6974616C6963292C73697A653A322A28612E73697A657C7C3130292C756E6465726C696E653A652E753F7B7D3A76';
wwv_flow_imp.g_varchar2_table(290) := '6F696420302C737472696B653A2121652E732C636F6C6F723A652E633F6C28652E63293A766F696420302C666F6E743A795B652E665D5B315D7D297D29297D29297D29297D656C736520696628226573706163696F223D3D3D69296F2E70757368286E65';
wwv_flow_imp.g_varchar2_table(291) := '7720722E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28612E6865696768747C7C3629297D7D29293B656C736520696628226C696E6561223D3D3D69297B6966';
wwv_flow_imp.g_varchar2_table(292) := '28766F696420303D3D3D612E7831297B76617220703D4D6174682E726F756E642835362E372A28612E77696474687C7C3029292C413D703F4D6174682E6D617828302C4D6174682E726F756E642828732D70292F3229293A303B6F2E70757368286E6577';
wwv_flow_imp.g_varchar2_table(293) := '20722E506172616772617068287B6368696C6472656E3A5B5D2C73706163696E673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3229297D2C696E64656E743A2263656E746572223D';
wwv_flow_imp.g_varchar2_table(294) := '3D3D612E616C69676E3F7B6C6566743A412C72696768743A417D3A227269676874223D3D3D612E616C69676E3F7B6C6566743A322A417D3A7B72696768743A322A417D2C626F726465723A7B626F74746F6D3A7B7374796C653A722E426F726465725374';
wwv_flow_imp.g_varchar2_table(295) := '796C652E53494E474C452C73697A653A4D6174682E6D617828322C4D6174682E726F756E642832302A28612E746869636B6E6573737C7C2E332929292C636F6C6F723A6C28612E636F6C6F727C7C222330303030303022292C73706163653A317D7D7D29';
wwv_flow_imp.g_varchar2_table(296) := '297D7D656C73652069662822696D6167656E223D3D3D69297B766172204E3D4C28612C74293B6966284E297B76617220463D5528612C4E293B6F2E70757368286E657720722E506172616772617068287B616C69676E6D656E743A227269676874223D3D';
wwv_flow_imp.g_varchar2_table(297) := '3D612E616C69676E3F722E416C69676E6D656E74547970652E52494748543A2263656E746572223D3D3D612E616C69676E3F722E416C69676E6D656E74547970652E43454E5445523A722E416C69676E6D656E74547970652E4C4546542C73706163696E';
wwv_flow_imp.g_varchar2_table(298) := '673A7B61667465723A4D6174682E726F756E642835362E372A28766F69642030213D3D612E6761703F612E6761703A3329297D2C6368696C6472656E3A5B6E657720722E496D61676552756E287B747970653A226A7067223D3D3D4E2E6578743F226A70';
wwv_flow_imp.g_varchar2_table(299) := '67223A22706E67222C646174613A4E2E6275662C7472616E73666F726D6174696F6E3A7B77696474683A4D6174682E726F756E6428332E37382A462E77292C6865696768743A4D6174682E726F756E6428332E37382A462E68297D7D295D7D29297D7D65';
wwv_flow_imp.g_varchar2_table(300) := '6C7365206966282273616C746F223D3D3D69296F2E70757368286E657720722E506172616772617068287B6368696C6472656E3A5B6E657720722E50616765427265616B5D7D29293B656C736520696628226669636861223D3D3D69297B76617220523D';
wwv_flow_imp.g_varchar2_table(301) := '6228612C74295B305D7C7C7B7D2C6B3D612E636F6C756D6E737C7C332C443D5B5D2C493D5B5D3B69662828612E6669656C64737C7C5B5D292E66696C746572282866756E6374696F6E2865297B72657475726E21652E7768656E7C7C7628652E7768656E';
wwv_flow_imp.g_varchar2_table(302) := '2C742C52297D29292E666F7245616368282866756E6374696F6E2865297B492E70757368284D286D28652E6C6162656C2C742C52292C7B626F6C643A21302C73697A653A31377D292C4D286A28652C742C52292C7B73697A653A31377D29292C492E6C65';
wwv_flow_imp.g_varchar2_table(303) := '6E6774683D3D3D322A6B262628442E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A497D29292C493D5B5D297D29292C492E6C656E677468297B666F72283B492E6C656E6774683C322A6B3B29492E70757368284D28222229';
wwv_flow_imp.g_varchar2_table(304) := '293B442E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A497D29297D696628442E6C656E677468297B666F722876617220473D5B5D2C5F3D303B5F3C322A6B3B5F2B2B29472E70757368284D6174682E726F756E6428732F28';
wwv_flow_imp.g_varchar2_table(305) := '322A6B2929293B6F2E70757368286E657720722E5461626C65287B726F77733A442C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C636F6C756D6E5769647468733A472C626F72646572733A667D292C4F2829';
wwv_flow_imp.g_varchar2_table(306) := '297D7D656C73652069662822616C65727461223D3D3D69296228612C74292E66696C746572282866756E6374696F6E2865297B72657475726E207628612E7768656E2C742C65297D29292E736C69636528302C612E656163683F3939393A31292E666F72';
wwv_flow_imp.g_varchar2_table(307) := '45616368282866756E6374696F6E2865297B6F2E70757368286E657720722E5461626C65287B726F77733A5B6E657720722E5461626C65526F77287B6368696C6472656E3A5B4D286D28612E746578742C742C65292C7B626F6C643A21302C73697A653A';
wwv_flow_imp.g_varchar2_table(308) := '31372C66696C6C3A7728612E636F6C6F722C742C65297C7C2223453645434632227D295D7D295D2C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C636F6C756D6E5769647468733A5B735D2C626F7264657273';
wwv_flow_imp.g_varchar2_table(309) := '3A667D292C4F2829297D29293B656C736520696628227461626C61223D3D3D69297B76617220423D6228612C74293B69662821422E6C656E67746826262131213D3D612E68696465456D707479262621612E656D707479546578742972657475726E3B76';
wwv_flow_imp.g_varchar2_table(310) := '617220573D4528612C742C42292C593D5B5D3B696628612E7469746C652626592E70757368286E657720722E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A5B4D286D28612E7469746C652C74292C7B626F6C643A';
wwv_flow_imp.g_varchar2_table(311) := '21302C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C7370616E3A572E6C656E6774682C73697A653A672B327D295D7D29292C612E67726F7570732626592E70757368286E657720722E5461626C65526F77287B746162';
wwv_flow_imp.g_varchar2_table(312) := '6C654865616465723A21302C6368696C6472656E3A7A28612C57292E6D6170282866756E6374696F6E2865297B72657475726E204D28652E6C6162656C7C7C22222C7B626F6C643A21302C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E70';
wwv_flow_imp.g_varchar2_table(313) := '72696D6172792C616C69676E3A2263656E746572222C7370616E3A652E636F6C737D297D29297D29292C592E70757368286E657720722E5461626C65526F77287B7461626C654865616465723A21302C6368696C6472656E3A572E6D6170282866756E63';
wwv_flow_imp.g_varchar2_table(314) := '74696F6E2865297B72657475726E204D28652E6C6162656C2C7B626F6C643A21302C636F6C6F723A6E2E68656164546578742C66696C6C3A6E2E7072696D6172792C616C69676E3A2263656E746572227D297D29297D29292C422E6C656E6774687C7C59';
wwv_flow_imp.g_varchar2_table(315) := '2E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A5B4D286D28612E656D707479546578742C74292C7B6974616C69633A21302C7370616E3A572E6C656E6774687D295D7D29292C422E666F7245616368282866756E6374696F';
wwv_flow_imp.g_varchar2_table(316) := '6E28652C6F297B76617220693D7828612E726F775374796C652C742C65293B592E70757368286E657720722E5461626C65526F77287B63616E7453706C69743A21302C6368696C6472656E3A572E6D6170282866756E6374696F6E2872297B766172206C';
wwv_flow_imp.g_varchar2_table(317) := '3D7828722E63656C6C5374796C652C742C65297C7C697C7C7B7D3B72657475726E204D284328722C652C74292C7B616C69676E3A722E616C69676E2C626F6C643A722E626F6C647C7C6C2E626F6C642C636F6C6F723A6C2E636F6C6F727C7C722E636F6C';
wwv_flow_imp.g_varchar2_table(318) := '6F722C66696C6C3A6C2E66696C6C7C7C286F25323D3D3126262131213D3D612E7A656272613F6E2E7A656272613A6E756C6C297D297D29297D29297D29292C612E746F74616C732626422E6C656E677468297B76617220483D612E746F74616C732E6D61';
wwv_flow_imp.g_varchar2_table(319) := '70282866756E6374696F6E2865297B72657475726E20537472696E672865292E746F55707065724361736528297D29292C243D21313B592E70757368286E657720722E5461626C65526F77287B6368696C6472656E3A572E6D6170282866756E6374696F';
wwv_flow_imp.g_varchar2_table(320) := '6E2865297B76617220743D22223B72657475726E20652E636F6C2626482E696E6465784F6628652E636F6C293E3D303F743D64285028422C652E636F6C292C652E666D747C7C226D6F6E657922293A247C7C28243D21302C743D612E746F74616C734C61';
wwv_flow_imp.g_varchar2_table(321) := '62656C7C7C22546F74616C657322292C4D28742C7B626F6C643A21302C616C69676E3A227269676874222C66696C6C3A6E2E746F74616C737D297D29297D29297D766172205A3D572E6D6170282866756E6374696F6E2865297B72657475726E20652E77';
wwv_flow_imp.g_varchar2_table(322) := '696474683F652E77696474682F32303A317D29292C4A3D5A2E726564756365282866756E6374696F6E28652C74297B72657475726E20652B747D292C30292C4B3D5A2E6D6170282866756E6374696F6E2865297B72657475726E204D6174682E666C6F6F';
wwv_flow_imp.g_varchar2_table(323) := '7228732A652F4A297D29293B6F2E70757368286E657720722E5461626C65287B726F77733A592C77696474683A7B73697A653A732C747970653A722E5769647468547970652E4458417D2C636F6C756D6E5769647468733A4B2C626F72646572733A687D';
wwv_flow_imp.g_varchar2_table(324) := '292C4F2829297D7D29293B76617220633D652E666F6F7465723B72657475726E7B70726F706572746965733A7B706167653A7B73697A653A7B77696474683A615B305D2C6865696768743A615B315D2C6F7269656E746174696F6E3A693F722E50616765';
wwv_flow_imp.g_varchar2_table(325) := '4F7269656E746174696F6E2E4C414E4453434150453A722E506167654F7269656E746174696F6E2E504F5254524149547D2C6D617267696E3A7B746F703A752C626F74746F6D3A752C6C6566743A752C72696768743A757D7D7D2C666F6F746572733A63';
wwv_flow_imp.g_varchar2_table(326) := '3F7B64656661756C743A6E657720722E466F6F746572287B6368696C6472656E3A4228632C742C6E297D297D3A766F696420302C6368696C6472656E3A6F2E6C656E6774683F6F3A5B52282222295D7D7D29292C443D6E657720722E446F63756D656E74';
wwv_flow_imp.g_varchar2_table(327) := '287B63726561746F723A226E6F76615265706F7274222C7469746C653A6D28652E7469746C657C7C22222C745B305D7C7C7B533A7B7D2C543A7B7D7D292C73656374696F6E733A6B7D293B72657475726E20722E5061636B65722E746F426C6F623F722E';
wwv_flow_imp.g_varchar2_table(328) := '5061636B65722E746F426C6F622844292E7468656E282866756E6374696F6E2865297B72657475726E20652E61727261794275666665723F652E617272617942756666657228293A657D29293A722E5061636B65722E746F4275666665722844297D2874';
wwv_flow_imp.g_varchar2_table(329) := '2C72293A22646F63782D74656D706C617465223D3D3D653F286F3D6E2E74656D706C61746555726C2C6F3F575B6F5D3F50726F6D6973652E7265736F6C766528575B6F5D293A6665746368286F2C7B63726564656E7469616C733A2273616D652D6F7269';
wwv_flow_imp.g_varchar2_table(330) := '67696E227D292E7468656E282866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20646573636172676172206C6120706C616E74696C6C612028222B652E7374617475732B222922';
wwv_flow_imp.g_varchar2_table(331) := '293B72657475726E20652E617272617942756666657228297D29292E7468656E282866756E6374696F6E2865297B72657475726E20575B6F5D3D652C657D29293A50726F6D6973652E72656A656374286E6577204572726F722827446566696E61206C61';
wwv_flow_imp.g_varchar2_table(332) := '2055524C206465206C6120706C616E74696C6C6120576F72642028617472696275746F2022506C616E74696C6C6120576F726422292E272929292E7468656E282866756E6374696F6E2865297B72657475726E204828652C725B305D297D29293A50726F';
wwv_flow_imp.g_varchar2_table(333) := '6D6973652E72656A656374286E6577204572726F722822466F726D61746F206E6F20736F706F727461646F3A20222B6529293B766172206F7D66756E6374696F6E20726528652C74297B76617220722C6E2C6F3D6F6528652E6C61796F7574292C613D7B';
wwv_flow_imp.g_varchar2_table(334) := '7D3B666F72287220696E206529615B725D3D655B725D3B72657475726E20612E6C61796F75743D6F2C286E3D6F2C50726F6D6973652E616C6C2866756E6374696F6E2865297B76617220743D5B5D3B66756E6374696F6E20722865297B28657C7C5B5D29';
wwv_flow_imp.g_varchar2_table(335) := '2E666F7245616368282866756E6374696F6E2865297B65262622696D6167656E223D3D3D652E747970652626652E75726C262621652E6669656C642626742E7075736828652E75726C297D29297D72657475726E207228652E73656374696F6E73292C65';
wwv_flow_imp.g_varchar2_table(336) := '2E62617463682626652E62617463682E73756D6D6172792626287228652E62617463682E73756D6D6172792E73656374696F6E73292C652E62617463682E73756D6D6172792E6C61796F757426267228652E62617463682E73756D6D6172792E6C61796F';
wwv_flow_imp.g_varchar2_table(337) := '75742E73656374696F6E7329292C747D286E292E6D6170282866756E6374696F6E2865297B76617220743D4F2865293B72657475726E20525B745D3F6E756C6C3A666574636828742C7B63726564656E7469616C733A2273616D652D6F726967696E227D';
wwv_flow_imp.g_varchar2_table(338) := '292E7468656E282866756E6374696F6E2865297B69662821652E6F6B297468726F77206E6577204572726F7228224E6F207365207075646F20636172676172206C6120696D6167656E20222B742B222028222B652E7374617475732B222922293B726574';
wwv_flow_imp.g_varchar2_table(339) := '75726E20652E617272617942756666657228297D29292E7468656E282866756E6374696F6E2865297B76617220723D6B2865293B525B745D3D7B6275663A652C773A722E772C683A722E682C6578743A722E6578742C646174613A22646174613A696D61';
wwv_flow_imp.g_varchar2_table(340) := '67652F222B28226A7067223D3D3D722E6578743F226A706567223A22706E6722292B223B6261736536342C222B442865297D7D29297D292929292E7468656E282866756E6374696F6E28297B72657475726E2066756E6374696F6E28652C74297B766172';
wwv_flow_imp.g_varchar2_table(341) := '20723D6F6528652E6C61796F7574292C6E3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C6F3D242874292C613D5A286F2C652E706172616D737C7C7B7D';
wwv_flow_imp.g_varchar2_table(342) := '292C693D652E6F75747075747C7C2266696C65223B69662821612E6C656E6774682972657475726E2050726F6D6973652E72656A656374286E6577204572726F7228652E656D7074794D6573736167657C7C722E656D7074794D6573736167657C7C224E';
wwv_flow_imp.g_varchar2_table(343) := '6F20686179206461746F7320706172612067656E6572617220656C207265706F7274652E2229293B696628722E62617463682626722E62617463682E6D6178446F63732626612E6C656E6774683E722E62617463682E6D6178446F63732972657475726E';
wwv_flow_imp.g_varchar2_table(344) := '2050726F6D6973652E72656A656374286E6577204572726F722822456C206C6F74652073757065726120656C206D5C753030653178696D6F20646520222B722E62617463682E6D6178446F63732B2220646F63756D656E746F732E2229293B6966282266';
wwv_flow_imp.g_varchar2_table(345) := '696C65223D3D3D692626313D3D3D612E6C656E6774682626313D3D3D6E2E6C656E6774687C7C226D65726765223D3D3D692626313D3D3D6E2E6C656E677468262622646F63782D74656D706C61746522213D3D6E5B305D297B766172206C3D6E5B305D3B';
wwv_flow_imp.g_varchar2_table(346) := '72657475726E207465286C2C722C612C65292E7468656E282866756E6374696F6E2874297B766172206E3D656528722C615B305D2C6C293B696628612E6C656E6774683E31297B76617220693D722E6261746368262628722E62617463682E6D65726765';
wwv_flow_imp.g_varchar2_table(347) := '4E616D657C7C722E62617463682E7A69704E616D65297C7C722E66696C654E616D657C7C227265706F727465223B6E3D6565287B66696C654E616D653A537472696E672869292E7265706C616365282F5C2E7A6970242F692C2222297D2C7B533A6F2E53';
wwv_flow_imp.g_varchar2_table(348) := '2C543A6F2E542C646F633A7B7D2C706172616D733A652E706172616D737C7C7B7D7D2C6C297D72657475726E7B6B696E643A6C2C646174613A742C6E616D653A6E2C636F756E743A612E6C656E6774687D7D29297D76617220752C733D6E65772077696E';
wwv_flow_imp.g_varchar2_table(349) := '646F772E4A535A69702C633D302C663D302C643D722E62617463682626722E62617463682E6368756E6B53697A657C7C352C683D7B7D3B666F72287520696E20652E706172616D737C7C7B7D29685B755D3D652E706172616D735B755D3B682E464F524D';
wwv_flow_imp.g_varchar2_table(350) := '41544F3D6E2E6C656E6774683E313F22746F646F73223A7B7064663A22706466222C786C73783A22657863656C222C646F63783A22776F7264222C22646F63782D74656D706C617465223A22776F7264227D5B6E5B305D5D3B76617220673D7B533A6F2E';
wwv_flow_imp.g_varchar2_table(351) := '532C543A6F2E542C646F633A7B7D2C706172616D733A687D2C763D7B7D3B66756E6374696F6E206228652C74297B666F722876617220723D652C6E3D323B765B722E746F4C6F7765724361736528295D3B29723D652E7265706C616365282F285C2E5B5E';
wwv_flow_imp.g_varchar2_table(352) := '2E5D2B29242F2C225F222B6E2B22243122292C6E2B2B3B765B722E746F4C6F7765724361736528295D3D21302C732E66696C6528722C74292C632B2B7D76617220773D50726F6D6973652E7265736F6C766528292C783D722E62617463682626722E6261';
wwv_flow_imp.g_varchar2_table(353) := '7463682E73756D6D6172793B782626227A6970223D3D3D69262628773D6E2E66696C746572282866756E6374696F6E2865297B72657475726E22646F63782D74656D706C61746522213D3D657D29292E726564756365282866756E6374696F6E28742C6E';
wwv_flow_imp.g_varchar2_table(354) := '297B72657475726E20742E7468656E282866756E6374696F6E28297B76617220743D782E6C61796F75747C7C7B706167653A722E706167652C666F6F7465723A782E666F6F7465727C7C722E666F6F7465722C73656374696F6E733A782E73656374696F';
wwv_flow_imp.g_varchar2_table(355) := '6E732C786C73783A782E786C73782C66696C654E616D653A782E66696C654E616D657D3B72657475726E20742E66696C654E616D657C7C28742E66696C654E616D653D782E66696C654E616D657C7C2230305F726573756D656E22292C7465286E2C742C';
wwv_flow_imp.g_varchar2_table(356) := '5B675D2C65292E7468656E282866756E6374696F6E2865297B6228656528742C672C6E292C65297D29297D29297D292C7729293B72657475726E20772E7468656E282866756E6374696F6E28297B72657475726E206E65772050726F6D69736528286675';
wwv_flow_imp.g_varchar2_table(357) := '6E6374696F6E28742C6F297B66756E6374696F6E206928297B666F7228766172206C3D4D6174682E6D696E28662B642C612E6C656E677468292C753D50726F6D6973652E7265736F6C766528293B663C6C3B662B2B292166756E6374696F6E2874297B6E';
wwv_flow_imp.g_varchar2_table(358) := '2E666F7245616368282866756E6374696F6E286E297B753D752E7468656E282866756E6374696F6E28297B72657475726E207465286E2C722C5B745D2C65292E7468656E282866756E6374696F6E2865297B6228656528722C742C6E292C65297D29297D';
wwv_flow_imp.g_varchar2_table(359) := '29297D29297D28615B665D293B752E7468656E282866756E6374696F6E28297B652E6F6E50726F67726573732626652E6F6E50726F677265737328662C612E6C656E677468292C663C612E6C656E6774683F73657454696D656F757428692C30293A2865';
wwv_flow_imp.g_varchar2_table(360) := '2E6F6E50726F67726573732626652E6F6E50726F6772657373282D312C63292C732E67656E65726174654173796E63287B747970653A652E7A6970547970657C7C22626C6F62222C636F6D7072657373696F6E3A224445464C415445222C636F6D707265';
wwv_flow_imp.g_varchar2_table(361) := '7373696F6E4F7074696F6E733A7B6C6576656C3A367D7D292E7468656E282866756E6374696F6E2865297B766172206E3D6D28722E62617463682626722E62617463682E7A69704E616D657C7C227265706F727465732E7A6970222C67293B74287B6B69';
wwv_flow_imp.g_varchar2_table(362) := '6E643A227A6970222C646174613A652C6E616D653A70282F5C2E7A6970242F692E74657374286E293F6E3A6E2B222E7A697022292C636F756E743A612E6C656E6774682C66696C65733A637D297D292C6F29297D292C6F297D73657454696D656F757428';
wwv_flow_imp.g_varchar2_table(363) := '692C30297D29297D29297D28612C74297D29297D66756E6374696F6E206E6528652C74297B69662822737472696E67223D3D747970656F66206526262240223D3D3D652E6368617241742830292626742626766F69642030213D3D745B652E7375627374';
wwv_flow_imp.g_varchar2_table(364) := '722831295D2972657475726E206E6528745B652E7375627374722831295D2C74293B69662841727261792E697341727261792865292972657475726E20652E726564756365282866756E6374696F6E28652C72297B766172206E3D22737472696E67223D';
wwv_flow_imp.g_varchar2_table(365) := '3D747970656F66207226262240223D3D3D722E636861724174283029262674262641727261792E6973417272617928745B722E7375627374722831295D292C6F3D6E6528722C74293B72657475726E206E3F652E636F6E636174286F293A652E636F6E63';
wwv_flow_imp.g_varchar2_table(366) := '6174285B6F5D297D292C5B5D293B696628652626226F626A656374223D3D747970656F662065297B76617220723D7B7D3B72657475726E204F626A6563742E6B6579732865292E666F7245616368282866756E6374696F6E286E297B725B6E5D3D226465';
wwv_flow_imp.g_varchar2_table(367) := '6673223D3D3D6E3F655B6E5D3A6E6528655B6E5D2C74297D29292C727D72657475726E20657D66756E6374696F6E206F652865297B76617220743B696628652626226F626A656374223D3D747970656F66206529743D653B656C73657B76617220723D53';
wwv_flow_imp.g_varchar2_table(368) := '7472696E6728657C7C2222292E7472696D28293B696628227B223D3D3D722E63686172417428302929743D4A534F4E2E70617273652872293B656C7365206966282128743D722E73706C697428222E22292E726564756365282866756E6374696F6E2865';
wwv_flow_imp.g_varchar2_table(369) := '2C74297B72657475726E20653F655B745D3A766F696420307D292C77696E646F772929297468726F77206E6577204572726F7228224E6F20736520656E636F6E74725C753030663320656C20646973655C75303066316F3A20222B72297D72657475726E';
wwv_flow_imp.g_varchar2_table(370) := '206E6528742C742E64656673297D66756E6374696F6E2061652865297B766172206E2C6F3D22616C6C223D3D3D652E666F726D61743F5B22706466222C22786C7378222C22646F6378225D3A5B652E666F726D61747C7C22706466225D2C613D313D3D3D';
wwv_flow_imp.g_varchar2_table(371) := '6F2E6C656E677468262622706466223D3D3D6F5B305D2626227A697022213D3D652E6F7574707574262622646F776E6C6F616422213D3D652E706466416374696F6E2C693D6126262131213D3D652E6C6F616465723F66756E6374696F6E2865297B7661';
wwv_flow_imp.g_varchar2_table(372) := '7220743D77696E646F772E6F70656E2822222C225F626C616E6B22293B69662821742972657475726E206E756C6C3B6966282266756E6374696F6E223D3D747970656F662077696E646F772E636F744C6F61646572297472797B77696E646F772E636F74';
wwv_flow_imp.g_varchar2_table(373) := '4C6F616465722874293B76617220723D742E646F63756D656E742E676574456C656D656E747342795461674E616D652822683122295B305D3B72262628722E74657874436F6E74656E743D2247656E6572616E646F207265706F72746522297D63617463';
wwv_flow_imp.g_varchar2_table(374) := '682865297B7D656C736520742E646F63756D656E742E777269746528273C21646F63747970652068746D6C3E3C68746D6C3E3C686561643E3C6D65746120636861727365743D227574662D38223E3C7469746C653E47656E6572616E646F207265706F72';
wwv_flow_imp.g_varchar2_table(375) := '74655C75323032363C2F7469746C653E3C7374796C653E626F64797B6D617267696E3A303B6865696768743A31303076683B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A6365';
wwv_flow_imp.g_varchar2_table(376) := '6E7465723B666F6E742D66616D696C793A73797374656D2D75692C73616E732D73657269663B6261636B67726F756E643A236634663666393B636F6C6F723A233166346537397D2E627B746578742D616C69676E3A63656E7465727D2E737B7769647468';
wwv_flow_imp.g_varchar2_table(377) := '3A353670783B6865696768743A353670783B626F726465723A35707820736F6C696420236436653065613B626F726465722D746F702D636F6C6F723A233166346537393B626F726465722D7261646975733A3530253B616E696D6174696F6E3A72203173';
wwv_flow_imp.g_varchar2_table(378) := '206C696E65617220696E66696E6974653B6D617267696E3A30206175746F20313870787D406B65796672616D657320727B746F7B7472616E73666F726D3A726F7461746528333630646567297D7D68317B666F6E742D73697A653A323070783B6D617267';
wwv_flow_imp.g_varchar2_table(379) := '696E3A302030203670787D707B6D617267696E3A303B636F6C6F723A233562366237627D3C2F7374796C653E3C2F686561643E3C626F64793E3C64697620636C6173733D2262223E3C64697620636C6173733D2273223E3C2F6469763E3C68313E47656E';
wwv_flow_imp.g_varchar2_table(380) := '6572616E646F207265706F7274653C2F68313E3C702069643D226D7367223E3C2F703E3C2F6469763E3C2F626F64793E3C2F68746D6C3E27292C742E646F63756D656E742E636C6F736528293B72657475726E204B28742C65292C747D28652E6D657373';
wwv_flow_imp.g_varchar2_table(381) := '6167657C7C22436F6E73756C74616E646F206461746F735C753230323622293A6E756C6C2C6C3D77696E646F772E617065782626617065782E7574696C3F617065782E7574696C2E73686F775370696E6E657228293A6E756C6C3B7472797B6E3D6F6528';
wwv_flow_imp.g_varchar2_table(382) := '652E6C61796F7574297D63617463682865297B72657475726E206C26266C2E72656D6F766528292C692626692E636C6F736528292C562822446973655C75303066316F20696E765C75303065316C69646F3A20222B652E6D657373616765292C50726F6D';
wwv_flow_imp.g_varchar2_table(383) := '6973652E72656A6563742865297D76617220753D7B6C61796F75743A6E2C666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075742C706172616D733A652E706172616D737C7C7B7D2C74656D706C61746555726C3A652E74656D70';
wwv_flow_imp.g_varchar2_table(384) := '6C61746555726C2C686F6F6B733A652E686F6F6B737C7C7B7D7D3B5828227374617274222C7B666F726D61743A652E666F726D61742C6F75747075743A652E6F75747075747D293B76617220733D722866756E6374696F6E28652C72297B766172206E3D';
wwv_flow_imp.g_varchar2_table(385) := '5B5D3B72657475726E20652E666F7245616368282866756E6374696F6E2865297B28745B655D7C7C5B5D292E666F7245616368282866756E6374696F6E2865297B6E2E696E6465784F662865293C3026266E2E707573682865297D29297D29292C722626';
wwv_flow_imp.g_varchar2_table(386) := '6E2E7075736828226A737A697022292C6E7D286F2C226D6572676522213D3D652E6F757470757429292C633D652E646174613F50726F6D6973652E7265736F6C766528652E64617461293A6E65772050726F6D697365282866756E6374696F6E28742C72';
wwv_flow_imp.g_varchar2_table(387) := '297B617065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C7B7830313A4A534F4E2E737472696E6769667928752E706172616D73292C7830323A227A6970223D3D3D652E6F75747075743F2259223A224E222C706167';
wwv_flow_imp.g_varchar2_table(388) := '654974656D733A652E6974656D737C7C766F696420307D2C7B64617461547970653A226A736F6E227D292E7468656E282866756E6374696F6E2865297B652626652E6F6B3F7428652E64617461293A72286E6577204572726F7228652626652E6D73677C';
wwv_flow_imp.g_varchar2_table(389) := '7C224572726F7220616C206F6274656E6572206C6F73206461746F732E2229297D292C2866756E6374696F6E28652C742C6E297B72286E6577204572726F7228224572726F7220646520636F6D756E69636163695C75303066336E3A20222B286E7C7C74';
wwv_flow_imp.g_varchar2_table(390) := '2929297D29297D29293B72657475726E2050726F6D6973652E616C6C285B632C735D292E7468656E282866756E6374696F6E2874297B6C2626286C2E72656D6F766528292C6C3D6E756C6C293B76617220723D652E7472616E73666F726D2626652E7472';
wwv_flow_imp.g_varchar2_table(391) := '616E73666F726D28745B305D297C7C745B305D3B72657475726E204B28692C2241726D616E646F20656C20646F63756D656E746F5C753230323622292C752E6F6E50726F67726573733D66756E6374696F6E28652C74297B2D313D3D3D653F4A2822436F';
wwv_flow_imp.g_varchar2_table(392) := '6D7072696D69656E646F20222B742B22206172636869766F735C753230323622293A284A282247656E6572616E646F20222B652B2220646520222B742B225C753230323622292C58282270726F6772657373222C7B646F6E653A652C746F74616C3A747D';
wwv_flow_imp.g_varchar2_table(393) := '29297D2C726528752C72297D29292E7468656E282866756E6374696F6E2865297B6966284A28292C22706466223D3D3D652E6B696E64262661297B76617220743D55524C2E6372656174654F626A65637455524C286E657720426C6F62285B652E646174';
wwv_flow_imp.g_varchar2_table(394) := '615D2C7B747970653A712E7064667D29293B69262621692E636C6F7365643F692E6C6F636174696F6E2E687265663D743A77696E646F772E6F70656E28742C225F626C616E6B22297D656C736520692626692E636C6F736528292C6E3D652E646174612C';
wwv_flow_imp.g_varchar2_table(395) := '6F3D652E6E616D652C6C3D227A6970223D3D3D652E6B696E643F226170706C69636174696F6E2F7A6970223A715B652E6B696E645D7C7C712E646F63782C753D6E20696E7374616E63656F6620426C6F623F6E3A6E657720426C6F62285B6E5D2C7B7479';
wwv_flow_imp.g_varchar2_table(396) := '70653A6C7C7C226170706C69636174696F6E2F6F637465742D73747265616D227D292C28733D646F63756D656E742E637265617465456C656D656E742822612229292E687265663D55524C2E6372656174654F626A65637455524C2875292C732E646F77';
wwv_flow_imp.g_varchar2_table(397) := '6E6C6F61643D6F2C646F63756D656E742E626F64792E617070656E644368696C642873292C732E636C69636B28292C73657454696D656F7574282866756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C28732E68726566292C732E';
wwv_flow_imp.g_varchar2_table(398) := '72656D6F766528297D292C346533292C227A6970223D3D3D652E6B696E64262628723D225A49502067656E657261646F3A20222B652E66696C65732B22206172636869766F7320646520222B652E636F756E742B2220646F63756D656E746F732E222C77';
wwv_flow_imp.g_varchar2_table(399) := '696E646F772E617065782626617065782E6D6573736167652626617065782E6D6573736167652E73686F775061676553756363657373287229293B76617220722C6E2C6F2C6C2C752C733B72657475726E20582822656E64222C7B6E616D653A652E6E61';
wwv_flow_imp.g_varchar2_table(400) := '6D652C636F756E743A652E636F756E742C66696C65733A652E66696C65737D292C657D29292E6361746368282866756E6374696F6E2865297B7468726F77206C26266C2E72656D6F766528292C4A28292C69262621692E636C6F7365642626692E636C6F';
wwv_flow_imp.g_varchar2_table(401) := '736528292C77696E646F772E636F6E736F6C652626636F6E736F6C652E6572726F722865292C5828226572726F72222C7B6D6573736167653A652E6D6573736167657D292C5628652E6D6573736167657C7C224E6F207365207075646F2067656E657261';
wwv_flow_imp.g_varchar2_table(402) := '7220656C207265706F7274652E22292C657D29297D7661722069653D21312C6C653D6E756C6C3B72657475726E22756E646566696E656422213D747970656F6620646F63756D656E742626646F63756D656E742E6164644576656E744C697374656E6572';
wwv_flow_imp.g_varchar2_table(403) := '2626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C2866756E6374696F6E2865297B6C653D652E7461726765742626652E7461726765742E636C6F736573742626652E7461726765742E636C6F736573742822612C';
wwv_flow_imp.g_varchar2_table(404) := '627574746F6E2C5B646174612D6F75747075745D2C5B646174612D666F726D61745D22297C7C652E7461726765747D292C2130292C7B76657273696F6E3A22312E362E31222C6C6962733A652C72756E3A61652C64613A66756E6374696F6E2865297B76';
wwv_flow_imp.g_varchar2_table(405) := '617220743D746869732626746869732E616374696F6E3F746869733A7B7D2C723D742E616374696F6E7C7C7B7D2C6E3D742E74726967676572696E67456C656D656E747C7C6C652C6F3D742E62726F777365724576656E743B6966286F26266F2E707265';
wwv_flow_imp.g_varchar2_table(406) := '76656E7444656661756C7426266F2E70726576656E7444656661756C7428292C216965297B76617220613D652626226F626A656374223D3D747970656F6620653F653A7B7D2C693D2266756E6374696F6E223D3D747970656F6620653F653A612E696E69';
wwv_flow_imp.g_varchar2_table(407) := '742C6C3D7B7D2C753D6E26266E2E646174617365747C7C7B7D2C733D612E6F75747075747C7C722E61747472696275746530337C7C2266696C65222C633D612E666F726D61747C7C722E61747472696275746530327C7C22706466223B4F626A6563742E';
wwv_flow_imp.g_varchar2_table(408) := '6B6579732875292E666F7245616368282866756E6374696F6E2865297B226F757470757422213D3D653F22666F726D617422213D3D653F6C5B652E7265706C616365282F285B412D5A5D292F672C225F243122292E746F55707065724361736528295D3D';
wwv_flow_imp.g_varchar2_table(409) := '755B655D3A633D755B655D3A733D755B655D7D29293B76617220663D7B6C61796F75743A612E6C61796F75747C7C722E61747472696275746530312C666F726D61743A632C6F75747075743A732C6974656D733A612E6974656D737C7C722E6174747269';
wwv_flow_imp.g_varchar2_table(410) := '6275746530347C7C22222C706466416374696F6E3A612E706466416374696F6E7C7C722E61747472696275746530357C7C226F70656E222C74656D706C61746555726C3A612E74656D706C61746555726C7C7C722E61747472696275746530362C6D6573';
wwv_flow_imp.g_varchar2_table(411) := '736167653A612E6D6573736167657C7C722E61747472696275746530372C706172616D733A6C2C616A61784964656E7469666965723A612E616A61784964656E7469666965727C7C722E616A61784964656E7469666965727D3B2266756E6374696F6E22';
wwv_flow_imp.g_varchar2_table(412) := '3D3D747970656F662069262628663D692866297C7C66292C69653D21302C61652866292E7468656E282866756E6374696F6E28297B69653D21317D292C2866756E6374696F6E28297B69653D21317D29297D7D2C6275696C643A72652C656E737572653A';
wwv_flow_imp.g_varchar2_table(413) := '722C5F696E7465726E616C733A7B494D473A522C696D6744696D733A6B2C74706C3A6D2C636F6E643A762C666D743A642C6E6F726D616C697A653A242C636F6E74657874733A5A7D7D7D28293B';
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
