-- =========================================================================
-- SCRIPTS PARA GENERACIÓN Y SIMULACIÓN DE DATOS DE PRUEBA (QA)
-- PORTAL EDITORIAL - INTEGRACIÓN SAP SD VENTA
-- =========================================================================
--
-- NOTA: Estos scripts permiten mockear compras completas para simular la
--       integración con SAP usando utsap001.pkg_integra_utal.int_leg05_sd_venta.
--

-- CASO DE PRUEBA 1: COMPRA DE USUARIO INTERNO (FUNCIONARIO - 30% DESCUENTO)
-- RUT: 15318220-5
DECLARE
    v_clie_codigo VARCHAR2(100) := '999901';
    v_vent_codigo VARCHAR2(100) := '888801';
    v_num_op      VARCHAR2(100) := 'OP-TEST-INT-001';
    v_rut_base    VARCHAR2(100) := '15318220';
    v_rut_dv      VARCHAR2(1)   := '5';
    
    v_ret         VARCHAR2(1000);
    v_msg         VARCHAR2(4000);
    v_json_res    json;
BEGIN
    -- Limpieza previa de pruebas con la misma clave
    DELETE FROM vec_cob03.pove_venta_detalle WHERE vent_codigo = v_vent_codigo;
    DELETE FROM vec_cob03.pove_venta WHERE vent_codigo = v_vent_codigo;
    DELETE FROM vec_cob03.pove_cliente WHERE clie_codigo = v_clie_codigo;
    DELETE FROM vec_cob01.pop_pagos_detalle_temp_sap WHERE pa_nro_operacion = v_num_op;
    
    -- 1. Crear el cliente
    INSERT INTO vec_cob03.pove_cliente (
        CLIE_CODIGO, CLIE_RUT, PAIS_CODIGO, REGI_CODIGO, CIUD_CODIGO, CLIE_DV,
        CLIE_DESTINATARIO, CLIE_EMAIL, CLIE_TEL_CONTACTO, CLIE_DIRECCION, CLIE_RETIRO,
        CLIE_BOL_FAC, CLIE_NOMBRE_PILA, CLIE_APELLIDO_PATERNO, CLIE_APELLIDO_MATERNO
    ) VALUES (
        v_clie_codigo, v_rut_base, 1, 7, 71, v_rut_dv,
        'JAIME VENEGAS', 'jvenegas@utalca.cl', '999999999', 'Av. Lircay s/n', 'S',
        'B', 'JAIME', 'VENEGAS', 'VENEGAS'
    );

    -- 2. Crear la venta (Subtotal: 30,000, 30% desc, Pago: 21,000)
    INSERT INTO vec_cob03.pove_venta (
        VENT_CODIGO, CLIE_CODIGO, ESVE_CODIGO, TIPA_CODIGO, VENT_FECHA, VENT_TOTAL
    ) VALUES (
        v_vent_codigo, v_clie_codigo, 3, 1, SYSDATE, 21000
    );

    -- 3. Detalle de la Venta (Libro 900001497 y Libro 900001522)
    -- Libro 1: ¡Viva la ciencia! (Precio base $10,000, desc $3,000, subtotal $7,000)
    INSERT INTO vec_cob03.pove_venta_detalle (
        VEDE_CODIGO, PROD_CODIGO, CLIE_CODIGO, VENT_CODIGO, ESDE_CODIGO,
        VEDE_SUB_TOTAL, VEDE_DESCUENTO, VEDE_CANTIDAD, VEDE_DESPACHO
    ) VALUES (
        '777701', '82', v_clie_codigo, v_vent_codigo, 1,
        7000, 3000, 1, 0
    );

    -- Libro 2: El gusto de criticar (Precio base $20,000, desc $6,000, subtotal $14,000)
    INSERT INTO vec_cob03.pove_venta_detalle (
        VEDE_CODIGO, PROD_CODIGO, CLIE_CODIGO, VENT_CODIGO, ESDE_CODIGO,
        VEDE_SUB_TOTAL, VEDE_DESCUENTO, VEDE_CANTIDAD, VEDE_DESPACHO
    ) VALUES (
        '777702', '45', v_clie_codigo, v_vent_codigo, 1,
        14000, 6000, 1, 0
    );

    -- 4. Registrar en la tabla temporal de integración de pagos SAP (pop_pagos_detalle_temp_sap)
    INSERT INTO vec_cob01.pop_pagos_detalle_temp_sap (
        pa_rut, pa_nro_operacion, pade_tipo_documento, pade_fec_vencimiento,
        pade_nro_carrera, pade_monto_local, pade_nro_documento
    ) VALUES (
        TO_NUMBER(v_rut_base), v_num_op, 'ZP08', TRUNC(SYSDATE),
        '0', 21000, v_vent_codigo
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Caso de prueba 1 (Funcionario) mockeado correctamente.');
    
    -- Para ejecutar la integración en vivo descomente lo siguiente:
    -- v_json_res := utsap001.pkg_integra_utal.int_leg05_sd_venta(v_rut_base, v_num_op, v_ret, v_msg);
    -- DBMS_OUTPUT.PUT_LINE('Retorno SAP: ' || v_ret || ' - Mensaje: ' || v_msg);
END;
/


-- CASO DE PRUEBA 2: COMPRA DE USUARIO EXTERNO (PÚBLICO GENERAL - 10% DESCUENTO)
-- RUT: 12345678-9
DECLARE
    v_clie_codigo VARCHAR2(100) := '999902';
    v_vent_codigo VARCHAR2(100) := '888802';
    v_num_op      VARCHAR2(100) := 'OP-TEST-EXT-002';
    v_rut_base    VARCHAR2(100) := '12345678';
    v_rut_dv      VARCHAR2(1)   := '9';
    
    v_ret         VARCHAR2(1000);
    v_msg         VARCHAR2(4000);
    v_json_res    json;
BEGIN
    -- Limpieza previa de pruebas con la misma clave
    DELETE FROM vec_cob03.pove_venta_detalle WHERE vent_codigo = v_vent_codigo;
    DELETE FROM vec_cob03.pove_venta WHERE vent_codigo = v_vent_codigo;
    DELETE FROM vec_cob03.pove_cliente WHERE clie_codigo = v_clie_codigo;
    DELETE FROM vec_cob01.pop_pagos_detalle_temp_sap WHERE pa_nro_operacion = v_num_op;
    
    -- 1. Crear el cliente
    INSERT INTO vec_cob03.pove_cliente (
        CLIE_CODIGO, CLIE_RUT, PAIS_CODIGO, REGI_CODIGO, CIUD_CODIGO, CLIE_DV,
        CLIE_DESTINATARIO, CLIE_EMAIL, CLIE_TEL_CONTACTO, CLIE_DIRECCION, CLIE_RETIRO,
        CLIE_BOL_FAC, CLIE_NOMBRE_PILA, CLIE_APELLIDO_PATERNO, CLIE_APELLIDO_MATERNO
    ) VALUES (
        v_clie_codigo, v_rut_base, 1, 7, 71, v_rut_dv,
        'JUAN PEREZ', 'jperez@gmail.com', '988888888', 'Calle Falsa 123', 'S',
        'B', 'JUAN', 'PEREZ', 'PEREZ'
    );

    -- 2. Crear la venta (Subtotal: 30,000, 10% desc, Pago: 27,000)
    INSERT INTO vec_cob03.pove_venta (
        VENT_CODIGO, CLIE_CODIGO, ESVE_CODIGO, TIPA_CODIGO, VENT_FECHA, VENT_TOTAL
    ) VALUES (
        v_vent_codigo, v_clie_codigo, 3, 1, SYSDATE, 27000
    );

    -- 3. Detalle de la Venta (Libro 900001497 y Libro 900001522)
    -- Libro 1: ¡Viva la ciencia! (Precio base $10,000, desc $1,000, subtotal $9,000)
    INSERT INTO vec_cob03.pove_venta_detalle (
        VEDE_CODIGO, PROD_CODIGO, CLIE_CODIGO, VENT_CODIGO, ESDE_CODIGO,
        VEDE_SUB_TOTAL, VEDE_DESCUENTO, VEDE_CANTIDAD, VEDE_DESPACHO
    ) VALUES (
        '777703', '82', v_clie_codigo, v_vent_codigo, 1,
        9000, 1000, 1, 0
    );

    -- Libro 2: El gusto de criticar (Precio base $20,000, desc $2,000, subtotal $18,000)
    INSERT INTO vec_cob03.pove_venta_detalle (
        VEDE_CODIGO, PROD_CODIGO, CLIE_CODIGO, VENT_CODIGO, ESDE_CODIGO,
        VEDE_SUB_TOTAL, VEDE_DESCUENTO, VEDE_CANTIDAD, VEDE_DESPACHO
    ) VALUES (
        '777704', '45', v_clie_codigo, v_vent_codigo, 1,
        18000, 2000, 1, 0
    );

    -- 4. Registrar en la tabla temporal de integración de pagos SAP (pop_pagos_detalle_temp_sap)
    INSERT INTO vec_cob01.pop_pagos_detalle_temp_sap (
        pa_rut, pa_nro_operacion, pade_tipo_documento, pade_fec_vencimiento,
        pade_nro_carrera, pade_monto_local, pade_nro_documento
    ) VALUES (
        TO_NUMBER(v_rut_base), v_num_op, 'ZP08', TRUNC(SYSDATE),
        '0', 27000, v_vent_codigo
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Caso de prueba 2 (Externo) mockeado correctamente.');
    
    -- Para ejecutar la integración en vivo descomente lo siguiente:
    -- v_json_res := utsap001.pkg_integra_utal.int_leg05_sd_venta(v_rut_base, v_num_op, v_ret, v_msg);
    -- DBMS_OUTPUT.PUT_LINE('Retorno SAP: ' || v_ret || ' - Mensaje: ' || v_msg);
END;
/
