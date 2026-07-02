create or replace PROCEDURE webpay_procesa (
    tbk_orden_compra   IN VARCHAR2,
    tbk_id_sesion      IN VARCHAR2,
    tbk_id_transaccion IN VARCHAR2,
    tbk_codigo_autori  IN VARCHAR2,
    tbk_monto          IN NUMBER,
    tbk_numero_tarjeta IN VARCHAR2,
    tbk_fecha          IN VARCHAR2,
    tbk_numero_cuotas  IN NUMBER,
    tbk_tipo_pago      IN VARCHAR2,
    resultado          OUT VARCHAR2,
    p_opcion           IN VARCHAR2 DEFAULT NULL,
    p_visualiza_log    IN VARCHAR2 DEFAULT NULL
) IS
/*********************************************************************************************************/
/*  FECHA ULTIMA EDICIÓN : 28/05/2010                                                                     */
/*  DESARROLLADO POR     : EMPRESA EXTERNA DESSCO LTDA.                                                  */
/*  COMENTARIO           : ESTE PROCEDIMIENTO ES EL QUE REALIZA EL DEVENGAMIENTO Y EL PAGO               */
/*                         DE LOS SIGUIENES DOCUMENTOS (ARABA,ARAPR,AREXA,ARAPO,ESTAW) POR WEBPAY        */
/*********************************************************************************************************/

    d_tipo_pago              VARCHAR2(20);
    v_tipo_caja              NUMBER(8, 0) := 1;
    v_caja                   VARCHAR2(20);
    v_carrera                VARCHAR2(4);
    resultado_proceso        VARCHAR2(1);
    v_fecha_movimiento       DATE;
    v_codigo_error           VARCHAR2(20);
    v_mensaje_error          VARCHAR2(4000);
    v_fecha_error            DATE;
    v_mensaje_personalizado  VARCHAR2(1000);
    v_tipo_documento         VARCHAR2(20);
    v_nro_documento          VARCHAR2(1000);
    url_origen               VARCHAR2(500) := 'http://webpay.utalca.cl/exito.php';--vec_cob01.portaldepagos.get_recurso('URLORIGWEBPAY');
    v_ano_matricula          NUMBER(4) := 2023;--vec_cob01.portaldepagos.get_recurso('ANO_MATRICULA');
    pexiste                  NUMBER(3) := 0;
    v_correlativo            NUMBER;
    v_correlativo_original   NUMBER;
    v_limite_checklist       DATE;
    v_tipo_proceso           VARCHAR2(2);
    v_desc                   NUMBER;
    l_tiempo_inicio          DATE;
    l_cli_json               json;
    l_cli_json2              json;
    l_data_json              json;
    l_data_json2             json;
    l_cli_json3              json;
    l_data_json3             CLOB;
    v_ret3                   VARCHAR2(1);
    l_cli_json_data          json_list;
    l_cli_json2_list         json_list;
    pl_modulo_origen         vec_cob01.pop_pagos_detalle_temp_sap.pade_modulo_origen%TYPE;
    l_cliente_sap            cli_extranjero_pasaporte.id_sap%TYPE;
    l_pasaporte              cli_extranjero_pasaporte.pasaporte%TYPE;
    CURSOR c_deuda IS
    SELECT
        pade_tipo_documento,
        pade_ano,
        pade_nro_documento,
        pade_nro_carrera,
        pa_nro_operacion,
        pade_cuota,
        pade_moneda,
        pade_monto,
        pade_interes,
        pade_monto_pesos,
        pade_fec_vencimiento,
        pade_monto_local,
        pade_monto_local_interes,
        pa_rut,
        pa_monto_cambio_moneda,
        pade_correlativo,
        pade_modulo_origen,
        pade_prod_id,
        pade_prod_idcliente,
        pade_prod_nomcliente,
        pade_tipo_cliente,
        pade_observacion,
        pade_subprod_id,
        pade_matricula,
        nvl(pade_monto_local + pade_monto_local_interes, 0) pade_monto_local_con_interes
    FROM
        vec_cob01.pop_pagos_detalle_temp_sap
    WHERE
            pa_nro_operacion = tbk_id_sesion
        AND ROWNUM = 1
    ORDER BY
        pade_tipo_documento,
        pade_nro_documento,
        pade_cuota,
        pade_correlativo;

    p_tipo_interlocutor      VARCHAR2(1000);
    p_cli_rut                VARCHAR2(1000); -- 15112572-7
    p_cli_matricula          VARCHAR2(1000);
    p_cli_cod_carrera        VARCHAR2(1000);
    p_cli_agrupacion         VARCHAR2(1000);
    p_cli_tratamiento        VARCHAR2(1000); --fijo
    p_cli_nombres1           VARCHAR2(1000);
    p_cli_nombres2           VARCHAR2(1000);
    p_cli_cod_giro           VARCHAR2(1000);
    p_cli_sexo               VARCHAR2(1000);
    p_cli_rubro              VARCHAR2(1000);
    p_cli_direccion          VARCHAR2(1000);
    p_cli_numero             VARCHAR2(1000);
    p_cli_codigo_comuna      VARCHAR2(1000);
    p_cli_region             VARCHAR2(1000);
    p_cli_telefono           VARCHAR2(1000);
    p_cli_email              VARCHAR2(1000);
    p_cli_celular            VARCHAR2(1000);
    p_documento              VARCHAR2(1000);
    p_cli_canal_distribucion VARCHAR2(1000);
    p_es_interno             VARCHAR2(1000);
    p_es_alumno              VARCHAR2(1000);
    v_ret                    VARCHAR2(4000);
    v_msg                    VARCHAR2(5000);
    v_id_venta               NUMBER;
    v_ret2                   VARCHAR2(4000);
    v_msg2                   VARCHAR2(5000);
    pl_nro_carrera           vec_cob01.pop_pagos_detalle_temp_sap.pade_nro_carrera%TYPE;
    pl_matricula             vec_cob01.pop_pagos_detalle_temp_sap.pade_matricula%TYPE;
    v_carrera_icon           VARCHAR2(20);
    v_tipo_documento_icon    VARCHAR2(20);
    v_resp_email             BLOB;
    CURSOR c_canal IS
    SELECT DISTINCT
        lpad(spc.canal, 2, '0') AS canal_dist --se cambia p_prod.id_categoria por spc.canal para obtener canal directo desde UTSAP001 DS 07/082025
    FROM
        vec_cob01.pip_productos2             p_prod,
        vec_cob01.pop_pagos_detalle_temp_sap p_det,
        utsap001.sap_categoria_canal spc -- se agrega tabla que contiene canales asociados a categorias DS 07/082025
    WHERE
            p_det.pa_nro_operacion = tbk_id_sesion
        AND TO_CHAR(p_det.pade_prod_id) = p_prod.codigo_sap
        AND p_prod.id_categoria = spc.categoria -- se agrega condiciona para obtener canales en base a id categoria DS 07/082025
    ORDER BY
        canal_dist;

    CURSOR c_tipo_flujo IS
    SELECT DISTINCT
        pade_nro_carrera AS tipo_flujo
    FROM
        vec_cob01.pop_pagos_detalle_temp_sap
    WHERE
            pa_nro_operacion = tbk_id_sesion
        AND pa_rut = tbk_orden_compra;

BEGIN
-- rpalaciosa 11-10-2017 .
-- Log de tiempo de ejecucion

    l_tiempo_inicio := sysdate;

/***************************************************************************/
/*DETRMINAMOS EL TIPO DE PAGO (SOLO WEBPAY)                                */
/***************************************************************************/
    IF tbk_tipo_pago = 'VN' THEN
        d_tipo_pago := 'SIN CUOTAS';
    ELSIF tbk_tipo_pago = 'VC' THEN
        d_tipo_pago := 'NORMALES';
    ELSIF tbk_tipo_pago = 'SI' THEN
        d_tipo_pago := 'SIN INTERES';
    END IF;

/****************************************************************************/
/*OBTENEMOS EL DETALLE DE LOS PAGOS                                         */
/****************************************************************************/
--ENCABEZADO
    SELECT
        pa_fecha
    INTO v_fecha_movimiento
    FROM
        vec_cob01.pop_pagos_temp
    WHERE
            pa_rut = tbk_orden_compra
        AND pa_nro_operacion = tbk_id_sesion;

    BEGIN
        SELECT
            pade_nro_carrera,
            pade_matricula
        INTO
            pl_nro_carrera,
            pl_matricula
        FROM
            vec_cob01.pop_pagos_detalle_temp_sap
        WHERE
                pa_nro_operacion = tbk_id_sesion
            AND pa_rut = tbk_orden_compra
            AND ROWNUM = 1;

    EXCEPTION
        WHEN no_data_found THEN
            pl_nro_carrera := NULL;
            pl_matricula := NULL;
    END;

--DETALLE
    v_correlativo_original := 1;
    resultado_proceso := 'S';
    FOR reg IN c_deuda LOOP
/***************************************************************************/
/* PROCESAMOS CADA UNO DE LOS PAGOS ASOCIADOS                              */
/***************************************************************************/
        v_tipo_documento := reg.pade_tipo_documento;
        v_nro_documento := reg.pade_nro_documento;
        pl_modulo_origen := reg.pade_modulo_origen;
        v_carrera_icon := utsap001.pkg_recursos.recupera_codigo_icon(2, 1, NULL, reg.pade_nro_carrera);

        v_tipo_documento_icon := utsap001.pkg_recursos.recupera_codigo_icon(2, 2, NULL, v_tipo_documento);
    ------------------------------
    --OTROS ALUMNOS
    ------------------------------
        v_caja := 'CAJA-WEBPAY';
        BEGIN
            IF pl_modulo_origen IN ( 'PORTALCERTIFICADOS', 'PORTALTITULACION', 'PORTALMATRICULA', 'PORTALSUBPRODUCTOS' ) THEN
        --CREACION DE CLIENTE
                BEGIN
                    IF pl_modulo_origen = 'PORTALSUBPRODUCTOS' THEN
                        BEGIN
                            SELECT
                                '0001'                                                                      tipo_interlocutor,
                                alu_rut_n
                                || '-'
                                || alu_rut_v                                                                cli_rut,
                                pl_matricula                                                                nro_matricula,
                                pl_nro_carrera                                                              cli_cod_carrera,
                                'ZC01'                                                                      cli_agrupacion,
                                decode(alu_sexo, 'M', '0002', '0001')                                       cli_tratamiento,
                                alu_nombres,
                                alu_paterno
                                || ' '
                                || alu_materno                                                              cli_apellidos,
                                ''                                                                          cli_cod_giro,
                                decode(alu_sexo, 'M', '2', '1')                                             cli_sexo,
                                ''                                                                          cli_rubro,
                                alu_dir_origen,
                                ''                                                                          cli_direccion_numero,
                                utsap001.pkg_recursos.recupera_codigo_sap(1, 10, '', alu_comuna_origen_alu) cli_comuna,
                                utsap001.pkg_recursos.recupera_codigo_sap(1, 9, '', alu_localidad_origen)   cli_region,
                                alu_fono_origen                                                             cli_telefono,
                                NULL                                                                        post_email,
                                NULL                                                                        post_celular,
                                11                                                                          cli_canal_distribucion
                            INTO
                                p_tipo_interlocutor,
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
                            FROM
                                vac_estruc.alumno
                            WHERE
                                    alu_rut_n = tbk_orden_compra
                                AND ROWNUM = 1;

                        EXCEPTION
                            WHEN OTHERS THEN
                                SELECT
                                    '0001'                            tipo_interlocutor,
                                    rut
                                    || '-'
                                    || utalca.calcula_digito(rut)     cli_rut,
                                    rut                               nro_matricula,
                                    'SD'                              cli_cod_carrera,
                                    'ZC01'                            cli_agrupacion,
                                    decode(nvl(sexo, 'M'),
                                           'M',
                                           '0002',
                                           '0001')                    cli_tratamiento,
                                    upper(nombres)                    alu_nombres,
                                    upper(ap_paterno
                                          || ' '
                                          || ap_materno)                    cli_apellidos,
                                    ''                                cli_cod_giro,
                                    decode(nvl(sexo, 'M'),
                                           'M',
                                           '2',
                                           '1')                       cli_sexo,
                                    ''                                cli_rubro,
                                    nvl(direccion, '1 PONIENTE 1141') alu_dir_origen,
                                    ''                                cli_direccion_numero,
                                    utsap001.pkg_recursos.recupera_codigo_sap(1,
                                                                              3,
                                                                              '',
                                                                              nvl(comuna, '001104'))   cli_comuna,
                                    utsap001.pkg_recursos.recupera_codigo_sap(1,
                                                                              8,
                                                                              '',
                                                                              nvl(region, '7'))        cli_region,
                                    ''                                cli_telefono,
                                    email                             post_email,
                                    ''                                post_celular,
                                    11                                cli_canal_distribucion
                                INTO
                                    p_tipo_interlocutor,
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
                                FROM
                                    vec_cob01.pop_productos_habilita
                                WHERE
                                    rut = tbk_orden_compra;

                        END;

                        p_cli_canal_distribucion := 16;
                        p_cli_matricula := tbk_orden_compra;
                    ELSE
                        SELECT
                            '0001'                                                                      tipo_interlocutor,
                            alu_rut_n
                            || '-'
                            || alu_rut_v                                                                cli_rut,
                            pl_matricula                                                                nro_matricula,
                            pl_nro_carrera                                                              cli_cod_carrera,
                            'ZC01'                                                                      cli_agrupacion,
                            decode(alu_sexo, 'M', '0002', '0001')                                       cli_tratamiento,
                            alu_nombres,
                            alu_paterno
                            || ' '
                            || alu_materno                                                              cli_apellidos,
                            ''                                                                          cli_cod_giro,
                            decode(alu_sexo, 'M', '2', '1')                                             cli_sexo,
                            ''                                                                          cli_rubro,
                            alu_dir_origen,
                            ''                                                                          cli_direccion_numero,
                            utsap001.pkg_recursos.recupera_codigo_sap(1, 10, '', alu_comuna_origen_alu) cli_comuna,
                            utsap001.pkg_recursos.recupera_codigo_sap(1, 9, '', alu_localidad_origen)   cli_region,
                            alu_fono_origen                                                             cli_telefono,
                            NULL                                                                        post_email,
                            NULL                                                                        post_celular,
                            11                                                                          cli_canal_distribucion
                        INTO
                            p_tipo_interlocutor,
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
                        FROM
                            vac_estruc.alumno
                        WHERE
                                alu_rut_n = tbk_orden_compra
                            AND ROWNUM = 1;

                        p_cli_canal_distribucion := 11;
                    END IF;
             --CREAMOS EL CLIENTE
             /*llama a la función int_leg04_json*/
                    BEGIN
                        l_cli_json2 := utsap001.pkg_integra_utal.int_leg04_json(p_tipo_interlocutor, p_cli_rut, 'D000', p_cli_matricula
                        , p_cli_cod_carrera,
                                                                               p_cli_agrupacion, p_cli_tratamiento, p_cli_nombres1, p_cli_nombres2
                                                                               , p_cli_cod_giro,
                                                                               p_cli_sexo, p_cli_rubro, p_cli_direccion, p_cli_numero
                                                                               , p_cli_codigo_comuna,
                                                                               p_cli_region, p_cli_telefono, p_cli_celular, p_cli_email
                                                                               , p_cli_canal_distribucion,
                                                                               v_ret, v_msg);

                        l_data_json2 :=
                            JSON(
                                l_cli_json2.get('data')
                            );
                        v_ret2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'TYPE');
                        v_msg2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'MESSAGE');
                --REGISTRAMOS EL LOG DE LA CREACION
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_codigo_error := sqlcode;
                            v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                            v_fecha_error := sysdate;
                            INSERT INTO log_error (
                                correlativo,
                                codigo_error,
                                mensaje_error,
                                fecha,
                                mensaje_personalizado
                            ) VALUES (
                                seq_error.NEXTVAL,
                                v_codigo_error,
                                v_mensaje_error,
                                v_fecha_error,
                                '*'
                            );

                            COMMIT;

                --- almacena Json
                            INSERT INTO log_error_json (
                                correlativo,
                                codigo_error,
                                mensaje_error,
                                fecha,
                                mensaje_personalizado,
                                data_json
                            ) VALUES (
                                seq_error.NEXTVAL,
                                v_codigo_error,
                                v_mensaje_error,
                                v_fecha_error,
                                '*',
                                to_clob(substr(l_cli_json2.get('data').get_string,
                                               1,
                                               32000))
                            );

                            COMMIT;
                            INSERT INTO log_crea_cliente (
                                tipo_interlocutor,
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
                                post_celular
                            ) VALUES (
                                p_tipo_interlocutor,
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
                                p_cli_email,
                                p_cli_celular
                            );

                    END;

                    BEGIN
                        INSERT INTO log_crea_cliente (
                            tipo_interlocutor,
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
                            post_celular
                        ) VALUES (
                            p_tipo_interlocutor,
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
                            p_cli_email,
                            p_cli_celular
                        );

                    EXCEPTION
                        WHEN OTHERS THEN
                            v_mensaje_personalizado := 'FALLO EN LOG DE CLIENTE, DATOS'
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
                                                       || p_cli_email
                                                       || ','
                                                       || p_cli_celular;

                            v_codigo_error := sqlcode;
                            v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                            v_fecha_error := sysdate;
                            INSERT INTO log_error (
                                correlativo,
                                codigo_error,
                                mensaje_error,
                                fecha,
                                mensaje_personalizado
                            ) VALUES (
                                seq_error.NEXTVAL,
                                v_codigo_error,
                                v_mensaje_error,
                                v_fecha_error,
                                v_mensaje_personalizado
                            );

                            COMMIT;
                    END;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm
                                           || dbms_utility.format_error_backtrace
                                           || '-'
                                           || tbk_orden_compra
                                           || '-'
                                           || tbk_id_sesion;

                        v_fecha_error := sysdate;
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            '*'
                        );

                        COMMIT;
                END;
            END IF;

            IF pl_modulo_origen IN ( 'PORTALVENTA' ) THEN
    --CREACION DE CLIENTE
                SELECT
                    '0001'                                                           tipo_interlocutor,
                    clie_rut
                    || '-'
                    || clie_dv                                                       cli_rut,
                    clie_rut                                                         nro_matricula,
                    'SD'                                                             cli_cod_carrera,
                    'ZC01'                                                           cli_agrupacion,
                    decode(decode(clie_interlocutor, 2, 'F', 'M'),
                           'M',
                           '0002',
                           '0001')                                                   cli_tratamiento,
                    clie_nombre_pila                                                 alu_nombres,
                    clie_apellido_paterno
                    || ' '
                    || clie_apellido_materno                                         cli_apellidos,
                    ''                                                               cli_cod_giro,
                    decode(decode(clie_interlocutor, 2, 'F', 'M'),
                           'M',
                           '2',
                           '1')                                                      cli_sexo,
                    ''                                                               cli_rubro,
                    clie_direccion                                                   alu_dir_origen,
                    ''                                                               cli_direccion_numero,
                    utsap001.pkg_recursos.recupera_codigo_sap(1, 3, '', '001104')    cli_comuna,
                    utsap001.pkg_recursos.recupera_codigo_sap(1, 8, '', regi_codigo) cli_region,
                    clie_tel_contacto                                                cli_telefono,
                    clie_email                                                       post_email,
                    NULL                                                             post_celular,
                    '03'                                                             cli_canal_distribucion
                INTO
                    p_tipo_interlocutor,
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
                FROM
                    vec_cob03.pove_cliente
                WHERE
                        clie_rut = tbk_orden_compra
                    AND ROWNUM = 1;

       --CREAMOS EL CLIENTE
       /*llama a la función int_leg04_json*/
                BEGIN
                    l_cli_json2 := utsap001.pkg_integra_utal.int_leg04_json(p_tipo_interlocutor, p_cli_rut, 'D000', p_cli_matricula, p_cli_cod_carrera
                    ,
                                                                           p_cli_agrupacion, p_cli_tratamiento, p_cli_nombres1, p_cli_nombres2
                                                                           , p_cli_cod_giro,
                                                                           p_cli_sexo, p_cli_rubro, p_cli_direccion, p_cli_numero, p_cli_codigo_comuna
                                                                           ,
                                                                           p_cli_region, p_cli_telefono, p_cli_celular, p_cli_email, p_cli_canal_distribucion
                                                                           ,
                                                                           v_ret, v_msg);

                    l_data_json2 :=
                        JSON(
                            l_cli_json2.get('data')
                        );
                    v_ret2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'TYPE');
                    v_msg2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'MESSAGE');
                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        v_mensaje_personalizado := 'FALLO EN LLAMADA CREA CLIENTE'
                                                   || p_tipo_interlocutor
                                                   || p_cli_rut
                                                   || p_cli_matricula
                                                   || p_cli_cod_carrera
                                                   || p_cli_agrupacion
                                                   || p_cli_tratamiento
                                                   || p_cli_nombres1
                                                   || p_cli_nombres2
                                                   || p_cli_cod_giro
                                                   || p_cli_sexo
                                                   || p_cli_rubro
                                                   || p_cli_direccion
                                                   || p_cli_numero
                                                   || p_cli_codigo_comuna
                                                   || p_cli_region
                                                   || p_cli_telefono
                                                   || p_cli_email
                                                   || p_cli_celular
                                                   || p_cli_canal_distribucion;

                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;
       --REGISTRAMOS EL LOG DE LA CREACION

                BEGIN
                    INSERT INTO log_crea_cliente (
                        tipo_interlocutor,
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
                        post_celular
                    ) VALUES (
                        p_tipo_interlocutor,
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
                        p_cli_email,
                        p_cli_celular
                    );

                EXCEPTION
                    WHEN OTHERS THEN
                        v_mensaje_personalizado := 'FALLO EN LOG DE CLIENTE, DATOS'
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
                                                   || p_cli_email
                                                   || ','
                                                   || p_cli_celular;

                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;

            END IF;

            IF pl_modulo_origen IN ( 'PORTALPRODUCTOS' ) THEN
    --CREACION DE CLIENTE, SI NO ES EXTRANJERO
                IF reg.pade_tipo_cliente IN ( 'R', 'P' ) THEN
                    SELECT
                        '0001'                                                        tipo_interlocutor,
                        replace(a.rut, '.', '')                                       cli_rut,
                        substr(replace(a.rut, '.', ''),
                               1,
                               length(replace(a.rut, '.', '')) - 2)                   nro_matricula,
                        'SD'                                                          cli_cod_carrera,
                        'ZC01'                                                        cli_agrupacion,
                        decode(a.sexo, 'M', '0002', '0001')                           cli_tratamiento,
                        a.nombre                                                      alu_nombres,
                        a.apellidos                                                   cli_apellidos,
                        ''                                                            cli_cod_giro,
                        decode(a.sexo, 'M', '2', '1')                                 cli_sexo,
                        ''                                                            cli_rubro,
                        a.direccion                                                   alu_dir_origen,
                        ''                                                            cli_direccion_numero,
                        (
                            SELECT
                                b.ciud_descripcion
                            FROM
                                vec_cob01.pop_ciudad b
                            WHERE
                                b.ciud_codigo = a.comuna
                        )                                                             cli_comuna,
                        utsap001.pkg_recursos.recupera_codigo_sap(1, 9, '', a.region) AS cli_region,
                        a.celular                                                     cli_telefono,
                        a.email                                                       post_email,
                        NULL                                                          post_celular,
                        '16'                                                          cli_canal_distribucion,
                        pasaporte
                    INTO
                        p_tipo_interlocutor,
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
                        p_cli_canal_distribucion,
                        l_pasaporte
                    FROM
                        vec_cob01.pop_clientes_congresos a
                    WHERE
                            id = reg.pade_nro_documento
                        AND ROWNUM = 1;

           --CREAMOS EL CLIENTE
           /*llama a la función int_leg04_json*/
                    IF reg.pade_tipo_cliente IN ( 'R' ) THEN
                        BEGIN
                            l_cli_json2 := utsap001.pkg_integra_utal.int_leg04_json(p_tipo_interlocutor, p_cli_rut, 'D000', p_cli_matricula
                            , p_cli_cod_carrera,
                                                                                   p_cli_agrupacion, p_cli_tratamiento, p_cli_nombres1
                                                                                   , p_cli_nombres2, p_cli_cod_giro,
                                                                                   p_cli_sexo, p_cli_rubro, p_cli_direccion, p_cli_numero
                                                                                   , p_cli_codigo_comuna,
                                                                                   p_cli_region, p_cli_telefono, p_cli_celular, p_cli_email
                                                                                   , p_cli_canal_distribucion,
                                                                                   v_ret, v_msg);

                            l_data_json2 :=
                                JSON(
                                    l_cli_json2.get('data')
                                );
                            v_ret2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'TYPE');
                            v_msg2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'MESSAGE');
                        EXCEPTION
                            WHEN OTHERS THEN
                                v_codigo_error := sqlcode;
                                v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                                v_fecha_error := sysdate;
                                v_mensaje_personalizado := 'FALLO EN LLAMADA CREA CLIENTE'
                                                           || p_tipo_interlocutor
                                                           || p_cli_rut
                                                           || p_cli_matricula
                                                           || p_cli_cod_carrera
                                                           || p_cli_agrupacion
                                                           || p_cli_tratamiento
                                                           || p_cli_nombres1
                                                           || p_cli_nombres2
                                                           || p_cli_cod_giro
                                                           || p_cli_sexo
                                                           || p_cli_rubro
                                                           || p_cli_direccion
                                                           || p_cli_numero
                                                           || p_cli_codigo_comuna
                                                           || p_cli_region
                                                           || p_cli_telefono
                                                           || p_cli_email
                                                           || p_cli_celular
                                                           || p_cli_canal_distribucion;

                                INSERT INTO log_error (
                                    correlativo,
                                    codigo_error,
                                    mensaje_error,
                                    fecha,
                                    mensaje_personalizado
                                ) VALUES (
                                    seq_error.NEXTVAL,
                                    v_codigo_error,
                                    v_mensaje_error,
                                    v_fecha_error,
                                    v_mensaje_personalizado
                                );

                                COMMIT;
                        END;

                    ELSE
                    --- valida que el pasaporte no esté ingresado previamente.
                        IF cli_extranjero_pasaporte_pkg.id_sap(l_pasaporte) IS NULL THEN
                            BEGIN
                                p_cli_rut := '55555555-5';
                                p_cli_matricula := '5555';
                                p_cli_rubro := l_pasaporte;
                                l_cli_json := utsap001.pkg_integra_utal.int_leg04_json_interfaces_ex(p_tipo_interlocutor, p_cli_rut, 'D000'
                                , p_cli_matricula, p_cli_cod_carrera,
                                                                                                    'ZC02', p_cli_tratamiento, p_cli_nombres1
                                                                                                    , p_cli_nombres2, NULL,
                                                                                                    NULL, p_cli_cod_giro, p_cli_sexo,
                                                                                                    p_cli_rubro, p_cli_direccion,
                                                                                                    p_cli_numero, p_cli_codigo_comuna
                                                                                                    , p_cli_region, p_cli_telefono, p_cli_celular
                                                                                                    ,
                                                                                                    p_cli_email, p_cli_canal_distribucion
                                                                                                    , v_ret, v_msg);

                                l_cli_json2_list := json_list(l_cli_json.get('data'));
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_data_json2 :=
                                        JSON(
                                            l_cli_json.get('data')
                                        );
                            END;

                            IF l_cli_json2_list IS NOT NULL THEN
                                FOR i IN 1..l_cli_json2_list.count LOOP
                                    v_ret := utsap001.pkg_integra_utal.lee_json(
                                                                               JSON(
                                                                                   l_cli_json2_list.get(i)
                                                                               ), 'TYPE');

                                    v_msg := v_msg
                                             || ' '
                                             || utsap001.pkg_integra_utal.lee_json(
                                                                                  JSON(
                                                                                      l_cli_json2_list.get(i)
                                                                                  ), 'MESSAGE');

                                    IF v_ret = 'S' THEN
                                        l_cliente_sap := utsap001.pkg_integra_utal.lee_json(
                                                                                           JSON(
                                                                                               l_cli_json2_list.get(i)
                                                                                           ), 'MESSAGE_V2');
                                    END IF;

                                END LOOP;

                            ELSE
                                v_ret := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'TYPE');
                                v_msg := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'MESSAGE');
                                IF v_ret = 'S' THEN
                                    l_cliente_sap := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'MESSAGE_V2');
                                END IF;

                            END IF;

                        ---- aca se registra el codigo cliente / pasaporte  xxxxxx
                            IF l_cliente_sap IS NOT NULL THEN
                                INSERT INTO cli_extranjero_pasaporte (
                                    id_sap,
                                    pasaporte
                                ) VALUES (
                                    l_cliente_sap,
                                    l_pasaporte
                                );

                            END IF;

                        END IF;
                    END IF;

           --REGISTRAMOS EL LOG DE LA CREACION

                    BEGIN
                        INSERT INTO log_crea_cliente (
                            tipo_interlocutor,
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
                            post_celular
                        ) VALUES (
                            p_tipo_interlocutor,
                            nvl(p_cli_rut, 0),
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
                            p_cli_celular
                        );

                    EXCEPTION
                        WHEN OTHERS THEN
                            v_mensaje_personalizado := 'FALLO EN LOG DE CLIENTE, DATOS'
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
                                                       || p_cli_email
                                                       || ','
                                                       || p_cli_celular;

                            v_codigo_error := sqlcode;
                            v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                            v_fecha_error := sysdate;
                            INSERT INTO log_error (
                                correlativo,
                                codigo_error,
                                mensaje_error,
                                fecha,
                                mensaje_personalizado
                            ) VALUES (
                                seq_error.NEXTVAL,
                                v_codigo_error,
                                v_mensaje_error,
                                v_fecha_error,
                                v_mensaje_personalizado
                            );

                            COMMIT;
                    END;

                END IF;
            END IF;

            IF pl_modulo_origen IN ( 'PORTALCERTIFICADOS' ) THEN
                l_cli_json := utsap001.pkg_integra_utal.int_leg05_fica_portal_sap(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg);
            ELSIF pl_modulo_origen IN ( 'PORTALTITULACION' ) THEN
                l_cli_json := utsap001.pkg_integra_utal.int_leg05_sd_titulacion(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg);
        --AVANZAMOS EL WF DE TITULACION
                ractit01.avanzar_pago_wf_titulacion_id(v_nro_documento, tbk_id_sesion);
            ELSIF pl_modulo_origen IN ( 'PORTALPAGOS', 'PORTAL2' ) THEN
                l_cli_json := utsap001.pkg_integra_utal.int_leg02_portal_sap(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg);
            ELSIF pl_modulo_origen IN ( 'PORTALMATRICULA' ) THEN
                BEGIN
                    l_cli_json := utsap001.pkg_integra_utal.int_leg05_fica_matricula_sap(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg
                    );
                EXCEPTION
                    WHEN OTHERS THEN
                        resultado_proceso := 'P';
                END;

                v_desc := sdi_sgc.obtiene_descuento_decil(tbk_orden_compra, to_char(sysdate, 'YYYY'));
                IF v_desc > 0 THEN
                    --l_cli_json3 := utsap001.pkg_integra_utal.int_crea_descuento_preg(tbk_orden_compra, v_desc, reg.pade_nro_carrera
                    --, reg.pade_matricula, v_ret3,
                    --                                                                    l_data_json3);
                    l_cli_json3 := utsap001.pkg_integra_utal.int_crea_descuento_preg(
                                                                                                    tbk_orden_compra,
                                                                                                    v_desc,
                                                                                                    reg.pade_nro_carrera,
                                                                                                    reg.pade_matricula,
                                                                                                    v_ret3,
                                                                                                    l_data_json3
                                               );
                END IF;

            ELSIF pl_modulo_origen IN ( 'PORTALPRODUCTOS' ) THEN
                BEGIN
        --l_cli_json := UTSAP001.pkg_integra_utal.int_leg05_SD_VENTA3(TBK_ORDEN_COMPRA, TBK_ID_SESION,v_ret,v_msg);
                    l_cli_json := utsap001.pkg_integra_utal.int_leg05_portal_seminarios(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg
                    );
                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        v_mensaje_personalizado := 'FALLO EN LLAMADA CREA Y PAGA';
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;
      /* BEGIN
         v_correlativo:=SEQ_POP_VTA_SUBPROD.NEXTVAL;
         insert into vec_cob01.pop_pagos_subproductos
         (pasubprd_correlativo, pasubprd_nro_operacion, pasubprd_rut_icon,PASUBPRD_FECHA) values
         (v_correlativo, TBK_ID_SESION, TBK_ORDEN_COMPRA,sysdate);
         commit;
         V_RESP_EMAIL:=get_url_file('http://portaldepagos.utalca.cl/portalsubproductos/envio_correo_vinculo.php?id_vta_subprod='||v_correlativo||'&orden_compra='||TBK_ID_SESION);
       EXCEPTION
       WHEN OTHERS THEN
            NULL;
       END;*/

            ELSIF pl_modulo_origen IN ( 'PORTALSUBPRODUCTOS' ) THEN
                BEGIN
                    l_cli_json := utsap001.pkg_integra_utal.int_leg05_sd_venta2(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg);
                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        v_mensaje_personalizado := 'FALLO EN LLAMADA CREA Y PAGA';
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;

                BEGIN
                    v_correlativo := seq_pop_vta_subprod.nextval;
                    INSERT INTO vec_cob01.pop_pagos_subproductos (
                        pasubprd_correlativo,
                        pasubprd_nro_operacion,
                        pasubprd_rut_icon,
                        pasubprd_fecha
                    ) VALUES (
                        v_correlativo,
                        tbk_id_sesion,
                        tbk_orden_compra,
                        sysdate
                    );

                    COMMIT;
                    v_resp_email := get_url_file('http://portaldepagos.utalca.cl/portalsubproductos/envio_correo_vinculo.php?id_vta_subprod='
                                                 || v_correlativo
                                                 || '&orden_compra='
                                                 || tbk_id_sesion);
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;

            /* JV: Inicio PORTALPREVENTAS */
            ELSIF pl_modulo_origen IN ( 'PORTALPREVENTAS' ) THEN
                SELECT
                    COUNT(*)
                INTO p_es_interno
                FROM
                    utsap001.rem_ficha_sap
                WHERE
                    rol_emp = tbk_orden_compra;

                SELECT
                    COUNT(*)
                INTO p_es_alumno
                FROM
                    vac_estruc.alumno
                WHERE
                    alu_rut_n = tbk_orden_compra;

                IF
                    p_es_interno = 0
                    AND p_es_alumno = 0
                THEN
                    /* Inicio creación de usuario externo */

                    SELECT
                        '0001'                               AS tipo_interlocutor,
                        codigo_cli
                        || '-'
                        || utalca.calcula_digito(codigo_cli) AS cli_rut,
                        codigo_cli                           AS nro_matricula,
                        'SD'                                 AS cli_cod_carrera,
                        'ZC01'                               AS cli_agrupacion, /* ZC01 nacional */
                        decode(sexo, 'M', '0002', 'O', '0002',
                               'F', '0001')                  AS cli_tratamiento,
                        nombre                               AS cli_nombres,
                        apellido                             AS cli_apellidos,
                        ''                                   AS cli_cod_giro,
                        decode(sexo, 'M', '2', 'O', '2',
                               'F', '1')                     AS cli_sexo,
                        ''                                   AS cli_rubro,
                        direccion                            AS cli_direccion,
                        numero                               AS cli_numero,
                        comuna                               AS cli_comuna,
                        region                               AS cli_region,
                        telefono                             AS cli_telefono,
                        correo                               AS cli_email,
                        ''                                   AS post_celular
                    INTO
                        p_tipo_interlocutor,
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
                        p_cli_celular
                    FROM
                        vec_cob01.pip_clientes
                    WHERE
                            codigo_cli = tbk_orden_compra
                        AND ROWNUM = 1;
                /* Inicio crear cliente funcionario */
                ELSIF
                    p_es_interno = 1
                    AND p_es_alumno = 0
                THEN
                    SELECT
                        '0001'                            AS tipo_interlocutor,
                        rol_emp
                        || '-'
                        || utalca.calcula_digito(rol_emp) AS cli_rut,
                        rol_emp                           AS nro_matricula,
                        'SD'                              AS cli_cod_carrera,
                        'ZC01'                            AS cli_agrupacion, /* ZC01 nacional */
                        decode(sexo, 'M', '0002', '0001') AS cli_tratamiento,
                        nombre_pila                       AS cli_nombres,
                        apellido_paterno
                        || ' '
                        || apellido_materno               AS cli_apellidos,
                        ''                                AS cli_cod_giro,
                        decode(nvl(sexo, 'M'),
                               'M',
                               '2',
                               '1')                       AS cli_sexo,
                        ''                                AS cli_rubro,
                        domicilio_calle                   AS cli_direccion,
                        domicilio_numero                  AS cli_numero,
                        (
                            SELECT DISTINCT
                                rec_nombre_sap
                            FROM
                                utsap001.conf_recursos b
                            WHERE
                                    b.rec_recurso = 'COMUNAS'
                                AND b.rec_codigo_sap = ficha.domicilio_comuna
                        )                                 AS cli_comuna,
                        coalesce((
                            SELECT DISTINCT
                                lpad(a.region, 2, '0')
                            FROM
                                vac_estruc.t_comunas2  a,
                                utsap001.conf_recursos b
                            WHERE
                                    b.rec_recurso = 'COMUNAS'
                                AND nlssort(upper(b.rec_nombre_sap),
                                            'NLS_SORT = BINARY_AI') = nlssort(upper(a.nombre),
                                                                              'NLS_SORT = BINARY_AI')
                                AND b.rec_codigo_sap = ficha.domicilio_comuna
                        ),
                                 (
                            SELECT DISTINCT
                                lpad(a.tco_region, 2, '0')
                            FROM
                                vac_estruc.t_comuna    a,
                                utsap001.conf_recursos b
                            WHERE
                                    b.rec_recurso = 'COMUNAS'
                                AND nlssort(upper(b.rec_nombre_sap),
                                            'NLS_SORT = BINARY_AI') = nlssort(upper(a.tco_descripcion),
                                                                              'NLS_SORT = BINARY_AI')
                                AND b.rec_codigo_sap = ficha.domicilio_comuna
                        ),
                                 (
                            SELECT DISTINCT
                                lpad(a.cr, 2, '0')
                            FROM
                                vac_estruc.t_comuna_3k a,
                                utsap001.conf_recursos b
                            WHERE
                                    b.rec_recurso = 'COMUNAS'
                                AND nlssort(upper(b.rec_nombre_sap),
                                            'NLS_SORT = BINARY_AI') = nlssort(upper(a.com_nombre),
                                                                              'NLS_SORT = BINARY_AI')
                                AND b.rec_codigo_sap = ficha.domicilio_comuna
                        ))                                AS cli_region,
                        domicilio_telefono                AS cli_telefono,
                        email                             AS cli_email,
                        ''                                AS post_celular
                    INTO
                        p_tipo_interlocutor,
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
                        p_cli_celular
                    FROM
                        (
                            SELECT
                                *
                            FROM
                                utsap001.rem_ficha_sap
                            WHERE
                                    rol_emp = tbk_orden_compra
                                AND ROWNUM = 1
                            ORDER BY
                                id_persona DESC
                        ) ficha;
                    
                    /* Fin crear cliente funcionario */

                ELSIF
                    p_es_interno = 0
                    AND p_es_alumno = 1
                THEN
                    /*Inicio crear cliente alumno */
                    SELECT
                        '0001'                                AS tipo_interlocutor,
                        alu_rut_n
                        || '-'
                        || utalca.calcula_digito(alu_rut_n)   AS cli_rut,
                        alu_rut_n                             AS nro_matricula,
                        'SD'                                  AS cli_cod_carrera,
                        'ZC01'                                AS cli_agrupacion, /* ZC01 nacional */
                        decode(alu_sexo, 'M', '0002', '0001') AS cli_tratamiento,
                        alu_nombres                           AS cli_nombres,
                        alu_paterno
                        || ' '
                        || alu_materno                        AS cli_apellidos,
                        ''                                    AS cli_cod_giro,
                        decode(nvl(alu_sexo, 'M'),
                               'M',
                               '2',
                               '1')                           AS cli_sexo,
                        ''                                    AS cli_rubro,
                        alu_dir_origen                        AS cli_direccion,
                        1                                     AS cli_numero,
                        alumno_pkg.sel_comuna(alu_rut_n)      AS cli_comuna, /* CONFIRMAR SELECT */
                        0 || alumno_pkg.sel_region(alu_rut_n) AS region,
                        alu_fono_origen                       AS cli_telefono,
                        --u_online.ldap_mail(alu_rut_n)         AS cli_email, /* Solicitar acceso */
                        ''                                    AS cli_email,
                        ''                                    AS post_celular
                    INTO
                        p_tipo_interlocutor,
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
                        p_cli_celular
                    FROM
                        (
                            SELECT
                                *
                            FROM
                                vac_estruc.alumno a
                            WHERE
                                alu_rut_n = tbk_orden_compra
                            ORDER BY
                                alu_rut_n DESC
                        )
                    WHERE
                        ROWNUM = 1;

                END IF;
                /*Fin crear cliente alumno */

                BEGIN
                    FOR loop_tipo_flujo IN c_tipo_flujo LOOP
                        IF ( loop_tipo_flujo.tipo_flujo = 'FI' ) THEN
                            l_cli_json2 := utsap001.pkg_integra_utal.int_leg04_json(p_tipo_interlocutor, p_cli_rut, 'D000', p_cli_matricula
                            , p_cli_cod_carrera,
                                                                                   p_cli_agrupacion, p_cli_tratamiento, p_cli_nombres1
                                                                                   , p_cli_nombres2, p_cli_cod_giro,
                                                                                   p_cli_sexo, p_cli_rubro, p_cli_direccion, p_cli_numero
                                                                                   , p_cli_codigo_comuna,
                                                                                   p_cli_region, p_cli_telefono, p_cli_celular, p_cli_email
                                                                                   , '14',
                                                                                   v_ret, v_msg);
                        ELSE
                            FOR loop_canal IN c_canal LOOP
                                l_cli_json2 := utsap001.pkg_integra_utal.int_leg04_json(p_tipo_interlocutor, p_cli_rut, 'D000', p_cli_matricula
                                , p_cli_cod_carrera,
                                                                                       p_cli_agrupacion, p_cli_tratamiento, p_cli_nombres1
                                                                                       , p_cli_nombres2, p_cli_cod_giro,
                                                                                       p_cli_sexo, p_cli_rubro, p_cli_direccion, p_cli_numero
                                                                                       , p_cli_codigo_comuna,
                                                                                       p_cli_region, p_cli_telefono, p_cli_celular, p_cli_email
                                                                                       , loop_canal.canal_dist,
                                                                                       v_ret, v_msg);
                            END LOOP;
                        END IF;
                        
                        /* 07-03-2025 No es necesario y no se utilizan variables
                        l_data_json2 :=
                            JSON(
                                l_cli_json2.get('data')
                            );
                        v_ret2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'TYPE');
                        v_msg2 := utsap001.pkg_integra_utal.lee_json(l_data_json2, 'MESSAGE');
                        */
                    END LOOP;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        v_mensaje_personalizado := 'FALLO EN LLAMADA CREA CLIENTE'
                                                   || p_tipo_interlocutor
                                                   || p_cli_rut
                                                   || p_cli_matricula
                                                   || p_cli_cod_carrera
                                                   || p_cli_agrupacion
                                                   || p_cli_tratamiento
                                                   || p_cli_nombres1
                                                   || p_cli_nombres2
                                                   || p_cli_cod_giro
                                                   || p_cli_sexo
                                                   || p_cli_rubro
                                                   || p_cli_direccion
                                                   || p_cli_numero
                                                   || p_cli_codigo_comuna
                                                   || p_cli_region
                                                   || p_cli_telefono
                                                   || p_cli_email
                                                   || p_cli_celular
                                                   || p_cli_canal_distribucion;

                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;

                BEGIN
                    INSERT INTO log_crea_cliente (
                        tipo_interlocutor,
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
                        post_celular
                    ) VALUES (
                        p_tipo_interlocutor,
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
                        p_cli_email,
                        p_cli_celular
                    );

                EXCEPTION
                    WHEN OTHERS THEN
                        v_mensaje_personalizado := 'FALLO EN LOG DE CLIENTE, DATOS'
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
                                                   || p_cli_email
                                                   || ','
                                                   || p_cli_celular;

                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;
                    /* Fin creación de usuario */
                

                

                /* JV: CONDICIONES PREVIAS AL 27 DE NOV 2024 
                IF ( pl_nro_carrera <> 'SD' ) THEN --cambio de dato de entrada, ahora lo lee desde la tabla pop_pagos_detalles_temp_sap, 16-10-2024
                    l_cli_json := utsap001.pkg_integra_utal.int_leg02_portal_sap(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg);
                ELSE
                    BEGIN
                        l_cli_json := utsap001.pkg_integra_utal.int_leg05_sd_portal_integral(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg
                        ); --tbk_orden_compra sería RUT (p_idcliente), tbk_id_sesión sería cupón (p_num_op)
                */

                FOR loop_tipo_flujo IN c_tipo_flujo LOOP
                    IF ( loop_tipo_flujo.tipo_flujo = 'FI' ) THEN
                        l_cli_json := utsap001.pkg_integra_utal.int_leg05_fica_portal_integral(tbk_orden_compra, tbk_id_sesion, v_ret
                        , v_msg);
                    ELSIF ( loop_tipo_flujo.tipo_flujo = 'SD' ) THEN --cambio de dato de entrada, ahora lo lee desde la tabla pop_pagos_detalles_temp_sap, 16-10-2024
                        l_cli_json := utsap001.pkg_integra_utal.int_leg05_sd_portal_integral(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg
                        ); --tbk_orden_compra sería RUT (p_idcliente), tbk_id_sesión sería cupón (p_num_op)                    
                    ELSE
                        BEGIN
                            l_cli_json := utsap001.pkg_integra_utal.int_leg02_portal_sap(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg
                            );
                        EXCEPTION
                            WHEN OTHERS THEN
                                v_codigo_error := sqlcode;
                                v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                                v_fecha_error := sysdate;
                                v_mensaje_personalizado := 'FALLO EN PORTALPREVENTAS';
                                INSERT INTO log_error (
                                    correlativo,
                                    codigo_error,
                                    mensaje_error,
                                    fecha,
                                    mensaje_personalizado
                                ) VALUES (
                                    seq_error.NEXTVAL,
                                    v_codigo_error,
                                    v_mensaje_error,
                                    v_fecha_error,
                                    v_mensaje_personalizado
                                );

                                COMMIT;
                                IF nvl(p_visualiza_log, 'N') = 'S' THEN
                                    htp.p(v_mensaje_error
                                          || ':'
                                          || nvl(v_mensaje_personalizado, '')
                                          || '<BR>');
                                END IF;

                        END; --exception
                    END IF; --cierra if ( p_opcion = 'SP' ) then
                END LOOP;
                /* JV: Fin PORTALPREVENTAS */

            ELSIF pl_modulo_origen IN ( 'PORTALVENTA' ) THEN
                BEGIN
                    l_cli_json := utsap001.pkg_integra_utal.int_leg05_sd_venta(tbk_orden_compra, tbk_id_sesion, v_ret, v_msg);
                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        v_mensaje_personalizado := 'FALLO EN LLAMADA CREA Y PAGA';
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;

                BEGIN
                    SELECT
                        a.pade_nro_documento
                    INTO v_id_venta
                    FROM
                        vec_cob01.pop_pagos_detalle_temp_sap a
                    WHERE
                            pa_rut = tbk_orden_compra
                        AND pa_nro_operacion = tbk_id_sesion;
        --update
                    UPDATE vec_cob03.pove_venta_transacciones
                    SET
                        vetr_estado = 1
                    WHERE
                        vetr_codigo = v_id_venta;
 
        --ENVIO DE EMAIL
                    BEGIN
                        NULL;
           -- V_RESP_EMAIL:=get_url_file('http://portaldepagos.utalca.cl/portaleditorial/envio_correo_editorial.php?id_venta='||v_id_venta||'&orden_compra='||TBK_ID_SESION);
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_codigo_error := sqlcode;
                        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                        v_fecha_error := sysdate;
                        v_mensaje_personalizado := 'FALLO EN LLAMADA CREA Y PAGA';
                        INSERT INTO log_error (
                            correlativo,
                            codigo_error,
                            mensaje_error,
                            fecha,
                            mensaje_personalizado
                        ) VALUES (
                            seq_error.NEXTVAL,
                            v_codigo_error,
                            v_mensaje_error,
                            v_fecha_error,
                            v_mensaje_personalizado
                        );

                        COMMIT;
                END;

            END IF;
 
    --SI FALLA UN REGISTRO DEL CUPON
            IF v_ret <> 'S' THEN
                resultado_proceso := 'O';
            END IF;
 
    --INSERTAMOS UN REGISTRO CON EL DETALLE DEL CUPON PROCESADO
            BEGIN
                INSERT INTO log_procesa_webpay (
                    pa_nro_operacion,
                    pa_rut,
                    pade_modulo_origen,
                    resultado,
                    mensaje_resul
                ) VALUES (
                    reg.pa_nro_operacion,
                    reg.pa_rut,
                    reg.pade_modulo_origen,
                    v_ret,
                    v_msg
                );

            EXCEPTION
                WHEN OTHERS THEN
                    v_mensaje_personalizado := 'FALLO AL INSERTAR EN LOG PROCESO DE CUOTA';
                    v_codigo_error := sqlcode;
                    v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                    v_fecha_error := sysdate;
                    INSERT INTO log_error (
                        correlativo,
                        codigo_error,
                        mensaje_error,
                        fecha,
                        mensaje_personalizado
                    ) VALUES (
                        seq_error.NEXTVAL,
                        v_codigo_error,
                        v_mensaje_error,
                        v_fecha_error,
                        v_mensaje_personalizado
                    );

                    COMMIT;
            END;
 
    --GENERAMOS EL EVENTO ADM
            IF ( pl_modulo_origen = 'PORTALMATRICULA' ) THEN
                v_limite_checklist := TO_DATE ( vec_cob01.portaldepagos.get_recurso('LIMITE_CHECKLIST'), 'DD-MM-YYYY' );
--           if SYSDATE>V_LIMITE_CHECKLIST  then
                IF ( substr(pl_matricula, 1, 4) < vec_cob01.portaldepagos.get_recurso('ANO_MATRICULA') ) THEN
              --procesar registro de evento adm para cada pago
                    procesar_sgc_sap(tbk_orden_compra, tbk_id_sesion);
              --actualiza_sgc_sap(reg.pade_ano,TBK_ORDEN_COMPRA,V_CARRERA_ICON,to_date(reg.pade_fec_vencimiento,'YYYYMMDD'),v_tipo_documento_icon);
                END IF;

            ELSE
                procesar_sgc_sap(tbk_orden_compra, tbk_id_sesion);
           --actualiza_sgc_sap(reg.pade_ano,TBK_ORDEN_COMPRA,V_CARRERA_ICON,to_date(reg.pade_fec_vencimiento,'YYYYMMDD'),v_tipo_documento_icon);
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                resultado_proceso := 'Y';
                v_mensaje_personalizado := 'Error AL Pagar Deuda en SAP VEC_COB02.WEBPAY, DATOS'
                                           || ' TBK_ORDEN_COMPRA='
                                           || nvl(tbk_orden_compra, 'XXXX')
                                           || ' TBK_ID_SESION='
                                           || nvl(tbk_id_sesion, 'XXXX')
                                           || ' TBK_ID_TRANSACCION='
                                           || nvl(tbk_id_transaccion, '-1')
                                           || ' TBK_CODIGO_AUTORI='
                                           || to_char(nvl(tbk_codigo_autori, -1))
                                           || ' TBK_MONTO='
                                           || to_char(nvl(tbk_monto, -1))
                                           || ' TBK_NUMERO_TARJETA='
                                           || nvl(tbk_numero_tarjeta, 'XXXX')
                                           || ' TBK_NUMERO_TARJETA='
                                           || nvl(tbk_fecha, '01-01-0001')
                                           || ' TBK_NUMERO_CUOTAS='
                                           || to_char(nvl(tbk_numero_cuotas, -1))
                                           || ' TBK_TIPO_PAGO='
                                           || nvl(tbk_tipo_pago, 'XXXX');

                v_codigo_error := sqlcode;
                v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                v_fecha_error := sysdate;
                INSERT INTO log_error (
                    correlativo,
                    codigo_error,
                    mensaje_error,
                    fecha,
                    mensaje_personalizado
                ) VALUES (
                    seq_error.NEXTVAL,
                    v_codigo_error,
                    v_mensaje_error,
                    v_fecha_error,
                    v_mensaje_personalizado
                );

                COMMIT;
        END;
 
        -------------------------------------------------------------
        --INSERTAMOS EL REGISTRO DE LA TRASACCION                  --
        -------------------------------------------------------------
        BEGIN
            INSERT INTO alumno_registro_transac_sap (
                caja,
                alu_rut_n,
                alu_id_transaccion,
                n_cuota,
                alu_codigo_carrera,
                alu_fecha_pago,
                alu_monto,
                usuario,
                alu_fecha_registro,
                tipo_deuda,
                origen,
                alu_estado_pago,
                alu_cod_autorizacion,
                correlativo
            ) VALUES (
                v_caja,
                tbk_orden_compra,
                tbk_id_transaccion,
                reg.pade_cuota,
                reg.pade_nro_carrera,
                trunc(sysdate),
                reg.pade_monto_pesos,
                0,
                ( sysdate ),
                reg.pade_tipo_documento,
                4,
                'S',
                tbk_codigo_autori,
                v_correlativo
            );

            NULL;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_mensaje_personalizado := 'Error AL INSERTAR LA TRANSACCION EN ALUMNO_REGISTRO_TRANSACCION VEC_COB02.WEBPAY, DATOS'
                                           || ' TBK_ORDEN_COMPRA='
                                           || nvl(tbk_orden_compra, 'XXXX')
                                           || ' TBK_ID_SESION='
                                           || nvl(tbk_id_sesion, 'XXXX')
                                           || ' TBK_ID_TRANSACCION='
                                           || nvl(tbk_id_transaccion, '-1')
                                           || ' TBK_CODIGO_AUTORI='
                                           || to_char(nvl(tbk_codigo_autori, -1))
                                           || ' TBK_MONTO='
                                           || to_char(nvl(tbk_monto, -1))
                                           || ' TBK_NUMERO_TARJETA='
                                           || nvl(tbk_numero_tarjeta, 'XXXX')
                                           || ' TBK_NUMERO_TARJETA='
                                           || nvl(tbk_fecha, '01-01-0001')
                                           || ' TBK_NUMERO_CUOTAS='
                                           || to_char(nvl(tbk_numero_cuotas, -1))
                                           || ' TBK_TIPO_PAGO='
                                           || nvl(tbk_tipo_pago, 'XXXX');

                v_codigo_error := sqlcode;
                v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
                v_fecha_error := sysdate;
                INSERT INTO log_error (
                    correlativo,
                    codigo_error,
                    mensaje_error,
                    fecha,
                    mensaje_personalizado
                ) VALUES (
                    seq_error.NEXTVAL,
                    v_codigo_error,
                    v_mensaje_error,
                    v_fecha_error,
                    v_mensaje_personalizado
                );

                COMMIT;
        END;

    END LOOP;

    BEGIN
        IF resultado_proceso = 'S' THEN
            vec_cob01.portaldepagos.carga_pagos_webpay(tbk_orden_compra, tbk_id_sesion);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            v_mensaje_personalizado := 'Error AL IMPRIMIR EL COMPROBANTE DE PAGO  VEC_COB02.WEBPAY, DATOS'
                                       || ' TBK_ORDEN_COMPRA='
                                       || nvl(tbk_orden_compra, 'XXXX')
                                       || ' TBK_ID_SESION='
                                       || nvl(tbk_id_sesion, 'XXXX')
                                       || ' TBK_ID_TRANSACCION='
                                       || to_char(nvl(tbk_id_transaccion, -1))
                                       || ' TBK_CODIGO_AUTORI='
                                       || to_char(nvl(tbk_codigo_autori, -1))
                                       || ' TBK_MONTO='
                                       || to_char(nvl(tbk_monto, -1))
                                       || ' TBK_NUMERO_TARJETA='
                                       || nvl(tbk_numero_tarjeta, 'XXXX')
                                       || ' TBK_NUMERO_TARJETA='
                                       || nvl(tbk_fecha, '01-01-0001')
                                       || ' TBK_NUMERO_CUOTAS='
                                       || to_char(nvl(tbk_numero_cuotas, -1))
                                       || ' TBK_TIPO_PAGO='
                                       || nvl(tbk_tipo_pago, 'XXXX');

            v_codigo_error := sqlcode;
            v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
            v_fecha_error := sysdate;
            INSERT INTO log_error (
                correlativo,
                codigo_error,
                mensaje_error,
                fecha,
                mensaje_personalizado
            ) VALUES (
                seq_error.NEXTVAL,
                v_codigo_error,
                v_mensaje_error,
                v_fecha_error,
                v_mensaje_personalizado
            );

            COMMIT;
    END;
 
/***************************************************************************************/
/* SE ENVIA CORREO CUANDO EL PAGO CORRESPONDE A UN PAGO DE MATRICULA DE ALUMNO ANTIGUO */
/***************************************************************************************/
--IF resultado_proceso='S' then
    BEGIN
        correos.envia_correo_confirmacion(tbk_orden_compra, tbk_id_sesion, v_tipo_documento, v_nro_documento, tbk_numero_tarjeta,
                                         tbk_orden_compra, tbk_codigo_autori, tbk_monto, tbk_numero_cuotas, d_tipo_pago);
    EXCEPTION
        WHEN OTHERS THEN
            v_mensaje_personalizado := 'Error AL enviar_correo VEC_COB02.WEBPAY, DATOS'
                                       || ' TBK_ORDEN_COMPRA='
                                       || nvl(tbk_orden_compra, 'XXXX')
                                       || ' TBK_ID_SESION='
                                       || nvl(tbk_id_sesion, 'XXXX')
                                       || ' TBK_ID_TRANSACCION='
                                       || to_char(nvl(tbk_id_transaccion, -1))
                                       || ' TBK_CODIGO_AUTORI='
                                       || to_char(nvl(tbk_codigo_autori, -1))
                                       || ' TBK_MONTO='
                                       || to_char(nvl(tbk_monto, -1))
                                       || ' TBK_NUMERO_TARJETA='
                                       || nvl(tbk_numero_tarjeta, 'XXXX')
                                       || ' TBK_NUMERO_TARJETA='
                                       || nvl(tbk_fecha, '01-01-0001')
                                       || ' TBK_NUMERO_CUOTAS='
                                       || to_char(nvl(tbk_numero_cuotas, -1))
                                       || ' TBK_TIPO_PAGO='
                                       || nvl(tbk_tipo_pago, 'XXXX');

            v_codigo_error := sqlcode;
            v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
            v_fecha_error := sysdate;
            INSERT INTO log_error (
                correlativo,
                codigo_error,
                mensaje_error,
                fecha,
                mensaje_personalizado
            ) VALUES (
                seq_error.NEXTVAL,
                v_codigo_error,
                v_mensaje_error,
                v_fecha_error,
                v_mensaje_personalizado
            );

            COMMIT;
    END;
--end if;

    resultado := nvl(resultado_proceso, 'E');
    BEGIN
        INSERT INTO log_tiempo (
            alu_id_transaccion,
            inicio,
            fin
        ) VALUES (
            tbk_id_transaccion,
            l_tiempo_inicio,
            sysdate
        );

    EXCEPTION
        WHEN OTHERS THEN
            v_mensaje_personalizado := 'Error AL insertar en tabla log_tiempo'
                                       || ' TBK_ORDEN_COMPRA='
                                       || nvl(tbk_orden_compra, 'XXXX')
                                       || ' TBK_ID_SESION='
                                       || nvl(tbk_id_sesion, 'XXXX')
                                       || ' TBK_ID_TRANSACCION='
                                       || to_char(nvl(tbk_id_transaccion, -1))
                                       || ' TBK_CODIGO_AUTORI='
                                       || to_char(nvl(tbk_codigo_autori, -1))
                                       || ' TBK_MONTO='
                                       || to_char(nvl(tbk_monto, -1))
                                       || ' TBK_NUMERO_TARJETA='
                                       || nvl(tbk_numero_tarjeta, 'XXXX')
                                       || ' TBK_NUMERO_TARJETA='
                                       || nvl(tbk_fecha, '01-01-0001')
                                       || ' TBK_NUMERO_CUOTAS='
                                       || to_char(nvl(tbk_numero_cuotas, -1))
                                       || ' TBK_TIPO_PAGO='
                                       || nvl(tbk_tipo_pago, 'XXXX');

            v_codigo_error := sqlcode;
            v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
            v_fecha_error := sysdate;
            INSERT INTO log_error (
                correlativo,
                codigo_error,
                mensaje_error,
                fecha,
                mensaje_personalizado
            ) VALUES (
                seq_error.NEXTVAL,
                v_codigo_error,
                v_mensaje_error,
                v_fecha_error,
                v_mensaje_personalizado
            );

            COMMIT;
    END;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        v_codigo_error := sqlcode;
        v_mensaje_error := sqlerrm || dbms_utility.format_error_backtrace;
        v_fecha_error := sysdate;
        v_mensaje_personalizado := resultado;
        INSERT INTO log_error (
            correlativo,
            codigo_error,
            mensaje_error,
            fecha,
            mensaje_personalizado
        ) VALUES (
            seq_error.NEXTVAL,
            v_codigo_error,
            v_mensaje_error,
            v_fecha_error,
            v_mensaje_personalizado
        );

        COMMIT;
        resultado := nvl(resultado_proceso, 'A');
END; -- Procedure