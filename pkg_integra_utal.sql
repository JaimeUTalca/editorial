create or replace PACKAGE BODY           pkg_integra_utal
IS
   g_charset            VARCHAR2 (15) := 'ISO-8859-1';
   G_clave              VARCHAR2 (10) := 'SAPUTALCA';

   -- g_sistema_sapqa varchar2(100):='http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000';
   g_sistema_sapqa      VARCHAR2 (100) := 'http://sappoqa.utalca.cl:52000';
   g_clave_sap_pipo     VARCHAR2 (100) := 'c2FwcGl1dGFsY2E6cGl1dGFsY2EyMDE2'; --user:password base64 coded
   g_sistema_sapqa19c   VARCHAR2 (100) := 'http://sappoqa.utalca.cl:52000';
   g_sistema_sapdv      VARCHAR2 (100)
      := 'http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000';

--DBA
   --g_sistema_sapprod    VARCHAR2 (100)
    --  := 'http://sappoprod.utalca.cl:53000';
--DBA      := 'http://sappiutalca:piutalca2016@sappoprod.utalca.cl:53000';

   g_sistema_sap varchar2(100):=g_sistema_sapqa19c;
--   g_sistema_sap        VARCHAR2 (100) := g_sistema_sapqa;

   -- desarrollo v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/FISD01/INT_SAP02', v_json);
   -- qa v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000/RESTAdapter/FISD01/INT_SAP02', v_json);

   /* 09/01/2025 Se crea procedimiento para que utilice integración FICA009/CREA_BECA_POSTGRADO, anteriormente se utilizaba CREA_DESC_POSTGRADO (int_crea_descuento_pregrado) */
   FUNCTION int_crea_descuento_preg (p_rut_deudor        IN     VARCHAR2,
                                     p_monto_descuento   IN     VARCHAR2,
                                     p_codigo_carrera    IN     VARCHAR2,
                                     p_nro_matricula     IN     VARCHAR2,
                                     p_ret                  OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                     p_msg                  OUT VARCHAR2 --mensaje de error
                                                                        )
      RETURN json
   IS
      v_token               VARCHAR2 (500);
      v_line_deuda          VARCHAR2 (32766);
      l_data_json           json;
      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      pl_centro_gestor      operacion_sub_operacion_sap.centro_gestor_base%TYPE;
      pl_observacion        VARCHAR2 (4000);
      v_respuesta           CLOB;
      id_log                NUMBER;
      l_resp_json           json;
      l_return_json         json;
      l_data_json_l         json_list;
      carrera               NUMBER;
      v_fecha_inicio        VARCHAR2 (8);
      v_fecha_fin           VARCHAR2 (8);
   BEGIN
      p_ret := 'S';
      v_fecha_inicio := '20260331';
         /*TO_CHAR (
            TO_DATE ('31-MAR-' || EXTRACT (YEAR FROM SYSDATE), 'DD-MON-YYYY'),
            'YYYYMMDD');*/
      v_fecha_fin :='20261231';
         /*TO_CHAR (
            TO_DATE ('31-DIC-' || EXTRACT (YEAR FROM SYSDATE), 'DD-MON-YYYY'),
            'YYYYMMDD');*/

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         v_line_deuda := '{
              "Token": "'  || v_token || '",
               "data":{
                       "Matricula": "",
                       "Fecha_Inicio": "' || v_fecha_inicio || '",
                       "Fecha_Fin": "' || v_fecha_fin || '",
                       "Rut_Alumno": "' || p_rut_deudor || '",
                       "Clase_Doc": "DA",
                       "Fecha_Doc": "",
                       "Num_Cupon": "",
                       "Num_Doc": "",
                       "Cuota": "0000",
                       "Fecha_Vence": "",
                       "Importe": "' || p_monto_descuento || '-",
                       "Sociedad": "UT01",
                       "Carrera": "' || p_codigo_carrera || '",
                       "Moneda": "CLP",
                       "Num_Matricula": "' || p_nro_matricula || '",
                       "Centro_Beneficio": "",
                       "Operacion_Principal": "",
                       "Operacion_Parcial": "",
                       "Texto": "DA-DESCUENTO ARANCEL",
                       "Elemento_PEP": ""
                      }
                    }';

         BEGIN
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                         'Crea deuda POST:',
                         p_rut_deudor,
                         v_line_deuda,
                         SYSDATE);

            COMMIT;
            v_respuesta :=
               call_url_p_1 (
                  g_sistema_sap || '/RESTAdapter/FICA009/CREA_BECA',
                  v_line_deuda);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                  p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'R',
                            'INTLEG05(CREA DSCTO FICA PREGRADO)',
                            'Crea deuda POST:',
                            p_rut_deudor,
                            p_msg,
                            SYSDATE);
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               BEGIN
                  l_resp_json := JSON (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := JSON (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (JSON (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (JSON (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (JSON (l_data_json_l.get (2)), 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := JSON (v_respuesta);
                        l_data_json := JSON (l_resp_json.get ('Resp'));
                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg := v_respuesta;
                           l_data_json := NULL;
                     END;
               END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta 1 : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'R',
                      'INTLEG05(CREA DSCTO FICA PREGRADO)',
                      'Crea DSCTO PRE:',
                      p_rut_deudor,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg := p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'CREA DSCTO FICA PREGRADO',
                      'Crea DSCTO PRE:',
                      p_rut_deudor,
                      p_msg,
                      SYSDATE);
   END int_crea_descuento_preg;

   PROCEDURE json_libros (p_prod_codigo NUMBER DEFAULT NULL)
   IS
      l_json_clob       CLOB;
      l_json            json;
      l_employee_json   json;
      l_jobs_json       json_list;
      v_sql             VARCHAR2 (2000);
      v_autores         VARCHAR2 (2000);
      v_coleccion       VARCHAR2 (2000);
   BEGIN
      OWA_UTIL.mime_header ('application/json', FALSE, g_charset);
      OWA_UTIL.http_header_close;
      v_autores :=
         '(SELECT wm_concat(auto_nombre) FROM  pove_libros_autores, pove_autor where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo) as autores ';
      v_coleccion :=
         '(SELECT wm_concat(d.cate_descripcion)  FROM pove_categoria_producto c,pove_categorias d  where  c.tipo_codigo=d.tipo_codigo and c.cate_codigo=d.cate_codigo and c.prod_codigo=a.prod_codigo group by c.prod_codigo) as coleccion ';

      v_sql :=
            'select a.prod_codigo,a.prod_nombre,a.prod_descripcion,a.prod_precio,a.prod_imagen,a.prod_estado,b.libr_isbn,b.libr_agno,b.libr_num_paginas,'
         || v_autores
         || ','
         || v_coleccion
         || ' from pove_producto a left join pove_libros b on a.prod_codigo=b.prod_codigo where a.prod_codigo='''
         || p_prod_codigo
         || '''';


      l_jobs_json := json_list ();
      l_jobs_json := json_dyn.executeList (v_sql);

      l_json := json ();
      l_json.put ('data', l_jobs_json.to_json_value);
      l_json.HTP ();
   END;

   PROCEDURE get_json_std_1_resp
   /*armar consultas complejas*/
   IS
      l_json_clob       CLOB;
      l_json            json;
      l_employee_json   json;
      l_jobs_json       json_list;

      CURSOR c1
      IS
         SELECT a.prod_codigo,
                a.prod_nombre,
                a.prod_descripcion,
                a.prod_precio,
                a.prod_imagen,
                a.prod_estado,
                (SELECT wm_concat (auto_nombre)
                   FROM vec_cob03.pove_libros_autores, vec_cob03.pove_autor
                  WHERE     pove_libros_autores.auto_codigo =
                               pove_autor.auto_codigo
                        AND prod_codigo = a.prod_codigo)
                   AS autores
           FROM vec_cob03.pove_producto a
          WHERE a.prod_precio IS NOT NULL;

      fila              c1%ROWTYPE;
   BEGIN
      OWA_UTIL.mime_header ('application/json', FALSE, g_charset);
      OWA_UTIL.http_header_close;


      l_jobs_json := json_list ();
      l_employee_json := json ();

      FOR fila IN c1
      LOOP
         l_json := json ();
         l_json.put ('prod_codigo', fila.prod_codigo);
         l_json.put ('prod_nombre', fila.prod_nombre);
         l_json.put ('prod_descripcion', fila.prod_descripcion);
         l_json.put ('prod_precio', fila.prod_precio);
         l_json.put ('prod_imagen', fila.prod_imagen);
         l_json.put ('prod_estado', fila.prod_estado);
         l_json.put ('autores', fila.autores);

         l_jobs_json.append (l_json.to_json_value);
      END LOOP;


      l_employee_json.put ('data', l_jobs_json.to_json_value);

      l_employee_json.HTP ();
   --htp.p(l_jobs_json.count());

   END;

   PROCEDURE inst_sap10 (v_cli_rut VARCHAR2, v_canal_distribucion VARCHAR2)
   IS
   BEGIN
      ENCABEZADO ();

      HTP.p (
            '
<script>

$(document).ready(function(){

function consulta_cliente (){

        var var1 = ''{ '' +
        ''  "Token": "F70713F194043E7267F88C9C7589944A0F5355CB9737906866778BA2F80E6493",'' +
        ''    "data":{'' +
        ''          "cli_rut": "'
         || v_cli_rut
         || '", '' +
        ''             "canal_distribucion": "'
         || v_canal_distribucion
         || '" '' +
        ''           } '' +
        ''}'';

        var1.replace("\n"," ");


          $.ajax({
                     url:''http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/SD005/INT_SAP10'',
                     type:''GET'',
                     data:var1,
                     dataType: "json",


                     success:function(response){

                             alert("paso");
                                                     },
                     error: function(xhr, status, error) {
                                     alert("algo salio bastante mal : " + xhr.responseText)
                                         }

             });



            }

         consulta_cliente ();
})


</script>
'         );
   END;

   FUNCTION int_leg05_json_cyp_fica (p_codigo_cli         IN     VARCHAR2,
                                     p_tipo_documento     IN     VARCHAR2,
                                     p_fecha_documento    IN     VARCHAR2,
                                     p_num_cuponera       IN     VARCHAR2,
                                     p_importe            IN     VARCHAR2,
                                     p_carrera            IN     VARCHAR2,
                                     p_num_matricula      IN     VARCHAR2,
                                     p_fecha_venc         IN     VARCHAR2,
                                     p_cuota              IN     VARCHAR2,
                                     p_centro_beneficio   IN     VARCHAR2,
                                     p_operacion          IN     VARCHAR2,
                                     p_sub_operacion      IN     VARCHAR2,
                                     p_descripcion        IN     VARCHAR2,
                                     p_paga               IN     VARCHAR2,
                                     p_ret                   OUT VARCHAR2,
                                     --Salida estado si tiene error en oracle S (Success) E (Error)
                                     p_msg                   OUT VARCHAR2 --mensaje de error
                                                                         )
      RETURN json
   IS
      v_json          VARCHAR2 (3200);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);
      l_resp_json     json;
      l_data_json     json_list;
      l_return_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      /*
      select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;
      */
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         -- agregar campo legado para saber si es  0001 natural 0003 empresa
         -- separar en el legado de ventas nombres y apellidos y en otros cortar de 40 caracteres  hasta completar 2 80 caracteres
         -- nombre3 el código giro
         -- busqueda2 rubro
         -- mauro enviara tabla con canal y clase ic y con legado correspondiente
         --Cli_clasificacion_fiscal si pide factura 1 y si no 0
         v_json :=
               '{
                    "TOKEN": "'
            || v_token
            || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {
                            "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
            || p_codigo_cli
            || '",
                               "Tipo_documento": "'
            || p_tipo_documento
            || '",
                               "Fecha_documento": "'
            || p_fecha_documento
            || '",
                               "Nro_Cuponera": "'
            || p_num_cuponera
            || '",
                               "Documento": "",
                               "Cuota": "'
            || p_cuota
            || '",
                               "Fecha_vencimiento": "'
            || p_fecha_venc
            || '",
                               "Importe": "'
            || p_importe
            || '",
                               "Empresa": "UT01",
                               "Carrera": "'
            || p_carrera
            || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
            || p_num_matricula
            || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
            || p_operacion
            || '",
                               "Sub_operacion": "'
            || p_sub_operacion
            || '",
                               "Descripcion": "'
            || p_descripcion
            || '",
                               "Elemento_PEP": "",
                               "Pagar": "'
            || p_paga
            || '"
                            }
                    }
                }
                ';

         --htp.p(v_json);

         /*Fin Json de entrada */
         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

                    falta que nos envien la url para la interfaz int_leg02
            */
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;
      END IF;

      HTP.p (v_respuesta || '<BR><BR><BR>' || v_json);    -- imprime respuesta

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_return_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         -- l_RETURN_json := json(l_resp_json.get('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* if p_ret = 'S' then
           --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

           if lee_json(l_RETURN_json,'TYPE') <> 'S' then
               p_ret := substr(lee_json(l_RETURN_json,'TYPE'),1,1) ;
               --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
           end if;
       end if;


       begin
           l_RETURN_json := json(l_resp_json.get('data'));
       exception when others then
           p_ret := 'S';
           p_msg := p_msg||' Error en el formato de la respuesta data*: '||sqlerrm;
           l_data_json := null;
       end ;*/

      /*retorna json*/
      RETURN l_return_json;
   END int_leg05_json_cyp_fica;

   FUNCTION int_leg05_fica_matricula_sap (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2,
      --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg         OUT VARCHAR2,
      p_conv            VARCHAR2 DEFAULT NULL               --mensaje de error
                                             )
      RETURN json
   IS
      v_line                VARCHAR2 (32766);
      v_paga                VARCHAR2 (1);
      v_json                CLOB := EMPTY_CLOB ();
      --
      p_idcliente_v         VARCHAR2 (10) := p_idcliente;
      v_respuesta           CLOB;
      v_token               VARCHAR2 (500);
      l_resp_json           json;
      l_data_json           json;
      l_return_json         json;
      l_data_json_l         json_list;
      nombre_dcto           VARCHAR2 (5000);
      V_FECHA_DOCUMENTO     DATE;
      v_convenio            VARCHAR2 (3);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_matri a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
           SELECT *
             FROM vec_cob01.pop_pagos_detalle_temp_matri a
            --18-01-2024 11:52          WHERE pa_rut = p_idcliente
            --          WHERE pa_rut = to_char(p_idcliente)
            WHERE     pa_rut = p_idcliente_v
                  AND pade_tipo_documento = p_tipo_doc
                  AND pa_nro_operacion = p_num_op
         ORDER BY pade_fec_vencimiento ASC;

      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      id_log                NUMBER;
      v_contador            NUMBER := 0;

      l_tiempo_inicio       DATE := SYSDATE;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      IF p_conv = 'X'
      THEN
         v_convenio := 'Z8';
      ELSE
         v_convenio := get_clase_documento_sap(p_idcliente,p_num_op);
      END IF;

      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            BEGIN
               SELECT rec_nombre_sap
                 INTO nombre_dcto
                 FROM utsap001.conf_recursos
                WHERE     rec_categoria = 2
                      AND rec_subcategoria = 2
                      AND rec_codigo_sap = reg_grupo.pade_tipo_documento;

               SELECT operacion_op, sub_operacion_op
                 INTO pl_operacion_op, pl_sub_operacion_op
                 FROM operacion_sub_operacion_sap
                WHERE clase_documento_sap = reg_grupo.pade_tipo_documento;

               v_json := '';
               v_contador := 0;
               v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  IF (reg.pade_paga = 'S')
                  THEN
                     v_paga := 'X';
                  ELSE
                     v_paga := '';
                  END IF;

                  IF v_contador = 0
                  THEN
                     IF SYSDATE >
                           TO_DATE (reg.pade_fec_vencimiento, 'YYYYMMDD')
                     THEN
                        V_FECHA_DOCUMENTO :=
                           TO_DATE (reg.pade_fec_vencimiento, 'YYYYMMDD');
                     ELSE
                        V_FECHA_DOCUMENTO := SYSDATE;
                     END IF;
                  END IF;

                  v_contador := v_contador + 1;
                  v_line :=
                        v_line
                     || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                     || reg.pa_rut
                     || '",
                               "Tipo_documento": "'
                     || reg.pade_tipo_documento
                     || '",
                              "Fecha_documento": "'
                     || TO_CHAR (V_FECHA_DOCUMENTO, 'YYYYMMDD')
                     || '",
                               "Nro_Cuponera": "'
                     || reg.pa_nro_operacion
                     || '",
                               "Documento": "",
                               "Cuota": "'
                     || v_contador
                     || '",
                               "Fecha_vencimiento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Importe": "'
                     || reg.pade_monto_local
                     || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                     || reg.pade_nro_carrera
                     || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                     || reg.pade_matricula
                     || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                     || pl_operacion_op
                     || '",
                               "Sub_operacion": "'
                     || pl_sub_operacion_op
                     || '",
                               "Descripcion": "'
                     || reg.pade_tipo_documento
                     || '-'
                     || nombre_dcto
                     || '-'
                     || 'CUOTA '
                     || v_contador
                     || '",
                               "Elemento_PEP": "",
                               "Pagar": "'
                     || v_paga
                     || '",
                                 "Tipo_Documento_Pago": "'||v_convenio||'"
                            },';
               END LOOP;

               v_json := v_json || v_line;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            /*Fin Json de entrada */
            BEGIN
               /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
               /*  sappodev:desarrollo  puerto 51000
                   sappoqa:testing      puerto 52000
                       falta que nos envien la url para la interfaz int_leg02
               */
               --LGC 18-01-2024 12:34
               --            insert into utsap001.log_traza (CORRELATIVO ,DESCRIPCION, F_SISTEMA, F_INICIO)
               --            values (p_idcliente, '1.- Previo llamada a : /RESTAdapter/SD001/INT_LEG05', sysdate, l_tiempo_inicio);

               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            --            insert into utsap001.log_traza (CORRELATIVO ,DESCRIPCION, F_SISTEMA, F_INICIO)
            --            values (p_idcliente, '2.- Post llamada a : /RESTAdapter/SD001/INT_LEG05', sysdate, l_tiempo_inicio);


            /*Fin llamada a servicio SAP*/
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;

            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');

                  IF p_ret = 'S'
                  THEN
                     UPDATE vec_cob01.jf_regulariza_2018_tmp
                        SET procesado = 'S', FECHA_PROCESO_SAP = SYSDATE
                      WHERE     ALU_RUT_N = p_idcliente
                            AND NRO_CUPON_WEBPAY = p_num_op;

                     COMMIT;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('Resp'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');

                        IF p_ret = 'S'
                        THEN
                           UPDATE vec_cob01.jf_regulariza_2018_tmp
                              SET procesado = 'S',
                                  FECHA_PROCESO_SAP = SYSDATE
                            WHERE     ALU_RUT_N = p_idcliente
                                  AND NRO_CUPON_WEBPAY = p_num_op;

                           COMMIT;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg := v_respuesta;
                           l_data_json := NULL;
                     END;
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg :=
                  'Error en el formato de la respuesta 2 : ' || v_respuesta;
            END IF;

            INSERT INTO log_portal_pagos_sap (ID,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                    VALUES (
                              id_log,
                              'S',
                              'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_matricula_sap',
                              p_num_op,
                              p_num_op,
                              'Crea y paga deuda:',
                              p_idcliente,
                              SUBSTR (v_json, 1, 4000),
                              SYSDATE);

            BEGIN
               INSERT INTO log_portal_pagos_sap (ID,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 dato2,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                       VALUES (
                                 id_log,
                                 'S',
                                 'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_matricula_sap',
                                 p_num_op,
                                 p_num_op,
                                 'Crea y paga deuda:',
                                 p_idcliente,
                                 v_respuesta,
                                 SYSDATE);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  INSERT INTO log_portal_pagos_sap (ID,
                                                    tipo_llamada,
                                                    integracion,
                                                    pade_nro_documento,
                                                    dato2,
                                                    tipo_integracion,
                                                    dato1,
                                                    msg_sap,
                                                    fecha_msg)
                          VALUES (
                                    id_log,
                                    'E',
                                    'INTLEG05(CREA Y PAGA DEUDA  FICA): ERROR MAYOR DE 4000 (int_leg05_fica_matricula_sap)',
                                    p_num_op,
                                    p_num_op,
                                    'Crea y paga deuda:',
                                    p_idcliente,
                                    SUBSTR (v_respuesta, 1, 4000),
                                    SYSDATE);
            END;
         END LOOP;
      END IF;

      RETURN l_data_json;
   END int_leg05_fica_matricula_sap;

   FUNCTION int_leg05_fica_crea_mat_sap (p_idcliente       VARCHAR2,
                                         p_num_op          VARCHAR2,
                                         p_ret         OUT VARCHAR2,
                                         --Salida estado si tiene error en oracle S (Success) E (Error)
                                         p_msg         OUT VARCHAR2 --mensaje de error
                                                                   )
      RETURN json
   IS
      v_line                VARCHAR2 (32766);
      v_paga                VARCHAR2 (1);
      v_json                CLOB := EMPTY_CLOB ();
      --
      v_respuesta           CLOB;
      v_token               VARCHAR2 (500);
      l_resp_json           json;
      l_data_json           json;
      l_return_json         json;
      l_data_json_l         json_list;
      nombre_dcto           VARCHAR2 (5000);
      V_FECHA_DOCUMENTO     DATE;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_matri a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
           SELECT *
             FROM vec_cob01.pop_pagos_detalle_temp_matri a
            WHERE     pa_rut = p_idcliente
                  AND pade_tipo_documento = p_tipo_doc
                  AND pa_nro_operacion = p_num_op
         ORDER BY pade_fec_vencimiento ASC;

      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      id_log                NUMBER;
      v_contador            NUMBER := 0;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            BEGIN
               SELECT rec_nombre_sap
                 INTO nombre_dcto
                 FROM utsap001.conf_recursos
                WHERE     rec_categoria = 2
                      AND rec_subcategoria = 2
                      AND rec_codigo_sap = reg_grupo.pade_tipo_documento;

               SELECT operacion_op, sub_operacion_op
                 INTO pl_operacion_op, pl_sub_operacion_op
                 FROM operacion_sub_operacion_sap
                WHERE clase_documento_sap = reg_grupo.pade_tipo_documento;

               v_json := '';
               v_contador := 0;
               v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  IF (reg.pade_paga = 'S')
                  THEN
                     v_paga := 'X';
                  ELSE
                     v_paga := '';
                  END IF;

                  IF v_contador = 0
                  THEN
                     /* rpalaciosa  26-01-2021 . se regulariza para pagos de matriculas
                                                 por que la fecha debe ajustarse a la menor fecha
                     */
                     IF SYSDATE >
                           TO_DATE (reg.pade_fec_vencimiento, 'YYYYMMDD')
                     THEN
                        V_FECHA_DOCUMENTO :=
                           TO_DATE (reg.pade_fec_vencimiento, 'YYYYMMDD');
                     ELSE
                        V_FECHA_DOCUMENTO := SYSDATE;
                     END IF;
                  END IF;

                  v_contador := v_contador + 1;
                  v_line :=
                        v_line
                     || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                     || reg.pa_rut
                     || '",
                               "Tipo_documento": "'
                     || reg.pade_tipo_documento
                     || '",
                               "Fecha_documento": "'
                     || TO_CHAR (V_FECHA_DOCUMENTO, 'YYYYMMDD')
                     || '",
                               "Nro_Cuponera": "'
                     || reg.pa_nro_operacion
                     || '",
                               "Documento": "",
                               "Cuota": "'
                     || reg.pade_cuota
                     || '",
                               "Fecha_vencimiento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Importe": "'
                     || reg.pade_monto_local
                     || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                     || reg.pade_nro_carrera
                     || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                     || reg.pade_matricula
                     || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                     || pl_operacion_op
                     || '",
                               "Sub_operacion": "'
                     || pl_sub_operacion_op
                     || '",
                               "Descripcion": "'
                     || reg.pade_tipo_documento
                     || '-'
                     || nombre_dcto
                     || '-'
                     || 'CUOTA '
                     || reg.pade_cuota                  --reg.pade_observacion
                     || '",
                               "Elemento_PEP": "",
                               "Pagar": ""
                            },';
               END LOOP;

               v_json := v_json || v_line;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            /*Fin Json de entrada */
            BEGIN
               /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
               /*  sappodev:desarrollo  puerto 51000
                   sappoqa:testing      puerto 52000
                       falta que nos envien la url para la interfaz int_leg02
               */
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            -- HTP.P(v_respuesta);


            /*Fin llamada a servicio SAP*/
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;

            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');

                  UPDATE vec_cob01.cc_pagos_banco_sap_matri
                     SET CODIGO_MSG_SAP = p_ret,
                         MSG_SAP = p_msg,
                         FECHA_PROCESO_SAP = SYSDATE,
                         ESTADO_SAP = p_ret
                   WHERE    ESTADO_SAP = ''
                         OR     ESTADO_SAP IS NULL
                            AND rut = p_idcliente
                            AND nro_operacion = p_num_op;

                  UPDATE vec_cob01.cc_pagos_bci_caja_sap_matri
                     SET CODIGO_MSG_SAP = p_ret,
                         MSG_SAP = p_msg,
                         FECHA_PROCESO_SAP = SYSDATE,
                         ESTADO_SAP = p_ret
                   WHERE    ESTADO_SAP = ''
                         OR     ESTADO_SAP IS NULL
                            AND rut = p_idcliente
                            AND correlativo_id2 = p_num_op;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('Resp'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');

                        UPDATE vec_cob01.cc_pagos_banco_sap_matri
                           SET CODIGO_MSG_SAP = p_ret,
                               MSG_SAP = p_msg,
                               FECHA_PROCESO_SAP = SYSDATE,
                               ESTADO_SAP = p_ret
                         WHERE    ESTADO_SAP = ''
                               OR     ESTADO_SAP IS NULL
                                  AND rut = p_idcliente
                                  AND nro_operacion = p_num_op;

                        UPDATE vec_cob01.cc_pagos_bci_caja_sap_matri
                           SET CODIGO_MSG_SAP = p_ret,
                               MSG_SAP = p_msg,
                               FECHA_PROCESO_SAP = SYSDATE,
                               ESTADO_SAP = p_ret
                         WHERE    ESTADO_SAP = ''
                               OR     ESTADO_SAP IS NULL
                                  AND rut = p_idcliente
                                  AND correlativo_id2 = p_num_op;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg :=
                                 'Error en el formato de la respuesta 1 : '
                              || SQLERRM;
                           l_data_json := NULL;

                           UPDATE vec_cob01.cc_pagos_banco_sap_matri
                              SET CODIGO_MSG_SAP = p_ret,
                                  MSG_SAP = p_msg,
                                  FECHA_PROCESO_SAP = SYSDATE,
                                  ESTADO_SAP = p_ret
                            WHERE    ESTADO_SAP = ''
                                  OR     ESTADO_SAP IS NULL
                                     AND rut = p_idcliente
                                     AND nro_operacion = p_num_op;

                           UPDATE vec_cob01.cc_pagos_bci_caja_sap_matri
                              SET CODIGO_MSG_SAP = p_ret,
                                  MSG_SAP = p_msg,
                                  FECHA_PROCESO_SAP = SYSDATE,
                                  ESTADO_SAP = p_ret
                            WHERE    ESTADO_SAP = ''
                                  OR     ESTADO_SAP IS NULL
                                     AND rut = p_idcliente
                                     AND correlativo_id2 = p_num_op;
                     END;
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
            END IF;

            BEGIN
               INSERT INTO log_portal_pagos_sap (ID,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 dato2,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                       VALUES (
                                 id_log,
                                 'S',
                                 'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_crea_mat_sap',
                                 p_num_op,
                                 p_num_op,
                                 'Crea y paga deuda:',
                                 p_idcliente,
                                 v_respuesta,
                                 SYSDATE);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  INSERT INTO log_portal_pagos_sap (ID,
                                                    tipo_llamada,
                                                    integracion,
                                                    pade_nro_documento,
                                                    dato2,
                                                    tipo_integracion,
                                                    dato1,
                                                    msg_sap,
                                                    fecha_msg)
                          VALUES (
                                    id_log,
                                    'E',
                                    'INTLEG05(CREA Y PAGA DEUDA  FICA): ERROR MAYOR DE 4000 - int_leg05_fica_crea_mat_sap',
                                    p_num_op,
                                    p_num_op,
                                    'Crea y paga deuda:',
                                    p_idcliente,
                                    SUBSTR (v_respuesta, 1, 4000),
                                    SYSDATE);
            END;
         END LOOP;
      END IF;

      RETURN l_data_json;
   END int_leg05_fica_crea_mat_sap;


   FUNCTION int_leg05_fica_crea_mat_grat (p_idcliente       VARCHAR2,
                                          p_num_op          VARCHAR2,
                                          p_ret         OUT VARCHAR2,
                                          --Salida estado si tiene error en oracle S (Success) E (Error)
                                          p_msg         OUT VARCHAR2 --mensaje de error
                                                                    )
      RETURN json
   IS
      v_line                VARCHAR2 (32766);
      v_paga                VARCHAR2 (1);
      v_json                CLOB := EMPTY_CLOB ();
      --
      v_respuesta           CLOB;
      v_token               VARCHAR2 (500);
      l_resp_json           json;
      l_data_json           json;
      l_return_json         json;
      l_data_json_l         json_list;
      nombre_dcto           VARCHAR2 (5000);
      V_FECHA_DOCUMENTO     DATE;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
           SELECT *
             FROM vec_cob01.pop_pagos_detalle_temp_sap a
            WHERE     pa_rut = p_idcliente
                  AND pade_tipo_documento = p_tipo_doc
                  AND pa_nro_operacion = p_num_op
         ORDER BY pade_fec_vencimiento ASC;

      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      id_log                NUMBER;
      v_contador            NUMBER := 0;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            BEGIN
               SELECT rec_nombre_sap
                 INTO nombre_dcto
                 FROM utsap001.conf_recursos
                WHERE     rec_categoria = 2
                      AND rec_subcategoria = 2
                      AND rec_codigo_sap = reg_grupo.pade_tipo_documento;

               SELECT operacion_op, sub_operacion_op
                 INTO pl_operacion_op, pl_sub_operacion_op
                 FROM operacion_sub_operacion_sap
                WHERE clase_documento_sap = reg_grupo.pade_tipo_documento;

               v_json := '';
               v_contador := 0;
               v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_paga := '';

                  IF v_contador = 0
                  THEN
                     IF SYSDATE >
                           TO_DATE (reg.pade_fec_vencimiento, 'YYYYMMDD')
                     THEN
                        V_FECHA_DOCUMENTO :=
                           TO_DATE (reg.pade_fec_vencimiento, 'YYYYMMDD');
                     ELSE
                        V_FECHA_DOCUMENTO := SYSDATE;
                     END IF;
                  END IF;

                  v_contador := v_contador + 1;
                  v_line :=
                        v_line
                     || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                     || reg.pa_rut
                     || '",
                               "Tipo_documento": "'
                     || reg.pade_tipo_documento
                     || '",
                               "Fecha_documento": "'
                     || TO_CHAR (V_FECHA_DOCUMENTO, 'YYYYMMDD')
                     || '",
                               "Nro_Cuponera": "'
                     || reg.pa_nro_operacion
                     || '",
                               "Documento": "",
                               "Cuota": "'
                     || reg.pade_cuota
                     || '",
                               "Fecha_vencimiento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Importe": "'
                     || reg.pade_monto_local
                     || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                     || reg.pade_nro_carrera
                     || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                     || reg.pade_matricula
                     || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                     || pl_operacion_op
                     || '",
                               "Sub_operacion": "'
                     || pl_sub_operacion_op
                     || '",
                               "Descripcion": "'
                     || reg.pade_tipo_documento
                     || '-'
                     || nombre_dcto
                     || '-'
                     || 'CUOTA '
                     || reg.pade_cuota                  --reg.pade_observacion
                     || '",
                               "Elemento_PEP": "",
                               "Pagar": ""
                            },';
               END LOOP;

               v_json := v_json || v_line;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            /*Fin Json de entrada */
            BEGIN
               /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
               /*  sappodev:desarrollo  puerto 51000
                   sappoqa:testing      puerto 52000
                       falta que nos envien la url para la interfaz int_leg02
               */
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            /*Fin llamada a servicio SAP*/
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;

            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');

                  IF p_ret = 'S'
                  THEN
                     UPDATE vec_cob01.pop_procesa_gratuidad
                        SET procesado = 'S', FECHA_PROCESO_SAP = SYSDATE
                      WHERE ALU_RUT_N = p_idcliente AND NRO_CUPON = p_num_op;

                     COMMIT;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('Resp'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');

                        IF p_ret = 'S'
                        THEN
                           UPDATE vec_cob01.pop_procesa_gratuidad
                              SET procesado = 'S',
                                  FECHA_PROCESO_SAP = SYSDATE
                            WHERE     ALU_RUT_N = p_idcliente
                                  AND NRO_CUPON = p_num_op;

                           COMMIT;

                           UPDATE vec_cob01.jf_regulariza_2018_tmp
                              SET procesado = 'S',
                                  FECHA_PROCESO_SAP = SYSDATE
                            WHERE     ALU_RUT_N = p_idcliente
                                  AND NRO_CUPON_GRATUIDAD = p_num_op;

                           COMMIT;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg := v_respuesta;
                           l_data_json := NULL;
                     END;
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
            END IF;

            BEGIN
               INSERT INTO log_portal_pagos_sap (ID,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 dato2,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'S',
                            'INTLEG05(CREA DEUDA  FICA GRATUIDAD)',
                            p_num_op,
                            p_num_op,
                            'Crea y paga deuda:',
                            p_idcliente,
                            v_respuesta,
                            SYSDATE);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  INSERT INTO log_portal_pagos_sap (ID,
                                                    tipo_llamada,
                                                    integracion,
                                                    pade_nro_documento,
                                                    dato2,
                                                    tipo_integracion,
                                                    dato1,
                                                    msg_sap,
                                                    fecha_msg)
                          VALUES (
                                    id_log,
                                    'E',
                                    'INTLEG05(CREA DEUDA  FICA GRATUIDAD): ERROR MAYOR DE 4000',
                                    p_num_op,
                                    p_num_op,
                                    'Crea y paga deuda:',
                                    p_idcliente,
                                    SUBSTR (v_respuesta, 1, 4000),
                                    SYSDATE);
            END;
         END LOOP;
      END IF;

      RETURN l_data_json;
   END int_leg05_fica_crea_mat_grat;

   PROCEDURE int_leg05_llama_matri_sap (p_banco IN VARCHAR2)
   IS
      v_json                     VARCHAR2 (3200);
      --v_respuesta varchar2(32000);
      v_respuesta                CLOB;
      v_token                    VARCHAR2 (500);
      v_codigo_error             VARCHAR2 (20);
      v_mensaje_error            VARCHAR2 (4000);
      v_fecha_error              DATE;
      v_mensaje_personalizado    VARCHAR2 (1000);

      l_cli_json                 json;
      l_cli_json_data            json_list;
      l_cli_json2                json;
      l_data_json                json;
      l_data_json2               json;

      v_error                    VARCHAR2 (5000);
      p_tipo_interlocutor        VARCHAR2 (1000);
      p_cli_rut                  VARCHAR2 (1000);                -- 15112572-7
      p_cli_matricula            VARCHAR2 (1000);
      p_cli_cod_carrera          VARCHAR2 (1000);
      p_cli_agrupacion           VARCHAR2 (1000);
      p_cli_tratamiento          VARCHAR2 (1000);                       --fijo
      p_cli_nombres1             VARCHAR2 (1000);
      p_cli_nombres2             VARCHAR2 (1000);
      p_cli_cod_giro             VARCHAR2 (1000);
      p_cli_sexo                 VARCHAR2 (1000);
      p_cli_rubro                VARCHAR2 (1000);
      p_cli_direccion            VARCHAR2 (1000);
      p_cli_numero               VARCHAR2 (1000);
      p_cli_codigo_comuna        VARCHAR2 (1000);
      p_cli_region               VARCHAR2 (1000);
      p_cli_telefono             VARCHAR2 (1000);
      p_cli_email                VARCHAR2 (1000);
      p_cli_celular              VARCHAR2 (1000);
      p_documento                VARCHAR2 (1000);
      p_cli_canal_distribucion   VARCHAR2 (1000);

      v_ret                      VARCHAR2 (4000);
      v_msg                      VARCHAR2 (5000);
      v_id_venta                 NUMBER;

      v_ret2                     VARCHAR2 (4000);
      v_msg2                     VARCHAR2 (5000);

      pl_nro_carrera             vec_cob01.pop_pagos_detalle_temp_sap.pade_nro_carrera%TYPE;
      pl_matricula               vec_cob01.pop_pagos_detalle_temp_sap.pade_matricula%TYPE;
      V_CARRERA_ICON             VARCHAR2 (20);

      CURSOR alumnos_matri (
         c_banco   IN VARCHAR2)
      IS
         SELECT A.rut,
                A.nro_operacion,
                A.estado_sap,
                A.CANT_RUT
           FROM (  SELECT rut,
                          nro_operacion,
                          estado_sap,
                          COUNT (DISTINCT rut) CANT_RUT
                     FROM vec_cob01.cc_pagos_banco_sap_matri
                    WHERE     'SANTANDER' = c_banco
                          AND (estado_sap = '' OR estado_sap IS NULL)
                 GROUP BY rut, nro_operacion, estado_sap) A
         UNION
         SELECT B.rut,
                B.nro_operacion,
                B.estado_sap,
                B.CANT_RUT
           FROM (  SELECT rut,
                          TO_NUMBER (correlativo_id2) nro_operacion,
                          estado_sap,
                          COUNT (DISTINCT rut)      CANT_RUT
                     FROM vec_cob01.cc_pagos_bci_caja_sap_matri
                    WHERE     'BCI' = c_banco
                          AND (estado_sap = '' OR estado_sap IS NULL)
                 GROUP BY rut, correlativo_id2, estado_sap) B;
   BEGIN
      FOR reg IN alumnos_matri (p_banco)
      LOOP
         --CREACIÓN DE CLIENTES BANCO DE MATRICULAS
         BEGIN
            SELECT pade_nro_carrera, pade_matricula
              INTO pl_nro_carrera, pl_matricula
              FROM vec_cob01.pop_pagos_detalle_temp_sap
             WHERE     pa_nro_operacion = reg.nro_operacion
                   AND pa_rut = reg.rut
                   AND ROWNUM = 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pl_nro_carrera := NULL;
               pl_matricula := NULL;
         END;

         --CREACION DE CLIENTE
         SELECT '0001'                                 tipo_interlocutor,
                alu_rut_n || '-' || alu_rut_v          cli_rut,
                pl_matricula                           nro_matricula,
                pl_nro_carrera                         cli_cod_carrera,
                'ZC01'                                 cli_agrupacion,
                DECODE (alu_sexo, 'M', '0002', '0001') cli_tratamiento,
                alu_nombres,
                alu_paterno || ' ' || alu_materno      cli_apellidos,
                ''                                     cli_cod_giro,
                DECODE (alu_sexo, 'M', '2', '1')       cli_sexo,
                ''                                     cli_rubro,
                alu_dir_origen,
                ''                                     cli_direccion_numero,
                utsap001.pkg_recursos.recupera_codigo_sap (
                   1,
                   10,
                   '',
                   alu_comuna_origen_alu)
                   cli_comuna,
                utsap001.pkg_recursos.recupera_codigo_sap (
                   1,
                   9,
                   '',
                   alu_localidad_origen)
                   cli_region,
                alu_fono_origen                        cli_telefono,
                NULL                                   post_email,
                NULL                                   post_celular,
                11                                     cli_canal_distribucion
           INTO p_tipo_interlocutor,
                p_cli_rut,
                p_cli_matricula,
                p_cli_cod_carrera,
                p_cli_agrupacion,
                p_cli_tratamiento,
                p_cli_nombres1,
                p_cli_nombres2,
                p_cli_cod_giro,
                p_cli_sexo,
                p_cli_rubro,
                p_cli_direccion,
                p_cli_numero,
                p_cli_codigo_comuna,
                p_cli_region,
                p_cli_telefono,
                p_cli_email,
                p_cli_celular,
                p_cli_canal_distribucion
           FROM vac_estruc.alumno
          WHERE alu_rut_n = reg.rut AND ROWNUM = 1;

         HTP.P ('Procesando:' || p_cli_rut || '<br>');

         --CREAMOS EL CLIENTE
         --llama a la función int_leg04_json
         BEGIN
            l_cli_json2 :=
               utsap001.pkg_integra_utal.int_leg04_json (
                  p_tipo_interlocutor,
                  p_cli_rut,
                  'D000',
                  p_cli_matricula,
                  p_cli_cod_carrera,
                  p_cli_agrupacion,
                  p_cli_tratamiento,
                  p_cli_nombres1,
                  p_cli_nombres2,
                  p_cli_cod_giro,
                  p_cli_sexo,
                  p_cli_rubro,
                  p_cli_direccion,
                  p_cli_numero,
                  p_cli_codigo_comuna,
                  p_cli_region,
                  p_cli_telefono,
                  p_cli_celular,
                  p_cli_email,
                  p_cli_canal_distribucion,
                  v_ret,
                  v_msg);
            l_data_json2 := json (l_cli_json2.get ('data'));
            v_ret2 :=
               UTSAP001.pkg_integra_utal.lee_json (l_data_json2, 'TYPE');
            v_msg2 :=
               UTSAP001.pkg_integra_utal.lee_json (l_data_json2, 'MESSAGE');
         --REGISTRAMOS EL LOG DE LA CREACION
         EXCEPTION
            WHEN OTHERS
            THEN
               v_codigo_error := SQLCODE;
               v_mensaje_error :=
                  SQLERRM || DBMS_UTILITY.format_error_backtrace;
               v_fecha_error := SYSDATE;

               INSERT INTO vec_cob02.log_error (CORRELATIVO,
                                                codigo_error,
                                                mensaje_error,
                                                fecha,
                                                mensaje_personalizado)
                    VALUES (0,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            '*');

               COMMIT;

               INSERT INTO vec_cob02.LOG_CREA_CLIENTE (tipo_interlocutor,
                                                       cli_rut,
                                                       alu_nombres,
                                                       cli_apellidos,
                                                       cli_cod_giro,
                                                       cli_sexo,
                                                       cli_rubro,
                                                       alu_dir_origen,
                                                       cli_direccion_numero,
                                                       cli_comuna,
                                                       cli_region,
                                                       cli_telefono,
                                                       post_email,
                                                       post_celular)
                    VALUES (p_tipo_interlocutor,
                            p_cli_rut,
                            p_cli_nombres1,
                            p_cli_nombres2,
                            p_cli_cod_giro,
                            p_cli_sexo,
                            p_cli_rubro,
                            p_cli_direccion,
                            p_cli_numero,
                            p_cli_codigo_comuna,
                            p_cli_region,
                            p_cli_telefono,
                            p_cli_EMAIL,
                            p_cli_celular);
         END;

         BEGIN
            INSERT INTO vec_cob02.LOG_CREA_CLIENTE (tipo_interlocutor,
                                                    cli_rut,
                                                    alu_nombres,
                                                    cli_apellidos,
                                                    cli_cod_giro,
                                                    cli_sexo,
                                                    cli_rubro,
                                                    alu_dir_origen,
                                                    cli_direccion_numero,
                                                    cli_comuna,
                                                    cli_region,
                                                    cli_telefono,
                                                    post_email,
                                                    post_celular)
                 VALUES (p_tipo_interlocutor,
                         p_cli_rut,
                         p_cli_nombres1,
                         p_cli_nombres2,
                         p_cli_cod_giro,
                         p_cli_sexo,
                         p_cli_rubro,
                         p_cli_direccion,
                         p_cli_numero,
                         p_cli_codigo_comuna,
                         p_cli_region,
                         p_cli_telefono,
                         p_cli_EMAIL,
                         p_cli_celular);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_mensaje_personalizado :=
                     'FALLO EN LOG DE CLIENTE, DATOS'
                  || p_tipo_interlocutor
                  || ','
                  || p_cli_rut
                  || ','
                  || p_cli_nombres1
                  || ','
                  || p_cli_nombres2
                  || ','
                  || p_cli_cod_giro
                  || ','
                  || p_cli_sexo
                  || ','
                  || p_cli_rubro
                  || ','
                  || p_cli_direccion
                  || ','
                  || p_cli_numero
                  || ','
                  || p_cli_codigo_comuna
                  || ','
                  || p_cli_region
                  || ','
                  || p_cli_telefono
                  || ','
                  || p_cli_EMAIL
                  || ','
                  || p_cli_celular;

               v_codigo_error := SQLCODE;
               v_mensaje_error :=
                  SQLERRM || DBMS_UTILITY.format_error_backtrace;
               v_fecha_error := SYSDATE;

               INSERT INTO vec_cob02.log_error (CORRELATIVO,
                                                codigo_error,
                                                mensaje_error,
                                                fecha,
                                                mensaje_personalizado)
                    VALUES (1,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado);

               COMMIT;
         END;

         /*llama a la función int_sap11_json y en la variable l_cli_json recibe el json del data*/
         BEGIN
            IF (reg.estado_sap = '' OR reg.estado_sap IS NULL)
            THEN
               l_cli_json :=
                  int_leg05_fica_crea_mat_sap (reg.rut,
                                               reg.nro_operacion,
                                               v_ret,
                                               v_msg);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_error_deudas_sap (codigo_error,
                                                 mensaje_error,
                                                 fecha,
                                                 mensaje_sap)
                    VALUES (2,
                            v_error,
                            SYSDATE,
                            v_msg);

               COMMIT;
         END;
      END LOOP;


      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         NULL;
      ELSE
         --htp.p(v_error||' - '||v_msg);
         v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_error_deudas_sap (codigo_error,
                                           mensaje_error,
                                           fecha,
                                           mensaje_sap)
              VALUES (3,
                      'Error',
                      SYSDATE,
                      v_error || ' - ' || v_msg);

         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_error_deudas_sap (codigo_error,
                                           mensaje_error,
                                           fecha,
                                           mensaje_sap)
              VALUES (4,
                      'Error',
                      SYSDATE,
                      v_msg);

         COMMIT;
   END int_leg05_llama_matri_sap;


   PROCEDURE reprocesar_pago_banco (p_banco       IN VARCHAR2,
                                    p_rut            VARCHAR2,
                                    p_nro_cupon      VARCHAR2)
   IS
      v_token                    VARCHAR2 (500);
      v_codigo_error             VARCHAR2 (20);
      v_mensaje_error            VARCHAR2 (4000);
      v_fecha_error              DATE;
      v_mensaje_personalizado    VARCHAR2 (1000);
      l_data_json_l              json_list;
      v_json                     CLOB;
      v_json_2                   VARCHAR2 (32000);
      v_json_2_ini               VARCHAR2 (32000);
      v_json_2_fin               VARCHAR2 (32000);
      v_json_inicio              CLOB;
      v_json_fin                 CLOB;
      v_respuesta                CLOB;

      l_cli_json                 json;
      l_cli_json_data            json_list;
      p_tipo_doc                 VARCHAR2 (10);

      l_resp_json                json;
      l_data_json                json;
      id_log                     NUMBER;

      v_error                    VARCHAR2 (5000);
      p_idcliente                VARCHAR2 (1000);
      cuota                      VARCHAR2 (1000);
      carrera                    VARCHAR2 (1000);
      codig_transaccion          VARCHAR2 (1000);
      matricula                  VARCHAR2 (1000);


      p_tipo_documento           VARCHAR2 (1000);
      p_fecha_documento          VARCHAR2 (1000);
      --p_fecha_documento      date;
      p_cuponera                 VARCHAR2 (1000);
      p_documento                VARCHAR2 (1000);
      p_cuota                    VARCHAR2 (1000);
      p_fecha_vencimiento        VARCHAR2 (1000);
      p_monto_local              VARCHAR2 (1000);
      p_empresa                  VARCHAR2 (1000);
      p_carrera                  VARCHAR2 (1000);
      p_moneda                   VARCHAR2 (1000);
      p_nro_matricula            VARCHAR2 (1000);
      p_centro_beneficio         VARCHAR2 (1000);
      p_monto                    VARCHAR2 (1000);
      p_cli_canal_distribucion   VARCHAR2 (1000);
      v_Tipo_Documento           VARCHAR2 (32000);
      v_Fecha_Vencimiento        VARCHAR2 (32000);
      v_rut                      VARCHAR2 (200);

      v_ret                      VARCHAR2 (4000);
      p_ret                      VARCHAR2 (4000);

      v_msg                      VARCHAR2 (5000);
      p_msg                      VARCHAR2 (5000);
      v_id_venta                 NUMBER;

      v_ret2                     VARCHAR2 (4000);
      v_msg2                     VARCHAR2 (5000);

      pl_nro_carrera             vec_cob01.pop_pagos_detalle_temp_sap.pade_nro_carrera%TYPE;
      pl_matricula               vec_cob01.pop_pagos_detalle_temp_sap.pade_matricula%TYPE;
      V_CARRERA_ICON             VARCHAR2 (20);

      CURSOR matri_bci
      IS
         SELECT DISTINCT a.rut,
                         a.correlativo_id2,
                         TO_CHAR (a.valor) valor,
                         a.cuota,
                         a.matricula,
                         a.carrera,
                         a.codigo_transaccion,
                         a.descripcion,
                         a.fecha_recaudacion,
                         a.fecha_vencimiento,
                         a.documento_sap,
                         a.estado_sap,
                         a.msg_sap
           FROM vec_cob01.cc_pagos_bci_caja_sap a
          WHERE     estado_sap = 'E'
                AND rut = p_rut
                AND correlativo_id2 = p_nro_cupon
                AND 'BCI' = p_banco
         UNION
         SELECT DISTINCT a.rut,
                         TO_CHAR (a.nro_operacion) correlativo_id2,
                         A.monto_recaudar          valor,
                         a.cuota,
                         a.matricula,
                         a.carrera,
                         a.codigo_transaccion,
                         a.descripcion,
                         a.fecha_pago              fecha_recaudacion,
                         a.fecha_vencimiento,
                         a.documento_sap,
                         a.estado_sap,
                         a.msg_sap
           FROM vec_cob01.cc_pagos_banco_sap a
          WHERE     estado_sap = 'E'
                AND rut = p_rut
                AND nro_operacion = p_nro_cupon
                AND 'SANTANDER' = p_banco;
   BEGIN
      HTP.p (
            '<STRONG>REPROCESANDO CUPON '
         || p_rut
         || ' RUT '
         || p_nro_cupon
         || ' BANCO '
         || p_banco
         || '</STRONG><BR>');

      p_ret := 'S';

      BEGIN
         v_token := pkg_token.Get_token;
         v_json_inicio := '{"Token": "' || v_token || '",';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            HTP.p (p_msg);
      END;

      IF p_ret = 'S'
      THEN
         v_json_2 := '';
         v_json_2_fin := '';

         v_json_fin := '';
         v_json := '';

         FOR reg IN matri_bci
         LOOP
            p_ret := 'S';
            p_idcliente := reg.rut;

            IF p_banco = 'BCI'
            THEN
               p_tipo_documento := 'Y4';
            END IF;

            IF p_banco = 'SANTANDER'
            THEN
               p_tipo_documento := 'Y3';
            END IF;

            p_fecha_documento := reg.fecha_recaudacion;
            p_cuponera := reg.correlativo_id2;
            p_documento := reg.documento_sap;
            p_cuota := reg.cuota;
            p_fecha_vencimiento := reg.fecha_vencimiento;
            p_monto_local := reg.valor;
            p_empresa := 'UT01';
            p_carrera := reg.carrera;
            p_moneda := reg.codigo_transaccion;
            p_nro_matricula := reg.matricula;
            p_centro_beneficio := '';

            --***** SE MODIFICA MONTO DE ENVIO PARA EL PAGO DE DEUDAS EN MONEDA DIFERENTE A CLP
            --***** AHORA SE ENVIARÀ P_MONTO Y NO P_MONTO_LOCAL
            p_monto := reg.valor;

            IF (p_moneda <> 'CLP')
            THEN
               p_monto := REPLACE (reg.valor, ',', '.');
            END IF;

            --***************************************************************************************
            v_respuesta :=
                  '{ "Token": "'
               || v_token
               || '",
                                            "data":{
                                                           "Codigo_cli": "'
               || p_idcliente
               || '",
                                                           "Tipo_documento": "'
               || p_tipo_documento
               || '",
                                                           "Fecha_documento": "'
               || p_fecha_documento
               || '",
                                                           "Cuponera": "'
               || p_cuponera
               || '",
                                                           "Documento": "'
               || p_documento
               || '",
                                                           "Cuota": "'
               || p_cuota
               || '",
                                                           "Fecha_vencimiento": "'
               || p_fecha_vencimiento
               || '",
                                                           "Monto_local": "0'
               || p_monto
               || '",
                                                           "Empresa": "'
               || p_empresa
               || '",
                                                           "Carrera": "'
               || p_carrera
               || '",
                                                           "Moneda": "'
               || p_moneda
               || '",
                                                           "Nro_matricula": "'
               || p_nro_matricula
               || '",
                                                           "Centro_beneficio": "'
               || p_centro_beneficio
               || '",
                                                           "Descripcion": "'
               || reg.descripcion
               || '"
                                            },}';

            v_json := v_respuesta;


            HTP.p (
               '<STRONG>LLAMADA JSON:</STRONG><BR>' || v_json || '<BR><BR>');


            --inserto en el log de registros, no esta guardando mensaje, revisar
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG02(PAGA DEUDA ' || p_banco || ')',
                         p_documento,
                         'Pago ' || p_tipo_documento,
                         p_idcliente,
                         p_cuponera,
                         v_respuesta,
                         SYSDATE);

            COMMIT;

            --LLAMDA A INTEGRACION DE SAP CON EL JSON
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02',
                           v_json);

            HTP.p ('<STRONG>RESPUESTA JSON:</STRONG><BR>');

            --REVISAMOS LA RESUESTA DEL JSON
            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  HTP.P (v_respuesta || '<BR>');
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');

                  IF p_ret = 'S'
                  THEN
                     UPDATE vec_cob01.cc_pagos_bci_caja_sap
                        SET estado_sap = p_ret,
                            MSG_SAP = p_msg,
                            FECHA_PROCESO_SAP = SYSDATE
                      WHERE     rut = p_idcliente
                            AND correlativo_id2 = p_cuponera
                            AND fecha_vencimiento = p_fecha_vencimiento
                            AND documento_sap = p_documento;

                     UPDATE vec_cob01.cc_pagos_banco_sap
                        SET estado_sap = p_ret,
                            MSG_SAP = p_msg,
                            FECHA_PROCESO_SAP = SYSDATE
                      WHERE     rut = p_idcliente
                            AND nro_operacion = p_cuponera
                            AND fecha_vencimiento = p_fecha_vencimiento
                            AND documento_sap = p_documento;

                     COMMIT;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('data'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');

                        IF p_ret = 'S'
                        THEN
                           UPDATE vec_cob01.cc_pagos_bci_caja_sap
                              SET estado_sap = p_ret,
                                  MSG_SAP = p_msg,
                                  FECHA_PROCESO_SAP = SYSDATE
                            WHERE     rut = p_idcliente
                                  AND correlativo_id2 = p_cuponera
                                  AND fecha_vencimiento = p_fecha_vencimiento
                                  AND documento_sap = p_documento;

                           UPDATE vec_cob01.cc_pagos_banco_sap
                              SET estado_sap = p_ret,
                                  MSG_SAP = p_msg,
                                  FECHA_PROCESO_SAP = SYSDATE
                            WHERE     rut = p_idcliente
                                  AND nro_operacion = p_cuponera
                                  AND fecha_vencimiento = p_fecha_vencimiento
                                  AND documento_sap = p_documento;

                           COMMIT;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg :=
                                 'Error en el formato de la respuesta 1 : '
                              || SQLERRM;
                           l_data_json := NULL;

                           UPDATE vec_cob01.cc_pagos_bci_caja_sap
                              SET estado_sap = p_ret
                            WHERE     rut = p_idcliente
                                  AND correlativo_id2 = p_cuponera
                                  AND fecha_vencimiento = p_fecha_vencimiento
                                  AND documento_sap = p_documento;

                           UPDATE vec_cob01.cc_pagos_banco_sap
                              SET estado_sap = p_ret
                            WHERE     rut = p_idcliente
                                  AND nro_operacion = p_cuponera
                                  AND fecha_vencimiento = p_fecha_vencimiento
                                  AND documento_sap = p_documento;
                     END;
               END;
            END IF;


            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               HTP.p ('*********** ' || p_msg || ' *************');
            END IF;
         --RETRONAMOS EL OBJETO JSON
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg :=
               'error en la funcion:'
            || SQLERRM
            || DBMS_UTILITY.format_error_backtrace;
         HTP.p ('*********** ' || p_msg || ' *************');
   END reprocesar_pago_banco;



   PROCEDURE pago_banco_bci_masivo
   IS
      v_token                    VARCHAR2 (500);
      v_codigo_error             VARCHAR2 (20);
      v_mensaje_error            VARCHAR2 (4000);
      v_fecha_error              DATE;
      v_mensaje_personalizado    VARCHAR2 (1000);

      v_json                     CLOB;
      v_json_2                   VARCHAR2 (32000);
      v_json_2_ini               VARCHAR2 (32000);
      v_json_2_fin               VARCHAR2 (32000);
      v_json_inicio              CLOB;
      v_json_fin                 CLOB;
      v_respuesta                CLOB;

      l_cli_json                 json;
      l_cli_json_data            json_list;
      p_tipo_doc                 VARCHAR2 (10);

      l_resp_json                json;
      l_data_json                json;
      id_log                     NUMBER;

      v_error                    VARCHAR2 (5000);
      p_idcliente                VARCHAR2 (1000);
      cuota                      VARCHAR2 (1000);
      carrera                    VARCHAR2 (1000);
      codig_transaccion          VARCHAR2 (1000);
      matricula                  VARCHAR2 (1000);


      p_tipo_documento           VARCHAR2 (1000);
      p_fecha_documento          VARCHAR2 (1000);
      --p_fecha_documento      date;
      p_cuponera                 VARCHAR2 (1000);
      p_documento                VARCHAR2 (1000);
      p_cuota                    VARCHAR2 (1000);
      p_fecha_vencimiento        VARCHAR2 (1000);
      p_monto_local              VARCHAR2 (1000);
      p_empresa                  VARCHAR2 (1000);
      p_carrera                  VARCHAR2 (1000);
      p_moneda                   VARCHAR2 (1000);
      p_nro_matricula            VARCHAR2 (1000);
      p_centro_beneficio         VARCHAR2 (1000);
      p_monto                    VARCHAR2 (1000);
      p_cli_canal_distribucion   VARCHAR2 (1000);
      v_Tipo_Documento           VARCHAR2 (32000);
      v_Fecha_Vencimiento        VARCHAR2 (32000);
      v_rut                      VARCHAR2 (200);

      v_ret                      VARCHAR2 (4000);
      p_ret                      VARCHAR2 (4000);

      v_msg                      VARCHAR2 (5000);
      p_msg                      VARCHAR2 (5000);
      v_id_venta                 NUMBER;

      v_ret2                     VARCHAR2 (4000);
      v_msg2                     VARCHAR2 (5000);

      pl_nro_carrera             vec_cob01.pop_pagos_detalle_temp_sap.pade_nro_carrera%TYPE;
      pl_matricula               vec_cob01.pop_pagos_detalle_temp_sap.pade_matricula%TYPE;
      V_CARRERA_ICON             VARCHAR2 (20);

      CURSOR matri_bci
      IS
           SELECT a.rut,
                  a.correlativo_id2,
                  a.valor,
                  a.cuota,
                  a.matricula,
                  a.carrera,
                  a.codigo_transaccion,
                  a.descripcion,
                  a.fecha_recaudacion,
                  a.fecha_vencimiento,
                  a.documento_sap,
                  a.estado_sap,
                  a.msg_sap
             FROM vec_cob01.cc_pagos_bci_caja_sap a
            WHERE     estado_sap = 'E' /*and (
                  (rut='18653737' and correlativo_id2=309548) or
                  (rut='18176989' and correlativo_id2=309840)
                  )*/
                  AND EXISTS
                         (SELECT 1
                            FROM vec_cob01.cc_pagos_bci_caja_sap_MATRI B
                           WHERE     A.rut = B.RUT
                                 AND A.correlativo_id2 = B.correlativo_id2)
         ORDER BY a.rut, a.fecha_vencimiento;
   BEGIN
      p_ret := 'S';

      BEGIN
         v_token := pkg_token.Get_token;
         v_json_inicio := '{"Token": "' || v_token || '",';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            HTP.p (p_msg);
      END;

      IF p_ret = 'S'
      THEN
         v_json_2 := '';
         v_json_2_fin := '';

         v_json_fin := '';
         v_json := '';

         FOR reg IN matri_bci
         LOOP
            p_ret := 'S';
            p_idcliente := reg.rut;
            p_tipo_documento := 'Y4';
            p_fecha_documento := reg.fecha_recaudacion;
            p_cuponera := reg.correlativo_id2;
            p_documento := reg.documento_sap;
            p_cuota := reg.cuota;
            p_fecha_vencimiento := reg.fecha_vencimiento;
            p_monto_local := reg.valor;
            p_empresa := 'UT01';
            p_carrera := reg.carrera;
            p_moneda := reg.codigo_transaccion;
            p_nro_matricula := reg.matricula;
            p_centro_beneficio := '';

            --***** SE MODIFICA MONTO DE ENVIO PARA EL PAGO DE DEUDAS EN MONEDA DIFERENTE A CLP
            --***** AHORA SE ENVIARÀ P_MONTO Y NO P_MONTO_LOCAL
            p_monto := reg.valor;

            IF (p_moneda <> 'CLP')
            THEN
               p_monto := REPLACE (reg.valor, ',', '.');
            END IF;

            --***************************************************************************************
            v_respuesta :=
                  '{ "Token": "'
               || v_token
               || '",
                                            "data":{
                                                           "Codigo_cli": "'
               || p_idcliente
               || '",
                                                           "Tipo_documento": "'
               || p_tipo_documento
               || '",
                                                           "Fecha_documento": "'
               || p_fecha_documento
               || '",
                                                           "Cuponera": "'
               || p_cuponera
               || '",
                                                           "Documento": "'
               || p_documento
               || '",
                                                           "Cuota": "'
               || p_cuota
               || '",
                                                           "Fecha_vencimiento": "'
               || p_fecha_vencimiento
               || '",
                                                           "Monto_local": "'
               || p_monto
               || '",
                                                           "Empresa": "'
               || p_empresa
               || '",
                                                           "Carrera": "'
               || p_carrera
               || '",
                                                           "Moneda": "'
               || p_moneda
               || '",
                                                           "Nro_matricula": "'
               || p_nro_matricula
               || '",
                                                           "Centro_beneficio": "'
               || p_centro_beneficio
               || '",
                                                           "Descripcion": "'
               || reg.descripcion
               || '"
                                            },}';

            v_json := v_respuesta;


            HTP.p (v_json || '<BR><BR>');


            --inserto en el log de registros, no esta guardando mensaje, revisar
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG02(PAGA DEUDA BCI)',
                         p_documento,
                         'Pago ' || p_tipo_documento,
                         p_idcliente,
                         p_cuponera,
                         v_respuesta,
                         SYSDATE);

            COMMIT;

            --LLAMDA A INTEGRACION DE SAP CON EL JSON
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02',
                           v_json);

            --REVISAMOS LA RESUESTA DEL JSON
            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json := json (l_resp_json.get ('data'));
                  p_ret := lee_json (l_data_json, 'TYPE');
                  p_msg := lee_json (l_data_json, 'MESSAGE');
                  HTP.p (
                        '<br>'
                     || v_respuesta
                     || 'mensaje: '
                     || p_msg
                     || '<br><br>');

                  IF p_msg = 'Cuota ya pagada'
                  THEN
                     p_ret := 'S';
                  END IF;

                  UPDATE vec_cob01.cc_pagos_bci_caja_sap
                     SET estado_sap = p_ret
                   WHERE     rut = p_idcliente
                         AND correlativo_id2 = p_cuponera
                         AND fecha_vencimiento = p_fecha_vencimiento
                         AND documento_sap = p_documento;

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_ret := 'E';
                     p_msg :=
                        'Error en el formato de la respuesta : ' || SQLERRM;
                     l_data_json := NULL;
                     HTP.p ('*********** ' || p_msg || ' *************');
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               HTP.p ('*********** ' || p_msg || ' *************');
            END IF;
         --RETRONAMOS EL OBJETO JSON
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg :=
               'error en la funcion:'
            || SQLERRM
            || DBMS_UTILITY.format_error_backtrace;
         HTP.p ('*********** ' || p_msg || ' *************');
   END pago_banco_bci_masivo;

   PROCEDURE actualiza_doc_matri (p_banco IN VARCHAR2)
   IS
      v_json                     VARCHAR2 (3200);
      --v_respuesta varchar2(32000);
      v_respuesta                CLOB;
      v_token                    VARCHAR2 (500);
      v_codigo_error             VARCHAR2 (20);
      v_mensaje_error            VARCHAR2 (4000);
      v_fecha_error              DATE;
      v_mensaje_personalizado    VARCHAR2 (1000);

      l_cli_json                 json_list;
      l_cli_json_data            json;

      v_error                    VARCHAR2 (5000);
      p_tipo_interlocutor        VARCHAR2 (1000);
      p_cli_rut                  VARCHAR2 (1000);                -- 15112572-7
      p_cli_matricula            VARCHAR2 (1000);
      p_cli_cod_carrera          VARCHAR2 (1000);
      p_cli_agrupacion           VARCHAR2 (1000);
      p_cli_tratamiento          VARCHAR2 (1000);                       --fijo
      p_cli_nombres1             VARCHAR2 (1000);
      p_cli_nombres2             VARCHAR2 (1000);
      p_cli_cod_giro             VARCHAR2 (1000);
      p_cli_sexo                 VARCHAR2 (1000);
      p_cli_rubro                VARCHAR2 (1000);
      p_cli_direccion            VARCHAR2 (1000);
      p_cli_numero               VARCHAR2 (1000);
      p_cli_codigo_comuna        VARCHAR2 (1000);
      p_cli_region               VARCHAR2 (1000);
      p_cli_telefono             VARCHAR2 (1000);
      p_cli_email                VARCHAR2 (1000);
      p_cli_celular              VARCHAR2 (1000);
      p_documento                VARCHAR2 (1000);
      p_cli_canal_distribucion   VARCHAR2 (1000);
      v_Tipo_Documento           VARCHAR2 (32000);
      v_Fecha_Vencimiento        VARCHAR2 (32000);
      v_rut                      VARCHAR2 (200);

      v_ret                      VARCHAR2 (4000);
      v_msg                      VARCHAR2 (5000);
      v_id_venta                 NUMBER;

      v_ret2                     VARCHAR2 (4000);
      v_msg2                     VARCHAR2 (5000);

      pl_nro_carrera             vec_cob01.pop_pagos_detalle_temp_sap.pade_nro_carrera%TYPE;
      pl_matricula               vec_cob01.pop_pagos_detalle_temp_sap.pade_matricula%TYPE;
      V_CARRERA_ICON             VARCHAR2 (20);

      CURSOR alumnos_matri (
         c_banco   IN VARCHAR2)
      IS
         SELECT A.rut,
                A.nro_operacion,
                A.estado_sap,
                A.CANT_RUT
           FROM (  SELECT rut,
                          nro_operacion,
                          estado_sap,
                          COUNT (DISTINCT rut) CANT_RUT
                     FROM vec_cob01.cc_pagos_banco_sap_matri
                    WHERE     'SANTANDER' = c_banco
                          AND NVL (ACTUALIZADO, 'N') = 'N'
                 GROUP BY rut, nro_operacion, estado_sap) A
         UNION
         SELECT B.rut,
                B.nro_operacion,
                B.estado_sap,
                B.CANT_RUT
           FROM (  SELECT rut,
                          TO_NUMBER (correlativo_id2) nro_operacion,
                          estado_sap,
                          COUNT (DISTINCT rut)      CANT_RUT
                     FROM vec_cob01.cc_pagos_bci_caja_sap_matri
                    WHERE 'BCI' = c_banco AND NVL (ACTUALIZADO, 'N') = 'N'
                 GROUP BY rut, correlativo_id2, estado_sap) B;
   BEGIN
      FOR reg IN alumnos_matri (p_banco)
      LOOP
         v_rut := reg.rut;
         l_cli_json :=
            UTSAP001.pkg_integra_utal.int_sap02_json_fica (reg.rut,
                                                           '',
                                                           '',
                                                           '',
                                                           '',
                                                           '',
                                                           v_ret,
                                                           v_msg);

         IF l_cli_json IS NOT NULL
         THEN
            FOR i IN 1 .. l_cli_json.COUNT
            LOOP
               v_Tipo_Documento :=
                  UTSAP001.pkg_integra_utal.lee_json (
                     json (l_cli_json.get (i)),
                     'Tipo_Documento');
               p_documento :=
                  UTSAP001.pkg_integra_utal.lee_json (
                     json (l_cli_json.get (i)),
                     'Documento');

               v_Fecha_Vencimiento :=
                  UTSAP001.pkg_integra_utal.lee_json (
                     json (l_cli_json.get (i)),
                     'Fecha_Vencimiento');
               v_Tipo_Documento := TRIM (SUBSTR (v_Tipo_Documento, 1, 2));

               BEGIN
                  IF (p_banco = 'BCI')
                  THEN
                     UPDATE vec_cob01.cc_pagos_bci_caja_sap
                        SET documento_sap =
                               TRIM (
                                  SUBSTR (p_documento,
                                          3,
                                          LENGTH (p_documento))),
                            nro_documento =
                               TRIM (
                                  SUBSTR (p_documento,
                                          3,
                                          LENGTH (p_documento)))
                      WHERE     rut = reg.rut
                            AND correlativo_id2 = reg.nro_operacion
                            AND TRIM (SUBSTR (descripcion, 5, 3)) =
                                   v_Tipo_Documento
                            AND fecha_vencimiento = v_Fecha_Vencimiento;
                  END IF;

                  IF (p_banco = 'SANTANDER')
                  THEN
                     UPDATE vec_cob01.cc_pagos_banco_sap
                        SET documento_sap = TRIM (p_documento),
                            nro_documento = TRIM (p_documento)
                      WHERE     rut = reg.rut
                            AND nro_operacion = reg.nro_operacion
                            AND tipo_documento = v_Tipo_Documento
                            AND fecha_vencimiento =
                                   TRIM (v_Fecha_Vencimiento);
                  END IF;

                  COMMIT;

                  HTP.p (l_cli_json.COUNT);
                  HTP.p (
                        reg.rut
                     || ' '
                     || reg.nro_operacion
                     || ' '
                     || v_Tipo_Documento
                     || ' '
                     || p_documento
                     || '<br><br>');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     HTP.p ('**********' || v_rut || '*************');
                     v_codigo_error := SQLCODE;
                     v_mensaje_error :=
                           SQLERRM
                        || DBMS_UTILITY.format_error_backtrace
                        || '**********'
                        || v_rut
                        || '*************';
                     v_fecha_error := SYSDATE;

                     INSERT
                       INTO log_error (codigo_error, mensaje_error, fecha)
                     VALUES (v_codigo_error, v_mensaje_error, v_fecha_error);

                     COMMIT;
               END;
            END LOOP;
         ELSE
            l_cli_json_data :=
               UTSAP001.pkg_integra_utal.int_sap02_json_data (v_rut,
                                                              '',
                                                              '',
                                                              '',
                                                              '',
                                                              '',
                                                              v_ret,
                                                              v_msg);
            p_documento :=
               UTSAP001.pkg_integra_utal.lee_json (l_cli_json_data,
                                                   'Documento');
         END IF;

         IF p_banco = 'SANTANDER'
         THEN
            UPDATE vec_cob01.cc_pagos_banco_sap_matri
               SET ACTUALIZADO = 'S'
             WHERE rut = reg.rut AND nro_operacion = reg.nro_operacion;

            UPDATE vec_cob01.cc_pagos_banco_sap
               SET estado_sap = NULL
             WHERE rut = reg.rut AND nro_operacion = reg.nro_operacion;
         END IF;

         IF p_banco = 'BCI'
         THEN
            UPDATE vec_cob01.cc_pagos_bci_caja_sap_matri
               SET ACTUALIZADO = 'S'
             WHERE rut = reg.rut AND correlativo_id2 = reg.nro_operacion;

            UPDATE vec_cob01.cc_pagos_bci_caja_sap
               SET estado_sap = NULL
             WHERE rut = reg.rut AND correlativo_id2 = reg.nro_operacion;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;
         HTP.p (v_error || '+++');
         HTP.p ('**********' || v_rut || '*************');

         INSERT INTO log_error_deudas_sap (codigo_error,
                                           mensaje_error,
                                           fecha,
                                           mensaje_sap)
              VALUES (4,
                      'Error',
                      SYSDATE,
                      v_msg);

         COMMIT;
   END actualiza_doc_matri;

   FUNCTION int_leg05_fica_portal_sap (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2,
      --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg         OUT VARCHAR2,                          --mensaje de error,
      p_pagar           VARCHAR2 DEFAULT 'X')
      RETURN json
   IS
      v_line                 VARCHAR2 (32766);
      v_json                 CLOB := EMPTY_CLOB ();
      --
      v_respuesta            CLOB;
      v_token                VARCHAR2 (500);
      l_resp_json            json;
      l_data_json            json;
      l_return_json          json;
      l_data_json_l          json_list;


      l_centro_gestor_base   operacion_sub_operacion_sap.centro_gestor_base%TYPE;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      pl_operacion_op        operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op    operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      id_log                 NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            BEGIN
               SELECT operacion_op, sub_operacion_op, centro_gestor_base
                 INTO pl_operacion_op,
                      pl_sub_operacion_op,
                      l_centro_gestor_base
                 FROM operacion_sub_operacion_sap
                WHERE clase_documento_sap = reg_grupo.pade_tipo_documento;

               -- clase_documento_sap clase_documento_icon

               v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_line :=
                        v_line
                     || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                     || reg.pa_rut
                     || '",
                               "Tipo_documento": "'
                     || reg.pade_tipo_documento
                     || '",
                               "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Nro_Cuponera": "'
                     || reg.pa_nro_operacion
                     || '",
                               "Documento": "",
                               "Cuota": "0001",
                               "Fecha_vencimiento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Importe": "'
                     || reg.pade_monto_local
                     || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                     || reg.pade_nro_carrera
                     || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                     || reg.pade_matricula
                     || '",
                               "Centro_beneficio": "'
                     || l_centro_gestor_base
                     || '",
                               "Operacion": "'
                     || pl_operacion_op
                     || '",
                               "Sub_operacion": "'
                     || pl_sub_operacion_op
                     || '",
                               "Descripcion": "'
                     || reg.pade_observacion
                     || '",
                               "Elemento_PEP": "",
                               "Pagar": "'
                     || p_pagar
                     || '",
                            "Tipo_Documento_Pago": "'||get_clase_documento_sap(reg.pa_rut,reg.pa_nro_operacion)||'"
                            }';
               END LOOP;

               v_json := v_json || v_line;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
         END LOOP;

         v_line := '';
         v_line := '} }';
         v_json := v_json || v_line;

         /*Fin Json de entrada */
         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
                    falta que nos envien la url para la interfaz int_leg02
            */
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json_l := json_list (l_resp_json.get ('Resp'));
               l_data_json := json (l_data_json_l.get (1));
               p_ret :=
                  lee_json (json (l_data_json_l.get (1)), 'TYPE');
               p_msg :=
                     lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                  || ', '
                  || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     l_resp_json := json (v_respuesta);
                     l_data_json := json (l_resp_json.get ('Resp'));

                     p_ret :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'TYPE');
                     p_msg :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'MESSAGE');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_ret := 'E';
                        p_msg := v_respuesta;
                        l_data_json := NULL;
                  END;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;


         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
                 VALUES (
                           id_log,
                           'S',
                           'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_portal_sap',
                           p_num_op,
                           p_num_op,
                           'Crea y paga deuda:',
                           p_idcliente,
                           v_json,
                           SYSDATE);


         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
                 VALUES (
                           id_log,
                           'S',
                           'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_portal_sap',
                           p_num_op,
                           p_num_op,
                           'Crea y paga deuda:',
                           p_idcliente,
                           v_respuesta,
                           SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   END int_leg05_fica_portal_sap;

   FUNCTION int_leg05_sd_titulacion (p_idcliente       VARCHAR2,
                                     p_num_op          VARCHAR2,
                                     p_ret         OUT VARCHAR2,
                                     --Salida estado si tiene error en oracle S (Success) E (Error)
                                     p_msg         OUT VARCHAR2, --mensaje de error
                                     p_pagar           VARCHAR2 DEFAULT 'X')
      RETURN json
   IS
      v_line               VARCHAR2 (32766);
      v_json               CLOB := EMPTY_CLOB ();
      v_respuesta          CLOB;
      v_token              VARCHAR2 (500);
      l_resp_json          json;
      l_data_json          json;
      l_return_json        json;
      pl_fecha_documento   VARCHAR2 (1000);
      p_numero_material    VARCHAR2 (1000);
      p_numero_deudor      VARCHAR2 (1000);
      p_monto              VARCHAR2 (1000);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      p_nro_cuota          NUMBER;
      id_log               NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_line :=
                        '{
                                    "TOKEN": "'
                     || v_token
                     || '",
                                    "FLAG": "SD",
                                    "BAPI_SALESORDER_CREATEFROMDAT2": {
                                    "ORDER_HEADER_IN": {
                                                          "Tipo_objeto": "BUS2031",
                                                          "Clase_documento": "ZP04",
                                                          "Canal_distribucion": "11",
                                                          "Fecha_entrega": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Fecha_referencia_cliente": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Cupon_pago": "'
                     || p_num_op
                     || '",
                                                          "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Matricula": "'
                     || reg.pade_matricula
                     || '",
                                                          "Codigo_carrera": "'
                     || reg.pade_nro_carrera
                     || '"
                                    },';
                  v_json := v_line;
                  v_line := '';
                  v_line :=
                        ' "ORDER_ITEMS_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "Posicion_superior_materiales": "000000",
                                                      "Numero_material": "'
                     || reg.pade_tipo_documento
                     || '",
                                                      "Jerarquia_posicion": "U0035",
                                                      "Centro": "UT01",
                                                      "Cantidad_prevista": "1",
                                                      "Unidad_medida": "UN",
                                                      "Centro_beneficio": "",
                                                      "Creado_por": "SYSPOSTGRADO",
                                                      "Clase_factura": "ZF02",
                                                      "Fecha_factura": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Pagar": "'
                     || p_pagar
                     || '",
                          "Tipo_Documento_Pago": "'||get_clase_documento_sap(p_idcliente,p_num_op)||'"
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_PARTNERS": {
                                                      "Funcion_interlocutor": "AG",
                                                      "Numero_deudor": "'
                     || reg.pa_rut
                     || '",
                                                      "Clave_pais": "CL",
                                                      "Clave_idioma": "ES"
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_SCHEDULES_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "N_reparto": "0001",
                                                      "Fecha_reparto": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Cantidad_pedida": "1"
                              },
                               "ORDER_CONDITIONS_IN": {
                                                      "Numero_posicion_condicion": "'
                     || p_nro_cuota
                     || '",
                                                      "Clase_condicion": "ZPR0",
                                                      "Importe_condicion": "'
                     || reg.pade_monto_local
                     || '",
                                                      "Clave_moneda": "CLP",
                                                      "Unidad_medida_condicion": "UN"
                               },';
                  p_nro_cuota := p_nro_cuota + 10;
                  v_json := v_json || v_line;
                  v_line := '';
               END LOOP;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json := json (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda:',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda:',
                      p_idcliente,
                      v_json,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      RETURN l_data_json;
   END int_leg05_sd_titulacion;

   FUNCTION int_leg05_sd_venta2 (p_idcliente       VARCHAR2,
                                 p_num_op          VARCHAR2,
                                 p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                 p_msg         OUT VARCHAR2 --mensaje de error
                                                           )
      RETURN json
   IS
      v_line               VARCHAR2 (32766);
      v_json               CLOB := EMPTY_CLOB ();
      v_respuesta          CLOB;
      v_token              VARCHAR2 (500);
      l_resp_json          json;
      l_data_json          json;
      l_return_json        json;
      pl_fecha_documento   VARCHAR2 (1000);
      p_numero_material    VARCHAR2 (1000);
      p_numero_deudor      VARCHAR2 (1000);
      p_monto              VARCHAR2 (1000);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      p_nro_cuota          NUMBER;
      id_log               NUMBER;
      v_posicion_item      NUMBER := 0;
      V_MATERIAL           VARCHAR2 (100);
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  V_MATERIAL := reg.pade_tipo_documento;

                  v_line :=
                        '{
                                    "TOKEN": "'
                     || v_token
                     || '",
                                    "FLAG": "SD",
                                    "BAPI_SALESORDER_CREATEFROMDAT2": {
                                    "ORDER_HEADER_IN": {
                                                          "Tipo_objeto": "BUS2031",
                                                          "Clase_documento": "ZP06",
                                                          "Canal_distribucion": "16",
                                                          "Fecha_entrega": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Fecha_referencia_cliente": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Cupon_pago": "'
                     || p_num_op
                     || '",
                                                          "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Matricula": "'
                     || p_idcliente
                     || '",
                                                          "Codigo_carrera": "'
                     || reg.pade_nro_carrera
                     || '"
                                    },';
                  v_json := v_line;
                  v_line := '';
                  v_line :=
                        ' "ORDER_ITEMS_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "Posicion_superior_materiales": "000000",
                                                      "Numero_material": "'
                     || reg.pade_tipo_documento
                     || '",
                                                      "Jerarquia_posicion": "U0065",
                                                      "Centro": "UT01",
                                                      "Cantidad_prevista": "1",
                                                      "Unidad_medida": "UN",
                                                      "Centro_beneficio": "",
                                                      "Creado_por": "USERINTERPO",
                                                      "Clase_factura": "ZF03",
                                                      "Fecha_factura": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Pagar": "X",
                                                        "Tipo_Documento_Pago": "'||get_clase_documento_sap(p_idcliente,p_num_op)||'"    
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_PARTNERS": {
                                                      "Funcion_interlocutor": "AG",
                                                      "Numero_deudor": "'
                     || reg.pa_rut
                     || '",
                                                      "Clave_pais": "CL",
                                                      "Clave_idioma": "ES"
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_SCHEDULES_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "N_reparto": "0001",
                                                      "Fecha_reparto": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Cantidad_pedida": "1"
                              },
                               "ORDER_CONDITIONS_IN": {
                                                      "Numero_posicion_condicion": "'
                     || p_nro_cuota
                     || '",
                                                      "Clase_condicion": "ZPR0",
                                                      "Importe_condicion": "'
                     || reg.pade_monto_local
                     || '",
                                                      "Clave_moneda": "CLP",
                                                      "Unidad_medida_condicion": "UN"
                               },';
                  p_nro_cuota := p_nro_cuota + 10;
                  v_json := v_json || v_line;
                  v_line := '';
               END LOOP;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            BEGIN
               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 tipo_integracion,
                                                 dato1,
                                                 dato2,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'S',
                            'INTLEG05(CREA Y PAGA DEUDA  SD 2)',
                            V_MATERIAL,
                            'Crea y paga deuda: Vinculo',
                            p_idcliente,
                            p_num_op,
                            v_json,
                            SYSDATE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            COMMIT;

            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json := json (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD 2)',
                      V_MATERIAL,
                      p_num_op,
                      'Crea y paga deuda: Vinculo',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;

            INSERT INTO log_portal_pagos_sap (ID,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG05(CREA Y PAGA DEUDA  SD 2)',
                         p_num_op,
                         p_num_op,
                         p_msg || '-Crea y paga deuda:',
                         p_idcliente,
                         v_respuesta,
                         SYSDATE);

            COMMIT;
      END;

      RETURN l_data_json;
   END int_leg05_sd_venta2;

   FUNCTION int_leg05_sd_venta3 (p_idcliente       VARCHAR2,
                                 p_num_op          VARCHAR2,
                                 p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                 p_msg         OUT VARCHAR2 --mensaje de error
                                                           )
      RETURN json
   IS
      v_line               VARCHAR2 (32766);
      v_json               CLOB := EMPTY_CLOB ();
      v_respuesta          CLOB;
      v_token              VARCHAR2 (500);
      l_resp_json          json;
      l_data_json          json;
      l_return_json        json;
      pl_fecha_documento   VARCHAR2 (1000);
      p_numero_material    VARCHAR2 (1000);
      p_numero_deudor      VARCHAR2 (1000);
      p_monto              VARCHAR2 (1000);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      p_nro_cuota          NUMBER;
      id_log               NUMBER;
      v_posicion_item      NUMBER := 0;
      V_MATERIAL           VARCHAR2 (100);
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  --obtenemos el material de la tabla de productos
                  BEGIN
                     SELECT prod_centro_costo
                       INTO V_MATERIAL
                       FROM vec_cob01.pop_productos
                      WHERE prod_id = reg.pade_prod_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_MATERIAL := '900001800';
                  END;


                  v_line :=
                        '{
                                    "TOKEN": "'
                     || v_token
                     || '",
                                    "FLAG": "SD",
                                    "BAPI_SALESORDER_CREATEFROMDAT2": {
                                    "ORDER_HEADER_IN": {
                                                          "Tipo_objeto": "BUS2031",
                                                          "Clase_documento": "ZP06",
                                                          "Canal_distribucion": "16",
                                                          "Fecha_entrega": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Fecha_referencia_cliente": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Cupon_pago": "'
                     || p_num_op
                     || '",
                                                          "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Matricula": "'
                     || p_idcliente
                     || '",
                                                          "Codigo_carrera": "'
                     || reg.pade_nro_carrera
                     || '"
                                    },';
                  v_json := v_line;
                  v_line := '';
                  v_line :=
                        ' "ORDER_ITEMS_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "Posicion_superior_materiales": "000000",
                                                      "Numero_material": "'
                     || V_MATERIAL
                     || '",
                                                      "Jerarquia_posicion": "U0065",
                                                      "Centro": "UT01",
                                                      "Cantidad_prevista": "1",
                                                      "Unidad_medida": "UN",
                                                      "Centro_beneficio": "",
                                                      "Creado_por": "USERINTERPO",
                                                      "Clase_factura": "ZF03",
                                                      "Fecha_factura": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Pagar": "X",
                                                        "Tipo_Documento_Pago": "'||get_clase_documento_sap(p_idcliente,p_num_op)||'"
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_PARTNERS": {
                                                      "Funcion_interlocutor": "AG",
                                                      "Numero_deudor": "'
                     || reg.pa_rut
                     || '",
                                                      "Clave_pais": "CL",
                                                      "Clave_idioma": "ES"
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_SCHEDULES_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "N_reparto": "0001",
                                                      "Fecha_reparto": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Cantidad_pedida": "1"
                              },
                               "ORDER_CONDITIONS_IN": {
                                                      "Numero_posicion_condicion": "'
                     || p_nro_cuota
                     || '",
                                                      "Clase_condicion": "ZPR0",
                                                      "Importe_condicion": "'
                     || reg.pade_monto_local
                     || '",
                                                      "Clave_moneda": "CLP",
                                                      "Unidad_medida_condicion": "UN"
                               },';
                  p_nro_cuota := p_nro_cuota + 10;
                  v_json := v_json || v_line;
                  v_line := '';
               END LOOP;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            BEGIN
               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 tipo_integracion,
                                                 dato1,
                                                 dato2,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'S',
                            'INTLEG05(CREA Y PAGA DEUDA  SD 3)',
                            V_MATERIAL,
                            'Crea y paga deuda',
                            p_idcliente,
                            p_num_op,
                            v_json,
                            SYSDATE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            COMMIT;

            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json := json (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD 3)',
                      V_MATERIAL,
                      p_num_op,
                      'Crea y paga deuda',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;

            INSERT INTO log_portal_pagos_sap (ID,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG05(CREA Y PAGA DEUDA  SD 3)',
                         p_num_op,
                         p_num_op,
                         'Crea y paga deuda',
                         p_idcliente,
                         v_respuesta,
                         SYSDATE);

            COMMIT;
      END;

      RETURN l_data_json;
   END int_leg05_sd_venta3;


   PROCEDURE llama_crea_paga_venta (p_idcliente VARCHAR2, p_num_op VARCHAR2)
   IS
      llamada   json;                     --CLOB             := EMPTY_CLOB ();
      p_ret     VARCHAR2 (5000);
      p_msg     VARCHAR2 (5000);
   BEGIN
      llamada :=
         pkg_integra_utal.int_leg05_sd_venta (p_idcliente,
                                              p_num_op,
                                              p_ret,
                                              p_msg);

      llamada.HTP;
      HTP.p ('<br><br>' || p_ret || '-mensaje: ' || p_msg);
   END;


   FUNCTION f_calculadespacho_sap (p_venta_codigo NUMBER)
      RETURN NUMBER
   IS
      v_cantidad_total   NUMBER (4);
      v_total_despacho   NUMBER;
   BEGIN
      BEGIN
         SELECT SUM (vede_cantidad)
           INTO v_cantidad_total
           FROM vec_cob03.pove_venta_detalle
          WHERE vent_codigo = p_venta_codigo;

         SELECT DECODE (
                   a.clie_retiro,
                   'S', 0,
                   vec_cob03.venta_online.f_costo_envio (tade_codigo,
                                                         cire_codigo,
                                                         v_cantidad_total))
                   AS valor_despacho
           INTO v_total_despacho
           FROM vec_cob03.pove_cliente a
                INNER JOIN vec_cob03.pove_pais i
                   ON i.pais_codigo = a.pais_codigo
                INNER JOIN vec_cob03.pove_region r
                   ON r.regi_codigo = a.regi_codigo
                INNER JOIN vec_cob03.pove_ciudad c
                   ON c.ciud_codigo = a.ciud_codigo
          WHERE clie_codigo = p_venta_codigo;

         RETURN (v_total_despacho);
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN (0);
      END;
   /*v_total_despacho*/
   END f_calculadespacho_sap;



   FUNCTION int_leg05_sd_venta (p_idcliente       VARCHAR2,
                                p_num_op          VARCHAR2,
                                p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                p_msg         OUT VARCHAR2  --mensaje de error
                                                          )
      RETURN json
   IS
      v_line                    VARCHAR2 (32766);
      v_json                    CLOB := EMPTY_CLOB ();
      v_respuesta               CLOB;
      v_token                   VARCHAR2 (500);
      l_resp_json               json;
      l_data_json               json;
      l_return_json             json;
      pl_fecha_documento        VARCHAR2 (1000);
      p_numero_material         VARCHAR2 (1000);
      p_numero_deudor           VARCHAR2 (1000);
      p_monto                   VARCHAR2 (1000);
      v_codigo_error            VARCHAR2 (20);
      v_mensaje_error           VARCHAR2 (4000);
      v_fecha_error             DATE;
      v_mensaje_personalizado   VARCHAR2 (4000);
      v_error                   VARCHAR2 (2000);
      v_valor                   BOOLEAN;
      v_factor                  NUMBER := 1;
      contadorlibros            NUMBER;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      CURSOR c_deudas_ventas (
         p_id_venta    NUMBER)
      --cursor alan
      IS
         SELECT c.clie_codigo,
                c.clie_rut,
                v.vent_codigo,
                p.prod_codigo_sap,
                p.prod_nombre,
                v.vent_total,
                vd.vede_cantidad, --getnetofromtotal(v.vent_total) prod_precio_impuesto
                --p.prod_precio_impuesto
                -- 17.01.2025 AlAN Riquelme - cambio de precio sin iva por precio nor
                p.prod_precio AS prod_precio_impuesto
           FROM vec_cob03.pove_venta         v,
                vec_cob03.pove_venta_detalle vd,
                vec_cob03.pove_producto_tl   p,
                vec_cob03.pove_cliente       c
          WHERE     v.vent_codigo = vd.vent_codigo
                AND p.prod_codigo = vd.prod_codigo
                AND c.clie_codigo = v.clie_codigo
                AND v.vent_codigo = p_id_venta;

      p_nro_cuota               NUMBER;
      id_log                    NUMBER;
      v_posicion_item           NUMBER := 0;
      v_valor_final             NUMBER;
      v_despacho_sap            NUMBER;
      V_MONTO_FINAL_SAP         NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_line :=
                        '{
                                    "TOKEN": "'
                     || v_token
                     || '",
                                    "FLAG": "SD",
                                    "BAPI_SALESORDER_CREATEFROMDAT2": {
                                    "ORDER_HEADER_IN": {
                                        "Tipo_objeto": "BUS2031",
                                        "Clase_documento": "ZP08",
                                        "Canal_distribucion": "03",
                                        "Fecha_entrega": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                        "Fecha_referencia_cliente": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                        "Cupon_pago": "'
                     || p_num_op
                     || '",
                                        "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                        "Matricula": "'
                     || reg.pa_rut
                     || '",
                                        "Codigo_carrera": "'
                     || reg.pade_nro_carrera
                     || '"
                                    },';

                  v_json := v_line;
                  v_line := '';
                  v_valor :=
                     vec_cob03.venta_online.get_esutalca (p_idcliente);

                  IF v_valor
                  THEN
                     v_factor := 0.7;
                  ELSE
                     v_factor := 0.9;
                  END IF;

                  /*  INSERT INTO vec_cob03.TMP_DATOS
                      (
                          VALOR_1,
                          VALOR_2,
                          VALOR_3
                      )
                VALUES ('JSONSAP',  v_factor,p_idcliente);*/

                  contadorlibros := 1;

                  --DETALLE DE LOS LIBROS
                  FOR reg_sap IN c_deudas_ventas (reg.pade_nro_documento)
                  LOOP
                     IF contadorlibros = 1
                     THEN
                        /*11.12.2024 ARI Se grega calculo de despacho el cual se sumara a la primera linea*/
                        v_despacho_sap :=
                           pkg_integra_utal.f_calculadespacho_sap (
                              reg.pade_nro_documento);
                        v_valor_final :=
                           ROUND (
                                reg_sap.prod_precio_impuesto * v_factor
                              + v_despacho_sap,
                              0);
                     ELSE
                        v_valor_final :=
                           ROUND (reg_sap.prod_precio_impuesto * v_factor, 0);
                     END IF;

                     contadorlibros := contadorlibros + 1;
                     /*    INSERT INTO vec_cob03.tmp_datos (
                             valor_1,
                             valor_2,
                             valor_3
                         ) VALUES (
                             'JSONSAP_ciclo',
                             v_factor,
                             v_valor_final
                         );*/

                     v_posicion_item := v_posicion_item + 10;
                     v_line :=
                           ' "ORDER_ITEMS_IN": {
                                        "Posicion_documento": "'
                        || v_posicion_item
                        || '",
                                        "Posicion_superior_materiales": "000000",
                                        "Numero_material": "'
                        || reg_sap.prod_codigo_sap
                        || '",
                                        "Jerarquia_posicion": "U0035",
                                        "Centro": "UT01",
                                        "Cantidad_prevista": "1",
                                        "Unidad_medida": "UN",
                                        "Centro_beneficio": "",
                                        "Creado_por": "SYSPOSTGRADO",
                                        "Clase_factura": "ZF02",
                                        "Fecha_factura": "'
                        || reg.pade_fec_vencimiento
                        || '",
                                        "Pagar": "X",
                                            "Tipo_Documento_Pago": "'||get_clase_documento_sap(p_idcliente,p_num_op)||'"
                               },';

                     v_json := v_json || v_line;
                     v_line := '';
                     v_line :=
                           --         v_line
                           --    ||
                           '"ORDER_PARTNERS": {
                                        "Funcion_interlocutor": "AG",
                                        "Numero_deudor": "'
                        || reg.pa_rut
                        || '",
                                        "Clave_pais": "CL",
                                        "Clave_idioma": "ES"
                               },';
                     v_line :=
                           v_line
                        || '"ORDER_SCHEDULES_IN": {
                                        "Posicion_documento": "'
                        || v_posicion_item
                        || '",
                                        "N_reparto": "0001",
                                        "Fecha_reparto": "'
                        || reg.pade_fec_vencimiento
                        || '",
                                        "Cantidad_pedida": "1"
                              },
                          "ORDER_CONDITIONS_IN": {
                                        "Numero_posicion_condicion": "'
                        || v_posicion_item
                        || '",
                                        "Clase_condicion": "ZPR0",
                                        "Importe_condicion": "'
                        || v_valor_final
                        || '",
                                        "Clave_moneda": "CLP",
                                        "Unidad_medida_condicion": "UN"
                               },';

                     p_nro_cuota := p_nro_cuota + 10;
                     v_json := v_json || v_line;
                     v_line := '';
                  END LOOP;
               END LOOP;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            --htp.p(v_json);
            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := JSON (v_respuesta);
               l_data_json := JSON (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD VENTA)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda venta:',
                      p_idcliente,
                      v_json,
                      SYSDATE);

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD VENTA)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda venta:',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            v_mensaje_personalizado := SQLERRM;
            v_codigo_error := SQLCODE;
            v_mensaje_error :=
                  SQLERRM
               || DBMS_UTILITY.format_error_backtrace
               || ' - '
               || p_idcliente;
            v_fecha_error := SYSDATE;

            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                    VALUES (
                              id_log,
                              'R',
                              'INTLEG05(CREA Y PAGA DEUDA  SD VENTA)',
                              p_num_op,
                              p_num_op,
                                 p_msg
                              || '-Crea y paga deuda venta:'
                              || v_mensaje_error,
                              p_idcliente,
                              v_respuesta,
                              SYSDATE);

            COMMIT;
      END;

      RETURN l_data_json;
   END int_leg05_sd_venta;

   /*llamada Creacion de deuda por ventas leg05*/

   PROCEDURE int_leg05_fica (p_codigo_cli         IN VARCHAR2,
                             p_tipo_documento     IN VARCHAR2,
                             p_fecha_documento    IN VARCHAR2,
                             p_num_cuponera       IN VARCHAR2,
                             p_importe            IN VARCHAR2,
                             p_carrera            IN VARCHAR2,
                             p_num_matricula      IN VARCHAR2,
                             p_centro_beneficio   IN VARCHAR2,
                             p_operacion          IN VARCHAR2,
                             p_sub_operacion      IN VARCHAR2,
                             p_descripcion        IN VARCHAR2)
   IS
      v_json            VARCHAR2 (3200);
      --v_respuesta varchar2(32000);
      v_respuesta       CLOB;
      v_token           VARCHAR2 (500);


      l_cli_json        json;

      l_cli_json_data   json_list;

      v_ret             VARCHAR2 (10);
      v_msg             VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sap11_json y en la variable l_cli_json recibe el json del data*/
      BEGIN
         l_cli_json :=
            int_leg05_json_fica (p_codigo_cli,
                                 p_tipo_documento,
                                 p_fecha_documento,
                                 p_num_cuponera,
                                 p_importe,
                                 p_carrera,
                                 p_num_matricula,
                                 p_centro_beneficio,
                                 p_operacion,
                                 p_sub_operacion,
                                 p_descripcion,
                                 v_ret,
                                 v_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
      END;

      HTP.p (v_ret || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         NULL;
         HTP.p (l_cli_json.COUNT);
      /*    FOR i IN 1 .. l_cli_json.COUNT loop

             if (i=1) then
             htp.p('REGISTRO:'||i||'<br>');
             htp.p('CODIGO_CLI:'||lee_json(json (l_cli_json.get (i)) , 'CODIGO_CLI')||'<br>');
             htp.p('CODIGO_CLI:'||lee_json(json (l_cli_json.get (i)) , 'CODIGO_CLI')||'<br>');
             htp.p('CUENTA_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'CUENTA_CONTRATO')||'<br>');
             htp.p('TIPO_CUENTA_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'TIPO_CUENTA_CONTRATO')||'<br>');
             htp.p('OBJETO_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'OBJETO_CONTRATO')||'<br>');
             htp.p('CLASE_OBJETO_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'CLASE_OBJETO_CONTRATO')||'<br>');
             htp.p('TIPO_DOCUMENTO:'||lee_json(json (l_cli_json.get (i)) , 'TIPO_DOCUMENTO')||'<br>');
             htp.p('DOCUMENTO:'||lee_json(json (l_cli_json.get (i)) , 'DOCUMENTO')||'<br>');
             htp.p('DOCUMENTO_INTERES:'||lee_json(json (l_cli_json.get (i)) , 'DOCUMENTO_INTERES')||'<br>');
             htp.p('FECHA_VENCIMIENTO:'||lee_json(json (l_cli_json.get (i)) , 'FECHA_VENCIMIENTO')||'<br>');
             htp.p('DOCUMENTO_PAGO:'||lee_json(json (l_cli_json.get (i)) , 'DOCUMENTO_PAGO')||'<br>');
             htp.p('SALDO_PAGADO:'||lee_json(json (l_cli_json.get (i)) , 'SALDO_PAGADO')||'<br>');
             htp.p('NRO_CUPON:'||lee_json(json (l_cli_json.get (i)) , 'NRO_CUPON')||'<br>');
             else
             htp.p('TYPE:'||lee_json(json (l_cli_json.get (i)) , 'TYPE')||'<br>');
             end if;
             htp.p('<br><br><br>');

           end LOOP;*/

      ELSE
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_leg05_fica;

   /*http://condor2-19testing.utalca.cl/pls/sap_test/pkg_integra_utal.int_leg05_fica?p_codigo_cli=124140692&p_fecha_documento=20170101&p_tipo_documento=MA&p_num_cuponera=1&p_importe=115555&p_carrera=04&p_num_matricula=97401027&p_centro_beneficio=FCA310001&p_operacion=&p_sub_operacion=&p_descripcion=ARANCEL*/

   FUNCTION int_leg05_json_fica (p_codigo_cli         IN     VARCHAR2,
                                 p_tipo_documento     IN     VARCHAR2,
                                 p_fecha_documento    IN     VARCHAR2,
                                 p_num_cuponera       IN     VARCHAR2,
                                 p_importe            IN     VARCHAR2,
                                 p_carrera            IN     VARCHAR2,
                                 p_num_matricula      IN     VARCHAR2,
                                 p_centro_beneficio   IN     VARCHAR2,
                                 p_operacion          IN     VARCHAR2,
                                 p_sub_operacion      IN     VARCHAR2,
                                 p_descripcion        IN     VARCHAR2,
                                 p_ret                   OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                 p_msg                   OUT VARCHAR2 --mensaje de error
                                                                     )
      RETURN json
   IS
      v_json          VARCHAR2 (3200);

      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      l_data_json     json_list;
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         -- agregar campo legado para saber si es  0001 natural 0003 empresa
         -- separar en el legado de ventas nombres y apellidos y en otros cortar de 40 caracteres  hasta completar 2 80 caracteres
         -- nombre3 el código giro
         -- busqueda2 rubro
         -- mauro enviara tabla con canal y clase ic y con legado correspondiente
         --Cli_clasificacion_fiscal si pide factura 1 y si no 0

         v_json :=
               '{
                    "TOKEN": "'
            || v_token
            || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {
                            "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
            || p_codigo_cli
            || '",
                               "Tipo_documento": "'
            || p_tipo_documento
            || '",
                               "Fecha_documento": "'
            || p_fecha_documento
            || '",
                               "Nro_Cuponera": "'
            || p_num_cuponera
            || '",
                               "Documento": "",
                               "Cuota": "0001",
                               "Fecha_vencimiento": "'
            || p_fecha_documento
            || '",
                               "Importe": "'
            || p_importe
            || '",
                               "Empresa": "UT01",
                               "Carrera": "'
            || p_carrera
            || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
            || p_num_matricula
            || '",
                               "Centro_beneficio": "'
            || p_centro_beneficio
            || '",
                               "Operacion": "'
            || p_operacion
            || '",
                               "Sub_operacion": "'
            || p_sub_operacion
            || '",
                               "Descripcion": "'
            || p_descripcion
            || '"
                            }
                    }
                }
                ';

         --htp.p(v_json);


         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

                    falta que nos envien la url para la interfaz int_leg02
            */

            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;
      END IF;


      HTP.p (v_respuesta);                                -- imprime respuesta

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         -- l_RETURN_json := json(l_resp_json.get('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* if p_ret = 'S' then
           --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

           if lee_json(l_RETURN_json,'TYPE') <> 'S' then
               p_ret := substr(lee_json(l_RETURN_json,'TYPE'),1,1) ;
               --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
           end if;
       end if;


       begin
           l_RETURN_json := json(l_resp_json.get('data'));
       exception when others then
           p_ret := 'S';
           p_msg := p_msg||' Error en el formato de la respuesta data*: '||sqlerrm;
           l_data_json := null;
       end ;*/



      /*retorna json*/
      RETURN l_RETURN_json;
   END int_leg05_json_fica;

   FUNCTION int_leg05_json_sd (p_clase_documento    IN     VARCHAR2,
                               p_canal              IN     VARCHAR2,
                               p_fecha_documento    IN     VARCHAR2,
                               p_matricula          IN     VARCHAR2,
                               p_codigo_carrera     IN     VARCHAR2,
                               p_numero_material    IN     VARCHAR2,
                               p_centro_beneficio   IN     VARCHAR2,
                               p_numero_deudor      IN     VARCHAR2,
                               p_monto              IN     VARCHAR2,
                               p_ret                   OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                               p_msg                   OUT VARCHAR2 --mensaje de error
                                                                   )
      RETURN json
   IS
      v_json          VARCHAR2 (3200);

      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      l_data_json     json_list;
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         -- agregar campo legado para saber si es  0001 natural 0003 empresa
         -- separar en el legado de ventas nombres y apellidos y en otros cortar de 40 caracteres  hasta completar 2 80 caracteres
         -- nombre3 el código giro
         -- busqueda2 rubro
         -- mauro enviara tabla con canal y clase ic y con legado correspondiente
         --Cli_clasificacion_fiscal si pide factura 1 y si no 0

         v_json :=
               '{
                        "TOKEN": "'
            || v_token
            || '",
                         "FLAG": "SD",
         "BAPI_SALESORDER_CREATEFROMDAT2": {
           "ORDER_HEADER_IN": {
                                  "Tipo_objeto": "BUS2031",
                                  "Clase_documento": "'
            || p_clase_documento
            || '",
                                  "Canal_distribucion": "'
            || p_canal
            || '",
                                  "Fecha_entrega": "'
            || p_fecha_documento
            || '",
                                  "Fecha_referencia_cliente": "'
            || p_fecha_documento
            || '",
                                  "Cupon_pago": "1",
                                  "Fecha_documento": "'
            || p_fecha_documento
            || '",
                                  "Matricula": "'
            || p_matricula
            || '",
                                  "Codigo_carrera": "'
            || p_codigo_carrera
            || '"
           },
           "ORDER_ITEMS_IN": {
                                  "Posicion_documento": "10",
                                  "Posicion_superior_materiales": "000000",
                                  "Numero_material": "'
            || p_numero_material
            || '",
                                  "Jerarquia_posicion": "U0035",
                                  "Centro": "UT01",
                                  "Cantidad_prevista": "1",
                                  "Unidad_medida": "UN",
                                  "Centro_beneficio": "'
            || p_centro_beneficio
            || '",
                                  "Creado_por": "MHUERTA",
                                  "Clase_factura": "ZF02",
                                  "Fecha_factura": "'
            || p_fecha_documento
            || '"
           },
           "ORDER_PARTNERS": {
                                  "Funcion_interlocutor": "AG",
                                  "Numero_deudor": "'
            || p_numero_deudor
            || '",
                                  "Clave_pais": "CL",
                                  "Clave_idioma": "ES"
           },
           "ORDER_SCHEDULES_IN": {
                                  "Posicion_documento": "10",
                                  "N_reparto": "0001",
                                  "Fecha_reparto": "'
            || p_fecha_documento
            || '",
                                  "Cantidad_pedida": "1"
          },
           "ORDER_CONDITIONS_IN": {
                                  "Numero_posicion_condicion": "10",
                                  "Clase_condicion": "ZPR0",
                                  "Importe_condicion": "'
            || p_monto
            || '",
                                  "Clave_moneda": "CLP",
                                  "Unidad_medida_condicion": "UN"
           }
       }
}
'         ;

         --htp.p(v_json);


         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

                    falta que nos envien la url para la interfaz int_leg02
            */

            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;
      END IF;


      HTP.p (v_respuesta);                                -- imprime respuesta

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         -- l_RETURN_json := json(l_resp_json.get('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* if p_ret = 'S' then
           --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

           if lee_json(l_RETURN_json,'TYPE') <> 'S' then
               p_ret := substr(lee_json(l_RETURN_json,'TYPE'),1,1) ;
               --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
           end if;
       end if;


       begin
           l_RETURN_json := json(l_resp_json.get('data'));
       exception when others then
           p_ret := 'S';
           p_msg := p_msg||' Error en el formato de la respuesta data*: '||sqlerrm;
           l_data_json := null;
       end ;*/



      /*retorna json*/
      RETURN l_RETURN_json;
   END int_leg05_json_sd;

   PROCEDURE int_leg05_sd (p_clase_documento    IN VARCHAR2 DEFAULT NULL,
                           p_canal              IN VARCHAR2 DEFAULT NULL,
                           p_fecha_documento    IN VARCHAR2 DEFAULT NULL,
                           p_matricula          IN VARCHAR2 DEFAULT NULL,
                           p_codigo_carrera     IN VARCHAR2 DEFAULT NULL,
                           p_numero_material    IN VARCHAR2 DEFAULT NULL,
                           p_centro_beneficio   IN VARCHAR2 DEFAULT NULL,
                           p_numero_deudor      IN VARCHAR2 DEFAULT NULL,
                           p_monto              IN VARCHAR2 DEFAULT NULL)
   IS
      v_json            VARCHAR2 (3200);
      --v_respuesta varchar2(32000);
      v_respuesta       CLOB;
      v_token           VARCHAR2 (500);


      l_cli_json        json;

      l_cli_json_data   json_list;

      v_ret             VARCHAR2 (10);
      v_msg             VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sap11_json y en la variable l_cli_json recibe el json del data*/
      BEGIN
         l_cli_json :=
            int_leg05_json_sd (p_clase_documento,
                               p_canal,
                               p_fecha_documento,
                               p_matricula,
                               p_codigo_carrera,
                               p_numero_material,
                               p_centro_beneficio,
                               p_numero_deudor,
                               p_monto,
                               v_ret,
                               v_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
      END;

      HTP.p (v_ret || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         NULL;
         HTP.p (l_cli_json.COUNT);
      /*    FOR i IN 1 .. l_cli_json.COUNT loop

             if (i=1) then
             htp.p('REGISTRO:'||i||'<br>');
             htp.p('CODIGO_CLI:'||lee_json(json (l_cli_json.get (i)) , 'CODIGO_CLI')||'<br>');
             htp.p('CUENTA_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'CUENTA_CONTRATO')||'<br>');
             htp.p('TIPO_CUENTA_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'TIPO_CUENTA_CONTRATO')||'<br>');
             htp.p('OBJETO_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'OBJETO_CONTRATO')||'<br>');
             htp.p('CLASE_OBJETO_CONTRATO:'||lee_json(json (l_cli_json.get (i)) , 'CLASE_OBJETO_CONTRATO')||'<br>');
             htp.p('TIPO_DOCUMENTO:'||lee_json(json (l_cli_json.get (i)) , 'TIPO_DOCUMENTO')||'<br>');
             htp.p('DOCUMENTO:'||lee_json(json (l_cli_json.get (i)) , 'DOCUMENTO')||'<br>');
             htp.p('DOCUMENTO_INTERES:'||lee_json(json (l_cli_json.get (i)) , 'DOCUMENTO_INTERES')||'<br>');
             htp.p('FECHA_VENCIMIENTO:'||lee_json(json (l_cli_json.get (i)) , 'FECHA_VENCIMIENTO')||'<br>');
             htp.p('DOCUMENTO_PAGO:'||lee_json(json (l_cli_json.get (i)) , 'DOCUMENTO_PAGO')||'<br>');
             htp.p('SALDO_PAGADO:'||lee_json(json (l_cli_json.get (i)) , 'SALDO_PAGADO')||'<br>');
             htp.p('NRO_CUPON:'||lee_json(json (l_cli_json.get (i)) , 'NRO_CUPON')||'<br>');
             else
             htp.p('TYPE:'||lee_json(json (l_cli_json.get (i)) , 'TYPE')||'<br>');
             end if;
             htp.p('<br><br><br>');

           end LOOP;*/

      ELSE
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_leg05_sd;



   /*Creacion de deuda por ventas leg05
   function  json_int_leg05_deuda (
   v_clase_dcoumento_venta varchar2,
   v_canal_distribucion varchar2,
   v_fecha_entrega varchar2,
   v_fecha_referencia varchar2,
   v_referencia_cliente varchar2,
   v_fecha_documento varchar2,
   v_codigo_material varchar2,
   v_unidad_medida varchar2,
   v_numero_deudor varchar2,
   v_fecha_reparto varchar2,
   v_cantidad_pedida varchar2,
   v_importe_condicion varchar2,
   v_canal_distribucion1 varchar2,
   v_clase_dcoumento_venta1 varchar2,
   v_importe_condicion1 varchar2,
   v_clave_moneda varchar2,
   v_centro_beneficio varchar2

   ) return  varchar2
   is
   begin

    owa_util.mime_header('application/json',false, g_charset);
         OWA_UTIL.http_header_close;

   htp.p('
   {
    "TOKEN": "F70713F194043E7267F88C9C7589944A785444892D10C516DF76A8903E04A9A8",
       "FLAG": "FICA",
          "BAPI_SALESORDER_CREATEFROMDAT2": {
              "ORDER_HEADER_IN": {
                                   "Tipo_objeto"             : "BUS2031",
                                   "Clase_documento"         : "'||v_clase_dcoumento_venta||'",
                                   "Canal_distribucion"      : "'||v_canal_distribucion||'",
                                   "Fecha_entrega"           : "'||v_fecha_entrega||'",
                                   "Fecha_referencia_cliente": "'||v_fecha_referencia||'",
                                   "Referencia_cliente"      : "'||v_referencia_cliente||'",
                                   "Fecha_documento"         : "'||v_fecha_documento||'"
              },
              "ORDER_ITEMS_IN": {
                                   "Posicion_documento"          : "000010",
                                   "Posicion_superior_materiales": "1",
                                   "Numero_material"             : "'||v_codigo_material||'",
                                   "Centro"                      : "UT01",
                                   "Cantidad_prevista"           : "1",
                                   "Unidad_medida"               : "'||v_unidad_medida||'"
              },
              "ORDER_PARTNERS": {
                                   "Funcion_interlocutor": "SO",
                                   "Numero_deudor"       : "'||v_numero_deudor||'",
                                   "Clave_pais"          : "CL",
                                   "Clave_idioma"        : "E"
              },
              "ORDER_SCHEDULES_IN": {
                                   "Posicion_documento": "000010",
                                   "N_reparto"         : "1",
                                   "Fecha_reparto"     : "'||v_fecha_reparto||'",
                                   "Cantidad_pedida"   : "'||v_cantidad_pedida||'"
             },
              "ORDER_CONDITIONS_IN": {
                                   "Numero_posicion_condicion": "000010",
                                   "Clase_condicion"          : "0",
                                   "Importe_condicion"        : "'||v_importe_condicion||'",
                                   "Clave_moneda"             : "CLP",
                                   "Unidad_medida_condicion"  : "CLP"
              },
          },
          "BAPI_BILLINGDOC_CREATEMULTIPLE": {
              "CREATORDATAIN": {
                                     "Creado_por"              : "MHUERTA"
              },
              "BILLINGDATAIN": {
                                   "Organizacion_Ventas"      : "UT01",
                                   "Canal_distribucion"       : "'||v_canal_distribucion1||'",
                                   "Sector"                   : "02",
                                   "Clase_documento"          : "'||v_clase_dcoumento_venta1||'",
                                   "Fecha_factura"            : "20161122",
                                   "Solicitante"              : "0145674093",
                                   "Centro"                   : "UT01",
                                   "MATERIAL"                 : "113",
                                   "Cantidad_pedido_acumulada": "10",
                                   "Documento_ventas"         : "63",
                                   "Posicion_documento"       : "000010",
                                   "Posicion_responsable"     : "000010",
                                   "Nombre_responsable"       : "MHUERTA"
              },
              "CONDITIONDATAIN": {
                                   "Indicador_entrada" : "1",
                                   "Clase_condicion"   : "0",
                                   "Importe_condicion" : "'||v_importe_condicion1||'",
                                   "Moneda_condicion"  : "CLP"
              },
          },
           "BAPI_CTRACDOCUMENT_CREATE": {
                   "ZCLFICA_MF_CREADEUDA":{
                      "GPART": "1",
                      "BLART": "2",
                      "BLDAT": "3",
                      "OPBEL": "4",
                      "OPUPK": "5",
                      "FAEDN": "6",
                      "TOTAL": "7",
                      "TOLOC": "8",
                      "SALDO": "9",
                      "SALOC": "10",
                      "BUKRS": "11",
                      "KOFIZ": "12",
                      "INTLO": "13",
                      "INTER": "14",
                      "CAMBI": "15",
                      "WAERS": "'||v_clave_moneda||'",
                      "MATRI": "17",
                      "PRCTR": "'||v_centro_beneficio||'"
                   }
           }
   }
   ');



   /* separa Descrcion de >> Observacion (:::COMENTARIO ADICIONAL:::)

    "TOKEN": "F70713F194043E7267F88C9C7589944A785444892D10C516DF76A8903E04A9A8",
       "FLAG": "FICA",
          "BAPI_SALESORDER_CREATEFROMDAT2": {
              "ORDER_HEADER_IN": {
                                   "Tipo_objeto"             : "BUS2031" "(":::en documento se llama tipo_de_objeto:::") Tipo objeto en SAP que indica que esa una venta >> Valor fijo BUS2031",
                                   "Clase_documento"         : "'||v_clase_dcoumento_venta||'" "(":::en documento se llama Clase_dcoumento_venta:::") Solicita boleta o factura >> Valores:FACTURA BOLETA",  ,
                                   "Canal_distribucion"      : "'||v_canal_distribucion||'" "Canal de Distribución >> Se obtiene de la consulta crea cliente",
                                   "Fecha_entrega"           : "'||v_fecha_entrega||'" "Corresponde a la fecha entrega >> Valor defecto fecha actual sysdate",
                                   "Fecha_referencia_cliente": "'||v_fecha_referencia||'" "(":::en documento se llama fecha_referencia:::") Fecha del primer vencimiento",
                                   "Referencia_cliente"      : "'||v_referencia_cliente||'" "Referencia del Cliente corresponde al número de orden de compra >> Numero de cupon de pago Aplica solo cerficados imprime cupón y paga en caja",
                                   "Fecha_documento"         : "'||v_fecha_documento||'" "Fecha de generación la deuda >> Fecha actual (sysdate)"
              },
              "ORDER_ITEMS_IN": {
                                   "Posicion_documento"          : "NO ESTA" "000010",
                                   "Posicion_superior_materiales": "1" "(":::en documento se llama posicion_superior:::") Por defecto 1",
                                   "Numero_material"             : "'||v_codigo_material||'" "(":::en documento se llama código_material:::") Código del producto desde SAP >> Se obtiene de la integración de consulta productos",
                                   "Centro"                      : "NO ESTA" "UT01",
                                   "Cantidad_prevista"           : "NO ESTA" "1",
                                   "Unidad_medida"               : "'||v_unidad_medida||'" "Unidad de Medida >> UND C/U"
              },
              "ORDER_PARTNERS": {
                                   "Funcion_interlocutor": "SO" "(":::en documento se llama func_interlocutor:::") Tipo de interlocutor >> Valor por defecto SO: solicitante (Todo mayúscula)",
                                   "Numero_deudor"       : "'||v_numero_deudor||'" "Rut del deudor sin digito verificador >> (":::EN EL EJEMPLO NO SALE UN RUT SI NO ESTE CODIGO 4100000071:::)",
                                   "Clave_pais"          : "CL" "Código del país >> CL: chile",
                                   "Clave_idioma"        : "E" "Idioma >> Valor por defecto E"
              },
              "ORDER_SCHEDULES_IN": {
                                   "Posicion_documento": "NO ESTA" "000010",
                                   "N_reparto"         : "1" "(":::en documento se llama num_reparto:::") Corresponde al número de reparto >> Valor por defecto 1",
                                   "Fecha_reparto"     : "'||v_fecha_reparto||'" "El fecha de reparto >> Por defecto la fecha actual",
                                   "Cantidad_pedida"   : "'||v_cantidad_pedida||'" "13 enteros 3 decimales >> Valor por defecto cantidad"
             },
              "ORDER_CONDITIONS_IN": {
                                   "Numero_posicion_condicion": "NO ESTA" "000010",
                                   "Clase_condicion"          : "0" "Clase de condición >> Valor por defecto ZPR0 Es un cero",
                                   "Importe_condicion"        : "'||v_importe_condicion||'" "Precio unitario",
                                   "Clave_moneda"             : "CLP" "Clave de moneda",
                                   "Unidad_medida_condicion"  : "CLP" "CLP"
              },
          },
          "BAPI_BILLINGDOC_CREATEMULTIPLE": {
              "CREATORDATAIN": {
                                     "Creado_por"              : "NO ESTA" "MHUERTA"
              },
              "BILLINGDATAIN": {
                                   "Organizacion_Ventas"      : "UT01" "(":::en documento se llama org_venta:::") Organización de ventas >> Valor fijo UT01",
                                   "Canal_distribucion"       : "'||v_canal_distribucion1||'" "Canal de Distribución >> Se obtiene de la consulta crea cliente",
                                   "Sector"                   : "02" "Segregación de un medio por el cual se entrega el  >> Valor fijo 02",
                                   "Clase_documento"          : "'||v_clase_dcoumento_venta1||'" "(":::en documento se llama Clase_dcoumento_venta:::") Solicita boleta o factura >> Valores:FACTURA BOLETA",
                                   "Fecha_factura"            : "NO ESTA" "20161122",
                                   "Solicitante"              : "NO ESTA" "0145674093",
                                   "Centro"                   : "NO ESTA" "UT01",
                                   "MATERIAL"                 : "NO ESTA" "113",
                                   "Cantidad_pedido_acumulada": "NO ESTA" "10",
                                   "Documento_ventas"         : "NO ESTA" "63",
                                   "Posicion_documento"       : "000010" "(":::en documento se llama v_pos_doc_venta:::") Posición documento de venta línea  dentro del detalle crece de 10 en 10 >> Valor por defecto 000010",
                                   "Posicion_responsable"     : "NO ESTA" "000010",
                                   "Nombre_responsable"       : "NO ESTA" "MHUERTA"
              },
              "CONDITIONDATAIN": {
                                   "Indicador_entrada" : "NO ESTA" "1",
                                   "Clase_condicion"   : "0" "Clase de condición >> Valor por defecto ZPR0 Es un cero",
                                   "Importe_condicion" : "'||v_importe_condicion1||'" "Precio unitario",
                                   "Moneda_condicion"  : "NO ESTA" "CLP"
              },
          },
           "BAPI_CTRACDOCUMENT_CREATE": {
                   "ZCLFICA_MF_CREADEUDA":{
                      "GPART": "NO ESTA" "1",
                      "BLART": "NO ESTA" "2",
                      "BLDAT": "NO ESTA" "3",
                      "OPBEL": "NO ESTA" "4",
                      "OPUPK": "NO ESTA" "5",
                      "FAEDN": "NO ESTA" "6",
                      "TOTAL": "NO ESTA" "7",
                      "TOLOC": "NO ESTA" "8",
                      "SALDO": "NO ESTA" "9",
                      "SALOC": "NO ESTA" "10",
                      "BUKRS": "NO ESTA" "11",
                      "KOFIZ": "NO ESTA" "12",
                      "INTLO": "NO ESTA" "13",
                      "INTER": "NO ESTA" "14",
                      "CAMBI": "NO ESTA" "15",
                      "WAERS": "'||v_clave_moneda||'" "(":::en documento se el valor era 16 y en el ejemplo era CLP:::")",
                      "MATRI": "NO ESTA" "17",
                      "PRCTR": "'||v_Centro_beneficio||'" "Centro de beneficio >> Cuando es eduacacional, viene de tabla de conversión, en caso contrario se obtiene de la tabla de productos"



   end json_int_leg05_deuda;*/


   /*llamada ayuda estudianti, crea deuda int_leg01*/
   PROCEDURE int_leg01 (v_sociedad                 VARCHAR2,
                        v_fecha_registro           VARCHAR2,
                        v_fecha_contabilizacion    VARCHAR2,
                        v_documento                VARCHAR2,
                        v_nro_resolucion           VARCHAR2,
                        v_codigo_prv               VARCHAR2,
                        v_carrera                  VARCHAR2,
                        v_horas                    VARCHAR2,
                        v_documento_a              VARCHAR2,
                        v_fecha_vencimiento        VARCHAR2,
                        v_via_pago                 VARCHAR2,
                        v_cod_ayuda                VARCHAR2,
                        v_codigo_prv1              VARCHAR2,
                        v_carrera1                 VARCHAR2,
                        v_horas1                   VARCHAR2,
                        v_documento1               VARCHAR2,
                        v_fecha_vencimiento1       VARCHAR2,
                        v_via_pago1                VARCHAR2,
                        v_cod_ayuda1               VARCHAR2,
                        v_cuenta                   VARCHAR2,
                        v_centro_costo             VARCHAR2,
                        v_moneda                   VARCHAR2,
                        v_monto_cuota              VARCHAR2,
                        v_monto_total              VARCHAR2,
                        v_moneda1                  VARCHAR2,
                        v_monto_cuota1             VARCHAR2,
                        v_monto_total1             VARCHAR2,
                        v_moneda2                  VARCHAR2,
                        v_monto_cuota2             VARCHAR2,
                        v_monto_total2             VARCHAR2)
   IS
      v_data   VARCHAR2 (32000);
   BEGIN
      /*http://condor2-19testing.utalca.cl/pls/sap_test/pkg_integra_utal.int_leg01?v_sociedad=UT01&v_fecha_registro=20161121&v_fecha_contabilizacion=20161121&v_documento=Z9&v_nro_resolucion=RU%202016/8978&v_codigo_prv=1300000014&v_carrera=001&v_horas=7&v_documento_a=898888&v_fecha_vencimiento=20161230&v_via_pago=3&v_cod_ayuda=02&v_codigo_prv1=1300000014&v_carrera1=001&v_horas1=7&v_documento1=898888&v_fecha_vencimiento1=20161230&v_via_pago1=3&v_cod_ayuda1=02&v_cuenta=5101070040&v_centro_costo=VAC100001&v_moneda=CLP&v_monto_cuota=200000&v_monto_total=200000&v_moneda1=CLP&v_monto_cuota1=1&v_monto_total1=100000-&v_moneda2=CLP&v_monto_cuota2=100000-&v_monto_total2=100000-*/

      ENCABEZADO ();

      HTP.p (
            '
<script>

var var1= '' "DOCUMENTHEADER": { ''
+'' "Sociedad"             : "'
         || v_sociedad
         || '",              ''
+'' "Fecha_registro"       : "'
         || v_fecha_registro
         || '",        ''
+'' "Fecha_contabilizacion": "'
         || v_fecha_contabilizacion
         || '", ''
+'' "Tipo_documento"       : "'
         || v_documento
         || '",             ''
+'' "Nro_resolucion"       : "'
         || v_nro_resolucion
         || '",        ''
+'' },                                                        ''
+'' "ACCOUNTPAYABLE": {                                       ''
+'' "Codigo_prv"       : "'
         || v_codigo_prv
         || '",                ''
+'' "Carrera"          : "'
         || v_carrera
         || '",                   ''
+'' "Horas"            : "'
         || v_horas
         || '",                     ''
+'' "Documento"        : "'
         || v_documento_a
         || '",               ''
+'' "Fecha_vencimiento": "'
         || v_fecha_vencimiento
         || '",         ''
+'' "Via_pago"         : "'
         || v_via_pago
         || '",                  ''
+'' "Cod_ayuda"        : "'
         || v_cod_ayuda
         || '",                 ''
+'' },                                                        ''
+'' "ACCOUNTPAYABLE": {                                       ''
+'' "Codigo_prv"       : "'
         || v_codigo_prv1
         || '",               ''
+'' "Carrera"          : "'
         || v_carrera1
         || '",                  ''
+'' "Horas"            : "'
         || v_horas1
         || '",                    ''
+'' "Documento"        : "'
         || v_documento1
         || '",                ''
+'' "Fecha_vencimiento": "'
         || v_fecha_vencimiento1
         || '",        ''
+'' "Via_pago"         : "'
         || v_via_pago1
         || '",                 ''
+'' "Cod_ayuda"        : "'
         || v_cod_ayuda1
         || '",                ''
+'' },                                                        ''
+'' "ACCOUNTGL": {                                            ''
+'' "Cuenta"      : "'
         || v_cuenta
         || '",                         ''
+'' "Centro_costo": "'
         || v_centro_costo
         || '",                   ''
+'' },                                                        ''
+'' "CURRENCYAMOUNT": {                                       ''
+'' "Moneda"     : "'
         || v_moneda
         || '",                          ''
+'' "Monto_cuota": "'
         || v_monto_cuota
         || '",                     ''
+'' "Monto_total": "'
         || v_monto_total
         || '",                     ''
+'' },                                                        ''
+'' "CURRENCYAMOUNT": {                                       ''
+'' "Moneda"     : "'
         || v_moneda1
         || '",                         ''
+'' "Monto_cuota": "'
         || v_monto_cuota1
         || '",                    ''
+'' "Monto_total": "'
         || v_monto_total1
         || '",                    ''
+'' },                                                        ''
+'' "CURRENCYAMOUNT": {                                       ''
+'' "Moneda"     : "'
         || v_moneda2
         || '",                         ''
+'' "Monto_cuota": "'
         || v_monto_cuota2
         || '",                    ''
+'' "Monto_total": "'
         || v_monto_total2
         || '",                    ''
+'' },                                                        ''
+'' }                                                         '';


var1.replace("\n"," ");

function crear_deuda_est_sap (){
          $.ajax({
                     url:''http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/FI001/INT_LEG01'',
                     type:''POST'',
                     data:''''+var1+'''',
                     dataType: "json",
                     success:function(response){

                             alert("paso");
                     },
                     error: function(xhr, status, error) {
                                     alert("algo salio bastante mal : " + xhr.responseText)
            }

             });
}

crear_deuda_est_sap ()

</script>

'         );
   /* separa Descrcion de >> Observacion (:::COMENTARIO ADICIONAL:::)

   "DOCUMENTHEADER": {
   "Sociedad"             : "'||v_sociedad||'" "Sociedad Por defecto UT01: Universidad de Talca",
   "Fecha_registro"       : "'||v_fecha_registro||'" "Fecha de registro",
   "Fecha_contabilizacion": "'||v_fecha_contabilizacion||'" "Fecha de contabilización ",
   "Tipo_documento"       : "'||v_documento||'" "Tipo de documento",
   "Nro_resolucion"       : "'||v_nro_resolucion||'" "Número de Resolución"
   },
   "ACCOUNTPAYABLE": {
   "Codigo_prv"       : "'||v_codigo_prv||'" "Rut proveedor, con digito verificador sin guion",
   "Carrera"          : "'||v_carrera||'" "Carrera del alumno",
   "Horas"            : "'||v_horas||'" "Número de horas",
   "Documento"        : "'||v_documento||'" "Documento de enlace con el legado (Matricula, Numero WF)",
   "Fecha_vencimiento": "'||v_fecha_vencimiento||'" "Fecha Vencimiento cuota",
   "Via_pago"         : "'||v_via_pago||'" "Forma de Pago >> 3: Cheque 4. Deposito en cuenta",
   "Cod_ayuda"        : "'||v_cod_ayuda||'" "Código de la ayuda >> Tabla de conversión"
   },
   "ACCOUNTPAYABLE": {    (:::ESTA REPETIDO:::)
   "Codigo_prv"       : "'||v_codigo_prv1||'" "Rut proveedor, con digito verificador sin guion",
   "Carrera"          : "'||v_carrera1||'" "Carrera del alumno",
   "Horas"            : "'||v_horas1||'" "Número de horas",
   "Documento"        : "'||v_documento1||'" "Documento de enlace con el legado (Matricula, Numero WF)",
   "Fecha_vencimiento": "'||v_fecha_vencimiento1||'" "Fecha Vencimiento cuota",
   "Via_pago"         : "'||v_via_pago1||'" "Forma de Pago >> 3: Cheque 4. Deposito en cuenta",
   "Cod_ayuda"        : "'||v_cod_ayuda1||'" "Código de la ayuda >> Tabla de conversión"
   },
   "ACCOUNTGL": {
   "Cuenta"      : "'||v_cuenta||'" "Cuenta contable",
   "Centro_costo": "'||v_centro_costo||'" "Centro de responsabilidad"
   },
   "CURRENCYAMOUNT": {
   "Moneda"     : "'||v_moneda||'" "Moneda, default >> Por defecto CLP",
   "Monto_cuota": "'||v_monto_cuota||'" "Monto Cuota",
   "Monto_total": "'||v_monto_total||'" "Monto total del beneficio"
   },
   "CURRENCYAMOUNT": { (:::ESTA REPETIDO:::)
   "Moneda"     : "'||v_moneda1||'" "Moneda, default >> Por defecto CLP",
   "Monto_cuota": "'||v_monto_cuota1||'" "Monto Cuota",
   "Monto_total": "'||v_monto_total1||'" "Monto total del beneficio"
   },
   "CURRENCYAMOUNT": { (:::ESTA REPETIDO:::)
   "Moneda"     : "'||v_moneda2||'" "Moneda, default >> Por defecto CLP",
   "Monto_cuota": "'||v_monto_cuota2||'" "Monto Cuota",
   "Monto_total": "'||v_monto_total2||'" "Monto total del beneficio"
   */


   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (
               'Error:'
            || SQLERRM
            || ' procedure int_leg01, favor contactar al Administrador');
   END int_leg01;


   /*ayuda estudianti, crea deuda
   function json_int_leg01 (
               v_sociedad varchar2,
               v_fecha_registro varchar2,
               v_fecha_contabilizacion varchar2,
               v_documento varchar2,
               v_nro_resolucion varchar2,
               v_codigo_prv varchar2,
               v_carrera varchar2,
               v_horas varchar2,
               v_documento_a varchar2,
               v_fecha_vencimiento varchar2,
               v_via_pago varchar2,
               v_cod_ayuda varchar2,
               v_codigo_prv1 varchar2,
               v_carrera1 varchar2,
               v_horas1 varchar2,
               v_documento1 varchar2,
               v_fecha_vencimiento1 varchar2,
               v_via_pago1 varchar2,
               v_cod_ayuda1 varchar2,
               v_cuenta varchar2,
               v_centro_costo varchar2,
               v_moneda varchar2,
               v_monto_cuota varchar2,
               v_monto_total varchar2,
               v_moneda1 varchar2,
               v_monto_cuota1 varchar2,
               v_monto_total1 varchar2,
               v_moneda2 varchar2,
               v_monto_cuota2 varchar2,
               v_monto_total2 varchar2
   ) return varchar2
   is
   begin
         owa_util.mime_header('application/json',false, g_charset);
         OWA_UTIL.http_header_close;



   htp.p('{
   "DOCUMENTHEADER": {
   "Sociedad"             : "'||v_sociedad||'",
   "Fecha_registro"       : "'||v_fecha_registro||'",
   "Fecha_contabilizacion": "'||v_fecha_contabilizacion||'",
   "Tipo_documento"       : "'||v_documento||'",
   "Nro_resolucion"       : "'||v_nro_resolucion||'",
   },
   "ACCOUNTPAYABLE": {
   "Codigo_prv"       : "'||v_codigo_prv||'",
   "Carrera"          : "'||v_carrera||'",
   "Horas"            : "'||v_horas||'",
   "Documento"        : "'||v_documento_a||'",
   "Fecha_vencimiento": "'||v_fecha_vencimiento||'",
   "Via_pago"         : "'||v_via_pago||'",
   "Cod_ayuda"        : "'||v_cod_ayuda||'",
   },
   "ACCOUNTPAYABLE": {
   "Codigo_prv"       : "'||v_codigo_prv1||'",
   "Carrera"          : "'||v_carrera1||'",
   "Horas"            : "'||v_horas1||'",
   "Documento"        : "'||v_documento1||'",
   "Fecha_vencimiento": "'||v_fecha_vencimiento1||'",
   "Via_pago"         : "'||v_via_pago1||'",
   "Cod_ayuda"        : "'||v_cod_ayuda1||'",
   },
   "ACCOUNTGL": {
   "Cuenta"      : "'||v_cuenta||'",
   "Centro_costo": "'||v_centro_costo||'",
   },
   "CURRENCYAMOUNT": {
   "Moneda"     : "'||v_moneda||'",
   "Monto_cuota": "'||v_monto_cuota||'",
   "Monto_total": "'||v_monto_total||'",
   },
   "CURRENCYAMOUNT": {
   "Moneda"     : "'||v_moneda1||'",
   "Monto_cuota": "'||v_monto_cuota1||'",
   "Monto_total": "'||v_monto_total1||'",
   },
   "CURRENCYAMOUNT": {
   "Moneda"     : "'||v_moneda2||'",
   "Monto_cuota": "'||v_monto_cuota2||'",
   "Monto_total": "'||v_monto_total2||'",
   },
   }


   ');
    separa Descrcion de >> Observacion (:::COMENTARIO ADICIONAL:::)

   "DOCUMENTHEADER": {
   "Sociedad"             : "'||v_sociedad||'" "Sociedad Por defecto UT01: Universidad de Talca",
   "Fecha_registro"       : "'||v_fecha_registro||'" "Fecha de registro",
   "Fecha_contabilizacion": "'||v_fecha_contabilizacion||'" "Fecha de contabilización ",
   "Tipo_documento"       : "'||v_documento||'" "Tipo de documento",
   "Nro_resolucion"       : "'||v_nro_resolucion||'" "Número de Resolución"
   },
   "ACCOUNTPAYABLE": {
   "Codigo_prv"       : "'||v_codigo_prv||'" "Rut proveedor, con digito verificador sin guion",
   "Carrera"          : "'||v_carrera||'" "Carrera del alumno",
   "Horas"            : "'||v_horas||'" "Número de horas",
   "Documento"        : "'||v_documento||'" "Documento de enlace con el legado (Matricula, Numero WF)",
   "Fecha_vencimiento": "'||v_fecha_vencimiento||'" "Fecha Vencimiento cuota",
   "Via_pago"         : "'||v_via_pago||'" "Forma de Pago >> 3: Cheque 4. Deposito en cuenta",
   "Cod_ayuda"        : "'||v_cod_ayuda||'" "Código de la ayuda >> Tabla de conversión"
   },
   "ACCOUNTPAYABLE": {    (:::ESTA REPETIDO:::)
   "Codigo_prv"       : "'||v_codigo_prv1||'" "Rut proveedor, con digito verificador sin guion",
   "Carrera"          : "'||v_carrera1||'" "Carrera del alumno",
   "Horas"            : "'||v_horas1||'" "Número de horas",
   "Documento"        : "'||v_documento1||'" "Documento de enlace con el legado (Matricula, Numero WF)",
   "Fecha_vencimiento": "'||v_fecha_vencimiento1||'" "Fecha Vencimiento cuota",
   "Via_pago"         : "'||v_via_pago1||'" "Forma de Pago >> 3: Cheque 4. Deposito en cuenta",
   "Cod_ayuda"        : "'||v_cod_ayuda1||'" "Código de la ayuda >> Tabla de conversión"
   },
   "ACCOUNTGL": {
   "Cuenta"      : "'||v_cuenta||'" "Cuenta contable",
   "Centro_costo": "'||v_centro_costo||'" "Centro de responsabilidad"
   },
   "CURRENCYAMOUNT": {
   "Moneda"     : "'||v_moneda||'" "Moneda, default >> Por defecto CLP",
   "Monto_cuota": "'||v_monto_cuota||'" "Monto Cuota",
   "Monto_total": "'||v_monto_total||'" "Monto total del beneficio"
   },
   "CURRENCYAMOUNT": { (:::ESTA REPETIDO:::)
   "Moneda"     : "'||v_moneda1||'" "Moneda, default >> Por defecto CLP",
   "Monto_cuota": "'||v_monto_cuota1||'" "Monto Cuota",
   "Monto_total": "'||v_monto_total1||'" "Monto total del beneficio"
   },
   "CURRENCYAMOUNT": { (:::ESTA REPETIDO:::)
   "Moneda"     : "'||v_moneda2||'" "Moneda, default >> Por defecto CLP",
   "Monto_cuota": "'||v_monto_cuota2||'" "Monto Cuota",
   "Monto_total": "'||v_monto_total2||'" "Monto total del beneficio"


   end json_int_leg01;*/


   FUNCTION int_leg05_json_fica_postgrado (
      p_clase_documento    IN     VARCHAR2,
      p_canal              IN     VARCHAR2,
      p_matricula          IN     VARCHAR2,
      p_codigo_carrera     IN     VARCHAR2,
      p_centro_beneficio   IN     VARCHAR2,
      p_postulacion_id     IN     NUMBER,
      p_rut_alumno         IN     NUMBER,
      p_conf_canal         IN     VARCHAR2,
      p_fecha_documento    IN     VARCHAR2,
      p_ret                   OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg                   OUT VARCHAR2                  --mensaje de error
                                          )
      RETURN json
   IS
      v_line                  CLOB := EMPTY_CLOB ();
      v_line_deuda            VARCHAR2 (32766);
      v_json                  CLOB := EMPTY_CLOB ();
      v_json_arr              CLOB := EMPTY_CLOB ();
      v_respuesta             CLOB;
      v_token                 VARCHAR2 (500);
      l_resp_json             json;
      l_data_json             json;
      l_RETURN_json           json;
      l_data_json_l           json_list;
      v_ret                   VARCHAR2 (20);


      pl_fecha_vencimiento    VARCHAR2 (1000);
      pl_fecha_documento      VARCHAR2 (1000);
      p_numero_material       VARCHAR2 (1000);
      p_numero_deudor         VARCHAR2 (1000);
      p_monto                 VARCHAR2 (1000);
      pl_tipo_documento_sap   VARCHAR2 (1000);

      pl_operacion_op         operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op     operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      pl_centro_gestor        operacion_sub_operacion_sap.centro_gestor_base%TYPE;

      id_log                  NUMBER;
      v_tipo_moneda           VARCHAR2 (10) := 'CLP';

      CURSOR c_deuda_postgrados (
         p_canal_conf    VARCHAR2)
      IS
         SELECT correlativo,
                TO_CHAR (fec_vencimiento, 'yyyymmdd') fecha_documento,
                tipo_documento                        numero_material,
                total_local,
                cuota,
                moneda
           FROM vec_postgrado.cc_documentos
          WHERE     codigo_cli = p_rut_alumno
                AND documento = p_matricula
                AND tipo_documento = p_conf_canal;



      p_nro_cuota             NUMBER;
      pl_observacion          VARCHAR2 (4000);



      TYPE array_t IS VARRAY (20) OF VARCHAR2 (32766);

      array                   array_t := array_t ();

      pl_arr_cuota            NUMBER;
      pl_indice               NUMBER;

      pl_add_coma             NUMBER;

      pl_total_vencidas       NUMBER;

      pl_dias_mes             NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         v_line_deuda := '{
              "TOKEN": "'  || v_token || '",
              "FLAG": "FICA",
              "BAPI_CTRACDOCUMENT_CREATE": {';



         v_line := v_line_deuda;

         p_nro_cuota := 10;

         pl_arr_cuota := 1;
         pl_indice := 1;

         pl_add_coma := 0;


         BEGIN
            SELECT COUNT (*), TRUNC (LAST_DAY (SYSDATE)) - TRUNC (SYSDATE)
              INTO pl_total_vencidas, pl_dias_mes
              FROM vec_postgrado.cc_documentos
             WHERE     codigo_cli = p_rut_alumno
                   AND documento = p_matricula
                   AND tipo_documento = p_conf_canal
                   AND fec_vencimiento < TRUNC (SYSDATE)
            HAVING COUNT (*) > 0;

            IF pl_dias_mes < pl_total_vencidas
            THEN
               pl_fecha_documento :=
                  TO_CHAR (SYSDATE - pl_total_vencidas, 'yyyymmdd');
            ELSE
               pl_fecha_documento := TO_CHAR (SYSDATE, 'yyyymmdd');
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pl_fecha_documento := TO_CHAR (SYSDATE, 'yyyymmdd');
         END;



         FOR r IN c_deuda_postgrados (p_conf_canal)
         LOOP
            BEGIN
               pl_fecha_vencimiento := r.fecha_documento;
               p_numero_material := r.numero_material;
               p_numero_deudor := r.correlativo;
               p_monto := r.total_local;

               -- para control UF
               IF r.moneda = '03'
               THEN
                  v_tipo_moneda := 'UF';
                  p_monto := REPLACE (r.total_local, ',', '.');
               ELSE
                  v_tipo_moneda := 'CLP';
               END IF;

               BEGIN
                  SELECT operacion_op,
                         sub_operacion_op,
                            clase_documento_icon
                         || '-'
                         || nombre_clase_documento
                            obs,
                         centro_gestor_base
                    INTO pl_operacion_op,
                         pl_sub_operacion_op,
                         pl_observacion,
                         pl_centro_gestor
                    FROM operacion_sub_operacion_sap
                   WHERE clase_documento_icon = p_numero_material;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     pl_operacion_op := NULL;
                     pl_sub_operacion_op := NULL;
                     pl_centro_gestor := NULL;
                  WHEN OTHERS
                  THEN
                     pl_operacion_op := NULL;
                     pl_sub_operacion_op := NULL;
                     pl_centro_gestor := NULL;
               END;


               pl_observacion := pl_observacion || '-' || r.cuota;

               BEGIN
                  SELECT sap_id
                    INTO pl_tipo_documento_sap
                    FROM (SELECT UTSAP001.pkg_recursos.RECUPERA_CODIGO_SAP (
                                    2,
                                    2,
                                    NULL,
                                    p_numero_material)
                                    sap_id
                            FROM DUAL)
                   WHERE sap_id IS NOT NULL;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     pl_tipo_documento_sap := '';
                  WHEN OTHERS
                  THEN
                     pl_tipo_documento_sap := '';
               END;


               IF TO_NUMBER (pl_fecha_vencimiento) <
                     TO_NUMBER (pl_fecha_documento)
               THEN
                  pl_fecha_vencimiento := pl_fecha_documento + r.cuota;
               END IF;



               v_line_deuda :=
                     ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                  || p_rut_alumno
                  || '",
                               "Tipo_documento": "'
                  || pl_tipo_documento_sap
                  || '",
                               "Fecha_documento": "'
                  || pl_fecha_documento
                  || '",
                               "Nro_Cuponera": "'
                  || p_numero_deudor
                  || '",
                               "Documento": "",
                               "Cuota": "'
                  || p_nro_cuota
                  || '",
                               "Fecha_vencimiento": "'
                  || pl_fecha_vencimiento
                  || '",
                               "Importe": "'
                  || p_monto
                  || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                  || p_codigo_carrera
                  || '",
                               "Moneda": "'
                  || v_tipo_moneda
                  || '",
                               "Nro_matricula": "'
                  || p_matricula
                  || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                  || pl_operacion_op
                  || '",
                               "Sub_operacion": "'
                  || pl_sub_operacion_op
                  || '",
                               "Descripcion": "'
                  || pl_observacion
                  || '",
                               "Elemento_PEP": "'
                  || pl_centro_gestor
                  || '",
                               "Pagar": ""
                            }';


               IF pl_add_coma > 0
               THEN
                  DBMS_LOB.writeappend (v_line,
                                        LENGTH (',' || v_line_deuda),
                                        ',' || v_line_deuda);
               ELSE
                  DBMS_LOB.writeappend (v_line,
                                        LENGTH (v_line_deuda),
                                        v_line_deuda);
               END IF;

               p_nro_cuota := p_nro_cuota + 10;
               pl_add_coma := pl_add_coma + 1;
            END;
         END LOOP;

         DBMS_LOB.writeappend (v_line, LENGTH ('} }'), '} }');

         DELETE FROM tabla_clob_sap
               WHERE ID = 1;

         INSERT INTO tabla_clob_sap (ID, valor)
              VALUES (1, v_line);

         v_line := EMPTY_CLOB ();

         BEGIN
            SELECT valor
              INTO v_line
              FROM tabla_clob_sap
             WHERE ID = 1;

            v_respuesta :=
               call_url_p_1 (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                             v_line);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                  p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 dato2,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'S',
                            'INTLEG05(CREA DEUDA FICA POSTGRADO)',
                            p_postulacion_id,
                            p_postulacion_id,
                            'Crea deuda POST:',
                            p_rut_alumno,
                            p_msg,
                            SYSDATE);
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json_l := json_list (l_resp_json.get ('Resp'));
               --LEEMOS LAS RESPUESTAS
               --SI EXISTE UNA CON ERROR SE ENVIA ERROR
               v_ret := 'S';
               p_msg := '';

               FOR i IN 1 .. l_data_json_l.COUNT
               LOOP
                  l_data_json := json (l_data_json_l.get (1));
                  v_ret :=
                     lee_json (json (l_data_json_l.get (i)), 'TYPE');

                  IF v_ret = 'E'
                  THEN
                     p_ret := 'E';
                  END IF;

                  --SE CONCATENAN LOS MENSAJES
                  p_msg :=
                        p_msg
                     || lee_json (json (l_data_json_l.get (i)), 'MESSAGE')
                     || '. ';
               END LOOP;
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     l_resp_json := json (v_respuesta);
                     l_data_json := json (l_resp_json.get ('Resp'));
                     p_ret :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'TYPE');
                     p_msg :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'MESSAGE');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_ret := 'E';
                        p_msg :=
                              'Error en el formato de la respuesta 1 : '
                           || SQLERRM;
                        l_data_json := NULL;
                  END;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA DEUDA FICA POSTGRADO)',
                      p_postulacion_id,
                      p_postulacion_id,
                      'Crea deuda POST:',
                      p_rut_alumno,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg := p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA DEUDA FICA POSTGRADO)',
                      p_postulacion_id,
                      p_postulacion_id,
                      'Crea deuda POST:',
                      p_rut_alumno,
                      p_msg,
                      SYSDATE);
   END int_leg05_json_fica_postgrado;



   FUNCTION int_leg05_json_fica_postgradoH (
      p_clase_documento    IN     VARCHAR2,
      p_canal              IN     VARCHAR2,
      p_matricula          IN     VARCHAR2,
      p_codigo_carrera     IN     VARCHAR2,
      p_centro_beneficio   IN     VARCHAR2,
      p_postulacion_id     IN     NUMBER,
      p_rut_alumno         IN     NUMBER,
      p_conf_canal         IN     VARCHAR2,
      p_fecha_documento    IN     VARCHAR2,
      p_ret                   OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg                   OUT VARCHAR2                  --mensaje de error
                                          )
      RETURN json
   IS
      v_line                  VARCHAR2 (32766);
      v_json                  CLOB := EMPTY_CLOB ();

      v_json_arr              CLOB := EMPTY_CLOB ();



      v_respuesta             CLOB;
      v_token                 VARCHAR2 (500);


      l_resp_json             json;
      l_data_json             json;

      l_RETURN_json           json;
      l_data_json_l           json_list;


      pl_fecha_vencimiento    VARCHAR2 (1000);
      pl_fecha_documento      VARCHAR2 (1000);
      p_numero_material       VARCHAR2 (1000);
      p_numero_deudor         VARCHAR2 (1000);
      p_monto                 VARCHAR2 (1000);
      pl_tipo_documento_sap   VARCHAR2 (1000);

      pl_operacion_op         operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op     operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      pl_centro_gestor        operacion_sub_operacion_sap.centro_gestor_base%TYPE;

      id_log                  NUMBER;

      CURSOR c_deuda_postgrados (
         p_canal_conf    VARCHAR2)
      IS
         SELECT correlativo,
                TO_CHAR (fec_vencimiento, 'yyyymmdd') fecha_documento,
                tipo_documento                        numero_material,
                total_local,
                cuota
           FROM vec_postgrado.cc_documentos
          WHERE     codigo_cli = p_rut_alumno
                AND documento = p_matricula
                AND tipo_documento = p_conf_canal;



      p_nro_cuota             NUMBER;
      pl_observacion          VARCHAR2 (4000);



      TYPE array_t IS VARRAY (20) OF VARCHAR2 (32766);

      array                   array_t := array_t ();

      pl_arr_cuota            NUMBER;
      pl_indice               NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         v_line := '{
              "TOKEN": "' || v_token || '",
              "FLAG": "FICA",
              "BAPI_CTRACDOCUMENT_CREATE": {';

         v_json := v_line;


         p_nro_cuota := 10;

         v_line := '';
         pl_arr_cuota := 1;
         pl_indice := 1;

         pl_fecha_documento := TO_CHAR (SYSDATE, 'yyyymmdd');

         FOR r IN c_deuda_postgrados (p_conf_canal)
         LOOP
            BEGIN
               pl_fecha_vencimiento := r.fecha_documento;
               p_numero_material := r.numero_material;
               p_numero_deudor := r.correlativo;
               p_monto := r.total_local;


               BEGIN
                  SELECT operacion_op,
                         sub_operacion_op,
                            clase_documento_icon
                         || '-'
                         || nombre_clase_documento
                            obs,
                         centro_gestor_base
                    INTO pl_operacion_op,
                         pl_sub_operacion_op,
                         pl_observacion,
                         pl_centro_gestor
                    FROM operacion_sub_operacion_sap
                   WHERE clase_documento_icon = p_numero_material;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     pl_operacion_op := NULL;
                     pl_sub_operacion_op := NULL;
                     pl_centro_gestor := NULL;
                  WHEN OTHERS
                  THEN
                     pl_operacion_op := NULL;
                     pl_sub_operacion_op := NULL;
                     pl_centro_gestor := NULL;
               END;


               pl_observacion := pl_observacion || '-' || r.cuota;

               BEGIN
                  SELECT sap_id
                    INTO pl_tipo_documento_sap
                    FROM (SELECT UTSAP001.pkg_recursos.RECUPERA_CODIGO_SAP (
                                    2,
                                    2,
                                    NULL,
                                    p_numero_material)
                                    sap_id
                            FROM DUAL)
                   WHERE sap_id IS NOT NULL;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     pl_tipo_documento_sap := NULL;
                  WHEN OTHERS
                  THEN
                     pl_tipo_documento_sap := NULL;
               END;


               IF TO_NUMBER (pl_fecha_vencimiento) <
                     TO_NUMBER (pl_fecha_documento)
               THEN
                  pl_fecha_vencimiento := pl_fecha_documento;
               END IF;

               IF p_nro_cuota > 10
               THEN
                  v_line := v_line || ',';
               END IF;


               v_line :=
                     v_line
                  || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                  || p_rut_alumno
                  || '",
                               "Tipo_documento": "'
                  || pl_tipo_documento_sap
                  || '",
                               "Fecha_documento": "'
                  || pl_fecha_documento
                  || '",
                               "Nro_Cuponera": "'
                  || p_numero_deudor
                  || '",
                               "Documento": "",
                               "Cuota": "'
                  || p_nro_cuota
                  || '",
                               "Fecha_vencimiento": "'
                  || pl_fecha_vencimiento
                  || '",
                               "Importe": "'
                  || p_monto
                  || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                  || p_codigo_carrera
                  || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                  || p_matricula
                  || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                  || pl_operacion_op
                  || '",
                               "Sub_operacion": "'
                  || pl_sub_operacion_op
                  || '",
                               "Descripcion": "'
                  || pl_observacion
                  || '",
                               "Elemento_PEP": "'
                  || pl_centro_gestor
                  || '",
                               "Pagar": ""
                            }';


               IF pl_arr_cuota = 10
               THEN
                  array.EXTEND ();                                -- Extend it
                  array (pl_indice) := v_line;

                  v_line := '';
                  pl_arr_cuota := 1;

                  pl_indice := pl_indice + 1;
               END IF;

               pl_arr_cuota := pl_arr_cuota + 1;
               p_nro_cuota := p_nro_cuota + 10;
            END;
         END LOOP;


         IF pl_arr_cuota <> 1
         THEN
            array.EXTEND ();                                      -- Extend it
            array (pl_indice) := v_line;
         END IF;



         /*Fin Json de entrada */

         v_line := '} }';


         FOR i IN 1 .. array.COUNT
         LOOP
            v_json_arr := v_json || array (i) || v_line;

            htpPrn (v_json_arr);
         END LOOP;


         p_ret := 'E';
         p_msg := 'Error en el formato de la respuesta 1 : ';
         l_data_json := NULL;
      END IF;

      RETURN l_data_json;
   END int_leg05_json_fica_postgradoH;


   /*llamada crea un un cliente leg04*/
   PROCEDURE int_leg04_13_02_2017 (v_rut                         VARCHAR2,
                                   v_cli_nombres1                VARCHAR2,
                                   v_cli_nombres2                VARCHAR2,
                                   v_cli_direccion               VARCHAR2,
                                   v_cli_numero                  VARCHAR2,
                                   v_cli_codigo_comuna           VARCHAR2,
                                   v_cli_pais                    VARCHAR2,
                                   v_cli_region                  VARCHAR2,
                                   v_cli_email                   VARCHAR2,
                                   v_cli_cuenta                  VARCHAR2,
                                   v_cli_condicion_pago          VARCHAR2,
                                   v_cli_canal_distribucion      VARCHAR2,
                                   v_cli_grupo_cliente           VARCHAR2,
                                   v_cli_esquema_cliente         VARCHAR2,
                                   v_cli_grupo_imputacion        VARCHAR2,
                                   v_cli_clasificacion_fiscal    VARCHAR2)
   IS
      v_data   VARCHAR2 (32000);
   BEGIN
      /*13107260-0*/

      /*http://condor2-19testing.utalca.cl/pls/sap_test/pkg_integra_utal.int_leg04?v_rut=13107260-0&v_cli_nombres1=ALVARO&v_cli_nombres2=RODRIGUEZ&v_cli_direccion=1%20OTE.%20939&v_cli_numero=1&v_cli_codigo_comuna=TALCA&v_cli_pais=CL&v_cli_region=07&v_cli_email=ARODRIGUEZ@ADHOCSYSTEM.CL&v_cli_cuenta=1103010000&v_cli_condicion_pago=D000&v_cli_canal_distribucion=6&v_cli_grupo_cliente=10&v_cli_esquema_cliente=1&v_cli_grupo_imputacion=1&v_cli_clasificacion_fiscal=0*/


      ENCABEZADO ();

      HTP.p (
            '

<script>
$(document).ready(function(){

function crear_cliente_sap (){

var var1 = ''data: { ''
+'' "Token": "853ADF7E713F835946C8116DF081BB3B352EF8162D05B45298E42DE47D5E08F3",''
+'' "data": {                                                                   ''
+'' "SEARCH_TYPE"    : "2",                                                     ''
+'' "SEARCH_ID"      : "3",                                                     ''
+'' "PARTNER_NUMBER" : "0785736508",                                            ''
+'' "CREATION_GROUP" : "ZC01",                                                  ''
+'' "PARTNER_ROLE"   : "FMCA02X",                                               ''
+'' "PARTNER_TIMEDEP": "29991231",                                              ''
+'' "CREATION_NUMBER": "785736508",                                             ''
+'' "TITLE_MEDI"     : "0003",                                                  ''
+'' "NAME_FIRST"     : "'
         || v_cli_nombres1
         || '",                                  ''
+'' "NAME_LAST"      : "'
         || v_cli_nombres2
         || '",                                  ''
+'' "SEX"            : "",                                                      ''
+'' "BU_SORT1_TXT"   : "",                                                      ''
+'' "STREET"         : "'
         || v_cli_direccion
         || '",                                 ''
+'' "HOUSE_NUM1"     :  "'
         || v_cli_numero
         || '",                                   ''
+'' "POST_CODE1"     : "",                                                      ''
+'' "CITY1"          : "'
         || v_cli_codigo_comuna
         || '",                             ''
+'' "COUNTRY"        : "'
         || v_cli_pais
         || '",                                      ''
+'' "REGION"         : "'
         || v_cli_region
         || '",                                    ''
+'' "TEL_NUMBER"     : "S/NUM",                                                 ''
+'' "MOB_NUMBER"     : "S/NUM",                                                 ''
+'' "SMTP_ADDR"      : "'
         || v_cli_email
         || '",                                     ''
+'' "MARITALSTATUS"  : "1",                                                     ''
+'' "NATIONALITY"    : "CL",                                                    ''
+'' "TAXNUMXL"       : "78573650-8",                                            ''
+'' "BPKIND"         : "9010",                                                  ''
+'' "BUKRS"          : "UT01",                                                  ''
+'' "AKONT"          : "'
         || v_cli_cuenta
         || '",                                    ''
+'' "ZTERM"          : "'
         || v_cli_condicion_pago
         || '",                            ''
+'' "ZWELS"          : "1",                                                     ''
+'' "VTWEG"          : "'
         || v_cli_canal_distribucion
         || '",                        ''
+'' "BZIRK"          : "UT001",                                                 ''
+'' "KDGRP"          : "'
         || v_cli_grupo_cliente
         || '",                             ''
+'' "AWAHR"          : "",                                                      ''
+'' "KONDA"          : "1",                                                     ''
+'' "KALKS"          : "'
         || v_cli_esquema_cliente
         || '",                           ''
+'' "VSBED"          : "1",                                                     ''
+'' "KTGRD"          : "'
         || v_cli_grupo_imputacion
         || '",                          ''
+'' "TAXKD"          : "'
         || v_cli_clasificacion_fiscal
         || '",                      ''
+'' "BKVID"          : "",                                                      ''
+'' "BANK_CTRY"      : "",                                                      ''
+'' "BANK_KEY"       : "",                                                      ''
+'' "BANK_ACCT"      : "",                                                      ''
+'' "LF_BUKRS"       : "",                                                      ''
+'' "LF_AKONT"       : "",                                                      ''
+'' "LF_ZTERM"       : "",                                                      ''
+'' "REPRF"          : "",                                                      ''
+'' "LF_ZWELS"       : "",                                                      ''
+'' "WITHT"          : "",                                                      ''
+'' "WT_WITHCD"      : "",                                                      ''
+'' "WT_SUBJCT"      : "",                                                      ''
+'' "EKORG"          : "",                                                      ''
+'' "WAERS"          : "",                                                      ''
+'' "KALSK"          : "",                                                      ''
+'' }                                                                           ''
+'' }                                                                           '';


var1.replace("\n"," ");

$.ajax({
                     url:''http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/SD004/INT_LEG04'',
                     type:''POST'',
                     data:''''+var1+'''',
                     dataType: ''json'',
                     success:function(response){

                             alert("paso");
                     },
                     error: function(xhr, status, error) {
                                     alert("algo salio bastante mal : " + error + status + xhr.responseText)
            }

             });

}

crear_cliente_sap ()




})
</script>
</body>
</html>
'         );
   /*
   separa Descrcion de >> Observacion

   "SEARCH_TYPE"    : "NO ESTA",
   "SEARCH_ID"      : "NO ESTA",
   "PARTNER_NUMBER" : "NO ESTA",
   "CREATION_GROUP" : "NO ESTA",
   "PARTNER_ROLE"   : "NO ESTA",
   "PARTNER_TIMEDEP": "NO ESTA",
   "CREATION_NUMBER": "NO ESTA",
   "TITLE_MEDI"     : "NO ESTA",
   "NAME_FIRST"     : "Nombre de pila del cliente o empresa" v_cli_nombres1,
   "NAME_LAST"      : "Apellidos del cliente o nombre empresa >> 0001 y 0002: Apellido Paterno y Materno 0003: Nombre empresa" v_cli_nombres2,
   "SEX"            : "NO ESTA",
   "BU_SORT1_TXT"   : "NO ESTA",
   "STREET"         : "Dirección completa incluye Villa, Block, Población" v_cli_direccion,
   "HOUSE_NUM1"     : "Número de la casa" v_cli_numero,
   "POST_CODE1"     : "NO ESTA",
   "CITY1"          : "Código comuna SAP" v_cli_codigo_comuna (:::Decia "Talca" y no un codigo:::),
   "COUNTRY"        : "Codigo Pais SAP" v_cli_pais,
   "REGION"         : "Código región SAP" v_cli_región,
   "TEL_NUMBER"     : "NO ESTA",
   "MOB_NUMBER"     : "NO ESTA",
   "SMTP_ADDR"      : "Email del cliente" v_cli_email,
   "MARITALSTATUS"  : "NO ESTA",
   "NATIONALITY"    : "NO ESTA",
   "TAXNUMXL"       : "NO ESTA",
   "BPKIND"         : "NO ESTA",
   "BUKRS"          : "NO ESTA",
   "AKONT"          : "Tipo de cuenta del cliente >> Valores por definir. Nacionales una cuenta y extranjeros, las debe definir amrcela" v_cli_cuenta,
   "ZTERM"          : "Condición de Pago >> Por defecto D000: Contado" v_cli_condicion_pago,
   "ZWELS"          : "NO ESTA",
   "VTWEG"          : "Canal de distribución" v_cli_canal_distribucion,
   "BZIRK"          : "NO ESTA",
   "KDGRP"          : "Grupo cliente >> Tabla Conversion" v_cli_grupo_cliente,
   "AWAHR"          : "NO ESTA",
   "KONDA"          : "NO ESTA",
   "KALKS"          : "Esquema cliente >> Nacional 01 Extranjero 02" v_cli_esquema_cliente,
   "VSBED"          : "NO ESTA",
   "KTGRD"          : "Grupo de imputación >> Nacional 01 Extranjero 02" v_cli_grupo_imputacion,
   "TAXKD"          : "Clasificación Fiscal >> Verificar con marcela, valor por defecto 0 Exento 1 Afecto" v_cli_clasificacion_fiscal,
   "BKVID"          : "NO ESTA",
   "BANK_CTRY"      : "NO ESTA",
   "BANK_KEY"       : "NO ESTA",
   "BANK_ACCT"      : "NO ESTA",
   "LF_BUKRS"       : "NO ESTA",
   "LF_AKONT"       : "NO ESTA",
   "LF_ZTERM"       : "NO ESTA",
   "REPRF"          : "NO ESTA",
   "LF_ZWELS"       : "NO ESTA",
   "WITHT"          : "NO ESTA",
   "WT_WITHCD"      : "NO ESTA",
   "WT_SUBJCT"      : "NO ESTA",
   "EKORG"          : "NO ESTA",
   "WAERS"          : "NO ESTA",
   "KALSK"          : "NO ESTA"

   */

   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (
               'Error:'
            || SQLERRM
            || ' procedure int_leg04, favor contactar al Administrador');
   END int_leg04_13_02_2017;


   /*integracion que crea un un cliente
   function json_int_leg04 (
                       v_rut varchar2,
                       v_cli_nombres1 varchar2,
                       v_cli_nombres2 varchar2,
                       v_cli_direccion varchar2,
                       v_cli_numero varchar2,
                       v_cli_codigo_comuna varchar2,
                       v_cli_pais varchar2,
                       v_cli_region varchar2,
                       v_cli_email varchar2,
                       v_cli_cuenta varchar2,
                       v_cli_condicion_pago varchar2,
                       v_cli_canal_distribucion varchar2,
                       v_cli_grupo_cliente varchar2,
                       v_cli_esquema_cliente varchar2,
                       v_cli_grupo_imputacion varchar2,
                       v_cli_clasificacion_fiscal varchar2
   ) return varchar2   is

   begin


   return ('{
   "Token": "853ADF7E713F835946C8116DF081BB3B352EF8162D05B45298E42DE47D5E08F3",
   "data": {
   "SEARCH_TYPE"    : "2",
   "SEARCH_ID"      : "3",
   "PARTNER_NUMBER" : "0785736508",
   "CREATION_GROUP" : "ZC01",
   "PARTNER_ROLE"   : "FMCA02X",
   "PARTNER_TIMEDEP": "29991231",
   "CREATION_NUMBER": "785736508",
   "TITLE_MEDI"     : "0003",
   "NAME_FIRST"     : "'||v_cli_nombres1||'",
   "NAME_LAST"      : "'||v_cli_nombres2||'",
   "SEX"            : "",
   "BU_SORT1_TXT"   : "",
   "STREET"         : "'||v_cli_direccion||'",
   "HOUSE_NUM1"     :  "'||v_cli_numero||'",
   "POST_CODE1"     : "",
   "CITY1"          : "'||v_cli_codigo_comuna||'",
   "COUNTRY"        : "'||v_cli_pais||'",
   "REGION"         : "'||v_cli_region||'",
   "TEL_NUMBER"     : "S/NUM",
   "MOB_NUMBER"     : "S/NUM",
   "SMTP_ADDR"      : "'||v_cli_email||'",
   "MARITALSTATUS"  : "1",
   "NATIONALITY"    : "CL",
   "TAXNUMXL"       : "78573650-8",
   "BPKIND"         : "9010",
   "BUKRS"          : "UT01",
   "AKONT"          : "'||v_cli_cuenta||'",
   "ZTERM"          : "'||v_cli_condicion_pago||'",
   "ZWELS"          : "1",
   "VTWEG"          : "'||v_cli_canal_distribucion||'",
   "BZIRK"          : "UT001",
   "KDGRP"          : "'||v_cli_grupo_cliente||'",
   "AWAHR"          : "",
   "KONDA"          : "1",
   "KALKS"          : "'||v_cli_esquema_cliente||'",
   "VSBED"          : "1",
   "KTGRD"          : "'||v_cli_grupo_imputacion||'",
   "TAXKD"          : "'||v_cli_clasificacion_fiscal||'",
   "BKVID"          : "",
   "BANK_CTRY"      : "",
   "BANK_KEY"       : "",
   "BANK_ACCT"      : "",
   "LF_BUKRS"       : "",
   "LF_AKONT"       : "",
   "LF_ZTERM"       : "",
   "REPRF"          : "",
   "LF_ZWELS"       : "",
   "WITHT"          : "",
   "WT_WITHCD"      : "",
   "WT_SUBJCT"      : "",
   "EKORG"          : "",
   "WAERS"          : "",
   "KALSK"          : "",
                   }
   }
   ');

   separa Descrcion de >> Observacion

   "SEARCH_TYPE"    : "NO ESTA",
   "SEARCH_ID"      : "NO ESTA",
   "PARTNER_NUMBER" : "NO ESTA",
   "CREATION_GROUP" : "NO ESTA",
   "PARTNER_ROLE"   : "NO ESTA",
   "PARTNER_TIMEDEP": "NO ESTA",
   "CREATION_NUMBER": "NO ESTA",
   "TITLE_MEDI"     : "NO ESTA",
   "NAME_FIRST"     : "Nombre de pila del cliente o empresa" v_cli_nombres1,
   "NAME_LAST"      : "Apellidos del cliente o nombre empresa >> 0001 y 0002: Apellido Paterno y Materno 0003: Nombre empresa" v_cli_nombres2,
   "SEX"            : "NO ESTA",
   "BU_SORT1_TXT"   : "NO ESTA",
   "STREET"         : "Dirección completa incluye Villa, Block, Población" v_cli_direccion,
   "HOUSE_NUM1"     : "Número de la casa" v_cli_numero,
   "POST_CODE1"     : "NO ESTA",
   "CITY1"          : "Código comuna SAP" v_cli_codigo_comuna (:::Decia "Talca" y no un codigo:::),
   "COUNTRY"        : "Codigo Pais SAP" v_cli_pais,
   "REGION"         : "Código región SAP" v_cli_región,
   "TEL_NUMBER"     : "NO ESTA",
   "MOB_NUMBER"     : "NO ESTA",
   "SMTP_ADDR"      : "Email del cliente" v_cli_email,
   "MARITALSTATUS"  : "NO ESTA",
   "NATIONALITY"    : "NO ESTA",
   "TAXNUMXL"       : "NO ESTA",
   "BPKIND"         : "NO ESTA",
   "BUKRS"          : "NO ESTA",
   "AKONT"          : "Tipo de cuenta del cliente >> Valores por definir. Nacionales una cuenta y extranjeros, las debe definir amrcela" v_cli_cuenta,
   "ZTERM"          : "Condición de Pago >> Por defecto D000: Contado" v_cli_condicion_pago,
   "ZWELS"          : "NO ESTA",
   "VTWEG"          : "Canal de distribución" v_cli_canal_distribucion,
   "BZIRK"          : "NO ESTA",
   "KDGRP"          : "Grupo cliente >> Tabla Conversion" v_cli_grupo_cliente,
   "AWAHR"          : "NO ESTA",
   "KONDA"          : "NO ESTA",
   "KALKS"          : "Esquema cliente >> Nacional 01 Extranjero 02" v_cli_esquema_cliente,
   "VSBED"          : "NO ESTA",
   "KTGRD"          : "Grupo de imputación >> Nacional 01 Extranjero 02" v_cli_grupo_imputacion,
   "TAXKD"          : "Clasificación Fiscal >> Verificar con marcela, valor por defecto 0 Exento 1 Afecto" v_cli_clasificacion_fiscal,
   "BKVID"          : "NO ESTA",
   "BANK_CTRY"      : "NO ESTA",
   "BANK_KEY"       : "NO ESTA",
   "BANK_ACCT"      : "NO ESTA",
   "LF_BUKRS"       : "NO ESTA",
   "LF_AKONT"       : "NO ESTA",
   "LF_ZTERM"       : "NO ESTA",
   "REPRF"          : "NO ESTA",
   "LF_ZWELS"       : "NO ESTA",
   "WITHT"          : "NO ESTA",
   "WT_WITHCD"      : "NO ESTA",
   "WT_SUBJCT"      : "NO ESTA",
   "EKORG"          : "NO ESTA",
   "WAERS"          : "NO ESTA",
   "KALSK"          : "NO ESTA"


   end json_int_leg04;*/

   PROCEDURE test_header
   IS
      v_dato             VARCHAR2 (255);
      Resta              NUMBER;

      tiempo_permitido   NUMBER;
   BEGIN
      tiempo_permitido := 0.00005;
      v_dato :=
            v_dato
         || utal_dti.p_encrypt_utal.decrypt_ssn (
               OWA_UTIL.GET_CGI_ENV ('HTTP_AUTHORIZATION'));

      Resta := SYSDATE - TO_DATE (v_dato, 'dd/mm/yyyy hh24:mi:ss');

      IF Resta < tiempo_permitido
      THEN
         HTP.p ('Dato:' || v_dato || ' Resta ' || Resta);
         HTP.p ('fecha:' || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'));
      ELSE
         HTP.p ('Error' || Resta || '*');
      END IF;
   END;


   PROCEDURE Get_json (v_vsql IN VARCHAR2)
   IS
      l_json_clob       CLOB;
      l_json            json;
      l_employee_json   json;
      l_jobs_json       json_list;
      v_sql             VARCHAR2 (32000);
   BEGIN
      --if (get_autorizacion) then
      OWA_UTIL.mime_header ('application/json', FALSE, g_charset);
      OWA_UTIL.http_header_close;

      v_sql := v_vsql;


      l_jobs_json := json_list ();
      l_jobs_json := json_dyn.executeList (v_sql);

      l_json := json ();
      l_json.put ('data', l_jobs_json.to_json_value);
      l_json.HTP ();
   --end if;

   END;

   /*************************************************************************/
   /******************************    PROCEDURES ADHOC***********************/
   /*************************************************************************/

   PROCEDURE Get_ganador_aniversario (p_premio IN VARCHAR2 DEFAULT NULL)
   IS
      v_sql         VARCHAR2 (2000);

      v_nombre      VARCHAR2 (100);
      l_seed        VARCHAR2 (100);
      v_no_pedido   NUMBER;
   BEGIN
      l_seed := TO_CHAR (SYSTIMESTAMP, 'YYYYDDMMHH24MISSFFFF');
      DBMS_RANDOM.seed (val => l_seed);

      UPDATE EVB_PEDIDOS
         SET nombre = REPLACE (nombre, 'Ã¿', 'Ñ'),
             apellidos = REPLACE (apellidos, 'Ã¿', 'Ñ');

      UPDATE EVB_PEDIDOS
         SET nombre = REPLACE (nombre, 'Â´', ' '),
             apellidos = REPLACE (apellidos, 'Â´', ' ');

      UPDATE EVB_PEDIDOS
         SET nombre = REPLACE (nombre, 'Ã', 'Á'),
             apellidos = REPLACE (apellidos, 'Ã', 'Á');

      UPDATE EVB_PEDIDOS
         SET nombre = REPLACE (nombre, 'Ã¿', 'Ú'),
             apellidos = REPLACE (apellidos, 'Ã¿', 'É');

      UPDATE EVB_PEDIDOS
         SET nombre = REPLACE (nombre, 'Ã¿', 'Ó'),
             apellidos = REPLACE (apellidos, 'Ã¿', 'Ó');

      UPDATE EVB_PEDIDOS
         SET nombre = REPLACE (nombre, 'Ã¿', 'Ú'),
             apellidos = REPLACE (apellidos, 'Ã¿', 'Ú');

      COMMIT;


      BEGIN
         SELECT no_pedido
           INTO v_no_pedido
           FROM (  SELECT *
                     FROM EVB_PEDIDOS
                    WHERE NVL (flag_premio, '0') = '0'
                 ORDER BY DBMS_RANDOM.RANDOM)
          WHERE ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_no_pedido := -1;
      END;

      IF p_premio IS NOT NULL
      THEN
         UPDATE EVB_PEDIDOS
            SET flag_premio = SUBSTR (p_premio, 1, 50)
          WHERE no_pedido = v_no_pedido AND ROWNUM = 1;
      END IF;


      v_sql :=
            'SELECT decode(instr(nombre    , '' '' ) , 0 ,nombre    , substr(nombre   ,0, instr(nombre    , '' '' )-1 )) nombre ,
               substr(apellidos, 0, instr(apellidos, '' '')-1)  apellido,
               substr(apellidos, instr(apellidos, '' '')+1)  apellido_m ,
               nombre||'' ''||apellidos as nombre_completo,
               correo_electronico,
               NO_PEDIDO
                FROM     EVB_PEDIDOS
                where no_pedido = '
         || v_no_pedido
         || '
                and   rownum = 1';
      Get_json (v_sql);
   END Get_ganador_aniversario;



   -- Devuelve carrera alumno
   PROCEDURE Get_carrera_alumno (v_rut_est IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (5000);
   BEGIN
      v_sql :=
            'select pra_nombre
              from(
                    select *
                    from vac_estruc.his_sit_alu h
                    where h.alu_rut_n = '''
         || v_rut_est
         || '''
                      and exists (select 1 from vac_estruc.programa_academico p where h.pra_codigo = p.pra_codigo and p.pra_codigo_tipo in (1,2,4,5))
                       order by h.pal_fecha_ingreso desc
                ) a,  vac_estruc.programa_academico
                 where
                 a.pra_codigo=programa_academico.pra_codigo and
              rownum = 1';

      Get_json (v_sql);
   END Get_carrera_alumno;

   -- Devuelve datos de contrato del funcionario
   -- f_int04
   PROCEDURE Get_contratos_funcionario (v_rol_emp    IN VARCHAR2,
                                        v_vigencia   IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_contrato_utsap where rol_emp='''
         || v_rol_emp
         || ''' and vigencia='''
         || v_vigencia
         || ''' ';
      Get_json (v_sql);
   END Get_contratos_funcionario;


   -- Devuelve datos de estudios del funcionario
   -- f_int05
   PROCEDURE Get_estudios_funcionario (v_rol_emp IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where rol_emp='''
         || v_rol_emp
         || ''' ';
      Get_json (v_sql);
   END Get_estudios_funcionario;


   PROCEDURE Get_sit_acad_estudiante (
      v_rut_est       IN VARCHAR2 DEFAULT NULL,
      v_carrera_est   IN VARCHAR2 DEFAULT NULL)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select alu_rut_n, alumno_pkg.sel_nombre(alu_rut_n) nombre,
hist_situacion.his_situacion_actual_fecha(uni_codigo,fac_codigo,esc_codigo,pra_codigo
,pla_codigo,alu_rut_n, pal_fecha_ingreso) fecha,
pal_situacion_academica_actual,
hist_situacion.nombre_situacion(1,pal_situacion_academica_actual) nombre_situacion
from vac_estruc.plan_alu
where alu_rut_n = '''
         || v_rut_est
         || '''
and pra_codigo = '''
         || v_carrera_est
         || '''  ';



      Get_json (v_sql);
   END;

   PROCEDURE llama_json
   IS
      v_token       VARCHAR2 (500);


      l_resp_json   json;
      p_ret         VARCHAR2 (100);
      v_json        VARCHAR2 (32000);
   BEGIN
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E' || SQLERRM;
      END;

       /* v_json:='{ "Token" : "69F77D92CBCE42E7A507F7B3D591482786E7390DFEAA4D1C3AC4C95B1CE37E84",

                             "data" : {   "alumnos" : [ { "rut" : "19389032", "fecha" : "28-07-2017" }]
 }
}';*/



      v_json :=
         '{ "Token" : "69F77D92CBCE42E7A507F7B3D591482786E7390DFEAA4D1C3AC4C95B1CE37E84",

                             "data" : {   "alumnos" : [ { "rut" : "10580692", "fecha" : "03-03-2006" },
                             { "rut" : "10563203", "fecha" : "01-03-2005" },
                             { "rut" : "16997896", "fecha" : "01-03-2007" },
                             { "rut" : "16583752", "fecha" : "01-03-2007" } ]
 }
}'     ;



      /*v_json:='{ "Token"             : "'||v_token||'",

    "data" : {   "alumnos" : [ { "rut" : "10580692", "fecha" : "03-01-2006" },
                               { "rut" : "10563203", "fecha" : "03-01-2005" },
                               { "rut" : "16997896", "fecha" : "03-01-2007" },
                               { "rut" : "16583752", "fecha" : "03-01-2007" } ]


                                           }
                                            }';*/

      -- l_resp_json := json(v_json);
      Get_situaciones_masiva (v_json);
   END;

   PROCEDURE Get_situaciones_masiva (p_json IN VARCHAR2)
   IS
      p_json1           json;
      p_json2           json;
      p_json3           json_list;
      p_json4           json;
      l_resp_json       json;
      l_resp_json2      json;
      l_data_json       json_list;
      l_data_json2      json_list;
      v_sql             VARCHAR2 (32000);
      v_get_json        VARCHAR2 (5000);
      v_get_json1       VARCHAR2 (5000);
      v_get_json2       VARCHAR2 (5000) := '';
      v_respuesta       VARCHAR2 (32000);
      v_respuesta2      VARCHAR2 (32000);
      v_json_final      VARCHAR2 (32000);
      v_rut             VARCHAR2 (5000);
      v_fecha           VARCHAR2 (5000);
      l_json_clob       CLOB;
      l_json            json;
      l_employee_json   json;
      v_sql_sin_datos   VARCHAR2 (5000);
      l_jobs_json       json_list;
      v_json_salida     VARCHAR2 (32000);
      v_1               VARCHAR (20);
      v_2               VARCHAR (20);
   BEGIN
      l_resp_json := json (p_json);
      p_json1 := json (l_resp_json.get ('data'));

      OWA_UTIL.mime_header ('application/json', FALSE, g_charset);
      OWA_UTIL.http_header_close;
      l_jobs_json := json_list ();

      v_1 := '{"data":[';
      -- htp.p(v_1);
      v_respuesta := '';

      FOR i IN 1 .. p_json1.COUNT
      LOOP
         l_data_json := json_list (p_json1.get (i));

         FOR j IN 1 .. l_data_json.COUNT
         LOOP
            v_rut := lee_json (json (l_data_json.get (j)), 'rut');
            v_fecha := lee_json (json (l_data_json.get (j)), 'fecha');

            -- v_sql:=v_sql||consulta_sql(v_rut,v_fecha);
            v_sql := consulta_sql (v_rut, v_fecha);
            -- v_respuesta:=v_sql;

            -- htp.p(v_respuesta||'******<br><br>********');
            -- Get_json(v_respuesta);

            --if (get_autorizacion) then



            l_jobs_json := json_dyn.executeList (v_sql);



            --  v_respuesta2 :=replace(replace(l_jobs_json.to_char(),'[',''),']','');--l_jobs_json.to_char();
            v_respuesta :=
                  v_respuesta
               || REPLACE (REPLACE (l_jobs_json.TO_CHAR (), '[', ''),
                           ']',
                           '');


            --  l_json := json();
            -- l_json.put('data',l_jobs_json.to_json_value);

            --end if;
            IF (j <> l_data_json.COUNT)
            THEN
               v_respuesta := v_respuesta || ',';
            ELSE
               v_respuesta := v_respuesta || '';
            END IF;
         -- htp.p(v_respuesta);
         -- htp.p(replace(replace(v_respuesta,'[',''),']',''));

         END LOOP;
      END LOOP;

      --v_respuesta:=v_sql;
      --Get_json(v_respuesta);
      v_2 := ']}';
      --htp.p(v_2);

      v_respuesta2 := v_1 || v_respuesta || v_2;
      p_json1 := json (v_respuesta2);
      p_json1.HTP ();
   --htp.p(v_respuesta2);

   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END;


   FUNCTION consulta_sql (p_rut IN VARCHAR2, p_fecha IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_sql                            VARCHAR2 (32000);
      alu_rut_n                        VARCHAR2 (32000);
      nombre                           VARCHAR2 (32000);
      fecha                            DATE;
      pra_codigo                       VARCHAR2 (32000);
      pra_nombre                       VARCHAR2 (32000);
      pal_situacion_academica_actual   VARCHAR2 (32000);
      nombre_situacion                 VARCHAR2 (32000);
   BEGIN
      v_sql :=
            'select alu_rut_n, alumno_pkg.sel_nombre(alu_rut_n) nombre, sit_f_resol as fecha,
    a.pra_codigo,programa_academico.pra_nombre,
    sit_codigo as pal_situacion_academica_actual,
    hist_situacion.nombre_situacion(1,sit_codigo) nombre_situacion
from ( select his_sit_alu.*
    from his_sit_alu
    where alu_rut_n ='''
         || p_rut
         || '''
    and trunc(sit_fecha_digit) <= trunc(to_date('''
         || p_fecha
         || ''',''dd-mm-yyyy''))
    and sit_fecha_digit = (select max(sit_fecha_digit)
                   from his_sit_alu
                    where alu_rut_n ='''
         || p_rut
         || '''
                    and trunc(sit_fecha_digit) <= trunc(to_date('''
         || p_fecha
         || ''',''dd-mm-yyyy''))
                )) a,
    programa_academico
where a.pra_codigo=programa_academico.pra_codigo';

      BEGIN
         SELECT alu_rut_n,
                alumno_pkg.sel_nombre (alu_rut_n) nombre,
                sit_f_resol                       AS fecha,
                a.pra_codigo,
                programa_academico.pra_nombre,
                sit_codigo
                   AS pal_situacion_academica_actual,
                hist_situacion.nombre_situacion (1, sit_codigo)
                   nombre_situacion
           INTO alu_rut_n,
                nombre,
                fecha,
                pra_codigo,
                pra_nombre,
                pal_situacion_academica_actual,
                nombre_situacion
           FROM (SELECT his_sit_alu.*
                   FROM his_sit_alu
                  WHERE     alu_rut_n = '' || p_rut || ''
                        AND TRUNC (sit_fecha_digit) <=
                               TRUNC (
                                  TO_DATE ('' || p_fecha || '', 'dd-mm-yyyy'))
                        AND sit_fecha_digit =
                               (SELECT MAX (sit_fecha_digit)
                                  FROM his_sit_alu
                                 WHERE     alu_rut_n = '' || p_rut || ''
                                       AND TRUNC (sit_fecha_digit) <=
                                              TRUNC (
                                                 TO_DATE (
                                                    '' || p_fecha || '',
                                                    'dd-mm-yyyy')))) a,
                programa_academico
          WHERE a.pra_codigo = programa_academico.pra_codigo;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_sql :=
                  'select '
               || p_rut
               || ' alu_rut_n, ''SIN DATOS'' nombre, ''1900-01-01'' fecha,99999 pra_codigo,
             ''SIN DATOS'' pra_nombre, ''SIN DATOS'' pal_situacion_academica_actual, ''SIN DATOS'' nombre_situacion
             from dual';
      END;

      RETURN v_sql;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END;

   PROCEDURE Get_situacion_acad_fecha (v_rut_est   IN VARCHAR2,
                                       v_fecha     IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            ' select alu_rut_n, alumno_pkg.sel_nombre(alu_rut_n) nombre,
sit_f_resol as fecha,a.pra_codigo,programa_academico.pra_nombre,
sit_codigo as pal_situacion_academica_actual,
hist_situacion.nombre_situacion(1,sit_codigo) nombre_situacion
 from (
select his_sit_alu.* from his_sit_alu
where alu_rut_n='''
         || v_rut_est
         || '''
and  trunc(sit_f_resol) <= trunc(to_date('''
         || v_fecha
         || ''',''dd-mm_yyyy''))
order by sit_ano_afecta desc, pal_fecha_ingreso desc
) a, programa_academico
where
a.pra_codigo=programa_academico.pra_codigo and
rownum=1';
      --htp.p(v_sql);
      Get_json (v_sql);
   END;



   PROCEDURE Get_deuda_biblioteca (p_id IN VARCHAR2 DEFAULT NULL)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from V_REM_DEUDAS_BIBLIOTECA db where  trim(db.id) = trim(nvl('''
         || p_id
         || ''' , db.id))  ';
      --htp.p(v_sql);

      Get_json (v_sql);
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END;

   PROCEDURE Get_situaciones_estudiante (v_rut_est IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select alu_rut_n, alumno_pkg.sel_nombre(alu_rut_n) nombre,pa.pra_codigo,p.pra_nombre,
hist_situacion.his_situacion_actual_fecha(pa.uni_codigo,pa.fac_codigo,pa.esc_codigo
,pa.pra_codigo,pa.pla_codigo,pa.alu_rut_n, pa.pal_fecha_ingreso) fecha,
pal_situacion_academica_actual,
hist_situacion.nombre_situacion(1,pal_situacion_academica_actual) nombre_situacion
from vac_estruc.plan_alu pa, vac_estruc.programa_academico p
where pa.pra_codigo = p.pra_codigo
and   alu_rut_n = '''
         || v_rut_est
         || '''  ';
      --htp.p(v_sql);
      Get_json (v_sql);
   END;

   -- f_int05
   PROCEDURE Get_deuda_estudiante (v_rut_est          IN VARCHAR2,
                                   v_tipo_documento   IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      /*SQL ORIGINAL*/
      v_sql :=
            'select trim(a.tipo_documento) as tipo_documento,fec_recepcion,c.moneda as tipo_moneda,a.documento,nvl(carrera,''0'') as carrera,
           b.tipo_documento,nmb_documento,a.ano,a.cuota,a.saldo as monto,
           decode(c.moneda,''03'',c.simbolo,decode(c.moneda,''04'',c.simbolo,c.nombre)) moneda,
           0 monto_pesos,intereses interes,to_char(a.fec_vencimiento,''dd/mm/yyyy'') as fec_vencimiento,
           a.saldo as total_pagar,nvl(a.correlativo,0) correlativo
    from utalca.cc_documentos a, utalca.CT_TIPO_DOCUMENTO b, utalca.cg_moneda c
    where a.saldo>0
    and b.AUXILIAR=''CXC''
    AND b.EMPRESA=10
    and a.empresa=b.empresa
    and a.tipo_documento=b.tipo_documento
    and a.tipo_documento='''
         || v_tipo_documento
         || '''
    and a.moneda=c.moneda
    and a.codigo_cli='''
         || v_rut_est
         || '''
    order by nmb_documento,a.ano,a.cuota ';

      /*SQL TEMPORAL ADAPTADA*/
      v_sql :=
            'select trim(a.tipo_documento) as tipo_documento,fec_recepcion,c.moneda as tipo_moneda,a.documento,nvl(carrera,''0'') as carrera,
           b.tipo_documento,nmb_documento,a.ano,a.cuota, decode(c.moneda,''04'',(a.saldo*28500),a.saldo) as monto,
           ''PESOS'' moneda,
           0 monto_pesos,intereses interes,to_char(a.fec_vencimiento,''dd/mm/yyyy'') as fec_vencimiento,
           decode(c.moneda,''04'',(a.saldo*28500),a.saldo) as total_pagar,nvl(a.correlativo,0) correlativo
    from utalca.cc_documentos a, utalca.CT_TIPO_DOCUMENTO b, utalca.cg_moneda c
    where a.saldo>0
    and b.AUXILIAR=''CXC''
    AND b.EMPRESA=10
    and a.empresa=b.empresa
    and a.tipo_documento=b.tipo_documento
    and a.tipo_documento='''
         || v_tipo_documento
         || '''
    and a.moneda=c.moneda
    and a.codigo_cli='''
         || v_rut_est
         || '''
    order by nmb_documento,a.ano,a.cuota ';

      --htp.p(v_sql);
      Get_json (v_sql);
   END Get_deuda_estudiante;


   -- Devuelve datos de previsión del funcionario
   -- f_int06
   PROCEDURE Get_prevision_funcionario (v_rol_emp    IN VARCHAR2,
                                        v_vigencia   IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where rol_emp='''
         || v_rol_emp
         || ''' and vigencia='''
         || v_vigencia
         || ''' ';
      Get_json (v_sql);
   END Get_prevision_funcionario;


   -- deuda institucional
   PROCEDURE Get_deuda_institucional (v_rut IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            ' select c.descripcion as tipo_de_credito,a.ano,a.matricula,decode(a.moneda,''02'',''04'',decode(a.moneda,''03'',''03'')) as moneda,
                        nvl(vec_cob01.interes_institucionales(a.ano, to_number(to_char(sysdate,''yyyy'')),a.monto_actual),0) monto
                        from utalca.ci_documentos a, utalca.cg_moneda b, utalca.ci_tipo_credito c
                        where a.estado<>''P''
                              and decode(a.moneda,''02'',''04'',decode(a.moneda,''03'',''03''))=b.moneda
                              and a.tipo_credito=c.codigo
                              and rut = '
         || v_rut
         || '
                              order by a.ano asc';

      Get_json (v_sql);
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (
               'Error:'
            || SQLERRM
            || ' procedure Get_deuda_institucional, favor contactar al Administrador'
            || v_sql);
   END Get_deuda_institucional;


   -- utm
   PROCEDURE Get_indicador_utm
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
         '  select valor
                  from utalca.cg_moneda_cambio
                  where fecha in (select max(fecha) from utalca.cg_moneda_cambio where moneda = ''04'')
                  and moneda=''04'' ';

      Get_json (v_sql);
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (
               'Error:'
            || SQLERRM
            || ' procedure Get_indicador, favor contactar al Administrador'
            || v_sql);
   END Get_indicador_utm;

   -- uf
   PROCEDURE Get_indicador_uf
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
         ' select valor
                      from utalca.cg_moneda_cambio
                      where fecha in (select max(fecha) from utalca.cg_moneda_cambio where moneda = ''03'')
                      and moneda=''03''';

      Get_json (v_sql);
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (
               'Error:'
            || SQLERRM
            || ' procedure Get_indicador_uf, favor contactar al Administrador'
            || v_sql);
   END Get_indicador_uf;



   -- Devuelve listado de todas las licencias médicas del funcionario
   -- f_int07
   PROCEDURE Get_licencias_funcionario (v_rol_emp   IN VARCHAR2,
                                        v_agno      IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where rol_emp='''
         || v_rol_emp
         || ''' and agno='''
         || v_agno
         || ''' ';
      Get_json (v_sql);
   END Get_licencias_funcionario;


   -- Devuelve datos de unidad del contrato de funcionario
   -- f_int08
   PROCEDURE Get_unidad_funcionario (v_rol_emp IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where rol_emp='''
         || v_rol_emp
         || ''' ';
      Get_json (v_sql);
   END Get_unidad_funcionario;


   -- Datos del Paciente/Alumno/Proveedor

   PROCEDURE Get_clientes (v_rut IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      --ejemplos  8024316 76129865
      v_sql :=
            'select Rut, Dvr,Nombre,Direccion,Comuna,Ciudad,Region,Telefono,Email,''RB-001'' Rubro from utalca.ct_entidad
where rut='''
         || v_rut
         || ''' ';

      Get_json (v_sql);
   END Get_clientes;

   -- Datos de la deuda

   PROCEDURE Get_datos_deuda (v_rut IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      --ejemplos  15222778
      v_sql :=
            'select codigo_cli Rut, utalca.calcula_digito(codigo_cli) dv,
cuota, saldo_local Monto, sysdate Fecha_vencimiento, ''FCI100001'' Centro_costo,
''12121001001'' Cuenta,''10020011001'' Tarea,Tipo_documento,
documento, sysdate Fecha_registro from utalca.cc_documentos
where saldo_local>0
and codigo_cli='''
         || v_rut
         || ''' and cuota=1';

      Get_json (v_sql);
   END Get_datos_deuda;


   -- Datos de Biblioteca
   PROCEDURE Get_datos_biblioteca (v_rut IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      --ejemplos  8024316 76129865
      v_sql := 'SELECT ALEPH_KEY, ESTADO, ID,TIPO,
ITEM_COD_BAR,SUB_BIB, VALOR,FECHA, TITULO FROM UTBIB01.T_PENDIENTES
WHERE trim(ID)=''' || v_rut || '''
AND ESTADO=''AP'' ';

      Get_json (v_sql);
   --htp.p(v_sql);

   END Get_datos_biblioteca;


   PROCEDURE Get_pago_fscu (v_rut IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      --ejemplos  8024316 76129865
      v_sql := 'select  Rut,Cod_deuda,
Cod_acreedor,Cod_estado_deuda,
Correlativo,Monto_utm, numero_subcuota cuota, Monto_utm*45000 Capital_pesos,
0 Int_normal, 0 Int_penal, Monto_utm*45000 Total_pesos,
fecha_vencto Fecha_pago,ano_cuenta Ano_cuota
from fscuprod.cartola where numero_subcuota=1
and ano_cuenta=2015 and rut=''' || v_rut || ''' ';

      Get_json (v_sql);
   END Get_pago_fscu;


   /*indica que tipo de pago tiene asociado un pago de alumno webpay etc..*/
   PROCEDURE Get_pago_convenios (v_tipo_convenio     IN VARCHAR2,
                                 v_nombre_convenio   IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select count(*) cantidad
                  from pop_convenios
                  where conv_tipo_documento='''
         || v_tipo_convenio
         || ''' and
                        conv_nombre_convenio='''
         || v_nombre_convenio
         || ''' and
                        conv_estado=''A'' ';

      Get_json (v_sql);
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (
               'Error:'
            || SQLERRM
            || ' procedure Get_pago_convenios, favor contactar al Administrador'
            || v_sql);
   END Get_pago_convenios;


   -- Devuelve Datos de las deudas asociadas al alumno.
   -- F2_int01
   PROCEDURE Get_saldo_alumno (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' ';
      Get_json (v_sql);
   END Get_saldo_alumno;


   -- Devuelve Datos de las deudas por año asociadas al alumno.
   -- F2_int02
   PROCEDURE Get_saldo_agno_alumno (v_codigo_cli   IN VARCHAR2,
                                    v_ano          IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' and ano='''
         || v_ano
         || ''' ';
      Get_json (v_sql);
   END Get_saldo_agno_alumno;


   -- Devuelve Datos de la cuenta de pago asociada al alumno.
   -- F2_int03
   PROCEDURE Get_cuenta_alumno (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' ';
      Get_json (v_sql);
   END Get_cuenta_alumno;


   -- Devuelve todos los Datos personales del alumno.
   -- F2_int04
   PROCEDURE Get_datos_alumno (v_rut_est IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select alu_rut_n,alu_rut_v,alu_nombre from vac_estruc.alumno where alu_rut_n='''
         || v_rut_est
         || ''' ';
      Get_json (v_sql);
   END Get_datos_alumno;


   -- Devuelve los Datos del valor del trámite de título del alumno.
   -- F2_int05
   PROCEDURE Get_precio_titulo_alumno (v_codigo_cli   IN VARCHAR2,
                                       v_ano          IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' and ano='''
         || v_ano
         || ''' ';
      Get_json (v_sql);
   END Get_precio_titulo_alumno;


   -- Devuelve monto de disponibilidad presupuestaria del fondo.
   -- F3_int01
   PROCEDURE Get_fondo_presupuesto (v_Centro_costo   IN VARCHAR2,
                                    v_Cuenta         IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where Centro_costo='''
         || v_Centro_costo
         || ''' and Cuenta='''
         || v_Cuenta
         || ''' ';
      Get_json (v_sql);
   END Get_fondo_presupuesto;


   -- Devuelve monto de disponibilidad presupuestaria de la licitación.
   -- F3_int02
   PROCEDURE Get_licitacion_presupuesto (v_Centro_costo   IN VARCHAR2,
                                         v_Cuenta         IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where Centro_costo='''
         || v_Centro_costo
         || ''' and Cuenta='''
         || v_Cuenta
         || ''' ';
      Get_json (v_sql);
   END Get_licitacion_presupuesto;


   -- Devuelve nombre de beneficio beca asociado al alumno.
   -- F4_int01
   PROCEDURE Get_tipo_doc_beneficios (v_Tipo_documento IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where Tipo_documento='''
         || v_Tipo_documento
         || ''' ';
      Get_json (v_sql);
   END Get_tipo_doc_beneficios;


   -- Devuelve datos de la renta del empleado para bienestar.
   -- F4_int02
   PROCEDURE Get_renta_personal (v_rol_emp IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where rol_emp='''
         || v_rol_emp
         || ''' ';
      Get_json (v_sql);
   END Get_renta_personal;


   -- Devuelve todos los datos de beneficio beca asociado al alumno.
   -- F4_int03
   PROCEDURE Get_DATOS_doc_beneficios (v_Tipo_documento IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where Tipo_documento='''
         || v_Tipo_documento
         || ''' ';
      Get_json (v_sql);
   END Get_DATOS_doc_beneficios;


   -- Devuelve nombre del centro costos del postulante a postgrado.
   -- F5_int01
   PROCEDURE Get_nombre_centro_postulacion (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' ';
      Get_json (v_sql);
   END Get_nombre_centro_postulacion;


   -- Devuelve datos del centro costos del postulante a postgrado.
   -- F5_int02
   PROCEDURE Get_datos_centro_postulacion (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' ';
      Get_json (v_sql);
   END Get_datos_centro_postulacion;


   -- Devuelve los datos pago como el tipo documento y monto a cancelar del cliente.
   -- F6_int01
   PROCEDURE Get_pago_alumno (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' ';
      Get_json (v_sql);
   END Get_pago_alumno;


   -- Devuelve los datos de documentos por rendir para un centro en específico.
   -- F7_int01
   PROCEDURE Get_rendicion_pendiente (v_Codigo_prv IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where Codigo_prv='''
         || v_Codigo_prv
         || ''' ';
      Get_json (v_sql);
   END Get_rendicion_pendiente;


   -- Devuelve los datos de deudas de pagarés FSCU del cliente.
   -- F8_int01
   PROCEDURE Get_pagares_alumno (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            ' select ano,carrera,matricula,vec_cob01.interes_fscu(ano, to_number(to_char(sysdate,''yyyy'')), '
         || '               nvl(monto_utm,0)) monto_utm, '
         || '               monto monto_pesos, monto_carrera,folio '
         || '        FROM utalca.cc_credito '
         || '        WHERE RUT = '
         || v_codigo_cli
         || '              and carga=''S'' '
         || '              and NVL(monto_utm,0)>0 '
         || '        order by ano ';

      Get_json (v_sql);
   END Get_pagares_alumno;


   -- Devuelve nombre del alumno.
   -- F10_int01
   PROCEDURE Get_nombre_alumno (v_codigo_cli IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_cli='''
         || v_codigo_cli
         || ''' ';
      Get_json (v_sql);
   END Get_nombre_alumno;


   PROCEDURE Get_web_token
   IS
      v_sql     VARCHAR2 (2000);
      p_clave   VARCHAR2 (100) := 'SAPUTALCA';
   BEGIN
      v_sql :=
            'select utal_dti.p_encrypt_utal.encrypt_ssn_sap('''
         || p_clave
         || '''  ||to_char(sysdate,''dd/mm/yyyy hh24:mi:ss'')) as dato_encriptado from dual';
      --htp.p(v_sql);
      Get_json (v_sql);
   END;


   PROCEDURE desencriptar_web_token (p_token VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select utal_dti.p_encrypt_utal.decrypt_ssn('''
         || p_token
         || ''') as dato_desencriptado from dual';
      --htp.p(v_sql);
      Get_json (v_sql);
   END;

   -- Devuelve todos los datos de productos.
   -- F11_int01
   PROCEDURE Get_datos_productos (v_codigo_producto IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where codigo_producto='''
         || v_codigo_producto
         || ''' ';
      Get_json (v_sql);
   END Get_datos_productos;

   -- Devuelve Datos personales del funcionario correspondiente a la rem_ficha
   -- f_int01
   PROCEDURE Get_datos_funcionario (v_rol_emp IN VARCHAR2)
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      v_sql :=
            'select * from v_rem_ficha_utsap where rol_emp='''
         || v_rol_emp
         || ''' ';
      Get_json (v_sql);
   END Get_datos_funcionario;

   -- evuelve datos de la estructura  organizacional del funcionario
   -- f_int02
   FUNCTION Get_nombre_funcionario (v_rol_emp IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_sql   VARCHAR2 (2000);
   BEGIN
      --select nombre into v_sql from v_rem_ficha_utsap where rol_emp=''||v_rol_emp||'' ;
      RETURN (v_sql);
   END;



   PROCEDURE ENCABEZADO
   IS
   BEGIN
      HTP.P (
         '

<html>
<head>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
</head>
<body>



'         );
   END;



   /*************************************************************************/
   /******************************FIN PROCEDURES ADHOC***********************/
   /*************************************************************************/



   PROCEDURE SOL_HEADER
   IS
   BEGIN
      HTP.p (SYS_CONTEXT ('USERENV', 'IP_ADDRESS', 15));

      HTP.P (
            '
<!DOCTYPE html>
<html>
<head>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script>

var autorizacion="'
         || utal_dti.p_encrypt_utal.encrypt_ssn (
               TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
         || '";
$(document).ready(function(){
    $("button").click(function(){
        $.ajax({
        url: "pkg_integra_utal.test_header",
        beforeSend: function(xhr){xhr.setRequestHeader(''Authorization'', autorizacion);},

        success: function(result){
            $("#div1").html(result);
        }});
    });
});
</script>
</head>
<body>

<div id="div1"><h2>Let jQuery AJAX Change This Text</h2></div>

<button>Get External Content</button>

</body>
</html>

'         );
   END;


   PROCEDURE pago_inst_financieras (p_rut                   NUMBER,
                                    p_banco                 VARCHAR2,
                                    p_num_op                VARCHAR2,
                                    p_fecha_pago            VARCHAR2,
                                    p_estado                VARCHAR2,
                                    p_rut_usuario           VARCHAR2,
                                    p_fecha_registro        DATE,
                                    param_tipo_documento    VARCHAR2,
                                    param_ano               NUMBER/*p_NRO_DOCUMENTO varchar2,
                                                                  p_ano number,
                                                                  p_cuota number,
                                                                  p_fecha_pago date,
                                                                  p_monto_recaudar number,
                                                                  p_total_pagado number,
                                                                  p_monto_recargo number,
                                                                  p_tipo_documento varchar2,
                                                                  p_caja varchar2,
                                                                  p_estado varchar2,
                                                                  p_rut_usuario number,
                                                                  p_fecha_registro date,
                                                                  p_nro_operacion number,
                                                                  p_correlativo_doc number,
                                                                  p_correlativo_sap number,
                                                                  p_contador number*/
                                    )
   IS
      --p_codigo_cli            varchar2(1000):=p_idcliente;
      p_tipo_documento          VARCHAR2 (1000);
      p_fecha_documento         VARCHAR2 (1000);
      --p_fecha_documento      date;
      p_cuponera                VARCHAR2 (1000);
      p_documento               VARCHAR2 (1000);
      p_cuota                   VARCHAR2 (1000);
      p_fecha_vencimiento       VARCHAR2 (1000);
      p_monto_local             VARCHAR2 (1000);
      p_empresa                 VARCHAR2 (1000);
      p_carrera                 VARCHAR2 (1000);
      p_moneda                  VARCHAR2 (1000);
      p_nro_matricula           VARCHAR2 (1000);
      p_centro_beneficio        VARCHAR2 (1000);
      p_monto                   VARCHAR2 (1000);
      p_ano                     VARCHAR2 (100);
      v_fecha_pago              DATE;
      v_fecha_registro          DATE;
      v_matricula               VARCHAR2 (100);



      v_json                    VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta               CLOB;
      v_token                   VARCHAR2 (500);
      v_codigo_error            VARCHAR2 (5000);
      v_mensaje_error           VARCHAR2 (5000);
      v_fecha_error             DATE;
      v_contador                NUMBER (10) := 0;
      v_insert                  VARCHAR2 (5000);
      v_correlativo_sap         NUMBER (10);
      v_descripcion             VARCHAR2 (5000);
      v_fecha_venc              VARCHAR2 (5000);
      v_fecha_doc               VARCHAR2 (5000);
      v_correlativo             NUMBER (5);
      v_carrera_sap             VARCHAR (10);
      v_tipo_doc_sap            VARCHAR (200);
      v_Codigo_cli              VARCHAR2 (1000) := '';
      v_Empresa                 VARCHAR2 (1000) := '';
      v_Cuenta_Contrato         VARCHAR2 (1000) := '';
      v_Tipo_Cuenta_Contrato    VARCHAR2 (1000) := '';
      v_Objeto_Contrato         VARCHAR2 (1000) := '';
      v_Clase_Objeto_Contrato   VARCHAR2 (1000) := '';
      v_Tipo_Documento          VARCHAR2 (1000) := '';
      v_Documento               VARCHAR2 (1000) := '';
      v_Cuota                   VARCHAR2 (1000) := '';
      v_Posicion_Interes        VARCHAR2 (1000) := '';
      v_Fecha_Vencimiento       VARCHAR2 (1000) := '';
      v_Fecha_Documento         VARCHAR2 (1000) := '';
      v_Total                   VARCHAR2 (1000) := '';
      v_Total_Local             VARCHAR2 (100);
      v_Saldo                   VARCHAR2 (1000) := '';
      v_Saldo_Local             VARCHAR2 (1000) := '';
      v_Carrera                 VARCHAR2 (1000) := '';
      v_Intereses_Local         VARCHAR2 (1000) := '';
      v_Interes                 VARCHAR2 (1000) := '';
      v_Valor_de_Cambio         VARCHAR2 (1000) := '';
      v_Moneda                  VARCHAR2 (1000) := '';
      v_tipo_doc                VARCHAR2 (1000) := '';
      v_Centro_Beneficio        VARCHAR2 (1000) := '';
      v_Centro_Gestor           VARCHAR2 (1000) := '';
      v_Clave_Estadistica       VARCHAR2 (1000) := '';
      v_Nro_Matricula           VARCHAR2 (100) := '';
      v_Cuota_paso              VARCHAR2 (10) := '-1'; --para eviar que se repita la cuota, solo mientra en SAP arreglan el issue i.villaseca
      l_cli_json                json_list;
      v_ret                     VARCHAR2 (10);
      v_msg                     VARCHAR2 (5000);
      v_error                   VARCHAR2 (15000);
      contador_deudas           NUMBER (10);
      fec_vencimiento           DATE;
      fec_doc                   DATE;

      --cursor de deudas en tabla temporal, agrupada por tipo
      /* DESCOMENTAR UNA VEZ CARGADOS LOS ARCHIVOS DEL BANCO
        cursor c_deudas_actuales(p_idcliente numeric) is

            select distinct pade_tipo_documento
             from VEC_COB01.pop_pagos_detalle_temp_sap a
             where pa_rut=p_idcliente
             and PA_NRO_OPERACION=p_num_op;

        --cursor de deudas en tabla temporal que forma el json
        cursor c_deudas_actuales_detalle (p_tipo_doc varchar2) is

            select *
             from VEC_COB01.pop_pagos_detalle_temp_sap a
             where pa_rut=p_rut
             and pade_tipo_documento =  p_tipo_doc
             and PA_NRO_OPERACION=p_num_op;*/



      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM VEC_COB01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND PA_NRO_OPERACION = p_num_op;

      --cursor de deudas en tabla temporal que forma el json

      --cursor c_deudas_actuales_detalle (p_tipo_doc varchar2) is
      CURSOR c_deudas_actuales_detalle (
         p_idcliente    NUMERIC,
         num_ope        VARCHAR2,
         p_tipo_doc     VARCHAR2)
      IS
         SELECT *
           FROM VEC_COB01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND PA_NRO_OPERACION = num_ope;
   /*select pa_rut rut,pade_nro_documento nro_documento,pade_nro_carrera carrera,pade_fec_vencimiento fec_vencimiento
   from vec_cob01.pop_pagos_detalle_temp
   where pa_nro_operacion=nro_cupon;*/

   /*cursor deudas_SAP is

   select b.FEC_VENCIMIENTO FEC_VENCIMIENTO,b.cuota cuota
   from TMP_DEUDAS_SAP a,TMP_DEUDAS_SAP b
   where a.rut=b.CODIGO_CLI
   and a.cuota=b.cuota;
   --and a.tipo_documento
   order by a.FEC_VENCIMIENTO asc;
   */


   BEGIN
      --utsap001.pkg_recursos.recupera_codigo_sap(1, 10, '', alu_comuna_origen_alu)
      -- utsap001.pkg_recursos.recupera_codigo_sap(1, 10, '', alu_comuna_origen_alu)

      IF (p_banco = 'SANT')
      THEN
         vec_cob01.portaldepagos.deudas_vigentes_json (p_rut);



         --FOR reg_grupo In c_deudas_actuales(p_rut)
         --             LOOP
         v_tipo_doc_sap :=
            pkg_recursos.RECUPERA_CODIGO_SAP (2,
                                              2,
                                              NULL,
                                              param_tipo_documento);

         FOR reg
            IN c_deudas_actuales_detalle (p_rut, p_num_op, v_tipo_doc_sap)
         LOOP
            p_tipo_documento := 'Y3'; -- reg.pade_tipo_documento; se agrego Z2 a solicitud del cliente
            p_fecha_documento := p_fecha_pago; --to_char(sysdate,'YYYYMMDD');--reg.pade_fec_vencimiento; -- no se cual es el campo
            p_cuponera := reg.pa_nro_operacion;      -- no se cual es el campo
            p_documento := reg.pade_nro_documento;
            p_cuota := reg.pade_cuota;
            p_fecha_vencimiento := reg.pade_fec_vencimiento;
            p_monto_local := reg.pade_monto_local;
            p_empresa := 'UT01'; -- 10 no se cual es el campo se agrego UT01 a solicitud del cliente
            p_carrera := reg.pade_nro_carrera; --pkg_recursos.RECUPERA_CODIGO_SAP(2,1,NULL, reg.pade_nro_carrera);--reg.pade_nro_carrera;
            p_moneda := reg.pade_moneda;
            --p_nro_matricula:='';--reg.pade_matricula; --reg.cuenta_contrato; -- no se cual es el campo
            p_centro_beneficio := '';   -- no se cual es reg.centro_beneficio;
            p_monto := reg.pade_monto;
            p_ano := reg.pade_ano;

            IF (reg.pade_moneda <> 'CLP')
            THEN
               p_monto := REPLACE (reg.pade_monto, ',', '.');
            END IF;

            /*    select distinct pade_tipo_documento into v_tipo_doc
                     from VEC_COB01.pop_pagos_detalle_temp a
                     where pa_rut=p_rut
                     and PA_NRO_OPERACION=p_num_op;*/


            SELECT DISTINCT (matricula)
              INTO v_matricula
              FROM vec_cob01.documentos_sap
             WHERE     codigo_cli = p_rut
                   AND carrera = p_carrera
                   AND tipo_documento = v_tipo_doc_sap;

            p_nro_matricula := v_matricula;



            --  v_fecha_pago:=p_fecha_pago;
            --  v_fecha_registro:=p_fecha_registro;


            v_fecha_pago :=
               TO_DATE (
                  TO_CHAR (TO_DATE (p_fecha_pago, 'DD-MON-YY'),
                           'DD-MON-YYYY'),
                  'DD-MM-YYYY'); --to_date(TO_CHAR(p_fecha_pago,'DD-MM-YYYY'),'DD-MM-YYYY');
            -- v_fecha_pago:=SUBSTR(p_fecha_pago,7,2)||'-'||SUBSTR(p_fecha_pago,5,2)||'-'||SUBSTR(p_fecha_pago,1,4);
            v_fecha_registro :=
               TO_DATE (
                  TO_CHAR (TO_DATE (p_fecha_registro, 'DD-MON-YY'),
                           'DD-MON-YYYY'),
                  'DD-MM-YYYY'); --SUBSTR(p_fecha_registro,7,2)||'-'||SUBSTR(p_fecha_registro,5,2)||'-'||SUBSTR(p_fecha_registro,1,4);
            --p_fecha_documento:=SUBSTR(p_fecha_documento,7,2)||'-'||SUBSTR(p_fecha_documento,5,2)||'-'||SUBSTR(p_fecha_documento,1,4);
            p_fecha_vencimiento :=
               TO_DATE (
                     SUBSTR ('20171023', 7, 2)
                  || '-'
                  || SUBSTR ('20171023', 5, 2)
                  || '-'
                  || SUBSTR ('20171023', 1, 4),
                  'DD-MM-YYYY'); --TO_CHAR(TO_DATE(p_fecha_vencimiento,'DD-MON-YY'),'DD-MON-YYYY');


            INSERT INTO log_error_deudas_sap (codigo_error,
                                              mensaje_error,
                                              fecha,
                                              mensaje_sap)
                    VALUES (
                              0,
                                 'rut: '
                              || p_rut
                              ||                                          --si
                                '-tipo_doc: '
                              || param_tipo_documento
                              ||                                          --si
                                '-tipo_DOC_SAP: '
                              || v_tipo_doc_sap
                              ||                                          --si
                                '-matri: '
                              || p_nro_matricula
                              ||                                          --si
                                '-fec_pago: '
                              || v_fecha_pago
                              || '-fec_regis: '
                              || v_fecha_registro
                              || '-fec_doc'
                              || v_fecha_pago
                              || '-fec_venc: '
                              || p_fecha_vencimiento
                              ||                                          --si
                                '-Num_Doc: '
                              || p_documento,
                              SYSDATE,
                              'PASO');

            COMMIT;



            BEGIN
               INSERT INTO vec_cob01.cc_pagos_banco_sap (NRO_CONTRATO,
                                                         RUT,
                                                         ANO,
                                                         CUOTA,
                                                         FECHA_PAGO,
                                                         MONTO_RECAUDAR,
                                                         TOTAL_PAGADO,
                                                         MONTO_RECARGO,
                                                         SUCURSAL,
                                                         CARGA,
                                                         TIPO_DOCUMENTO,
                                                         CLASE_DOCUMENTO,
                                                         CAJA,
                                                         ESTADO,
                                                         RUT_USUARIO,
                                                         FECHA_REGISTRO,
                                                         NRO_OPERACION,
                                                         NRO_DOCUMENTO,
                                                         CORRELATIVO_DOC,
                                                         CODIGO_MSG_SAP,
                                                         MSG_SAP,
                                                         FECHA_PROCESO_SAP,
                                                         ESTADO_SAP,
                                                         DOCUMENTO_SAP,
                                                         CARRERA,
                                                         DESCRIPCION,
                                                         FECHA_DOCUMENTO,
                                                         FECHA_VENCIMIENTO,
                                                         MATRICULA,
                                                         CORRELATIVO)
                       VALUES (
                                 NULL,
                                 TO_NUMBER (p_rut),
                                 TO_NUMBER (p_ano),
                                 TO_NUMBER (p_cuota),
                                 v_fecha_pago,
                                 TO_NUMBER (p_monto),
                                 TO_NUMBER (p_monto),
                                 reg.pade_interes,
                                 '',
                                 '',
                                 v_tipo_doc_sap,
                                 '',
                                 'CAJA-SANTANDER',
                                 p_estado,
                                 TO_NUMBER (p_rut_usuario),
                                 v_fecha_registro,
                                 TO_NUMBER (p_cuponera),
                                 p_documento,
                                 123,
                                 '',
                                 '',
                                 '',
                                 '',
                                 p_documento,
                                 p_carrera,
                                    'PAGO '
                                 || REG.pade_tipo_documento
                                 || ' CUOTA '
                                 || p_cuota,
                                 p_fecha_documento,
                                 p_fecha_vencimiento,
                                 p_nro_matricula,
                                 SEQ_CORR_CC_SANT_SAP.NEXTVAL);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

                  INSERT INTO log_error_deudas_sap (codigo_error,
                                                    mensaje_error,
                                                    fecha,
                                                    mensaje_sap)
                       VALUES (0,
                               v_error,
                               SYSDATE,
                               v_msg);

                  COMMIT;
            END;
         --END LOOP;
         END LOOP;
      END IF;
   /*
   exception when others then
       htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace);
       */

   END pago_inst_financieras;



   PROCEDURE pago_inst_financieras_resp (p_rut NUMBER, p_banco VARCHAR2/*p_NRO_DOCUMENTO varchar2,
                                                                       p_ano number,
                                                                       p_cuota number,
                                                                       p_fecha_pago date,
                                                                       p_monto_recaudar number,
                                                                       p_total_pagado number,
                                                                       p_monto_recargo number,
                                                                       p_tipo_documento varchar2,
                                                                       p_caja varchar2,
                                                                       p_estado varchar2,
                                                                       p_rut_usuario number,
                                                                       p_fecha_registro date,
                                                                       p_nro_operacion number,
                                                                       p_correlativo_doc number,
                                                                       p_correlativo_sap number,
                                                                       p_contador number*/
   )
   IS
      v_json                    VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta               CLOB;
      v_token                   VARCHAR2 (500);
      v_codigo_error            VARCHAR2 (5000);
      v_mensaje_error           VARCHAR2 (5000);
      v_fecha_error             DATE;
      v_contador                NUMBER (10) := 0;
      v_insert                  VARCHAR2 (5000);
      v_correlativo_sap         NUMBER (10);
      v_descripcion             VARCHAR2 (5000);
      v_fecha_venc              VARCHAR2 (5000);
      v_fecha_doc               VARCHAR2 (5000);
      v_correlativo             NUMBER (5);
      v_Codigo_cli              VARCHAR2 (1000) := '';
      v_Empresa                 VARCHAR2 (1000) := '';
      v_Cuenta_Contrato         VARCHAR2 (1000) := '';
      v_Tipo_Cuenta_Contrato    VARCHAR2 (1000) := '';
      v_Objeto_Contrato         VARCHAR2 (1000) := '';
      v_Clase_Objeto_Contrato   VARCHAR2 (1000) := '';
      v_Tipo_Documento          VARCHAR2 (1000) := '';
      v_Documento               VARCHAR2 (1000) := '';
      v_Cuota                   VARCHAR2 (1000) := '';
      v_Posicion_Interes        VARCHAR2 (1000) := '';
      v_Fecha_Vencimiento       VARCHAR2 (1000) := '';
      v_Fecha_Documento         VARCHAR2 (1000) := '';
      v_Total                   VARCHAR2 (1000) := '';
      v_Total_Local             VARCHAR2 (100);
      v_Saldo                   VARCHAR2 (1000) := '';
      v_Saldo_Local             VARCHAR2 (1000) := '';
      v_Carrera                 VARCHAR2 (1000) := '';
      v_Intereses_Local         VARCHAR2 (1000) := '';
      v_Interes                 VARCHAR2 (1000) := '';
      v_Valor_de_Cambio         VARCHAR2 (1000) := '';
      v_Moneda                  VARCHAR2 (1000) := '';
      v_tipo_doc                VARCHAR2 (1000) := '';
      v_Centro_Beneficio        VARCHAR2 (1000) := '';
      v_Centro_Gestor           VARCHAR2 (1000) := '';
      v_Clave_Estadistica       VARCHAR2 (1000) := '';
      v_Nro_Matricula           VARCHAR2 (100) := '';
      v_Cuota_paso              VARCHAR2 (10) := '-1'; --para eviar que se repita la cuota, solo mientra en SAP arreglan el issue i.villaseca
      l_cli_json                json_list;
      v_ret                     VARCHAR2 (10);
      v_msg                     VARCHAR2 (5000);
      v_error                   VARCHAR2 (15000);
      contador_deudas           NUMBER (10);

      CURSOR corr_pagos_banco
      IS
         SELECT correlativo,
                rut,
                cuota,
                carrera
           FROM vec_cob01.cc_pagos_banco_SAP;
   /*cursor deudas_SAP is

   select b.FEC_VENCIMIENTO FEC_VENCIMIENTO,b.cuota cuota
   from TMP_DEUDAS_SAP a,TMP_DEUDAS_SAP b
   where a.rut=b.CODIGO_CLI
   and a.cuota=b.cuota;
   --and a.tipo_documento
   order by a.FEC_VENCIMIENTO asc;
   */


   BEGIN
      IF (p_banco = 'SANT')
      THEN
         BEGIN
            l_cli_json :=
               int_sap02_json (p_rut,
                               '',
                               '',
                               '',
                               '',
                               '',
                               v_ret,
                               v_msg);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_error_deudas_sap (codigo_error,
                                                 mensaje_error,
                                                 fecha,
                                                 mensaje_sap)
                    VALUES (0,
                            v_error,
                            SYSDATE,
                            v_msg);

               COMMIT;
         END;


         FOR i IN 1 .. l_cli_json.COUNT
         LOOP
            v_contador := v_contador + 1;


            --  EXIT WHEN v_contador > 1;

            v_Codigo_cli :=
               TO_NUMBER (
                  UTSAP001.pkg_integra_utal.lee_json (
                     json (l_cli_json.get (i)),
                     'Codigo_cli'));
            v_Empresa :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Empresa');
            v_Cuenta_Contrato :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Cuenta_Contrato');
            v_Tipo_Cuenta_Contrato :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Tipo_Cuenta_Contrato');
            v_Objeto_Contrato :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Objeto_Contrato');
            v_Clase_Objeto_Contrato :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Clase_Objeto_Contrato');
            v_Tipo_Documento :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Tipo_Documento');
            v_tipo_doc :=
               SUBSTR (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Tipo_Documento'),
                  1,
                  INSTR (v_Tipo_Documento, '-') - 1);
            --                      v_tipo_doc:= PKG_RECURSOS.RECUPERA_CODIGO_ICON(2,2,'',v_tipo_doc); se debe usar en el deuda SD


            v_Documento :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Documento');
            v_Cuota :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)), 'Cuota');
            v_Posicion_Interes :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Posicion_Interes');
            v_Fecha_Vencimiento :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Fecha_Vencimiento');
            v_Fecha_Documento :=
               lee_json (json (l_cli_json.get (i)), 'Fecha_Focumento');
            v_Total :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)), 'Total');
            --v_Total                  := replace(pkg_integra_utal.lee_json(json(l_cli_json.get (i)) , 'Total'),'.','');
            -- v_Total := replace(v_Total,',','');


            v_Total_Local :=
               REPLACE (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Total_Local'),
                  '.',
                  '');
            v_Total_Local := REPLACE (v_Total_Local, ',', '');

            --htp.p(replace(UTSAP001.pkg_integra_utal.lee_json(json (l_cli_json.get (i)) , 'Total_Local'),'.',''));
            v_Saldo :=
               REPLACE (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Saldo'),
                  '.',
                  '');

            v_Saldo := REPLACE (v_Saldo, ',', '');

            v_Saldo_Local :=
               REPLACE (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Saldo_Local'),
                  '.',
                  '');
            v_Carrera :=
               SUBSTR (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Carrera'),
                  1,
                  2);
            v_Intereses_Local :=
               REPLACE (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Intereses_Local'),
                  '.',
                  '');
            v_Interes :=
               REPLACE (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Interes'),
                  '.',
                  '');
            v_Valor_de_Cambio :=
               REPLACE (
                  pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                             'Valor_de_Cambio'),
                  '.',
                  '');
            v_Moneda :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Moneda');
            v_Nro_Matricula :=
               pkg_integra_utal.lee_json (json (l_cli_json.get (i)),
                                          'Nro_Matricula');

            --v_tipo_doc:=SUBSTR(pkg_integra_utal.lee_json(json (l_cli_json.get (i)) , 'Tipo_Documento'),1,2);



            /*if(p_tipo_documento='ARAPR') THEN

            v_Tipo_Documento:='AG';

            END IF;*/


            SELECT COUNT (*)
              INTO contador_deudas
              FROM TMP_DEUDAS_SAP
             WHERE CODIGO_CLI = p_rut;


            IF (contador_deudas <> 0)
            THEN
               BEGIN
                  DELETE FROM TMP_DEUDAS_SAP
                        WHERE CODIGO_CLI = p_rut;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_error :=
                        SQLERRM || DBMS_UTILITY.format_error_backtrace;

                     INSERT INTO log_error_deudas_sap (codigo_error,
                                                       mensaje_error,
                                                       fecha,
                                                       mensaje_sap)
                          VALUES (0,
                                  v_error,
                                  SYSDATE,
                                  'Error al borrar TMP_DEUDAS_SAP');

                     COMMIT;
               END;
            END IF;

            BEGIN
               INSERT INTO TMP_DEUDAS_SAP (AUXILIAR,
                                           EMPRESA,
                                           CODIGO_CLI,
                                           FEC_RECEPCION,
                                           TIPO_MONEDA,
                                           DOCUMENTO,
                                           CARRERA,
                                           TIPO_DOCUMENTO,
                                           NMB_DOCUMENTO,
                                           ANO,
                                           CUOTA,
                                           MONTO,
                                           MONEDA,
                                           MONTO_PESOS,
                                           INTERES,
                                           FEC_VENCIMIENTO,
                                           TOTAL_PAGAR,
                                           CORRELATIVO,
                                           CUENTA_CONTRATO,
                                           OBJETO_CONTRATO,
                                           Centro_Beneficio,
                                           Centro_Gestor,
                                           Clave_Estadistica,
                                           matricula)
                    VALUES ('CXC',
                            '10',
                            p_rut,
                            v_Fecha_Documento,
                            '01',
                            v_Documento,
                            v_Carrera,
                            v_tipo_doc,
                            v_Tipo_Documento,
                            SUBSTR (v_Fecha_Vencimiento, 1, 4),
                            v_Cuota,
                            v_Total,
                            v_Moneda,
                            v_Saldo,
                            v_Interes,
                            v_Fecha_Vencimiento,
                            v_Total_Local,
                            i,
                            v_Cuenta_Contrato,
                            v_Objeto_Contrato,
                            v_Centro_Beneficio,
                            v_Centro_Gestor,
                            v_Clave_Estadistica,
                            v_Nro_Matricula);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

                  INSERT INTO log_error_deudas_sap (codigo_error,
                                                    mensaje_error,
                                                    fecha,
                                                    mensaje_sap)
                       VALUES (0,
                               v_error,
                               SYSDATE,
                               v_msg);

                  COMMIT;
            END;



            v_fecha_venc :=
                  SUBSTR (v_Fecha_Vencimiento, 7, 2)
               || '-'
               || SUBSTR (v_Fecha_Vencimiento, 5, 2)
               || '-'
               || SUBSTR (v_Fecha_Vencimiento, 1, 4);

            v_fecha_doc :=
                  SUBSTR (v_Fecha_Documento, 7, 2)
               || '-'
               || SUBSTR (v_Fecha_Documento, 5, 2)
               || '-'
               || SUBSTR (v_Fecha_Documento, 1, 4);


            FOR j IN corr_pagos_banco
            LOOP
               /*htp.p('SAP: '||to_number(v_Cuota)||'<br>');
               htp.p('J :'||j.cuota||'<br>');*/


               BEGIN
                  /*
                  select CORRELATIVO
                  INTO v_contador
                  FROM VEC_COB01.CC_PAGOS_BANCO_SAP
                  where CORRELATIVO=j.correlativo;
                  */

                  UPDATE VEC_COB01.CC_PAGOS_BANCO_SAP
                     SET CODIGO_MSG_SAP = '',
                         MSG_SAP = '',
                         FECHA_PROCESO_SAP = '',
                         ESTADO_SAP = 'X',
                         DOCUMENTO_SAP = v_Documento,
                         CARRERA = v_Carrera,
                         DESCRIPCION = 'PAGO',
                         FECHA_DOCUMENTO = v_fecha_doc,
                         FECHA_VENCIMIENTO = v_fecha_venc,
                         MATRICULA = v_Nro_Matricula
                   WHERE     rut = p_rut
                         AND CORRELATIVO = j.correlativo
                         AND carrera = j.carrera;

                  --and cuota=to_number(v_Cuota); --SENTENCIA CORRECTA, COMENTAR MIENTRAS NO SE PAGUEN MÁS CUOTAS

                  --and replace(TOTAL_PAGADO,'.','')=replace(v_Total_Local,'.','')
                  --and TIPO_DOCUMENTO=v_Tipo_Documento;

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_error :=
                        SQLERRM || DBMS_UTILITY.format_error_backtrace;

                     INSERT INTO log_error_deudas_sap (codigo_error,
                                                       mensaje_error,
                                                       fecha,
                                                       mensaje_sap)
                          VALUES (p_rut,
                                  v_error,
                                  SYSDATE,
                                  v_msg);

                     COMMIT;
               END;
            END LOOP;
         END LOOP;
      /*

          EXCEPTION
            WHEN OTHERS
            THEN
               HTP.p
                  (   'Error:'
                   || SQLERRM
                   || ' procedure deudas_vigentes_json2, favor contactar al Administrador'
                  );
      */

      END IF;

      IF (p_banco = 'BCI')
      THEN
         NULL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END pago_inst_financieras_resp;


   PROCEDURE prueba
   IS
   BEGIN
      HTP.p ('hola');
   END;

   FUNCTION encripta_sap
      RETURN VARCHAR2
   IS
      l_retorno   VARCHAR2 (1000);
   BEGIN
      l_retorno :=
         utal_dti.p_encrypt_utal.encrypt_ssn_sap (
            G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'));

      RETURN l_retorno;
   END encripta_sap;


   FUNCTION desencripta_sap (p_valor VARCHAR2)
      RETURN VARCHAR2
   IS
      l_retorno   VARCHAR2 (1000);
   BEGIN
      l_retorno := utal_dti.p_encrypt_utal.decrypt_ssn (p_valor);

      RETURN l_retorno;
   END desencripta_sap;



   /*function call_url_p( p_url in varchar2 ,p_json varchar2) return long
   is
       v_url varchar2(500) ;
       v_req   UTL_HTTP.REQ;
       v_resp  UTL_HTTP.RESP;
       v_line   VARCHAR2(32766);
       v_count  number := 0;
       v_return_pg long :='';

   begin
       --v_url := trim(decode_base_64(p_url));
       v_url := p_url;
       --htp.p(v_url);

       v_req := utl_http.begin_request(v_url,  method => 'POST' );
         utl_http.set_header(v_req, 'user-agent', 'mozilla/4.0');
         utl_http.set_header(v_req, 'content-type', 'application/json');
         utl_http.set_header(v_req, 'Content-Length', length(p_json));


         utl_http.write_text(v_req, p_json);
         v_resp := utl_http.get_response(v_req);

       LOOP
           --UTL_HTTP.READ_LINE(v_resp, v_line, TRUE);
           UTL_HTTP.read_text(v_resp, v_line, 32766);
           v_return_pg := v_return_pg || v_line;

           v_count := v_count + 1 ;

           --contador de seguridad
           if v_count >= 100 then
               exit;
           end if ;
       END LOOP;
         utl_http.end_response(v_resp);

         return v_return_pg;


    EXCEPTION
      WHEN utl_http.end_of_body THEN
           utl_http.end_response(v_resp);
           return v_return_pg;
   END call_url_p;*/
   FUNCTION call_url_p_11g (p_url IN VARCHAR2, p_json VARCHAR2)
      RETURN CLOB
   IS
      v_url                VARCHAR2 (500);
      v_req                UTL_HTTP.REQ;
      v_resp               UTL_HTTP.RESP;
      v_line               VARCHAR2 (32766);
      v_count              NUMBER := 0;
      v_return_pg          CLOB := EMPTY_CLOB ();
      v_largo              NUMBER;
      v_NLS_CHARACTERSET   VARCHAR2 (100);
   BEGIN
      SELECT VALUE
        INTO v_NLS_CHARACTERSET
        FROM nls_database_parameters
       WHERE parameter = 'NLS_CHARACTERSET';

      --v_largo:=utl_raw.length(utl_raw.convert(utl_raw.cast_to_raw( p_json),'american_america.al32utf8',v_NLS_CHARACTERSET));
      v_largo :=
         UTL_RAW.LENGTH (
            UTL_RAW.cast_to_raw (
               CONVERT (p_json, 'UTF8', v_NLS_CHARACTERSET)));

      v_url := p_url;
      v_req := UTL_HTTP.begin_request (v_url, method => 'POST');
      UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
      --utl_http.set_header(v_req, 'content-type', 'application/json');
      --utl_http.set_header(v_req, 'Content-Length', length(p_json));
      --utl_http.write_text(v_req, p_json);
      UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
      UTL_HTTP.set_header (v_req,
                           'content-type',
                           'application/json; charset=utf-8');
      UTL_HTTP.set_header (v_req, 'Content-Length', v_largo);
      /*Se agrega autorización, cambio de oracle 19c**/
       UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);  
      UTL_HTTP.WRITE_RAW (
         v_req,
         UTL_RAW.cast_to_raw (CONVERT (p_json, 'UTF8', v_NLS_CHARACTERSET)));

      v_resp := UTL_HTTP.get_response (v_req);

      LOOP
         UTL_HTTP.read_text (v_resp, v_line, 32766);                   --32766
         v_return_pg := v_return_pg || v_line;

         v_count := v_count + 1;

         IF v_count >= 100
         THEN
            EXIT;
         END IF;
      END LOOP;

      UTL_HTTP.end_response (v_resp);

      RETURN v_return_pg;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (v_resp);
         RETURN v_return_pg;
   END call_url_p_11g;

   FUNCTION call_url_p_2 (p_url IN VARCHAR2, p_json CLOB)
      RETURN CLOB
   IS
      v_url                VARCHAR2 (500);
      v_req                UTL_HTTP.REQ;
      v_resp               UTL_HTTP.RESP;
      v_line               VARCHAR2 (32766);
      v_count              NUMBER := 0;
      v_return_pg          CLOB := EMPTY_CLOB ();
      v_largo              NUMBER;
      v_NLS_CHARACTERSET   VARCHAR2 (100);
   BEGIN
      SELECT VALUE
        INTO v_NLS_CHARACTERSET
        FROM nls_database_parameters
       WHERE parameter = 'NLS_CHARACTERSET';

      -- htp.p('hola');
      v_largo :=
         UTL_RAW.LENGTH (
            cast_to_raw_dti (CONVERT (p_json, 'UTF8', v_NLS_CHARACTERSET)));
      v_url := p_url;
      v_req := UTL_HTTP.begin_request (v_url, method => 'POST');
      UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
      
      UTL_HTTP.set_header (v_req,
                           'content-type',
                           'application/json; charset=utf-8');
        /*Se agrega autorización, cambio de oracle 19c**/
       UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);  
      UTL_HTTP.set_header (v_req, 'Content-Length', v_largo);
      UTL_HTTP.WRITE_RAW (
         v_req,
         cast_to_raw_dti (CONVERT (p_json, 'UTF8', v_NLS_CHARACTERSET)));

      v_resp := UTL_HTTP.get_response (v_req);

      LOOP
         UTL_HTTP.read_text (v_resp, v_line, 32766);                   --32766
         v_return_pg := v_return_pg || v_line;

         v_count := v_count + 1;

         IF v_count >= 100
         THEN
            EXIT;
         END IF;
      END LOOP;

      UTL_HTTP.end_response (v_resp);

      RETURN v_return_pg;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (v_resp);
         RETURN v_return_pg;
   END call_url_p_2;

   FUNCTION call_url_p (p_url IN VARCHAR2, p_json VARCHAR2)
      RETURN CLOB
   IS
      v_url                VARCHAR2 (500);
      v_req                UTL_HTTP.REQ;
      v_resp               UTL_HTTP.RESP;
      v_line               VARCHAR2 (32766);
      v_count              NUMBER := 0;
      v_return_pg          CLOB := EMPTY_CLOB ();
      v_largo              NUMBER;
      v_NLS_CHARACTERSET   VARCHAR2 (100);
      l_username           VARCHAR2 (100);
      l_password           VARCHAR2 (100);
      protocol_str         VARCHAR2 (100);
      l_auth_string        VARCHAR2 (1000);
   BEGIN
      SELECT VALUE
        INTO v_NLS_CHARACTERSET
        FROM nls_database_parameters
       WHERE parameter = 'NLS_CHARACTERSET';

      v_largo :=
         UTL_RAW.LENGTH (
            CASt_to_raw_dti (CONVERT (p_json, 'UTF8', v_NLS_CHARACTERSET)));
      v_url := p_url;
      v_req := UTL_HTTP.begin_request (v_url, method => 'POST');
      UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
      UTL_HTTP.set_header (v_req,
                           'content-type',
                           'application/json; charset=utf-8');
      UTL_HTTP.set_header (v_req, 'Content-Length', v_largo);

      UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);
      UTL_HTTP.WRITE_RAW (
         v_req,
         cast_to_raw_dti (CONVERT (p_json, 'UTF8', v_NLS_CHARACTERSET)));

      v_resp := UTL_HTTP.get_response (v_req);

      LOOP
         UTL_HTTP.read_text (v_resp, v_line, 32766);                   --32766
         v_return_pg := v_return_pg || v_line;

         v_count := v_count + 1;

         IF v_count >= 100
         THEN
            EXIT;
         END IF;
      END LOOP;

      UTL_HTTP.end_response (v_resp);

      RETURN v_return_pg;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (v_resp);
         RETURN v_return_pg;
   END call_url_p;

   FUNCTION call_url_p_1 (p_url IN VARCHAR2, p_json CLOB)
      RETURN CLOB
   IS
      v_url         VARCHAR2 (500);
      v_req         UTL_HTTP.req;
      v_resp        UTL_HTTP.resp;
      v_line        VARCHAR2 (32766);
      v_count       NUMBER := 0;
      v_return_pg   CLOB := EMPTY_CLOB ();
      req_length    BINARY_INTEGER;
      buffer        VARCHAR2 (2000);
      amount        PLS_INTEGER := 2000;
      offset        PLS_INTEGER := 1;
   BEGIN
      --v_url := trim(decode_base_64(p_url));

      v_url := p_url;
      --htp.p(v_url);
      v_req := UTL_HTTP.begin_request (v_url, method => 'POST');
      req_length := DBMS_LOB.getlength (p_json);

      IF req_length <= 32767
      THEN
         UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
         UTL_HTTP.set_header (v_req, 'content-type', 'application/json');
         UTL_HTTP.set_header (v_req, 'Content-Length', req_length);
              UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);
         UTL_HTTP.write_text (v_req, p_json);
      ELSE
         UTL_HTTP.set_header (v_req, 'Transfer-Encoding', 'chunked');
            UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);  
         WHILE (offset < req_length)
         LOOP
            DBMS_LOB.read (p_json,
                           amount,
                           offset,
                           buffer);
            UTL_HTTP.write_text (v_req, buffer);
            offset := offset + amount;
         END LOOP;
      END IF;

      v_resp := UTL_HTTP.get_response (v_req);

      LOOP
         --UTL_HTTP.READ_LINE(v_resp, v_line, TRUE);
         UTL_HTTP.read_text (v_resp, v_line, 32766);                   --32766
         v_return_pg := v_return_pg || v_line;
         v_count := v_count + 1;

         --contador de seguridad
         IF v_count >= 100
         THEN
            EXIT;
         END IF;
      END LOOP;

      UTL_HTTP.end_response (v_resp);

      RETURN v_return_pg;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (v_resp);
         RETURN v_return_pg;
   END call_url_p_1;


   FUNCTION call_url_p_1_adh (p_url IN VARCHAR2, p_json CLOB)
      RETURN CLOB
   IS
      v_url         VARCHAR2 (500);
      v_req         UTL_HTTP.req;
      v_resp        UTL_HTTP.resp;
      v_line        VARCHAR2 (32766);
      v_count       NUMBER := 0;
      v_return_pg   CLOB := EMPTY_CLOB ();
   BEGIN
      --v_url := trim(decode_base_64(p_url));
      v_url := p_url;
      --htp.p(v_url);
      v_req := UTL_HTTP.begin_request (v_url, method => 'POST');
      UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
      UTL_HTTP.set_header (v_req, 'content-type', 'application/json');
      UTL_HTTP.set_header (v_req, 'Content-Length', LENGTH (p_json));
      UTL_HTTP.write_text (v_req, p_json);
      v_resp := UTL_HTTP.get_response (v_req);

      LOOP
         --UTL_HTTP.READ_LINE(v_resp, v_line, TRUE);
         UTL_HTTP.read_text (v_resp, v_line, 32766);                   --32766
         v_return_pg := v_return_pg || v_line;
         v_count := v_count + 1;

         --contador de seguridad
         IF v_count >= 100
         THEN
            EXIT;
         END IF;
      END LOOP;

      UTL_HTTP.end_response (v_resp);
      RETURN v_return_pg;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (v_resp);
         RETURN v_return_pg;
   END call_url_p_1_adh;


   FUNCTION call_url_p_postgrado (p_url IN VARCHAR2, p_json CLOB)
      RETURN CLOB
   IS
      v_url         VARCHAR2 (500);
      v_req         UTL_HTTP.REQ;
      v_resp        UTL_HTTP.RESP;
      v_line        VARCHAR2 (32766);
      v_count       NUMBER := 0;
      v_return_pg   CLOB := EMPTY_CLOB ();
   BEGIN
      --v_url := trim(decode_base_64(p_url));
      v_url := p_url;
      --htp.p(v_url);

      v_req := UTL_HTTP.begin_request (v_url, method => 'POST');
      UTL_HTTP.set_header (v_req, 'user-agent', 'mozilla/4.0');
      UTL_HTTP.set_header (v_req, 'content-type', 'application/json');
      UTL_HTTP.set_header (v_req, 'Content-Length', LENGTH (p_json));
    /*Se agrega autorización, cambio de oracle 19c**/
       UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);  

      UTL_HTTP.write_text (v_req, p_json);
      v_resp := UTL_HTTP.get_response (v_req);

      LOOP
         --UTL_HTTP.READ_LINE(v_resp, v_line, TRUE);
         UTL_HTTP.read_text (v_resp, v_line, 32766);                   --32766
         v_return_pg := v_return_pg || v_line;

         v_count := v_count + 1;

         --contador de seguridad
         IF v_count >= 100
         THEN
            EXIT;
         END IF;
      END LOOP;

      UTL_HTTP.end_response (v_resp);

      RETURN v_return_pg;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (v_resp);
         RETURN v_return_pg;
   END call_url_p_postgrado;

   FUNCTION int_sap03_json (p_agno_ejercicio       VARCHAR2, --parametro consulta
                            p_centro               VARCHAR2, --parametro consulta
                            p_proyecto             VARCHAR2, --parametro consulta
                            p_orden_co             VARCHAR2,
                            p_cuenta               VARCHAR2, --parametro consulta
                            p_ret              OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                            p_msg              OUT VARCHAR2 --mensaje de error
                                                           )
      RETURN json
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_resp_json   json;
      l_data_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      --v_token := v_token||'*';

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json :=
               '{
                "Token": "'
            || v_token
            || '",
                "data": {
                               "Ejercicio": "'
            || p_agno_ejercicio
            || '",
                               "Objeto": {
                                               "Centro_Costo": "'
            || p_centro
            || '",
                                               "Proyecto": "'
            || p_proyecto
            || '",
                                               "Orden_CO": "'
            || p_orden_co
            || '"
                               },
                               "Cuenta": "'
            || p_cuenta
            || '",
                }
}'        ;

         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
            */
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FM001/INT_SAP03',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      --htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_data_json := json (l_resp_json.get ('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /*verifica que el data viene vacío*/
      IF l_data_json IS NULL
      THEN
         p_ret := 'E';
         p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
      END IF;

      /*retorna json*/
      RETURN l_data_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_sap03_json;


   PROCEDURE int_sap03 (p_agno_ejercicio    VARCHAR2,
                        p_centro            VARCHAR2,
                        p_proyecto          VARCHAR2,
                        p_orden_co          VARCHAR2,
                        p_cuenta            VARCHAR2)
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_cli_json    json;

      v_ret         VARCHAR2 (1);
      v_msg         VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sapxx_json y en la variable l_cli_json recibe el json del data*/
      l_cli_json :=
         int_sap03_json (p_agno_ejercicio,
                         p_centro,
                         p_proyecto,
                         p_orden_co,
                         p_cuenta,
                         v_ret,
                         v_msg);

      HTP.p (v_ret || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         HTP.p (
               'Centro_Gestor:'
            || lee_json (l_cli_json, 'Centro_Gestor')
            || '<br>');
         HTP.p ('Pospre:' || lee_json (l_cli_json, 'Pospre') || '<br>');
         HTP.p ('Monto:' || lee_json (l_cli_json, 'Monto') || '<br>');
         HTP.p ('<br>');
      /*
       FOR i IN 1 .. l_cli_json.COUNT loop
                htp.p('Centro_Gestor:'||lee_json(json(l_cli_json.get(i)) , 'Centro_Gestor')||'<br>');
                htp.p('Pospre:'||lee_json(json(l_cli_json.get(i)) , 'Pospre')||'<br>');
                htp.p('Monto:'||lee_json(json(l_cli_json.get(i)) , 'Monto')||'<br>');
       end loop;


      */
      ELSE
         /*imprime mensaje de error*/
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_sap03;

   FUNCTION int_sap09_json (p_material       VARCHAR2,    --parametro consulta
                            p_centro         VARCHAR2,    --parametro consulta
                            p_ret        OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                            p_msg        OUT VARCHAR2       --mensaje de error
                                                     )
      RETURN json
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);
      l_resp_json   json;
      l_data_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json := '{
                "Token": "' || v_token || '",
                "data": {
                               "Material": "' || p_material || '",
                               "Centro": "' || p_centro || '",
                }
        }';

         /*Fin Json de entrada*/

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
            */

            --   v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000/RESTAdapter/MM004/INT_SAP09', v_json);
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/MM004/INT_SAP09',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      HTP.p (v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_data_json := json (l_resp_json.get ('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /*verifica que el data viene vacío*/
      IF l_data_json IS NULL
      THEN
         p_ret := 'E';
         p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
      END IF;

      /*retorna json*/
      RETURN l_data_json;
   END int_sap09_json;

   PROCEDURE int_sap09 (p_material VARCHAR2, p_centro VARCHAR2)
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_cli_json    json;

      v_ret         VARCHAR2 (1);
      v_msg         VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sapxx_json y en la variable l_cli_json recibe el json del data*/
      l_cli_json :=
         int_sap09_json (p_material,
                         p_centro,
                         v_ret,
                         v_msg);

      HTP.p (v_ret || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         HTP.p ('Material:' || lee_json (l_cli_json, 'Material') || '<br>');
         HTP.p ('Cantidad:' || lee_json (l_cli_json, 'Cantidad') || '<br>');
         HTP.p ('<br>');
      ELSE
         /*imprime mensaje de error*/
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_sap09;


   FUNCTION int_leg06_json (itemtype   IN     VARCHAR2,
                            itemkey    IN     VARCHAR2,
                            p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                            p_msg         OUT VARCHAR2      --mensaje de error
                                                      )
      RETURN json
   IS
      v_json                    VARCHAR2 (32000);
      v_json2                   VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta               CLOB;
      v_respuesta_json          json;
      v_token                   VARCHAR2 (500);

      l_resp_json               json;
      l_data_json               json_list;
      l_RETURN_json             json;
      v_contador_centro_costo   NUMBER (10);
      v_tipo_centro             VARCHAR2 (100);
      v_tipo_centro_sap         VARCHAR2 (10);
      v_Centro_Costo            VARCHAR2 (100);
      v_Elemento_PEP            VARCHAR2 (100);
      v_centro_costo_sap        VARCHAR2 (100);
      v_fecha_licitacion        VARCHAR2 (20);
      v_fecha1                  VARCHAR2 (20);
      v_type                    VARCHAR (5000);
      clase_centro              VARCHAR2 (50);
      v_orden_co                VARCHAR (100);
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_contador_centro_costo :=
            pkg_integra_utal.LEERDATOTABLA_WF (itemtype,
                                               itemkey,
                                               'CONTADOR_CENTRO_COSTO',
                                               1);
         v_fecha1 :=
            pkg_integra_utal.LEERDATOTABLA_WF (itemtype,
                                               itemkey,
                                               'FECHA_LICITACION');
         --pkg_integra_utal.LEERDATOTABLA_WF(itemtype,itemkey,'FECHA_LICITACION');


         v_fecha_licitacion :=
               TO_CHAR (TO_DATE (v_fecha1, 'dd-mm-yyyy'), 'yyyy')
            || TO_CHAR (TO_DATE (v_fecha1, 'dd-mm-yyyy'), 'mm')
            || TO_CHAR (TO_DATE (v_fecha1, 'dd-mm-yyyy'), 'dd');

         v_json := '{
                "Token": "' || v_token || '",
                "data": {
             ';

         FOR i IN 1 .. v_contador_centro_costo
         LOOP
            v_centro_costo_sap :=
               pkg_integra_utal.LEERDATOTABLA_WF (itemtype,
                                                  itemkey,
                                                  'TXT_C_RESPONSABILIDAD',
                                                  i);

            SELECT DISTINCT tipo_centro
              INTO v_tipo_centro
              FROM v_centros_sap
             WHERE centro = v_centro_costo_sap;

            SELECT DISTINCT clase
              INTO clase_centro
              FROM v_centros_sap
             WHERE centro = v_centro_costo_sap;

            IF v_tipo_centro = 'PRESUP'
            THEN
               IF clase_centro = 'O'
               THEN
                  v_tipo_centro_sap := 'F';
                  v_Elemento_PEP := '';
                  v_Centro_Costo := '';
                  v_orden_co := v_centro_costo_sap;
               ELSE
                  v_tipo_centro_sap := 'K';
                  v_Centro_Costo := v_centro_costo_sap;
                  v_Elemento_PEP := '';
                  v_orden_co := '';
               END IF;
            ELSE
               v_tipo_centro_sap := 'P';
               v_Centro_Costo := '';
               v_orden_co := '';
               v_Elemento_PEP := v_centro_costo_sap;
            END IF;

            v_json :=
                  v_json
               || ' "REQUISITION_ITEMS": {
                                               "Posicion": "'
               || i * 10
               || '",
                                               "Nombre_Solicitante": "'
               || pkg_integra_utal.LEERDATOTABLA_WF ('WF_LICI',
                                                     itemkey,
                                                     'USR_UNIDAD')
               || '",
                                               "Fecha_Creacion": "'
               || v_fecha_licitacion
               || '",
                                               "Texto_Breve": "'
               || pkg_integra_utal.LEERDATOTABLA_WF (itemtype,
                                                     itemkey,
                                                     'TXT_NOMBRE_LICITACION')
               || '",
                                               "Material": "",
                                               "Centro": "UT01",
                                               "Numero_Necesidad": "'
               || SUBSTR (itemkey, 5)
               || '",
                                               "Cantidad": "1",
                                               "Fecha_Entrega": "'
               || v_fecha_licitacion
               || '",
                                               "Precio": "'
               || pkg_integra_utal.LEERDATOTABLA_WF (itemtype,
                                                     itemkey,
                                                     'TXT_NUEVO_MONTO',
                                                     i)
               || '",
                                               "Imputacion": "'
               || v_tipo_centro_sap
               || '",
                                               "Moneda": "CLP",
                                               "Grupo_Articulo": ""
                               },

                               "REQUISITION_ACCOUNT_ASSIGNMENT": {
                                               "Posicion": "'
               || i * 10
               || '",
                                               "N_Cuenta_Mayor": "'
               || pkg_integra_utal.LEERDATOTABLA_WF (itemtype,
                                                     itemkey,
                                                     'CUENTA',
                                                     i)
               || '",
                                               "Centro_Costo": "'
               || v_Centro_Costo
               || '",
                                               "Elemento_PEP": "'
               || v_Elemento_PEP
               || '",
                                               "Orden_CO": "'
               || v_orden_co
               || '"
                               }
                               ';

            IF i <> v_contador_centro_costo
            THEN
               v_json := v_json || ',';
            END IF;
         END LOOP;

         v_json := v_json || '     }
}'        ;

         --htp.p(v_json||'<br>');


         /*

               v_monto_compra(i)       :=WF_FUNCIONESGENERALES.leerdatotabla(itemtype,itemkey,'TXT_NUEVO_MONTO',i);
               vl_monto_asignado       := v_monto_compra(i);
               p_centro_costo(i)       := WF_FUNCIONESGENERALES.leerdatotabla(itemtype,itemkey,'TXT_C_RESPONSABILIDAD',i);
               vl_centro_costo         := p_centro_costo(i);
               p_cuenta(i)             := WF_FUNCIONESGENERALES.leerdatotabla(itemtype,itemkey,'CUENTA',i);
               vl_cuenta               := p_cuenta(i);
             --  p_tarea(i)              := WF_FUNCIONESGENERALES.leerdatotabla(itemtype,itemkey,'TAREA',i);
              -- vl_tarea                := p_tarea(i);
               posicion:=posicion+10;

           select distinct  tipo_centro
                into v_tipo_centro
               from v_centros_sap
               where  centro=vl_centro_costo;

           if(v_tipo_centro='PRESUP') then


               --v_json:=utsap001.pkg_integra_utal.int_leg06_json(posicion,v_rut_unidad,fecha_lici,nombre_lici,vl_solicitud,vl_monto_asignado,'K',vl_centro_costo,vl_cuenta,null,p_ret,p_msg);

                v_json2 := ' "REQUISITION_ACCOUNT_ASSIGNMENT": {
                                                      "Posicion": "'||p_posicion||'",
                                                      "N_Cuenta_Mayor": "'||p_cuenta||'",
                                                      "Centro_Costo": "'||p_centro_costo||'",
                                                      "Elemento_PEP": ""
                                      },
                                      "REQUISITION_ACCOUNT_ASSIGNMENT": {
                                                      "Posicion": "'||p_posicion||'",
                                                      "N_Cuenta_Mayor": "'||p_cuenta||'",
                                                      "Centro_Costo": "",
                                                      "Elemento_PEP": "'||p_elemento_pep||'"
                                      }
                       }
               }';

           else
               v_json:=utsap001.pkg_integra_utal.int_leg06_json(posicion,v_rut_unidad,fecha_lici,nombre_lici,vl_solicitud,vl_monto_asignado,'P',null,vl_cuenta,vl_centro_costo,p_ret,p_msg);

           end if;
       end loop;
       */

         --********************+



         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
            */

            --v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000/RESTAdapter/MM004/INT_LEG06', v_json);
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/MM05/INT_LEG06',
                           v_json);
            HTP.p (v_respuesta);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      --htp.p('TYPE:'||lee_json(v_respuesta , 'TYPE')||'<br>');
      -- v_respuesta_json:=json(v_respuesta);
      --v_type:=lee_json(v_respuesta_json , 'TYPE');
      -- htp.p(v_type);
      INSERT INTO log_wf_licitaciones_sap (item_type,
                                           item_key,
                                           msg_sap,
                                           fecha_msg)
           VALUES (itemtype,
                   itemkey,
                   v_respuesta,
                   SYSDATE);

      COMMIT;

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         --  l_data_json := json(l_resp_json.get('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /*
          --verifica que el data viene vacío
          if l_data_json is null then
              p_ret := 'E';
              p_msg := 'Error en el formato de la respuesta : '||sqlerrm;
          end if;
           /*retorna json   */
      RETURN l_RETURN_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace); --SQLERRM||DBMS_UTILITY.format_error_backtrace
   END int_leg06_json;

   PROCEDURE int_leg06 (itemtype IN VARCHAR2, itemkey IN VARCHAR2)
   IS
      v_json            VARCHAR2 (1500);
      v_respuesta       CLOB;
      v_token           VARCHAR2 (500);
      l_cli_json        json;
      l_cli_json_data   json_list;
      v_ret             VARCHAR2 (1);
      v_msg             VARCHAR2 (5000);
   BEGIN
      l_cli_json :=
         int_leg06_json (itemtype,
                         itemkey,
                         v_ret,
                         v_msg);
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace); --SQLERRM||DBMS_UTILITY.format_error_backtrace
   END int_leg06;

   FUNCTION LEERDATOTABLA_WF (itemtype      IN VARCHAR2,
                              itemkey       IN VARCHAR2,
                              DATOBUSCAR    IN VARCHAR2,
                              posicionfin   IN NUMBER DEFAULT 1)
      RETURN VARCHAR2
   IS
      ELDATO       VARCHAR2 (2000);

      CUENTADATO   NUMBER;
   BEGIN
      BEGIN
         SELECT dato
           INTO ELDATO
           FROM owf_mgr.tmp_seguirdatos
          WHERE     workflow = itemtype
                AND id = itemkey
                AND UPPER (Nombredato) = UPPER (DATOBUSCAR)
                AND posicion = posicionfin;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT dato
                 INTO ELDATO
                 FROM owf_mgr.tmp_seguirdatos_his
                WHERE     workflow = itemtype
                      AND id = itemkey
                      AND UPPER (Nombredato) = UPPER (DATOBUSCAR)
                      AND posicion = posicionfin;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  ELDATO := NULL;
            END;
      END;

      RETURN (ELDATO);
   END;


   FUNCTION int_sap10_json_interfaces (p_cli_rut                  VARCHAR2,
                                       p_canal_distribucion       VARCHAR2,
                                       p_ret                  OUT VARCHAR2,
                                       p_msg                  OUT VARCHAR2)
      RETURN json
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);

      l_resp_json   json;
      l_data_json   json;
   BEGIN
      p_ret := 'S';

      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;


      IF p_ret = 'S'
      THEN
         v_json :=
               '{   "Token": "'
            || v_token
            || '",
            "data":{          "cli_rut": "'
            || p_cli_rut
            || '",
                              "canal_distribucion": "'
            || p_canal_distribucion
            || '"
                   }
            }';


         BEGIN
         --DBA            
            v_respuesta := call_url_p(g_sistema_sap||'/RESTAdapter/SD005/INT_SAP10', v_json);
         --   v_respuesta := call_url_p (g_sistema_sapqa || '/RESTAdapter/SD005/INT_SAP10', v_json);
         
         --    PRUEBA ALAN RIQUELME 08/03/2017
         -- v_respuesta := call_url_p(g_sistema_sapdv_alan||'/RESTAdapter/SD005/INT_SAP10', v_json);
         --htp.p(v_respuesta);

         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;

               --DBA
               INSERT INTO LOG_CREA_CLIENTE_SAP (RUT,
                                                 MENSAJE_SQL,
                                                 MSG_SAP,
                                                 FECHA_MSG)
                    VALUES ('',
                            p_msg,
                            p_msg,
                            SYSDATE);

               COMMIT;
         END;
      END IF;

      --  htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            l_resp_json := json (v_respuesta);
            l_data_json := json (l_resp_json.get ('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;


      IF l_data_json IS NULL
      THEN
         p_ret := 'E';
         p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
      END IF;

      RETURN l_data_json;
   END int_sap10_json_interfaces;



   FUNCTION int_sap10_json (p_cli_rut                  VARCHAR2,
                            p_canal_distribucion       VARCHAR2,
                            p_ret                  OUT VARCHAR2,
                            p_msg                  OUT VARCHAR2)
      RETURN json
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_resp_json   json;
      l_data_json   json;
   BEGIN
      p_ret := 'S';

      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;


      IF p_ret = 'S'
      THEN
         v_json :=
               '{   "Token": "'
            || v_token
            || '",
            "data":{          "cli_rut": "'
            || p_cli_rut
            || '",
                              "canal_distribucion": "'
            || p_canal_distribucion
            || '"
                   }
            }';


         BEGIN
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD005/INT_SAP10',
                           v_json);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;


      IF p_ret = 'S'
      THEN
         BEGIN
            l_resp_json := json (v_respuesta);
            l_data_json := json (l_resp_json.get ('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;


      IF l_data_json IS NULL
      THEN
         p_ret := 'E';
         p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
      END IF;

      RETURN l_data_json;
   END int_sap10_json;

   /*
   function lee_json(p_json json , p_campo varchar2) return varchar2 is
   v_return varchar2(32000);
   begin
       begin
           v_return := substr( p_json.get(p_campo).get_string, 1 ,32000)
       exception
       when SELF_IS_NULL then
           v_return := 'No Existe dato '''||p_campo||''' En el JSON';
       when others then
           v_return := 'Error:'||sqlerrm;
       end ;
       return v_return;
   end lee_json;*/

   FUNCTION lee_json (p_json json, p_campo VARCHAR2)
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (32000);
   BEGIN
      BEGIN
         v_return := SUBSTR (p_json.get (p_campo).get_string, 1, 32000);

         IF TRIM (v_return) IS NULL
         THEN
            v_return :=
               TRIM (SUBSTR (p_json.get (p_campo).get_number, 1, 32000));
         END IF;
      EXCEPTION
         WHEN SELF_IS_NULL
         THEN
            v_return := 'No Existe dato ''' || p_campo || ''' En el JSON';
         WHEN OTHERS
         THEN
            v_return := 'Error:' || SQLERRM;
      END;

      RETURN v_return;
   END lee_json;


   FUNCTION lee_json_n (p_json json, p_campo VARCHAR2)
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (32000);
   BEGIN
      BEGIN
         v_return := SUBSTR (p_json.get (p_campo).get_string, 1, 32000);

         IF TRIM (v_return) IS NULL
         THEN
            v_return :=
               TRIM (SUBSTR (p_json.get (p_campo).get_number, 1, 32000));
         END IF;
      EXCEPTION
         WHEN SELF_IS_NULL
         THEN
            v_return := '';
         WHEN OTHERS
         THEN
            v_return := '';
      END;

      RETURN v_return;
   END lee_json_n;


   PROCEDURE int_sap10 (p_cli_rut VARCHAR2, p_canal_distribucion VARCHAR2)
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_cli_json    json;

      v_ret         VARCHAR2 (1);
      v_msg         VARCHAR2 (5000);
   BEGIN
      BEGIN
         l_cli_json :=
            int_sap10_json (p_cli_rut,
                            p_canal_distribucion,
                            v_ret,
                            v_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
      END;


      HTP.p (v_ret || '<br>');

      IF v_ret = 'S'
      THEN
         HTP.p ('cli_rut:' || lee_json (l_cli_json, 'cli_rut'));
         HTP.p ('<br>');
         HTP.p ('cli_nombre:' || lee_json (l_cli_json, 'cli_nombre'));
         HTP.p ('<br>');
         HTP.p ('cli_direccion:' || lee_json (l_cli_json, 'cli_direccion'));
         HTP.p ('<br>');
         HTP.p ('cli_numero:' || lee_json (l_cli_json, 'cli_numero'));
         HTP.p ('<br>');
         HTP.p ('cli_comuna:' || lee_json (l_cli_json, 'cli_comuna'));
         HTP.p ('<br>');
         HTP.p ('cli_pais:' || lee_json (l_cli_json, 'cli_pais'));
         HTP.p ('<br>');
         HTP.p ('cli_region:' || lee_json (l_cli_json, 'cli_region'));
         HTP.p ('<br>');
         HTP.p ('cli_email:' || lee_json (l_cli_json, 'cli_email'));
         HTP.p ('<br>');
         HTP.p ('cli_telefono:' || lee_json (l_cli_json, 'cli_telefono'));
         HTP.p ('<br>');
         HTP.p (
               'cli_existe_canal_dist:'
            || lee_json (l_cli_json, 'cli_existe_canal_dist'));
      ELSE
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_sap10;

   --****************************************************************************************************
   --********************* CREACIÓN DE CLIENTES USANDO INTERFAZ******************************************
   --****************************************************************************************************

   FUNCTION int_leg04_json_interfaces (
      p_tipo_interlocutor            VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_rut                      VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_condicion_pago           VARCHAR2 DEFAULT NULL,
      p_cli_matricula                VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_cod_carrera              VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_agrupacion               VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_tratamiento              VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres1                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres2                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres3                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres4                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_cod_giro                 VARCHAR2 DEFAULT NULL, --parametro consulta rubro codigo del giro
      p_cli_sexo                     VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_rubro                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_direccion                VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_numero                   VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_codigo_comuna            VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_region                   VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_telefono                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_movil                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_email                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_canal_distribucion       VARCHAR2 DEFAULT NULL, --parametro consulta
      p_ret                      OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg                      OUT VARCHAR2               --mensaje de error
                                             )
      RETURN json
   IS
      v_json            VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta       CLOB;
      v_token           VARCHAR2 (500);

      l_resp_json       json;
      l_data_json       json_list;
      l_data_json2      json;
      l_RETURN_json     json;
      resp_json         json;
      v_grupo_cliente   VARCHAR (200);
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF (   p_cli_canal_distribucion = '11'
          OR p_cli_canal_distribucion = '12'
          OR p_cli_canal_distribucion = '13')
      THEN
         v_grupo_cliente := '15';
      ELSE
         v_grupo_cliente := '10';
      END IF;

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_json :=
               '{
                "Token": "'
            || v_token
            || '",
                "data": {
                               "Tipo_interlocutor": "'
            || p_tipo_interlocutor
            || '",
                               "Cli_rut": "'
            || p_cli_rut
            || '",
                               "Cli_matricula": "'
            || p_cli_matricula
            || '",
                               "Cli_cod_carrera": "'
            || p_cli_cod_carrera
            || '", // 03
                               "Cli_agrupacion": "'
            || p_cli_agrupacion
            || '",  // ZC01 nacional
                               "Cli_role": "FMCA02X",
                               "Cli_vigencia": "29991231",
                               "Cli_tratamiento": "'
            || p_cli_tratamiento
            || '", // 0003
                               "Cli_nombres1": "'
            || p_cli_nombres1
            || '",
                               "Cli_nombres2": "'
            || p_cli_nombres2
            || '",
                               "Cli_nombres3": "'
            || p_cli_nombres3
            || '", // codigo del giro
                               "Cli_nombres4": "'
            || p_cli_nombres4
            || '",
                               "Cli_sexo": "'
            || p_cli_sexo
            || '",
                               "Cli_busqueda": "P. NACIONAL",
                               "Cli_busqueda2": "'
            || p_cli_rubro
            || '", // rubro
                               "Cli_direccion": "'
            || p_cli_direccion
            || '",
                               "Cli_numero": "'
            || p_cli_numero
            || '",
                               "Cli_cod_postal": "",
                               "Cli_codigo_comuna": "'
            || p_cli_codigo_comuna
            || '",
                               "Cli_pais": "CL",
                               "Cli_region": "'
            || p_cli_region
            || '", //  ||p_cli_region||
                               "Cli_telefono": "'
            || p_cli_telefono
            || '",
                               "Cli_movil": "'
            || p_cli_movil
            || '",
                               "Cli_email": "'
            || p_cli_email
            || '",
                               "Cli_estado_civil": "1",
                               "Cli_nacionalidad": "CL",
                               "Cli_clase_ic": "9010",
                               "Cli_sociedad": "UT01",
                               "Cli_cuenta": "1103010010",
                               "Cli_condicion_pago": "'
            || p_cli_condicion_pago
            || '",
                               "Cli_vias_pago": "1",
                               "Cli_canal_distribucion": "'
            || p_cli_canal_distribucion
            || '", // 13
                               "Cli_zona_venta": "UT001",
                               "Cli_grupo_cliente": "'
            || v_grupo_cliente
            || '",
                               "Cli_pedido": "001",
                               "Cli_gpo_precio": "01",

                               "Cli_esquema_cliente": "01",
                               "Cli_expedicion": "01",
                               "Cli_grupo_imputacion": "01",
                               "Cli_clasificacion_fiscal": "0",

                               "Cli_id_banco": "",
                               "Cli_clave_pais_banco": "",
                               "Cli_clave_banco": "",
                               "Cli_cuenta_corriente": "",

                               "Pro_sociedad": "UT01",

                               "Pro_cuenta_mayor": "2102010010",
                               "Pro_cond_pago": "P030",
                               "Pro_verif_doble": "X",
                               "Pro_via_pago": "1",
                               "Pro_tipo_retencion": "",
                               "Pro_ind_retencion": "",
                               "Pro_sujeto_a_retencion": "",
                               "Pro_org_compras": "UT01",
                               "Pro_moneda": "CLP",
                               "Pro_grupo_esquema": "Z1",
                }
}'        ;

         /*Fin Json de entrada */


         --htp.p(v_json);
         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
            */
            /* g_sistema_sap_alan    sappoqa.utalca.cl:52000/RESTAdapter/SD004/INT_LEG04 -- sappodev.utalca.cl:51000/RESTAdapter/SD004/INT_LEG04*/



            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD004/INT_LEG04',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      --****IMPRIMER JSON DE RESPUESTA
      -- htp.p(v_respuesta);
      /* if(p_cli_canal_distribucion='17') then
           htp.p(v_json);
       end if;

       htp.p(p_cli_region);*/

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         --  l_data_json := json(l_resp_json.get('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* en duto debo descomentar insert into log_editorial_sap (item_type,
         item_key  ,
         msg_sap,fecha_msg) values (p_cli_rut,p_cli_nombres1, v_respuesta,sysdate);
         commit;*/



      /*
          --verifica que el data viene vacío
          if l_data_json is null then
              p_ret := 'E';
              p_msg := 'Error en el formato de la respuesta : '||sqlerrm;
          end if;
           /*retorna json   */
      RETURN l_RETURN_json;
   END int_leg04_json_interfaces;


   --****************************************************************************************************/



   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                CREA CLIENTE PAGO INT_LEG04 PRUEBA ***********
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

   FUNCTION int_leg04_json (
      p_tipo_interlocutor            VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_rut                      VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_condicion_pago           VARCHAR2 DEFAULT NULL,
      p_cli_matricula                VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_cod_carrera              VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_agrupacion               VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_tratamiento              VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres1                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres2                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_cod_giro                 VARCHAR2 DEFAULT NULL, --parametro consulta rubro codigo del giro
      p_cli_sexo                     VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_rubro                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_direccion                VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_numero                   VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_codigo_comuna            VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_region                   VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_telefono                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_movil                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_email                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_canal_distribucion       VARCHAR2 DEFAULT NULL, --parametro consulta
      p_ret                      OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg                      OUT VARCHAR2               --mensaje de error
                                             )
      RETURN json
   IS
      v_json          VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);

      l_resp_json     json;
      l_data_json     json_list;
      l_data_json2    json;
      l_RETURN_json   json;
      resp_json       json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_json :=
               '{
                "Token": "'
            || v_token
            || '",
                "data": {
                               "Tipo_interlocutor": "'
            || p_tipo_interlocutor
            || '",
                               "Cli_rut": "'
            || p_cli_rut
            || '",
                               "Cli_matricula": "'
            || p_cli_matricula
            || '",
                               "Cli_cod_carrera": "'
            || p_cli_cod_carrera
            || '", // 03
                               "Cli_agrupacion": "'
            || p_cli_agrupacion
            || '",  // ZC01 nacional
                               "Cli_role": "FMCA02X",
                               "Cli_vigencia": "29991231",
                               "Cli_tratamiento": "'
            || p_cli_tratamiento
            || '", // 0003
                               "Cli_nombres1": "'
            || p_cli_nombres1
            || '",
                               "Cli_nombres2": "'
            || p_cli_nombres2
            || '",
                               "Cli_nombres3": "'
            || p_cli_nombres2
            || '", // codigo del giro
                               "Cli_nombres4": "'
            || p_cli_cod_giro
            || '",
                               "Cli_sexo": "'
            || p_cli_sexo
            || '",
                               "Cli_busqueda": "'
            || p_cli_rut
            || '",
                               "Cli_busqueda2": "'
            || p_cli_rubro
            || '", // rubro
                               "Cli_direccion": "'
            || p_cli_direccion
            || '",
                               "Cli_numero": "'
            || p_cli_numero
            || '",
                               "Cli_cod_postal": "",
                               "Cli_codigo_comuna": "'
            || p_cli_codigo_comuna
            || '",
                               "Cli_pais": "CL",
                               "Cli_region": "'
            || p_cli_region
            || '", //  ||p_cli_region||
                               "Cli_telefono": "'
            || p_cli_telefono
            || '",
                               "Cli_movil": "'
            || p_cli_movil
            || '",
                               "Cli_email": "'
            || p_cli_email
            || '",
                               "Cli_estado_civil": "1",
                               "Cli_nacionalidad": "CL",
                               "Cli_clase_ic": "9010",
                               "Cli_sociedad": "UT01",
                               "Cli_cuenta": "1103010010",
                               "Cli_condicion_pago": "'
            || p_cli_condicion_pago
            || '",
                               "Cli_vias_pago": "1",
                               "Cli_canal_distribucion": "'
            || p_cli_canal_distribucion
            || '", // 13
                               "Cli_zona_venta": "UT001",
                               "Cli_grupo_cliente": "10",
                               "Cli_pedido": "001",
                               "Cli_gpo_precio": "01",


                               "Cli_esquema_cliente": "01",
                               "Cli_expedicion": "01",
                               "Cli_grupo_imputacion": "01",
                               "Cli_clasificacion_fiscal": "0",

                               "Cli_id_banco": "",
                               "Cli_clave_pais_banco": "",
                               "Cli_clave_banco": "",
                               "Cli_cuenta_corriente": "",

                               "Pro_sociedad": "UT01",

                               "Pro_cuenta_mayor": "2102010010",
                               "Pro_cond_pago": "P030",
                               "Pro_verif_doble": "X",
                               "Pro_via_pago": "1",
                               "Pro_tipo_retencion": "",
                               "Pro_ind_retencion": "",
                               "Pro_sujeto_a_retencion": "",
                               "Pro_org_compras": "UT01",
                               "Pro_moneda": "CLP",
                               "Pro_grupo_esquema": "Z1",
                }
}'        ;

         /*Fin Json de entrada */


         --htp.p(v_json);
         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
            */
            /* g_sistema_sap_alan    sappoqa.utalca.cl:52000/RESTAdapter/SD004/INT_LEG04 -- sappodev.utalca.cl:51000/RESTAdapter/SD004/INT_LEG04*/



            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD004/INT_LEG04',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO LOG_CREA_CLIENTE_SAP (RUT,
                                                 MENSAJE_SQL,
                                                 MSG_SAP,
                                                 FECHA_MSG)
                    VALUES (p_cli_rut,
                            p_msg,
                            'CREACLIENTE: ' || v_respuesta,
                            SYSDATE);

               COMMIT;
         END;
      END IF;

      --****IMPRIMER JSON DE RESPUESTA
      --htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);

            INSERT INTO LOG_CREA_CLIENTE_SAP (RUT,
                                              MENSAJE_SQL,
                                              MSG_SAP,
                                              FECHA_MSG)
                 VALUES (p_cli_rut,
                         SUBSTR (v_json, 1, 4000),
                         'CREACLIENTE: ' || v_respuesta,
                         SYSDATE);

            COMMIT;
         /* seccion data la inserta en un  json*/
         --  l_data_json := json(l_resp_json.get('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;

               INSERT INTO LOG_CREA_CLIENTE_SAP (RUT,
                                                 MENSAJE_SQL,
                                                 MSG_SAP,
                                                 FECHA_MSG)
                    VALUES (p_cli_rut,
                            p_msg,
                            'CREACLIENTE: ' || v_respuesta,
                            SYSDATE);

               COMMIT;
         END;
      END IF;

      /* en duto debo descomentar insert into log_editorial_sap (item_type,
         item_key  ,
         msg_sap,fecha_msg) values (p_cli_rut,p_cli_nombres1, v_respuesta,sysdate);
         commit;*/
      /*
          --verifica que el data viene vacío
          if l_data_json is null then
              p_ret := 'E';
              p_msg := 'Error en el formato de la respuesta : '||sqlerrm;
          end if;
           /*retorna json   */
      RETURN l_RETURN_json;
   END int_leg04_json;


   -- i.villaseca, integracion paga deuda en SAP
   FUNCTION int_leg02_portal_sap (p_idcliente       VARCHAR2,
                                  p_num_op          VARCHAR2,
                                  p_ret         OUT VARCHAR2,
                                  p_msg         OUT VARCHAR2,
                                  p_tipo            VARCHAR2 DEFAULT NULL)
      RETURN json
   IS
        p_tipo_documento    VARCHAR2(1000);
        p_fecha_documento   VARCHAR2(1000);
        p_cuponera          VARCHAR2(1000);
        p_documento         VARCHAR2(1000);
        p_documento_int     VARCHAR2(1000);
        p_cuota             VARCHAR2(1000);
        p_fecha_vencimiento VARCHAR2(1000);
        p_monto_local       VARCHAR2(1000);
        p_empresa           VARCHAR2(1000);
        p_carrera           VARCHAR2(1000);
        p_moneda            VARCHAR2(1000);
        p_nro_matricula     VARCHAR2(1000);
        p_centro_beneficio  VARCHAR2(1000);
        p_monto             VARCHAR2(1000);
        p_posicion          VARCHAR2(4);
        p_posicion_rep      VARCHAR2(3);
        p_posicion_par      VARCHAR2(3);
        v_tipo_doc          VARCHAR2(50);
        v_json              CLOB;
        v_json_inicio       CLOB;
        v_json_fin          CLOB;
        v_respuesta         CLOB;
        v_respuesta_int     CLOB;
        v_json_intereses    CLOB;
        v_token             VARCHAR2(500);
        l_cli_json          json;
        l_cli_json_data     json_list;
        p_tipo_doc          VARCHAR2(10);
        l_resp_json         json;
        l_data_json         json;
        id_log              NUMBER;

      --cursor de deudas en tabla temporal, agrupada por tipo
        CURSOR c_deudas_actuales (
            p_idcliente NUMBER
        ) IS
       /* SELECT DISTINCT
            pade_tipo_documento,
            e.clase_documento_sap -- se agrega nuevo campo para integración SAP DS 19/05/2025
        FROM
            vec_cob01.pop_pagos_detalle_temp_sap a
            JOIN vec_cob02.webpay_trasaccion d ON TO_CHAR(d.id_sesion) = TO_CHAR(a.pa_nro_operacion)
            JOIN vec_cob02.tipo_pago_descripcion e ON d.tipo_pago = e.codigo_pago
        WHERE
                pa_rut = p_idcliente
            AND pa_nro_operacion = p_num_op
            AND pade_tipo_documento <> 'IE';*/
            
           SELECT DISTINCT pade_tipo_documento
           FROM VEC_COB01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND PA_NRO_OPERACION = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
        CURSOR c_deudas_actuales_detalle (
            p_tipo_doc VARCHAR2
        ) IS
        SELECT
            *
        FROM
            vec_cob01.pop_pagos_detalle_temp_sap a
        WHERE
                pa_rut = p_idcliente
            AND pade_tipo_documento = p_tipo_doc
            AND pa_nro_operacion = p_num_op
            AND pade_tipo_documento <> 'IE';

    BEGIN
        p_ret := 'S';
       IF p_tipo = 'X' THEN
            v_tipo_doc := 'Z8';
        ELSIF p_tipo = 'Y' THEN
            v_tipo_doc := 'Z9';
        ELSE
            v_tipo_doc := get_clase_documento_sap(p_idcliente,p_num_op);
        END IF;

        BEGIN
            v_token := pkg_token.get_token;
            v_json_inicio := '{"Token": "'
                             || v_token
                             || '",';
        EXCEPTION
            WHEN OTHERS THEN
                p_ret := 'E';
                p_msg := 'error recuperando el TOKEN:' || sqlerrm;
                RETURN l_data_json;
        END;

        IF p_ret = 'S' THEN
            SELECT
                seq_id_log_intleg02portal.NEXTVAL
            INTO id_log
            FROM
                dual;

            FOR reg_grupo IN c_deudas_actuales(p_idcliente) LOOP
                v_json_fin := '';
                v_json := '';
                v_json_intereses := '';
                FOR reg IN c_deudas_actuales_detalle(reg_grupo.pade_tipo_documento) LOOP
                    --p_tipo_documento := reg_grupo.clase_documento_sap; ---- se cambia v_tipo_doc a nuevo campo para integración SAP DS 19/05/2025
                    p_tipo_documento := v_tipo_doc;
                    -- cambios para no tener error con las fechas de los reprocesos
                    begin
                        select to_char(t.pa_fecha, 'YYYYMMDD') into p_fecha_documento from vec_cob01.pop_pagos_temp t where t.pa_nro_operacion=reg.pa_nro_operacion;
                    exception when others then 
                        p_fecha_documento := to_char(sysdate, 'YYYYMMDD');
                    end;
                    --- fin 
                    
                    --p_fecha_documento := to_char(sysdate, 'YYYYMMDD');
                    p_cuponera := reg.pa_nro_operacion;
                    p_documento := reg.pade_nro_documento;
                    p_cuota := reg.pade_cuota;
                    p_fecha_vencimiento := reg.pade_fec_vencimiento;
                    p_monto_local := reg.pade_monto_local;
                    p_empresa := 'UT01';
                    p_carrera := reg.pade_nro_carrera;
                    p_moneda := reg.pade_moneda;
                    p_nro_matricula := reg.pade_matricula;
                    p_centro_beneficio := '';
                    p_monto := reg.pade_monto;
                    v_respuesta_int := '';
                    p_posicion := reg.posicion;
                    p_posicion_rep := reg.posicion_rep;
                    p_posicion_par := reg.posicion_par;
                    IF ( reg.pade_moneda <> 'CLP' ) THEN
                        IF ( reg.pade_moneda = 'UF' ) THEN
                            p_monto := to_char(TO_NUMBER(reg.pade_monto) * 100);
                            p_monto := replace(p_monto, ',', '.');
                        ELSE
                            p_monto := to_char(TO_NUMBER(reg.pade_monto) * 100);
                            p_monto := replace(p_monto, ',', '.');
                        END IF;

                        p_monto := trim(p_monto);
                    ELSE
                        p_monto := reg.pade_monto || '00';
                    END IF;

                    v_respuesta := '"data":{"Codigo_cli": "'
                                   || p_idcliente
                                   || '","Tipo_documento": "'
                                   || p_tipo_documento
                                   || '","Fecha_documento": "'
                                   || p_fecha_documento
                                   || '","Cuponera": "'
                                   || p_cuponera
                                   || '","Documento": "'
                                   || p_documento
                                   || '","Cuota": "'
                                   || p_posicion
                                   || '","Fecha_vencimiento": "'
                                   || p_fecha_vencimiento
                                   || '","Monto_local": "'
                                   || p_monto
                                   || '","Empresa": "'
                                   || p_empresa
                                   || '","Carrera": "'
                                   || p_carrera
                                   || '","Moneda": "'
                                   || p_moneda
                                   || '","Nro_matricula": "'
                                   || p_nro_matricula
                                   || '","Centro_beneficio": "'
                                   || p_centro_beneficio
                                   || '","Descripcion": "Pago '
                                   || p_tipo_documento
                                   || ' Portal cuota '
                                   || p_cuota
                                   || '","posicion_par": "'
                                   || p_posicion_par
                                   || '","posicion_rep": "'
                                   || p_posicion_rep
                                   || '"},';
                    -- se agrega nuevo campo para integración SAP DS 19/05/2025
                    IF reg.pade_nro_documento IS NOT NULL THEN
                  /*IF LENGTH (TRIM (reg.pade_documento_interes)) > 0 THEN
                     p_tipo_documento :='Z5';
                     p_documento_int  := reg.pade_documento_interes;
                     p_monto          := reg.pade_monto_local_interes||'00';
                     --v_respuesta_int  := '"data":{"Codigo_cli": "'||p_idcliente||'","Tipo_documento": "'||p_tipo_documento||'","Fecha_documento": "'||p_fecha_documento||'","Cuponera": "'||p_cuponera||'","Documento": "'||p_documento_int||'","Cuota": "0001","Fecha_vencimiento": "'||p_fecha_vencimiento||'","Monto_local": "'||p_monto||'","Empresa": "'||p_empresa||'","Carrera": "'||p_carrera||'","Moneda": "'||p_moneda||'","Nro_matricula": "'||p_nro_matricula||'","Centro_beneficio": "'||p_centro_beneficio||'","Descripcion": "Pago Int.'||p_tipo_documento||' Portal cuota '||p_cuota||'","posicion_par": "000","posicion_rep": "000"},';
                     v_respuesta_int  := '"data":{"Codigo_cli": "'||p_idcliente||'","Tipo_documento": "'||p_tipo_documento||'","Fecha_documento": "'||p_fecha_documento||'","Cuponera": "'||p_cuponera||'","Documento": "'||p_documento_int||'","Cuota": "0001","Fecha_vencimiento": "'||p_fecha_vencimiento||'","Monto_local": "'||p_monto||'","Empresa": "'||p_empresa||'","Carrera": "'||p_carrera||'","Moneda": "'||p_moneda||'","Nro_matricula": "'||p_nro_matricula||'","Centro_beneficio": "'||p_centro_beneficio||'","Descripcion": "Int. mora Pago '||p_tipo_documento||' Portal cuota '||p_cuota||'","posicion_par": "'||p_posicion_par||'","posicion_rep": "'||p_posicion_rep||'"},';

                  END IF;*/

                        IF length(trim(reg.pade_documento_interes)) > 0 THEN -- se cambia reg.pade_documento_interes a reg.pade_interes 8/11/20224 DS
                            --p_tipo_documento := reg_grupo.clase_documento_sap; ---- se cambia v_tipo_doc a nuevo campo para integración SAP DS 19/05/2025--v_tipo_doc;
                            p_documento_int := reg.pade_documento_interes;
                     --p_monto          := round(reg.pade_monto_local_interes)||'00';
                            p_monto := '00'
                                       || to_char(100 * TO_NUMBER(reg.pade_interes));
                            p_monto := replace(p_monto, ',', '.');
                     -- p_moneda := 'CLP';
                            v_respuesta_int := '"data":{"Codigo_cli": "'
                                               || p_idcliente
                                               || '","Tipo_documento": "'
                                               || p_tipo_documento
                                               || '","Fecha_documento": "'
                                               || p_fecha_documento
                                               || '","Cuponera": "'
                                               || p_cuponera
                                               || '","Documento": "'
                                               || p_documento_int   -- se cambia p_documento_int a p_documento 08/11/2024 DS
                                               || '","Cuota": "0001","Fecha_vencimiento": "'
                                               || p_fecha_vencimiento
                                               || '","Monto_local": "'
                                               || p_monto
                                               || '","Empresa": "'
                                               || p_empresa
                                               || '","Carrera": "'
                                               || p_carrera
                                               || '","Moneda": "'
                                               || p_moneda
                                               || '","Nro_matricula": "'
                                               || p_nro_matricula
                                               || '","Centro_beneficio": "'
                                               || p_centro_beneficio
                                               || '","Descripcion": "Int. mora Pago '
                                               || p_tipo_documento
                                               || ' Portal cuota '
                                               || p_cuota
                                               || '","posicion_par": "'
                                               || p_posicion_par
                                               || '","posicion_rep": "'
                                               || p_posicion_rep
                                               || '"},';

                        END IF;
                    END IF;

                    v_json := v_json
                              || v_respuesta
                              || v_respuesta_int;
                END LOOP;

                v_json_fin := ' }';
                v_json := substr(v_json, 1, length(v_json) - 1);
                v_json := v_json_inicio
                          || v_json
                          || v_json_fin;

            --INNSERTO LOG DE REGISTRO DE JSON DE LALLAMDA
                INSERT INTO log_portal_pagos_sap (
                    id,
                    tipo_llamada,
                    integracion,
                    pade_nro_documento,
                    tipo_integracion,
                    dato1,
                    dato2,
                    msg_sap,
                    fecha_msg,
                    msg_sap2
                ) VALUES (
                    id_log,
                    'S',
                    '** INTLEG02(PAGA DEUDA) - '
                    || g_sistema_sap
                    || '/RESTAdapter/FI002/INT_LEG02',
                    p_documento,
                    'Pago ' || p_tipo_documento,
                    p_idcliente,
                    p_num_op,
                    substr(v_json, 1, 4000),
                    sysdate,
                    v_json
                );

                COMMIT;
            --LLAMDA A INTEGRACION DE SAP CON EL JSON
                v_respuesta := call_url_p(g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02', v_json);

            --REVISAMOS LA RESUESTA DEL JSON
                IF p_ret = 'S' THEN
                    BEGIN
                        l_resp_json :=
                            JSON(
                                v_respuesta
                            );
                        l_data_json :=
                            JSON(
                                l_resp_json.get('data')
                            );
                        p_ret := lee_json(l_data_json, 'TYPE');
                        p_msg := lee_json(l_data_json, 'MESSAGE');
                    EXCEPTION
                        WHEN OTHERS THEN
                            p_ret := 'E';
                            p_msg := 'Error en el formato de la respuesta : ' || sqlerrm;
                            l_data_json := NULL;
                    END;
                END IF;

                IF l_data_json IS NULL THEN
                    p_ret := 'E';
                    p_msg := 'Error en el formato de la respuesta : ' || sqlerrm;
                END IF;

         --INSERTAMOS EN TABLA DE LOG DE INTEGRACION
                INSERT INTO log_portal_pagos_sap (
                    id,
                    tipo_llamada,
                    integracion,
                    pade_nro_documento,
                    tipo_integracion,
                    dato1,
                    dato2,
                    msg_sap,
                    fecha_msg
                ) VALUES (
                    id_log,
                    'R',
                    '** INTLEG02(PAGA DEUDA)',
                    p_documento,
                    'Pago Cuota ' || p_cuota,
                    p_idcliente,
                    p_num_op,
                    v_respuesta,
                    sysdate
                );

                COMMIT;
            END LOOP;
         --RETRONAMOS EL OBJETO JSON-
            RETURN l_data_json;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_ret := 'E';
            p_msg := 'error en la funcion:'
                     || sqlerrm
                     || dbms_utility.format_error_backtrace;
            RETURN l_data_json;
    END;


   FUNCTION int_leg02_portal_sap_pac (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2,
      p_msg         OUT VARCHAR2,
      p_tipo            VARCHAR2 DEFAULT NULL)
      RETURN json
   IS
      p_tipo_documento      VARCHAR2 (1000);
      p_fecha_documento     VARCHAR2 (1000);
      p_cuponera            VARCHAR2 (1000);
      p_documento           VARCHAR2 (1000);
      p_documento_int       VARCHAR2 (1000);
      p_cuota               VARCHAR2 (1000);
      p_fecha_vencimiento   VARCHAR2 (1000);
      p_monto_local         VARCHAR2 (1000);
      p_empresa             VARCHAR2 (1000);
      p_carrera             VARCHAR2 (1000);
      p_moneda              VARCHAR2 (1000);
      p_nro_matricula       VARCHAR2 (1000);
      p_centro_beneficio    VARCHAR2 (1000);
      p_monto               VARCHAR2 (1000);
      p_posicion            VARCHAR2 (4);
      p_posicion_rep        VARCHAR2 (3);
      p_posicion_par        VARCHAR2 (3);
      v_tipo_doc            VARCHAR2 (50);
      v_json                CLOB;
      v_json_inicio         CLOB;
      v_json_fin            CLOB;
      v_respuesta           CLOB;
      v_respuesta_int       CLOB;
      v_json_intereses      CLOB;
      v_token               VARCHAR2 (500);
      l_cli_json            json;
      l_cli_json_data       json_list;
      p_tipo_doc            VARCHAR2 (10);
      l_resp_json           json;
      l_data_json           json;
      id_log                NUMBER;
      v_fecha_debito        VARCHAR2 (1000);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (
         p_idcliente    NUMBER)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pa_nro_operacion = p_num_op
                AND pade_tipo_documento <> 'IE';

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op
                AND pade_tipo_documento <> 'IE';
   BEGIN
      p_ret := 'S';

      IF p_tipo = 'X'
      THEN
         v_tipo_doc := 'Z8';
      ELSIF p_tipo = 'Y'
      THEN
         v_tipo_doc := 'Z9';
      ELSE
         v_tipo_doc := get_clase_documento_sap(p_idcliente,p_num_op);
      END IF;

      BEGIN
         v_token := pkg_token.get_token;
         v_json_inicio := '{"Token": "' || v_token || '",';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            RETURN l_data_json;
      END;



      SELECT TO_CHAR (PACR_FECHA_DEBITO, 'YYYYMMDD')
        INTO v_fecha_debito
        FROM vec_cob01.pac_rendicion
       WHERE pacr_num_factura = p_num_op AND PACR_ESTADO_DEBITO = '00';

      IF p_ret = 'S'
      THEN
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            v_json_fin := '';
            v_json := '';
            v_json_intereses := '';

            FOR reg
               IN c_deudas_actuales_detalle (reg_grupo.pade_tipo_documento)
            LOOP
               p_tipo_documento := v_tipo_doc;
               p_fecha_documento := v_fecha_debito;
               p_cuponera := reg.pa_nro_operacion;
               p_documento := reg.pade_nro_documento;
               p_cuota := reg.pade_cuota;
               p_fecha_vencimiento := reg.pade_fec_vencimiento;
               p_monto_local := reg.pade_monto_local;
               p_empresa := 'UT01';
               p_carrera := reg.pade_nro_carrera;
               p_moneda := reg.pade_moneda;
               p_nro_matricula := reg.pade_matricula;
               p_centro_beneficio := '';
               p_monto := reg.pade_monto;
               v_respuesta_int := '';
               p_posicion := reg.posicion;
               p_posicion_rep := reg.posicion_rep;
               p_posicion_par := reg.posicion_par;

               IF (reg.pade_moneda <> 'CLP')
               THEN
                  IF (reg.pade_moneda = 'UF')
                  THEN
                     p_monto := TO_CHAR (TO_NUMBER (reg.pade_monto) * 100);
                     p_monto := REPLACE (p_monto, ',', '.');
                  ELSE
                     p_monto := TO_CHAR (TO_NUMBER (reg.pade_monto) * 100);
                     p_monto := REPLACE (p_monto, ',', '.');
                  END IF;

                  p_monto := TRIM (p_monto);
               ELSE
                  p_monto := reg.pade_monto || '00';
               END IF;

               v_respuesta :=
                     '"data":{"Codigo_cli": "'
                  || p_idcliente
                  || '","Tipo_documento": "'
                  || p_tipo_documento
                  || '","Fecha_documento": "'
                  || p_fecha_documento
                  || '","Cuponera": "'
                  || p_cuponera
                  || '","Documento": "'
                  || p_documento
                  || '","Cuota": "'
                  || p_posicion
                  || '","Fecha_vencimiento": "'
                  || p_fecha_vencimiento
                  || '","Monto_local": "'
                  || p_monto
                  || '","Empresa": "'
                  || p_empresa
                  || '","Carrera": "'
                  || p_carrera
                  || '","Moneda": "'
                  || p_moneda
                  || '","Nro_matricula": "'
                  || p_nro_matricula
                  || '","Centro_beneficio": "'
                  || p_centro_beneficio
                  || '","Descripcion": "Pago '
                  || p_tipo_documento
                  || ' Portal cuota '
                  || p_cuota
                  || '","posicion_par": "'
                  || p_posicion_par
                  || '","posicion_rep": "'
                  || p_posicion_rep
                  || '"},';

               IF reg.pade_nro_documento IS NOT NULL
               THEN
                  /*IF LENGTH (TRIM (reg.pade_documento_interes)) > 0 THEN
                     p_tipo_documento :='Z5';
                     p_documento_int  := reg.pade_documento_interes;
                     p_monto          := reg.pade_monto_local_interes||'00';
                     --v_respuesta_int  := '"data":{"Codigo_cli": "'||p_idcliente||'","Tipo_documento": "'||p_tipo_documento||'","Fecha_documento": "'||p_fecha_documento||'","Cuponera": "'||p_cuponera||'","Documento": "'||p_documento_int||'","Cuota": "0001","Fecha_vencimiento": "'||p_fecha_vencimiento||'","Monto_local": "'||p_monto||'","Empresa": "'||p_empresa||'","Carrera": "'||p_carrera||'","Moneda": "'||p_moneda||'","Nro_matricula": "'||p_nro_matricula||'","Centro_beneficio": "'||p_centro_beneficio||'","Descripcion": "Pago Int.'||p_tipo_documento||' Portal cuota '||p_cuota||'","posicion_par": "000","posicion_rep": "000"},';
                     v_respuesta_int  := '"data":{"Codigo_cli": "'||p_idcliente||'","Tipo_documento": "'||p_tipo_documento||'","Fecha_documento": "'||p_fecha_documento||'","Cuponera": "'||p_cuponera||'","Documento": "'||p_documento_int||'","Cuota": "0001","Fecha_vencimiento": "'||p_fecha_vencimiento||'","Monto_local": "'||p_monto||'","Empresa": "'||p_empresa||'","Carrera": "'||p_carrera||'","Moneda": "'||p_moneda||'","Nro_matricula": "'||p_nro_matricula||'","Centro_beneficio": "'||p_centro_beneficio||'","Descripcion": "Int. mora Pago '||p_tipo_documento||' Portal cuota '||p_cuota||'","posicion_par": "'||p_posicion_par||'","posicion_rep": "'||p_posicion_rep||'"},';

                  END IF;*/

                  IF LENGTH (TRIM (reg.pade_documento_interes)) > 0
                  THEN -- se cambia reg.pade_documento_interes a reg.pade_interes 8/11/20224 DS
                     --p_tipo_documento := v_tipo_doc;
                     p_documento_int := reg.pade_documento_interes;
                     --p_monto          := round(reg.pade_monto_local_interes)||'00';
                     p_monto :=
                        '00' || TO_CHAR (100 * TO_NUMBER (reg.pade_interes));
                     p_monto := REPLACE (p_monto, ',', '.');
                     -- p_moneda := 'CLP';
                     v_respuesta_int :=
                           '"data":{"Codigo_cli": "'
                        || p_idcliente
                        || '","Tipo_documento": "'
                        || p_tipo_documento
                        || '","Fecha_documento": "'
                        || p_fecha_documento
                        || '","Cuponera": "'
                        || p_cuponera
                        || '","Documento": "'
                        || p_documento_int -- se cambia p_documento_int a p_documento 08/11/2024 DS
                        || '","Cuota": "0001","Fecha_vencimiento": "'
                        || p_fecha_vencimiento
                        || '","Monto_local": "'
                        || p_monto
                        || '","Empresa": "'
                        || p_empresa
                        || '","Carrera": "'
                        || p_carrera
                        || '","Moneda": "'
                        || p_moneda
                        || '","Nro_matricula": "'
                        || p_nro_matricula
                        || '","Centro_beneficio": "'
                        || p_centro_beneficio
                        || '","Descripcion": "Int. mora Pago '
                        || p_tipo_documento
                        || ' Portal cuota '
                        || p_cuota
                        || '","posicion_par": "'
                        || p_posicion_par
                        || '","posicion_rep": "'
                        || p_posicion_rep
                        || '"},';
                  END IF;
               END IF;

               v_json :=
                  v_json || v_respuesta || v_respuesta_int;
            END LOOP;

            v_json_fin := ' }';
            v_json := SUBSTR (v_json, 1, LENGTH (v_json) - 1);
            v_json := v_json_inicio || v_json || v_json_fin;

            --INNSERTO LOG DE REGISTRO DE JSON DE LALLAMDA
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                    VALUES (
                              id_log,
                              'S',
                                 '** INTLEG02(PAGA DEUDA) - '
                              || g_sistema_sap
                              || '/RESTAdapter/FI002/INT_LEG02',
                              p_documento,
                              'Pago ' || p_tipo_documento,
                              p_idcliente,
                              p_num_op,
                              SUBSTR (v_json, 1, 4000),
                              SYSDATE);

            COMMIT;
            --LLAMDA A INTEGRACION DE SAP CON EL JSON
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02',
                           v_json);

            --REVISAMOS LA RESUESTA DEL JSON
            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := JSON (v_respuesta);
                  l_data_json := JSON (l_resp_json.get ('data'));
                  p_ret := lee_json (l_data_json, 'TYPE');
                  p_msg := lee_json (l_data_json, 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_ret := 'E';
                     p_msg :=
                        'Error en el formato de la respuesta : ' || SQLERRM;
                     l_data_json := NULL;
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
            END IF;

            --INSERTAMOS EN TABLA DE LOG DE INTEGRACION
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'R',
                         '** INTLEG02(PAGA DEUDA)',
                         p_documento,
                         'Pago Cuota ' || p_cuota,
                         p_idcliente,
                         p_num_op,
                         v_respuesta,
                         SYSDATE);

            COMMIT;
         END LOOP;

         --RETRONAMOS EL OBJETO JSON-
         RETURN l_data_json;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg :=
               'error en la funcion:'
            || SQLERRM
            || DBMS_UTILITY.format_error_backtrace;
         RETURN l_data_json;
   END;


   PROCEDURE int_leg04 (p_tipo_interlocutor         VARCHAR2 DEFAULT NULL,
                        p_cli_rut                   VARCHAR2 DEFAULT NULL,
                        p_cli_condicion_pago        VARCHAR2 DEFAULT NULL,
                        p_cli_matricula             VARCHAR2 DEFAULT NULL,
                        p_cli_cod_carrera           VARCHAR2 DEFAULT NULL,
                        p_cli_agrupacion            VARCHAR2 DEFAULT NULL,
                        p_cli_tratamiento           VARCHAR2 DEFAULT NULL,
                        p_cli_nombres1              VARCHAR2 DEFAULT NULL,
                        p_cli_nombres2              VARCHAR2 DEFAULT NULL,
                        p_cli_cod_giro              VARCHAR2 DEFAULT NULL,
                        p_cli_sexo                  VARCHAR2 DEFAULT NULL,
                        p_cli_rubro                 VARCHAR2 DEFAULT NULL,
                        p_cli_direccion             VARCHAR2 DEFAULT NULL,
                        p_cli_numero                VARCHAR2 DEFAULT NULL,
                        p_cli_codigo_comuna         VARCHAR2 DEFAULT NULL,
                        p_cli_region                VARCHAR2 DEFAULT NULL,
                        p_cli_telefono              VARCHAR2 DEFAULT NULL,
                        p_cli_email                 VARCHAR2 DEFAULT NULL,
                        p_cli_canal_distribucion    VARCHAR2 DEFAULT NULL)
   IS
      v_json            VARCHAR2 (1500);
      v_respuesta       CLOB;
      v_token           VARCHAR2 (500);
      l_cli_json        json;
      l_cli_json_data   json_list;
      v_ret             VARCHAR2 (1);
      v_msg             VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sapxx_json y en la variable l_cli_json recibe el json del data*/
      BEGIN
         /*llama a la función int_leg04_json y en la variable l_cli_json recibe el json del data   p_cli_cod_carrera,p_cli_agrupacion ,*/

         NULL;

         l_cli_json :=
            int_leg04_json (p_tipo_interlocutor,
                            p_cli_rut,
                            'D000',
                            p_cli_matricula,
                            p_cli_cod_carrera,
                            p_cli_agrupacion,
                            p_cli_tratamiento,
                            p_cli_nombres1,
                            p_cli_nombres2,
                            p_cli_cod_giro,
                            p_cli_sexo,
                            p_cli_rubro,
                            p_cli_direccion,
                            p_cli_numero,
                            p_cli_codigo_comuna,
                            p_cli_region,
                            p_cli_telefono,
                            '',
                            p_cli_email,
                            p_cli_canal_distribucion,
                            v_ret,
                            v_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
      END;

      HTP.p (v_ret || '<br>');

      /* imprime estructura json por serpara y se revisa formato */
      IF v_ret = 'S'
      THEN
         /*
                 htp.p('TYPE:'||lee_json(l_cli_json , 'TYPE')||'<br>');
                 htp.p('MESSAGE:'||lee_json(l_cli_json , 'MESSAGE')||'<br>');
                 htp.p('LOG_MSG_NO:'||lee_json(l_cli_json , 'LOG_MSG_NO')||'<br>');
                 htp.p('MESSAGE_V1:'||lee_json(l_cli_json , 'MESSAGE_V1')||'<br>');
                 htp.p('<br>');
         */

         --htp.p(l_cli_json.COUNT);

         FOR i IN 1 .. l_cli_json.COUNT
         LOOP
            HTP.p ('REGISTRO:' || i || '<br>');
            HTP.p (
                  'TYPE:'
               || lee_json (json (l_cli_json.get (i)), 'TYPE')
               || '<br>');
            HTP.p (
               'ID:' || lee_json (json (l_cli_json.get (i)), 'ID') || '<br>');
            HTP.p (
                  'NUMBER:'
               || lee_json (json (l_cli_json.get (i)), 'NUMBER')
               || '<br>');
            HTP.p (
                  'MESSAGE:'
               || lee_json (json (l_cli_json.get (i)), 'MESSAGE')
               || '<br>');
            HTP.p (
                  'LOG_MSG_NO:'
               || lee_json (json (l_cli_json.get (i)), 'LOG_MSG_NO')
               || '<br>');
            HTP.p (
                  'MESSAGE_V1:'
               || lee_json (json (l_cli_json.get (i)), 'MESSAGE_V1')
               || '<br>');
            HTP.p (
                  'MESSAGE_V2:'
               || lee_json (json (l_cli_json.get (i)), 'MESSAGE_V2')
               || '<br>');
            HTP.p (
                  'MESSAGE_V3:'
               || lee_json (json (l_cli_json.get (i)), 'MESSAGE_V3')
               || '<br>');
            HTP.p (
                  'MESSAGE_V4:'
               || lee_json (json (l_cli_json.get (i)), 'MESSAGE_V4')
               || '<br>');
            HTP.p (
                  'ROW:'
               || lee_json (json (l_cli_json.get (i)), 'ROW')
               || '<br>');
            HTP.p (
                  'SYSTEM:'
               || lee_json (json (l_cli_json.get (i)), 'SYSTEM')
               || '<br>');

            HTP.p ('<br>');
         END LOOP;
      ELSE
         /*imprime mensaje de error*/
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_leg04;

   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               FIN  CREA CLIENTE INT_LEG04 ***********
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



















   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                PAGO DE DEUDA INT_LEG02
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

   FUNCTION int_leg02_json (p_codigo_cli              VARCHAR2, --parametro consulta
                            p_tipo_documento          VARCHAR2, --parametro consulta
                            p_fecha_documento         VARCHAR2, --parametro consulta
                            p_cuponera                VARCHAR2, --parametro consulta
                            p_documento               VARCHAR2, --parametro consulta
                            p_cuota                   VARCHAR2, --parametro consulta
                            p_fecha_vencimiento       VARCHAR2, --parametro consulta
                            p_monto_local             VARCHAR2, --parametro consulta
                            p_empresa                 VARCHAR2, --parametro consulta
                            p_carrera                 VARCHAR2, --parametro consulta
                            p_moneda                  VARCHAR2, --parametro consulta
                            p_nro_matricula           VARCHAR2, --parametro consulta
                            p_ret                 OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                            p_msg                 OUT VARCHAR2 --mensaje de error
                                                              )
      RETURN json
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_resp_json   json;
      l_data_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         /* v_json := '{
                         "Token": "7CEB765280350E9B79562A82428300832BEE1C96B9BE3507B747552BF3DFCD6C",
                         "data":{
                             "Codigo_cli": "'||p_codigo_cli||'",                     // 699617911
                             "Tipo_documento": "'||p_tipo_documento||'",             // Z2
                             "Fecha_documento": "'||p_fecha_documento||'",           // 20170207
                             "Cuponera": "'||p_cuponera||'",                         // 1234567890
                             "Documento": "'||p_documento||'",                       // 003000000046
                             "Cuota": "'||p_cuota||'",   // 1
                             "Fecha_vencimiento": "'||p_fecha_vencimiento||'",       // 20170203
                             "Monto_local": "'||p_monto_local||'",                   // 230000
                             "Empresa": "'||p_empresa||'",                           // UT01
                             "Carrera": "'||p_carrera||'",                           // 06
                             "Moneda": "'||p_moneda||'",                             // CLP
                             "Nro_matricula": "'||p_nro_matricula||'",               // 763498012
                             "Centro_beneficio": "",
                             "Descripcion": "Test Interface Pago"
                         }

 }';*/
         v_json :=
               '{
                "Token": "'
            || v_token
            || '",
                "data":{
                               "Codigo_cli": "'
            || p_codigo_cli
            || '",
                               "Tipo_documento": "'
            || p_tipo_documento
            || '",
                               "Fecha_documento": "'
            || p_fecha_documento
            || '",
                               "Cuponera": "'
            || p_cuponera
            || '",
                               "Documento": "'
            || p_documento
            || '",
                               "Cuota": "'
            || p_cuota
            || '",
                               "Fecha_vencimiento": "'
            || p_fecha_vencimiento
            || '",
                               "Monto_local": "'
            || p_monto_local
            || '",
                               "Empresa": "'
            || p_empresa
            || '",
                               "Carrera": "'
            || p_carrera
            || '",
                               "Moneda": "'
            || p_moneda
            || '",
                               "Nro_matricula": "'
            || p_nro_matricula
            || '",
                               "Centro_beneficio": "",
                               "Descripcion": "Test Interface Pago"
                }

}'        ;

         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

            */
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      HTP.p (v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_data_json := json (l_resp_json.get ('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /*verifica que el data viene vacío*/
      IF l_data_json IS NULL
      THEN
         p_ret := 'E';
         p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
      END IF;

      /*retorna json*/
      RETURN l_data_json;
   END int_leg02_json;


   PROCEDURE int_leg02 (p_codigo_cli           VARCHAR2,
                        p_tipo_documento       VARCHAR2,
                        p_fecha_documento      VARCHAR2,
                        p_cuponera             VARCHAR2,
                        p_documento            VARCHAR2,
                        p_cuota                VARCHAR2,
                        p_fecha_vencimiento    VARCHAR2,
                        p_monto_local          VARCHAR2,
                        p_empresa              VARCHAR2,
                        p_carrera              VARCHAR2,
                        p_moneda               VARCHAR2,
                        p_nro_matricula        VARCHAR2)
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_cli_json    json;

      v_ret         VARCHAR2 (1);
      v_msg         VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_leg02_json y en la variable l_cli_json recibe el json del data*/
      l_cli_json :=
         int_leg02_json (p_codigo_cli,
                         p_tipo_documento,
                         p_fecha_documento,
                         p_cuponera,
                         p_documento,
                         p_cuota,
                         p_fecha_vencimiento,
                         p_monto_local,
                         p_empresa,
                         p_carrera,
                         p_moneda,
                         p_nro_matricula,
                         v_ret,
                         v_msg);

      HTP.p (v_ret || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         HTP.p ('TYPE:' || lee_json (l_cli_json, 'TYPE') || '<br>');
         HTP.p ('NUMBER:' || lee_json (l_cli_json, 'NUMBER') || '<br>');
         HTP.p ('MESSAGE:' || lee_json (l_cli_json, 'MESSAGE') || '<br>');
         HTP.p (
            'LOG_MSG_NO:' || lee_json (l_cli_json, 'LOG_MSG_NO') || '<br>');
         HTP.p ('ROW:' || lee_json (l_cli_json, 'ROW') || '<br>');
       /* htp.p('Cuota:'||lee_json(l_cli_json , 'Cuota')||'<br>');
        htp.p('Fecha_vencimiento:'||lee_json(l_cli_json , 'Fecha_vencimiento')||'<br>');
        htp.p('Monto_local:'||lee_json(l_cli_json , 'Monto_local')||'<br>');
        htp.p('Empresa:'||lee_json(l_cli_json , 'Empresa')||'<br>');
        htp.p('Carrera:'||lee_json(l_cli_json , 'Carrera')||'<br>');
        htp.p('Moneda:'||lee_json(l_cli_json , 'Moneda')||'<br>');
        htp.p('Nro_matricula:'||lee_json(l_cli_json , 'Nro_matricula')||'<br>');
        htp.p('<br>');

/*FOR i IN 1 .. l_cli_json.COUNT loop
       htp.p('REGISTRO:'||i||'<br>');
      htp.p('TYPE:'||lee_json(l_cli_json , 'TYPE')||'<br>');
        htp.p('NUMBER:'||lee_json(l_cli_json , 'NUMBER')||'<br>');
        htp.p('MESSAGE:'||lee_json(l_cli_json , 'MESSAGE')||'<br>');
        htp.p('LOG_MSG_NO:'||lee_json(l_cli_json , 'LOG_MSG_NO')||'<br>');
        htp.p('ROW:'||lee_json(l_cli_json , 'ROW')||'<br><br>');

        end LOOP;*/
      ELSE
         /*imprime mensaje de error*/
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_leg02;

   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               FIN  DE PAGO DE DEUDA INT_LEG02
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                CONSULTA DEUDA INT_SAP02
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

   FUNCTION int_sap02_json (p_codigo_cli            VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_tipo_documento        VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_cuenta_contrato       VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_fecha_documento       VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_documento             VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_cuota                 VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_ret               OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                            p_msg               OUT VARCHAR2 --mensaje de error
                                                            )
      RETURN json_list
   IS
      v_json          VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      /*PASO 1 - Se remplaza objeto json por json_list*/
      l_data_json     json_list;
      /*PASO 2 - Se agrega una variable l_RETURN_json */
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json := '{
                        "Token": "' || v_token || '",
                        "data":{
                            "codigo_cli": "' || p_codigo_cli || '",
                            "tipo_documento": "' || p_tipo_documento || '",
                            "cuenta_contrato": "' || p_cuenta_contrato || '",
                            "fecha_documento": "' || p_fecha_documento || '",
                            "documento": "' || p_documento || '",
                            "cuota": "' || p_cuota || '",
                        }
}'        ;

         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000


            */
            -- v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/FISD01/INT_SAP02', v_json);
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FISD01/INT_SAP02',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      /*PASO 3 - Se comenta el htp.p(v_respuesta)*/
      -- htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_RETURN_json := json (l_resp_json.get ('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      IF p_ret = 'S'
      THEN
         --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

         IF lee_json (l_RETURN_json, 'TYPE') <> 'S'
         THEN
            p_ret := SUBSTR (lee_json (l_RETURN_json, 'TYPE'), 1, 1);
         --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
         END IF;
      END IF;


      BEGIN
         l_data_json := json_list (l_resp_json.get ('data'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg :=
                  p_msg
               || ' Error en el formato de la respuesta data: '
               || SQLERRM;
            l_data_json := NULL;
      END;



      /*retorna json*/
      RETURN l_data_json;
   END int_sap02_json;

   FUNCTION int_sap02_json_matri (p_codigo_cli       VARCHAR2 DEFAULT NULL, --parametro consulta
                                  p_ret          OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                  p_msg          OUT VARCHAR2 --mensaje de error
                                                             )
      RETURN json_list
   IS
      v_json          VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      /*PASO 1 - Se remplaza objeto json por json_list*/
      l_data_json     json_list;
      /*PASO 2 - Se agrega una variable l_RETURN_json */
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json := '{
                        "Token": "' || v_token || '",
                        "data":{
                            "codigo_cli": "",
                            "tipo_documento": "",
                            "cuenta_contrato": "",
                            "fecha_documento": "",
                            "documento": "",
                            "cuota": "",
                        }
}'        ;

         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000


            */
            -- v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/FISD01/INT_SAP02', v_json);
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FISD01/INT_SAP02',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      /*PASO 3 - Se comenta el htp.p(v_respuesta)*/
      -- htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_RETURN_json := json (l_resp_json.get ('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      IF p_ret = 'S'
      THEN
         --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

         IF lee_json (l_RETURN_json, 'TYPE') <> 'S'
         THEN
            p_ret := SUBSTR (lee_json (l_RETURN_json, 'TYPE'), 1, 1);
         --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
         END IF;
      END IF;


      BEGIN
         l_data_json := json_list (l_resp_json.get ('data'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg :=
                  p_msg
               || ' Error en el formato de la respuesta data: '
               || SQLERRM;
            l_data_json := NULL;
      END;



      /*retorna json*/
      RETURN l_data_json;
   END int_sap02_json_matri;



   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                CONSULTA DEUDA INT_SAP02 FICA
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

   FUNCTION int_sap02_json_fica (
      p_codigo_cli            VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_tipo_documento        VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_cuenta_contrato       VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_fecha_documento       VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_documento             VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_cuota                 VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_ret               OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg               OUT VARCHAR2                      --mensaje de error
                                      )
      RETURN json_list
   IS
      v_json          VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta     CLOB;

      v_respuesta1    VARCHAR2 (32000);

      v_token         VARCHAR2 (500);


      l_resp_json     json;
      /*PASO 1 - Se remplaza objeto json por json_list*/
      l_data_json     json_list;
      /*PASO 2 - Se agrega una variable l_RETURN_json */
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      --htp.p(p_ret||'texto');

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/



      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json := '{
                        "Token": "' || v_token || '",
                        "data":{
                            "codigo_cli": "' || p_codigo_cli || '",
                            "tipo_documento": "' || p_tipo_documento || '",
                            "cuenta_contrato": "' || p_cuenta_contrato || '",
                            "fecha_documento": "' || p_fecha_documento || '",
                            "documento": "' || p_documento || '",
                            "cuota": "' || p_cuota || '",
                        }
}'        ;

         /*Fin Json de entrada*/

         BEGIN
            --htp.p('Envia: '||v_json||'<br><br>');

            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000


            */
            --g_sistema_sap= 'http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000'

            --v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/FISD01/INT_SAP02', v_json);


            BEGIN
               --     htp.p(g_sistema_sap||'/RESTAdapter/FISD01/INT_SAP02'||'<br>');


               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/FISD01/INT_SAP02/',
                     v_json);

               --  if(p_msg is null) then
               --p_msg:=v_respuesta;
               --  end if;

               DELETE FROM tabla_clob_sap
                     WHERE id = 1;

               INSERT INTO tabla_clob_sap (id, valor)
                    VALUES (1, v_respuesta);

               COMMIT;
               DBMS_OUTPUT.put_line ('');
            -- htp.p('inserto');



            EXCEPTION
               WHEN OTHERS
               THEN
                  -- rpalaciosa 16082017 , este mensaje esta apareciendo en portal de pagos.
                  --htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace); --SQLERRM||DBMS_UTILITY.format_error_backtrace
                  NULL;
            END;
         -- htp.p('salio'||v_respuesta);

         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      --  PASO 3 - Se comenta el htp.p(v_respuesta)
      --htp.p(v_respuesta);



      --htp.p('Respuesta: '||v_respuesta||'<br>');

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_RETURN_json := json (l_resp_json.get ('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      IF p_ret = 'S'
      THEN
         --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

         IF lee_json (l_RETURN_json, 'TYPE') <> 'S'
         THEN
            p_ret := SUBSTR (lee_json (l_RETURN_json, 'TYPE'), 1, 1);
         --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
         END IF;
      END IF;


      BEGIN
         l_data_json := json_list (l_resp_json.get ('data'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg :=
                  p_msg
               || ' Error en el formato de la respuesta data: '
               || SQLERRM;
            l_data_json := NULL;
      END;

      --p_msg:=v_respuesta;

      /*retorna json*/
      RETURN l_data_json;
   END int_sap02_json_fica;



   PROCEDURE int_sap02 (p_codigo_cli         VARCHAR2 DEFAULT NULL,
                        p_tipo_documento     VARCHAR2 DEFAULT NULL,
                        p_cuenta_contrato    VARCHAR2 DEFAULT NULL,
                        p_fecha_documento    VARCHAR2 DEFAULT NULL,
                        p_documento          VARCHAR2 DEFAULT NULL,
                        p_cuota              VARCHAR2 DEFAULT NULL)
   IS
      v_json        VARCHAR2 (1500);
      --v_respuesta varchar2(32000);
      v_respuesta   CLOB;
      v_token       VARCHAR2 (500);


      l_cli_json    json_list;
      l_cli_json2   json;

      v_ret         VARCHAR2 (10);
      v_msg         VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sap02_json y en la variable l_cli_json recibe el json del data*/
      BEGIN
         l_cli_json :=
            int_sap02_json (p_codigo_cli,
                            p_tipo_documento,
                            p_cuenta_contrato,
                            p_fecha_documento,
                            p_documento,
                            p_cuota,
                            v_ret,
                            v_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
      END;



      HTP.p (v_ret || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         /*     htp.p('codigo_cli:'||lee_json(l_cli_json , 'codigo_cli')||'<br>');
              htp.p('tipo_documento:'||lee_json(l_cli_json , 'tipo_documento')||'<br>');
              htp.p('cuenta_contrato:'||lee_json(l_cli_json , 'cuenta_contrato')||'<br>');
              htp.p('fecha_documento:'||lee_json(l_cli_json , 'fecha_documento')||'<br>');
              htp.p('documento:'||lee_json(l_cli_json , 'documento')||'<br>');
              htp.p('cuota:'||lee_json(l_cli_json , 'cuota')||'<br>');
              htp.p('<br>');
              null;*/


         FOR i IN 1 .. l_cli_json.COUNT
         LOOP
            HTP.p ('REGISTRO CONSULTA DEUDA:' || i || '<br>');
            HTP.p (
                  'Codigo_cli:'
               || lee_json (json (l_cli_json.get (i)), 'Codigo_cli')
               || '<br>');
            HTP.p (
                  'Tipo_Documento:'
               || lee_json (json (l_cli_json.get (i)), 'Tipo_Documento')
               || '<br>');
            HTP.p (
                  'Cuenta_Contrato:'
               || lee_json (json (l_cli_json.get (i)), 'Cuenta_Contrato')
               || '<br>');
            HTP.p (
                  'Fecha_Vencimiento:'
               || lee_json (json (l_cli_json.get (i)), 'Fecha_Vencimiento')
               || '<br>');
            HTP.p (
                  'Documento:'
               || lee_json (json (l_cli_json.get (i)), 'Documento')
               || '<br>');
            HTP.p (
                  'Cuota:'
               || lee_json (json (l_cli_json.get (i)), 'Cuota')
               || '<br>');
            HTP.p (
                  'Empresa:'
               || lee_json (json (l_cli_json.get (i)), 'Empresa')
               || '<br>');
            HTP.p (
                  'Tipo_Cuenta_Contrato:'
               || lee_json (json (l_cli_json.get (i)),
                            'Tipo_Cuenta_Contrato')
               || '<br>');
            HTP.p (
                  'Documento_Interes:'
               || lee_json (json (l_cli_json.get (i)), 'Documento_Interes')
               || '<br>');
            HTP.p (
                  'Total:'
               || lee_json (json (l_cli_json.get (i)), 'Total')
               || '<br>');
            HTP.p (
                  'Total_Local:'
               || lee_json (json (l_cli_json.get (i)), 'Total_Local')
               || '<br>');
            HTP.p (
                  'Saldo:'
               || lee_json (json (l_cli_json.get (i)), 'Saldo')
               || '<br>');
            HTP.p (
                  'Saldo_lOCAL:'
               || lee_json (json (l_cli_json.get (i)), 'Saldo_Local')
               || '<br>');
            HTP.p (
                  'Carrera:'
               || lee_json (json (l_cli_json.get (i)), 'Carrera')
               || '<br>');
            HTP.p (
                  'Valor_de_Cambio:'
               || lee_json (json (l_cli_json.get (i)), 'Valor_de_Cambio')
               || '<br>');
            HTP.p (
                  'Moneda:'
               || lee_json (json (l_cli_json.get (i)), 'Moneda')
               || '<br>');
            HTP.p (
                  'Centro_Gestor:'
               || lee_json (json (l_cli_json.get (i)), 'Centro_Gestor')
               || '<br>');

            HTP.p ('<br><br><br>');
         END LOOP;
      ELSE
         /*imprime mensaje de error*/
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_sap02;

   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               FIN  CONSULTA DEUDA INT_SAP02
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                CONSULTA PAGO INT_SAP11 ALAN RIQUELME 20/02/2017
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

   FUNCTION int_sap11_json (p_codigo_cli           VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_carrera              VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_nro_matricula        VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_tipo_documento       VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_nro_cupon            VARCHAR2 DEFAULT NULL, --parametro consulta
                            p_ret              OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                            p_msg              OUT VARCHAR2 --mensaje de error
                                                           )
      RETURN json
   IS
      v_json          VARCHAR2 (1500);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      l_data_json     json_list;
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_json := '{
                    "Token": "' || v_token || '",
                    "data":{
                        "Codigo_cli": "' || p_codigo_cli || '",
                        "Carrera": "' || p_carrera || '",
                        "Nro_matricula": "' || p_nro_matricula || '",
                        "Tipo_documento": "' || p_tipo_documento || '",
                        "Nro_cupon": "' || p_nro_cupon || '",
                       }
                    }';

         --htp.p(v_json);


         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

                    falta que nos envien la url para la interfaz int_leg02
            */

            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI004/INT_SAP11',
                           v_json);

            BEGIN
               INSERT INTO log_integra_utal (id,
                                             llamado,
                                             respuesta,
                                             fecha)
                    VALUES ('INT_SAP11_JSON',
                            v_json,
                            SUBSTR (v_respuesta, 1, 4000),
                            SYSDATE);
            --insert into tabla_clob_sap values (3 , v_respuesta);

            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;
      END IF;


      --   htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            l_RETURN_json := json (v_respuesta);

            v_respuesta := convertir_a_txt (v_respuesta);
            --htp.p(v_respuesta);
            p_msg := v_respuesta;
         /*respuesta la inserta en una estructura en un json*/

         /* seccion data la inserta en un  json*/
         -- l_RETURN_json := json(l_resp_json.get('RETURN'));

         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* if p_ret = 'S' then
           --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

           if lee_json(l_RETURN_json,'TYPE') <> 'S' then
               p_ret := substr(lee_json(l_RETURN_json,'TYPE'),1,1) ;
               --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
           end if;
       end if;


       begin
           l_RETURN_json := json(l_resp_json.get('data'));
       exception when others then
           p_ret := 'S';
           p_msg := p_msg||' Error en el formato de la respuesta data*: '||sqlerrm;
           l_data_json := null;
       end ;*/



      /*retorna json*/
      RETURN l_RETURN_json;
   END int_sap11_json;


   FUNCTION int_sap11_json_test (
      p_codigo_cli           VARCHAR2 DEFAULT NULL,       --parametro consulta
      p_carrera              VARCHAR2 DEFAULT NULL,       --parametro consulta
      p_nro_matricula        VARCHAR2 DEFAULT NULL,       --parametro consulta
      p_tipo_documento       VARCHAR2 DEFAULT NULL,       --parametro consulta
      p_nro_cupon            VARCHAR2 DEFAULT NULL,       --parametro consulta
      p_ret              OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg              OUT VARCHAR2                       --mensaje de error
                                     )
      RETURN json
   IS
      v_json          VARCHAR2 (1500);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      l_data_json     json_list;
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_json := '{
                    "Token": "' || v_token || '",
                    "data":{
                        "Codigo_cli": "' || p_codigo_cli || '",
                        "Carrera": "' || p_carrera || '",
                        "Nro_matricula": "' || p_nro_matricula || '",
                        "Tipo_documento": "' || p_tipo_documento || '",
                        "Nro_cupon": "' || p_nro_cupon || '",
                       }
                    }';

         --htp.p(v_json);


         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

                    falta que nos envien la url para la interfaz int_leg02
            */

            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI004/INT_SAP11',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;
      END IF;


      --   htp.p(v_respuesta);

      IF p_ret = 'S'
      THEN
         BEGIN
            v_respuesta := convertir_a_txt (v_respuesta);
            HTP.p (v_respuesta);
            p_msg := v_respuesta;
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         -- l_RETURN_json := json(l_resp_json.get('RETURN'));

         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* if p_ret = 'S' then
           --htp.p('~~'||lee_json(l_RETURN_json,'TYPE')||'~~');

           if lee_json(l_RETURN_json,'TYPE') <> 'S' then
               p_ret := substr(lee_json(l_RETURN_json,'TYPE'),1,1) ;
               --p_msg := p_msg||lee_json(l_RETURN_json,'MESSAGE') ;
           end if;
       end if;


       begin
           l_RETURN_json := json(l_resp_json.get('data'));
       exception when others then
           p_ret := 'S';
           p_msg := p_msg||' Error en el formato de la respuesta data*: '||sqlerrm;
           l_data_json := null;
       end ;*/



      /*retorna json*/
      RETURN l_RETURN_json;
   END int_sap11_json_test;

   /*condor2-19testing.utalca.cl/pls/sap_test/pkg_integra_utal_dev.int_sap11?p_codigo_cli=0699617911&p_carrera=&p_nro_matricula=&p_tipo_documento=*/
   PROCEDURE int_sap11 (p_codigo_cli        VARCHAR2 DEFAULT NULL,
                        p_carrera           VARCHAR2 DEFAULT NULL,
                        p_nro_matricula     VARCHAR2 DEFAULT NULL,
                        p_tipo_documento    VARCHAR2 DEFAULT NULL,
                        p_nro_cupon         VARCHAR2 DEFAULT NULL)
   IS
      v_json            VARCHAR2 (3200);
      --v_respuesta varchar2(32000);
      v_respuesta       CLOB;
      v_token           VARCHAR2 (500);


      l_cli_json        json;

      l_cli_json_data   json_list;

      v_ret             VARCHAR2 (10);
      v_msg             VARCHAR2 (5000);
   BEGIN
      /*llama a la función int_sap11_json y en la variable l_cli_json recibe el json del data*/
      BEGIN
         l_cli_json :=
            int_sap11_json (p_codigo_cli,
                            p_carrera,
                            p_nro_matricula,
                            p_tipo_documento,
                            p_nro_cupon,
                            v_ret,
                            v_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
      END;

      HTP.p (v_ret || '<br>');
      HTP.p (v_msg || '<br>');

      /*imprime estructura json por serpara y se revisa formato*/
      IF v_ret = 'S'
      THEN
         NULL;
         HTP.p (l_cli_json.COUNT);

         FOR i IN 1 .. l_cli_json.COUNT
         LOOP
            IF (i = 1)
            THEN
               HTP.p ('REGISTRO:' || i || '<br>');
               HTP.p (
                     'CODIGO_CLI:'
                  || lee_json (json (l_cli_json.get (i)), 'CODIGO_CLI')
                  || '<br>');
               HTP.p (
                     'CUENTA_CONTRATO:'
                  || lee_json (json (l_cli_json.get (i)), 'CUENTA_CONTRATO')
                  || '<br>');
               HTP.p (
                     'TIPO_CUENTA_CONTRATO:'
                  || lee_json (json (l_cli_json.get (i)),
                               'TIPO_CUENTA_CONTRATO')
                  || '<br>');
               HTP.p (
                     'OBJETO_CONTRATO:'
                  || lee_json (json (l_cli_json.get (i)), 'OBJETO_CONTRATO')
                  || '<br>');
               HTP.p (
                     'CLASE_OBJETO_CONTRATO:'
                  || lee_json (json (l_cli_json.get (i)),
                               'CLASE_OBJETO_CONTRATO')
                  || '<br>');
               HTP.p (
                     'TIPO_DOCUMENTO:'
                  || lee_json (json (l_cli_json.get (i)), 'TIPO_DOCUMENTO')
                  || '<br>');
               HTP.p (
                     'DOCUMENTO:'
                  || lee_json (json (l_cli_json.get (i)), 'DOCUMENTO')
                  || '<br>');
               HTP.p (
                     'DOCUMENTO_INTERES:'
                  || lee_json (json (l_cli_json.get (i)),
                               'DOCUMENTO_INTERES')
                  || '<br>');
               HTP.p (
                     'FECHA_VENCIMIENTO:'
                  || lee_json (json (l_cli_json.get (i)),
                               'FECHA_VENCIMIENTO')
                  || '<br>');
               HTP.p (
                     'DOCUMENTO_PAGO:'
                  || lee_json (json (l_cli_json.get (i)), 'DOCUMENTO_PAGO')
                  || '<br>');
               HTP.p (
                     'SALDO_PAGADO:'
                  || lee_json (json (l_cli_json.get (i)), 'SALDO_PAGADO')
                  || '<br>');
               HTP.p (
                     'NRO_CUPON:'
                  || lee_json (json (l_cli_json.get (i)), 'NRO_CUPON')
                  || '<br>');
            ELSE
               HTP.p (
                     'TYPE:'
                  || lee_json (json (l_cli_json.get (i)), 'TYPE')
                  || '<br>');
            END IF;

            HTP.p ('<br><br><br>');
         END LOOP;
      ELSE
         /*imprime mensaje de error*/
         HTP.p (v_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM || DBMS_UTILITY.format_error_backtrace);
   END int_sap11;


   FUNCTION int_sap02_json_data (
      p_codigo_cli            VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_tipo_documento        VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_cuenta_contrato       VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_fecha_documento       VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_documento             VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_cuota                 VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_ret               OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg               OUT VARCHAR2                      --mensaje de error
                                      )
      RETURN json
   IS
      v_json             VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta        CLOB;

      v_respuesta1       VARCHAR2 (32000);

      v_token            VARCHAR2 (500);


      l_resp_json        json;
      /*PASO 1 - Se remplaza objeto json por json_list*/
      l_data_json        json_list;
      /*PASO 2 - Se agrega una variable l_RETURN_json */
      l_RETURN_json      json;


      pl_mensaje_error   VARCHAR2 (4000);
   BEGIN
      p_ret := 'S';

      --htp.p(p_ret||'texto');

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/



      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json := '{
                        "Token": "' || v_token || '",
                        "data":{
                            "codigo_cli": "' || p_codigo_cli || '",
                            "tipo_documento": "' || p_tipo_documento || '",
                            "cuenta_contrato": "' || p_cuenta_contrato || '",
                            "fecha_documento": "' || p_fecha_documento || '",
                            "documento": "' || p_documento || '",
                            "cuota": "' || p_cuota || '",
                        }
}'        ;

         /*Fin Json de entrada*/

         BEGIN
            --htp.p('Envia: '||v_json||'<br><br>');

            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000


            */
            --g_sistema_sap= 'http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000'

            --v_respuesta := call_url_p('http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000/RESTAdapter/FISD01/INT_SAP02', v_json);


            BEGIN
               --     htp.p(g_sistema_sap||'/RESTAdapter/FISD01/INT_SAP02'||'<br>');


               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/FISD01/INT_SAP02/',
                     v_json);


               DELETE FROM tabla_clob_sap
                     WHERE id = 1;

               INSERT INTO tabla_clob_sap (id, valor)
                    VALUES (1, v_respuesta);
            -- htp.p('inserto');



            EXCEPTION
               WHEN OTHERS
               THEN
                  --                 htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace); --SQLERRM||DBMS_UTILITY.format_error_backtrace
                  pl_mensaje_error :=
                     SQLERRM || DBMS_UTILITY.format_error_backtrace;

                  INSERT INTO tabla_clob_sap (id, valor)
                       VALUES (1, pl_mensaje_error);
            END;

            COMMIT;
         -- htp.p('salio'||v_respuesta);

         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      /*PASO 3 - Se comenta el htp.p(v_respuesta)
htp.p(v_respuesta);*/



      --htp.p('Respuesta: '||v_respuesta||'<br>');

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_RETURN_json := json (l_resp_json.get ('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;



      IF p_ret = 'S'
      THEN
         IF lee_json (l_RETURN_json, 'TYPE') <> 'S'
         THEN
            p_ret := SUBSTR (lee_json (l_RETURN_json, 'TYPE'), 1, 1);
         END IF;
      END IF;

      /*
          begin
              l_data_json := json_list(l_resp_json.get('data'));
          exception when others then
              p_ret := 'E';
              p_msg := p_msg||' Error en el formato de la respuesta data: '||sqlerrm;
              l_data_json := null;
          end ;

      */



      /*retorna json*/
      RETURN json (l_resp_json.get ('data'));
   END int_sap02_json_data;


   FUNCTION int_sap02_json_data2 (
      p_codigo_cli            VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_tipo_documento        VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_cuenta_contrato       VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_fecha_documento       VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_documento             VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_cuota                 VARCHAR2 DEFAULT NULL,      --parametro consulta
      p_ret               OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg               OUT VARCHAR2                      --mensaje de error
                                      )
      RETURN json
   IS
      v_json             VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta        CLOB;

      v_respuesta1       VARCHAR2 (32000);

      v_token            VARCHAR2 (500);


      l_resp_json        json;
      /*PASO 1 - Se remplaza objeto json por json_list*/
      l_data_json        json_list;
      /*PASO 2 - Se agrega una variable l_RETURN_json */
      l_RETURN_json      json;


      pl_mensaje_error   VARCHAR2 (4000);
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/
         v_json := '{
                        "Token": "' || v_token || '",
                        "data":{
                            "codigo_cli": "' || p_codigo_cli || '",
                            "tipo_documento": "' || p_tipo_documento || '",
                            "cuenta_contrato": "' || p_cuenta_contrato || '",
                            "fecha_documento": "' || p_fecha_documento || '",
                            "documento": "' || p_documento || '",
                            "cuota": "' || p_cuota || '",
                        }
        }';

         /*Fin Json de entrada*/
         BEGIN
            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/FISD01/INT_SAP02/',
                     v_json);


               DELETE FROM tabla_clob_sap
                     WHERE id = 2;

               INSERT INTO tabla_clob_sap (id, valor)
                    VALUES (2, v_respuesta);
            EXCEPTION
               WHEN OTHERS
               THEN
                  pl_mensaje_error :=
                     SQLERRM || DBMS_UTILITY.format_error_backtrace;

                  INSERT INTO tabla_clob_sap (id, valor)
                       VALUES (2, pl_mensaje_error);
            END;

            COMMIT;
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;
      END IF;

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_resp_json := json (v_respuesta);
            /* seccion data la inserta en un  json*/
            l_RETURN_json := json (l_resp_json.get ('RETURN'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      IF p_ret = 'S'
      THEN
         IF lee_json (l_RETURN_json, 'TYPE') <> 'S'
         THEN
            p_ret := SUBSTR (lee_json (l_RETURN_json, 'TYPE'), 1, 1);
         END IF;
      END IF;

      --    if p_codigo_cli=17497104 then
      --     htp.p(v_respuesta);
      --    end if;

      /*retorna json*/
      RETURN (l_resp_json);
   END int_sap02_json_data2;



   /*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               FIN  CREA Y PAGA DEUDA INT_SAP11 ***********
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   realizadas en la tarde del 15 de febr 2017.

   - CREACION  DE CLIENTE INT_LEG04
   - PAGO DE DEUDA INT_LEG02
   - CONSULTA DEUDA INT_SAP02
   - CREA Y PAGA DEUDA INT_SAP11

   faltaria.

   INT_LEG05 -> CREACION DE DEUDA*/



   PROCEDURE htpprn (pclob IN OUT NOCOPY CLOB)
   IS
      v_excel   VARCHAR2 (32000);
      v_clob    CLOB := pclob;
   BEGIN
      WHILE LENGTH (v_clob) > 0
      LOOP
         BEGIN
            IF LENGTH (v_clob) > 16000
            THEN
               v_excel := SUBSTR (v_clob, 1, 16000);
               HTP.prn (v_excel);
               v_clob := SUBSTR (v_clob, LENGTH (v_excel) + 1);
            ELSE
               v_excel := v_clob;
               HTP.prn (v_excel);
               v_clob := '';
               v_excel := '';
            END IF;
         END;
      END LOOP;
   END;

   FUNCTION convertir_a_txt (txt VARCHAR2)
      RETURN VARCHAR2
   IS
      vtxt   VARCHAR2 (32000);
   BEGIN
      vtxt := txt;
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":0', 'TOTAL_DEUDA":"0');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":1', 'TOTAL_DEUDA":"1');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":2', 'TOTAL_DEUDA":"2');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":3', 'TOTAL_DEUDA":"3');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":4', 'TOTAL_DEUDA":"4');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":5', 'TOTAL_DEUDA":"5');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":6', 'TOTAL_DEUDA":"6');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":7', 'TOTAL_DEUDA":"7');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":8', 'TOTAL_DEUDA":"8');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":9', 'TOTAL_DEUDA":"9');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":9', 'TOTAL_DEUDA":"0');

      vtxt := REPLACE (vtxt, '-","SALDO_PAGADO', '","SALDO_PAGADO');


      vtxt := REPLACE (vtxt, '1,"SALDO_PAGADO', '1","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '2,"SALDO_PAGADO', '2","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '3,"SALDO_PAGADO', '3","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '4,"SALDO_PAGADO', '4","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '5,"SALDO_PAGADO', '5","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '6,"SALDO_PAGADO', '6","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '7,"SALDO_PAGADO', '7","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '8,"SALDO_PAGADO', '8","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '9,"SALDO_PAGADO', '9","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '0,"SALDO_PAGADO', '0","SALDO_PAGADO');

      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":1', 'SALDO_PAGADO":"1');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":2', 'SALDO_PAGADO":"2');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":3', 'SALDO_PAGADO":"3');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":4', 'SALDO_PAGADO":"4');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":5', 'SALDO_PAGADO":"5');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":6', 'SALDO_PAGADO":"6');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":7', 'SALDO_PAGADO":"7');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":8', 'SALDO_PAGADO":"8');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":9', 'SALDO_PAGADO":"9');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":0', 'SALDO_PAGADO":"0');


      vtxt := REPLACE (vtxt, '1,"NRO_MATRICULA', '1","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '2,"NRO_MATRICULA', '2","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '3,"NRO_MATRICULA', '3","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '4,"NRO_MATRICULA', '4","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '5,"NRO_MATRICULA', '5","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '6,"NRO_MATRICULA', '6","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '7,"NRO_MATRICULA', '7","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '8,"NRO_MATRICULA', '8","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '9,"NRO_MATRICULA', '9","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '0,"NRO_MATRICULA', '0","NRO_MATRICULA');

      RETURN vtxt;
   END;

   FUNCTION int_leg05_fica_crea_mat_col (p_idcliente         VARCHAR2,
                                         p_tipo_doc          VARCHAR2,
                                         p_carrera_sap       VARCHAR2,
                                         p_matricula         VARCHAR2,
                                         p_ano               VARCHAR2,
                                         p_ret           OUT VARCHAR2,
                                         --Salida estado si tiene error en oracle S (Success) E (Error)
                                         p_msg           OUT VARCHAR2 --mensaje de error
                                                                     )
      RETURN json
   IS
      v_line                VARCHAR2 (32766);
      v_paga                VARCHAR2 (1);
      v_json                CLOB := EMPTY_CLOB ();
      --
      v_respuesta           CLOB;
      v_token               VARCHAR2 (500);
      l_resp_json           json;
      l_data_json           json;
      l_return_json         json;
      l_data_json_l         json_list;
      nombre_dcto           VARCHAR2 (5000);
      V_FECHA_DOCUMENTO     DATE;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle
      IS
           SELECT *
             FROM vec_cob02.carga_colchagua a
            WHERE     interlocutor = p_idcliente
                  AND clase_sap = p_tipo_doc
                  AND matricula = p_matricula
                  AND carrera_sap = p_carrera_sap
                  AND ano = p_ano
         ORDER BY fec_vencimiento ASC;

      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      id_log                NUMBER;
      v_contador            NUMBER := 0;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         BEGIN
            SELECT rec_nombre_sap
              INTO nombre_dcto
              FROM utsap001.conf_recursos
             WHERE     rec_categoria = 2
                   AND rec_subcategoria = 2
                   AND rec_codigo_sap = p_tipo_doc;

            SELECT operacion_op, sub_operacion_op
              INTO pl_operacion_op, pl_sub_operacion_op
              FROM operacion_sub_operacion_sap
             WHERE clase_documento_sap = p_tipo_doc;

            v_json := '';
            v_contador := 0;
            v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

            FOR reg IN c_deudas_actuales_detalle
            LOOP
               v_contador := v_contador + 1;
               v_line :=
                     v_line
                  || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                  || reg.interlocutor
                  || '",
                               "Tipo_documento": "'
                  || reg.clase_sap
                  || '",
                               "Fecha_documento": "'
                  || TO_CHAR (reg.fecha_documento, 'YYYYMMDD')
                  || '",
                               "Nro_Cuponera": "",
                               "Documento": "",
                               "Cuota": "'
                  || v_contador
                  || '",
                               "Fecha_vencimiento": "'
                  || TO_CHAR (reg.fec_vencimiento, 'YYYYMMDD')
                  || '",
                               "Importe": "'
                  || reg.monto_cuota
                  || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                  || reg.carrera_sap
                  || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                  || reg.matricula
                  || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                  || pl_operacion_op
                  || '",
                               "Sub_operacion": "'
                  || pl_sub_operacion_op
                  || '",
                               "Descripcion": "'
                  || reg.texto
                  || '",
                               "Elemento_PEP": "",
                               "Pagar": ""
                            },';
            END LOOP;

            v_json := v_json || v_line;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         v_line := '';
         v_line := '} }';
         v_json := v_json || v_line;

         /*Fin Json de entrada */
         BEGIN
            HTP.p ('JSON envio:' || v_json || '<br>');
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                           v_json);
            HTP.P ('JSON respuesta:' || v_respuesta || '<BR>');
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json_l := json_list (l_resp_json.get ('Resp'));
               l_data_json := json (l_data_json_l.get (1));
               p_ret :=
                  lee_json (json (l_data_json_l.get (1)), 'TYPE');
               p_msg :=
                     lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                  || ', '
                  || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     l_resp_json := json (v_respuesta);
                     l_data_json := json (l_resp_json.get ('Resp'));
                     p_ret :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'TYPE');
                     p_msg :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'MESSAGE');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_ret := 'E';
                        p_msg :=
                              'Error en el formato de la respuesta 1 : '
                           || SQLERRM;
                        l_data_json := NULL;
                  END;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;
      END IF;

      RETURN l_data_json;
   END int_leg05_fica_crea_mat_col;

   FUNCTION int_sap11v2_json (p_codigo_cli           VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_carrera              VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_nro_matricula        VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_tipo_documento       VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_nro_cupon            VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_fecha_ini            VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_fecha_fin            VARCHAR2 DEFAULT NULL, --parametro consulta
                              p_ret              OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                              p_msg              OUT CLOB   --mensaje de error
                                                         )
      RETURN json
   IS
      v_json          VARCHAR2 (1500);
      v_respuesta     CLOB;
      v_token         VARCHAR2 (500);


      l_resp_json     json;
      l_data_json     json_list;
      l_RETURN_json   json;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         SELECT utal_dti.p_encrypt_utal.encrypt_ssn_sap (
                   G_clave || TO_CHAR (SYSDATE, 'dd/mm/yyyy hh24:mi:ss'))
                   AS dato_encriptado
           INTO v_token
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_json := '{
                    "Token": "' || v_token || '",
                    "data":{
                        "Codigo_cli": "' || p_codigo_cli || '",
                        "Carrera": "' || p_carrera || '",
                        "Nro_matricula": "' || p_nro_matricula || '",
                        "Tipo_documento": "' || p_tipo_documento || '",
                        "Nro_cupon": "' || p_nro_cupon || '",
                        "fechaini": "' || p_fecha_ini || '",
                        "fechafin": "' || p_fecha_fin || '",
                       }
                    }';


         /*Fin Json de entrada */

         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000

                    falta que nos envien la url para la interfaz int_leg02
            */

            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/FI004/INT_SAP11',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;
      END IF;

      IF p_ret = 'S'
      THEN
         BEGIN
            v_respuesta := convertir_a_txt2 (v_respuesta);
            p_msg := v_respuesta;
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
            NULL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                     p_msg
                  || ' Error en el formato de la respuesta : '
                  || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /*retorna json*/
      RETURN l_RETURN_json;
   END int_sap11v2_json;

   FUNCTION convertir_a_txt2 (txt CLOB)
      RETURN CLOB
   IS
      vtxt   CLOB;
   BEGIN
      vtxt := txt;
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":0', 'TOTAL_DEUDA":"0');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":1', 'TOTAL_DEUDA":"1');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":2', 'TOTAL_DEUDA":"2');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":3', 'TOTAL_DEUDA":"3');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":4', 'TOTAL_DEUDA":"4');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":5', 'TOTAL_DEUDA":"5');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":6', 'TOTAL_DEUDA":"6');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":7', 'TOTAL_DEUDA":"7');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":8', 'TOTAL_DEUDA":"8');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":9', 'TOTAL_DEUDA":"9');
      vtxt := REPLACE (vtxt, 'TOTAL_DEUDA":9', 'TOTAL_DEUDA":"0');

      vtxt := REPLACE (vtxt, '-","SALDO_PAGADO', '","SALDO_PAGADO');


      vtxt := REPLACE (vtxt, '1,"SALDO_PAGADO', '1","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '2,"SALDO_PAGADO', '2","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '3,"SALDO_PAGADO', '3","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '4,"SALDO_PAGADO', '4","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '5,"SALDO_PAGADO', '5","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '6,"SALDO_PAGADO', '6","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '7,"SALDO_PAGADO', '7","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '8,"SALDO_PAGADO', '8","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '9,"SALDO_PAGADO', '9","SALDO_PAGADO');
      vtxt := REPLACE (vtxt, '0,"SALDO_PAGADO', '0","SALDO_PAGADO');

      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":1', 'SALDO_PAGADO":"1');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":2', 'SALDO_PAGADO":"2');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":3', 'SALDO_PAGADO":"3');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":4', 'SALDO_PAGADO":"4');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":5', 'SALDO_PAGADO":"5');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":6', 'SALDO_PAGADO":"6');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":7', 'SALDO_PAGADO":"7');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":8', 'SALDO_PAGADO":"8');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":9', 'SALDO_PAGADO":"9');
      vtxt := REPLACE (vtxt, 'SALDO_PAGADO":0', 'SALDO_PAGADO":"0');


      vtxt := REPLACE (vtxt, '1,"NRO_MATRICULA', '1","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '2,"NRO_MATRICULA', '2","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '3,"NRO_MATRICULA', '3","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '4,"NRO_MATRICULA', '4","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '5,"NRO_MATRICULA', '5","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '6,"NRO_MATRICULA', '6","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '7,"NRO_MATRICULA', '7","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '8,"NRO_MATRICULA', '8","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '9,"NRO_MATRICULA', '9","NRO_MATRICULA');
      vtxt := REPLACE (vtxt, '0,"NRO_MATRICULA', '0","NRO_MATRICULA');

      RETURN vtxt;
   END;

   FUNCTION int_leg02_portal_sap2 (p_idcliente       VARCHAR2,
                                   p_num_op          VARCHAR2,
                                   p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                   p_msg         OUT VARCHAR2,
                                   p_tipo            VARCHAR2 DEFAULT NULL --mensaje de error
                                                                          )
      RETURN json
   IS
      --p_codigo_cli           varchar2(1000):=p_idcliente;
      p_tipo_documento      VARCHAR2 (1000);
      p_fecha_documento     VARCHAR2 (1000);
      --p_fecha_documento      date;
      p_cuponera            VARCHAR2 (1000);
      p_documento           VARCHAR2 (1000);
      p_cuota               VARCHAR2 (1000);
      p_fecha_vencimiento   VARCHAR2 (1000);
      p_monto_local         VARCHAR2 (1000);
      p_empresa             VARCHAR2 (1000);
      p_carrera             VARCHAR2 (1000);
      p_moneda              VARCHAR2 (1000);
      p_nro_matricula       VARCHAR2 (1000);
      p_centro_beneficio    VARCHAR2 (1000);
      p_monto               VARCHAR2 (1000);
      v_tipo_doc            VARCHAR2 (50);

      -- v_rut varchar2 (1000):= substr(p_idcliente,1,length(p_idcliente)-2);

      v_json                CLOB;
      v_json_inicio         CLOB;
      v_json_fin            CLOB;
      v_respuesta           CLOB;

      v_token               VARCHAR2 (500);
      l_cli_json            json;
      l_cli_json_data       json_list;
      p_tipo_doc            VARCHAR2 (10);

      l_resp_json           json;
      l_data_json           json;
      id_log                NUMBER;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMBER)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM VEC_COB01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND PA_NRO_OPERACION = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM VEC_COB01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND PA_NRO_OPERACION = p_num_op;
   BEGIN
      p_ret := 'S';

      IF p_tipo = 'X'
      THEN
         v_tipo_doc := 'Z8';
      ELSE
         v_tipo_doc := get_clase_documento_sap(p_idcliente,p_num_op);
      END IF;

      BEGIN
         v_token := pkg_token.Get_token;
         v_json_inicio := '{"Token": "' || v_token || '",';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            RETURN l_data_json;
      END;

      IF p_ret = 'S'
      THEN
         SELECT SEQ_ID_LOG_INTLEG02PORTAL.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            v_json_fin := '';
            v_json := '';

            FOR reg
               IN c_deudas_actuales_detalle (reg_grupo.pade_tipo_documento)
            LOOP
               p_tipo_documento := v_tipo_doc; -- reg.pade_tipo_documento; se agrego Z2 a solicitud del cliente
               p_fecha_documento := TO_CHAR (SYSDATE, 'YYYYMMDD'); --reg.pade_fec_vencimiento; -- no se cual es el campo
               p_cuponera := reg.pa_nro_operacion;   -- no se cual es el campo
               p_documento := reg.pade_nro_documento;
               p_cuota := reg.pade_cuota;
               p_fecha_vencimiento := reg.pade_fec_vencimiento;
               p_monto_local := reg.pade_monto_local;
               p_empresa := 'UT01'; -- 10 no se cual es el campo se agrego UT01 a solicitud del cliente
               p_carrera := reg.pade_nro_carrera;
               p_moneda := reg.pade_moneda;
               p_nro_matricula := reg.pade_matricula; --reg.cuenta_contrato; -- no se cual es el campo
               p_centro_beneficio := ''; -- no se cual es reg.centro_beneficio;

               --***** SE MODIFICA MONTO DE ENVIO PARA EL PAGO DE DEUDAS EN MONEDA DIFERENTE A CLP
               --***** AHORA SE ENVIARÀ P_MONTO Y NO P_MONTO_LOCAL
               p_monto := reg.pade_monto;

               IF (reg.pade_moneda <> 'CLP')
               THEN
                  p_monto := TO_CHAR (REG.pade_monto, '999999999999D0000');
                  p_monto := REPLACE (p_monto, ',', '.');
               --formato de 4 digitos
               END IF;

               --***************************************************************************************
               v_respuesta :=
                     '"data":{"Codigo_cli": "'
                  || p_idcliente
                  || '","Tipo_documento": "'
                  || p_tipo_documento
                  || '","Fecha_documento": "'
                  || p_fecha_documento
                  || '","Cuponera": "'
                  || p_cuponera
                  || '","Documento": "'
                  || p_documento
                  || '","Cuota": "'
                  || p_cuota
                  || '","Fecha_vencimiento": "'
                  || p_fecha_vencimiento
                  || '","Monto_local": "'
                  || p_monto
                  || '","Empresa": "'
                  || p_empresa
                  || '","Carrera": "'
                  || p_carrera
                  || '","Moneda": "'
                  || p_moneda
                  || '","Nro_matricula": "'
                  || p_nro_matricula
                  || '","Centro_beneficio": "'
                  || p_centro_beneficio
                  || '","Descripcion": "Pago '
                  || p_tipo_documento
                  || ' Portal cuota '
                  || p_cuota
                  || '"},';
               v_json := v_json || v_respuesta;
            END LOOP;


            v_json_fin := '}';
            v_json := SUBSTR (v_json, 1, LENGTH (v_json) - 1);
            v_json := v_json_inicio || v_json || v_json_fin;

            --inserto en el log de registros, no esta guardando mensaje, revisar
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG02(PAGA DEUDA)',
                         p_documento,
                         'Pago ' || p_tipo_documento,
                         p_idcliente,
                         p_num_op,
                         v_json,
                         SYSDATE);

            COMMIT;
            HTP.p (LENGTH (v_json));
            --LLAMDA A INTEGRACION DE SAP CON EL JSON
            v_respuesta :=
               call_url_p_postgrado (
                  g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02',
                  v_json);

            --REVISAMOS LA RESUESTA DEL JSON
            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json := json (l_resp_json.get ('data'));
                  p_ret := lee_json (l_data_json, 'TYPE');
                  p_msg := lee_json (l_data_json, 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_ret := 'E';
                     p_msg :=
                        'Error en el formato de la respuesta : ' || SQLERRM;
                     l_data_json := NULL;
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
            END IF;

            --INSERTAMOS EN TABLA DE LOG DE INTEGRACION
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'R',
                         'INTLEG02(PAGA DEUDA)',
                         p_documento,
                         'Pago Cuota ' || p_cuota,
                         p_idcliente,
                         p_num_op,
                         v_json,
                         SYSDATE);

            COMMIT;
         END LOOP;

         --RETRONAMOS EL OBJETO JSON
         RETURN l_data_json;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg :=
               'error en la funcion:'
            || SQLERRM
            || DBMS_UTILITY.format_error_backtrace;
         RETURN l_data_json;
   END;

   FUNCTION int_leg02_portal_sap2_pac (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg         OUT VARCHAR2,
      p_tipo            VARCHAR2 DEFAULT NULL               --mensaje de error
                                             )
      RETURN json
   IS
      --p_codigo_cli           varchar2(1000):=p_idcliente;
      p_tipo_documento      VARCHAR2 (1000);
      p_fecha_documento     VARCHAR2 (1000);
      --p_fecha_documento      date;
      p_cuponera            VARCHAR2 (1000);
      p_documento           VARCHAR2 (1000);
      p_cuota               VARCHAR2 (1000);
      p_fecha_vencimiento   VARCHAR2 (1000);
      p_monto_local         VARCHAR2 (1000);
      p_empresa             VARCHAR2 (1000);
      p_carrera             VARCHAR2 (1000);
      p_moneda              VARCHAR2 (1000);
      p_nro_matricula       VARCHAR2 (1000);
      p_centro_beneficio    VARCHAR2 (1000);
      p_monto               VARCHAR2 (1000);
      v_tipo_doc            VARCHAR2 (50);
      v_fecha_debito        VARCHAR2 (1000);

      -- v_rut varchar2 (1000):= substr(p_idcliente,1,length(p_idcliente)-2);

      v_json                CLOB;
      v_json_inicio         CLOB;
      v_json_fin            CLOB;
      v_respuesta           CLOB;
      v_token               VARCHAR2 (500);
      l_cli_json            json;
      l_cli_json_data       json_list;
      p_tipo_doc            VARCHAR2 (10);
      l_resp_json           json;
      l_data_json           json;
      id_log                NUMBER;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMBER)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;
   BEGIN
      p_ret := 'S';

      IF p_tipo = 'X'
      THEN
         v_tipo_doc := 'Z8';
      ELSIF p_tipo = 'Y'
      THEN
         v_tipo_doc := 'Z9';
      ELSE
         v_tipo_doc := get_clase_documento_sap(p_idcliente,p_num_op);
      END IF;

      SELECT TO_CHAR (PACR_FECHA_DEBITO, 'YYYYMMDD')
        INTO v_fecha_debito
        FROM vec_cob01.pac_rendicion
       WHERE pacr_num_factura = p_num_op AND PACR_ESTADO_DEBITO = '00';

      BEGIN
         v_token := pkg_token.get_token;
         v_json_inicio := '{"Token": "' || v_token || '",';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            RETURN l_data_json;
      END;

      IF p_ret = 'S'
      THEN
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            v_json_fin := '';
            v_json := '';

            FOR reg
               IN c_deudas_actuales_detalle (reg_grupo.pade_tipo_documento)
            LOOP
               p_tipo_documento := v_tipo_doc; -- reg.pade_tipo_documento; se agrego Z2 a solicitud del cliente
               p_fecha_documento := v_fecha_debito; --reg.pade_fec_vencimiento; -- no se cual es el campo
               p_cuponera := reg.pa_nro_operacion;   -- no se cual es el campo
               p_documento := reg.pade_nro_documento;
               p_cuota := reg.pade_cuota;
               p_fecha_vencimiento := reg.pade_fec_vencimiento;
               p_monto_local := reg.pade_monto_local;
               p_empresa := 'UT01'; -- 10 no se cual es el campo se agrego UT01 a solicitud del cliente
               p_carrera := reg.pade_nro_carrera;
               p_moneda := reg.pade_moneda;
               p_nro_matricula := reg.pade_matricula; --reg.cuenta_contrato; -- no se cual es el campo
               p_centro_beneficio := ''; -- no se cual es reg.centro_beneficio;

               --***** SE MODIFICA MONTO DE ENVIO PARA EL PAGO DE DEUDAS EN MONEDA DIFERENTE A CLP
               --***** AHORA SE ENVIARÀ P_MONTO Y NO P_MONTO_LOCAL
               p_monto := reg.pade_monto;

               IF (reg.pade_moneda <> 'CLP')
               THEN
                  p_monto := TO_CHAR (reg.pade_monto, '999999999999D0000');
                  p_monto := REPLACE (p_monto, ',', '.');
               --formato de 4 digitos
               END IF;

               --***************************************************************************************
               v_respuesta :=
                     '"data":{"Codigo_cli": "'
                  || p_idcliente
                  || '","Tipo_documento": "'
                  || p_tipo_documento
                  || '","Fecha_documento": "'
                  || p_fecha_documento
                  || '","Cuponera": "'
                  || p_cuponera
                  || '","Documento": "'
                  || p_documento
                  || '","Cuota": "'
                  || p_cuota
                  || '","Fecha_vencimiento": "'
                  || p_fecha_vencimiento
                  || '","Monto_local": "'
                  || p_monto
                  || '","Empresa": "'
                  || p_empresa
                  || '","Carrera": "'
                  || p_carrera
                  || '","Moneda": "'
                  || p_moneda
                  || '","Nro_matricula": "'
                  || p_nro_matricula
                  || '","Centro_beneficio": "'
                  || p_centro_beneficio
                  || '","Descripcion": "Pago '
                  || p_tipo_documento
                  || ' Portal cuota '
                  || p_cuota
                  || '"},';

               v_json := v_json || v_respuesta;
            END LOOP;

            v_json_fin := '}';
            v_json := SUBSTR (v_json, 1, LENGTH (v_json) - 1);
            v_json := v_json_inicio || v_json || v_json_fin;

            --inserto en el log de registros, no esta guardando mensaje, revisar
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG02(PAGA DEUDA)',
                         p_documento,
                         'Pago ' || p_tipo_documento,
                         p_idcliente,
                         p_num_op,
                         v_json,
                         SYSDATE);

            COMMIT;
            HTP.p (LENGTH (v_json));
            --LLAMDA A INTEGRACION DE SAP CON EL JSON
            v_respuesta :=
               call_url_p_postgrado (
                  g_sistema_sap || '/RESTAdapter/FI002/INT_LEG02',
                  v_json);

            --REVISAMOS LA RESUESTA DEL JSON
            IF p_ret = 'S'
            THEN
               BEGIN
                  l_resp_json := JSON (v_respuesta);
                  l_data_json := JSON (l_resp_json.get ('data'));
                  p_ret := lee_json (l_data_json, 'TYPE');
                  p_msg := lee_json (l_data_json, 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_ret := 'E';
                     p_msg :=
                        'Error en el formato de la respuesta : ' || SQLERRM;
                     l_data_json := NULL;
               END;
            END IF;

            IF l_data_json IS NULL
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
            END IF;

            --INSERTAMOS EN TABLA DE LOG DE INTEGRACION
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              tipo_integracion,
                                              dato1,
                                              dato2,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'R',
                         'INTLEG02(PAGA DEUDA)',
                         p_documento,
                         'Pago Cuota ' || p_cuota,
                         p_idcliente,
                         p_num_op,
                         v_json,
                         SYSDATE);

            COMMIT;
         END LOOP;

         --RETRONAMOS EL OBJETO JSON
         RETURN l_data_json;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg :=
               'error en la funcion:'
            || SQLERRM
            || DBMS_UTILITY.format_error_backtrace;
         RETURN l_data_json;
   END;


   FUNCTION int_crea_descuento_postgrado (
      p_tipo_proceso          IN     VARCHAR2,
      p_rut_deudor            IN     VARCHAR2,
      p_clase_documento_sap   IN     VARCHAR2,
      p_monto_descuento       IN     VARCHAR2,
      p_codigo_carrera        IN     VARCHAR2,
      p_nro_matricula         IN     VARCHAR2,
      p_numero_material       IN     VARCHAR2,
      p_ret                      OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg                      OUT VARCHAR2               --mensaje de error
                                             )
      RETURN json
   IS
      v_token               VARCHAR2 (500);
      v_line_deuda          VARCHAR2 (32766);
      l_data_json           json;


      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      pl_centro_gestor      operacion_sub_operacion_sap.centro_gestor_base%TYPE;
      pl_observacion        VARCHAR2 (4000);
      v_respuesta           CLOB;
      id_log                NUMBER;
      l_resp_json           json;
      l_RETURN_json         json;
      l_data_json_l         json_list;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         BEGIN
            SELECT operacion_op,
                   sub_operacion_op,
                   clase_documento_icon || '-' || nombre_clase_documento obs,
                   centro_gestor_base
              INTO pl_operacion_op,
                   pl_sub_operacion_op,
                   pl_observacion,
                   pl_centro_gestor
              FROM operacion_sub_operacion_sap
             WHERE clase_documento_icon = p_numero_material;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pl_operacion_op := NULL;
               pl_sub_operacion_op := NULL;
               pl_centro_gestor := NULL;
            WHEN OTHERS
            THEN
               pl_operacion_op := NULL;
               pl_sub_operacion_op := NULL;
               pl_centro_gestor := NULL;
         END;


         v_line_deuda := '{
              "Token": "'  || v_token || '",
               "data":{
                       "Matricula": "' || p_tipo_proceso || '",
                       "Rut_Alumno": "' || p_rut_deudor || '",
                       "Clase_Doc": "' || p_clase_documento_sap || '",
                       "Fecha_Doc": "",
                       "Num_Cupon": "",
                       "Num_Doc": "",
                       "Cuota": "0000",
                       "Fecha_Vence": "",
                       "Importe": "' || p_monto_descuento || '-",
                       "Sociedad": "UT01",
                       "Carrera": "' || p_codigo_carrera || '",
                       "Moneda": "CLP",
                       "Num_Matricula": "' || p_nro_matricula || '",
                       "Centro_Beneficio": "' || pl_centro_gestor || '",
                       "Operacion_Principal": "' || pl_operacion_op || '",
                       "Operacion_Parcial": "' || pl_sub_operacion_op || '",
                       "Texto": "' || pl_observacion || '",
                       "Elemento_PEP": ""
                      }
                    }';

         BEGIN
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                         p_numero_material,
                         p_numero_material,
                         'Crea deuda POST:',
                         p_rut_deudor,
                         v_line_deuda,
                         SYSDATE);

            COMMIT;
            v_respuesta :=
               call_url_p_1 (
                  g_sistema_sap || '/RESTAdapter/FICA010/CREA_DESC',
                  v_line_deuda);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                  p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 dato2,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'R',
                            'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                            p_numero_material,
                            p_numero_material,
                            'Crea deuda POST:',
                            p_rut_deudor,
                            p_msg,
                            SYSDATE);
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('Resp'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg := v_respuesta;
                           l_data_json := NULL;
                     END;
               END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta 1 : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'R',
                      'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                      p_numero_material,
                      p_numero_material,
                      'Crea DSCTO POST:',
                      p_rut_deudor,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg := p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'CREA DSCTO FICA POSTGRADO',
                      p_numero_material,
                      p_numero_material,
                      'Crea DSCTO POST:',
                      p_rut_deudor,
                      p_msg,
                      SYSDATE);
   END int_crea_descuento_postgrado;



   FUNCTION int_crea_beca_postgrado (p_tipo_proceso          IN     VARCHAR2,
                                     p_rut_deudor            IN     VARCHAR2,
                                     p_clase_documento_sap   IN     VARCHAR2,
                                     p_monto_descuento       IN     VARCHAR2,
                                     p_codigo_carrera        IN     VARCHAR2,
                                     p_nro_matricula         IN     VARCHAR2,
                                     p_numero_material       IN     VARCHAR2,
                                     p_fecha_inicio          IN     VARCHAR2,
                                     p_fecha_fin             IN     VARCHAR2,
                                     p_ru_beca               IN     VARCHAR2,
                                     p_ret                      OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                     p_msg                      OUT VARCHAR2 --mensaje de error
                                                                            )
      RETURN json
   IS
      v_token               VARCHAR2 (500);
      v_line_deuda          VARCHAR2 (32000);
      l_data_json           json;
      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      pl_centro_gestor      operacion_sub_operacion_sap.centro_gestor_base%TYPE;
      pl_observacion        VARCHAR2 (4000);
      v_respuesta           CLOB;
      id_log                NUMBER;
      l_resp_json           json;
      l_RETURN_json         json;
      l_data_json_l         json_list;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/


      IF p_ret = 'S'
      THEN
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         BEGIN
            SELECT operacion_op,
                   sub_operacion_op,
                   clase_documento_icon || '-' || nombre_clase_documento obs,
                   centro_gestor_base
              INTO pl_operacion_op,
                   pl_sub_operacion_op,
                   pl_observacion,
                   pl_centro_gestor
              FROM operacion_sub_operacion_sap
             WHERE clase_documento_icon = p_numero_material;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pl_operacion_op := NULL;
               pl_sub_operacion_op := NULL;
               pl_centro_gestor := NULL;
            WHEN OTHERS
            THEN
               pl_operacion_op := NULL;
               pl_sub_operacion_op := NULL;
               pl_centro_gestor := NULL;
         END;



         v_line_deuda :=
               '{
          "Token": "'
            || v_token
            || '",
           "data":{
                   "Matricula": "'
            || p_tipo_proceso
            || '",
                   "Fecha_Inicio": "'
            || p_fecha_inicio
            || '",
                   "Fecha_Fin": "'
            || p_fecha_fin
            || '",
                   "Rut_Alumno": "'
            || p_rut_deudor
            || '",
                   "Clase_Doc": "'
            || p_clase_documento_sap
            || '",
                   "Fecha_Doc": "",
                   "Num_Cupon": "",
                   "Num_Doc": "",
                   "Cuota": "0000",
                   "Fecha_Vence": "",
                   "Importe": "'
            || p_monto_descuento
            || '-",
                   "Sociedad": "UT01",
                   "Carrera": "'
            || p_codigo_carrera
            || '",
                   "Moneda": "CLP",
                   "Num_Matricula": "'
            || p_nro_matricula
            || '",
                   "Centro_Beneficio": "'
            || pl_centro_gestor
            || '",
                   "Operacion_Principal": "'
            || pl_operacion_op
            || '",
                   "Operacion_Parcial": "'
            || pl_sub_operacion_op
            || '",
                   "Texto": "'
            || SUBSTR (p_ru_beca || ' ' || pl_observacion, 1, 50)
            || '",
                   "Elemento_PEP": ""
                  }
                }';



         BEGIN
            --INNSERTO LOG DE REGISTRO DE JSON DE LALLAMDA
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG05(CREA BECA FICA POSTGRADO)',
                         p_numero_material,
                         p_numero_material,
                         'Crea BECA POST:',
                         p_rut_deudor,
                         v_line_deuda,
                         SYSDATE);

            COMMIT;
            v_respuesta :=
               call_url_p_1 (
                  g_sistema_sap || '/RESTAdapter/FICA009/CREA_BECA',
                  v_line_deuda);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                  p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 dato2,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'R',
                            'INTLEG05(CREA BECA FICA POSTGRADO)',
                            p_numero_material,
                            p_numero_material,
                            'Crea BECA POST:',
                            p_rut_deudor,
                            p_msg,
                            SYSDATE);

               COMMIT;
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('Resp'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg := v_respuesta;
                           l_data_json := NULL;
                     END;
               END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta 1 : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;


         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'R',
                      'INTLEG05(CREA BECA FICA POSTGRADO)',
                      p_numero_material,
                      p_numero_material,
                      'Crea BECA POST:',
                      p_rut_deudor,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg := p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'CREA BECA FICA POSTGRADO',
                      p_numero_material,
                      p_numero_material,
                      'Crea BECA POST:',
                      p_rut_deudor,
                      p_msg,
                      SYSDATE);
   END int_crea_beca_postgrado;

   FUNCTION int_crea_descuento_pregrado (p_rut_deudor        IN     VARCHAR2,
                                         p_monto_descuento   IN     VARCHAR2,
                                         p_codigo_carrera    IN     VARCHAR2,
                                         p_nro_matricula     IN     VARCHAR2,
                                         p_ret                  OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                         p_msg                  OUT VARCHAR2 --mensaje de error
                                                                            )
      RETURN json
   IS
      v_token               VARCHAR2 (500);
      v_line_deuda          VARCHAR2 (32766);
      l_data_json           json;


      pl_operacion_op       operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op   operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      pl_centro_gestor      operacion_sub_operacion_sap.centro_gestor_base%TYPE;
      pl_observacion        VARCHAR2 (4000);
      v_respuesta           CLOB;
      id_log                NUMBER;
      l_resp_json           json;
      l_RETURN_json         json;
      l_data_json_l         json_list;
      carrera               NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF p_ret = 'S'
      THEN
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;


         v_line_deuda := '{
              "Token": "'  || v_token || '",
               "data":{
                       "Matricula": "",
                       "Rut_Alumno": "' || p_rut_deudor || '",
                       "Clase_Doc": "DA",
                       "Fecha_Doc": "",
                       "Num_Cupon": "",
                       "Num_Doc": "",
                       "Cuota": "0000",
                       "Fecha_Vence": "",
                       "Importe": "' || p_monto_descuento || '-",
                       "Sociedad": "UT01",
                       "Carrera": "' || p_codigo_carrera || '",
                       "Moneda": "CLP",
                       "Num_Matricula": "' || p_nro_matricula || '",
                       "Centro_Beneficio": "",
                       "Operacion_Principal": "",
                       "Operacion_Parcial": "",
                       "Texto": "DA-DESCUENTO ARANCEL",
                       "Elemento_PEP": ""
                      }
                    }';

         BEGIN
            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                         'Crea deuda POST:',
                         p_rut_deudor,
                         v_line_deuda,
                         SYSDATE);

            COMMIT;
            v_respuesta :=
               call_url_p_1 (
                  g_sistema_sap || '/RESTAdapter/FICA010/CREA_DESC',
                  v_line_deuda);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg :=
                  p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 tipo_integracion,
                                                 dato1,
                                                 msg_sap,
                                                 fecha_msg)
                    VALUES (id_log,
                            'R',
                            'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                            'Crea deuda POST:',
                            p_rut_deudor,
                            p_msg,
                            SYSDATE);
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               BEGIN
                  l_resp_json := json (v_respuesta);
                  l_data_json_l := json_list (l_resp_json.get ('Resp'));
                  l_data_json := json (l_data_json_l.get (1));
                  p_ret :=
                     lee_json (json (l_data_json_l.get (1)), 'TYPE');
                  p_msg :=
                        lee_json (json (l_data_json_l.get (1)), 'MESSAGE')
                     || ', '
                     || lee_json (json (l_data_json_l.get (2)), 'MESSAGE');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     BEGIN
                        l_resp_json := json (v_respuesta);
                        l_data_json := json (l_resp_json.get ('Resp'));

                        p_ret :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'TYPE');
                        p_msg :=
                           utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                               'MESSAGE');
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_ret := 'E';
                           p_msg := v_respuesta;
                           l_data_json := NULL;
                     END;
               END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta 1 : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'R',
                      'INTLEG05(CREA DSCTO FICA POSTGRADO)',
                      'Crea DSCTO POST:',
                      p_rut_deudor,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_ret := 'E';
         p_msg := p_msg || SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'CREA DSCTO FICA POSTGRADO',
                      'Crea DSCTO POST:',
                      p_rut_deudor,
                      p_msg,
                      SYSDATE);
   END int_crea_descuento_pregrado;

   FUNCTION int_leg05_portal_seminarios (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg         OUT VARCHAR2,                           --mensaje de error
      p_conv            VARCHAR2 DEFAULT NULL)
      RETURN json
   IS
      v_line                      VARCHAR2 (32766);
      v_json                      CLOB := EMPTY_CLOB ();
      v_respuesta                 CLOB;
      v_token                     VARCHAR2 (500);
      l_resp_json                 json;
      l_data_json                 json;
      l_return_json               json;
      pl_fecha_documento          VARCHAR2 (1000);
      p_numero_material           VARCHAR2 (1000);
      p_numero_deudor             VARCHAR2 (1000);
      p_monto                     VARCHAR2 (1000);
      v_convenio                  VARCHAR2 (3);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      p_nro_cuota                 NUMBER;
      id_log                      NUMBER;
      v_posicion_item             NUMBER := 0;
      V_MATERIAL                  VARCHAR2 (100);

      pl_operacion_op             operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op         operacion_sub_operacion_sap.sub_operacion_op%TYPE;

      p_pagar                     VARCHAR2 (2) := 'X';
      l_observacion_subproducto   VARCHAR2 (1000);

      l_clase_documento_sap       VARCHAR2 (10);

      l_centro_gestor_base        VARCHAR2 (200);
      l_centro_gestor_base2       VARCHAR2 (200);

      l_pade_matricula            VARCHAR2 (200);


      l_id_sap                    VARCHAR2 (30);
      l_cli_matricula             VARCHAR2 (50);
   BEGIN
      p_ret := 'S';

      IF p_conv = 'X'
      THEN
         v_convenio := 'Z8';
      ELSE
         v_convenio := get_clase_documento_sap(p_idcliente,p_num_op);
      END IF;

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;


               v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  --obtenemos el material de la tabla de productos
                  BEGIN
                     SELECT prod_centro_costo, prod_centro_costo
                       INTO V_MATERIAL, l_centro_gestor_base2
                       FROM vec_cob01.pop_productos
                      WHERE prod_id = reg.pade_prod_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_MATERIAL := '900001800';
                  END;

                  BEGIN
                     SELECT operacion_op,
                            sub_operacion_op,
                            clase_documento_sap,
                            centro_gestor_base
                       INTO pl_operacion_op,
                            pl_sub_operacion_op,
                            l_clase_documento_sap,
                            l_centro_gestor_base
                       FROM operacion_sub_operacion_sap
                      WHERE clase_documento_icon =
                               reg_grupo.pade_tipo_documento;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        pl_operacion_op := 1;
                        pl_sub_operacion_op := 1;
                  END;


                  BEGIN
                     SELECT p.prod_titulo || ' - ' || sp.prod_item_nombre
                       INTO l_observacion_subproducto
                       FROM vec_cob01.POP_PRODUCTOS       p,
                            vec_cob01.POP_PRODUCTOS_ITEMS sp
                      WHERE     p.prod_id = sp.prod_id
                            AND p.prod_id = reg.pade_prod_id
                            AND prod_item_id = reg.pade_subprod_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_observacion_subproducto := '';
                  END;

                  -- si el producto tiene configurado un centro gestor, lo respeta,
                  -- de lo contrario toma el general de la clase de producto .

                  l_centro_gestor_base :=
                     NVL (l_centro_gestor_base2, l_centro_gestor_base);

                  IF reg.pade_tipo_cliente = 'P'
                  THEN
                     l_observacion_subproducto :=
                           l_observacion_subproducto
                        || '- '
                        || reg.pade_prod_nomcliente;
                  ELSE
                     l_observacion_subproducto :=
                        l_observacion_subproducto || reg.pade_observacion;
                  END IF;


                  IF NVL (reg.pade_tipo_cliente, 'R') = 'R'
                  THEN
                     l_id_Sap := reg.pa_rut;
                     l_cli_matricula := p_idcliente;
                  ELSE
                     l_id_Sap :=
                        vec_cob02.cli_extranjero_pasaporte_pkg.id_sap2 (
                           reg.pade_prod_idcliente);
                     ---l_cli_matricula := l_id_Sap ;
                     l_cli_matricula := 5555;
                  END IF;


                  v_line :=
                        v_line
                     || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                     || l_id_Sap
                     || '",
                               "Tipo_documento": "'
                     || l_clase_documento_sap
                     || '",
                               "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Nro_Cuponera": "'
                     || reg.pa_nro_operacion
                     || '",
                               "Documento": "",
                               "Cuota": "0001",
                               "Fecha_vencimiento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Importe": "'
                     || reg.pade_monto_local
                     || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                     || reg.pade_nro_carrera
                     || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                     || l_cli_matricula
                     || '",
                               "Centro_beneficio": "",
                               "Operacion": "'
                     || pl_operacion_op
                     || '",
                               "Sub_operacion": "'
                     || pl_sub_operacion_op
                     || '",
                               "Descripcion": "'
                     || SUBSTR (
                           REPLACE (
                                 l_observacion_subproducto
                              || reg.pade_observacion,
                              '"',
                              ''),
                           1,
                           47)
                     || '@'
                     || v_convenio
                     || '",
                               "Elemento_PEP": "'
                     || l_centro_gestor_base
                     || '",
                               "Pagar": "'
                     || p_pagar
                     || '",
                                 "Tipo_Documento_Pago": "'||v_convenio||'"
                            }';
               END LOOP;


               v_json := v_json || v_line;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            BEGIN
               INSERT INTO log_portal_pagos_sap (id,
                                                 tipo_llamada,
                                                 integracion,
                                                 pade_nro_documento,
                                                 tipo_integracion,
                                                 dato1,
                                                 dato2,
                                                 msg_sap,
                                                 fecha_msg)
                       VALUES (
                                 id_log,
                                 'S',
                                 'int_leg05_portal_seminarios(CREA Y PAGA DEUDA)*',
                                 V_MATERIAL,
                                 'Crea y paga deuda',
                                 p_idcliente,
                                 p_num_op,
                                 v_json,
                                 SYSDATE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            COMMIT;

            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json := json (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (ID,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'int_leg05_portal_seminarios(CREA Y PAGA DEUDA)**',
                      V_MATERIAL,
                      p_num_op,
                      'Crea y paga deuda',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error:' || SQLERRM;

            INSERT INTO log_portal_pagos_sap (ID,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                 VALUES (id_log,
                         'S',
                         'int_leg05_portal_seminarios(CREA Y PAGA DEUDA)***',
                         p_num_op,
                         p_num_op,
                         'Crea y paga deuda',
                         p_idcliente,
                         p_msg,
                         SYSDATE);

            COMMIT;
      END;

      RETURN l_data_json;
   END int_leg05_portal_seminarios;



   FUNCTION int_leg04_json_interfaces_ex (
      p_tipo_interlocutor            VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_rut                      VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_condicion_pago           VARCHAR2 DEFAULT NULL,
      p_cli_matricula                VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_cod_carrera              VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_agrupacion               VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_tratamiento              VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres1                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres2                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres3                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_nombres4                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_cod_giro                 VARCHAR2 DEFAULT NULL, --parametro consulta rubro codigo del giro
      p_cli_sexo                     VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_rubro                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_direccion                VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_numero                   VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_codigo_comuna            VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_region                   VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_telefono                 VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_movil                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_email                    VARCHAR2 DEFAULT NULL, --parametro consulta
      p_cli_canal_distribucion       VARCHAR2 DEFAULT NULL, --parametro consulta
      p_ret                      OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg                      OUT VARCHAR2               --mensaje de error
                                             )
      RETURN json
   IS
      v_json            VARCHAR2 (32000);
      --v_respuesta varchar2(32000);
      v_respuesta       LONG;
      v_token           VARCHAR2 (500);

      l_resp_json       json;
      l_data_json       json_list;
      l_data_json2      json;
      l_RETURN_json     json;
      resp_json         json;
      v_grupo_cliente   VARCHAR (200);

      v_mensaje_error   VARCHAR2 (1000);
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.Get_token;
      /*select utal_dti.p_encrypt_utal.encrypt_ssn_sap(G_clave || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')) as dato_encriptado
           into v_token
           from dual;*/
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/

      IF (   p_cli_canal_distribucion = '11'
          OR p_cli_canal_distribucion = '12'
          OR p_cli_canal_distribucion = '13')
      THEN
         v_grupo_cliente := '15';
      ELSE
         v_grupo_cliente := '10';
      END IF;

      IF p_ret = 'S'
      THEN
         /*Json de entrada que requiere el servicio SAP, Formato entregado por seidor donde se reemplazan los parametros de Entrada*/
         /*Orden_CO siempre va vacío*/

         v_json :=
               '{
                "Token": "'
            || v_token
            || '",
                "data": {
                               "Tipo_interlocutor": "'
            || p_tipo_interlocutor
            || '",
                               "Cli_rut": "'
            || p_cli_rut
            || '",
                               "Cli_matricula": "'
            || p_cli_matricula
            || '",
                               "Cli_cod_carrera": "'
            || p_cli_cod_carrera
            || '", // 03
                               "Cli_agrupacion": "'
            || p_cli_agrupacion
            || '",  // ZC01 nacional
                               "Cli_role": "FMCA02X",
                               "Cli_vigencia": "29991231",
                               "Cli_tratamiento": "'
            || p_cli_tratamiento
            || '", // 0003
                               "Cli_nombres1": "'
            || p_cli_nombres1
            || '",
                               "Cli_nombres2": "'
            || p_cli_nombres2
            || '",
                               "Cli_nombres3": "'
            || p_cli_nombres3
            || '", // codigo del giro
                               "Cli_nombres4": "'
            || p_cli_nombres4
            || '",
                               "Cli_sexo": "'
            || p_cli_sexo
            || '",
                               "Cli_busqueda": "P. EXTRANJERO",
                               "Cli_busqueda2": "'
            || p_cli_rubro
            || '", // rubro
                               "Cli_direccion": "2 Norte",
                               "Cli_numero": "685",
                               "Cli_cod_postal": "",
                               "Cli_codigo_comuna": "TALCA",
                               "Cli_pais": "CL",
                               "Cli_region": "07", //  ||p_cli_region||
                               "Cli_telefono": "'
            || p_cli_telefono
            || '",
                               "Cli_movil": "'
            || p_cli_movil
            || '",
                               "Cli_email": "'
            || p_cli_email
            || '",
                               "Cli_estado_civil": "1",
                               "Cli_nacionalidad": "CL",
                               "Cli_clase_ic": "9010",
                               "Cli_sociedad": "UT01",
                               "Cli_cuenta": "2102010020",
                               "Cli_condicion_pago": "'
            || p_cli_condicion_pago
            || '",
                               "Cli_vias_pago": "1",
                               "Cli_canal_distribucion": "'
            || p_cli_canal_distribucion
            || '", // 13
                               "Cli_zona_venta": "UT01",
                               "Cli_grupo_cliente": "'
            || v_grupo_cliente
            || '",
                               "Cli_pedido": "001",
                               "Cli_gpo_precio": "01",

                               "Cli_esquema_cliente": "01",
                               "Cli_expedicion": "01",
                               "Cli_grupo_imputacion": "01",
                               "Cli_clasificacion_fiscal": "0",

                               "Cli_id_banco": "",
                               "Cli_clave_pais_banco": "",
                               "Cli_clave_banco": "",
                               "Cli_cuenta_corriente": "",

                               "Pro_sociedad": "UT01",

                               "Pro_cuenta_mayor": "2102010020",
                               "Pro_cond_pago": "P030",
                               "Pro_verif_doble": "X",
                               "Pro_via_pago": "1",
                               "Pro_tipo_retencion": "",
                               "Pro_ind_retencion": "",
                               "Pro_sujeto_a_retencion": "",
                               "Pro_org_compras": "UT02",
                               "Pro_moneda": "CLP",
                               "Pro_grupo_esquema": "Z2",
                }
}'        ;

         /*Fin Json de entrada */


         --htp.p(v_json);
         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
            */
            /* g_sistema_sap_alan    sappoqa.utalca.cl:52000/RESTAdapter/SD004/INT_LEG04 -- sappodev.utalca.cl:51000/RESTAdapter/SD004/INT_LEG04*/



            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD004/INT_LEG04',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := SQLERRM;
         END;

         INSERT INTO LOG_CREA_CLIENTE_SAP (rut,
                                           mensaje_sql,
                                           msg_sap,
                                           fecha_msg)
              VALUES (9999,
                      v_json,
                      SUBSTR (v_respuesta, 1, 4000),
                      SYSDATE);
      END IF;

      --****IMPRIMER JSON DE RESPUESTA
      -- htp.p(v_respuesta);
      /* if(p_cli_canal_distribucion='17') then
           htp.p(v_json);
       end if;

       htp.p(p_cli_region);*/

      IF p_ret = 'S'
      THEN
         BEGIN
            /*respuesta la inserta en una estructura en un json*/
            l_RETURN_json := json (v_respuesta);
         /* seccion data la inserta en un  json*/
         --  l_data_json := json(l_resp_json.get('data'));
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
               l_data_json := NULL;
         END;
      END IF;

      /* en duto debo descomentar insert into log_editorial_sap (item_type,
         item_key  ,
         msg_sap,fecha_msg) values (p_cli_rut,p_cli_nombres1, v_respuesta,sysdate);
         commit;*/



      /*
          --verifica que el data viene vacío
          if l_data_json is null then
              p_ret := 'E';
              p_msg := 'Error en el formato de la respuesta : '||sqlerrm;
          end if;
           /*retorna json   */
      RETURN l_RETURN_json;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_mensaje_error := SQLERRM || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO LOG_CREA_CLIENTE_SAP (rut,
                                           mensaje_sql,
                                           msg_sap,
                                           fecha_msg)
              VALUES (9999,
                      v_mensaje_error,
                      ' ',
                      SYSDATE);
   END int_leg04_json_interfaces_ex;

   ----JV - DS 20-08-2024 INTEGRACION DE VENTAS PORTAL INTEGRAL

   FUNCTION int_leg05_sd_portal_integral (p_idcliente       VARCHAR2,
                                          p_num_op          VARCHAR2,
                                          p_ret         OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
                                          p_msg         OUT VARCHAR2 --mensaje de error
                                                                    )
      RETURN json
   IS
      v_line                    VARCHAR2 (32766);
      v_json                    CLOB := EMPTY_CLOB ();
      v_respuesta               CLOB;
      v_token                   VARCHAR2 (500);
      l_resp_json               json;
      l_data_json               json;
      l_return_json             json;
      pl_fecha_documento        VARCHAR2 (1000);
      p_numero_material         VARCHAR2 (1000);
      p_numero_deudor           VARCHAR2 (1000);
      p_monto                   VARCHAR2 (1000);
      v_codigo_error            VARCHAR2 (20);
      v_mensaje_error           VARCHAR2 (4000);
      v_fecha_error             DATE;
      v_mensaje_personalizado   VARCHAR2 (4000);
      v_error                   VARCHAR2 (2000);
      p_nro_cuota               NUMBER;
      id_log                    NUMBER;
      v_posicion_item           NUMBER := 0;
      v_canal                   VARCHAR2 (50);
      v_codigo                  VARCHAR2 (50);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a,
                vec_cob01.pip_productos2             b,
                utsap001.sap_categoria_canal         c
          WHERE     a.pa_rut = p_idcliente
                AND a.pade_tipo_documento = p_tipo_doc
                AND a.pa_nro_operacion = p_num_op
                AND a.pade_prod_id = b.id_producto
                AND c.categoria = b.id_categoria;

      --cursor para obtener el detalle del producto y quién compra JV-DS
      CURSOR c_deudas_ventas (
         pa_nro_operacion    VARCHAR2)
      IS
         SELECT p_prod.codigo_sap,
                p_det.pade_monto,
                p_det.pade_fec_vencimiento,
                p_prod.id_categoria
           FROM vec_cob01.pip_productos2             p_prod,
                vec_cob01.pop_pagos_detalle_temp_sap p_det
          WHERE     p_det.pade_prod_id = p_prod.id_producto
                AND p_det.pa_nro_operacion = pa_nro_operacion; -- parametro de entrada
   -- fin para obtener el detalle del producto y quién compra JV-DS
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_line :=
                        '{
                                    "TOKEN": "'
                     || v_token
                     || '",
                                    "FLAG": "SD",
                                    "BAPI_SALESORDER_CREATEFROMDAT2": {
                                    "ORDER_HEADER_IN": {
                                        "Tipo_objeto": "BUS2031",
                                        "Clase_documento": "'
                     || reg.codigo
                     || '",
                                        "Canal_distribucion": "'
                     || reg.canal
                     || '",
                                        "Fecha_entrega": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                        "Fecha_referencia_cliente": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                        "Cupon_pago": "'
                     || p_num_op
                     || '",
                                        "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                        "Matricula": "'
                     || reg.pa_rut
                     || '",
                                        "Codigo_carrera": "'
                     || reg.pade_nro_carrera
                     || '"
                                    },';

                  v_json := v_line;
                  v_line := '';

                  --DETALLE DE LOS PRODUCTOS
                  FOR reg_sap IN c_deudas_ventas (reg.pa_nro_operacion)
                  LOOP
                     v_posicion_item := v_posicion_item + 10;
                     v_line :=
                           ' "ORDER_ITEMS_IN": {
                                        "Posicion_documento": "'
                        || v_posicion_item
                        || '",
                                        "Posicion_superior_materiales": "000000",
                                        "Numero_material": "'
                        || reg_sap.codigo_sap
                        || '",
                                        "Jerarquia_posicion": "U0035",
                                        "Centro": "UT01",
                                        "Cantidad_prevista": "1",
                                        "Unidad_medida": "UN",
                                        "Centro_beneficio": "",
                                        "Creado_por": "SYSPOSTGRADO",
                                        "Clase_factura": "ZF02",
                                        "Fecha_factura": "'
                        || reg.pade_fec_vencimiento
                        || '",
                                        "Pagar": "X"
                               },';

                     v_json := v_json || v_line;
                     v_line := '';
                     v_line :=
                           '"ORDER_PARTNERS": {
                                        "Funcion_interlocutor": "AG",
                                        "Numero_deudor": "'
                        || reg.pa_rut
                        || '",
                                        "Clave_pais": "CL",
                                        "Clave_idioma": "ES"
                               },';
                     v_line :=
                           v_line
                        || '"ORDER_SCHEDULES_IN": {
                                        "Posicion_documento": "'
                        || v_posicion_item
                        || '",
                                        "N_reparto": "0001",
                                        "Fecha_reparto": "'
                        || reg.pade_fec_vencimiento
                        || '",
                                        "Cantidad_pedida": "1"
                              },
                          "ORDER_CONDITIONS_IN": {
                                        "Numero_posicion_condicion": "'
                        || v_posicion_item
                        || '",
                                        "Clase_condicion": "ZPR0",
                                        "Importe_condicion": "'
                        || reg_sap.pade_monto
                        || '",
                                        "Clave_moneda": "CLP",
                                        "Unidad_medida_condicion": "UN"
                               },';

                     p_nro_cuota := p_nro_cuota + 10;
                     v_json := v_json || v_line;
                     v_line := '';
                  END LOOP;
               END LOOP;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            --htp.p(v_json);
            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := json (v_respuesta);
               l_data_json := json (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD VENTA)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda venta:',
                      p_idcliente,
                      v_json,
                      SYSDATE);

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD VENTA)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda venta:',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
            v_mensaje_personalizado := SQLERRM;
            v_codigo_error := SQLCODE;
            v_mensaje_error :=
                  SQLERRM
               || DBMS_UTILITY.format_error_backtrace
               || ' - '
               || p_idcliente;
            v_fecha_error := SYSDATE;

            INSERT INTO log_portal_pagos_sap (id,
                                              tipo_llamada,
                                              integracion,
                                              pade_nro_documento,
                                              dato2,
                                              tipo_integracion,
                                              dato1,
                                              msg_sap,
                                              fecha_msg)
                    VALUES (
                              id_log,
                              'R',
                              'INTLEG05(CREA Y PAGA DEUDA  SD VENTA)',
                              p_num_op,
                              p_num_op,
                                 p_msg
                              || '-Crea y paga deuda venta:'
                              || v_mensaje_error,
                              p_idcliente,
                              v_respuesta,
                              SYSDATE);

            COMMIT;
      END;

      RETURN l_data_json;
   END int_leg05_sd_portal_integral;
   
    /* JV 27/11/2024 */

    /*se agrega integracion fica portal integral ds 31/01/2025*/
    FUNCTION int_leg05_fica_portal_integral (
        p_idcliente VARCHAR2,
        p_num_op    VARCHAR2,
        p_ret       OUT VARCHAR2, --Salida estado si tiene error en oracle S (Success) E (Error)
        p_msg       OUT VARCHAR2 --mensaje de error
    ) RETURN json IS

        v_line                  VARCHAR2(32766);
        v_json                  VARCHAR2(32766);
        v_respuesta             CLOB;
        v_envio_mail            CLOB;
        v_token                 VARCHAR2(500);
        l_resp_json             json;
        l_data_json             json;
        v_codigo_error          VARCHAR2(20);
        v_mensaje_error         VARCHAR2(4000);
        v_fecha_error           DATE;
        v_mensaje_personalizado VARCHAR2(4000);
        id_log                  NUMBER;
        v_posicion_item         NUMBER := 10;
        v_canal                 VARCHAR2(50);
        v_codigo                VARCHAR2(50);
        v_canal_anterior        VARCHAR2(100) := NULL; -- Para almacenar el valor anterior del canal
        v_canal_anterior_det    VARCHAR2(100) := NULL; -- Para almacenar el valor anterior del canal
        v_tiene_factura         NUMBER;

        CURSOR c_cabecera IS
        SELECT
            pade_fec_vencimiento,
            pa_rut,
            pade_nro_carrera,
            pade_tipo_documento AS tipo_documento,
            --b.operacion_principal,se cambia DS17/07/2025
            --b.operacion_parcial, se cambia DS17/07/2025
            b.nombre_servicio,
            b.elemento_pep,
            a.pade_monto,
            a.pade_matricula,
            pade_nro_documento,
            e.clase_documento_sap, --Se agrega nuevo campo para integración SAP
            f.operacion_parcial, --SE AGREGA parametrización17/07/2025
            f.operacion_principal--SE AGREGA parametrización17/07/2025
        FROM
                 vec_cob01.pop_pagos_detalle_temp_sap a
            JOIN vec_cob01.pip_servicios b ON a.pade_prod_id = b.id_servicio
            JOIN vec_cob02.webpay_trasaccion d ON TO_CHAR(d.id_sesion) = TO_CHAR(a.pa_nro_operacion)--Se agrega nuevo campo para integración SAP
            JOIN vec_cob02.tipo_pago_descripcion e ON d.tipo_pago = e.codigo_pago --Se agrega nuevo campo para integración SAP
            JOIN utsap001.servicios_operaciones f ON a.pade_tipo_documento = f.codigo_documento--SE AGREGA parametrización 17/07/2025
        WHERE
                a.pa_rut = p_idcliente
            AND a.pa_nro_operacion = p_num_op
        GROUP BY
            pade_fec_vencimiento,
            pa_rut,
            pade_nro_carrera,
            pade_tipo_documento,
            --b.operacion_principal,
            --b.operacion_parcial,
            b.nombre_servicio,
            b.elemento_pep,
            a.pade_monto,
            a.pade_matricula,
            pade_nro_documento,
            e.clase_documento_sap,--Se agrega nuevo campo para integración SAP
            f.operacion_parcial,
            f.operacion_principal;

        /*
        CURSOR c_facturas IS
        SELECT COUNT(*)
        INTO v_tiene_factura
        FROM vec_cob01.PIP_FACTURAS_RECIBIDAS
        WHERE cupon = p_num_op;
        */

    BEGIN
        p_ret := 'S';
        BEGIN
            /* Recupera Token*/
            v_token := pkg_token.get_token;
            /* Fin Recupera Token*/
            SELECT
                seq_id_log_intleg02portal.NEXTVAL
            INTO id_log
            FROM
                dual;

            IF p_ret = 'S' THEN
                FOR reg_grupo IN c_cabecera LOOP
                    v_json := '{
                                "TOKEN": "'
                              || v_token
                              || '",
                                "FLAG": "FICA",
                                "BAPI_CTRACDOCUMENT_CREATE": {
                                "ZCLFICA_MF_CREADEUDA": {
                                    "Codigo_cli": "'
                              || reg_grupo.pa_rut
                              || '",
                                    "Tipo_documento": "'
                              || reg_grupo.tipo_documento
                              || '",
                                    "Fecha_documento": "'
                              || reg_grupo.pade_fec_vencimiento
                              || '",
                                    "Nro_Cuponera": "'
                              || p_num_op
                              || '",
                                    "Documento": "",
                                    "Cuota": "0001",
                                "Fecha_vencimiento": "'
                              || reg_grupo.pade_fec_vencimiento
                              || '",
                                "Importe": "'
                              || reg_grupo.pade_monto
                              || '",
                                "Empresa": "UT01",
                                "Carrera": "SD",
                                "Moneda": "CLP",
                                "Nro_matricula": "'
                              || reg_grupo.pade_matricula
                              || '",
                                "Centro_beneficio": "",
                                "Operacion": "'
                              || reg_grupo.operacion_principal
                              || '",
                                "Sub_operacion": "'
                              || reg_grupo.operacion_parcial
                              || '",
                                "Descripcion": "'
                              || reg_grupo.nombre_servicio
                              || '",
                                "Elemento_PEP": "'
                              || reg_grupo.elemento_pep
                              || '",
                                "Pagar": "X",
                                "Tipo_Documento_Pago":"'
                                ||reg_grupo.clase_documento_sap
                                ||'"
                                }}}';
                    --Se agrega nuevo campo para integración SAP
                    BEGIN
                        v_respuesta := call_url_p(g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05', v_json);

                    EXCEPTION
                        WHEN OTHERS THEN
                            p_ret := 'E';
                            p_msg := p_msg || sqlerrm;
                    END;

                END LOOP;

--htp.p(v_json);
            END IF;

            IF p_ret = 'S' THEN
                BEGIN
                    l_resp_json :=
                        JSON(
                            v_respuesta
                        );
                    l_data_json :=
                        JSON(
                            l_resp_json.get('data')
                        );
                    p_ret := lee_json(l_data_json, 'TYPE');
                    p_msg := lee_json(l_data_json, 'MESSAGE');
                EXCEPTION
                    WHEN OTHERS THEN
                        p_ret := 'E';
                        p_msg := 'Error en el formato de la respuesta: ' || sqlerrm;
                        l_data_json := NULL;
                END;
            END IF;

            IF l_data_json IS NULL THEN
                p_ret := 'E';
                p_msg := 'Error en el formato de la respuesta: ' || sqlerrm;
            END IF;

            INSERT INTO log_portal_pagos_sap (
                id,
                tipo_llamada,
                integracion,
                pade_nro_documento,
                dato2,
                tipo_integracion,
                dato1,
                msg_sap,
                fecha_msg
            ) VALUES (
                id_log,
                'S',
                'INTLEG05(CREA Y PAGA DEUDA FICA VENTA)',
                p_num_op,
                p_num_op,
                substr(p_msg
                       || '-Crea y paga deuda venta fica:'
                       || v_mensaje_error, 1, 4000),-- Se ajusta para tamaño de respuesta 30/08/2024 DS
                p_idcliente,
                substr(v_json, 1, 4000),-- Se ajusta para tamaño de respuesta 30/08/2024 DS
                sysdate
            );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                p_ret := 'E';
                p_msg := 'error recuperando el TOKEN:' || sqlerrm;
                v_mensaje_personalizado := sqlerrm;
                v_codigo_error := sqlcode;
                v_mensaje_error := sqlerrm
                                   || dbms_utility.format_error_backtrace
                                   || ' - '
                                   || p_idcliente;
                v_fecha_error := sysdate;
                INSERT INTO log_portal_pagos_sap (
                    id,
                    tipo_llamada,
                    integracion,
                    pade_nro_documento,
                    dato2,
                    tipo_integracion,
                    dato1,
                    msg_sap,
                    fecha_msg
                ) VALUES (
                    id_log,
                    'R',
                    'INTLEG05(CREA Y PAGA DEUDA FICA VENTA)',
                    p_num_op,
                    p_num_op,
                    substr(p_msg
                           || '-Crea y paga deuda venta fica EXCEPTION:'
                           || v_mensaje_error, 1, 4000), -- Se ajusta para tamaño de respuesta 30/08/2024 DS
                    p_idcliente,
                    substr(v_respuesta, 1, 4000),-- Se ajusta para tamaño de respuesta 30/08/2024 DS
                    sysdate
                );

                COMMIT;
        END;

        RETURN l_data_json;
    END int_leg05_fica_portal_integral;

   -- CREADO POR ALEXIS PARA PORTAL DE PAGOS SANTANDER
   FUNCTION int_leg05_fica_portal_sant (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2,
      --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg         OUT VARCHAR2,                          --mensaje de error,
      p_pagar           VARCHAR2 DEFAULT 'X')
      RETURN json
   IS
      v_line                 VARCHAR2 (32766);
      v_json                 CLOB := EMPTY_CLOB ();
      --
      v_respuesta            CLOB;
      v_token                VARCHAR2 (500);
      l_resp_json            json;
      l_data_json            json;
      l_return_json          json;
      l_data_json_l          json_list;
      l_centro_gestor_base   operacion_sub_operacion_sap.centro_gestor_base%TYPE;

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      pl_operacion_op        operacion_sub_operacion_sap.operacion_op%TYPE;
      pl_sub_operacion_op    operacion_sub_operacion_sap.sub_operacion_op%TYPE;
      id_log                 NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      /* Fin Recupera Token*/
      IF p_ret = 'S'
      THEN
         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         FOR reg_grupo IN c_deudas_actuales (p_idcliente)
         LOOP
            BEGIN
               SELECT operacion_op, sub_operacion_op, centro_gestor_base
                 INTO pl_operacion_op,
                      pl_sub_operacion_op,
                      l_centro_gestor_base
                 FROM operacion_sub_operacion_sap
                WHERE clase_documento_sap = reg_grupo.pade_tipo_documento;

               -- clase_documento_sap clase_documento_icon

               v_line := '{
                    "TOKEN": "' || v_token || '",
                    "FLAG": "FICA",
                    "BAPI_CTRACDOCUMENT_CREATE": {';

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_line :=
                        v_line
                     || ' "ZCLFICA_MF_CREADEUDA":{
                               "Codigo_cli": "'
                     || reg.pa_rut
                     || '",
                               "Tipo_documento": "'
                     || reg.pade_tipo_documento
                     || '",
                               "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Nro_Cuponera": "'
                     || reg.pa_nro_operacion
                     || '",
                               "Documento": "",
                               "Cuota": "0001",
                               "Fecha_vencimiento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                               "Importe": "'
                     || reg.pade_monto_local
                     || '",
                               "Empresa": "UT01",
                               "Carrera": "'
                     || reg.pade_nro_carrera
                     || '",
                               "Moneda": "CLP",
                               "Nro_matricula": "'
                     || reg.pade_matricula
                     || '",
                               "Centro_beneficio": "'
                     || l_centro_gestor_base
                     || '",
                               "Operacion": "'
                     || pl_operacion_op
                     || '",
                               "Sub_operacion": "'
                     || pl_sub_operacion_op
                     || '",
                               "Descripcion": "'
                     || reg.pade_observacion
                     || '",
                               "Elemento_PEP": "",
                               "Pagar": "'
                     || p_pagar
                     || '",
                     "Tipo_Documento_Pago": "Z8"
                            }';
               END LOOP;

               v_json := v_json || v_line;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
         END LOOP;

         v_line := '';
         v_line := '} }';
         v_json := v_json || v_line;

         /*Fin Json de entrada */
         BEGIN
            /*llamada a servicio SAP  http://usuario:contraseña@servidor_sap:puerto/servicio  */
            /*  sappodev:desarrollo  puerto 51000
                sappoqa:testing      puerto 52000
                    falta que nos envien la url para la interfaz int_leg02
            */
            v_respuesta :=
               call_url_p (g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                           v_json);
         /*Fin llamada a servicio SAP*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_ret := 'E';
               p_msg := p_msg || SQLERRM;
         END;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := JSON (v_respuesta);
               l_data_json_l := json_list (l_resp_json.get ('Resp'));
               l_data_json := JSON (l_data_json_l.get (1));
               p_ret :=
                  lee_json (JSON (l_data_json_l.get (1)), 'TYPE');
               p_msg :=
                     lee_json (JSON (l_data_json_l.get (1)), 'MESSAGE')
                  || ', '
                  || lee_json (JSON (l_data_json_l.get (2)), 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     l_resp_json := JSON (v_respuesta);
                     l_data_json := JSON (l_resp_json.get ('Resp'));
                     p_ret :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'TYPE');
                     p_msg :=
                        utsap001.pkg_integra_utal.lee_json (l_data_json,
                                                            'MESSAGE');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_ret := 'E';
                        p_msg := v_respuesta;
                        l_data_json := NULL;
                  END;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta 2 : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
                 VALUES (
                           id_log,
                           'S',
                           'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_portal_sap',
                           p_num_op,
                           p_num_op,
                           'Crea y paga deuda:',
                           p_idcliente,
                           v_json,
                           SYSDATE);

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
                 VALUES (
                           id_log,
                           'S',
                           'INTLEG05(CREA Y PAGA DEUDA  FICA) - int_leg05_fica_portal_sap',
                           p_num_op,
                           p_num_op,
                           'Crea y paga deuda:',
                           p_idcliente,
                           v_respuesta,
                           SYSDATE);

         COMMIT;
      END IF;

      RETURN l_data_json;
   END int_leg05_fica_portal_sant;

   -- CREADO POR ALXIS, PARA PORTAL DE PAGOS DE TITULACION SANTANBDER
   FUNCTION int_leg05_sd_titulacion_sant (
      p_idcliente       VARCHAR2,
      p_num_op          VARCHAR2,
      p_ret         OUT VARCHAR2,
      --Salida estado si tiene error en oracle S (Success) E (Error)
      p_msg         OUT VARCHAR2,                           --mensaje de error
      p_pagar           VARCHAR2 DEFAULT 'X')
      RETURN json
   IS
      v_line               VARCHAR2 (32766);
      v_json               CLOB := EMPTY_CLOB ();
      v_respuesta          CLOB;
      v_token              VARCHAR2 (500);
      l_resp_json          json;
      l_data_json          json;
      l_return_json        json;
      pl_fecha_documento   VARCHAR2 (1000);
      p_numero_material    VARCHAR2 (1000);
      p_numero_deudor      VARCHAR2 (1000);
      p_monto              VARCHAR2 (1000);

      --cursor de deudas en tabla temporal, agrupada por tipo
      CURSOR c_deudas_actuales (p_idcliente NUMERIC)
      IS
         SELECT DISTINCT pade_tipo_documento
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE pa_rut = p_idcliente AND pa_nro_operacion = p_num_op;

      --cursor de deudas en tabla temporal que forma el json
      CURSOR c_deudas_actuales_detalle (
         p_tipo_doc    VARCHAR2)
      IS
         SELECT *
           FROM vec_cob01.pop_pagos_detalle_temp_sap a
          WHERE     pa_rut = p_idcliente
                AND pade_tipo_documento = p_tipo_doc
                AND pa_nro_operacion = p_num_op;

      p_nro_cuota          NUMBER;
      id_log               NUMBER;
   BEGIN
      p_ret := 'S';

      /* Recupera Token*/
      BEGIN
         v_token := pkg_token.get_token;

         /* Fin Recupera Token*/
         SELECT seq_id_log_intleg02portal.NEXTVAL INTO id_log FROM DUAL;

         IF p_ret = 'S'
         THEN
            FOR reg_grupo IN c_deudas_actuales (p_idcliente)
            LOOP
               p_nro_cuota := 10;

               FOR reg
                  IN c_deudas_actuales_detalle (
                        reg_grupo.pade_tipo_documento)
               LOOP
                  v_line :=
                        '{
                                    "TOKEN": "'
                     || v_token
                     || '",
                                    "FLAG": "SD",
                                    "BAPI_SALESORDER_CREATEFROMDAT2": {
                                    "ORDER_HEADER_IN": {
                                                          "Tipo_objeto": "BUS2031",
                                                          "Clase_documento": "ZP04",
                                                          "Canal_distribucion": "11",
                                                          "Fecha_entrega": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Fecha_referencia_cliente": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Cupon_pago": "'
                     || p_num_op
                     || '",
                                                          "Fecha_documento": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                          "Matricula": "'
                     || reg.pade_matricula
                     || '",
                                                          "Codigo_carrera": "'
                     || reg.pade_nro_carrera
                     || '"
                                    },';

                  v_json := v_line;
                  v_line := '';
                  v_line :=
                        ' "ORDER_ITEMS_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "Posicion_superior_materiales": "000000",
                                                      "Numero_material": "'
                     || reg.pade_tipo_documento
                     || '",
                                                      "Jerarquia_posicion": "U0035",
                                                      "Centro": "UT01",
                                                      "Cantidad_prevista": "1",
                                                      "Unidad_medida": "UN",
                                                      "Centro_beneficio": "",
                                                      "Creado_por": "SYSPOSTGRADO",
                                                      "Clase_factura": "ZF02",
                                                      "Fecha_factura": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Pagar": "'
                     || p_pagar
                     || '",
                     "Tipo_Documento_Pago": "Z8"
                               },';

                  v_line :=
                        v_line
                     || '"ORDER_PARTNERS": {
                                                      "Funcion_interlocutor": "AG",
                                                      "Numero_deudor": "'
                     || reg.pa_rut
                     || '",
                                                      "Clave_pais": "CL",
                                                      "Clave_idioma": "ES"
                               },';
                  v_line :=
                        v_line
                     || '"ORDER_SCHEDULES_IN": {
                                                      "Posicion_documento": "'
                     || p_nro_cuota
                     || '",
                                                      "N_reparto": "0001",
                                                      "Fecha_reparto": "'
                     || reg.pade_fec_vencimiento
                     || '",
                                                      "Cantidad_pedida": "1"
                              },
                               "ORDER_CONDITIONS_IN": {
                                                      "Numero_posicion_condicion": "'
                     || p_nro_cuota
                     || '",
                                                      "Clase_condicion": "ZPR0",
                                                      "Importe_condicion": "'
                     || reg.pade_monto_local
                     || '",
                                                      "Clave_moneda": "CLP",
                                                      "Unidad_medida_condicion": "UN"
                               },';

                  p_nro_cuota := p_nro_cuota + 10;
                  v_json := v_json || v_line;
                  v_line := '';
               END LOOP;
            END LOOP;

            v_line := '';
            v_line := '} }';
            v_json := v_json || v_line;

            BEGIN
               v_respuesta :=
                  call_url_p (
                     g_sistema_sap || '/RESTAdapter/SD001/INT_LEG05',
                     v_json);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg := p_msg || SQLERRM;
            END;
         END IF;

         IF p_ret = 'S'
         THEN
            BEGIN
               l_resp_json := JSON (v_respuesta);
               l_data_json := JSON (l_resp_json.get ('data'));
               p_ret := lee_json (l_data_json, 'TYPE');
               p_msg := lee_json (l_data_json, 'MESSAGE');
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_ret := 'E';
                  p_msg :=
                     'Error en el formato de la respuesta : ' || SQLERRM;
                  l_data_json := NULL;
            END;
         END IF;

         IF l_data_json IS NULL
         THEN
            p_ret := 'E';
            p_msg := 'Error en el formato de la respuesta : ' || SQLERRM;
         END IF;

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda:',
                      p_idcliente,
                      v_respuesta,
                      SYSDATE);

         INSERT INTO log_portal_pagos_sap (id,
                                           tipo_llamada,
                                           integracion,
                                           pade_nro_documento,
                                           dato2,
                                           tipo_integracion,
                                           dato1,
                                           msg_sap,
                                           fecha_msg)
              VALUES (id_log,
                      'S',
                      'INTLEG05(CREA Y PAGA DEUDA  SD)',
                      p_num_op,
                      p_num_op,
                      'Crea y paga deuda:',
                      p_idcliente,
                      v_json,
                      SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_ret := 'E';
            p_msg := 'error recuperando el TOKEN:' || SQLERRM;
      END;

      RETURN l_data_json;
   END int_leg05_sd_titulacion_sant;
END;