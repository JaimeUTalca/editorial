create or replace PACKAGE BODY           "VENTA_ONLINE" IS

   path_inspinia  VARCHAR2 (300) := 'http://inet.utalca.cl/inspinia/';
   path_awesome    VARCHAR2 (300) := 'http://inet.utalca.cl/inspinia/font-awesome/';

   path_dhtmlx  VARCHAR2 (300) := 'http://inet.utalca.cl/dhtmlxsuite4.3/';
   path_dhtmlx_36  VARCHAR2 (300) := 'http://inet.utalca.cl/dhtmlxsuite3.6/';

   --path_pdf  VARCHAR2 (300) := 'http://inet.utalca.cl/pdf/';
   /* Configuracion estandar*/

   g_charset   varchar2(15) := 'ISO-8859-1';
   g_formato_num VARCHAR2  (30)  :='FM99,999,999,999';
   g_sin_valor varchar2(2) := '-1';
   g_mascara_fecha varchar(25) :='RRRR-MM-DD hh24:mi';
   g_formato_num VARCHAR2  (30)  :='FM99,999,999,999';
   /* Fin Configuracion estandar*/
   g_nombre_sistema varchar2(80):='Sistema Portal de ventas Editorial Universidad de Talca';
   v_ancho_columna1 varchar2(50):='col-lg-2'; /*label*/
   v_ancho_columna2 varchar2(50):='col-lg-10'; /*1 etiqueta  1 campo textos 10 columnas*/
   v_ancho_columna3 varchar2(50):='col-lg-4'; /*2 etiqueta  2 campo textos de 4 columnas*/
   v_ancho_columna4 varchar2(50):='col-lg-2'; /*3 etiqueta  3 campo* textos 2 columnas*/
   v_ancho_columna5 varchar2(50):='col-lg-3'; /*3 etiqueta  3 campo* textos 2 columnas*/
    v_ancho_columna6 varchar2(50):='col-lg-5'; /*3 etiqueta  3 campo* textos 2 columnas*/
    v_ancho_columna7 varchar2(50):='col-lg-6'; /*3 etiqueta  3 campo* textos 2 columnas*/
    v_ancho_columna8 varchar2(50):='col-lg-12';
    v_ancho_columna9 varchar2(50):='col-lg-8';
    v_ancho_columna10 varchar2(50):='col-lg-7';
    v_factor  number:= 0.9; -- se cambia de 1 a 0.9 el valor por defecto ya ue corresponde el descuento a las personas que no son de la universidad - alan riquelme 16.05.2025

   v_ancho_label_lg varchar2(50):='col-lg-2'; /*label*/
   v_ancho_label_xs varchar2(50):='col-lg-1'; /*label*/
   g_m number;
   g_s varchar2(100);
   ruta_imagen varchar2(100):='http://inet.utalca.cl/inspinia/img/';

    ruta_imagen_libros varchar2(100):='http://inet.utalca.cl/inspinia/img/editorial/';

    ruta_web_editorial varchar2(100):='http://inet.utalca.cl/inspinia/web_editorial/';
    ruta_pdf_boleta varchar2(100):='http://inet.utalca.cl/inspinia/boleta_ingreso/pdf/examples/';
    username         VARCHAR2(60);

    NMB_USUARIO      gene_usuario.usua_nombre%TYPE;

   g_rut_session varchar2(15);

   g_mail_to   varchar2(100):= 'ariquelme@utalca.cl;macarena.oses@utalca.cl;cjiron@utalca.cl'; -- ;vhillmer@utalca.cl;cjiron@utalca.cl

 g_sistema_sapqa varchar2(500):='http://sappiutalca:piutalca2016@sappoqa.utalca.cl:52000';
 g_sistema_sapdv varchar2(500):='http://sappiutalca:piutalca2016@sappodev.utalca.cl:51000';
 g_sistema_sapprod varchar2(500):='http://sappiutalca:piutalca2016@sappoprod.utalca.cl:53000';

 g_sistema_sap varchar2(500):=g_sistema_sapqa;
 g_despacho number default 0; -- se creo una variable global g_despacho

FUNCTION verifica_sesion
  RETURN BOOLEAN
IS
  v_return       BOOLEAN := FALSE;
BEGIN
  -- g_rut_session := vec_cob03.web_util.get_cookie('SESSION_RUT');
  g_rut_session := '16600210';                                      --- Rut en duro para pruebas

  IF g_rut_session IS NOT NULL AND g_rut_session <> 'ERROR' THEN
     v_return := TRUE;
  ELSE
     v_return := FALSE;
  END IF;

  RETURN v_return;
END verifica_sesion;




Procedure valida_intranet(sesion in varchar2, ip in varchar2, mRutE in varchar2,sistema in varchar) is
  n         number;
begin
    g_rut_session :=toolkit.decrypt(mRutE);
  -------------------------------
  --INCLUIR VALIACION DE INTRANET
   n:= u_online.internet.ses_valida(sesion,ip,mRutE,sistema) ;

  -- validado para desarrollo. Quitar en producción.

  --n:=1;
  -------------------------------
  if n <> 0  then
             --CODIGO PARA CREAR SESION DE TRABAJO
               owa_util.mime_header('text/html', FALSE);
               owa_cookie.send('SESSION_RUT',g_rut_session, '', '/');
               owa_cookie.send('TIEMPO',to_char(sysdate,'YYYYMMDDHH24MISS'), sysdate + 181/(24*60) , '/');
               owa_util.redirect_url('VENTA_ONLINE.PRINCIPAL?m=133');
               owa_util.http_header_close;
  else
         htp.p('<script>alert("Acceso Denegado. Su sesión de la intranet ha expirado, por favor
         autentifiquese  nuevamente ");
         </script>');
  end if;

end valida_intranet;

procedure prueba_aleatorias is


begin


htp.p('


<html>
<head>
<title>. : Editorial Universidad de Talca : .</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<style type="text/css">
body {
    margin-left: 0px;
    margin-top: 0px;
    margin-right: 0px;
    margin-bottom: 0px;
}
</style>
<link href="css/estilos.css" rel="stylesheet" type="text/css">
</head>
<body bgcolor="#FFFFFF">
<!-- Save for Web Slices (editorial_interior002_cortes.psd) -->
<table width="905" height="968" border="0" align="center" cellpadding="0" cellspacing="0" id="Tabla_01">
      <tr>
        <td height="205" colspan="2"><img src="'||ruta_imagen_libros||'edit0006.jpg" alt="" width="180" height="205" usemap="#Map2" border="0"></td>
        <td colspan="2"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="449" height="205" alt=""></td>
        <td colspan="3"><img src="'||ruta_imagen_libros||'edit0006.jpg" alt="" width="271" height="205" usemap="#Map" border="0"></td>
      </tr>
      <tr>
        <td width="115" height="40"><a href="html/mision.html"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="112" height="40" alt=""></a></td>
        <td width="69"><a href="html/normas.html"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="68" height="40" alt=""></a></td>
        <td width="77"><a href="html/ventas.php"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="75" height="40" alt=""></a></td>
        <td width="374"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="374" height="40" alt=""></td>
        <td width="65"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="65" height="40" alt=""></td>
        <td width="109"><a href="index.html"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="109" height="40" alt=""></a></td>
        <td width="97"><a href="html/contactos.html"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="97" height="40" alt=""></a></td>
      </tr>
      <tr>
        <td height="58" colspan="7"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="900" height="58" alt=""></td>
      </tr>
      <tr>
        <td colspan="4" valign="top" style="padding-left:40px"><table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td height="226" align="center" background="imagenes/fondo_foto.png"><a href="http://www.utalca.cl/link.cgi//SalaPrensa/Academia/8084" target="_blank"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="554" height="209"></a></td>
          </tr>
        </table></td>
        <td height="246" valign="top"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="65" height="62" alt=""></td>
        <td height="246" colspan="2" valign="top"><table width="92%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td><a href="html/coleccion_academica.html"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="206" height="62" alt=""></a></td>
          </tr>
          <tr>
            <td><a href="html/ebook.php"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="206" height="40" alt=""></a></td>
          </tr>
          <tr>
            <td><a href="html/revistas.html"><img src="'||ruta_imagen_libros||'edit0006.jpg" width="206" height="40" alt=""></a></td>
          </tr>
          <tr>
            <td><img src="'||ruta_imagen_libros||'edit0006.jpg" width="206" height="84" alt=""></td>
          </tr>
        </table></td>
      </tr>
      <tr>
        <td height="19" colspan="7" align="left" valign="top" ><img src="'||ruta_imagen_libros||'edit0006.jpg" width="412" height="46"></td>
      </tr>
      <tr>
        <td height="250" colspan="7" align="center" valign="top" ><iframe src="" width="900" height="400" scrolling="no" frameborder="0" allowtransparency="yes"></iframe></td>
        </tr>
    </table>
<!-- End Save for Web Slices -->


</body>
</html>
');


end;

procedure imagenes_aleatorias_prueba is




cursor cur_imagenes is
select  prod_nombre, prod_imagen from (
SELECT *   FROM pove_producto_tl where prod_precio is not null
          ORDER BY DBMS_RANDOM.RANDOM

)
where rownum<129;

lista_imagenes varchar2(4000);



v_class_div varchar2(50);
 v_contador number:=0;

begin
estilos_editorial;
    htp.p('

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Documento sin t&iacute;tulo</title>
<script type="text/javascript" src="'||ruta_web_editorial||'js/SlideNotas/jquery.js"></script>
<script type="text/javascript" src="'||ruta_web_editorial||'js/SlideNotas/easySlider1.7.js"></script>
<link href="'||ruta_web_editorial||'js/screen.css" rel="stylesheet" type="text/css" media="screen" />
<link href="'||ruta_web_editorial||'css/estilos.css" rel="stylesheet" type="text/css" />
<style type="text/css">

    body {
       background-color: #ffffff;
   }


 . {
    font-family: Arial, Helvetica, Sans-Serif;
    /*color:#333;*/

}

body {
    /*background: url(http://editorial.utalca.cl////imagenes/fondo_notas.jpg) top;

    color:#333;*/
    /*line-height:180%;
    font:80% Trebuchet MS, Arial, Helvetica, Sans-Serif;*/
    margin:0;
    padding:0;
/*  text-align:center;
background-color:#e1e1e1;*/
vertical-align: top;
}
/*---bloque h1 para texto de sline notas----*/
h1  {
    margin: 25px 0 5px 5px;
    padding: 0;
    font-size: 12px;
    font-weight: bold;
    color: #FFFFFF;
    border: none;
    /*line-height: 13px;*/
}
/*---bloque h1 para texto de sline notas----*/
h2{
    font-size:160%;
    font-weight:normal;
}

h3{
    font-size:140%;
    font-weight:normal;
}

img {
    margin: 0 0 0 0;
    padding: 0;
    border: none;
}

img.vermas{
    margin: 0 0 0 5px;
    padding: 0;
    border: none;
}


pre{
    display:block;
    font:12px "Courier New", Courier, monospace;
    padding:10px;
    border:1px solid #bae2f0;
    background:#e3f4f9;
    margin:.5em 0;
    width:600px;
    vertical-align: top;
}

/* image replacement */
.graphic, #prevBtn, #nextBtn, #slider1prev, #slider1next{
    margin:0;
    padding:0;
    display:block;
    overflow:hidden;
    text-indent:-1000px;
}

/* // image replacement */

#container{
    margin:0 auto;
    position:relative;
    text-align:left;
    width:870px;
    /*background:#e1e1e1;       */
    margin-bottom:2em;
    border: none;
}

#header{
    height:400px;
    line-height:80px;
    background:#5DC9E1;
    color:#fff;
}

#content{
    position:relative;
}

/* Easy Slider */
#slider ul, #slider li, #slider2 ul, #slider2 li {
    margin:0;
    padding:0;
    list-style:none;

}

#slider2{
    margin-top:1em;
}

#slider li, #slider2 li {
    width:870px;
    height:400px;
    overflow:hidden;
}

#prevBtn, #nextBtn, #slider1next, #slider1prev{
    display:block;
    width:30px;
    height:77px;
    position:absolute;
   left:-15px;
    top:150px;
    z-index:0;
}

#nextBtn, #slider1next{
    left:870px;
}

#prevBtn a, #nextBtn a, #slider1next a, #slider1prev a{
    display:block;
    position:relative;
    width:30px;
    height:77px;
    background:url(http://editorial.utalca.cl/imagenes/flecha_izq.png) no-repeat 0 0;

}

#nextBtn a, #slider1next a{
    background:url(http://editorial.utalca.cl/imagenes/flecha_der.png) no-repeat 0 0;

}
/* // Easy Slider */


/* The Modal (background) */
.modal {
    display: none; /* Hidden by default */
    position: fixed; /* Stay in place */
    z-index: 1; /* Sit on top */
    padding-top: 100px; /* Location of the box */
    left: 0;
    top: 0;
    width: 100%; /* Full width */
    height: 50%; /* Full height */
    overflow: auto; /* Enable scroll if needed */
    background-color: rgb(0,0,0); /* Fallback color */
    background-color: rgba(0,0,0,0.4); /* Black w/ opacity */
}

/* Modal Content */
.modal-content {
    background-color: #fefefe;
    margin: auto;
    padding: 20px;
    border: 1px solid #888;
    width: 80%;
}

/* Modal Header */
.modal-header {
    padding: 2px 30px;
    background-color: #5cb85c;
    color: white;
}

/* Modal Body */
.modal-body {padding: 2px 8px;
            background-color: #5cb85c;
            color: white;
    }

/* Modal Footer */
.modal-footer {
    padding: 2px 8px;
    background-color: #5cb85c;
    color: white;
}




/* The Close Button */
.close {
    color: #aaaaaa;
    float: right;
    font-size: 28px;
    font-weight: bold;
}

.close:hover,
.close:focus {
    color: #000;
    text-decoration: none;
    cursor: pointer;
}


 </style>
</head>

<body>
<script type="text/javascript">
    $(document).ready(function(){
        $(''#slider'').easySlider({
            auto: true,
            continuous: true
        }, 10000);
    });
</script>




<div id="container">
    <div id="content">');

                   htp.p('<div id="slider">
                         <ul>
                            ');
                      v_contador:=1;
                      FOR fila IN cur_imagenes LOOP

                          IF (mod(v_contador,4) = 1 ) --or v_contador = 5 or v_contador = 9 or v_contador = 13
                          THEN
                            htp.p('<li><table width="870" border="0" cellspacing="0" cellpadding="0"><tr>');
                          END IF;

                          HTP.P('
                          --<td width="25%" align="center" valign="top" style="padding-left:10px; padding-right:10px"><a href=''http://condor2.utalca.cl/pls/cob3/venta_online.portal_ventas?s=1'' target=''_blank'' ><img src="'||ruta_imagen_libros||fila.prod_imagen||'" width="171" height="219"></a>
                          <td width="25%" align="center" valign="top" style="padding-left:10px; padding-right:10px"><a href=''http://condor2-19testing.utalca.cl/pls/cob3_test/venta_online.portal_venta?s=1'' target=''_blank'' ><img src="'||ruta_imagen_libros||fila.prod_imagen||'" width="171" height="219"></a>
                          ');

                          HTP.P('</td>');

                              IF (mod(v_contador,4) = 0 ) --or v_contador = 8 or v_contador = 12 or v_contador = 16
                              THEN

                           htp.p('</tr></table></li>');


                           END IF;
                           v_contador := v_contador+1;


                     end loop;
            htp.p('</ul>');

        htp.p('
         </div>
    </div>
</div>

<script>

/*

function abrir_modal(){




    var modal = document.getElementById(''myModal'');
     modal.style.display = "block";

// Get the <span> element that closes the modal
var span = document.getElementsByClassName("close")[0];

    // When the user clicks on <span> (x), close the modal
    span.onclick = function() {
        modal.style.display = "none";
    }

// When the user clicks on <span> (x), close the modal
span.onclick = function() {
    modal.style.display = "none";
}

// When the user clicks anywhere outside of the modal, close it
window.onclick = function(event) {
    if (event.target == modal) {
        modal.style.display = "none";
    }
}


}



</script>


</body>
</html>



'

);

--librerias_js;


end;



procedure info_editorial is


begin


--estilos;
   estilos_editorial;


 htp.p('


<div class="modal inmodal fade" id="myModal5" tabindex="-1" role="dialog"  aria-hidden="true">
      <div class="modal-dialog modal-lg">
          <div class="modal-content">
              <div class="modal-header">
                  <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
                  <h4 class="modal-title">Editorial de Talca</h4>
                  <small class="font-bold">Dirección de Extension Cultural</small>
              </div>
              <div class="modal-body">
                  <p><strong>Pronto podrás comprar nuestros libros de manera online</strong></p>
              </div>

              <div class="modal-footer">
                  <button type="button" class="btn btn-white" data-dismiss="modal">Cerrar</button>

              </div>
          </div>
      </div>
</div>

     <script>

        function info_modal(){



            //$("#Modal_info").modal("toggle");
        }

    </script>


            ');


librerias_js;


end info_editorial;




procedure imagenes_aleatorias_editorial is

cursor cur_imagenes is
select  prod_nombre, prod_imagen from (
SELECT *   FROM    pove_producto_tl  ORDER BY DBMS_RANDOM.RANDOM

)
where rownum<17;

lista_imagenes varchar2(4000);


v_class_div varchar2(50);
 v_contador number:=0;

begin
--estilos;
    htp.p('
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>Documento sin título</title>
<script type="text/javascript" src="http://editorial.utalca.cl////js_home/SlideNotas/jquery.js"></script>
<script type="text/javascript" src="http://editorial.utalca.cl////js_home/SlideNotas/easySlider1.7.js"></script>
<link href="http://editorial.utalca.cl////js_home/screen.css" rel="stylesheet" type="text/css" media="screen">
<link href="http://editorial.utalca.cl////css/estilos.css" rel="stylesheet" type="text/css">
</head>


 <style>

    body {
       background-color: #ffffff;
   }


 . {
    font-family: Arial, Helvetica, Sans-Serif;
    /*color:#333;*/

}

body {
    /*background: url(http://editorial.utalca.cl////imagenes/fondo_notas.jpg) top;

    color:#333;*/
    /*line-height:180%;
    font:80% Trebuchet MS, Arial, Helvetica, Sans-Serif;*/
    margin:0;
    padding:0;
/*  text-align:center;
background-color:#e1e1e1;*/
vertical-align: top;
}
/*---bloque h1 para texto de sline notas----*/
h1  {
    margin: 25px 0 5px 5px;
    padding: 0;
    font-size: 12px;
    font-weight: bold;
    color: #FFFFFF;
    border: none;
    /*line-height: 13px;*/
}
/*---bloque h1 para texto de sline notas----*/
h2{
    font-size:160%;
    font-weight:normal;
}

h3{
    font-size:140%;
    font-weight:normal;
}

img {
    margin: 0 0 0 0;
    padding: 0;
    border: none;
}

img.vermas{
    margin: 0 0 0 5px;
    padding: 0;
    border: none;
}

/*table{
    /*background-image:url(http://editorial.utalca.cl////imagenes/fondo_notas.jpg);
    height:200px;* /
    height:852px;
    /*background-color:#E1E1E1;* /
    margin: 0;
    padding: 0;
    border: none;
    border-collapse: collapse;
    width: 552px;

}

td {
    margin: 0;
    padding: 0;
    border: none;
    /*vertical-align: top;* /
}*/

pre{
    display:block;
    font:12px "Courier New", Courier, monospace;
    padding:10px;
    border:1px solid #bae2f0;
    background:#e3f4f9;
    margin:.5em 0;
    width:600px;
    vertical-align: top;
}

/* image replacement */
.graphic, #prevBtn, #nextBtn, #slider1prev, #slider1next{
    margin:0;
    padding:0;
    display:block;
    overflow:hidden;
    text-indent:-1000px;
}

/* // image replacement */

#container{
    margin:0 auto;
    position:relative;
    text-align:left;
    width:870px;
    /*background:#e1e1e1;       */
    margin-bottom:2em;
    border: none;
}

#header{
    height:400px;
    line-height:80px;
    background:#5DC9E1;
    color:#fff;
}

#content{
    position:relative;
}

/* Easy Slider */
#slider ul, #slider li, #slider2 ul, #slider2 li {
    margin:0;
    padding:0;
    list-style:none;

}

#slider2{
    margin-top:1em;
}

#slider li, #slider2 li {
    width:870px;
    height:400px;
    overflow:hidden;
}

#prevBtn, #nextBtn, #slider1next, #slider1prev{
    display:block;
    width:30px;
    height:77px;
    position:absolute;
    left:-15px;
    top:150px;
    z-index:0;
}

#nextBtn, #slider1next{
    left:870px;
}

#prevBtn a, #nextBtn a, #slider1next a, #slider1prev a{
    display:block;
    position:relative;
    width:30px;
    height:77px;
    background:url(http://editorial.utalca.cl///imagenes/flecha_izq.png) no-repeat 0 0;

}

#nextBtn a, #slider1next a{
    background:url(http://editorial.utalca.cl///imagenes/flecha_der.png) no-repeat 0 0;

}
/* // Easy Slider */
 </style>

   <body>
   <script type=''text/javascript''>
    $(document).ready(function(){
        $(''#slider'').easySlider({
            auto: false,
            continuous: true
        });
    });
</script>
<div id="container">
    <div id="content">
        <div id="slider" style="width: 870px; height: 400px; overflow: hidden;">
            <ul style="width: 1740px;">
              <li style="float: left;">
                <table width="870" border="0" cellspacing="0" cellpadding="0">
                  <tbody>');
                      v_contador:=1;
                      FOR fila IN cur_imagenes LOOP
                          IF (v_contador = 1 or v_contador = 5 or v_contador = 9 or v_contador = 13) THEN
                          HTP.P('<tr>');
                          END IF;
                          HTP.P('
                             <!--<td width="25%" align="center" valign="top" style="padding-left:10px; padding-right:10px"><a href="http://www.utalca.cl/link.cgi//SalaPrensa/Institucional/6257" target="_blank"><img src="'||ruta_imagen_libros||fila.prod_imagen||'" width="171" height="219"></a>-->
                             <td height="250" colspan="7" align="center" valign="top"><iframe src="'||ruta_imagen_libros||fila.prod_imagen||'" width="900" height="400" scrolling="no" frameborder="0" allowtransparency="yes"></iframe>
                             ');

                            HTP.P(v_contador||'</td>');
                           IF (v_contador = 4 or v_contador = 8 or v_contador = 12 or v_contador = 16) THEN
                           htp.p('*</tr>');

                           END IF;
                          v_contador := v_contador+1;

                      end loop;
                      htp.p('
                    </tbody>
                </table>
              </li>
            </ul>
         </div>
         <span id="prevBtn"><a href="javascript:void(0);">Anterior</a></span>
         <span id="nextBtn"><a href="javascript:void(0);">Siguiente</a></span>
    </div>
</div>




      </body>

       <script>
 /*   $(document).ready(function(){
        $(''#slider'').easySlider({
            auto: false,
            continuous: true
        });
    }); */
</script>

</html>');

librerias_js;


end;

procedure estilos is
begin
/*Estilos del sistema*/
htp.p('
    <link href="'||path_inspinia||'css/bootstrap.min.css" rel="stylesheet">
    <link href="'||path_awesome||'css/font-awesome.min.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/plugins/iCheck/custom.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/plugins/chosen/chosen.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/plugins/jasny/jasny-bootstrap.min.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/plugins/datapicker/datepicker3.css" rel="stylesheet">
    <!-- Toastr style -->
    <link href="'||path_inspinia||'css/plugins/toastr/toastr.min.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/animate.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/style1.css" rel="stylesheet">


    <link rel="'||path_dhtmlx||'stylesheet" type="text/css" href="dhtmlxSuite_v43_std/codebase/dhtmlx.css"/>');








end; -- fin estilos

   PROCEDURE perfil
   IS

   v_nombre_empleado varchar2(500);
   v_nombre_perfil   varchar2(100);
   v_sesion boolean;

       CURSOR c_cursor
      IS
       select initcap(USUA_NOMBRE) as nombre
        into v_nombre_empleado
            from GENE_USUARIO
            where usua_rut =  lpad(g_rut_session,8,'0')
            and   usua_rut <> '00000000';
      CURSOR c_perfil
      IS
       SELECT initcap(p.perf_nombre) as perfil
       into  v_nombre_perfil
       FROM gene_usuario_perfil a, gene_usuario u, gene_perfil p
       where a.usua_rut =  lpad(g_rut_session,8,'0')
       and a.perf_id = p.perf_id;
begin


    begin
        v_sesion := verifica_sesion;

      FOR m_cursor IN c_cursor
      LOOP
         v_nombre_empleado := m_cursor.nombre;
      END LOOP;
      FOR m_perfil IN c_perfil
      LOOP
         v_nombre_perfil := m_perfil.perfil;
      END LOOP;

    exception when others then
           v_nombre_empleado := '';
           v_nombre_perfil   := '';
    end ;

 htp.p('<li class="nav-header">
                    <div class="dropdown profile-element">
                        <a data-toggle="dropdown" class="dropdown-toggle" href="#">
                            <span class="clear"> <span class="block m-t-xs"> <strong class="font-bold">'||v_nombre_empleado||'</strong>
                             </span> <span class="text-muted text-xs block">'||v_nombre_perfil||'<b class="caret"></b></span> </span> </a>
                        <ul class="dropdown-menu animated fadeInRight m-t-xs">
                            <li><a href="venta_online.principal.php?m=134&dat_s=13069157">Ficha</a></li>
                            <li><a href="#">Contacto</a></li>
                            <li><a href="#">Mailbox</a></li>
                            <li class="divider"></li>
                            <li><a href="http://www.utalca.cl/link.cgi/#/link.cgi/">Salir</a></li>
                        </ul>
                    </div>
                    <div class="logo-element">
                        IN+
                    </div>
     </li>');
end;


procedure servicio_json_libros (p_prod_codigo number  default null)
 is
cursor c1 is
    SELECT a.prod_codigo,a.prod_nombre, a.prod_descripcion, a.prod_precio,
      a.prod_imagen, a.prod_estado
     FROM pove_producto_tl a where  a.prod_precio is not null;
v_flag_primero boolean :=true;
begin
      owa_util.mime_header('application/json',false, g_charset);
      OWA_UTIL.http_header_close;
 htp.p('{');

    --   htp.p('"success":"true",');
htp.p('"data":{');
      for c in c1 loop

        if not v_flag_primero then
            htp.p(',');
        end if;
        v_flag_primero := false;

htp.p('"'||c.prod_codigo||'":{');
        htp.p('"prod_codigo":"'||c.prod_codigo||'",');
        htp.p('"prod_nombre":"'||web_util.format_json(c.prod_nombre)||'",');
        htp.p('"prod_descripcion":"'||web_util.format_json(c.prod_descripcion)||'",');
        htp.p('"prod_precio":"'||web_util.format_json(c.prod_precio)||'",');
        htp.p('"prod_imagen":"'||web_util.format_json(c.prod_imagen)||'",');
        htp.p('"prod_estado":"'||web_util.format_json(c.prod_estado)||'"');
htp.p('}');



    end loop;
    htp.p('}');

htp.p('}');
end servicio_json_libros;


function f_costo_envio (p_tade_codigo number DEFAULT null,
                       p_cire_codigo number  DEFAULT null,
                       p_coen_cantidad number DEFAULT null) return number is


cursor cur_costo_envio is

 SELECT  a.coen_valor
 FROM pove_costo_envio a
 where tade_codigo =  p_tade_codigo
 and cire_codigo =    p_cire_codigo
 and coen_cantidad >= p_coen_cantidad
 order by coen_cantidad;

 begin

 FOR fila IN cur_costo_envio LOOP
  return(fila.coen_valor);
  exit;

 end LOOP;

end;




/** FIN DE LA FUNCION A PROBAR ALAN RIQUELME 10122024 **/


FUNCTION get_json_std
  RETURN  clob IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;

   cursor c1 is
    SELECT a.prod_codigo,a.prod_nombre, a.prod_descripcion, a.prod_precio,
      a.prod_imagen, a.prod_estado
     FROM pove_producto_tl a where a.prod_precio is not null;

BEGIN



    l_jobs_json := json_list();
    l_employee_json := json();

    FOR fila IN c1 LOOP
          l_json := json();
           l_json.put('prod_codigo', fila.prod_codigo);
           l_json.put('prod_nombre', fila.prod_nombre);
           l_json.put('prod_descripcion', fila.prod_descripcion);
           l_jobs_json.append(l_json.to_json_value);
    end loop;


   l_employee_json.put('Libros', l_jobs_json.to_json_value);
    dbms_lob.createtemporary(l_json_clob, true);

    l_employee_json.to_clob(l_json_clob);



      return l_json_clob;



END;
procedure prueba_alan
is
begin
htp.p('aaaa');
end;

function get_esutalca (p_rut varchar2  default null) return boolean
IS
v_encontro int;
v_rut_clean varchar2(100);

BEGIN

-- Clean the RUT by removing trailing hyphen-DV and any dots
v_rut_clean := regexp_replace(p_rut, '-[0-9kK]$', '');
v_rut_clean := replace(v_rut_clean, '.', '');

select count(*) into v_encontro from (
SELECT to_char(rol_emp) as rut
FROM REM_FICHA
union
select to_char(a.alu_rut_n) as rut
from alumno a,  plan_alu p
where a.alu_rut_n = p.alu_rut_n
and hist_situacion.situacion_valida_informes(pal_situacion_academica_actual) ='S'
and pal_situacion_academica_actual  in (1,4,19,30,31,32,72)
)
where rut= v_rut_clean;

if v_encontro > 0 then
    RETURN true;
else
    RETURN false;
end if;

end;

procedure get_json_descuento_comunidad(p_rut varchar2  default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);
    v_valor boolean;

BEGIN

  owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;

v_descuento:='select * from (
SELECT to_char(rol_emp||''-''||dv) Rut,nombre_pila as nombre,
       apellido_paterno as apellido_paterno,
       apellido_materno as apellido_materno,
       ''Funcionario'' as Clasificacion,
       e_mail,
       domicilio_calle as direccion,
       domicilio_numero numero_direccion,
       domicilio_telefono  as telefono
FROM REM_FICHA
union
select to_char(a.alu_rut_n||''-''||a.alu_rut_v) Rut,
       alu_nombres as nombre,alu_paterno as apellido_paterno,
       alu_materno as apellido_materno,
       ''Alumno'' as Clasificacion,
       ALUMNO_PKG.obtiene_correo(a.alu_rut_n,1) as e_mail,
       alu_dir_origen as direccion,
       alu_fono_origen as telefono,
       '''' as numero_direccion
from alumno a,  plan_alu p
where a.alu_rut_n = p.alu_rut_n
and hist_situacion.situacion_valida_informes(pal_situacion_academica_actual)=''S''
and pal_situacion_academica_actual  in (1,4,19,30,31,32,72)
)
where rut=UPPER('''||p_rut||''')
AND CLASIFICACION <> ''Externo''';


--AND CLASIFICACION <> ''Externo''

 l_jobs_json := json_list();
 l_jobs_json := json_dyn.executeList(v_descuento);

 l_json := json();
 l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();







END;

procedure get_json_regiones_fac(p_pais_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

 v_descuento:='SELECT ng.regi_codigo , ng.regi_descripcion, ng.pais_codigo, t.tade_codigo, t.tade_descripcion   FROM pove_pais i, pove_region ng , pove_tarifa_despacho t  WHERE i.pais_codigo = ng.pais_codigo  and ng.tade_codigo = t.tade_codigo and   ng.pais_codigo = '''||p_pais_codigo||''' ORDER BY ng.pais_codigo';


    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_descuento);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure get_json_regiones(p_pais_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

 v_descuento:='SELECT ng.regi_codigo , ng.regi_descripcion, ng.pais_codigo, t.tade_codigo, t.tade_descripcion   FROM pove_pais i, pove_region ng , pove_tarifa_despacho t  WHERE i.pais_codigo = ng.pais_codigo  and ng.tade_codigo = t.tade_codigo and   ng.pais_codigo = '''||p_pais_codigo||''' ORDER BY ng.pais_codigo';


    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_descuento);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure get_json_tipo_distribucion(p_ciud_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_distribucion varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;
 v_distribucion:='SELECT ng.regi_codigo , ng.regi_descripcion, ng.pais_codigo, t.tidi_codigo, t.tidi_descripcion FROM pove_pais i, pove_region ng ,pove_ciudad c, pove_tipo_distribucion t  WHERE i.pais_codigo = ng.pais_codigo  and  ng.regi_codigo = c.regi_codigo and c.tidi_codigo = t.tidi_codigo and   c.ciud_codigo = '''||p_ciud_codigo||''' ORDER BY c.tidi_codigo';



    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_distribucion);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure get_json_detalle_despacho(p_vent_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_detalle_venta varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

 v_detalle_venta:='SELECT pove_producto_tl.prod_nombre,pove_producto_tl.prod_precio,pove_venta_detalle.vede_cantidad FROM pove_producto_tl, pove_cliente, pove_venta, pove_venta_detalle WHERE pove_cliente.clie_codigo = pove_venta.clie_codigo AND  pove_venta.vent_codigo = pove_venta_detalle.vent_codigo AND pove_venta_detalle.prod_codigo = pove_producto_tl.prod_codigo AND pove_venta_detalle.clie_codigo = pove_CLIENTE.CLIE_codigo and  pove_venta.vent_codigo = '''||p_vent_codigo||''' ORDER BY pove_venta.vent_codigo ASC';


    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_detalle_venta);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;



procedure get_json_valores_desp(p_regi_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

 v_descuento:='SELECT ng.regi_codigo , ng.regi_descripcion, ng.pais_codigo, t.tade_codigo, t.tade_descripcion  FROM pove_pais i, pove_region ng , pove_tarifa_despacho t  WHERE i.pais_codigo = ng.pais_codigo  and ng.tade_codigo = t.tade_codigo and   ng.regi_codigo = '''||p_regi_codigo||''' ORDER BY ng.regi_codigo';


    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_descuento);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;

procedure get_json_ciudades_fac(p_regi_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

 v_descuento:='SELECT r.regi_codigo , r.regi_descripcion, r.pais_codigo, c.ciud_codigo, c.ciud_descripcion,c.cire_codigo   FROM pove_pais i, pove_region r , pove_ciudad c  WHERE i.pais_codigo = r.pais_codigo  and r.regi_codigo = c.regi_codigo and   r.regi_codigo = '''||p_regi_codigo||''' ORDER BY c.ciud_codigo';


    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_descuento);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;



procedure get_json_ciudades(p_regi_codigo  number default null)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

 v_descuento:='SELECT r.regi_codigo , r.regi_descripcion, r.pais_codigo, c.ciud_codigo, c.ciud_descripcion,c.cire_codigo   FROM pove_pais i, pove_region r , pove_ciudad c  WHERE i.pais_codigo = r.pais_codigo  and r.regi_codigo = c.regi_codigo and   r.regi_codigo = '''||p_regi_codigo||''' ORDER BY c.ciud_codigo';


    --htp.p(v_descuento);

   l_jobs_json := json_list();
   l_jobs_json := json_dyn.executeList(v_descuento);

  l_json := json();
l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure get_json_cargar_valores(p_ciud_codigo  number,p_cantidad number)
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_descuento varchar2(2000);
   v_sql     varchar2(2000);
   v_cire_codigo varchar2(100);
   v_tade_codigo varchar2(100);
   v_costo_despacho number;

BEGIN
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

SELECT  c.CIRE_CODIGO,r.tade_codigo   into v_cire_codigo, v_tade_codigo
FROM pove_pais i, pove_region r , pove_ciudad c
WHERE i.pais_codigo = r.pais_codigo
and r.regi_codigo = c.regi_codigo
and c.ciud_codigo = p_ciud_codigo;


select venta_online.f_costo_envio(v_tade_codigo, v_cire_codigo, p_cantidad)  into v_costo_despacho from dual;
g_despacho := v_costo_despacho;

INSERT INTO TMP_DATOS
      (
          VALOR_1,
          VALOR_2,
          VALOR_3
      )
VALUES ('despacho',  g_despacho,  v_costo_despacho);

htp.p('{"data":[{"COSTO_ENVIO":"'||v_costo_despacho||'"}]}');

END;



procedure get_json_std_1 (coleccion in varchar2, texto_busqueda in varchar2 DEFAULT '')
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
   v_autores varchar2(2000);
   v_sql     varchar2(2000);
   v_coleccion    varchar2(2000);
   v_condicion_adicional varchar2(2000);

BEGIN

 owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;
  if trim(texto_busqueda)=''  then
     v_condicion_adicional :='';
  else
    v_condicion_adicional :=' and ( UPPER(a.prod_nombre) like UPPER(''%'||texto_busqueda||'%'')  or  upper((SELECT listagg(auto_nombre, chr(44)) within group (order by auto_nombre) FROM  pove_libros_autores, pove_autor where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo))  like TRANSLATE(UPPER(''%'||texto_busqueda||'%''),''áéíóúàèìòùãõâêîôôäëïöüçÁÉÍÓÚÀÈÌÓÙÃÕÂÊÎÔÛÄËÏÖÜÇ'',''aeiouaeiouaoaeiooaeioucAEIOUAEIOUAOAEIOOAEIOUC'')  )';

   end if;
  v_autores:='(SELECT listagg(auto_nombre, chr(44)) within group (order by auto_nombre) FROM  pove_libros_autores, pove_autor where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo) as autores ';
   -- v_autores:= '1 as autores';
   v_sql:='SELECT a.prod_codigo, a.prod_nombre, a.prod_descripcion, a.prod_precio, a.prod_imagen, a.prod_estado, c.cate_codigo,c.cate_descripcion ,'||v_autores||'  FROM pove_producto_tl a,pove_categoria_producto b,pove_categorias c, pove_libros l    where  a.prod_codigo=b.prod_codigo   and b.tipo_codigo=c.tipo_codigo  and b.prod_codigo = l.prod_codigo and b.cate_codigo=c.cate_codigo  and c.cate_codigo='''||coleccion||''' '||v_condicion_adicional||' and a.prod_estado > 0 and a.prod_precio > 0 order by c.cate_codigo asc, l.libr_codigo desc';




 l_jobs_json := json_list();
 l_jobs_json := json_dyn.executeList(v_sql);

 l_json := json();
 l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure get_json_std_1_resp
 IS

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;

   cursor c1 is
    SELECT a.prod_codigo,a.prod_nombre, a.prod_descripcion, a.prod_precio,
      a.prod_imagen, a.prod_estado, (SELECT wm_concat(auto_nombre)
FROM  pove_libros_autores, pove_autor
where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo) as autores
     FROM pove_producto_tl a where  a.prod_precio is not null;

  fila   c1%rowtype;

BEGIN

      owa_util.mime_header('application/json',false, g_charset);
      OWA_UTIL.http_header_close;


    l_jobs_json := json_list();
    l_employee_json := json();

    FOR fila IN c1 LOOP
          l_json := json();
           l_json.put('prod_codigo', fila.prod_codigo);
           l_json.put('prod_nombre', fila.prod_nombre);
           l_json.put('prod_descripcion', fila.prod_descripcion);
           l_json.put('prod_precio', fila.prod_precio);
           l_json.put('prod_imagen', fila.prod_imagen);
           l_json.put('prod_estado', fila.prod_estado);
           l_json.put('autores', fila.autores);

           l_jobs_json.append(l_json.to_json_value);


    end loop;


   l_employee_json.put('data', l_jobs_json.to_json_value);

  l_employee_json.htp();

--htp.p(l_jobs_json.count());

END;


procedure get_json_std_personas
 IS

    l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;


BEGIN

  owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;

 l_jobs_json := json_list();
 l_jobs_json := json_dyn.executeList('SELECT * from utalca.rem_contrato where rol_emp=''12968261''');

 l_json := json();
 l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();




END;

 function no_print_symbols(str varchar2) return varchar2 as
    eol constant varchar2(10) := CHR(13) || CHR(10);
  begin
    return replace(replace(replace(replace(str, '\n', ''), CHR(13), ''), CHR(10), ''),'"','');
  end;




procedure get_combos(codigo in varchar2, descripcion in varchar2 , tablas in varchar2, condicion in varchar2,codigo_adic in varchar2 default '' ) is

  TYPE CUR_TYP IS REF CURSOR;
  c_cursor   CUR_TYP;
  vxml varchar2(32000);
  consulta_ejec   VARCHAR2(4000);
  condicion1 varchar2(2000);
  v_atributo_adic varchar2(200):='';

begin

 IF condicion IS NULL THEN
    condicion1:='';
 ELSE
    condicion1:=' where '||condicion;
 END IF;

 if codigo_adic<>'' then
   v_atributo_adic:='dato_adic='||codigo_adic;
 end if;

consulta_ejec:='select '||chr(39)||'<option '||v_atributo_adic||' value="'||chr(39)||'||'||codigo||'||'||chr(39)||'">'||chr(39)|| '||'||descripcion||'||' ||chr(39)||'</option>'||chr(39)||' as eldatofinal from '||tablas ||condicion1;
  OPEN c_cursor FOR consulta_ejec;
  LOOP
    FETCH c_cursor INTO vxml;
    EXIT WHEN c_cursor%NOTFOUND;
     htp.prn(vxml);
  END LOOP;

  CLOSE c_cursor;


end;



procedure menu_ubicacion(v_menu_id in NUMBER) is



cursor cur_menu_ubica is
 SELECT 2 as posicion, menu_nombre FROM gene_menu WHERE menu_id=v_menu_id union SELECT 1 as posicion, menu_nombre FROM gene_menu WHERE menu_id= (    SELECT menu_grupo FROM gene_menu WHERE menu_id=v_menu_id) order by posicion;

begin

htp.p(' <div class="row wrapper border-bottom white-bg page-heading">
                <div class="col-lg-10">
                    </br>
                    <ol class="breadcrumb">');

                        if (v_menu_id=0)  then


                         HTP.p
                            (   '<li>
                                     <a href="">Inicio</a>
                                  </li>'
                            );
                        end if;

                    FOR fila IN cur_menu_ubica LOOP


                        htp.p('
                        <li>
                            <a>'||fila.menu_nombre||'</a>
                        </li>



                        ');
                    end loop;


                    htp.p('</ol>
                </div>
                <div class="col-lg-2">

                </div>
            </div>');

end;


procedure menu (v_menu_id in NUMBER) is


--consulta_menu  varchar2(1000);
v_menu_grupo  varchar2(3);
v_linkmenu  vec_cob03.gene_menu.menu_link%type;
v_clase_menu varchar2(100);
vrut           VARCHAR2 (15):= vec_cob03.web_util.get_cookie ('SESSION_RUT');



      CURSOR cursore
      IS
         --   SELECT * FROM dtt_menu where menu_nivel=1 order by menu_orden;
         SELECT   *
             FROM gene_menu
            WHERE menu_nivel = 1
              AND menu_id IN (SELECT menu_id
                                FROM gene_perfil_menu a
                               WHERE a.perf_id IN (SELECT perf_id
                                                     FROM gene_usuario_perfil
                                                    WHERE usua_rut = vrut))
         ORDER BY menu_id;


      CURSOR cursora
      IS
         SELECT *
           FROM gene_menu
          WHERE menu_id = v_menu_id;


      CURSOR cursore_sub (x NUMBER)
      IS

         SELECT   *
             FROM gene_menu
            WHERE menu_nivel = 2
              AND menu_grupo = x
              AND menu_id IN (SELECT menu_id
                                FROM gene_perfil_menu a
                               WHERE a.perf_id IN (SELECT perf_id
                                                     FROM gene_usuario_perfil
                                                    WHERE usua_rut = vrut))
         ORDER BY menu_id;


BEGIN

    IF (v_menu_id != '0')
        THEN
            FOR m_cursora IN cursore
            LOOP
                v_menu_grupo := m_cursora.menu_grupo;
            END LOOP;
   ELSE
        v_menu_grupo :='0';
   END IF;
       htp.p('<li class="special_link">
                        <a href="VENTA_ONLINE.principal?m=0"><i class="fa fa-home"></i> <span class="nav-label">Inicio</span></a>
             </li>');

      FOR m_cursor IN cursore
      LOOP
         IF (m_cursor.menu_hoja = 1)
         THEN
            v_linkmenu := m_cursor.menu_link;
                    htp.p('<li class="special_link">
                        <a href="'||v_linkmenu||'?m='||m_cursor.MENU_ID||'">
                        <i class="'||m_cursor.MENU_IMAGEN||'"></i>
                        <span class="nav-label">'||m_cursor.MENU_NOMBRE||'</span></a>
                    </li>');
         ELSE
            v_clase_menu := '';                --se limpia la variable arriba
            v_clase_menu := 'class="menu_padre"';

            IF (m_cursor.menu_id = v_menu_grupo)
            THEN
               v_clase_menu := 'class="active menu_padre"';
            END IF;

             htp.p('<li '||v_clase_menu||'>
            <a href="'||v_linkmenu||'"><i class="'|| m_cursor.MENU_IMAGEN||'"></i> <span class="nav-label">'||m_cursor.MENU_NOMBRE||'</span><span class="fa arrow"></span></a>
                        <ul class="nav nav-second-level">');

            FOR m_cursor_sub IN cursore_sub (m_cursor.menu_id)
            LOOP
               v_clase_menu := '';             --se limpia la variable arriba

               IF (m_cursor_sub.menu_id = v_menu_id)
               THEN
                  v_clase_menu := 'class="active"';
               END IF;

                  htp.p('<li '||v_clase_menu||'><a href="'||m_cursor_sub.MENU_LINK||'?m='||m_cursor_sub.MENU_ID||'">'||m_cursor_sub.MENU_NOMBRE||'</a></li>');

            END LOOP;

            HTP.p ('</ul>
                            </li>');
         END IF;
      END LOOP;                                                      --cursore
   EXCEPTION
      WHEN OTHERS
      THEN
       htp.p('<li class="special_link">
                        <a href="VENTA_ONLINE.principal?m=10"><i class="fa fa-home"></i> <span class="nav-label">Inicio</span></a>
              </li>');
   END;




procedure estilos_editorial is

begin

    htp.p('
         <link href="'||path_inspinia||'css/estilos2.css" rel="stylesheet">
         <link href="'||path_inspinia||'css/estilos.css" rel="stylesheet">
         <link href="'||path_inspinia||'thickbox/css/thickbox.css" type="text/css" media="screen">


    ');


end;


procedure modal_desc_libro is
--(v_libro_id in NUMBER)

p_prod_codigo pove_producto_tl.prod_codigo%type;
v_prod_nombre  pove_producto_tl.prod_nombre%type;
v_prod_descripcion pove_producto_tl.prod_descripcion%type;
v_prod_precio pove_producto_tl.prod_precio%type;
v_prod_imagen pove_producto_tl.prod_imagen%type;



begin

htp.p('<style type="text/css">

.valor {
    color: #FFF;
    font-family: Arial, Helvetica, sans-serif;
    font-size: 18px;
    font-weight: normal;
    text-decoration: none;
}


.texto_precio {
    background-color: #7a7873;
    color: white;
}


#fondo {
    background-image: url(''http://inet.utalca.cl/inspinia/img/fondo_pg.jpg'');
}


.tit_fichas {
    color:#000;
    font-size:14px;
    font-weight:normal;
    text-decoration:none;
    }

.nombre_fichas {
    color:#779817;
    font-size:14px;
    font-weight:normal;
    text-decoration:none;
    }

.textos2 {
    font-size:11px;
    font-weight: bold;
    text-decoration:none;
    color:#000;
    line-height:14px;
    }

    .valor2 {
    color:#FFF;

    font-size:14px;
    font-weight:bold;
    text-decoration:none;
    }
/*input[type=text] {
    background-color: #7a7873;
    color: white;
}*/


</style>

<script type="text/javascript">

function valida_ingreso(e){
  var key = window.Event ? e.which : e.keyCode;
  var a = document.getElementById("modal_prod_cantidad");
  if (a.value == "") {
      return (key);
  }
  return (key);
}


</script>

<script>

//valida solo numeros
function solonumeros(e)
{
    key = e.keyCode || e.which;

    teclado = String.fromCharCode(key);

    numeros =''0123456789'';

    especiales=''8-37-38-46'';

    teclado_especial = false;

    for (var i in especiales){

        if(key==especiales[i]){
            teclado_especial = true;

        }
    }

    if(numeros.indexOf(teclado)==-1 && !teclado_especial){
        return false;
    }

}
</script>


'
);

htp.p('
    <div class="modal inmodal" id="ModalDetalles"  tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg"  >
                <div class="modal-content animated bounceInRight">
                    <div class="modal-body" id ="fondo">


');

    htp.p('

<table width="800" border="0" align="center" cellpadding="0" cellspacing="20" bgcolor="#FFFFFF">
  <tbody><tr>
    <td width="157" align="center" bgcolor="#FFFFFF"><img src="'||ruta_imagen||'jorge_volpi.png" id="modal_prod_imagen" width="157" height="223"></td>
    <td width="571" valign="middle" bgcolor="#FFFFFF"><p><textarea style="visibility:hidden" rows="1" cols="65" style="border:0;" id="modal_prod_codigo" name="modal_prod_codigo"></textarea><strong><textarea rows="2" cols="59" style="border:0;" id="modal_prod_nombre" name="modal_prod_nombre" readonly></textarea></strong><br />

      <span class="textos"><br>
        <br>
    </span><span class="nombre_fichas"><strong id="modal_autores">** </strong></span></p>
      <table width="219" border="0" cellspacing="0" cellpadding="0">
        <tbody><tr>
          <td colspan="2"><table width="219" border="0" cellpadding="0" cellspacing="3" class="valor">
            <tbody><tr id ="trAgotado" style="display:none">
                 <td width="107" align="center" bgcolor="#7a7873"  id="modal_prod_precio" >*</td>
              <td width="74" align="center" bgcolor="#d2d29d" class="valor2">Cantidad</td>
              <td align="center" bgcolor="#7a7873"><input class="texto_precio" type="text" size="2" value="1" onkeyup=''return valida_ingreso(event);'' onblur=''validar_blur_cantidad_modal();'' onkeypress=''return solonumeros(event)''  maxlength=''2'' id="modal_prod_cantidad"  name="modal_prod_cantidad" ></td>
            </tr>
            <tr id="mostrarAgo" width="74" style="display:none">
                 <td   align="center" ><h1 class="text-danger">AGOTADO</h1></td>
            </tr>
          </tbody></table>
          </td>
        </tr>
        <tr>
          <td>&nbsp;</td>
          <td>&nbsp;</td>
        </tr>
        <tr id="btnAgregar" style="display:none" >
          <td colspan="2"><a target="_parent" id="btn_carrito" name="btn_carrito"><img src="http://inet.utalca.cl/inspinia/img/carrito.jpg" width="219" height="37"></a></td>
        </tr>
      </tbody></table></td>
        <div class="col-lg-1 col-lg-offset-11">
      <div class="row">
          <button class="btn btn-primary btn-circle btn-md" type="button" data-dismiss="modal" ><i class="fa fa-times fa-5"></i></button>

      </div>
      &nbsp;
    </div>
  </tr>
  <tr>
    <td colspan="2" bgcolor="#FFFFFF">
        <p  id="modal_prod_codigo" style="visibility: hidden;"></p>

                                <div class="panel blank-panel"  >
                                    <div class="panel-heading info" >
                                        <div class="panel-options">
                                            <ul class="nav nav-tabs">
                                                <li class="active"><a data-toggle="tab" href="#tabulador-1" aria-expanded="true"><i class="fa fa-info-circle"></i>&nbsp;Descripcion</a></li>
                                                <li class=""><a data-toggle="tab" href="#tabulador-2" aria-expanded="false"><i class="fa fa-tasks"></i>&nbsp;Ficha Tecnica</a></li>
                                            </ul>
                                        </div>
                                    </div>
                                    <div class="panel-body " style=" background-color:#f3f3f4;  max-height: 200;overflow-y: scroll;" >
                                        <div class="tab-content"    >
                                            <div id="tabulador-1" class="tab-pane active">
                                                 <p align=''justify'' id="modal_prod_descripcion">*</p>
                                                 </br>
                                                 </br></br></br></br></br></br></br></br>
                                            </div>
                                            <div id="tabulador-2" class="tab-pane">
                                                <table class="table">
                                                    <thead>
                                                      <tr>
                                                        <th><font><font></i>Atributos</font></font></th>
                                                        <th><font><font>Detalle</font></font></th>
                                                      </tr>
                                                    </thead>
                                                    <tbody>
                                                      <tr>
                                                        <td><h5><font><font>Colección</font></font></h5></td>
                                                        <td><h5  id="modal_coleccion"> </h5></td>
                                                      </tr>
                                                      <tr>
                                                        <td><h5><font><font>Numeros de Paginas</font></font></h5></td>
                                                        <td><h5  id="modal_num_paginas"> </h5></td>
                                                      </tr>
                                                      <tr>
                                                        <td><h5><font><font>Año del libro</font></font></h5></td>
                                                        <td><h5  id="modal_agno"></h5></td>
                                                      </tr>
                                                      <tr>
                                                        <td><h5><font><font>Isbn</font></font></h5></td>
                                                        <td><h5  id="modal_isbn"> </h5></td>
                                                      </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div>


    </td>
  </tr>
</tbody>
</table>');
info_editorial;
htp.p('
                </div>
       </div>
    </div>
</div>


');

htp.p('
<script src="'||path_inspinia||'js/jquery-latest.js"></script>
<script>


function agregar_compra(){

    actualizar_precio (v_libros_1,v_cantidad_1)
calcular_total_venta();
    location=''venta_online.carrito_compra'';

}

</script>













    ');
end;

   PROCEDURE pie_pagina_editorial
   IS
   BEGIN

      HTP.p('

    <br>
    <br>
      <footer class="col-md-12" class="clase-general">

     <tr>
                     <div class="col-lg-offset-5 col-lg-7">
                     <br>
                     <br>
                     <div class="">
                        <h3><font><font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Soporte de los navegadores</font></font></h3>

                        <img src="'||ruta_imagen||'compatibilidad_navegadores.png" width="280" height="52" alt="Probado y apoyado en Chrome, Safari, Firefox, Internet Explorer y Opera." title="Probado y apoyado en Chrome, Safari, Firefox, Internet Explorer y Opera.">
                           <ul class="u">
                              <li><font><font class="">últimas Chrome</font></font></li>
                              <li><font><font>Las últimas Safari</font></font></li>
                              <li><font><font class="">última versión de Firefox</font></font></li>
                              <li><font><font class="">Internet Explorer 8/9/10/11</font></font></li>
                              <li><font><font>Las últimas Opera</font></font></li>
                           </ul>
                     </div>
     </tr>
       </footer>

          ');
   END;



procedure panel_carrito_tab1 is

cantidad_cookie OWA_COOKIE.cookie;
libros_cookie OWA_COOKIE.cookie;
nombre_libros_cookie OWA_COOKIE.cookie;


begin

   libros_cookie := OWA_COOKIE.get ('libros');
 --  nombre_libros_cookie := OWA_COOKIE.get ('nombre_libros');
   cantidad_cookie := OWA_COOKIE.get ('cantidad');

      htp.p('

<style type="text/css">
#sty_center {
    align: center;

}
a.opcion{font-size:20px}

a.opcion{text-decoration:none; color:#C2431A; font-size:20px; display:inline-block; margin-right:5px}
a.opcion:hover{color:#C2431A}
a.opcion:last-child{margin-right:0}
</style>
');

    htp.p('
           <div id="tab-1" class="tab-pane active" >
                 <div id="lista_l_carrito" style=" background-color:#f3f3f4;  max-height: 235;overflow-y: scroll;" >
                 </div>

                 <table class=''table invoice-total''>
                     <tbody>
                         <tr>
                             <td><strong>SubTotal Productos :</strong></td>
                             <td>$<span id=''v_total''></span></td>

                         </tr>
                     </tbody>
                 </table>
                 <table>
                      <tr>
                         <td ><span class=''changed''  Style=''Display:none;''  id=''c_cantidad_total'' ></span></td>
                      </tr>
                 </table>
                 <div class=''hr-line-dashed''></div>
                 <div class="well m-t"><strong></strong>
                 <div class="col-md-2 ">
                      <a onclick="goBack();" class="alert-link lg" ><strong>SEGUIR COMPRANDO</strong></a>
                 </div>
                 <div class="col-md-2 col-md-offset-8">
                    <button id="btn_continuar"  name="btn_continuar"  onclick=''actual_cant_total("+value.PROD_CODIGO+");'';type="button" class="btn btn-white btn-md"  aria-expanded="false" style="background:#769900; color:#FFFFFF;" ><i class="fa fa-arrow-right"></i> CONTINUAR </button>
                 </div>
                 <br>
                 <br>
             </div>
             </br>
             </br>
           </div>
    <!-- Div modal para mostrar y editar detalles -->
        <div class="modal inmodal" id="ModalCompra" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content animated bounceInRight">
                    <div class="modal-header">
                    <!--<i class="fa fa-book fa-6"></i>-->
                        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
                        <i class="fa fa-book modal-icon"></i>
                        <h4 class="modal-title">Venta de libros Online</h4>
                        <small class="font-bold">Universidad de Talca</small>
                    </div>
                    <div class="modal-body">
                        <p>Estimado Cliente: en esta ocasión no podemos continuar con su compra, debido a que en transacciones superiores a 29 unidades, debe dirigirse en forma presencial o contactarse con nuestra editorial vía correo electrónico.<br><br><br></p>

                         <strong>Correo electrónico:</strong><a href="">&nbsp;&nbsp;editorial@utalca.cl</a> / <a href="">&nbsp;&nbsp;vhillmer@utalca.cl</a><br><br>
                         <strong>Fono:</strong> 71 2 200154<br><br>
                         <strong>Dirección:</strong> 1 poniente 1141, Talca


                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-primary" id="Btn_GuardaryCerrarModal" onclick="return Guardar_y_cerrar_modal();" ><i class="fa fa-close"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>
        <!-- Div modal para mostrar y editar detalles -->




           ');

htp.p('
    <script>

          function goBack() {
          document.location.href=''venta_online.portal_ventas?s=1'';
        }
        function Guardar_y_cerrar_modal(){

            $("#ModalCompra").modal("toggle");
        }
    </script>




<script type="text/javascript">

function valida_ingreso(e,pos){
    var key = window.Event ? e.which : e.keyCode;
    var a = document.getElementById("c_cantidad_"+pos);
    
    if (a.value == "") {
        return (key);
    }
    
    var val = parseInt(a.value);
    if (!isNaN(val) && val > 0) {
        actual_cant_total();
    }
    return (key);
}

function validar_blur_cantidad_modal() {
    var a = document.getElementById("modal_prod_cantidad");
    if (a.value == "" || parseInt(a.value) <= 0 || isNaN(parseInt(a.value))) {
        a.value = "1";
    }
}

function validar_blur_cantidad(pos) {
    var a = document.getElementById("c_cantidad_" + pos);
    if (a.value == "" || parseInt(a.value) <= 0 || isNaN(parseInt(a.value))) {
        bootbox.confirm("¿Está seguro que desea eliminar el libro seleccionado del carrito?", function(result) {
            if (result) {
                eliminar_libro(pos);
            } else {
                a.value = "1";
                resfrescar_tab();
            }
        });
    } else {
        resfrescar_tab();
    }
}
</script>
<script>

//valida solo numeros
function solonumeros(e)
{
    key = e.keyCode || e.which;

    teclado = String.fromCharCode(key);

    numeros =''0123456789'';

    especiales=''8-37-38-46'';

    teclado_especial = false;

    for (var i in especiales){

        if(key==especiales[i]){
            teclado_especial = true;

        }
    }

    if(numeros.indexOf(teclado)==-1 && !teclado_especial){
        return false;
    }

}
</script>

<script>
var changed = $(''.changed'');
changed.on(''DOMSubtreeModified'', function(e){
     if(document.getElementById("c_cantidad_total").innerHTML > 29){
                   $("#ModalCompra").modal("toggle");
                   return false;
     }

});

</script>


<script>

  $(document).ready(function(){
  var a="";
  var url_json="venta_online.json_libros_carrito?v_lista_libros='||libros_cookie.vals(1)||'";
   $.getJSON(url_json, function(response) {

a=a+"   <table class=''table''>" +
"       <tr>                             " +
"           <th width=''50''>&nbsp;</th>     " +
"           <th>Lista Productos</th>     " +
"           <th>Cantidad</th>            " +
"           <th>Precio Unidad</th>       " +
"           <th>Precio Total</th>        " +
"       </tr>                            ";




    $.each(response.data, function(key, value){


    a=a+"<tr id=''eliminar_li_"+value.PROD_CODIGO+"''>" +
"<td><a title=''Eliminar'' class=''opcion'' onclick=''eliminar_libro("+value.PROD_CODIGO+");''><i class=''fa fa-remove''></i></a></td>" +
"   <td>" +
"   <img WIDTH=40 HEIGHT=40 src=''http://inet.utalca.cl/inspinia/img/editorial/"+value.PROD_IMAGEN+"'' class=''img-square'' alt=''image''>" +
"   <strong >"+value.PROD_NOMBRE+"</strong></td>" +
"   <td id=''actualizar_li_"+value.PROD_CODIGO+"''><input type=''hidden'' size=''2'' value=''"+value.PROD_CODIGO+"'' id=''c_cod_libro''  name=''c_cod_libro'' > <input type=''text'' size=''2''   onkeyup=''return valida_ingreso(event,"+value.PROD_CODIGO+");''  maxlength=''2'' onblur=''validar_blur_cantidad("+value.PROD_CODIGO+");'' onkeypress=''return solonumeros(event);''  id=''c_cantidad_"+value.PROD_CODIGO+"''  name=''c_cantidad_"+value.PROD_CODIGO+"'' class=''libro_"+value.PROD_CODIGO+"'' value=''1''></td> " +
"   <td>$<span id=''precio_libro_"+value.PROD_CODIGO+"''>"+value.PROD_PRECIO+"</span></td>             " +
"   <td>$<span id=''total_libro_"+value.PROD_CODIGO+"''></span></td> " +
"</tr>";


    });

 a=a+"</table>";



         document.getElementById("lista_l_carrito").innerHTML=a;
        actualizar_precio('''||libros_cookie.vals(1)||''','''||cantidad_cookie.vals(1)||''');


});


});

function Limpiar()
{

    var sAux="";
    var frm = document.getElementById("div_cliente");
    if (frm) {
        for (i=0;i<frm.elements.length;i++)
        {


            var str=frm.elements[i].name;
            if (frm.elements[i].type==''textarea'' || frm.elements[i].type==''text'' && str.indexOf("txt_")>=0  )
            {

                        frm.elements[i].value='''';
                }
            if (frm.elements[i].type==''select-one'')
            {
                $(''#''+frm.elements[i].name).val(-1);
                $(''#''+frm.elements[i].name).trigger("chosen:updated");

            }

        }
    }
}


function resfrescar_tab(){

        document.getElementById("myDIV").style.display = "none";
         actual_cant_total();
          var v_subtotal =eval(document.getElementById("v_total").innerHTML);
          document.getElementById("v_total_descuento").innerHTML=0;
          document.getElementById("v_valor_despacho").innerHTML=0;
          document.getElementById("v_total_compra").innerHTML=0;
          document.getElementById("v_subtotalprod").innerHTML=v_subtotal;
          calcular_total_venta();

}


function actualizar_precio (v_libros_1,v_cantidad_1){
         var array_libros = v_libros_1.split("@");
         var array_cantidad = v_cantidad_1.split("@");

         // 1. Agrupar cantidades por prod_codigo para manejar posibles duplicados heredados
         var cantidades_por_libro = {};
         for (var i = 1; i < array_libros.length; i++) {
             var cod = array_libros[i];
             var cant = parseInt(array_cantidad[i]) || 0;
             if (cod) {
                 cantidades_por_libro[cod] = (cantidades_por_libro[cod] || 0) + cant;
             }
         }

         // 2. Asignar las cantidades agrupadas a los inputs en el DOM
         for (var cod in cantidades_por_libro) {
             var input = document.getElementById("c_cantidad_" + cod);
             if (input) {
                 input.value = cantidades_por_libro[cod];
             }
         }

         // 3. Recorrer los libros en el DOM y calcular subtotales y total general
         var sumatotal = 0;
         var cantidad_total = 0;
         var inputs_cod = document.getElementsByTagName("input");
         
         for (var i = 0; i < inputs_cod.length; i++) {
             if (inputs_cod[i].id == "c_cod_libro") {
                 var cod = inputs_cod[i].value;
                 var input_cant = document.getElementById("c_cantidad_" + cod);
                 var span_precio = document.getElementById("precio_libro_" + cod);
                 var span_total = document.getElementById("total_libro_" + cod);
                 
                 if (input_cant && span_precio && span_total) {
                     var cant = parseInt(input_cant.value) || 0;
                     var precio = parseInt(span_precio.innerHTML) || 0;
                     var subtotal = cant * precio;
                     
                     span_total.innerHTML = subtotal;
                     sumatotal += subtotal;
                     cantidad_total += cant;
                 }
             }
         }

         // 4. Actualizar totales en la pantalla
         var span_cant_total = document.getElementById("c_cantidad_total");
         if (span_cant_total) {
             span_cant_total.innerHTML = cantidad_total;
         }
         
         var span_total_gral = document.getElementById("v_total");
         if (span_total_gral) {
             span_total_gral.innerHTML = sumatotal;
         }

         calcular_total_venta();
}


    function actual_cant_total(){


                        var v_textos=  document.getElementsByTagName("input");
                        var ll;
                         var v_libros_nuevos='''';
                         var v_cantidades_nuevas='''';
                         var v_cantidad_total='''';


                        //  alert(v_textos.length+'' textos'');

                            for (ll = 0; ll < v_textos.length; ll++) {



                                if (v_textos[ll].id==''c_cod_libro'')
                                {

                                   v_libros_nuevos=v_libros_nuevos+''@''+v_textos[ll].value;
                                }
                                else
                                 {        str=v_textos[ll].id;
                                           var n = str.indexOf(''c_cantidad_'');

                                          //alert(str + '':''+n);
                                         if (n !=-1)
                                        {
                                           v_cantidades_nuevas=v_cantidades_nuevas+''@''+v_textos[ll].value;

                                        }
                                       // v_cantidad_total=v_cantidades_nuevas;




                                 }
                              }


                actualizar_precio (v_libros_nuevos,v_cantidades_nuevas);

                calcular_total_venta();


            return true;
    }



function eliminar_libro(codigo){

 bootbox.confirm(" Esta seguro que desea eliminar el libro seleccionado? ", function(result) {

                        $("#eliminar_li_"+codigo).remove();
                        //document.getElementById("eliminar_li_"+codigo).remove();
                        var v_cantidad=  document.getElementsByTagName("input");


                         var ll;
                         var v_libros_nuevos='''';
                         var v_cantidades_nuevas='''';
                            for (ll = 0; ll < v_cantidad.length; ll++) {
                                if (v_cantidad[ll].id==''c_cod_libro'')
                                {

                                   v_libros_nuevos=v_libros_nuevos+''@''+v_cantidad[ll].value;
                                }
                                else
                                {


                                         str=v_cantidad[ll].id;
                                         var n = str.indexOf(''c_cantidad_'');
                                         if (n !=-1)
                                        {

                                           v_cantidades_nuevas=v_cantidades_nuevas+''@''+v_cantidad[ll].value;
                                        }
                                }
                            }



                               var v_data = ''v_libros=''+v_libros_nuevos +''&v_cantidad=''+v_cantidades_nuevas+''&v_limpiacookie=1'';

                                           $.ajax({
                                               url:''venta_online.escribir'',
                                               type:''GET'',
                                               data: v_data,

                                               success:function(response){

                                               actualizar_precio(v_libros_nuevos,v_cantidades_nuevas);
                                               calcular_total_venta();


                                                }



                                        });

                        return true;

                        });


    }
   var id='''';
   $(document).ready(function(){

        $(''.nav li'').not(''.active'').addClass(''disabled'');
        $(''.nav li'').not(''.active'').find(''a'').removeAttr("data-toggle");

    var v_desc_comuni = '''';
    var v_descuento_aplicado= '''';

    $("#btn_continuar").click ( function (e)
    {
          e.preventDefault();
          
          var v_libros_nuevos = "";
          var v_cantidades_nuevas = "";
          var v_textos = document.getElementsByTagName("input");
          var vistos = {};
          for (var ll = 0; ll < v_textos.length; ll++) {
              if (v_textos[ll].id == ''c_cod_libro'') {
                  if (!vistos[v_textos[ll].value]) {
                      v_libros_nuevos = v_libros_nuevos + ''@'' + v_textos[ll].value;
                      var cod = v_textos[ll].value;
                      var cant_input = document.getElementById(''c_cantidad_'' + cod);
                      v_cantidades_nuevas = v_cantidades_nuevas + ''@'' + (cant_input ? cant_input.value : 0);
                      vistos[v_textos[ll].value] = true;
                  }
              }
          }

          var v_data = ''v_libros='' + v_libros_nuevos + ''&v_cantidad='' + v_cantidades_nuevas + ''&v_limpiacookie=1'';
          //alert(v_data);
           $.ajax({
                   url:''venta_online.escribir'',
                   type:''GET'',
                   data: v_data,

                   success:function(response){
                            calcular_total_venta();
                           if(document.getElementById("c_cantidad_total").innerHTML > 29){
                                         $("#ModalCompra").modal("toggle");
                                         return false;

                           }
                           if(document.getElementById("v_total").innerHTML == 0){
                                 toastr.warning(''Debe agregar un libro al carrito de compra.'');
                                 return false;

                           }

                          e.preventDefault();
                          document.getElementById("btn_continuar").disabled = false;
                          var v_centro_responsabilidad = ''VEX700008'';
                          var v_centro_resp_edit =v_centro_responsabilidad;


                          var v_subtotal =eval(document.getElementById("v_total").innerHTML);
                          document.getElementById("v_total_descuento").innerHTML=0;
                          document.getElementById("v_valor_despacho").innerHTML=0;
                          document.getElementById("v_total_compra").innerHTML=0;
                          document.getElementById("v_centro_costo").innerHTML=v_centro_resp_edit;
                          document.getElementById("v_subtotalprod").innerHTML=v_subtotal;
                          calcular_total_venta();

                          document.getElementById("myDIV").style.display = "none";
                          Limpiar();

                                 $(''.nav li.active'').next(''li'').removeClass(''disabled'');
                                 $(''.nav li.active'').next(''li'').find(''a'').attr("data-toggle","tab").tab(''show'');

                                 $(''.nav li'').next(''.active'').addClass(''disabled'');
                                 $(''.nav li'').next(''.active'').find(''a'').removeAttr("data-toggle");


            }

        });


    });


 });
   </script>


<script language="javascript">
function mostrar(num){
if (document.getElementById(''a''+num).style.display==''inline'')
{
  document.getElementById(''a''+num).style.display=''none'';
}
else
{
  document.getElementById(''daiv''+num).style.display=''inline'';
  for (i=0;ele=document.opcion.elements[i];i++)
  {
    if(ele.name.indexOf(''a'') != -1)
      {
        ele.style.display=''none'';
      }
  }
}
}


</script>

        ');

end;

procedure barra_busqueda is

begin
    compatibilidad_navegadores;
    banner_editorial;
    htp.p('
    <div class="col-lg-offset-2 col-lg-8">
        <div class="search-form">
          <br>
          <br>
          <br>
            <div class="input-group">
                <input type="text" placeholder="Ingrese Libro o Autor a Buscar" name="search" id="search" class="form-control input-lg">
                <div class="input-group-btn">
                    <button class="btn btn-lg btn-primary" type="button" onclick="cargar_libros();">
                        Buscar libro
                    </button>
                </div>
            </div>
        </div>
    </div>
    ');
end;

PROCEDURE compatibilidad_navegadores is
begin

    htp.p('
            <div class="col-lg-offset-9 col-lg-3">
                       <div class="navbar-header">
                            <tr>
                                <td class="tooltip-demo"><img src="'||ruta_imagen||'navegadores/browser_logos.png" width="108" height="20" usemap="#Map1" border="0">
                                 <map name="Map1">
                                   <area shape="rect" coords="1,1,17,19" data-toggle="tooltip" data-placement="bottom" title="Ultimas de Chrome">
                                   <area shape="rect" coords="23,4,39,19" data-toggle="tooltip" data-placement="bottom" title="Ultimas de safari">
                                   <area shape="rect" coords="43,1,60,19" data-toggle="tooltip" data-placement="bottom" title="Ultimas de fox">
                                   <area shape="rect" coords="66,2,84,19" data-toggle="tooltip" data-placement="bottom" title="Internet Explorer 8/9/10/11">
                                   <area shape="rect" coords="90,1,105,19" data-toggle="tooltip" data-placement="bottom" title="Ultimas de opera">
                               </map></td>
                            </tr>
                        </table>
                    </div>
                </div>
          ');
end;


procedure test_header is
v_dato varchar2(255);
Resta number;

tiempo_permitido number;
begin
   tiempo_permitido:=0.00002;
   v_dato:=v_dato||utal_dti.p_encrypt_utal.decrypt_ssn(OWA_UTIL.GET_CGI_ENV('HTTP_AUTHORIZATION'));

   Resta :=sysdate - To_Date(v_dato, 'dd/mm/yyyy hh24:mi:ss');

   if  Resta < tiempo_permitido then
        htp.p('Dato:'||v_dato|| ' Resta '||Resta);
        htp.p('fecha:'||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'));
        else
         htp.p('Error'||Resta||'*');
   end if;
end;

PROCEDURE SOL_HEADER IS
BEGIN

htp.p(SYS_CONTEXT('USERENV', 'IP_ADDRESS', 15));

HTP.P('
<!DOCTYPE html>
<html>
<head>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script>

var autorizacion="'||utal_dti.p_encrypt_utal.encrypt_ssn(to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'))||'";
$(document).ready(function(){
    $("button").click(function(){
        $.ajax({
        url: "VENTA_ONLINE.test_header",
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

');
END;


function imagenes_aleatorias return varchar2 is

    l_seed   VARCHAR2(100);

cursor cur_imagenes is
select  prod_nombre, prod_imagen from (
SELECT *   FROM    pove_producto_tl  ORDER BY DBMS_RANDOM.RANDOM

)
where rownum<17;

lista_imagenes varchar2(4000);
begin
 l_seed := TO_CHAR(SYSTIMESTAMP,'YYYYDDMMHH24MISSFFFF');
 DBMS_RANDOM.seed (val => l_seed);
 lista_imagenes:='';
 FOR fila IN cur_imagenes LOOP

     lista_imagenes:=lista_imagenes ||fila.prod_imagen||',';
 end loop;
return (lista_imagenes);

end;




procedure panel_carrito_tab2 is

    v_prod_id                       varchar2(20):='26';
    v_cli_cod_carrera               varchar2(100)  :='SD';
    v_cli_sexo                      varchar2(100)  :='2';
    v_cli_tratamiento               varchar2(100)  :='0003';
    v_cli_agrupacion                varchar2(100)  :='ZC01';
    v_cli_cod_giro                  varchar2(100)  :='PRUEBA';
    v_cli_rubro                     varchar2(100)  :='PRUEBA';
    v_cli_canal_distribucion        varchar2(100)  :='03';

    l_cli_json_con          json;
    v_rut_clie              varchar2(13);--:='13110906-7'
    v_nombre_pila           varchar2(100);
    v_direccion             varchar2(100);
    v_direc_numero          varchar2(100);
    v_email_sap             varchar2(100);
    v_telefono              varchar2(100);
    v_ret1                  varchar2(100):='1';
    v_msg1                  varchar2(100):='';
begin


 /* l_cli_json_con := utsap001.pkg_integra_utal.int_sap10_json(v_rut_clie , v_cli_canal_distribucion , v_ret1 ,v_msg1);




        v_nombre_pila  :=lee_json(l_cli_json_con , 'cli_nombre');
        v_direccion    :=lee_json(l_cli_json_con , 'cli_direccion');
        v_direc_numero :=lee_json(l_cli_json_con , 'cli_numero');
        v_email_sap    :=lee_json(l_cli_json_con , 'cli_email');
        v_telefono     :=lee_json(l_cli_json_con , 'cli_telefono');*/

      htp.p('

<head>

</head>


<script>



$(document).ready(function(){

      $(".solonumero").keypress(function( event ) {
           var charCode = (event.which) ? event.which : event.keyCode;
               if (charCode > 31 && (charCode < 48 || charCode > 57))
               {
                    event.preventDefault();
               }
      });

});

</script>








    <script src="'||path_inspinia||'js/jquery-latest.js"></script>
  ');
    htp.p('
           <div id="tab-2" class="tab-pane" data-toggle="tab">
                  <div class="row">
                   <form id="div_cliente"   action="'||ruta_imagen_libros||'html2pdf/boleta.php" target="_blank" method="POST"  >
                       <label class="'||v_ancho_columna1||' control-label">Rut:</label>
                       <div class="'||v_ancho_columna1||'">
                            <input  placeholder="ejem: 11111111-1"  maxlength="10" class=" form-control obligatorio" value="" id="txt_clie_rut" name="txt_clie_rut" >
                      <br>
                      <br>
                      </div>
                      <div class="'||v_ancho_columna4||'">
                         <button type="button" class="btn btn-white btn-md" style="background:#769900; color:#FFFFFF;" onclick="" name="btn_obtener_desc" id="btn_obtener_desc"><i class="fa fa-eye"></i> BUSCAR </button>
                      </div>
                      <div class="'||v_ancho_columna7||'">
                         <div id="miDescuento">
                             <table class="table" style="font-size: 13px;">
                                 <thead>
                                 <tr>
                                     <th>Subtotal Productos:</th>
                                     <th>$&nbsp;<span  id=''v_subtotalprod'' ></span> </th>
                                 </tr>
                                 <tr>
                                     <th>Descuentos Comunidad Universitaria:</th>
                                     <th>$&nbsp;<span  id=''v_total_descuento''></span></th>
                                 </tr>
                                 <tr>
                                     <th>Costo de Env&iacute;o:</th>
                                     <th>$&nbsp;<span  id=''v_valor_despacho''></span></th>
                                 </tr>
                                 <tr>
                                     <th>Total a Pagar:</th>
                                     <th>$&nbsp;<span  id=''v_total_compra''></span></th>
                                 </tr>
                                 <tr style="display:none">
                                     <th>Centro de Costo:</th>
                                     <th>$&nbsp;<span  id=''v_centro_costo''></span></th>
                                 </tr>
                                 </thead>
                             </table>
                          </div>
                       </div>
                      <div id="myDIV" class="col-lg-12"  style="display:none" >
                                                                       <div id="" class="form-horizontal" >
                                                      <div class="form-group" style="display:none" >
                                                          <label class="'||v_ancho_columna1||' control-label">Tipo Cliente:</label>
                                                          <div class="'||v_ancho_columna3||'">
                                                               <input class="radio i-checks "  value="1" name="txt_clie_interlocutor" id="txt_clie_interlocutor" type="radio" checked>&nbsp;<label class="control-label">Persona</label>
                                                               <input class="radio i-checks "  value="2" name="txt_clie_interlocutor" id="txt_clie_interlocutor" type="radio" >&nbsp;<label class="control-label">Empresa</label>
                                                          </div>
                                                      </div>

                                                      <!-- GRUPO 1: DATOS PERSONALES -->
                                                      <div style="background:#ffffff; border:1px solid #e7eaec; border-radius:6px; padding:20px 20px 10px 20px; margin-bottom:25px; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                                                          <h4 style="margin-top:0; margin-bottom:18px; color:#769900; font-size:15px; font-weight:bold; border-bottom:1px solid #eee; padding-bottom:10px;">
                                                              <i class="fa fa-user-circle-o" style="margin-right:8px; color:#769900;"></i> Datos Personales
                                                          </h4>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Nombres:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: Juan" class="form-control obligatorio" value="" name="txt_clie_nombre_pila" id="txt_clie_nombre_pila">
                                                                  <input type="hidden" class="form-control" value="03" name="txt_clie_canal_distribucion" id="txt_clie_canal_distribucion">
                                                              </div>
                                                              <label class="'||v_ancho_columna1||' control-label">Apellido Paterno:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: P&eacute;rez" class="form-control obligatorio" value="" name="txt_clie_apellido_paterno" id="txt_clie_apellido_paterno">
                                                              </div>
                                                          </div>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Apellido Materno:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: Gonz&aacute;lez" class="form-control obligatorio" value="" name="txt_clie_apellido_materno" id="txt_clie_apellido_materno">
                                                              </div>
                                                              <label class="'||v_ancho_columna1||' control-label">Correo Electr&oacute;nico:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: correo@email.com" class="form-control obligatorio" value="" name="txt_clie_e_mail" id="txt_clie_e_mail">
                                                              </div>
                                                          </div>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Destinatario:</label>
                                                              <div class="col-lg-10">
                                                                  <input placeholder="Nombre de la persona que recibir&aacute; el pedido" class="form-control obligatorio" value="" name="txt_clie_destinatario" id="txt_clie_destinatario">
                                                                  <input type="hidden" id="DATE" name="DATE" value="WOULD_LIKE_TO_ADD_DATE_HERE">
                                                              </div>
                                                          </div>
                                                      </div>

                                                      <!-- GRUPO 2: UBICACIÓN -->
                                                      <div style="background:#ffffff; border:1px solid #e7eaec; border-radius:6px; padding:20px 20px 10px 20px; margin-bottom:25px; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                                                          <h4 style="margin-top:0; margin-bottom:18px; color:#769900; font-size:15px; font-weight:bold; border-bottom:1px solid #eee; padding-bottom:10px;">
                                                              <i class="fa fa-globe" style="margin-right:8px; color:#769900;"></i> Ubicaci&oacute;n
                                                          </h4>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Pa&iacute;s:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <div class="form-control" style="background:#f5f5f5; border:1px solid #e5e6e7; color:#555; cursor:default; display:flex; align-items:center; height:34px;">
                                                                      <i class="fa fa-flag" style="margin-right:8px; color:#769900;"></i> Chile
                                                                  </div>
                                                                  <input type="hidden" name="txt_pais_codigo" id="txt_pais_codigo" value="38">
                                                              </div>
                                                              <label class="'||v_ancho_columna1||' control-label">Regi&oacute;n:</label>
                                                              <div class="'||v_ancho_columna3||'" id="cont_select_nivel_region">
                                                                  <select class="chosen form-control m-b obligatorio" name="txt_regi_codigo" id="txt_regi_codigo">
                                                                      <option value="-1">Seleccione regi&oacute;n</option>
                                                                  ');
                                                                  get_combos('regi_codigo', ' regi_descripcion', 'vec_cob03.pove_region', '');
                                                                  HTP.P('</select>
                                                              </div>
                                                              <div class="'||v_ancho_columna3||'" id="hide_otra_region" style="display:none;">
                                                                  <input placeholder="Ingrese regi&oacute;n" class="form-control" id="disp_region" name="disp_region" value="" readonly="readonly">
                                                              </div>
                                                          </div>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Ciudad:</label>
                                                              <div class="'||v_ancho_columna3||'" id="cont_select_nivel_ciudad">
                                                                  <select class="chosen form-control m-b obligatorio" name="txt_ciud_codigo" id="txt_ciud_codigo">
                                                                      <option value="-1">Seleccione ciudad</option>
                                                                  </select>
                                                              </div>
                                                              <div class="'||v_ancho_columna3||'" id="hide_otra_ciudad" style="display:none;">
                                                                  <input placeholder="Ingrese ciudad" class="form-control" id="disp_ciudad" name="disp_ciudad" value="" readonly="readonly">
                                                              </div>
                                                          </div>
                                                      </div>

                                                      <!-- GRUPO 3: DESPACHO Y ENTREGA -->
                                                      <div style="background:#ffffff; border:1px solid #e7eaec; border-radius:6px; padding:20px 20px 10px 20px; margin-bottom:25px; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                                                          <h4 style="margin-top:0; margin-bottom:18px; color:#769900; font-size:15px; font-weight:bold; border-bottom:1px solid #eee; padding-bottom:10px;">
                                                              <i class="fa fa-truck" style="margin-right:8px; color:#769900;"></i> Despacho y Entrega
                                                          </h4>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Direcci&oacute;n:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: Av. Principal 123" class="form-control obligatorio" value="" name="txt_clie_direccion" id="txt_clie_direccion">
                                                              </div>
                                                              <label class="'||v_ancho_columna1||' control-label">N&uacute;mero de Direcci&oacute;n:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: 1141" class="form-control obligatorio solonumero" value="" name="txt_clie_num_direccion" id="txt_clie_num_direccion">
                                                              </div>
                                                          </div>

                                                          <div class="form-group">
                                                              <label class="'||v_ancho_columna1||' control-label">Tel&eacute;fono de Contacto:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <input placeholder="Ej: 912345678" class="form-control obligatorio solonumero" value="" name="txt_clie_tel_contacto" id="txt_clie_tel_contacto">
                                                              </div>
                                                              <label class="'||v_ancho_columna1||' control-label">Retiro en Tienda:</label>
                                                              <div class="'||v_ancho_columna3||'">
                                                                  <div style="padding-top: 5px;">
                                                                      <input class="radio i-checks" value="S" name="txt_clie_retiro" id="txt_clie_retiro" type="radio" checked>&nbsp;<label class="control-label" style="font-weight:normal;">S&iacute;</label>
                                                                      &nbsp;&nbsp;&nbsp;&nbsp;
                                                                      <input class="radio i-checks" value="N" name="txt_clie_retiro" id="txt_clie_retiro" type="radio">&nbsp;<label class="control-label" style="font-weight:normal;">No</label>
                                                                  </div>
                                                              </div>
                                                          </div>

                                                          <div class="form-group" style="margin-bottom:0;">
                                                              <div class="col-lg-offset-2 col-lg-10" id="mostrar_info" style="display: block; margin-bottom: 10px;">
                                                                  <div style="background:#f0f7e0; border-left:4px solid #769900; border-radius:4px; padding:10px 14px;">
                                                                      <p style="margin:0; color:#4a6400;"><i class="fa fa-map-marker" style="margin-right:6px;"></i><strong>Lugar de retiro:</strong> 1 Poniente #1141, frente a Plaza de Armas Nueva Casa Central.</p>
                                                                      <p style="margin:4px 0 0 22px; color:#4a6400;">Editorial, Universidad de Talca</p>
                                                                  </div>
                                                              </div>
                                                          </div>
                                                      </div>

                                                      <!-- DOCUMENTO TRIBUTARIO CENTRADO -->
                                                      <div class="form-group" style="margin-top: 25px; margin-bottom: 15px;">
                                                          <div class="col-lg-12 text-center" style="display: flex; justify-content: center; align-items: center; gap: 15px; font-size: 14px;">
                                                              <strong>Documento Tributario:</strong>
                                                              <div class="tooltip-demo" style="display: inline-block;">
                                                                 <input class="radio i-checks" value="0" name="txt_clie_bol_fac" id="txt_clie_bol_fac" type="radio" checked>&nbsp;<label class="control-label" style="font-weight:normal; margin-right:15px;">Boleta</label>
                                                                 <input disabled class="radio i-checks disabled" value="1" name="txt_clie_bol_fac" id="txt_clie_bol_fac" type="radio">&nbsp;<label class="control-label" style="font-weight:normal;">Factura</label>
                                                              </div>
                                                          </div>
                                                      </div>
                                                 <div class="form-group">
                                                   <div class=''hr-line-dashed''></div>
                                                   <div class="well m-t"><strong></strong>
                                                     <div class="col-md-3 col-md-offset-9">
                                                         <button id="btn_continuarpago" type="button" class="btn btn-white btn-md"  aria-expanded="false" style="background:#C2431A; color:#FFFFFF;" ><i class="fa fa-arrow-right"></i> Todo Ok, Finalizar mi pedido </button>
                                                     </div>
                                                     <br>
                                                     <br>
                                                   </div>
                                                 </div>
                                                     </div>
                                                   </div>
                                                 </form>
        </div>

    <!-- Modal de confirmacion de pedido -->
        <div class="modal inmodal" id="ModalConfirmarPedido" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content animated bounceInRight">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span></button>
                        <h4 class="modal-title"><i class="fa fa-shopping-cart"></i> Confirmar Pedido</h4>
                    </div>
                    <div class="modal-body">
                        <p>¿Confirma que desea continuar con la operación?</p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-white" data-dismiss="modal">Cancelar</button>
                        <button type="button" id="btn_confirmar_pedido" class="btn btn-primary">Confirmar</button>
                    </div>
                </div>
            </div>
        </div>

    <!-- Div modal para mostrar y editar detalles -->
        <div class="modal inmodal" id="ModalDetalles" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content animated bounceInRight">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
                        <h4 class="modal-title" id="">Información de Facturación</h4>
                        <small class="font-bold">Complete esta información únicamente si desea obtener factura por sus compras. <strong>Todos los campos son requeridos.</strong></small>
                    </div>
                    <div class="modal-body">

                        <form id="frm_facturacion" class="form-horizontal" >
                            <div class="form-group">
                                  <label class="'||v_ancho_columna1||' control-label">Nombre Empresa:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE NOMBRE EMPRESA" class="form-control " value="" name="txt_dato_nombre_emp" id="txt_dato_nombre_emp">
                                              <input type="hidden" id="txt_dato_codigo" name="txt_dato_codigo" value="">
                                  </div>

                                  <label class="'||v_ancho_columna1||' control-label">Detalle:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE DETALLE" class="form-control " value="" name="txt_dato_detalle" id="txt_dato_detalle">
                                  </div>
                            </div>
                            <div class="form-group">
                                  <label class="'||v_ancho_columna1||' control-label">Rut Empresa:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE RUT EMPRESA" class="form-control "  name="txt_dato_rut_empr" id="txt_dato_rut_empr" value="0">
                                  </div>
                                  <label class="'||v_ancho_columna1||' control-label">Prestación o Producto:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE PRESTACION O PRODUCTO" class="form-control " value="" name="txt_dato_prestac_prod" id="txt_dato_prestac_prod">
                                  </div>
                            </div>
                            <div class="form-group">
                                  <label class="'||v_ancho_columna1||' control-label">Giro, Industria:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE GIRO,INDUSTRIA" class="form-control " value="" name="txt_dato_giro" id="txt_dato_giro">
                                  </div>
                                  <label class="'||v_ancho_columna1||' control-label">Pais:</label>
                                  <div class="'||v_ancho_columna3||'">
                                          <select  class="chosen form-control m-b obligatorio" name="disp_pais_codigo" id="disp_pais_codigo">
                                                <option value="-1">SELECCIONE PAIS</option>');
                                                    get_combos('pais_codigo', ' pais_descripcion', 'vec_cob03.pove_pais', 'pais_codigo = ''38''');
                                 htp.p(' </select>
                                  </div>
                            </div>
                            <div class="form-group">

                                  <label class="'||v_ancho_columna1||' control-label">Orden de Compra:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE ORDEN DE COMPRA" class="form-control " value="" name="txt_dato_orden_compra" id="txt_dato_orden_compra">
                                  </div>
                                  <label class="'||v_ancho_columna1||' control-label">Región:</label>
                                  <div class="'||v_ancho_columna3||'" id="cont_select_nivel_region_fac">
                                     <select  class="chosen form-control m-b obligatorio" name="disp_regi_codigo" id="disp_regi_codigo">
                                            <option value="-1">SELECCIONE REGION</option>');
                                        get_combos('regi_codigo', 'regi_descripcion', 'vec_cob03.pove_region', '');
                             htp.p(' </select>
                                  </div>
                            </div>
                            <div class="form-group">
                                  <label class="'||v_ancho_columna1||' control-label">Valor :</label>
                                  <div class="'||v_ancho_columna3||'">
                                                <div ><span id=''total_compra_pag''></span></div>
                                              <!--<input  placeholder="INGRESE VALOR" class="form-control " value="" name="v_total_compra" id="v_total_compra">-->
                                  </div>
                                  <label class="'||v_ancho_columna1||' control-label">Ciudad:</label>
                                  <div class="'||v_ancho_columna3||'" id ="cont_select_nivel_ciudad_fac">
                                        <select  class="chosen form-control m-b obligatorio" name="disp_ciud_codigo" id="disp_ciud_codigo">
                                            <option value="-1">SELECCIONE CIUDAD</option>');
                                        get_combos('ciud_codigo', ' ciud_descripcion', 'vec_cob03.pove_ciudad', '');
                                htp.p(' </select>
                                  </div>
                            </div>
                            <div class="form-group">
                                  <label class="'||v_ancho_columna1||' control-label">Especificaciónes del proveedor:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE ESPECIFICACIONES DEL PROVEEDOR" class="form-control " value="" name="txt_dato_espec_provee" id="txt_dato_espec_provee">
                                  </div>
                                  <label class="'||v_ancho_columna1||' control-label">Dirección:</label>
                                  <div class="'||v_ancho_columna3||'">
                                              <input  placeholder="INGRESE DIRECCION" class="form-control " value="" name="txt_dato_direccion" id="txt_dato_direccion">
                                  </div>
                            </div>
                            <div class="form-group">
                                  <label class="'||v_ancho_columna1||' control-label">Centro de Costo:</label>
                                  <div class="'||v_ancho_columna3||'">
                                       <div ><span id=''v_centro_costos_edito''></span></div>
                                  </div>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-primary" id="btn_factura" onclick="return Guardar_modal_factura();" ><i class="fa fa-check"></i> Guardar Factura</button>
                    </div>
                </div>
            </div>
            --<form id="formu" name="formu" method="submit" enctype="multipart/form-data" action="http://condor2.utalca.cl/pls/cob/portaldepagos.valida_pagos_venta">
            <form id="formu" name="formu" method="submit" enctype="multipart/form-data" action="http://condor2-19testing.utalca.cl/pls/cob_test/portaldepagos.valida_pagos_venta">
                   <tr align="left" valign="middle">
                      <td><input type="hidden" name="producto_id"  id="producto_id" value="'||v_prod_id||'" /></td>
                      <td><input type="hidden" name="subproducto_id"  id="subproducto_id" value="" /></td>
                      <td><input type="hidden" name="tipo_cliente" value="R" /></td>
                      <td><input type="hidden" name="producto_cliente_id"  id="producto_cliente_id" value="" /></td>
                      <td><input type="hidden" name="producto_cliente_nmb"  id="producto_cliente_nmb" value="" /></td>
                      <td><input type="hidden" name="producto_valor"  id="producto_valor" value="" /></td>
                      <td><input type="hidden" name="p_observacion" id="p_observacion" value="PORTALEDITORIAL"></td>
                   </tr>
            </form>

        </div>

<script language="javascript">

    function comprobar(id_trx)
    {
        // Llenar los campos del formulario formu
        document.getElementById(''producto_cliente_id'').value = document.getElementById(''txt_clie_rut'').value;
        document.getElementById(''producto_id'').value = id_trx;
        document.getElementById(''producto_cliente_nmb'').value = document.getElementById(''txt_clie_destinatario'').value;
        document.getElementById(''producto_valor'').value = document.getElementById(''v_total_compra'').innerHTML;

        var BASE_TESTING = ''http://condor2-19testing.utalca.cl/pls/cob_test/'';
        var BASE_PROD = ''http://condor2.utalca.cl/pls/cob/'';
        var esTesting = window.location.hostname.indexOf(''testing'') !== -1;

        function corregir_url_entorno(url) {
            if (!url) return url;
            if (esTesting) {
                // En ambiente de testing, reescribir cualquier URL que intente ir a producción
                return url
                    .replace(''https://condor2.utalca.cl/pls/cob/'', BASE_TESTING)
                    .replace(''http://condor2.utalca.cl/pls/cob/'', BASE_TESTING);
            } else {
                // En ambiente de producción, reescribir cualquier URL que intente ir a testing
                return url
                    .replace(''https://condor2-19testing.utalca.cl/pls/cob_test/'', BASE_PROD)
                    .replace(''http://condor2-19testing.utalca.cl/pls/cob_test/'', BASE_PROD);
            }
        }

        var frm = document.getElementById(''formu'');
        var url_valida = corregir_url_entorno(frm.action);
        var params = new URLSearchParams(new FormData(frm)).toString();

        // Paso 1: POST a valida_pagos_venta
        fetch(url_valida, {
            method: ''POST'',
            headers: {''Content-Type'': ''application/x-www-form-urlencoded''},
            body: params,
            redirect: ''follow''
        })
        .then(function(r) { return r.text(); })
        .then(function(html) {
            var doc = new DOMParser().parseFromString(html, ''text/html'');
            var form1 = doc.getElementById(''form1'');
            if (!form1) { alert(''Error al iniciar el pago. Intente nuevamente.''); return; }

            var action_graba = corregir_url_entorno(form1.action);
            var params2 = [];
            form1.querySelectorAll(''input[type="hidden"]'').forEach(function(i) {
                params2.push(encodeURIComponent(i.name) + ''='' + encodeURIComponent(i.value));
            });

            // Paso 2: POST a graba_cookie siguiendo el redirect automaticamente
            // redirect:follow permite leer resp.url con la URL final del redirect
            return fetch(action_graba, {
                method: ''POST'',
                headers: {''Content-Type'': ''application/x-www-form-urlencoded''},
                body: params2.join(''&''),
                redirect: ''follow''
            });
        })
        .then(function(resp) {
            if (!resp) return;
            // resp.url contiene la URL final tras seguir el 302 de graba_cookie
            // resp.redirected confirma que se siguio el redirect
            var loc = resp.url || '''';
            if (!loc) { alert(''Error al procesar el pago. Intente nuevamente.''); return; }
            // Corregir según entorno (testing/prod)
            loc = corregir_url_entorno(loc);
            
            // Limpiar cookies del carrito en el navegador antes de ir a pagar
            fetch(''venta_online.escribir?v_libros=&v_cantidad=&v_limpiacookie=1'')
            .then(function() {
                window.location.href = loc;
            })
            .catch(function() {
                window.location.href = loc;
            });
        })
        .catch(function() {
            // Fallback: submit directo del formulario
            document.formu.submit();
        });






}







</script>

<script>

            $(document).ready(function () {
                $(''.i-checks'').iCheck({
                    checkboxClass: ''icheckbox_square-green'',
                    radioClass: ''iradio_square-green'',
                });

                $(''input[name="txt_clie_retiro"]'').on(''ifChanged'', function (event) {
                    mostrar_detalle();

                });

                $(''input[name="txt_clie_bol_fac"]'').on(''ifChanged'', function() {

                     //mostrar_det_bol_fac();



                });
});



    $(document).ready(function(){

                $("#btn_factura").click(function(e){


                   if(validar(''frm_facturacion''))
                   {
                          //  alert(''CAMPO REQUERIDO'');
                            $("#ModalDetalles").modal("toggle");

                   }

                });

    });


function Guardar_modal_factura(){

/*
    v_data = "p_clie_codigo="+v_clie_codigo;
     $.ajax({
        url:"VENTA_ONLINE.",
        data: v_data ,
        async: false,
        type:"GET",
        dataType: "json",
        success: function(data){
            toastr.success("Se han ingresado los datos de Facturacion");
        }

    });*/

   // $("#ModalDetalles").modal("toggle");
}

/**#####################################################################################################
                    FUNCIONES PARA REALIZAR EL INGRESO DE DATOS DE UNA FACTURA.
#####################################################################################################**/
function carga_regiones_fac(id_pais)
{
          v_data = "p_pais_codigo="+id_pais;

          $.ajax({
                   url:''venta_online.get_json_regiones_fac'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",


                   success:function(response){

                            var imprime_region_fac='' <select class="chosen form-control m-b obligatorio" name="disp_regi_codigo" id="disp_regi_codigo" >'';
                               imprime_region_fac=imprime_region_fac+ ''<option value="-1">SELECCIONE REGION</option>'';
                             var var_value='''';

                             $.each(response.data, function(key, value){

                                    $.each( value, function ( userkey, uservalue) {

                                        if (userkey==''REGI_CODIGO'')
                                                  var_value=var_value+''<option value="''+uservalue+''">'';
                                         if (userkey==''REGI_DESCRIPCION'')
                                                  var_value=var_value+uservalue+''</option>'';
                                    });

                             });
                             imprime_region_fac=imprime_region_fac+ var_value;
                            imprime_region_fac=imprime_region_fac+ ''</select>'';
                            document.getElementById("cont_select_nivel_region_fac").innerHTML = imprime_region_fac;

                             $(''#disp_regi_codigo'').change( function() {

                                carga_ciudades_fac($(this).val());

                            });
                            $("#disp_regi_codigo").chosen();

                   }
                 });

     }

     function carga_ciudades_fac(id_regiones)
     {

         v_data = "p_regi_codigo="+id_regiones;


          $.ajax({
                   url:''venta_online.get_json_ciudades_fac'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",

                   success:function(response){

                            var imprime_ciudad_fac='' <select class="chosen form-control m-b obligatorio" name="disp_ciud_codigo" id="disp_ciud_codigo" >'';
                               imprime_ciudad_fac=imprime_ciudad_fac+ ''<option value="-1">SELECCIONE CIUDAD</option>'';
                             var var_value='''';




                             $.each(response.data, function(key, value){
                                    var var_value_tmp='''';

                                    $.each( value, function ( userkey, uservalue) {


                                        if (userkey==''CIUD_CODIGO'')
                                                  var_value_tmp=var_value_tmp+''<option value="''+uservalue+''">'';
                                         if (userkey==''CIUD_DESCRIPCION'')
                                                  var_value_tmp=var_value_tmp+uservalue+''</option>'';


                                    });

                                    var_value=var_value+var_value_tmp;



                             });

                            imprime_ciudad_fac=imprime_ciudad_fac+ var_value;
                            imprime_ciudad_fac=imprime_ciudad_fac+ ''</select>'';
                            document.getElementById("cont_select_nivel_ciudad_fac").innerHTML = imprime_ciudad_fac;


                          $("#disp_ciud_codigo").chosen();

                   }

                 });


     }

    $(document).ready(function(){

           $(''#disp_pais_codigo'').change( function() {

                  if ($(this).val()==38)
                  {
                        carga_regiones_fac($(this).val());
                  }
                  else
                  {
                       return true;
                  }
        });


     });


/**#####################################################################################################
                    FIN DE LA FUNCION PARA REALIZAR EL INGRESO DE DATOS DE UNA FACTURA.
#####################################################################################################**/



function mostrar_detalle () {

        if($("input[name=''txt_clie_retiro'']:checked").val() == "S")  {

                      document.getElementById("mostrar_info").style.display = "block";
                      document.getElementById("v_valor_despacho").innerHTML = ''0'';
                      calcular_total_venta();

        }else if($("input[name=''txt_clie_retiro'']:checked").val() == "N") {

                      document.getElementById("mostrar_info").style.display = "none";

                      /* UX FIX: si la ciudad ya fue seleccionada, recalcular el costo de envio
                         en lugar de resetear a 0. Asi el usuario no pierde el valor al
                         cambiar entre los radios. */
                      var v_ciudad_actual = document.getElementById("txt_ciud_codigo");
                      if (v_ciudad_actual && v_ciudad_actual.value && v_ciudad_actual.value != "-1") {
                          mostrar_valores_despacho(v_ciudad_actual.value);
                      } else {
                          document.getElementById("v_valor_despacho").innerHTML = ''0'';
                          calcular_total_venta();
                      }
        }else{
                return false;
        }
}

function mostrar_det_bol_fac(){

        if($("input[name=''txt_clie_bol_fac'']:checked").val() == "0")  {

             return false;
        }else if($("input[name=''txt_clie_bol_fac'']:checked").val() == "1") {

            $("#ModalDetalles").modal("toggle");
            document.getElementById("total_compra_pag").innerHTML=eval(document.getElementById("v_total_compra").innerHTML);
            document.getElementById("v_centro_costos_edito").innerHTML = document.getElementById("v_centro_costo").innerHTML
             $("#disp_pais_codigo").chosen();
             $("#disp_regi_codigo").chosen();
             $("#disp_ciud_codigo").chosen();


        }else{
                return false;
        }

}
</script>


<script>


function Limpiar()
{

    var sAux="";
    var frm = document.getElementById("div_cliente");
    if (frm) {
        for (i=0;i<frm.elements.length;i++)
        {


            var str=frm.elements[i].name;
            if (frm.elements[i].type==''select-one'')
            {
                $(''#''+frm.elements[i].name).val(-1);
                $(''#''+frm.elements[i].name).trigger("chosen:updated");

            }

        }
    }
}
function calcular_total_venta (){

  var v_subtotal=document.getElementById("v_subtotalprod").innerHTML;
  var v_total_desc=document.getElementById("v_total_descuento").innerHTML;
  var v_valor_desp=document.getElementById("v_valor_despacho").innerHTML;


  document.getElementById("v_total_compra").innerHTML=(parseInt(v_subtotal)- parseInt(v_total_desc))+parseInt(v_valor_desp);

}

function mostrar_valores_despacho(id_ciudad){


          v_data = "p_ciud_codigo="+id_ciudad+"&p_cantidad="+document.getElementById("c_cantidad_total").innerHTML;

          $.ajax({
                   url:''venta_online.get_json_cargar_valores'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",

                   success:function(response){

                        var var_costo_envio='''';

                             $.each(response.data, function(key, value){

                                    $.each( value, function ( userkey, uservalue) {

                                         if (userkey==''COSTO_ENVIO'')
                                                  var_costo_envio=uservalue;

                                    });

                                        document.getElementById("v_valor_despacho").innerHTML = var_costo_envio;


                                        calcular_total_venta();


                              });



                    }
          });


}

</script>

<script>


     function carga_ciudades(id_regiones)
     {

         v_data = "p_regi_codigo="+id_regiones;


          $.ajax({
                   url:''venta_online.get_json_ciudades'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",

                   success:function(response){

                            var imprime_ciudad='' <select class="chosen form-control m-b obligatorio" name="txt_ciud_codigo" id="txt_ciud_codigo" >'';
                               imprime_ciudad=imprime_ciudad+ ''<option value="-1">SELECCIONE CIUDAD</option>'';
                             var var_value='''';




                             $.each(response.data, function(key, value){
                                    var var_value_tmp='''';

                                    $.each( value, function ( userkey, uservalue) {


                                        if (userkey==''CIUD_CODIGO'')
                                                  var_value_tmp=var_value_tmp+''<option value="''+uservalue+''">'';
                                         if (userkey==''CIUD_DESCRIPCION'')
                                                  var_value_tmp=var_value_tmp+uservalue+''</option>'';


                                    });

                                    var_value=var_value+var_value_tmp;



                             });

                            imprime_ciudad=imprime_ciudad+ var_value;
                            imprime_ciudad=imprime_ciudad+ ''</select>'';
                            document.getElementById("cont_select_nivel_ciudad").innerHTML = imprime_ciudad;


                             $(''#txt_ciud_codigo'').change( function() {

                                if($("input[name=''txt_clie_retiro'']:checked").val() == ''S''){

                                        document.getElementById("v_valor_despacho").innerHTML = ''0'';
                                        calcular_total_venta();

                                }else{
                                        mostrar_valores_despacho($(this).val());
                                }
                            });

                          $("#txt_ciud_codigo").chosen();

                   }

                 });


     }

</script>

 <script>

     function carga_regiones(id_pais)
     {
          v_data = "p_pais_codigo="+id_pais;

          $.ajax({
                   url:''venta_online.get_json_regiones'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",


                   success:function(response){

                            var imprime_region='' <select class="chosen form-control m-b obligatorio" name="txt_regi_codigo" id="txt_regi_codigo" >'';
                               imprime_region=imprime_region+ ''<option value="-1">SELECCIONE REGION</option>'';
                             var var_value='''';



                             $.each(response.data, function(key, value){

                                    $.each( value, function ( userkey, uservalue) {

                                        if (userkey==''REGI_CODIGO'')
                                                  var_value=var_value+''<option value="''+uservalue+''">'';
                                         if (userkey==''REGI_DESCRIPCION'')
                                                  var_value=var_value+uservalue+''</option>'';
                                    });

                             });
                             imprime_region=imprime_region+ var_value;
                            imprime_region=imprime_region+ ''</select>'';
                            document.getElementById("cont_select_nivel_region").innerHTML = imprime_region;



                             $(''#txt_regi_codigo'').change( function() {

                                carga_ciudades($(this).val());

                                  if ($(this).val()!=-1)
                                  {

                                      $(''#cont_select_nivel_ciudad'').show();
                                      $(''#hide_otra_ciudad'').hide();
                                  }
                                  else{
                                      $(''#cont_select_nivel_ciudad'').hide();
                                      $(''#hide_otra_ciudad'').show();

                                  }


                            });

                            $("#txt_regi_codigo").chosen();
                             calcular_total_venta();



                   }

                 });

     }


        $(document).ready(function(){
         /* Pais es Chile fijo (hidden), la region siempre visible.
            La ciudad se muestra solo tras elegir region. */
         $(''#cont_select_nivel_ciudad'').hide();
         $(''#hide_otra_ciudad'').hide();
         $(''#cont_select_nivel_region'').show();
         $(''#hide_otra_region'').hide();

         // Escuchar el cambio en el selector de region inicial
         $(''#txt_regi_codigo'').change(function() {
             carga_ciudades($(this).val());
             if ($(this).val() != -1) {
                 $(''#cont_select_nivel_ciudad'').show();
                 $(''#hide_otra_ciudad'').hide();
             } else {
                 $(''#cont_select_nivel_ciudad'').hide();
                 $(''#hide_otra_ciudad'').show();
             }
         });
     });



 function VerificaRut(rut) {
        if (rut.toString().trim() != "" && rut.toString().indexOf("-") > 0) {
            var caracteres = new Array();
            var serie = new Array(2, 3, 4, 5, 6, 7);
            var dig = rut.toString().substr(rut.toString().length - 1, 1);
            rut = rut.toString().substr(0, rut.toString().length - 2);
            for (var i = 0; i < rut.length; i++) {
                caracteres[i] = parseInt(rut.charAt((rut.length - (i + 1))));
            }
            var sumatoria = 0;
            var k = 0;
            var resto = 0;
            for (var j = 0; j < caracteres.length; j++) {
                if (k == 6) {
                    k = 0;
                }
                sumatoria += parseInt(caracteres[j]) * parseInt(serie[k]);
                k++;
            }
            resto = sumatoria % 11;
            dv = 11 - resto;
            if (dv == 10) {
                dv = "K";
            }
            else if (dv == 11) {
                dv = 0;
            }
            if (dv.toString().trim().toUpperCase() == dig.toString().trim().toUpperCase())
                return true;
            else
                return false;
        }
        else {
            return false;
        }
    }


 </script>
 <script>
    var id='''';
   $(document).ready(function(){

var v_desc_comuni = '''';
var v_descuento_aplicado= '''';
    $("#btn_obtener_desc").click ( function (e)
    {


       e.preventDefault();


       var rut_consultar = '''||v_rut_clie||''';

          v_porcentaje = 0.30;
          v_descru = 0.10;

          var v_subtotal =eval(document.getElementById("v_total").innerHTML);
          document.getElementById("v_total_descuento").innerHTML=0;
          document.getElementById("v_valor_despacho").innerHTML=0;
          document.getElementById("v_total_compra").innerHTML=0;
          document.getElementById("v_subtotalprod").innerHTML=v_subtotal;
         id = document.getElementById("txt_clie_rut").value

           if(!VerificaRut(id)){
               toastr.warning("El rut ingresado no es v&aacute;lido y el formato debe ser 12345678-5","ADVERTENCIA");
               document.getElementById("myDIV").style.display = "none";
               //document.getElementById("miDescuento").style.display = "none";
               document.getElementById("txt_clie_rut").focus();

               return null;
           }else {
               document.getElementById("myDIV").style.display = "block";
               document.getElementById("txt_clie_nombre_pila").focus();
                calcular_total_venta();

           }


          v_data = "p_rut="+id;

          if( id== rut_consultar) {


                        document.getElementById("txt_clie_nombre_pila").value='''||v_nombre_pila||''';
                        //document.getElementById("txt_clie_direccion").value='''||v_direccion||''';
                        document.getElementById("txt_clie_num_direccion").value='''||v_direc_numero||''';
                        document.getElementById("txt_clie_e_mail").value='''||v_email_sap||''';
                        document.getElementById("txt_clie_tel_contacto").value='''||v_telefono||''';
                        return null;
           }else{
                        document.getElementById("txt_clie_nombre_pila").value='''';
                        document.getElementById("txt_clie_direccion").value='''';
                        document.getElementById("txt_clie_num_direccion").value='''';
                        document.getElementById("txt_clie_e_mail").value='''';
                        document.getElementById("txt_clie_tel_contacto").value='''';

           }
           $.ajax({
                   url:''venta_online.get_json_descuento_comunidad'',
                   type:''GET'',
                   data: v_data,

                   success:function(response){

                            if(response.data=='''' ){

                                 document.getElementById(''txt_clie_destinatario'').value="";
                                 document.getElementById("txt_clie_destinatario").focus();
                                 document.getElementById(''txt_clie_direccion'').value="";
                                 document.getElementById(''txt_clie_e_mail'').value="";
                                 document.getElementById("miDescuento").style.display = "block";
                                 document.getElementById("v_total_descuento").innerHTML="0";
                                 //document.getElementById("v_total_descuento").innerHTML=v_desc_comuni;
                                 v_desc_comuni = v_subtotal * v_descru;
                                  document.getElementById("v_total_descuento").innerHTML=v_desc_comuni;
                                  calcular_total_venta();




                            }else{
                                 document.getElementById(''txt_clie_nombre_pila'').value=response.data[0].NOMBRE;
                                 document.getElementById(''txt_clie_apellido_paterno'').value=response.data[0].APELLIDO_PATERNO;
                                 document.getElementById(''txt_clie_apellido_materno'').value=response.data[0].APELLIDO_MATERNO;
                                 document.getElementById(''txt_clie_e_mail'').value=response.data[0].E_MAIL;
                                 // document.getElementById(''txt_clie_direccion'').value=response.data[0].DIRECCION;
                                // document.getElementById(''txt_clie_num_direccion'').value=response.data[0].NUMERO_DIRECCION;
                                 document.getElementById(''txt_clie_tel_contacto'').value=response.data[0].TELEFONO;
                                 document.getElementById("miDescuento").style.display = "block";
                                 v_desc_comuni = v_subtotal * v_porcentaje;
                                  document.getElementById("v_total_descuento").innerHTML=v_desc_comuni;
                                  calcular_total_venta();

                            }
                        }

              });


              // $("#txt_pais_codigo").chosen();
             $("#txt_ciud_codigo").chosen();


      }
    );

    });





</script>


    ');
librerias_js;
end;

procedure recibe_solicitud_clientes(p_variables   in varchar2,
                           p_operacion   in varchar2
                           ) is


    v_tipo_mensaje number(1);
    arr_ls_VAR ARRAY_STR;
    arr_VAR ARRAY_STR;
    arr_VAR_rut ARRAY_STR;
    arr_VAR_retiro ARRAY_STR;
    v_mensaje varchar2(2000);
    result_split NUMBER;
    result_split1 NUMBER;
    v_clie_rut              POVE_CLIENTE.CLIE_RUT%TYPE;
    v_clie_dv               POVE_CLIENTE.CLIE_DV%TYPE;
    v_pais_codigo           POVE_CLIENTE.PAIS_CODIGO%TYPE;
    v_regi_codigo           POVE_CLIENTE.REGI_CODIGO%TYPE;
    v_ciud_codigo           POVE_CLIENTE.CIUD_CODIGO%TYPE;
    v_clie_destinatario     POVE_CLIENTE.CLIE_DESTINATARIO%TYPE;
    v_clie_email            POVE_CLIENTE.CLIE_EMAIL%TYPE;
    v_clie_tel_contacto     POVE_CLIENTE.CLIE_TEL_CONTACTO%TYPE;
    v_clie_direccion        POVE_CLIENTE.CLIE_DIRECCION%TYPE;
    v_clie_retiro           POVE_CLIENTE.CLIE_RETIRO%TYPE;
    v_cuenta_rut   number;

     V_BASURA VARCHAR2(100);
       contador number:=0;

begin
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

    v_tipo_mensaje:='1';
    v_mensaje:='';
     result_split:= SPLIT(p_variables, '@@', arr_ls_VAR);


    if result_split >=0 then
             FOR i in 1 .. arr_ls_VAR.count-1
             LOOP
                result_split:= SPLIT(arr_ls_VAR(i)||'//', '//', arr_VAR);

                    if result_split=0 then


                       v_mensaje:=v_mensaje || UPPER(arr_VAR(1))||':' || UPPER(arr_VAR(2)) ||'&';

                         CASE  UPPER(arr_VAR(1))
                              WHEN UPPER('CLIE_RUT') then

                                   result_split1:= SPLIT(UPPER(arr_VAR(2))||'-', '-', arr_VAR_rut);
                                    if result_split1 >=0 then
                                         v_clie_rut:=arr_VAR_rut(1);
                                         v_clie_dv:=arr_VAR_rut(2);
                                    END IF;

                               --     htp.p(v_clie_rut||'<br>');
                             --       htp.p(v_clie_dv||'<br>');
                              When UPPER('PAIS_CODIGO') Then
                                v_pais_codigo:=UPPER(arr_VAR(2));
                              --   htp.p(v_pais_codigo||'<br>');
                              When UPPER('REGI_CODIGO') Then
                                v_regi_codigo:=UPPER(arr_VAR(2));
                              --  htp.p(v_regi_codigo||'<br>');
                              When UPPER('CIUD_CODIGO') Then
                                v_ciud_codigo:=UPPER(arr_VAR(2));
                              --   htp.p(v_ciud_codigo||'<br>');
                              when UPPER('CLIE_DESTINATARIO') then
                                v_clie_destinatario:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              WHEN UPPER('CLIE_EMAIL') then
                                v_clie_email:=UPPER(arr_VAR(2));
                              --  htp.p(v_clie_email||'<br>');
                              WHEN UPPER('clie_tel_contacto') then
                                v_clie_tel_contacto:=UPPER(arr_VAR(2));
                              --  htp.p(v_clie_tel_contacto||'<br>');
                              When UPPER('CLIE_DIRECCION') Then
                                v_clie_direccion:=UPPER(arr_VAR(2));
                             --   htp.p(v_clie_direccion||'<br>');
                             WHEN UPPER('CLIE_RETIRO') then
                              v_clie_retiro:=UPPER(arr_VAR(2));
                               -- htp.p(v_clie_retiro||' R<br>');
                             ELSE
                                V_BASURA:='';
                         END CASE;
                    end if;
                   contador:= contador+1;

             end loop;

      end if;

      if (p_operacion='I') then

      begin
      select count(*) into v_cuenta_rut from pove_cliente where CLIE_RUT =  v_clie_rut;
      exception when OTHERS then
        v_cuenta_rut:=-1;
      end;


      if v_cuenta_rut = 0 then
      begin


         INSERT INTO POVE_CLIENTE (CLIE_RUT,
                                   CLIE_DV,
                                   PAIS_CODIGO,
                                   REGI_CODIGO,
                                   CIUD_CODIGO,
                                   CLIE_DESTINATARIO,
                                   CLIE_EMAIL,
                                   CLIE_TEL_CONTACTO,
                                   CLIE_DIRECCION,
                                   CLIE_RETIRO)
              VALUES   (v_clie_rut,
                        v_clie_dv,
                        v_pais_codigo,
                        v_regi_codigo,
                        v_ciud_codigo,
                        v_clie_destinatario,
                        v_clie_email,
                        v_clie_tel_contacto,
                        v_clie_direccion,
                        v_clie_retiro);
              htp.p('{"success":"true","mensaje":"Se ingreso cliente ","tipo_mensaje":"'||v_tipo_mensaje||'"}');
      exception when OTHERS then
                v_cuenta_rut:=-1;
      end;
      ELSIF v_cuenta_rut > 0 then
      begin
      update POVE_CLIENTE set
          CLIE_DV               = V_CLIE_DV   ,
          PAIS_CODIGO           = v_pais_codigo  ,
          REGI_CODIGO           = v_regi_codigo  ,
          CIUD_CODIGO           = v_ciud_codigo  ,
          CLIE_DESTINATARIO     = v_clie_destinatario  ,
          CLIE_EMAIL            = v_clie_email ,
          CLIE_TEL_CONTACTO     = v_clie_tel_contacto ,
          CLIE_DIRECCION        = v_clie_direccion,
          CLIE_RETIRO           = v_clie_retiro
      where CLIE_RUT =  v_clie_rut
      and rownum = 1;
      v_tipo_mensaje:=3;
      htp.p('{"success":"true","mensaje":"Registro actualizado ","tipo_mensaje":"'||v_tipo_mensaje||'"}');
      exception when OTHERS then
                v_cuenta_rut:=-1;
      end;
      end if;

    end if;

end;







PROCEDURE REGISTRA_VENTA(p_variables   in varchar2,
                           p_operacion   in varchar2
                          -- p_diferir_envio          in varchar2 default 'NO'
                         )
IS

    v_tipo_mensaje number(1);
    arr_ls_VAR ARRAY_STR;
    arr_VAR ARRAY_STR;
    arr_VAR_rut ARRAY_STR;
    arr_VAR_rut_vent ARRAY_STR;
    arr_VAR_retiro ARRAY_STR;
    arr_ls_VAR_deta ARRAY_STR;
    v_prod_codigo_VAR ARRAY_STR;
    v_vede_cantidad_VAR ARRAY_STR;
    v_mensaje varchar2(2000);
    result_split NUMBER;
    result_split1 NUMBER;
    result_split2 NUMBER;
    result_split_ventdet NUMBER;
    pl_precio number;
    pl_descuento number;
    pl_venta_codigo number;


    v_ret_code  varchar2(5) :='S';
    v_ret_msg   varchar2(10000) :='';
    v_accion    varchar2(1) ;
    v_secuencia number;
    V_CLIE_COD number;

    v_cuenta_codigo   number;
   -- v_retcode      VARCHAR2 (2) := 'S';
     --TABLA POVE_CLIENTE
    v_clie_codigo           POVE_CLIENTE.clie_codigo%TYPE;
    v_clie_rut              POVE_CLIENTE.CLIE_RUT%TYPE;
    v_clie_dv               POVE_CLIENTE.CLIE_DV%TYPE;
    v_pais_codigo           POVE_CLIENTE.PAIS_CODIGO%TYPE;
    v_regi_codigo           POVE_CLIENTE.REGI_CODIGO%TYPE;
    v_ciud_codigo           POVE_CLIENTE.CIUD_CODIGO%TYPE;
    v_clie_destinatario     POVE_CLIENTE.CLIE_DESTINATARIO%TYPE;
    v_clie_e_mail           POVE_CLIENTE.CLIE_EMAIL%TYPE;
    v_clie_tel_contacto     POVE_CLIENTE.CLIE_TEL_CONTACTO%TYPE;
    v_clie_direccion        POVE_CLIENTE.CLIE_DIRECCION%TYPE;
    v_clie_retiro           POVE_CLIENTE.CLIE_RETIRO%TYPE;
    v_clie_bol_fac          POVE_CLIENTE.CLIE_BOL_FAC%TYPE;
    v_clie_interlocutor     POVE_CLIENTE.CLIE_INTERLOCUTOR%TYPE;
    v_clie_nombre_pila      POVE_CLIENTE.clie_nombre_pila%TYPE;
    v_clie_apellido_paterno POVE_CLIENTE.CLIE_APELLIDO_PATERNO%TYPE;
    v_clie_apellido_materno POVE_CLIENTE.CLIE_APELLIDO_MATERNO%TYPE;
    v_clie_num_direccion    POVE_CLIENTE.CLIE_NUM_DIRECCION%TYPE;
    v_clie_canal_distribucion  POVE_CLIENTE.clie_canal_distribucion%TYPE;


    --TABLA POVE_VENTA
  --  v_clie_codigo           POVE_CLIENTE.CLIE_CODIGO%TYPE;
    v_vent_codigo           POVE_VENTA.VENT_CODIGO%TYPE;
    v_vent_fecha            POVE_VENTA.VENT_FECHA%TYPE;
    v_vent_total            POVE_VENTA.VENT_TOTAL%TYPE;


    --TABLA POVE_VENTA_DETALLE

    v_vede_codigo                   POVE_VENTA_DETALLE.vede_codigo%TYPE;
    --PRUEBA
   -- v_prod_codigo                 VARCHAR2(100);
    v_prod_codigo                   pove_producto_tl.prod_codigo%TYPE;
 --   v_clie_codigo_det               POVE_CLIENTE.CLIE_CODIGO%TYPE;
    v_det_vent_codigo               POVE_VENTA.VENT_CODIGO%TYPE;
    v_esde_codigo                   POVE_ESTADO_DESPACHO.esde_codigo%TYPE;
    v_vede_sub_total                POVE_VENTA_DETALLE.vede_sub_total%TYPE;
    v_vede_descuento                POVE_VENTA_DETALLE.vede_descuento%TYPE;
    v_vede_cantidad                 VARCHAR2(100);--POVE_VENTA_DETALLE.vede_cantidad%TYPE;


--TABLA POVE_VENTA_TRANSACCION

    v_vetr_codigo                   POVE_VENTA_DETALLE.vede_codigo%TYPE;
    v_vetr_fecha                    POVE_VENTA_TRANSACCIONES.VETR_FECHA%TYPE;
    v_vetr_estado                   POVE_VENTA_TRANSACCIONES.VETR_ESTADO%TYPE;
  --  v_vetr_estado VARCHAR2(1):=0;

    V_VETR_BOL_FAC_ENVIA            POVE_VENTA_TRANSACCIONES.VETR_BOL_FAC_ENVIA%TYPE;


  --TABLA POVE_DATO_FACTURA

    v_dato_codigo           POVE_DATOS_FACTURA.dato_codigo%TYPE;
   -- v_clie_codigo           POVE_DATOS_FACTURA.clie_codigo%TYPE;
    v_dato_rut_empr         POVE_DATOS_FACTURA.dato_rut_empr%TYPE;
    v_dato_nombre_emp       POVE_DATOS_FACTURA.dato_nombre_emp%TYPE;
    v_dato_detalle          POVE_DATOS_FACTURA.dato_detalle%TYPE;
    v_dato_prestac_prod     POVE_DATOS_FACTURA.dato_prestac_prod%TYPE;
   -- v_dato_valor_total      POVE_DATOS_FACTURA.dato_valor_total%TYPE;
    v_dato_orden_compra     POVE_DATOS_FACTURA.dato_orden_compra%TYPE;
    v_dato_espec_provee     POVE_DATOS_FACTURA.dato_espec_provee%TYPE;
    v_dato_centro_resp      POVE_DATOS_FACTURA.dato_centro_resp%TYPE;
    v_pais_codigo_fac       POVE_DATOS_FACTURA.PAIS_CODIGO%TYPE;
    v_regi_codigo_fac       POVE_DATOS_FACTURA.REGI_CODIGO%TYPE;
    v_ciud_codigo_fac       POVE_DATOS_FACTURA.CIUD_CODIGO%TYPE;
    v_dato_direccion        POVE_DATOS_FACTURA.DATO_DIRECCION%TYPE;
    v_dato_giro             POVE_DATOS_FACTURA.dato_giro%TYPE;



-- DATOS DE SAP

     v_json json;
     v_cli_cod_carrera             varchar2(100):='SD';
     v_cli_sexo                    varchar2(100):='2';
     v_cli_tratamiento             varchar2(100):='0003';
     v_cli_agrupacion              varchar2(100):='ZC01';
     v_cli_cod_giro                varchar2(100):='PRUEBA';
     v_cli_rubro                    varchar2(100):='PRUEBA';
     v_ret varchar2(1);
     v_msg varchar2(5000);



     v_cuenta_rut   number;

     V_BASURA VARCHAR2(100);
     contador number:=0;
     v_valor boolean;
v_despacho number;
 valor_ins_despacho number;

libros_cookie OWA_COOKIE.cookie;




begin

  libros_cookie := OWA_COOKIE.get ('libros');
  v_prod_codigo    :=  substr(libros_cookie.vals(1),2);

--  cantidad_cookie := OWA_COOKIE.get ('cantidad');
--  v_vede_cantidad    :=  substr(cantidad_cookie.vals(1),2);




 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;

    v_tipo_mensaje:='1';
    v_mensaje:='';
     result_split:= SPLIT(p_variables, '@@', arr_ls_VAR);


    if result_split >=0 then
             FOR i in 1 .. arr_ls_VAR.count-1
             LOOP
                result_split:= SPLIT(arr_ls_VAR(i)||'//', '//', arr_VAR);

                    if result_split=0 then


                       v_mensaje:=v_mensaje || UPPER(arr_VAR(1))||':' || UPPER(arr_VAR(2)) ||'&';


                         CASE  UPPER(arr_VAR(1))
                          WHEN UPPER('CLIE_RUT') then

                                   result_split1:= SPLIT(UPPER(arr_VAR(2))||'-', '-', arr_VAR_rut);
                                    if result_split1 >=0 then
                                         v_clie_rut:=arr_VAR_rut(1);
                                         v_clie_dv:=arr_VAR_rut(2);
                                    END IF;

                               --    htp.p(v_clie_rut||'<br>');
                               --     htp.p(v_clie_dv||'<br>');
                              When UPPER('PAIS_CODIGO') Then
                                v_pais_codigo:=UPPER(arr_VAR(2));
                               -- htp.p(v_pais_codigo||'<br>');
                              When UPPER('REGI_CODIGO') Then
                                v_regi_codigo:=UPPER(arr_VAR(2));
                              When UPPER('CIUD_CODIGO') Then
                                v_ciud_codigo:=UPPER(arr_VAR(2));
                              --  htp.p(v_ciud_codigo||'<br>');
                              when UPPER('CLIE_DESTINATARIO') then
                                v_clie_destinatario:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              when UPPER('CLIE_NOMBRE_PILA') then
                                v_clie_nombre_pila:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              when UPPER('CLIE_APELLIDO_PATERNO') then
                                v_clie_apellido_paterno:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              when UPPER('CLIE_APELLIDO_MATERNO') then
                                v_clie_apellido_materno:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              when UPPER('CLIE_NUM_DIRECCION') then
                                v_clie_num_direccion:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                                when UPPER('CLIE_CANAL_DISTRIBUCION') then
                                v_clie_canal_distribucion:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              WHEN UPPER('CLIE_E_MAIL') then
                                v_clie_e_mail:=UPPER(arr_VAR(2));
                              --  htp.p(v_clie_email||'<br>');
                              WHEN UPPER('clie_tel_contacto') then
                                v_clie_tel_contacto:=UPPER(arr_VAR(2));
                              --  htp.p(v_clie_tel_contacto||'<br>');
                              When UPPER('CLIE_DIRECCION') Then
                                v_clie_direccion:=UPPER(arr_VAR(2));
                             --  htp.p(v_clie_direccion||'<br>');
                             WHEN UPPER('CLIE_RETIRO') then
                              v_clie_retiro:=UPPER(arr_VAR(2));
                            --  htp.p(v_clie_retiro||' R<br>');
                              WHEN UPPER('CLIE_BOL_FAC') then
                              v_clie_bol_fac:=UPPER(arr_VAR(2));
                            --  htp.p(v_clie_bol_fac||' R<br>');
                          --   WHEN UPPER('CLIE_RAZON_SOCIAL') then
                          --    v_clie_razon_social:=UPPER(arr_VAR(2));
                             -- htp.p(v_clie_razon_social||' R<br>');
                             WHEN UPPER('CLIE_CODIGO') then
                              v_clie_codigo:=UPPER(arr_VAR(2));
                            --  htp.p(v_clie_codigo||' R<br>');
                              WHEN UPPER('VENT_TOTAL') then
                              v_vent_total:=UPPER(arr_VAR(2));
                            --  htp.p(v_vent_total||' R<br>');
                              WHEN UPPER('VEDE_DESCUENTO') then
                              v_vede_descuento:=UPPER(arr_VAR(2));
                            --  htp.p(v_vede_descuento||' R<br>');
                              WHEN UPPER('VEDE_SUB_TOTAL') then
                              v_vede_sub_total:=UPPER(arr_VAR(2));
                              WHEN UPPER('clie_interlocutor') then
                                v_clie_interlocutor:=UPPER(arr_VAR(2));
                              --  htp.p(v_clie_tel_contacto||'<br>');
                            --  htp.p(v_vede_sub_total||' R<br>');
                       /*       When UPPER('DATO_RUT_EMPR') Then
                                v_dato_rut_empr:=UPPER(arr_VAR(2));
                               -- htp.p(v_pais_codigo||'<br>');
                              When UPPER('DATO_NOMBRE_EMP') Then
                                v_dato_nombre_emp:=UPPER(arr_VAR(2));
                             --   htp.p(v_regi_codigo||'<br>');
                              When UPPER('DATO_DETALLE') Then
                                v_dato_detalle:=UPPER(arr_VAR(2));
                              --  htp.p(v_ciud_codigo||'<br>');
                              when UPPER('DATO_PRESTAC_PROD') then
                                v_dato_prestac_prod:=UPPER(arr_VAR(2));
                              --   htp.p(v_clie_destinatario||'<br>');
                              WHEN UPPER('DATO_ORDEN_COMPRA') then
                                v_dato_orden_compra:=UPPER(arr_VAR(2));
                              --  htp.p(v_clie_tel_contacto||'<br>');
                              When UPPER('DATO_ESPEC_PROVEE') Then
                                v_dato_espec_provee:=UPPER(arr_VAR(2));
                             --  htp.p(v_clie_direccion||'<br>');
                             WHEN UPPER('DATO_CENTRO_RESP') then
                              v_dato_centro_resp:=UPPER(arr_VAR(2));
                            --  htp.p(v_clie_retiro||' R<br>');
                              WHEN UPPER('DATO_DIRECCION') then
                              v_dato_direccion:=UPPER(arr_VAR(2));
                            --  htp.p(v_clie_bol_fac||' R<br>');
                              WHEN UPPER('DATO_GIRO') then
                              v_dato_giro:=UPPER(arr_VAR(2));
                            --  htp.p(v_vent_total||' R<br>');
                              When UPPER('PAIS_CODIGO1') Then
                                v_pais_codigo_fac:=UPPER(arr_VAR(2));
                               -- htp.p(v_pais_codigo||'<br>');
                              When UPPER('REGI_CODIGO1') Then
                                v_regi_codigo_fac:=UPPER(arr_VAR(2));
                              When UPPER('CIUD_CODIGO1') Then
                                v_ciud_codigo_fac:=UPPER(arr_VAR(2));*/
                              --  htp.p(v_ciud_codigo||'<br>');
                              When UPPER('ls_libros') Then
                                v_prod_codigo:=UPPER(arr_VAR(2));
                              --  htp.p(v_ciud_codigo||'<br>');
                              When UPPER('ls_cantidad') Then
                                v_vede_cantidad:=UPPER(arr_VAR(2));
                              --  htp.p(v_ciud_codigo||'<br>');
                             ELSE
                                V_BASURA:='';
                         END CASE;
                    end if;
                   contador:= contador+1;

             end loop;

      end if;


    IF (p_operacion='I')  THEN


      begin
      select nvl(max(to_number(clie_codigo)),0)+1 into v_clie_codigo from pove_cliente;
      exception when OTHERS then
        v_clie_codigo:=-1;
      end;


      if v_clie_codigo >= 1 then
      begin

v_valor := venta_online.get_esutalca(v_clie_rut);
if v_valor then
  v_factor:=0.7;
else
    v_factor:=0.9; -- se aplica 10% de descuento a personas que no son de la universidad alan riuelme 16.05.2025
end if;

INSERT INTO TMP_DATOS
      (
          VALOR_1,
          VALOR_2,
          VALOR_3
      )
VALUES ('VALIDACION',  v_factor,v_clie_rut);


                       INSERT INTO POVE_CLIENTE (CLIE_CODIGO,
                                                   CLIE_RUT,
                                                   PAIS_CODIGO,
                                                   REGI_CODIGO,
                                                   CIUD_CODIGO,
                                                   CLIE_DV,
                                                   CLIE_DESTINATARIO,
                                                   CLIE_EMAIL,
                                                   CLIE_TEL_CONTACTO,
                                                   CLIE_DIRECCION,
                                                   CLIE_RETIRO,
                                                   CLIE_BOL_FAC,
                                                   CLIE_INTERLOCUTOR,
                                                   CLIE_NOMBRE_PILA,
                                                   CLIE_APELLIDO_PATERNO,
                                                   CLIE_APELLIDO_MATERNO,
                                                   CLIE_NUM_DIRECCION,
                                                   CLIE_CANAL_DISTRIBUCION)
                              VALUES   (v_clie_codigo,
                                        v_clie_rut,
                                        v_pais_codigo,
                                        v_regi_codigo,
                                        v_ciud_codigo,
                                        v_clie_dv,
                                        v_clie_destinatario,
                                        v_clie_e_mail,
                                        v_clie_tel_contacto,
                                        v_clie_direccion,
                                        v_clie_retiro,
                                        v_clie_bol_fac,
                                        v_clie_interlocutor,
                                        v_clie_nombre_pila,
                                        v_clie_apellido_paterno,
                                        v_clie_apellido_materno,
                                        v_clie_num_direccion,
                                        v_clie_canal_distribucion);

                          begin

                            vec_cob03.venta_online.CREA_CLIE_EDIT_SAP(v_clie_codigo);
                          exception when others then
                               htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace);
                          end;

                 begin
                         select nvl(max(to_number(vent_codigo)),0)+1 into v_vent_codigo from pove_venta;

                         exception when others then
                              null;
                         end ;
                         INSERT INTO POVE_VENTA
                                  (
                                      CLIE_CODIGO,
                                      VENT_CODIGO,
                                      VENT_FECHA,
                                      VENT_TOTAL
                                  )
                            VALUES (v_clie_codigo,
                                    v_vent_codigo,
                                    sysdate,
                                    --to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'),
                                    v_vent_total
                                    );




               begin


                  v_prod_codigo:=replace(v_prod_codigo,'/',',');

                  result_split:= SPLIT(v_prod_codigo||'@', '@', v_prod_codigo_VAR); --'@'||

                  result_split:= SPLIT(v_vede_cantidad||'@', '@', v_vede_cantidad_VAR); --'@'||



                     if result_split = 0 then
                         FOR i in 1 .. v_prod_codigo_VAR.count-1 --12
                         LOOP
                            begin

                                  begin
                                  select nvl(max(to_number(vede_codigo)),0)+1 into v_vede_codigo from pove_venta_detalle;
                                  exception when OTHERS then
                                    v_vede_codigo:=-1;
                                  end;


                            if v_vede_codigo >= 1 and  v_vede_codigo is not null and (length(trim(v_prod_codigo_VAR(i))) <> 0 or  length(trim(v_vede_cantidad_VAR(i))) <> 0) then
                           --   select nvl(max(to_number(vede_codigo)),0)+1 into v_vede_codigo from pove_venta_detalle;
/* Formatted on 02-12-2024 17:40:57 (QP5 v5.126) */
INSERT INTO TMP_DATOS
      (
          VALOR_1,
          VALOR_2
      )







VALUES ('POVE_VENTA_DETALLE',  v_factor);


if i = 1 then
      valor_ins_despacho :=  g_despacho;
    else
     valor_ins_despacho :=  0;
end if;

/* Formatted on 02-12-2024 17:40:57 (QP5 v5.126) */
INSERT INTO TMP_DATOS
      (
          VALOR_1,
          VALOR_2
      )

VALUES ('POVE_VENTA_DETALLE',  v_factor);


if i = 1 then
      valor_ins_despacho :=  g_despacho;
    else
     valor_ins_despacho :=  0;
end if;

                               INSERT INTO POVE_VENTA_DETALLE
                                          (
                                              VEDE_CODIGO,
                                              PROD_CODIGO,
                                              CLIE_CODIGO,
                                              VENT_CODIGO,
                                              ESDE_CODIGO,
                                              VEDE_SUB_TOTAL,
                                              VEDE_DESCUENTO,
                                              VEDE_CANTIDAD,
                                              VEDE_DESPACHO
                                          )
                                    VALUES (v_vede_codigo,
                                            v_prod_codigo_VAR(i),
                                            v_clie_codigo ,
                                            v_vent_codigo ,
                                            1 ,
                                            --v_vede_sub_total ,
                                            --v_vede_descuento ,
                                            v_vede_sub_total * v_factor ,
                                            v_vede_sub_total - (v_vede_sub_total * v_factor) ,
                                            v_vede_cantidad_VAR(i),
                                            valor_ins_despacho);



    /* htp.p( '                         INSERT INTO POVE_VENTA_DETALLE
                                          (
                                              VEDE_CODIGO,
                                              PROD_CODIGO,
                                              CLIE_CODIGO,
                                              VENT_CODIGO,
                                              ESDE_CODIGO,
                                              VEDE_SUB_TOTAL,
                                              VEDE_DESCUENTO,
                                              VEDE_CANTIDAD
                                          ) VALUES ('''||v_vede_codigo||''','''||
                                            v_prod_codigo_VAR(i)||''' ,''1'', '''||
                                            v_vede_sub_total ||''', '''||
                                            v_vede_descuento||''', '''||
                                            v_vede_cantidad_VAR(i)||''');
'
               );*/


                             end if;
                             exception when others then
                                 null;
                             end ;

                         end loop;
                     end if;
               exception when others then
                    null;
               end ;

               begin
                             select nvl(max(to_number(vetr_codigo)),0)+1 into v_vetr_codigo from pove_venta_transacciones;
                         exception when others then
                              null;
                         end ;
                         INSERT INTO POVE_VENTA_TRANSACCIONES
                                  (
                                      VETR_CODIGO,
                                      CLIE_CODIGO,
                                      VENT_CODIGO,
                                      VETR_FECHA,
                                      VETR_MONTO_PAGAR,
                                      VETR_ESTADO,
                                      VETR_BOL_FAC_ENVIA
                                  )
                            VALUES (v_vetr_codigo,
                                    v_clie_codigo,
                                    v_vent_codigo,
                                    SYSDATE,
                                    --to_char(sysdate,'dd/mm/yyyy hh24:mi:ss') ,
                                    v_vent_total,
                                    0,
                                    0);

/*      begin
      select nvl(max(to_number(dato_codigo)),0)+1 into v_dato_codigo from POVE_DATOS_FACTURA;
      exception when OTHERS then
        null;
      end;
k
          --  htp.p(v_clie_codigo);


                   INSERT INTO POVE_DATOS_FACTURA (DATO_CODIGO,
                                                   CLIE_CODIGO,
                                                   DATO_RUT_EMPR,
                                                   DATO_NOMBRE_EMP,
                                                   DATO_DETALLE,
                                                   DATO_PRESTAC_PROD,
                                                   DATO_VALOR_TOTAL,
                                                   DATO_ORDEN_COMPRA,
                                                   DATO_ESPEC_PROVEE,
                                                   DATO_CENTRO_RESP,
                                                   PAIS_CODIGO,
                                                   REGI_CODIGO,
                                                   CIUD_CODIGO,
                                                   DATO_DIRECCION,
                                                   DATO_GIRO)
                              VALUES   (v_dato_codigo,
                                        v_clie_codigo,
                                        v_dato_rut_empr,
                                        v_dato_nombre_emp,
                                        v_dato_detalle,
                                        v_dato_prestac_prod,
                                        v_vent_total,
                                        v_dato_orden_compra,
                                        v_dato_espec_provee,
                                        v_dato_centro_resp,
                                        v_pais_codigo_fac,
                                        v_regi_codigo_fac,
                                        v_ciud_codigo_fac,
                                        v_dato_direccion,
                                        v_dato_giro);*/

                        commit;






                          htp.p('{"success":"true","mensaje":"Se ingreso cliente ","tipo_mensaje":"'||v_tipo_mensaje||'","id_trx":"'||v_vent_codigo||'"}');



                          exception when OTHERS then
                                    v_clie_codigo:=-1;

            end;


      end if;

  END IF;




/*
           IF (p_operacion='I')  THEN
           COMMIT;
            BEGIN

            -- HTP.P('ENTROOOOOOO');
            envio_correo_ingresar(v_clie_codigo);

           EXCEPTION WHEN OTHERS THEN
               null;
            END ;
        ELSE
           ROLLBACK;
         END IF;

     HTP.p (
            '{"success":"true","ret_code":"'|| v_ret_code||
            '","id_solicitud":"'|| v_clie_codigo||
            '"}');*/

    EXCEPTION
    when others then
         null;
       htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace);

END REGISTRA_VENTA;


PROCEDURE ENVIO_NOTIFICACION IS

    v_ret_code  varchar2(5) :='S';
    v_ret_msg   varchar2(10000) :='';

    v_numero  varchar2(5) := '22';
    v_mensaje  varchar2(10000) :='';
    BEGIN


        IF v_ret_code = 'S' THEN
           COMMIT;
            BEGIN

            HTP.P('ENTROOOOOOO');
           -- envio_correo_ingresar(v_numero);

           EXCEPTION WHEN OTHERS THEN
               v_mensaje := 'Ocurrió un error al enviar el correo:'||replace(SQLERRM,',','' );
                v_ret_code := 'W';
            END ;
        ELSE
           ROLLBACK;
         END IF;

      HTP.p (
            '{"success":"true","ret_code":"'|| v_ret_code||
            '","id_solicitud":"'|| v_numero||
            '"}');




END ENVIO_NOTIFICACION ;

procedure panel_heading_carrito_compra is


 cantidad_cookie OWA_COOKIE.cookie;
 libros_cookie OWA_COOKIE.cookie;



begin

   libros_cookie := OWA_COOKIE.get ('libros');
   cantidad_cookie := OWA_COOKIE.get ('cantidad');




    htp.p('
           <div class="panel-heading">
              <div class="panel-options">
                  <ul class="nav nav-tabs">
                      <li class="active"  ><a data-toggle="tab" href="#tab-1" aria-expanded="true" aria-selected="true"><font><font class=""><i class="fa fa-shopping-cart" aria-hidden="true"></i>CARRITO</font></font></a></li>
                      <li   id="enablee"><a data-toggle="tab" href="#tab-2" aria-expanded="false" aria-selected="false"><font><font class=""><i class="fa fa-paper-plane-o" aria-hidden="true"></i>INFORMACION DE ENVIO</font></font></a></li>
                      <li class=""><a data-toggle="tab" href="#tab-3" aria-expanded="false" aria-selected="false"><font><font class=""><i class="fa fa-credit-card" aria-hidden="true"></i>FINALIZAR Y PAGAR</font></font></a></li>
                      <!--<li class=""><a data-toggle="tab" href="#tab-4" aria-expanded="false"><font><font class="">INFORMACION PERSONAL</font></font></a></li>-->
                  </ul>
              </div>
          </div>

    <script>

     var v_desc_navidad = 0.30;
        function calcular_venta_final (){

          var v_subtotal = document.getElementById("v_subtotalprod").innerHTML;
          var v_total_descuento_det =eval(document.getElementById("v_total_descuento").innerHTML);
        //var v_total_desc =eval(document.getElementById("v_total_descuento").innerHTML);
          var v_valor_desp =eval(document.getElementById("v_valor_despacho").innerHTML);

        document.getElementById("v_total_compra").innerHTML=(parseInt(v_subtotal)- parseInt(v_total_descuento_det))+parseInt(v_valor_desp);

        }

    $(document).ready(function() {

   $(''#btn_continuarpago'').click(function(){



                     calcular_venta_final();

                        var frm = document.getElementById("div_cliente");
                        var variables='''';
                        //alert(frm.elements.length);

                        for (i=0;i<frm.elements.length;i++)
                        {
                           str=frm.elements[i].name;

                            if(str!='''' && str.indexOf("txt_")>=0)
                            {
                                    var str_campo=str;

                                   if (frm.elements[i].type==''radio'')
                                   {
                                          if(frm.elements[i].checked)
                                            {

                                              variables=variables+str_campo.replace(''txt_'','''')+''//''+frm.elements[i].value+''@@'';
                                            }
                                   }
                                   else
                                   {
                                         if (frm.elements[i].type==''select-multiple'')
                                            {
                                              var v_sincomas;
                                              v_sincomas=$(''#''+frm.elements[i].name+'''').chosen().val()+'''';

                                              v_sincomas = v_sincomas.split('','').join(''-'');

                                              v_sincomas=v_sincomas.replace('','',''-'');
                                               variables=variables+str_campo.replace(''txt_'','''')+''//''+v_sincomas+''@@'';
                                            }
                                         else
                                           {
                                            variables=variables+str_campo.replace(''txt_'','''')+''//''+frm.elements[i].value+''@@'';
                                            }
                                   }

                            }

                        }

  /*                      var frm = document.getElementById("frm_facturacion");
                        var variables_fac='''';
                        //alert(frm.elements.length);

                        for (i=0;i<frm.elements.length;i++)
                        {

                           str=frm.elements[i].name;


                            if(str!='''' && str.indexOf("txt_")>=0)
                            {

                                    var str_campo=str;

                                   if (frm.elements[i].type==''radio'')
                                   {
                                          if(frm.elements[i].checked)
                                            {

                                              variables_fac=variables_fac+str_campo.replace(''txt_'','''')+''//''+frm.elements[i].value+''@@'';
                                            }
                                   }
                                   else
                                   {
                                         if (frm.elements[i].type==''select-multiple'')
                                            {
                                              var v_sincomas;
                                              v_sincomas=$(''#''+frm.elements[i].name+'''').chosen().val()+'''';

                                              v_sincomas = v_sincomas.split('','').join(''-'');


                                              v_sincomas=v_sincomas.replace('','',''-'');
                                               variables_fac=variables_fac+str_campo.replace(''txt_'','''')+''//''+v_sincomas+''@@'';

                                            }
                                         else
                                           {
                                            variables_fac=variables_fac+str_campo.replace(''txt_'','''')+''//''+frm.elements[i].value+''@@'';
                                            }
                                   }

                            }

                        }  */

               if(validar(''div_cliente''))
               {

                var today = new Date();
                var dd = today.getDate();
                var mm = today.getMonth()+1; //January is 0!
                var hh = today.getHours();
                var min = today.getMinutes();
                var ss = today.getSeconds();

                var yyyy = today.getFullYear();
                if(dd<10){
                    dd=''0''+dd
                }
                if(mm<10){
                    mm=''0''+mm
                }
                if(hh<10){
                    hh=''0''+hh
                }
                var today = dd+''-''+mm+''-''+yyyy;
                document.getElementById("DATE").value = today;
                var v_fecha_actual = document.getElementById("DATE").value;

                var v_dato_rut_empr =  document.getElementById("txt_dato_rut_empr").value=''0'';

                     var v_subtotal =eval(document.getElementById("v_subtotalprod").innerHTML);
                     var v_total_descuento_detalle =eval(document.getElementById("v_total_descuento").innerHTML);
                     var total_compra=eval(document.getElementById("v_total_compra").innerHTML);
                     var v_valor_desp =eval(document.getElementById("v_valor_despacho").innerHTML);

                     document.getElementById("v_centro_costos_edito").innerHTML = document.getElementById("v_centro_costo").innerHTML
                     var v_centro_resp=document.getElementById("v_centro_costos_edito").innerHTML;


                     var v_pa_codigo = document.getElementById("disp_pais_codigo").value;
                     var v_re_codigo = document.getElementById("disp_regi_codigo").value;
                     var v_ci_codigo = document.getElementById("disp_ciud_codigo").value;




                   if($("#txt_clie_e_mail").val().indexOf(''@'', 0) == -1 || $("#txt_clie_e_mail").val().indexOf(''.'', 0) == -1) {
                        toastr.warning(''El correo electrónico introducido no es correcto.'');
                        document.getElementById(''txt_clie_email'').focus();
                        return false;
                    }

                    // Construcción dinámica de libros y cantidades desde el DOM para evitar obsolescencia de cookies inyectadas por PL/SQL
                     var js_libros_var = "";
                     var js_cantidades_var = "";
                     var textos_inputs = document.getElementsByTagName("input");
                     var vistos_var = {};
                     for (var ll = 0; ll < textos_inputs.length; ll++) {
                         if (textos_inputs[ll].id == ''c_cod_libro'') {
                             var cod = textos_inputs[ll].value;
                             if (!vistos_var[cod]) {
                                 js_libros_var = js_libros_var + ''@'' + cod;
                                 var cant_input = document.getElementById(''c_cantidad_'' + cod);
                                 js_cantidades_var = js_cantidades_var + ''@'' + (cant_input ? cant_input.value : 0);
                                 vistos_var[cod] = true;
                             }
                         }
                     }

                     variables=variables+''dato_centro_resp//''+v_centro_resp+''@@vede_sub_total//''+v_subtotal+''@@pais_codigo1//''+v_pa_codigo+''@@regi_codigo1//''+v_re_codigo+''@@ciud_codigo1//''+v_ci_codigo+''@@vede_descuento//''+v_total_descuento_detalle+''@@vent_total//''+total_compra+''@@ls_libros//''+js_libros_var+''@@ls_cantidad//''+js_cantidades_var+''@@'';



                          // Guardar variables en contexto global para usarlas desde el modal
                          window._venta_variables = variables;

                          // Abrir modal de confirmacion Bootstrap en lugar del confirm() nativo
                          $(''#ModalConfirmarPedido'').modal(''show'');

                          // El boton Confirmar del modal ejecuta el AJAX
                          $(''#btn_confirmar_pedido'').off(''click'').on(''click'', function() {
                              $(''#ModalConfirmarPedido'').modal(''hide'');
                              $.ajax({
                                  url:''venta_online.REGISTRA_VENTA'',
                                  type:''GET'',
                                  data:"p_variables="+window._venta_variables+"&p_operacion=I",
                                  dataType: "json",
                                  success:function(json){ //response
                                      comprobar(json.id_trx);
                                  }
                              });
                          });


                }else{
                    alert(''No se ha podido realizar la venta'');

                }
        });

    });

</script>


<script>

   function validar(nombre_div)
{


    var sAux="";

    var frm = document.getElementById(nombre_div);

    for (i=0;i<frm.elements.length;i++)
    {


    if ( frm.elements[i].classList.contains(''obligatorio'') )
        {


            if ( (frm.elements[i].type==''text'' || frm.elements[i].type==''password'') && frm.elements[i].value=='''')
            {


                        mostrar_toastr( ''"''+ frm.elements[i].placeholder +  ''" CAMPO REQUERIDO'',2);
                        frm.elements[i].focus();
                        return false;

                        break;
            }
            if (frm.elements[i].type==''select-one'' &&  $(''#''+frm.elements[i].name).val()==''-1'')
            {
                        mostrar_toastr(''"''+ $(''#''+frm.elements[i].name+'' option:selected'').text() + ''" CAMPO REQUERIDO'',2);
                        frm.elements[i].focus();
                        return false;

                        break;
            }
        }
    }
    return true;

}


</script>


    ');

end;

function leer_cookie (cadena in varchar2) return varchar2 is

 result_split NUMBER;
 arr_ls_VAR ARRAY_STR;
  arr_VAR ARRAY_STR;
begin


  result_split:= SPLIT(cadena, ';', arr_ls_VAR);
    FOR i in 1 .. arr_ls_VAR.count-1
             LOOP
               result_split:= SPLIT(arr_ls_VAR(i),'=', arr_VAR);
                 if result_split=0 then
                       if (arr_VAR(1)='libros') then
                           return(arr_VAR(2));
                       end if;
                 end if;

    end loop;
end;



procedure carrito_compra_prueba_cookies is



cantidad_cookie OWA_COOKIE.cookie;
libros_cookie OWA_COOKIE.cookie;
begin


   libros_cookie := OWA_COOKIE.get ('libros');
   cantidad_cookie := OWA_COOKIE.get ('cantidad');



    htp.p('************');
       htp.p('***********
               <script language="javascript">
               alert("'||libros_cookie.vals(1)||'+'||cantidad_cookie.vals(1)||'");
           </script>
    *');

end;


procedure carrito_compra is


cantidad_cookie OWA_COOKIE.cookie;
libros_cookie OWA_COOKIE.cookie;
--nombre_libros_cookie OWA_COOKIE.cookie;



begin


   libros_cookie := OWA_COOKIE.get ('libros');
--   nombre_libros_cookie := OWA_COOKIE.get ('nombre_libros');
   cantidad_cookie := OWA_COOKIE.get ('cantidad');
   estilos;
   encabezado_carrito_compra;
    htp.p('

<style>
   body {
       background-color: #ffffff;
   }
 </style>
        <body>


          <div class="row form-horizontal">


                        <div class="col-lg-offset-1 col-lg-10">

                         <script src="'||path_inspinia||'js/jquery-latest.js"></script>


                            <div class="panel blank-panel" >
                            ');
                            panel_heading_carrito_compra;
                            htp.p('
                                <div class="panel-body">
                                    <div class="tab-content">
                                    ');
                                         panel_carrito_tab1;
                                         panel_carrito_tab2;

                                    htp.p('
                                    </div>
                                </div>
                        ');
                        pie_cuadro_ingresos_carrito;
                        htp.p('
                            </div>
                        </div>
                    </div>
            </body>
        ');
        pie_cuadro_carrito_compra;
        librerias_js;
        funcion_json;
        funciones_js;

exception when OTHERs THEN
    htp.p(
        SQLERRM||DBMS_UTILITY.format_error_backtrace
    );

end;

procedure libros is

begin
    htp.p('
        <div class="panel-body">
            <div class="tab-content">
                <div id="tab-1" class="tab-pane active">
                    <div class="col-md-12 b-r" >
                    </br>
                        </br>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/juan_villoro.png" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;SAFARI ACCIDENTAL</strong></h3><br><strong>&nbsp;&nbsp;Juan Villoro</strong>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$15.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/acerca_universidad.jpg" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;ACERCA DE LA UNIVERSIDAD</strong></h3><br><strong>&nbsp;&nbsp;Alvaro Rojas Marin</strong>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$12.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                        <a class="pull-left" onclick="mostrar_detalle();">
                            <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/cuarto_siglo.jpg" class="img-square" alt="image">
                        </a>
                        <h3><strong>&nbsp;&nbsp;UN CUARTO DE SIGLO </strong></h3><br><strong>&nbsp;&nbsp;Juan Antonio Rock</strong>
                        <div class=" ">
                            <label class=""><h3><strong><font>&nbsp;&nbsp;$17.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                            <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                        </div>
                        </div>
                    </div>
                    <div class="col-md-12 b-r" >
                    </br>
                        </br>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/ultimo_ramal.jpg" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;EL ULTIMO RAMAL </strong></h3><br><strong>&nbsp;&nbsp;Juan Pablo Figueroa</strong>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$15.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                               <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>

                            </div>
                        </div>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/pacto_sangre.jpg" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;PACTO DE SANGRE </strong></h3><br><strong>&nbsp;&nbsp;Efrain Barquero</strong>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$13.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/rio_loa.jpg" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;RIO LOA, ESTACION DE LOS SUE?OS</strong></h3><br><strong>&nbsp;&nbsp;Ludwig Zeller</strong>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$15.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-12 b-r" >
                        </br>
                        </br>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/ruegos_nubes.jpg" class="img-square" alt="image">
                            </a>
                            <h3>
                                <strong> &nbsp;&nbsp;RUEGO Y NUBES EN EL AZUL </strong>
                            </h3><br>
                            <strong>&nbsp;&nbsp;Elicura Chihuailaf</strong> <br>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$15.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <a class="pull-left"  onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/humanidad_y_fe.jpg" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;HUMANIDAD Y FE.</strong></h3>
                            <br>
                            <strong>&nbsp;&nbsp;Monse?or Carlos Gonzalez C.</strong> <br>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$15.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <a class="pull-left" onclick="mostrar_detalle();">
                                <img WIDTH=130 HEIGHT=150 src="'||path_inspinia||'img/amantes_guggenheim.jpg" class="img-square" alt="image">
                            </a>
                            <h3><strong>&nbsp;&nbsp;LOS AMANTES DEL GUGGENHEIM</strong></h3><br><strong>&nbsp;&nbsp;Isabel Allende</strong>
                            <div class=" ">
                                <label class=""><h3><strong><font>&nbsp;&nbsp;$15.000&nbsp;&nbsp;&nbsp;&nbsp;</font></strong></h3></label>
                                <a class="btn btn-outline btn-info" onclick="mostrar_detalle();"><i class="fa fa-eye"></i> VER MAS </a>
                            </div>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="col-lg-offset-2 col-lg-10">

                        </div>
                    </div>
                </div>
            </div>

        </div>

    ');
    funcion_json;


end;




procedure venta_lista_libros is


cursor cur_libros is
    SELECT a.prod_codigo,a.prod_nombre, a.prod_descripcion, a.prod_precio,
      a.prod_imagen
     FROM pove_producto_tl a where  a.prod_precio > 0 ; --and a.prod_estado <> 0;

    v_tabla varchar2(100);
    contador number(2);

begin
htp.p('<style>
  textarea {
    resize: none;
    padding: 5px;
    font-family: Tahoma, sans-serif;
    font-size:15px;
}
</style>');

  htp.p('<div class="col-md-12 b-r">');
contador:=0;

FOR fila IN cur_libros LOOP
         if contador=0  then
             htp.p('<div class="col-md-12 b-r"  style=" background-color:#FFF;">
                </br>
                        </br>');
          end if;
        contador:=contador+1;
        htp.p('<div class="col-md-4">
        <table border="0" width="100%">
            <tr>
                 <td rowspan="4">

                    <a class="pull-left" onclick="mostrar_detalles('||fila.prod_codigo||');">
                        <img WIDTH=130 HEIGHT=150 src="'||ruta_imagen||fila.prod_imagen||'" class="img-square" alt="image">
                    </a>
                </td>
            </tr>
            <tr>
                <td colspan="2" align="center">
                    <textarea rows="3" cols="25" style="border:0;">'||fila.prod_codigo||':' ||fila.prod_nombre||'</textarea>
                </td>
            </tr>
            <tr>
                <td colspan="2"  align="center">
                    <textarea rows="1" cols="25" style="border:0; font-size:12px;font-weight: bold;">Alvaro Rojas Marin</textarea>
                </td>
            </tr>
            <tr>
                <td align="center" width="50%">

                        <label class=""><h3><strong><font>$'||fila.prod_precio||'</font></strong></h3></label>
                </td>
                 <td align="right" width="50%">
                        <a class="btn btn-outline btn-info" onclick="mostrar_detalles('||fila.prod_codigo||');"><i class="fa fa-eye"></i> VER MAS </a>

                </td>
            </tr>
            </table>
                </div>
                        ');
          if contador=3 then

              htp.p('</div>');
               contador:=0;
          end if;
 end loop;

          if contador<3 then

              htp.p('</div>');
          end if;

  htp.p('</div>');
 modal_desc_libro;
  htp.p('



    <script>


    function mostrar_detalles(id){

        var v_data = ''p_prod_codigo=''+id;



   $.ajax({
                   url:''venta_online.json_libros'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",
                   success:function(response){



                          document.getElementById(''modal_prod_nombre'').innerHTML=response.prod_nombre;
                          document.getElementById(''modal_prod_precio'').innerHTML=response.prod_precio;
                          document.getElementById(''modal_prod_descripcion'').innerHTML= response.prod_descripcion;
                          document.getElementById(''modal_prod_imagen'').src= "'||ruta_imagen_libros||'"+ response.prod_imagen;


            }

        });


       $("#ModalDetalles").modal(''toggle'');


    }

    </script>

  ');

end;




procedure escribir (v_libros  in varchar2, --v_nombre_libros  in varchar2,
                    v_cantidad in varchar2, v_limpiacookie in number default 0 ) is
cantidad_cookie OWA_COOKIE.cookie;
libros_cookie OWA_COOKIE.cookie;
--nombre_libros_cookie OWA_COOKIE.cookie;
v_libros_antes varchar2(4000);
--v_nombre_libros_antes varchar2(4000);
v_cantidad_antes varchar2(4000);

BEGIN

            libros_cookie := OWA_COOKIE.get ('libros');
   --         nombre_libros_cookie := OWA_COOKIE.get ('nombre_libros');
            cantidad_cookie := OWA_COOKIE.get ('cantidad');

  -- v_libros_antes:= cantidad_cookie.vals(1);

  begin
         v_libros_antes:=libros_cookie.vals(1);--leer_cookie(owa_util.get_cgi_env('HTTP_COOKIE')) ;
     EXCEPTION
     WHEN OTHERS THEN
       v_libros_antes:='';
  end;



/*  begin
         v_nombre_libros_antes:=nombre_libros_cookie.vals(1);--leer_cookie(owa_util.get_cgi_env('HTTP_COOKIE')) ;
     EXCEPTION
     WHEN OTHERS THEN
       v_nombre_libros_antes:='';
  end;*/


   begin
         v_cantidad_antes:=cantidad_cookie.vals(1);--leer_cookie(owa_util.get_cgi_env('HTTP_COOKIE')) ;
     EXCEPTION
     WHEN OTHERS THEN
       v_cantidad_antes:='';
  end;



--v_libros_antes:='';
--v_cantidad_antes:='';

  if v_limpiacookie=1 then
   owa_util.mime_header('text/html', FALSE);
   owa_cookie.send('libros',v_libros, sysdate + 1);
  -- owa_cookie.send('nombre_libros',v_libros, sysdate + 1);
   owa_cookie.send('cantidad', v_cantidad, sysdate + 1);
   owa_util.http_header_close;

else
   owa_util.mime_header('text/html', FALSE);
   owa_cookie.send('libros',v_libros_antes||'@'||v_libros, sysdate + 1);
  -- owa_cookie.send('nombre_libros',v_libros_antes||'@'||v_libros, sysdate + 1);
   owa_cookie.send('cantidad', v_cantidad_antes||'@'||v_cantidad, sysdate + 1);
   owa_util.http_header_close;
 end if;

end;


procedure servicio_muestra_libros_prueba is
begin



htp.p('<style>
  textarea {
    resize: none;
    padding: 5px;
    font-family: Tahoma, sans-serif;
    font-size:15px;
}
</style>');


htp.p('<div id="pepito" class="col-md-12 b-r">

</div>');

 modal_desc_libro;

 htp.p('
    <script>

    $(document).ready(function(){

    $("#btn_carrito").click ( function (e)
    {
          e.preventDefault();
          alert(''ENTRO'');

/*
          var v_data = ''v_libros=''+document.getElementById(''modal_prod_codigo'').value +''&v_nombre_libros=''+document.getElementById(''modal_prod_nombre'').value +''&v_cantidad=''+document.getElementById(''modal_prod_cantidad'').value;

           $.ajax({
                   url:''venta_online.escribir'',
                   type:''GET'',
                   data: v_data,

                   success:function(response){

                          $("#myModal5").modal("toggle");
                        document.location.href=''venta_online.contacto_tecnico'';



            }

        });
*/

      }
    );

    });

    function mostrar_detalles(id){

        var v_data = ''p_prod_codigo=''+id;



   $.ajax({
                   url:''venta_online.json_libros'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",
                   success:function(response){


                         document.getElementById(''modal_prod_codigo'').innerHTML=response.data[0].PROD_CODIGO;
                          document.getElementById(''modal_prod_nombre'').innerHTML=response.data[0].PROD_NOMBRE;
                          document.getElementById(''modal_prod_precio'').innerHTML=response.data[0].PROD_PRECIO;
                          document.getElementById(''modal_prod_descripcion'').innerHTML= response.data[0].PROD_DESCRIPCION;
                          document.getElementById(''modal_prod_imagen'').src= "'||ruta_imagen_libros||'"+ response.data[0].PROD_IMAGEN;
                          document.getElementById(''modal_autores'').innerHTML= response.data[0].AUTORES;
                          document.getElementById(''modal_isbn'').innerHTML= response.data[0].LIBR_ISBN;
                          document.getElementById(''modal_agno'').innerHTML= response.data[0].LIBR_AGNO;
                          document.getElementById(''modal_num_paginas'').innerHTML= response.data[0].LIBR_NUM_PAGINAS;
                          document.getElementById(''modal_coleccion'').innerHTML= response.data[0].COLECCION;

            }

        });






       $("#ModalDetalles").modal(''toggle'');


    }

    </script>

  ');




htp.p('


<script>


  $(document).ready(function(){
 var contador=0;
  var a="";
  var url_json="venta_online.get_json_std_1?coleccion=1";
   $.getJSON(url_json, function(response) {


    $.each(response.data, function(key, value){

       if (contador==0)
      {
             a=a+"<div class=''col-md-12 b-r''  style='' background-color:#ffffff;''>";
             a=a+"</br>";

        }
        contador=contador+1;





    a=a+"<div class=''col-md-4''>                                                                                                                                   "+
"        <table border=''0'' width=''100%''>                                                                                                                "+
"            <tr>                                                                                                                                           "+
"                 <td rowspan=''4''>                                                                                                                        "+
"                                                                                                                                                           "+
"                    <a class=''pull-left''>                                                                                                                "+
"                        <img WIDTH=130 HEIGHT=150 src=''http://inet.utalca.cl/inspinia/img/editorial/"+value.PROD_IMAGEN+"'' class=''img-square'' alt=''image''>                            "+
"                    </a>                                                                                                                                   "+
"                </td>                                                                                                                                      "+
"            </tr>                                                                                                                                          "+
"            <tr>                                                                                                                                           "+
"                <td colspan=''2'' align=''center''>                                                                                                        "+
"                    <textarea rows=''3'' cols=''25'' style=''border:0;''>"+value.PROD_CODIGO+":" +value.PROD_NOMBRE+"</textarea>                           "+
"                </td>                                                                                                                                      "+
"            </tr>                                                                                                                                          "+
"            <tr>                                                                                                                                           "+
"                <td colspan=''2''  align=''center''>                                                                                                       "+
"                    <textarea rows=''1'' cols=''25'' style=''border:0; font-size:12px;font-weight: bold;''>"+value.AUTORES+"</textarea>                   "+
"                </td>                                                                                                                                      "+
"            </tr>                                                                                                                                          "+
"            <tr>                                                                                                                                           "+
"                <td align=''center'' width=''50%''>                                                                                                        "+
"                                                                                                                                                           "+
"                        <label class=''''><h3><strong><font>"+value.PROD_PRECIO+"</font></strong></h3></label>                                            "+
"                </td>                                                                                                                                      "+
"                 <td align=''right'' width=''50%''>                                                                                                        "+
"                        <a class=''btn btn-outline btn-info'' onclick=''mostrar_detalles(" +value.PROD_CODIGO+");''><i class=''fa fa-eye''></i> VER MAS </a>"+
"                                                                                                                                                           "+
"                </td>                                                                                                                                      "+
"            </tr>                                                                                                                                          "+
"            </table>                                                                                                                                       "+
"                </div> ";


 if (contador==3)
      {
             a=a+"</div>";
             contador=0;

        }


    });



      if (contador<3) {

             a=a+"</div>";
          }

               document.getElementById("pepito").innerHTML=a;

});


});

   </script>
        ');
end;





procedure servicio_muestra_libros is

cursor cur_categoria is

         SELECT a.tipo_codigo, a.cate_codigo, a.cate_descripcion, a.cate_destacado
           FROM pove_categorias a
          WHERE tipo_codigo = 1
         ORDER BY a.cate_orden;

v_destacado varchar2(500);

begin

-- <link href="'||path_inspinia||'css/bootstrap.min.css" rel="stylesheet">
 --  <link href="'||path_inspinia||'css/style1.css" rel="stylesheet">


htp.p('
<style>
  textarea {
    resize: none;
    padding: 5px;


  }
</style>
<style type="text/css">
body {

    font-family:Arial, Helvetica, sans-serif;
}
</style>

<style type="text/css">
.tit_fichas {
    color:#000;
    font-size:14px;
    font-weight:normal;
    text-decoration:none;
    }

.nombre_fichas {
    color:#779817;
    font-size:14px;
    font-weight:normal;
    text-decoration:none;
    }

.textos2 {
    font-size:11px;
    font-weight: bold;
    text-decoration:none;
    color:#000;
    line-height:14px;
    }

    .valor2 {
    color:#FFF;

    font-size:14px;
    font-weight:bold;
    text-decoration:none;
    }
    /* SEARCH PAGE */
.search-form {
  margin-top: 10px;a
}



</style>

');

barra_busqueda;


 modal_desc_libro;

 htp.p('
    <script>


    $(document).ready(function(){

    $("#btn_carrito").click ( function (e)
    {
          e.preventDefault();

/*

           bootbox.confirm(" MANTENDREMOS NUESTRA PAGINA CERRADA DEBIDO AL  RECESO UNIVERSITARIO, HASTA FINES DE MARZO", function(result) {

                null;
           });  */

/*iniciamos proceso  de bloqueo*/
     var v_data = ''v_libros=''+document.getElementById(''modal_prod_codigo'').value+''&v_cantidad=''+document.getElementById(''modal_prod_cantidad'').value;

           $.ajax({
                   url:''venta_online.escribir'',
                   type:''GET'',
                   data: v_data,

                   success:function(response){


                      document.location.href=''venta_online.carrito_compra'';



            }

        });
      }    
    );

    });

    function mostrar_detalles(id){

        var v_data = ''p_prod_codigo=''+id;



   $.ajax({
                   url:''venta_online.json_libros'',
                   type:''GET'',
                   data: v_data,
                   dataType: "json",
                   success:function(response){

                          var v_imagen=response.data[0].PROD_IMAGEN;
                         v_imagen=v_imagen.toLowerCase();

                          if(response.data[0].PROD_PRECIO == 0 ){
                            document.getElementById(''modal_prod_codigo'').innerHTML=response.data[0].PROD_CODIGO;
                            document.getElementById(''modal_prod_nombre'').innerHTML=response.data[0].PROD_NOMBRE;
                            document.getElementById(''modal_prod_descripcion'').innerHTML= response.data[0].PROD_DESCRIPCION;
                            document.getElementById(''modal_prod_imagen'').src= "'||ruta_imagen_libros||'"+ v_imagen;
                            document.getElementById(''modal_autores'').innerHTML= response.data[0].AUTORES;
                            document.getElementById(''modal_isbn'').innerHTML= response.data[0].LIBR_ISBN;
                            document.getElementById(''modal_agno'').innerHTML= response.data[0].LIBR_AGNO;
                            document.getElementById(''modal_num_paginas'').innerHTML= response.data[0].LIBR_NUM_PAGINAS;
                            document.getElementById(''modal_coleccion'').innerHTML= response.data[0].COLECCION;
                             document.getElementById("trAgotado").style.display = "none";
                             document.getElementById("btnAgregar").style.display = "none";
                             document.getElementById("mostrarAgo").style.display = "block";


                          //document.getElementById(''modal_prod_precio'').innerHTML=response.data[0].PROD_PRECIO;
                          }else{

                            document.getElementById(''modal_prod_codigo'').innerHTML=response.data[0].PROD_CODIGO;
                            document.getElementById(''modal_prod_nombre'').innerHTML=response.data[0].PROD_NOMBRE;
                            document.getElementById(''modal_prod_precio'').innerHTML=response.data[0].PROD_PRECIO;
                            document.getElementById(''modal_prod_descripcion'').innerHTML= response.data[0].PROD_DESCRIPCION;
                            document.getElementById(''modal_prod_imagen'').src= "'||ruta_imagen_libros||'"+ v_imagen;
                            document.getElementById(''modal_autores'').innerHTML= response.data[0].AUTORES;
                            document.getElementById(''modal_isbn'').innerHTML= response.data[0].LIBR_ISBN;
                            document.getElementById(''modal_agno'').innerHTML= response.data[0].LIBR_AGNO;
                            document.getElementById(''modal_num_paginas'').innerHTML= response.data[0].LIBR_NUM_PAGINAS;
                            document.getElementById(''modal_coleccion'').innerHTML= response.data[0].COLECCION;
                             document.getElementById("trAgotado").style.display = "block";
                              document.getElementById("btnAgregar").style.display = "block";
                              document.getElementById("mostrarAgo").style.display = "none";
                          }

            }

        });

       $("#ModalDetalles").modal(''toggle'');


    }

    </script>



');

FOR fila IN cur_categoria LOOP

htp.p('<div id="pepito_'||fila.cate_codigo||'" class="col-md-12 b-r">


</div>');
end loop;



htp.p('<script>


 function cargar_libros ()
 {




 valor_texto= document.getElementById(''search'').value;





');
FOR fila IN cur_categoria LOOP


IF fila.cate_destacado=1 THEN
/**<img src=''http://inet.utalca.cl/inspinia/img/editorial/nuevo.jpg'' width=''50'' height=''50''>**/
    v_destacado:='COLECCIÓN </span>" + response.data[0].CATE_DESCRIPCION +"&nbsp;';

ELSE
    v_destacado:='COLECCIÓN </span>" + response.data[0].CATE_DESCRIPCION +"';
END IF;

htp.p('



 var contador=0;
  var a="";
  var b="";

 var url_json="venta_online.get_json_std_1?coleccion='||fila.cate_codigo||'&texto_busqueda="+valor_texto;

 var autorizacion="'||utal_dti.p_encrypt_utal.encrypt_ssn(to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')||'@'||SYS_CONTEXT('USERENV', 'IP_ADDRESS', 15))||'";


 $.ajaxSetup({
  headers : {
    ''Authorization'' : autorizacion
  }
});
   $.getJSON(url_json)

   .done(
    function(response) {
      if (response.data!='''')
      {
      a=a+"<table id=''table1'' width=''1000'' align=''center'' border=''0'' cellspacing=''0'' cellpadding=''0''>";
      a=a+"<tr height=''50''>";
           a=a+"<td width=''50''>&nbsp;</td>";
           a=a+"<td valign=''bottom'' style=''border-style: none none dotted;''>";
                  a=a+"<strong><span style=''color:red;''>'|| v_destacado||' </strong>";
           a=a+"</td>";
           a=a+"<td width=''50''>&nbsp;</td>";

       a=a+"</tr>";
      a=a+"</table>"


      a=a+"<table id=''table1'' width=''1000'' align=''center'' border=''0'' cellspacing=''0'' cellpadding=''0''>";

    $.each(response.data, function(key, value){

       if (contador==0)
      {
                       a=a + "<tr>";

        }
        contador=contador+1;
       var v_imagen=value.PROD_IMAGEN;
        var v_imagen=v_imagen.toLowerCase();





a= a + "<td valign=''top''> <table width=''250'' border=''0'' cellspacing=''0'' cellpadding=''0''>                                                                      " +
"   <tr>                                                                                                                                      " +
"     <td width=''50''>&nbsp;</td>                                                                                                           " +
"     <td width=''185''>&nbsp;</td>                                                                                                           " +
"     <td width=''15''>&nbsp;</td>                                                                                                            " +
"   </tr>                                                                                                                                     " +
"   <tr>                                                                                                                                      " +
"     <td>&nbsp;</td>                                                                                                                         " +
"     <td><a onclick=''mostrar_detalles(" +value.PROD_CODIGO+");''><img src=''http://inet.utalca.cl/inspinia/img/editorial/"+v_imagen+"'' width=''157'' height=''203''></a></td>                  " +
"     <td>&nbsp;</td>                                                                                                                         " +
"   </tr>                                                                                                                                     " +
"   <tr>                                                                                                                                      " +
"     <td>&nbsp;</td>                                                                                                                         " +
"     <td><span class=''textos2''><br>                                                                                                        " +
"       </span><span class=''tit_fichas''><strong><textarea rows=''3''  style=''border:0;'' readonly>" +value.PROD_NOMBRE+"</textarea></strong></span> " +
"       <span class=''tit_fichas''>&nbsp;</span><span class=''textos''>" +
"       </span><span class=''nombre_fichas''><strong><textarea rows=''3''  style=''border:0;'' readonly>"+value.AUTORES+"</textarea></strong></span></td>                                                   " +
"     <td>&nbsp;</td>                                                                                                                           " +
"   </tr>                                                                                                                                       " +
"   <tr>                                                                                                                                        " +
"     <td>&nbsp;</td>                                                                                                                           " +
"     <td>                                                                                                                                      " +
"     <table width=''185'' border=''0'' cellspacing=''0'' cellpadding=''0''>   ";
if(+value.PROD_PRECIO == 0 ){
a=a+ " <tr>   ";
a=a+ "  <td width=''139'' align=''center'' bgcolor=''#c2c2bf'' class=''''>AGOTADO</td> ";<!--valor2-->
        }else{
a=a+ "  <td width=''139'' align=''center'' bgcolor=''#c2c2bf'' class=''valor2''>$"+value.PROD_PRECIO+"</td> ";
      }
a= a + "<td width=''46'' align=''right'' valign=''top''><a onclick=''mostrar_detalles(" +value.PROD_CODIGO+");'' class=''thickbox'' target=''_parent''><img src=''http://inet.utalca.cl/inspinia/img/ojo.jpg'' width=''46'' height=''26''></a></td> ";
a= a + "</tr>                                                                                                                                   "+
"     </table>                                                                                                                                  " +
"     </td>                                                                                                                                     " +
"     <td>&nbsp;</td>                                                                                                                           " +
"   </tr>                                                                                                                                       " +
"                                                                                                                                               " +
"</table> </td> ";



 if (contador==4)
      {

             a=a+"</tr><tr>";
             contador=0;

        }


    });



      if (contador<4) {

             b=b+"</div>";

             for (i = contador; i < 4; i++) {

             a=a+"<td valign=''top''>&nbsp;</td>";

                        }
             a=a+"</tr>";

          }
        a=a+"</table>";
}


               document.getElementById("pepito_'||fila.cate_codigo||'").innerHTML=a;
               a="";
               contador=0;



});



        ');

  end loop; --cursor categorias
  htp.p('

  }


   $(document).ready(function(){
    cargar_libros ();
  });
  </script>');
  --pie_pagina_editorial;

end;


procedure servicio_array_libros is

     v_url varchar2(500) ;
    request    UTL_HTTP.REQ;
    response  UTL_HTTP.RESP;
    v_line   VARCHAR2(1024);
    v_count  number := 0;
    v_return_pg varchar2(32000):='';
   --  v_return_pg_final varchar2(32000):='';
     buff VARCHAR2(4000);

      clob_buff CLOB;
       n NUMBER;

begin
    UTL_HTTP.SET_RESPONSE_ERROR_CHECK(FALSE);

    --v_url:='http://condor2.utalca.cl/pls/sap/pkg_integra_utal.Get_deuda_estudiante?v_rut_est=19390712';
    v_url:='http://condor2-19testing.utalca.cl/pls/sap/pkg_integra_utal.Get_deuda_estudiante?v_rut_est=19390712';

    request  :=  UTL_HTTP.BEGIN_REQUEST(v_url, 'GET');
    UTL_HTTP.SET_HEADER(request, 'User-Agent', 'Mozilla/4.0');

    response  := UTL_HTTP.GET_RESPONSE(request);
    IF response.status_code = 200 THEN
        BEGIN

          clob_buff := EMPTY_CLOB;
            LOOP
                UTL_HTTP.READ_TEXT(response, buff, LENGTH(buff));
                clob_buff := clob_buff || buff;
            END LOOP;
        UTL_HTTP.END_RESPONSE(response);

        EXCEPTION
        WHEN UTL_HTTP.END_OF_BODY THEN
                UTL_HTTP.END_RESPONSE(response);
        WHEN OTHERS THEN
                htp.p(SQLERRM);
                htp.p(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                UTL_HTTP.END_RESPONSE(response);
        end;

        SELECT COUNT(*) + 1 INTO n FROM WWW_DATA;
        INSERT INTO WWW_DATA VALUES (n, clob_buff);
        COMMIT;
   ELSE
        htp.p('No ejecuto pagina'||response.status_code);
        UTL_HTTP.END_RESPONSE(response);
   end if;



end;



procedure inicio is
cursor cur_botones is
    SELECT * FROM gene_menu_boton;
    v_tabla varchar2(100);
begin
FOR fila IN cur_botones LOOP

            CASE fila.MEBO_ID

            When 1001 Then
                v_tabla:='pove_producto_tl_tl';
            When 1002 Then
                 v_tabla:='POVE_CATEGORIAS';
            When 1003 Then
                 v_tabla:='POVE_AUTOR';
            Else
                v_tabla:='GENE_USUARIO';

         END CASE;

htp.p('<div class="col-lg-3">
 <a href="'||fila.MEBO_LINK||'?m='||fila.MEBO_ID||'">
                <div class="widget style1 '||fila.MEBO_COLOR||'">
                    <div class="row">
                        <div class="col-xs-4">
                            <i class="fa '||fila.MEBO_IMAGEN||' fa-5x"></i>
                        </div>
                        <div class="col-xs-8 text-right">
                            <span>'||fila.MEBO_NOMBRE||' </span>
                            <h2 class="font-bold">'||contar_registros(v_tabla)||'</h2>
                        </div>
                    </div>
                </div>
    </a>
  </div>');
 end loop;
end;


function contar_registros(p_tabla in varchar2) return number is
numero_registros number;
v_sql varchar2(100);
begin

     v_sql:=' select count(*)  from '||p_tabla;
  EXECUTE IMMEDIATE v_sql INTO numero_registros;

  return numero_registros;

end;


procedure encabezado_carrito_compra(p_titulo_pagina in varchar2 default null) is

begin
    htp.p('


          <!--********-->
                 <div class="row">
                <div class="col-lg-12">
                    <div class="ibox float-e-margins">


                        <div class="ibox-content">




    ');
end;



procedure encabezado_cuadro(p_titulo_pagina in varchar2 default null) is

begin
    htp.p('


          <!--********-->
                 <div class="row">
                <div class="col-lg-10">
                    <div class="ibox float-e-margins">
                        <div class="ibox-title">
                            <h5>');
                            htp.p(''||p_titulo_pagina||'');
                            htp.p('</h5>
                            <div class="ibox-tools">
                                <a class="collapse-link">
                                    <i class="fa fa-chevron-up"></i>
                                </a>
                                <a class="dropdown-toggle" data-toggle="dropdown" href="#">
                                    <i class="fa fa-wrench"></i>
                                </a>
                                <ul class="dropdown-menu dropdown-user">
                                    <li><a href="#">Ayuda</a>
                                    </li>
                                    <li><a href="#">Manual</a>
                                    </li>
                                </ul>
                                <a class="close-link">
                                    <i class="fa fa-times"></i>
                                </a>
                            </div>

                        </div>

                        <div class="ibox-content">




    ');
end;


procedure libreria_dhtmlx is
begin
    htp.p('<link rel="stylesheet" type="text/css" href="'|| path_dhtmlx||'codebase/dhtmlx.css"/>');
    HTP.p (   '<script src="'|| path_dhtmlx||'codebase/xx_dhtmlx.js"></script>');

end;

procedure dhxtoolbar_xml(dhxr                    VARCHAR DEFAULT NULL)
 is
begin
      OWA_UTIL.mime_header ('text/xml', FALSE);
      OWA_UTIL.http_header_close;
      htp.p('<?xml version=''1.0'' encoding=''ISO-8859-1''?>');
      htp.p('<toolbar>');

        htp.p('<item id="nueva_ficha" type="button"  img="new.gif" imgdis="new_dis.gif" text="Nuevo"/>');
        htp.p('<item id="sep1" type="separator"/>');
        htp.p('<item id="guardar_ficha" type="button"  img="save.gif" imgdis="save_dis.gif" text="Guargar"/>');
        htp.p('<item id="sep2" type="separator"/>');
        htp.p('<item id="eliminar_ficha" type="button"  img="eliminar.gif" imgdis="eliminar_dis.gif" text="Eliminar"/>');
        htp.p('<item id="sep2" type="separator"/>');
        htp.p('</toolbar>');
end dhxtoolbar_xml;


procedure toolbar is
begin

    libreria_dhtmlx;
    htp.p('
    </head>

    <div style="position:relative;width:100%;">
        <div id="toolbarObj"></div>
        <div id="response-container"></div>
    </div>

<script>
        var myToolbar;
                    myToolbar = new dhtmlXToolbarObject("toolbarObj");
                    //myToolbar = new dhtmlXToolbarObject({ parent: "toolbarObj",skin: tbSkin});
                    myToolbar.setIconSize(24);
                    myToolbar.setIconsPath("'||path_dhtmlx_36||'dhtmlxToolbar/samples/common/imgs/");
                    myToolbar.loadStruct("VENTA_ONLINE.dhxtoolbar_xml");
                    tbIconSize = 24;
                    myToolbar.attachEvent("onClick", function(id) {
                                llamarguardar(id);
                                //llamarnuevo(id);

                        });

</script>');


end;

procedure pie_cuadro_ingresos_carrito is
begin

    htp.p('
        </div>
            ');
            --toobar_carrito_compra;
            htp.p('
            </div>

            </div>

        </div>
    ');

end;

procedure pie_cuadro_ingresos is
begin
    htp.p('
        </div>
            ');
                toolbar;
            htp.p('
            </div>

            </div>

        </div>
    ');

end;

procedure pie_cuadro_carrito_compra is
begin
    htp.p('
        </div>
            ');


end;


procedure pie_cuadro_listado is
begin
    htp.p('
        </div>
            ');

            htp.p('
            </div>

            </div>

        </div>
    ');

end;

procedure funcion_json is
begin



    htp.p('

<script>


   function validar(nombre_div)
{


    var sAux="";
    var frm = document.getElementById(nombre_div);

    for (i=0;i<frm.elements.length;i++)
    {


    if ( frm.elements[i].classList.contains(''obligatorio'') )
        {


            if ( (frm.elements[i].type==''text'' || frm.elements[i].type==''password'') && frm.elements[i].value=='''')
            {


                        mostrar_toastr( ''"''+ frm.elements[i].placeholder +  ''" CAMPO REQUERIDO'',2);
                        frm.elements[i].focus();
                        return false;

                        break;
            }
            if (frm.elements[i].type==''select-one'' &&  $(''#''+frm.elements[i].name).val()==''-1'')
            {
                        mostrar_toastr(''"''+ $(''#''+frm.elements[i].name+'' option:selected'').text() + ''" CAMPO REQUERIDO'',2);
                        frm.elements[i].focus();
                        return false;

                        break;
            }
        }
    }
    return true;

}

    $(document).ready(function(){

    var allParas = document.getElementsByTagName("input");

    for (i=0;i<allParas.length;i++)
    {
        obj_texto=allParas[i];
        str=obj_texto.name;
        if(str.indexOf("txt_")>=0)
        {

           $(''#''+str).css("text-transform", "uppercase");


              $(''#''+str).change(function( event ) {




           });



           $(''#''+str).keypress(function( event ) {

                var charCode = (event.which) ? event.which : event.keyCode;


               if(this.classList.contains(''solonumero''))
               {

                    if (charCode > 31 && (charCode < 48 || charCode > 57))
                    {

                         event.preventDefault();
                    }
               }



           });

        }
    }

});

function Limpiar()
{

    var sAux="";
    var frm = document.getElementById("div_ficha");
    if (frm) {
        for (i=0;i<frm.elements.length;i++)
        {


            var str=frm.elements[i].name;
            if (frm.elements[i].type==''textarea'' || frm.elements[i].type==''text'' && str.indexOf("txt_")>=0  )
            {

                        frm.elements[i].value='''';
                }
            if (frm.elements[i].type==''select-one'')
            {
                $(''#''+frm.elements[i].name).val(-1);
                $(''#''+frm.elements[i].name).trigger("chosen:updated");

            }

        }
    }');

      CASE g_m

            When 180 Then
                htp.p('Buscar_num_max('''');');
            When 181 Then

                htp.p('Buscar_num_max(''-1'');');
            When 183 Then
                htp.p('Buscar_num_max('''');');
            --When 184 Then
              --  htp.p('Buscar_num_max('''');');
            When 184 Then
                htp.p('Buscar_num_max('''');');
            When 185 Then
                htp.p('Buscar_num_max(''-1'');');
            When 187 Then
                htp.p('Buscar_num_max('''');');
            When 192 Then
                htp.p('Buscar_num_max('''');');
           else
                htp.p('');

         END CASE;
htp.p('}


</script>

<script>

    function llamarguardar(id)
        {

                        var frm = document.getElementById("div_ficha");
                        var variables='''';  //pantalla='||g_m||'&variables=

                        for (i=0;i<frm.elements.length;i++)
                        {
                            if(frm.elements[i].name!='''')
                            {

                                    var str_campo=frm.elements[i].name;

                                   if (frm.elements[i].type==''radio'')
                                   {
                                          if(frm.elements[i].checked)
                                            {
                                             variables=variables+str_campo.replace(''txt_'','''')+''//''+frm.elements[i].value+''@@'';
                                            }
                                   }
                                   else
                                   {
                                         if (frm.elements[i].type==''select-multiple'')
                                            {
                                              var v_sincomas;
                                              v_sincomas=$(''#''+frm.elements[i].name+'''').chosen().val()+'''';

                                              v_sincomas = v_sincomas.split('','').join(''-'');


                                              v_sincomas=v_sincomas.replace('','',''-'');
                                               variables=variables+str_campo.replace(''txt_'','''')+''//''+v_sincomas+''@@'';

                                            }
                                         else
                                           {
                                            variables=variables+str_campo.replace(''txt_'','''')+''//''+frm.elements[i].value+''@@'';
                                            }
                                   }

                            }

                        }




            if(id==''nueva_ficha''){

               Limpiar();

            }

            if (id==''eliminar_ficha'')
            {
                $(document).ready(function(){

                var var_elresultado=false;
                bootbox.confirm("Desea Eliminar el Registro?", function(result) {
                     if(result)
                     {

                         $.ajax({
                                    url:''venta_online.recibe_solicitud'',
                                    type:''GET'',
                                    data:"p_pantalla='||g_m||'&p_variables="+variables+"&p_operacion=E",
                                    dataType: "json",
                                    success:function(response){

                                        mostrar_toastr(response.mensaje, response.tipo_mensaje);
                                        Limpiar();

                                       if ('||nvl(g_m, 0)||'==180)
                                       {
                                         ReCargar_grilla_tipo(''#txt_tipo_codigo'');


                                       }
                                       if ('||nvl(g_m, 0)||'==181)
                                       {
                                         ReCargar_grilla_categoria($(''#txt_tipo_codigo'').chosen().val());


                                       }
                                       if ('||nvl(g_m, 0)||'==183)
                                       {
                                         ReCargar_grilla_autor(''#txt_auto_codigo'');

                                       }
                                       if ('||nvl(g_m, 0)||'==184)
                                       {
                                         ReCargar_grilla_paises(''#txt_pais_codigo'');

                                       }
                                       if ('||nvl(g_m, 0)||'==185)
                                       {
                                         ReCargar_grilla_regiones($(''#txt_pais_codigo'').chosen().val());


                                       }
                                       if ('||nvl(g_m, 0)||'==187)
                                       {
                                         ReCargar_grilla_estado_despacho(''#txt_esde_codigo'');

                                       }
                                       if ('||nvl(g_m, 0)||'==192)
                                       {
                                         ReCargar_grilla_tarifa_despacho(''#txt_tade_codigo'');

                                       }
                            }});

                     }


                });

               });
            }

            if (id==''guardar_ficha'')
            {

               $(document).ready(function(){


                           if(validar(''div_ficha''))
                           {');

                              if   g_m=133 then

                           -- htp.p('alert(variables);');

                              htp.p('



                                var conteo_select = document.getElementById("conteo").innerHTML;

                             //  var v_auto_codigo1 = document.getElementById("txt_auto_codigo").value;
                                 var v_libr_codigo1 =  document.getElementById("txt_libr_codigo").value=''0'';
                                 var v_prod_codigo1 =  document.getElementById("txt_prod_codigo").value=''0'';



                                   // var v_archivo1 = document.getElementById("archivos1").files.length;
                                    var file2 = $("#archivos1")[0].files[0];
                                    var fileName2 = file2.name;
                                    $("#archivo1").val(fileName2);
                                        // variables=variables+''libr_codigo1//''+v_libr_codigo1+''@@prod_codigo1//''+v_prod_codigo1+''@@liau_posicion//''+conteo_select+''@@prod_imagen//''+fileName2;
                                         variables=variables+''liau_posicion//''+conteo_select+''@@prod_imagen//''+fileName2;
                                         alert(variables);
                                         $.ajax({
                                            url:''venta_online.recibe_solicitud_libros'',
                                            type:''GET'',
                                            data:"p_pantalla='||g_m||'&p_variables="+variables+"&p_operacion=I",
                                            contentType: "application/json; charset='||g_charset||'",
                                            dataType: "json",
                                            success:function(response){

                                                if(p_operacion == "I" ){

                                                toastr.success("LIBRO GUARDADO");

                                                }
                                            },
                                             error: function(){
                                                     toastr.error("Error cargando la pagina Guardar");
                                             }

                                    });




                      ');


                        else
                        htp.p(' $.ajax({
                                    url:''venta_online.recibe_solicitud'',
                                    type:''GET'',
                                    data:"p_pantalla='||g_m||'&p_variables="+variables+"&p_operacion=I",
                                    dataType: "json",
                                    success:function(response){

                                        mostrar_toastr(response.mensaje, response.tipo_mensaje);
                                        Limpiar();
                                       if ('||nvl(g_m, 0)||'==180)
                                       {
                                         ReCargar_grilla_tipo(''#txt_tipo_codigo'');
                                         //alert(''aaaa'');
                                       }
                                       if ('||nvl(g_m, 0)||'==181)
                                       {
                                         //ReCargar_grilla_categoria(''#txt_cate_codigo'');
                                         ReCargar_grilla_categoria($(''#txt_tipo_codigo'').chosen().val());
                                       }
                                       if ('||nvl(g_m, 0)||'==183)
                                       {
                                         ReCargar_grilla_autor(''#txt_auto_codigo'');
                                       }
                                       if ('||nvl(g_m, 0)||'==184)
                                       {
                                         ReCargar_grilla_paises(''#txt_pais_codigo'');

                                       }
                                       if ('||nvl(g_m, 0)||'==185)
                                       {

                                         ReCargar_grilla_regiones($(''#txt_pais_codigo'').chosen().val());

                                       }
                                       if ('||nvl(g_m, 0)||'==187)
                                       {
                                         ReCargar_grilla_estado_despacho(''#txt_esde_codigo'');

                                       }
                                       if ('||nvl(g_m, 0)||'==192)
                                       {
                                         ReCargar_grilla_tarifa_despacho(''#txt_tade_codigo'');

                                       }
                                       if ('||nvl(g_m, 0)||'==250){
                                            alert(''paso inser cliente'');

                                       }

                            }});


              ');

             end if; --fin de es ficha de libros
            htp.p(' }
              });
            }
    }
</script>

    ');
end;



procedure recibe_solicitud_libros(p_pantalla       in number,
                        p_variables   in varchar2,
                        p_operacion   in varchar2
                        ) is
 v_tipo_mensaje number(1);
   arr_ls_VAR ARRAY_STR;
   v_auto_codigo_VAR ARRAY_STR;

    v_claves  varchar2(32000);
    v_valores  varchar2(32000);
    arr_VAR ARRAY_STR;
    v_cuenta number(10);
    v_mensaje varchar2(20000);
    result_split NUMBER;
    v_prod_descripcion  pove_producto_tl.PROD_DESCRIPCION%TYPE;
    v_prod_nombre       pove_producto_tl.PROD_NOMBRE%TYPE;
    v_prod_precio       pove_producto_tl.PROD_PRECIO%TYPE;
    V_PROD_CODIGO_SAP   pove_producto_tl.prod_codigo_sap%TYPE;




    v_pove_libr_num_paginas pove_libros.libr_num_paginas%TYPE;
    v_pove_libr_isbn pove_libros.libr_isbn%TYPE;
    v_pove_libr_agno pove_libros.libr_agno%TYPE;





    v_cate_codigo varchar2(100);


    v_codigo_producto        pove_producto_tl.prod_codigo%type;
    v_pove_codigo_libros     pove_libros.libr_codigo%type;
    v_prod_imagen            pove_producto_tl.prod_imagen%TYPE;



    v_auto_codigo    varchar2(100);--pove_libros_autores.auto_codigo%TYPE;
 --CORRECTO;
   -- v_liau_posicion  pove_libros_autores.liau_posicion%TYPE;
      v_liau_posicion  number(3);



    V_BASURA VARCHAR2(100);
    sql_inserta_categoria varchar2(32000);
    sql_inserta_autor   VARCHAR2(32000);


p_error          varchar2(60);

v_ret_code  varchar2(5) :='S';
v_ret_msg   varchar2(10000) :='';


v_accion    varchar2(1);


begin
 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;


    v_tipo_mensaje:='1';
    v_mensaje:='';
     result_split:= SPLIT(p_variables||'@@', '@@', arr_ls_VAR);

     if result_split=0 then
             FOR i in 1 .. arr_ls_VAR.count-1 --12
             LOOP
                result_split:= SPLIT(arr_ls_VAR(i)||'//', '//', arr_VAR);

                    if result_split=0 then

                       v_mensaje:=v_mensaje || UPPER(arr_VAR(1))||':' || UPPER(arr_VAR(2)) ||'&';

                         CASE  UPPER(arr_VAR(1))
                            WHEN UPPER('cate_codigo') then
                                v_cate_codigo:=UPPER(arr_VAR(2));
                             --   htp.p(v_cate_codigo||'<br>');
                             When 'PROD_NOMBRE' Then
                                v_prod_nombre:=UPPER(arr_VAR(2));
                             --   htp.p(v_prod_nombre||'<br>');
                              When upper('auto_codigo') Then
                               v_auto_codigo:=UPPER(arr_VAR(2));
                              -- htp.p(v_auto_codigo||'<br>');
                              When upper('liau_posicion') Then
                               v_liau_posicion:=UPPER(arr_VAR(2));
                              -- htp.p(v_liau_posicion||'<br>');
                             When 'PROD_DESCRIPCION' Then
                                v_prod_descripcion:=UPPER(arr_VAR(2));
                             --   htp.p(v_prod_descripcion||'<br>');
                            when upper('pove_libr_agno') then
                                v_pove_libr_agno:=UPPER(arr_VAR(2));
                            --    htp.p(v_pove_libr_agno||'<br>');
                            WHEN UPPER('pove_libr_num_paginas') then
                                v_pove_libr_num_paginas:=UPPER(arr_VAR(2));
                             --   htp.p(v_pove_libr_num_paginas||'<br>');
                              WHEN UPPER('pove_libr_isbn') then
                                v_pove_libr_isbn:=UPPER(arr_VAR(2));
                             --   htp.p(v_pove_libr_isbn||'<br>');
                            When 'PROD_PRECIO' Then
                                v_prod_precio:=UPPER(arr_VAR(2));
                             --   htp.p(v_prod_precio||'<br>');
                            When 'PROD_IMAGEN' Then
                                v_prod_imagen:=UPPER(arr_VAR(2));
                              --  htp.p(v_prod_imagen||'<br>');
                            When 'PROD_CODIGO_SAP' Then
                                V_PROD_CODIGO_SAP:=UPPER(arr_VAR(2));
                              --  htp.p(v_prod_imagen||'<br>');
                            ELSE
                                V_BASURA:='';
                        END CASE;
                    end if;

             end loop;
      end if;


 if WEB_UTIL.verifica_referer('') then

    if (p_operacion='I') then
                begin
                      select nvl(max(to_number(prod_codigo)),0)+1 into v_codigo_producto from pove_producto_tl;

                      INSERT INTO pove_producto_tl   (prod_codigo,
                                                   prod_nombre,
                                                   prod_descripcion,
                                                   prod_precio,
                                                   prod_imagen,
                                                   prod_estado,
                                                   PROD_CODIGO_SAP)
                                            VALUES (v_codigo_producto,
                                                   v_prod_nombre,
                                                   v_prod_descripcion,
                                                   v_prod_precio,
                                                   v_prod_imagen,
                                                   1,
                                                   V_PROD_CODIGO_SAP);

                 exception
                   when others then
                     p_error:=0;
                 end ;

                 begin

                    v_cate_codigo:=replace(v_cate_codigo,'/',',');
                    sql_inserta_categoria:='INSERT INTO pove_categoria_producto (prod_codigo,tipo_codigo,cate_codigo,capr_estado) '||
                                               ' VALUES   ('''||v_codigo_producto||''','||v_cate_codigo||',1) ';
                    EXECUTE IMMEDIATE sql_inserta_categoria;
                    exception
                        when others then
                        p_error:=0;
                 end ;

                 begin

                          select nvl(max(to_number(libr_codigo)),0)+1 into v_pove_codigo_libros from pove_libros;


                          INSERT INTO pove_libros (prod_codigo,
                                               libr_codigo,
                                               libr_isbn,
                                               libr_num_paginas,
                                               libr_agno)
                              VALUES          (v_codigo_producto,
                                               v_pove_codigo_libros,
                                               v_pove_libr_isbn,
                                               v_pove_libr_num_paginas,
                                               v_pove_libr_agno);
                 exception when others then
                     v_ret_code := 'E';
                     v_ret_msg  :=v_ret_msg||'Error al crear el nuevo registro :'||substr(sqlerrm,1,500);
                 end;

                begin

                  v_auto_codigo:=replace(v_auto_codigo,'/',',');

                  result_split:= SPLIT(v_auto_codigo||'-', '-', v_auto_codigo_VAR);

                     if result_split=0 then   --and v_auto_codigo is not null
                         FOR i in 1 .. v_auto_codigo_VAR.count-1 --12
                         LOOP
                            begin
                                sql_inserta_autor:='INSERT INTO pove_libros_autores (auto_codigo,prod_codigo,libr_codigo,liau_posicion) '||
                                        ' VALUES   ('||v_auto_codigo_VAR(i)||','''||v_codigo_producto||''','||v_pove_codigo_libros||','||i||') ';
                               EXECUTE IMMEDIATE sql_inserta_autor;


                             exception when others then
                                 v_ret_code := 'E';
                                 v_ret_msg  :=v_ret_msg||'Error al crear el nuevo registro :'||substr(sqlerrm,1,500);
                             end ;

                         end loop;
                     end if;
               exception when others then
                   v_ret_code := 'E';
                   v_ret_msg  :=v_ret_msg||'Error al crear el nuevo registro :'||substr(sqlerrm,1,500);
               end ;

         -- end if;
        end if;


       if v_ret_code <> 'E' then
           commit;
       else
           rollback;
       end if;

   else
       v_ret_code:='E';
       v_ret_msg  :=v_ret_msg||'Esta pagina no puede ser accedida directamente';

   end if;

        owa_util.mime_header('application/json',false, g_charset);
        OWA_UTIL.http_header_close;
        htp.p('{');
        htp.p('"ret_code":"'||web_util.format_json(v_ret_code)||'",');
        htp.p('"ret_msg":"'||web_util.format_json(v_ret_msg)||'",');
        htp.p('}');


        EXCEPTION
        WHEN OTHERS THEN
         p_error:=0;
        htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace);

end;

procedure recibe_solicitud(p_pantalla       in number,
                        p_variables   in varchar2,
                        p_operacion   in varchar2
                        ) is
  arr_ls_VAR ARRAY_STR;
    v_claves  varchar2(32000);
    v_valores  varchar2(32000);
    arr_VAR ARRAY_STR;
    v_cuenta number(10);
    v_mensaje varchar2(200);
    esconstrain number(1);

    result_split NUMBER;
    cVAR VARCHAR2(32767);

    v_sql varchar2(32767);
    v_sql_elimina  varchar2(32767);
    v_sql_update  varchar2(32767);
    TIPO_DATO varchar2(100);
    TABLA_INSERTAR varchar2(100);
    CONDICION_BUSQUEDA varchar2(32767);
    CONDICION_BUSQUEDA1 varchar2(32767);
    condicion_update  varchar2(32767);

    CURSOR C_CONSTRAINT(V_TABLA_INSERTAR IN VARCHAR2) is
    SELECT COLUMN_NAME FROM ALL_CONS_COLUMNS ,all_constraints
                          WHERE ALL_CONS_COLUMNS.TABLE_NAME=upper(V_TABLA_INSERTAR)
                          AND ALL_CONS_COLUMNS.TABLE_NAME=all_constraints.TABLE_NAME
                          AND ALL_CONS_COLUMNS.constraint_name=all_constraints.constraint_name
                          AND constraint_type='P' ORDER BY POSITION;

v_ret_code  varchar2(5) :='S';
v_ret_msg   varchar2(10000) :='';
v_tipo_mensaje number(1);



begin

 owa_util.mime_header('application/json',false, g_charset);
 OWA_UTIL.http_header_close;
  v_tipo_mensaje:=1;


    CASE p_pantalla

            When 180 Then
                TABLA_INSERTAR:='POVE_TIPO_PRODUCTO';
            When 181 Then
                TABLA_INSERTAR:='POVE_CATEGORIAS';
            When 183 Then
                TABLA_INSERTAR:='POVE_AUTOR';
            When 184 Then
                TABLA_INSERTAR:='POVE_PAIS';
            When 185 Then
                TABLA_INSERTAR:='POVE_REGION';
            When 187 Then
                TABLA_INSERTAR:='POVE_ESTADO_DESPACHO';
            When 192 Then
                TABLA_INSERTAR:='POVE_TARIFA_DESPACHO';
            When 250 Then
                TABLA_INSERTAR:='POVE_CLIENTE';
            Else
               TABLA_INSERTAR:='POVE_TIPO_PRODUCTO';
        END CASE;


v_sql:='';
v_claves:='';
v_valores:='';
CONDICION_BUSQUEDA:='';
condicion_update:='';

   result_split:= SPLIT(p_variables, '@@', arr_ls_VAR);

     if result_split=0 then
             FOR i in 1 .. arr_ls_VAR.count-1 --12
             LOOP

               result_split:= SPLIT(arr_ls_VAR(i)||'//', '//', arr_VAR);

                    if result_split=0 then

                     SELECT DATA_TYPE INTO TIPO_DATO FROM ALL_TAB_COLUMNS
                          WHERE COLUMN_NAME= UPPER(arr_VAR(1))
                          AND TABLE_NAME=TABLA_INSERTAR;

                          v_claves:= v_claves || arr_VAR(1)||',';
                        if TIPO_DATO='VARCHAR2' THEN
                                v_valores:=v_valores||'UPPER('''||arr_VAR(2)||'''),';
                        ELSE
                                 v_valores:=v_valores||arr_VAR(2)||',';
                        END IF;
                        esconstrain:=0;
                        FOR e IN C_CONSTRAINT(TABLA_INSERTAR)
                          LOOP

                          if e.COLUMN_NAME=UPPER(arr_VAR(1)) then

                             CONDICION_BUSQUEDA:=CONDICION_BUSQUEDA || e.COLUMN_NAME || '=' || upper(arr_VAR(2)) || ' and ';
                             esconstrain:=1;
                          end if;

                          END LOOP;

                          if esconstrain=0 then
                               if TIPO_DATO='VARCHAR2' THEN
                                   condicion_update:=condicion_update||arr_VAR(1)||'=UPPER('''||arr_VAR(2)||'''),';
                            ELSE
                                    condicion_update:=condicion_update||arr_VAR(1)||'='||arr_VAR(2)||',';

                                END IF;
                          end if;


                  end if;

             end loop;
       commit;
    end if;

v_claves:= substr(v_claves,1,length(v_claves)-1);
v_valores:= substr(v_valores,1,length(v_valores)-1);
condicion_update:= substr(condicion_update,1,length(condicion_update)-1);

CONDICION_BUSQUEDA:=substr(CONDICION_BUSQUEDA,1,length(CONDICION_BUSQUEDA)-4);


begin
              CONDICION_BUSQUEDA1:= 'select count(*) from '||TABLA_INSERTAR|| ' where ' || CONDICION_BUSQUEDA;
              EXECUTE IMMEDIATE CONDICION_BUSQUEDA1 into v_cuenta;
            if (v_cuenta=0) then
                IF p_operacion='I' THEN
                        v_sql:='insert into '||TABLA_INSERTAR||' (' || v_claves || ') values (' || v_valores||')';
                        EXECUTE IMMEDIATE v_sql;
                        v_mensaje:='REGISTRO INSERTADO';
                end if;

            else

               IF p_operacion='I' THEN
                        v_sql_update:='update '||TABLA_INSERTAR|| ' set ' || condicion_update|| ' where ' || CONDICION_BUSQUEDA;
                        EXECUTE IMMEDIATE v_sql_update;
                        v_tipo_mensaje:=3;
                        v_mensaje:='SE ACTUALIZO EL REGISTRO';
               ELSE

                  IF p_operacion='E' THEN
                       v_sql_elimina:='delete from '||TABLA_INSERTAR|| ' where ' || CONDICION_BUSQUEDA;
                       EXECUTE IMMEDIATE v_sql_elimina;
                       v_mensaje:='REGISTRO ELIMINADO';
                  end if;
               END IF;
            end if;

EXCEPTION
WHEN OTHERS THEN
if (SQLCODE=-02292 and p_operacion='E') then
           v_mensaje:='Error:No se puede eliminar Registros con Datos Asociados';
     else
        v_mensaje:='Error:'||TO_CHAR(SQLCODE)|| ' '||SQLERRM;
 end if;
  v_tipo_mensaje:=2;

end;

     htp.p('{"success":"true","mensaje":"'||v_mensaje||'","tipo_mensaje":"'||v_tipo_mensaje||'"}');
end recibe_solicitud;

procedure funciones_js is

begin
    htp.p('
    <script type="text/javascript">

        function mostrar_toastr(msg,tipo)
        {


        if (tipo==1)
            toastr.success(msg);
        if (tipo==2)
             toastr.error(msg);
        if (tipo==3)
            toastr.warning(msg);


        }
    </script>
    ');
end;


procedure lista_xml(campos in varchar2 , tablas in varchar2, condicion in varchar2,dhxr in varchar2 default null) is
--a_dhx_rSeed
  xNode          XMLType;
  vxml varchar2(32000);
  TYPE CUR_TYP IS REF CURSOR;
  c_cursor   CUR_TYP;
  condicion1 varchar2(2000);

     result BOOLEAN;
      vText          VARCHAR2(4000);
      consulta_ejec   VARCHAR2(4000);
      v_campos   VARCHAR2(4000);

 BEGIN
      OWA_UTIL.mime_header ('text/xml', FALSE);
      OWA_UTIL.http_header_close;
      htp.p('<?xml version=''1.0'' encoding='''||g_charset||'''?>');

  /*OWA_UTIL.mime_header ('text/xml', false,'iso-8859-1');
    HTP.p ('Cache-Control: no-cache');
   HTP.p ('Pragma: no-cache');
   OWA_UTIL.http_header_close;*/
 IF condicion IS NULL THEN
    condicion1:='';
 ELSE
    condicion1:=' where '||condicion;
 END IF;

 v_campos:=replace(campos,'@@','''');
  v_campos:=replace(v_campos,'<>','&');

consulta_ejec:='select '||chr(39)||'<row id="'||chr(39)||'||rownum||'||chr(39)||'">' || LIB_AJAX.arma_string(UPPER(v_campos) , ',','||'||chr(39)||']]></cell>', '<cell><![CDATA['||chr(39)||'||')||'>' ||'</row>'||chr(39)||' as eldatofinal from '||tablas ||condicion1;
--htp.p(consulta_ejec);

htp.prn('<rows>');
  OPEN c_cursor FOR consulta_ejec;
  LOOP
    FETCH c_cursor INTO vxml;
    EXIT WHEN c_cursor%NOTFOUND;
     htp.prn(vxml);
  END LOOP;
  htp.prn('</rows>');
  CLOSE c_cursor;


  end;



procedure div_grilla_mantenedor (p_style in varchar2) is





begin
    htp.p('
     <div style="'||p_style||'">

        <div id="gridbox" style="position:relative; width: 100%; height: 100%;cursor: default;">
        </div>
    </div>
    ');
end;

procedure carga_grilla(p_titulos in varchar2,
                       p_anchos in varchar2,
                       p_alinear in varchar2,
                       p_sorting in varchar2,
                       p_ctypes in varchar2,
                       p_attachHeader in varchar2,
                       p_carga_xml in varchar2
                       --p_ImagePath in varchar2
                       ) is


begin

    htp.p('

    <script>
        mygrid = new dhtmlXGridObject(''gridbox'');
        mygrid.setImagePath("'||path_dhtmlx||'codebase/imgs/");
        mygrid.setHeader("'||p_titulos||'");
        mygrid.setInitWidths("'||p_anchos||'");
        //mygrid.enableAutoWidth(true);
        mygrid.setColAlign("'||p_alinear||'");
        mygrid.setColSorting("'||p_sorting||'"); //clasificacion
        mygrid.setColTypes("'||p_ctypes||'");
        mygrid.enableMultiselect(true);
        mygrid.enableMultiline(true);
        mygrid.attachFooter(''Registros,{#stat_count}'');
        mygrid.setNumberFormat(''0,000.00'');

        mygrid.init();

        mygrid.setSkin("dhx_skyblue");
        mygrid.attachHeader("'||p_attachHeader||'");
        mygrid.enableSmartRendering(true);
   /*     mygrid.attachEvent("onRowDblClicked", function(rId){
            mostrar_detalle_venta(rId);
        });  */
        mygrid.attachEvent("onCheck", function(rId,cInd,state){
            asignar_envio_bol_fac(rId,cInd,state);

        });

        function asignar_envio_bol_fac(rId,cInd,state){
         if (state) {
               v_action="1"
           }else{
               v_action="0"
           }

       v_confirm = true;

       if (v_confirm  ){

                v_data = "p_vetr_codigo="+rId+"&p_accion="+v_action;

                $.ajax({
                         url:"VENTA_ONLINE.informe_envio_asignar_ajax",
                         data: v_data ,
                         type:"GET",
                         contentType: "application/json; charset='||g_charset||'",
                         dataType: "json",
                         success: function(data){

                             if (data.ret_code == "S" ) {

                                    if(v_action == "1"){
                                 toastr.success("Venta Realizada")
                                 }
                             }
                             if (data.ret_code == "W" ) {
                                 toastr.warning(data.ret_msg , "Ocurrieron problemas al Asignar una venta")

                             }
                             if (data.ret_code == "E" ) {
                                 toastr.error(data.ret_msg , "ERROR")

                             }
                         },
                         error: function(){
                                 toastr.error("Error cargando la pagina Guardar");
                        }
                });

       }else{
         return false;
       }


    }

        if ('''||p_carga_xml||''' != '''')
        {
                 mygrid.loadXML("'||p_carga_xml||'");
        }


</script>


    ');
end;



procedure informe_envio_asignar_ajax( p_vetr_codigo    in varchar2,
                                      --p_vent_codigo    in varchar2,
                                      --p_clie_codigo    in varchar2,
                                      p_accion    in varchar2
                                     ) is
v_ret_code  varchar2(5) :='S';
v_ret_msg   varchar2(10000) :='';
v_accion    varchar2(1);


v_vetr_bol_fac_envia number;



begin
    if WEB_UTIL.verifica_referer('') then


  --  if p_accion = 1 then

     begin

                   update POVE_VENTA_TRANSACCIONES
                   set vetr_bol_fac_envia     = p_accion
                   where vetr_codigo          = p_vetr_codigo;
               exception when others then
                   v_ret_code := 'W';
                   v_ret_msg := v_ret_msg || ' Error al cambiar el estado del envio de boleta o factura : '||sqlerrm;
               end ;
  --  end if;

    else
        v_ret_code:='E';
        v_ret_msg  :=v_ret_msg|| 'Esta pagina no puede ser accedida directamente: '||OWA_UTIL.get_cgi_env ('REQUEST_PROTOCOL');
    end if;

    owa_util.mime_header('application/json',false, g_charset);
    OWA_UTIL.http_header_close;
    htp.p('{');
    htp.p('"ret_code":"'||web_util.format_json(v_ret_code)||'",');
    htp.p('"ret_msg":"'||web_util.format_json(v_ret_msg)||'",');
    htp.p('"ret_msg":"'||web_util.format_json(v_ret_msg)||'",');
    htp.p('"vetr_bol_fac_envia":"'||web_util.format_json(p_accion)||'"');
    htp.p('}');


end informe_envio_asignar_ajax;







procedure lista_libro is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

    v_texto_id:='txt_lib_id';


     v_titulos:='Codigo,Titulo del libro,Autor,Precio Lista, Cantidad';
     v_attachHeader:='#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter';
     v_anchos:='100,250,250,80,80';
     v_alineaciones:='left,left,left,left,left';
     v_sorting:='str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=vonl_libro.lib_id,vonl_libro.lib_titulo,vonl_libro.lib_autor,vonl_libro.lib_precio_lista,vonl_libro.lib_cantidad&tablas=vec_cob03.vonl_libro&condicion=';



     botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('




    ');
end;
procedure lista_precio_despacho is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

   -- v_texto_id:='txt_pro_id';


     v_titulos:='Codigo,Zona de despacho';
     v_attachHeader:='#text_filter,#select_filter';
     v_anchos:='100,200';
     v_alineaciones:='left,left';
     v_sorting:='str,str';
     v_ctypes:='ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=POVE_TARIFA_DESPACHO.tade_codigo,POVE_TARIFA_DESPACHO.TADE_DESCRIPCION&tablas=vec_cob03.POVE_TARIFA_DESPACHO&condicion=';


     botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

        <script>
          mygrid.attachEvent("onRowSelect",doOnRowSelected);

          function doOnRowSelected(id){

                  document.getElementById(''txt_tade_codigo'').value=mygrid.cellById(id,0).getValue();
                  document.getElementById(''txt_tade_descripcion'').value=mygrid.cellById(id,1).getValue();



          }
        </script>


    ');
end;

procedure lista_estado_desp is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

   -- v_texto_id:='txt_pro_id';


     v_titulos:='Codigo,Nombre Estado de despacho';
     v_attachHeader:='#text_filter,#text_filter';
     v_anchos:='100,200';
     v_alineaciones:='left,left';
     v_sorting:='str,str';
     v_ctypes:='ro,ro';
     --v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_estado_despacho.esde_codigo,pove_estado_despacho.esde_descripcion&tablas=vec_cob03.pove_estado_despacho&condicion=';


     botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

          <script>
          mygrid.attachEvent("onRowSelect",doOnRowSelected);

          function doOnRowSelected(id){

                  document.getElementById(''txt_esde_codigo'').value=mygrid.cellById(id,0).getValue();
                  document.getElementById(''txt_esde_descripcion'').value=mygrid.cellById(id,1).getValue();

          }
        </script>


    ');
end;



procedure lista_paises is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

   -- v_texto_id:='txt_pro_id';


     v_titulos:='Codigo,Nombre del Pais';
     v_attachHeader:='#text_filter,#text_filter';
     v_anchos:='100,200';
     v_alineaciones:='left,left';
     v_sorting:='str,str';
     v_ctypes:='ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_pais.pais_codigo,pove_pais.pais_descripcion&tablas=vec_cob03.pove_pais&condicion=';


     botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

          <script>
          mygrid.attachEvent("onRowSelect",doOnRowSelected);

          function doOnRowSelected(id){

                  document.getElementById(''txt_pais_codigo'').value=mygrid.cellById(id,0).getValue();
                  document.getElementById(''txt_pais_descripcion'').value=mygrid.cellById(id,1).getValue();


          }
        </script>


    ');
end;






procedure lista_autores is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

   -- v_texto_id:='txt_pro_id';


     v_titulos:='Codigo,Nombre del Autor';
     v_attachHeader:='#text_filter,#text_filter';
     v_anchos:='100,200';
     v_alineaciones:='left,left';
     v_sorting:='str,str';
     v_ctypes:='ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_autor.auto_codigo,pove_autor.auto_nombre&tablas=vec_cob03.pove_autor&condicion=';


     botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

          <script>
          mygrid.attachEvent("onRowSelect",doOnRowSelected);

          function doOnRowSelected(id){

                  document.getElementById(''txt_auto_codigo'').value=mygrid.cellById(id,0).getValue();
                  document.getElementById(''txt_auto_nombre'').value=mygrid.cellById(id,1).getValue();


          }
        </script>


    ');
end;

procedure lista_tipo_producto is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

    v_texto_id:='txt_pro_id';


     v_titulos:='Codigo,Nombre del producto';
     v_attachHeader:='#text_filter,#text_filter';
     v_anchos:='100,200';
     v_alineaciones:='left,left';
     v_sorting:='str,str';
     v_ctypes:='ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_tipo_producto.tipo_codigo,pove_tipo_producto.tipo_descripcion&tablas=vec_cob03.pove_tipo_producto&condicion=';


     botonera_grilla;
     div_grilla_mantenedor(v_style);

     libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

        <script>
          mygrid.attachEvent("onRowSelect",doOnRowSelected);

          function doOnRowSelected(id){

                  document.getElementById(''txt_tipo_codigo'').value=mygrid.cellById(id,0).getValue();
                  document.getElementById(''txt_tipo_descripcion'').value=mygrid.cellById(id,1).getValue();
            }
        </script>
    ');
end;


procedure lista_tipo_categoria is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

    v_texto_id:='txt_cat_id';


     v_titulos:='codigo,Tipo Venta,Codigo,Colección';
     v_attachHeader:='#text_filter,#text_filter,#text_filter';
     v_anchos:='0,100,100,200';
     v_alineaciones:='left,left,left,left';
     v_sorting:='str,str,str,str';
     v_ctypes:='ro,ro,ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=a.tipo_codigo,a.tipo_descripcion,b.cate_codigo,cate_descripcion&tablas=pove_tipo_producto a,pove_categorias b&condicion=a.tipo_codigo=b.tipo_codigo';


     botonera_grilla;
     div_grilla_mantenedor(v_style);

     libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

<script>
  mygrid.attachEvent("onRowSelect",doOnRowSelected);

  function doOnRowSelected(id){

           valor_curso=mygrid.cellById(id,0).getValue();

           $(''#txt_tipo_codigo'').val(valor_curso);
           $(''#txt_tipo_codigo'').trigger("chosen:updated");

          document.getElementById(''txt_cate_codigo'').value=mygrid.cellById(id,2).getValue();
          document.getElementById(''txt_cate_descripcion'').value=mygrid.cellById(id,3).getValue();

    }
</script>



    ');
end;

procedure lista_regiones is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';
begin

    v_texto_id:='txt_regi_id';


     v_titulos:='codigo,Pais,Codigo,Region,a, Zona de envio';
     v_attachHeader:='#text_filter,#text_filter,#text_filter,#select_filter,#select_filter,#select_filter';
     v_anchos:='0,100,200,200,0,200';
     v_alineaciones:='left,left,left,left,left,left';
     v_sorting:='str,str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=p.pais_codigo,p.pais_descripcion,r.regi_codigo,r.regi_descripcion,t.tade_codigo,t.tade_descripcion&tablas=pove_pais p,pove_region r, pove_tarifa_despacho t&condicion=p.pais_codigo=r.pais_codigo and r.tade_codigo = t.tade_codigo and p.pais_codigo=-1';


     botonera_grilla;
     div_grilla_mantenedor(v_style);

     libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('

<script>
  mygrid.attachEvent("onRowSelect",doOnRowSelected);

  function doOnRowSelected(id){

           valor_curso=mygrid.cellById(id,0).getValue();
           tade_codigo=mygrid.cellById(id,4).getValue();

           $(''#txt_pais_codigo'').val(valor_curso);
           $(''#txt_pais_codigo'').trigger("chosen:updated");

           $(''#txt_tade_codigo'').val(tade_codigo);
           $(''#txt_tade_codigo'').trigger("chosen:updated");


          document.getElementById(''txt_regi_codigo'').value=mygrid.cellById(id,2).getValue();
          document.getElementById(''txt_regi_descripcion'').value=mygrid.cellById(id,3).getValue();


    }
</script>



    ');
end;


procedure xml_grilla_productos(dhxr in varchar2 default null) is
--a_dhx_rSeed
  xNode          XMLType;
  vxml varchar2(32000);
  TYPE CUR_TYP IS REF CURSOR;
  c_cursor   CUR_TYP;
  condicion1 varchar2(2000);

     result BOOLEAN;
      vText          VARCHAR2(4000);
      consulta_ejec   VARCHAR2(4000);





cursor c_ls_producto is

            select a.prod_codigo,
                   a.prod_nombre,
                   a.prod_descripcion,
                   a.prod_precio,
                   a.prod_imagen,
                   a.prod_estado,
                   b.libr_isbn,
                   b.libr_agno,
                   b.libr_num_paginas,
          (SELECT wm_concat(auto_nombre) FROM  pove_libros_autores, pove_autor where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo) as autores
          ,(SELECT wm_concat(d.cate_descripcion)  FROM pove_categoria_producto c,pove_categorias d  where  c.tipo_codigo=d.tipo_codigo and c.cate_codigo=d.cate_codigo and c.prod_codigo=a.prod_codigo group by c.prod_codigo) as coleccion
           from pove_producto_tl a left join pove_libros b on a.prod_codigo=b.prod_codigo
         --  where a.prod_estado = 0
          order by b.libr_agno desc;

    pl_pais_destino varchar2(1000);


    pl_var_split varchar2(1000);

    pl_valor_split varchar2(32000);

    arr_var_split ARRAY_STR;

    result_split NUMBER;




 BEGIN


      OWA_UTIL.mime_header ('text/xml', FALSE);
      OWA_UTIL.http_header_close;
      htp.p('<?xml version=''1.0'' encoding='''||g_charset||'''?>');


  htp.prn('<rows>');

     for lis in c_ls_producto
     loop

            htp.prn('<row id="'||lis.prod_codigo||'">');
            htp.prn('<cell type="ro"><![CDATA[<img src="http://inet.utalca.cl/inspinia/img/editar.gif" title="ver" onclick="mostrar_producto('''||lis.prod_codigo||'''); return false;"/>]]></cell>');
            htp.prn('<cell>'||lis.prod_codigo||'</cell>');
            htp.prn('<cell>'||lis.prod_nombre||'</cell>');
            htp.prn('<cell>'||lis.coleccion||'</cell>');
            htp.prn('<cell>'||lis.prod_precio||'</cell>');
            htp.prn('<cell>'||lis.libr_isbn||'</cell>');
            htp.prn('<cell>'||lis.libr_agno||'</cell>');
            htp.prn('<cell>'||lis.libr_num_paginas||'</cell>');
            htp.prn('<cell>'||lis.autores||'</cell>');
            htp.prn('</row>');
     end loop;


  htp.prn('</rows>');

  end;



PROCEDURE listado_productos_prueb IS
    v_ancho_columna1 varchar2(50);
    v_ancho_columna2 varchar2(50);
    v_ancho_columna3 varchar2(50);
    v_ancho_columna4 varchar2(50);
    v_ancho_columna5 varchar2(50);
    v_ancho_columna6 varchar2(50);
    v_ancho_columna7 varchar2(50);
    v_ancho_columna8 varchar2(50);

    p_funcionario    varchar2(50);


v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 260px;cursor: default;';


begin

    v_ancho_columna1:='col-md-2';
    v_ancho_columna2:='col-md-10';
    v_ancho_columna3:='col-md-4';
    v_ancho_columna4:='col-md-2';
    v_ancho_columna5:='col-md-3';
    v_ancho_columna6:='col-md-1';
    v_ancho_columna7:='col-md-12';
    v_ancho_columna8:='col-md-6';


   p_funcionario:=username;



   encabezado_cuadro(p_titulo_pagina=>'Listado de productos');


htp.p('
<div id="response-container"></div>
      <div class="form-horizontal">

        ');

     v_titulos:='Editar,&nbsp;,Nombre libro,Colección,precio, isbn, año,numero paginas,autores';
     v_attachHeader:='#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter';
     v_anchos:='50,0,250,190,70,120,60,60,200';
     v_alineaciones:='center,left,left,left,left,left,left,left,left';
     v_sorting:='str,str,str,str,str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro,ro,ro,ro,ro';
     v_carga_xml:='venta_online.xml_grilla_productos';

    botonera_grilla;
    div_grilla_mantenedor(v_style);
    libreria_dhtmlx;

  carga_grilla(v_titulos, v_anchos,v_alineaciones,v_sorting,v_ctypes, v_attachHeader, v_carga_xml);




    --    pie_cuadro_ingresos;
        htp.p('
    </div>


    ');



 --   htp.p('<cell type="ro"><![CDATA[<img src="http://inet.utalca.cl/inspinia/img/editar.gif" title="ver" onclick="mostrar_producto('''||c.vent_codigo||'''); return false;"/>]]></cell>');

--     v_campos:='lower(@@http://inet.utalca.cl/inspinia/img/editar.gif^ver^venta_online.principal?m=133<>s=@@||pove_producto_tl.prod_codigo||@@^_self@@),cate_descripcion,prod_nombre, prod_descripcion, prod_precio ';

htp.p('
    <script>

function mostrar_producto(id_producto){



               location.href="venta_online.principal?m=133&s="+id_producto;
}

    </script>');

   END;







procedure listado_productos is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 360px;cursor: default;';

v_campos varchar2(1000);
begin


     v_campos:='lower(@@http://inet.utalca.cl/inspinia/img/editar.gif^ver^venta_online.principal?m=133<>s=@@||pove_producto_tl.prod_codigo||@@^_self@@),cate_descripcion,prod_nombre, prod_descripcion, prod_precio ';

     v_titulos:='Editar,Colección,Nombre, Descripcion, Precio';
     v_attachHeader:='#text_filter,#select_filter,#text_filter,#text_filter,#text_filter';
     v_anchos:='50,180,70,950,80';
     v_alineaciones:='center,left,left,left,left';
     v_sorting:='str,str,str,str,str';
     v_ctypes:='img,ro,ro,ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos='||v_campos||'&tablas=pove_producto_tl,pove_categoria_producto,pove_categorias&condicion=pove_producto_tl.prod_codigo=pove_categoria_producto.prod_codigo and pove_categoria_producto.cate_codigo=pove_categorias.cate_codigo and pove_categoria_producto.tipo_codigo=pove_categorias.tipo_codigo and pove_producto_tl.prod_estado > 0';

    encabezado_cuadro(p_titulo_pagina=>'Listado de Libros');
    botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('





    ');
    pie_cuadro_listado;




end;

procedure listado_autores is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 360px;cursor: default;';

v_campos varchar2(1000);
begin


v_campos:='lower(@@http://inet.utalca.cl/inspinia/img/editar.gif^ver^venta_online.principal?m=183<>s=@@||pove_autor.auto_codigo||@@^_self@@),auto_nombre  ';


     v_titulos:='Editar,Nombre del autor';
     v_attachHeader:='&nbsp;,#text_filter';
     v_anchos:='50,550';
     v_alineaciones:='center,left';
     v_sorting:='str,str';
     v_ctypes:='img,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos='||v_campos||'&tablas=pove_autor&condicion=';

encabezado_cuadro(p_titulo_pagina=>'Ingreso de Autores');
     botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
    htp.p('
    ');
    pie_cuadro_listado;

end;


procedure botonera_grilla is
begin
    htp.p('
    <script>
       function setCounter(){
                var span = document.getElementById("recfound");
                span.style.color = "";
                span.innerHTML = mygrid.getRowsNum();
            }
    </script>

<table>
<tr>
    <td>
        <a href="#" onclick="mygrid.toPDF('''||path_dhtmlx||'codebase/grid-pdf-php/generate.php'');"><img src="'||path_inspinia||'img/pdf.jpg"></a>

    </td>
    <td>
    <a href="#" onclick="mygrid.toExcel('''||path_dhtmlx||'codebase/grid-excel-php/generate.php'');"><img src="'||path_inspinia||'img/excel.jpg"></a>

    </td>

</tr>
</table>
');



end;

procedure mantenedor_tipo_categoria is
begin
  encabezado_cuadro(p_titulo_pagina=>'Tipo Colección');
    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">

                   <label class="'||v_ancho_label_lg||' control-label">Tipo Producto</label>
                                    <div class="'||v_ancho_columna2||'">

                                           <select class="chosen form-control m-b" name="txt_tipo_codigo" id="txt_tipo_codigo">
                                              <option value="-1">SELECCIONE TIPO PRODUCTO</option>');
                                          get_combos('tipo_codigo', ' tipo_descripcion', 'vec_cob03.pove_tipo_producto', 'tipo_codigo =''1''');
                               htp.p(' </select>');
                         htp.p('    </div>

                                    <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                                    <div class="'||v_ancho_columna2||'">
                                            <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_cate_codigo" id="txt_cate_codigo">

                                    </div>

                                   <label class="'||v_ancho_label_lg||' control-label">Descripcion</label>
                                    <div class="'||v_ancho_columna2||'">
                                             <input  placeholder="INGRESE COLECCION" class="form-control obligatorio"  name="txt_cate_descripcion" id="txt_cate_descripcion">
                                    </div>

                 </div>

        </form>
     </div>
   </div>



            ');
        lista_tipo_categoria;
        pie_cuadro_ingresos;

       htp.p('
    <script type="text/javascript">


    function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=cate_codigo&v_tabla=pove_categorias&v_condicion= pove_categorias.tipo_codigo = " + p_valor,
                            dataType: "json",
                            success:function(response){

                            document.getElementById(''txt_cate_codigo'').value=response.max;




                            }
                });
       }





  function ReCargar_grilla_categoria(p_valor)
        {
            mygrid.clearAll();
            if (p_valor==-1)
            {
                mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=a.tipo_codigo,a.tipo_descripcion,b.cate_codigo,b.cate_descripcion&tablas=pove_tipo_producto a,pove_categorias b&condicion=a.tipo_codigo=b.tipo_codigo");
            }
            else
            {
                mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=a.tipo_codigo,a.tipo_descripcion,b.cate_codigo,b.cate_descripcion&tablas=pove_tipo_producto a,pove_categorias b&condicion=a.tipo_codigo=b.tipo_codigo and a.tipo_codigo="+p_valor);
            }
            mygrid.getFilterElement(0).value='''';
            mygrid.getFilterElement(1).value='''';
        }
        $(document).ready(function(){
        $(''#txt_tipo_codigo'').chosen().change( function() {
            if ($(this).val()==-1)
            {
              document.getElementById(''txt_cate_codigo'').value='''';
            }
            else
            {
                Buscar_num_max($(this).val()) ;
                }
            ReCargar_grilla_categoria($(this).val());
        });

        });

        </script>

    ');

end;


procedure mantenedor_tipo_producto is
begin
  encabezado_cuadro(p_titulo_pagina=>'Tipo Venta');

    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">

                                    <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                                    <div class="'||v_ancho_columna2||'">
                                            <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_tipo_codigo" id="txt_tipo_codigo">
                                    </div>
                                   <label class="'||v_ancho_label_lg||' control-label">Descripcion</label>
                                    <div class="'||v_ancho_columna2||'">
                                            <input  placeholder="INGRESE TIPO PRODUCTO" class="form-control obligatorio"  name="txt_tipo_descripcion" id="txt_tipo_descripcion">
                                    </div>
                 </div>

        </form>
     </div>
   </div>



            ');
        lista_tipo_producto;
        pie_cuadro_ingresos;

       htp.p('
    <script type="text/javascript">

       function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=tipo_codigo&v_tabla=pove_tipo_producto&v_condicion=" + p_valor,
                            dataType: "json",
                            success:function(response){


                            document.getElementById(''txt_tipo_codigo'').value=response.max;




                            }});
       }
          function ReCargar_grilla_tipo(p_valor)
                {


                    mygrid.clearAll();
                    if (p_valor==-1)
                    {
                       mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=tipo_codigo,tipo_descripcion&tablas=pove_tipo_producto&condicion=");
                    }
                    else
                    {
                        mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=tipo_codigo,tipo_descripcion&tablas=pove_tipo_producto&condicion="+p_valor);
                    }
                    mygrid.getFilterElement(0).value='''';
                    mygrid.getFilterElement(1).value='''';

                }

                $(document).ready(function(){
                    if ($(this).val()==-1)
                    {
                      document.getElementById(''txt_tipo_codigo'').value='''';
                    }
                    else
                    {
                        Buscar_num_max($(this).val()) ;

                    }
                    ReCargar_grilla_tipo($(this).val());

                });

        </script>
    ');


end;

procedure mantenedor_valores_despacho is
begin
  encabezado_cuadro(p_titulo_pagina=>'Valores de despacho');

    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">

                          <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                          <div class="'||v_ancho_columna2||'">
                                  <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_tade_codigo" id="txt_tade_codigo">
                          </div>
                          <label class="'||v_ancho_label_lg||' control-label">Zona de envío</label>
                          <div class="'||v_ancho_columna2||'">
                                  <input  placeholder="INGRESE ZONA DE ENVIO" class="form-control obligatorio"  name="txt_tade_descripcion" id="txt_tade_descripcion">
                          </div>
                  </div>
        </form>
     </div>
   </div>



            ');
        lista_precio_despacho;
        pie_cuadro_ingresos;

       htp.p('


    <script type="text/javascript">

       function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=tade_codigo&v_tabla=POVE_TARIFA_DESPACHO&v_condicion=" + p_valor,
                            dataType: "json",
                            success:function(response){

                            document.getElementById(''txt_tade_codigo'').value=response.max;

                            }});
       }



          function ReCargar_grilla_tarifa_despacho(p_valor)
                {


                    mygrid.clearAll();
                    if (p_valor==-1)
                    {
                       mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=tade_codigo,tade_descripcion&tablas=pove_tarifa_despacho&condicion=");
                    }
                    else
                    {
                        mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=tade_codigo,tade_descripcion&tablas=pove_tarifa_despacho&condicion="+p_valor);
                    }
                    mygrid.getFilterElement(0).value='''';
                    mygrid.getFilterElement(1).value='''';


                }

                $(document).ready(function(){
                    if ($(this).val()==-1)
                    {
                      document.getElementById(''txt_tade_codigo'').value='''';
                    }
                    else
                    {
                        Buscar_num_max($(this).val()) ;

                    }
                    ReCargar_grilla_tarifa_despacho($(this).val());

                });

        </script>






    ');


end;

procedure mantenedor_estado_despacho is
begin
  encabezado_cuadro(p_titulo_pagina=>'Tipo de estado de despacho');

    htp.p('
        <div id="response-container">
          <div class="form-horizontal">

            <form id="div_ficha">
                      <div class="form-group">
                          <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                          <div class="'||v_ancho_columna2||'">
                                  <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_esde_codigo" id="txt_esde_codigo">
                          </div>
                          <label class="'||v_ancho_label_lg||' control-label">Nombre de estado</label>
                          <div class="'||v_ancho_columna2||'">
                                  <input  placeholder="INGRESE TIPO ESTADO DESPACHO" class="form-control obligatorio"  name="txt_esde_descripcion" id="txt_esde_descripcion">
                          </div>
                      </div>
            </form>
         </div>
       </div>
        ');
        lista_estado_desp;
        pie_cuadro_ingresos;

       htp.p('


    <script type="text/javascript">

       function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=esde_codigo&v_tabla=pove_estado_despacho&v_condicion=" + p_valor,
                            dataType: "json",
                            success:function(response){


                            document.getElementById(''txt_esde_codigo'').value=response.max;

                            }});
       }



          function ReCargar_grilla_estado_despacho(p_valor)
                {


                    mygrid.clearAll();
                    if (p_valor==-1)
                    {
                       mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=esde_codigo,esde_descripcion&tablas=pove_estado_despacho&condicion=");
                    }
                    else
                    {
                        mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=esde_codigo,esde_descripcion&tablas=pove_estado_despacho&condicion="+p_valor);
                    }
                    mygrid.getFilterElement(0).value='''';
                    mygrid.getFilterElement(1).value='''';

                }

                $(document).ready(function(){
                    if ($(this).val()==-1)
                    {
                      document.getElementById(''txt_esde_codigo'').value='''';
                    }
                    else
                    {
                        Buscar_num_max($(this).val()) ;

                    }
                    ReCargar_grilla_estado_despacho($(this).val());

                });

        </script>
     ');


end;



procedure mantenedor_paises is
begin
  encabezado_cuadro(p_titulo_pagina=>'Paises');

    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">
                          <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                          <div class="'||v_ancho_columna2||'">
                                  <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_pais_codigo" id="txt_pais_codigo">
                          </div>
                          <label class="'||v_ancho_label_lg||' control-label">Nombre del pais</label>
                          <div class="'||v_ancho_columna2||'">
                                  <input  placeholder="INGRESE TIPO PRODUCTO" class="form-control obligatorio"  name="txt_pais_descripcion" id="txt_pais_descripcion">
                          </div>
                  </div>
        </form>
     </div>
   </div>



            ');
        lista_paises;
        pie_cuadro_ingresos;

       htp.p('


    <script type="text/javascript">

       function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=pais_codigo&v_tabla=pove_pais&v_condicion=",
                            dataType: "json",
                            success:function(response){


                            document.getElementById(''txt_pais_codigo'').value=response.max;

                            }});
       }



          function ReCargar_grilla_paises(p_valor)
                {


                    mygrid.clearAll();
                    if (p_valor==-1)
                    {
                       mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=pais_codigo,pais_descripcion&tablas=pove_pais&condicion=");
                    }
                    else
                    {
                        mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=pais_codigo,pais_descripcion&tablas=pove_pais&condicion="+p_valor);
                    }
                    mygrid.getFilterElement(0).value='''';
                    mygrid.getFilterElement(1).value='''';

                }

                $(document).ready(function(){
                    if ($(this).val()==-1)
                    {
                      document.getElementById(''txt_pais_codigo'').value='''';
                    }
                    else
                    {
                        Buscar_num_max($(this).val()) ;

                    }
                    ReCargar_grilla_paises($(this).val());

                });

        </script>






    ');


end;


procedure mantenedor_regiones is
begin
  encabezado_cuadro(p_titulo_pagina=>'Regiones');
    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">

                   <label class="'||v_ancho_label_lg||' control-label">Pais</label>
                                    <div class="'||v_ancho_columna2||'">

                                           <select class="chosen form-control m-b" name="txt_pais_codigo" id="txt_pais_codigo">
                                              <option value="-1">SELECCIONE PAIS</option>');
                                          get_combos('pais_codigo', ' pais_descripcion', 'vec_cob03.pove_pais', '');
                               htp.p(' </select>');
                         htp.p('    </div>

                                    <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                                    <div class="'||v_ancho_columna2||'">
                                            <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_regi_codigo" id="txt_regi_codigo">

                                    </div>

                                   <label class="'||v_ancho_label_lg||' control-label">Descripcion</label>
                                    <div class="'||v_ancho_columna3||'">
                                             <input  placeholder="INGRESE REGION" class="form-control obligatorio"  name="txt_regi_descripcion" id="txt_regi_descripcion">
                                    </div>
                                   <label class="'||v_ancho_label_lg||' control-label">ZONA DE ENVIO</label>
                                                    <div class="'||v_ancho_columna3||'">

                                                           <select class="chosen form-control m-b" name="txt_tade_codigo" id="txt_tade_codigo">
                                                              <option value="-1">SELECCIONE ZONA DE ENVIO</option>');
                                                          get_combos('tade_codigo', ' tade_descripcion', 'vec_cob03.pove_tarifa_despacho', '');
                                               htp.p(' </select>');
                                         htp.p('    </div>
                 </div>

        </form>
     </div>
   </div>
   ');
        lista_regiones;
        pie_cuadro_ingresos;

       htp.p('
    <script type="text/javascript">


    function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=regi_codigo&v_tabla=pove_region&v_condicion= pove_region.pais_codigo = " + p_valor,
                            dataType: "json",
                            success:function(response){

                            document.getElementById(''txt_regi_codigo'').value=response.max;

                            }
                });
       }
  function ReCargar_grilla_regiones(p_valor)
        {
            mygrid.clearAll();

                mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=p.pais_codigo,p.pais_descripcion,r.regi_codigo,r.regi_descripcion, t.tade_codigo, t.tade_descripcion&tablas=pove_pais p,pove_region r, pove_tarifa_despacho t&condicion=p.pais_codigo=r.pais_codigo and r.tade_codigo = t.tade_codigo and p.pais_codigo="+p_valor);


            mygrid.getFilterElement(0).value='''';
            mygrid.getFilterElement(1).value='''';
            mygrid.getFilterElement(2).value='''';
            mygrid.getFilterElement(3).value='''';

        }
        $(document).ready(function(){
        $(''#txt_pais_codigo'').chosen().change( function() {
            if ($(this).val()==-1)
            {
              document.getElementById(''txt_regi_codigo'').value='''';
            }
            else
            {
                Buscar_num_max($(this).val()) ;
                }
            ReCargar_grilla_regiones($(this).val());
        });

        });

        </script>

    ');

end;


procedure mantenedor_ciudades is
begin
  encabezado_cuadro(p_titulo_pagina=>'Ciudades');
    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">

                   <label class="'||v_ancho_label_lg||' control-label">Pais</label>
                                    <div class="'||v_ancho_columna2||'">

                                           <select class="chosen form-control m-b" name="txt_pais_codigo" id="txt_pais_codigo">
                                              <option value="-1">SELECCIONE PAIS</option>');
                                          get_combos('pais_codigo', ' pais_descripcion', 'vec_cob03.pove_pais', '');
                               htp.p(' </select>');
                         htp.p('    </div>
                       <label class="'||v_ancho_label_lg||' control-label">Region</label>
                                        <div class="'||v_ancho_columna2||'">

                                               <select class="chosen form-control m-b" name="txt_regi_codigo" id="txt_regi_codigo">
                                                  <option value="-1">SELECCIONE REGION</option>');
                                              get_combos('regi_codigo', ' regi_descripcion', 'vec_cob03.pove_region', '');
                                   htp.p(' </select>');
                             htp.p('    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                                    <div class="'||v_ancho_columna2||'">
                                            <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_ciud_codigo" id="txt_ciud_codigo">

                                    </div>

                                   <label class="'||v_ancho_label_lg||' control-label">Descripcion</label>
                                    <div class="'||v_ancho_columna3||'">
                                             <input  placeholder="INGRESE CIUDAD" class="form-control obligatorio"  name="txt_ciud_descripcion" id="txt_ciud_descripcion">
                                    </div>
                                   <label class="'||v_ancho_label_lg||' control-label">DISTRIBUCION</label>
                                                    <div class="'||v_ancho_columna3||'">

                                                           <select class="chosen form-control m-b" name="txt_tidi_codigo" id="txt_tidi_codigo">
                                                              <option value="-1">SELECCIONE DISTRIBUCION</option>');
                                                          get_combos('tidi_codigo', ' tidi_descripcion', 'vec_cob03.pove_tipo_distribucion', '');
                                               htp.p(' </select>');
                                         htp.p('    </div>
                                   <label class="'||v_ancho_label_lg||' control-label">CIUDAD RECARGO</label>
                                                    <div class="'||v_ancho_columna3||'">

                                                           <select class="chosen form-control m-b" name="txt_cire_codigo" id="txt_cire_codigo">
                                                              <option value="-1">SELECCIONE RECARGO</option>');
                                                          get_combos('cire_codigo', ' cire_descripcion', 'vec_cob03.pove_ciudad_recargo', '');
                                               htp.p(' </select>');
                                         htp.p('    </div>
                 </div>

        </form>
     </div>
   </div>
   ');
        lista_regiones;
        pie_cuadro_ingresos;

       htp.p('
    <script type="text/javascript">


    function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=ciud_codigo&v_tabla=pove_ciudad&v_condicion= pove_ciudad.regi_codigo = " + p_valor,
                            dataType: "json",
                            success:function(response){

                            document.getElementById(''txt_ciud_codigo'').value=response.max;

                            }
                });
       }
  function ReCargar_grilla_regiones(p_valor)
        {
            mygrid.clearAll();

                mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=p.pais_codigo,p.pais_descripcion,r.regi_codigo,r.regi_descripcion, t.tade_codigo, t.tade_descripcion&tablas=pove_pais p,pove_region r, pove_tarifa_despacho t&condicion=p.pais_codigo=r.pais_codigo and r.tade_codigo = t.tade_codigo and p.pais_codigo="+p_valor);


            mygrid.getFilterElement(0).value='''';
            mygrid.getFilterElement(1).value='''';
            mygrid.getFilterElement(2).value='''';
            mygrid.getFilterElement(3).value='''';

        }
        $(document).ready(function(){
        $(''#txt_regi_codigo'').chosen().change( function() {
            if ($(this).val()==-1)
            {
              document.getElementById(''txt_regi_codigo'').value='''';
            }
            else
            {
                Buscar_num_max($(this).val()) ;
                }
            ReCargar_grilla_regiones($(this).val());
        });

        });

        </script>

    ');

end;



procedure mantenedor_autores is
begin
  encabezado_cuadro(p_titulo_pagina=>'Autores');

    htp.p('


    <div id="response-container">
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">
                                    <label class="'||v_ancho_label_lg||' control-label">Codigo</label>
                                    <div class="'||v_ancho_columna3||'">
                                            <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_auto_codigo" id="txt_auto_codigo">
                                    </div>
                                    <div class="col-lg-6">
                                    <span class="input-group-btn">
                                                <button id="btn_buscar"  type="button" class="btn btn-primary">Buscar</button>
                                    </span>
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Nombre del autor</label>
                                    <div class="'||v_ancho_columna2||'">
                                            <input  placeholder="INGRESE TIPO PRODUCTO" class="form-control obligatorio"  name="txt_auto_nombre" id="txt_auto_nombre">
                                    </div>
                  </div>
        </form>
     </div>
   </div>


            ');
        lista_autores;
        pie_cuadro_ingresos;

       htp.p('


    <script type="text/javascript">

       function Buscar_num_max(p_valor)
       {

                $.ajax({

                            url:''venta_online.numero_siguiente'',
                            type:''GET'',
                            data:"v_id_tabla=auto_codigo&v_tabla=pove_autor&v_condicion=" + p_valor,
                            dataType: "json",
                            success:function(response){


                            document.getElementById(''txt_auto_codigo'').value=response.max;

                            }});
       }



          function ReCargar_grilla_autor(p_valor)
                {


                    mygrid.clearAll();
                    if (p_valor==-1)
                    {
                       mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=auto_codigo,auto_nombre&tablas=pove_autor&condicion=");
                    }
                    else
                    {
                        mygrid.loadXML("VENTA_ONLINE.lista_xml?campos=auto_codigo,auto_nombre&tablas=pove_autor&condicion="+p_valor);
                    }
                    mygrid.getFilterElement(0).value='''';
                    mygrid.getFilterElement(1).value='''';

                }

                $(document).ready(function(){
                    if ($(this).val()==-1)
                    {
                      document.getElementById(''txt_auto_codigo'').value='''';
                    }
                    else
                    {
                        Buscar_num_max($(this).val()) ;

                    }
                    ReCargar_grilla_autor($(this).val());

                });

        </script>

    ');


end;

   PROCEDURE cargar_grilla_ventas_xml (P_FECHA_DESDE VARCHAR2 DEFAULT NULL,
                                       P_FECHA_HASTA VARCHAR2 DEFAULT NULL,
                                       connector VARCHAR2 DEFAULT NULL,
                                       dhx_colls VARCHAR2 DEFAULT NULL,
                                       dhxr VARCHAR2 DEFAULT NULL
   )
   IS
      CURSOR c1
      IS
        SELECT POVE_VENTA_DETALLE.VEDE_CODIGO, POVE_CLIENTE.CLIE_RUT,POVE_VENTA.VENT_FECHA,pove_producto_tl.PROD_NOMBRE,pove_producto_tl.PROD_PRECIO,POVE_VENTA_DETALLE.VEDE_CANTIDAD,POVE_ESTADO_DESPACHO.ESDE_DESCRIPCION
        FROM POVE_VENTA_DETALLE,pove_producto_tl,POVE_ESTADO_DESPACHO,POVE_VENTA,POVE_CLIENTE
        WHERE POVE_VENTA_DETALLE.PROD_CODIGO=pove_producto_tl.PROD_CODIGO
        AND  POVE_VENTA_DETALLE.ESDE_CODIGO=POVE_ESTADO_DESPACHO.ESDE_CODIGO
        AND  POVE_VENTA_DETALLE.VENT_CODIGO=POVE_VENTA.VENT_CODIGO
        AND  pove_cliente.clie_codigo = POVE_VENTA.clie_codigo
        AND  VENT_FECHA BETWEEN TO_DATE (P_FECHA_DESDE, 'dd/mm/rrrr')
        AND  TO_DATE (P_FECHA_HASTA, 'dd/mm/rrrr')
         ORDER BY VENT_FECHA DESC;






      v_html_ret   VARCHAR2 (32000);
   BEGIN
      OWA_UTIL.mime_header ('text/xml', FALSE);
      OWA_UTIL.http_header_close;
      HTP.p ('<?xml version=''1.0'' encoding=''' || g_charset || '''?>');
      HTP.p ('<rows>');

      FOR c IN c1
      LOOP
         HTP.p ('<row id=''' || c.VEDE_CODIGO || ''' >');
         --HTP.p ('<cell><![CDATA[' || c.vede_codigo || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.CLIE_RUT || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.VENT_FECHA || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.PROD_NOMBRE || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.VEDE_CANTIDAD || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.PROD_PRECIO || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.esde_descripcion || ']]></cell>');
         HTP.p ('</row>');
      END LOOP;

      HTP.p ('</rows>');
   END cargar_grilla_ventas_xml;

   PROCEDURE envio_bol_factura_xml (P_FECHA_DESDE VARCHAR2 DEFAULT NULL,
                                       P_FECHA_HASTA VARCHAR2 DEFAULT NULL,
                                       connector VARCHAR2 DEFAULT NULL,
                                       dhx_colls VARCHAR2 DEFAULT NULL,
                                       dhxr VARCHAR2 DEFAULT NULL
   )
   IS
      CURSOR c1
      IS

          SELECT a.dato_codigo, a.clie_codigo, a.dato_rut_empr, a.dato_nombre_emp,
                 a.dato_detalle, a.dato_prestac_prod, a.dato_valor_total,
                 a.dato_orden_compra, a.dato_espec_provee, a.dato_centro_resp,
                 a.pais_codigo, a.regi_codigo, a.ciud_codigo, a.dato_direccion,
                 a.dato_giro
          FROM pove_datos_factura a
          where a.dato_rut_empr is not  null;


      v_html_ret   VARCHAR2 (32000);
   BEGIN
      OWA_UTIL.mime_header ('text/xml', FALSE);
      OWA_UTIL.http_header_close;
      HTP.p ('<?xml version=''1.0'' encoding=''' || g_charset || '''?>');
      HTP.p ('<rows>');

      FOR c IN c1
      LOOP
         HTP.p ('<row id=''' || c.dato_codigo || ''' >');
         HTP.p ('<cell><![CDATA[' || c.clie_codigo || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.dato_rut_empr || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.dato_nombre_emp || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.dato_giro || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.dato_orden_compra || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.dato_valor_total || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.dato_espec_provee || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.dato_centro_resp || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.dato_detalle || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.dato_prestac_prod || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.pais_codigo || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.regi_codigo || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.ciud_codigo || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.dato_direccion || ']]></cell>');

         HTP.p ('</row>');
      END LOOP;

      HTP.p ('</rows>');
   END envio_bol_factura_xml;





   PROCEDURE cargar_informes_despacho_xml (P_FECHA_DESDE VARCHAR2 DEFAULT NULL,
                                       P_FECHA_HASTA VARCHAR2 DEFAULT NULL,
                                       connector VARCHAR2 DEFAULT NULL,
                                       dhx_colls VARCHAR2 DEFAULT NULL,
                                       dhxr VARCHAR2 DEFAULT NULL
                                      -- P_VENT_CODIGO VARCHAR2 DEFAULT NULL
   )
   IS

      v_vent_codigo VARCHAR2(30):= 2;        --  POVE_VENTA.VENT_CODIGO%TYPE;

      CURSOR c1
      IS

        SELECT POVE_VENTA.VENT_CODIGO, POVE_VENTA_TRANSACCIONES.vetr_codigo ,POVE_VENTA_TRANSACCIONES.vetr_bol_fac_envia, POVE_CLIENTE.CLIE_RUT,POVE_CLIENTE.clie_destinatario,
                to_char(pove_venta.VENT_FECHA ,'dd-mm-rrrr hh24:mi:ss') as VENT_FECHA,
                pove_cliente.clie_email,pove_cliente.clie_direccion,pove_cliente.clie_tel_contacto,pove_region.regi_descripcion, pove_ciudad.ciud_descripcion,
               DECODE(CLIE_RETIRO,'S','EN TIENDA','N','A DOMICILIO',CLIE_RETIRO) AS CLIE_RETIRO,
               decode(clie_bol_fac,'B','BOLETA','F','FACTURA',clie_bol_fac) AS clie_bol_fac
        FROM   POVE_VENTA,POVE_CLIENTE, POVE_REGION, POVE_CIUDAD, POVE_VENTA_TRANSACCIONES
        WHERE  pove_cliente.clie_codigo = POVE_VENTA.clie_codigo
        AND    pove_cliente.regi_codigo = pove_region.REGI_CODIGO
        AND    pove_cliente.ciud_codigo = pove_ciudad.ciud_CODIGO
        AND    POVE_VENTA_TRANSACCIONES.vent_codigo = POVE_VENTA.vent_codigo
     --   and    POVE_VENTA.VENT_CODIGO=POVE_VENTA.VENT_CODIGO
        AND    VENT_FECHA >= TO_DATE (P_FECHA_DESDE, 'dd-mm-rrrr hh24:mi:ss')
        AND    VENT_FECHA <= TO_DATE (P_FECHA_HASTA, 'dd-mm-rrrr  hh24:mi:ss')

        ORDER BY  VENT_FECHA DESC;



      v_html_ret   VARCHAR2 (32000);
   BEGIN
      OWA_UTIL.mime_header ('text/xml', FALSE);
      OWA_UTIL.http_header_close;
      HTP.p ('<?xml version=''1.0'' encoding=''' || g_charset || '''?>');
      HTP.p ('<rows>');

      FOR c IN c1


      LOOP
         HTP.p ('<row id=''' || c.VENT_CODIGO || ''' >');
         htp.p('<cell type="ro"><![CDATA[<img src="http://inet.utalca.cl/inspinia/img/pencil.png" title="ver detalle" onclick="mostrar_detalle_venta('''||c.vent_codigo||'''); return false;"/>]]></cell>');
         HTP.p ('<cell><![CDATA[' || c.VENT_CODIGO || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.CLIE_RUT || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.clie_destinatario || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.VENT_FECHA || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.clie_email || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.clie_direccion || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.clie_tel_contacto || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.regi_descripcion || ']]></cell>');
         htp.p('<cell><![CDATA[' || c.ciud_descripcion || ']]></cell>');
         HTP.p ('<cell><![CDATA[' || c.clie_retiro || ']]></cell>');
         htp.p ('<cell><![CDATA[' || c.clie_bol_fac || ']]></cell>');
         htp.p ('<cell><![CDATA[' || c.VETR_BOL_FAC_ENVIA || ']]></cell>');
         HTP.p ('</row>');
      END LOOP;
      HTP.p ('</rows>');

END cargar_informes_despacho_xml;


PROCEDURE MOSTRAR_LISTADO_DESPACHO (P_VENT_CODIGO IN VARCHAR2  DEFAULT NULL ) IS


cursor cur_deta_venta is
        SELECT pove_venta.vent_codigo,
               pove_producto_tl.prod_nombre,
               pove_producto_tl.prod_precio,
               pove_venta_detalle.vede_cantidad,
             --  to_char(pove_venta.vent_fecha,'dd-mm-yyyy hh:mm:')
               to_char(pove_venta.vent_fecha, 'dd/mm/yyyy hh24:mi:ss') as vent_fecha
        FROM   pove_producto_tl, pove_cliente, pove_venta, pove_venta_detalle
        WHERE pove_cliente.clie_codigo = pove_venta.clie_codigo
        AND   pove_venta.vent_codigo = pove_venta_detalle.vent_codigo
        AND   pove_venta_detalle.prod_codigo = pove_producto_tl.prod_codigo
        AND   pove_venta_detalle.clie_codigo = pove_CLIENTE.CLIE_codigo
        and   pove_venta.vent_codigo = 3
        ORDER BY pove_venta.vent_codigo ASC;


BEGIN
   htp.p('

   <!-- Div modal para mostrar y editar detalles -->
        <div class="modal inmodal" id="ModalDetalle_venta" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content animated bounceInRight">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
                        <h4 class="modal-title" id="">Información del detalle de la venta</h4>
                    </div>

                        <div class="col-lg-offset-1 col-lg-10">
                            <div class="ibox float-e-margins">
                                <div class="ibox-content">');

                             htp.p('<table class="table table-striped">
                                        <thead>
                                        <tr>
                                            <th></th>
                                            <th class="text-navy">Fecha de Compra</th>
                                            <th class="text-navy">Producto</th>
                                            <th class="text-navy">Cantidad</th>
                                        </tr>
                                        </thead>
                                        <tbody>');
                                        for kl in cur_deta_venta loop

                                  htp.p('<tr>
                                            <td></td>
                                            <td >');
                                                    htp.p(kl.vent_fecha);
                                    htp.p(' </td>
                                            <td >');
                                                    htp.p(kl.prod_nombre);
                                     htp.p('</td>
                                            <td >');
                                                    htp.p(kl.vede_cantidad);
                                     htp.p('</td>

                                        </tr>
                                        </tbody>');
                                       end loop;
                            htp.p('</table>
                                </div>
                            </div>
                        </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-primary" id="btn_factura" onclick="return Guardar_modal_detalle();" ><i class="fa fa-check"></i> Cerrar</button>
                    </div>
                </div>
            </div>
            <!-- Div modal para mostrar y editar detalles -->



');

 librerias_js;

end;


procedure informe_envio_despacho

    is

   BEGIN
      encabezado_cuadro (p_titulo_pagina => 'Listado Envio de Despacho');
      estilos;
      libreria_dhtmlx;
      HTP.p('
    <div id="response-container">
      <div class="form-horizontal">
        <form id="div_ficha">
                  <div class="form-group">
                                        <label class="'
            || v_ancho_label_lg
            || ' control-label obligatorio">Desde</label>
                                    <div class="'
            || v_ancho_columna3
            || '">


            <input  class="form-control obligatorio" name="txt_fecha_desde" id="txt_fecha_desde" value="" onclick="setSens(''txt_fecha_hasta'',''max'')" >

                                        <script>
                                            var myCalendar;

                                                myCalendar1 = new dhtmlXCalendarObject("txt_fecha_desde");
                                                myCalendar1.setDateFormat("%d/%m/%Y %H:%i");
                                            //    myCalendar1.hideTime();

                                        </script>
                                    </div>
                                    <label class="'
            || v_ancho_label_lg
            || ' control-label obligatorio">Hasta</label>
                                    <div class="'
            || v_ancho_columna3
            || '">
                <input type="text"  class="form-control" id="txt_fecha_hasta" value="" onclick="setSens(''txt_fecha_desde'',''min'')">
                                        <script>
                                            var myCalendar2;

                                                myCalendar2 = new dhtmlXCalendarObject("txt_fecha_hasta");
                                                myCalendar2.setDateFormat("%d/%m/%Y %H:%i");
                                              //  myCalendar2.hideTime();

                                        </script>
                                    </div>
                 </div><br><br>

                  <div class = "row">
                      <div class="col-lg-5 col-lg-offset-5">
                          <div class="form-group">
                              <button type="button" class="btn btn-outline btn-primary" onclick="cargar_xml();"> Consultar </button>
                          </div>
                      </div>

                  </div>
        </form>
     </div>
   </div>');
      listado_envio_despacho;

      librerias_js;

htp.p('

<script>

function mostrar_detalle_venta(id_venta){


         v_data = "p_vent_codigo="+id_venta;


          $.ajax({
                   url:''venta_online.MOSTRAR_LISTADO_DESPACHO'',
                   type:''GET'',
                   data: v_data,
                   dataType: "html",

                   success:function(data){

                          $("#ModalDetalle_venta").modal("toggle");

                   }

          });


}


function Guardar_modal_detalle(){


    $("#ModalDetalle_venta").modal("toggle");
}

</script>



      <script>


//funcion para validar calander
function setSens(inputId,mezh){
 if(mezh=="min"){
        if(document.getElementById(inputId).value != ""){
         myCalendar2.setSensitiveRange(document.getElementById(inputId).value,null);
         }
     }else{
            if(document.getElementById(inputId).value != ""){
        myCalendar1.setSensitiveRange(null,document.getElementById(inputId).value);
        }
     }
}

function cargar_xml(){
    var v_fecha_desde = document.getElementById("txt_fecha_desde").value;
    var v_fecha_hasta = document.getElementById("txt_fecha_hasta").value;


    mygrid.clearAll();
    ');

    HTP.p('mygrid.loadXML("venta_online.cargar_informes_despacho_xml?p_fecha_desde="+v_fecha_desde+"&p_fecha_hasta="+v_fecha_hasta);

}

// este llamado es para que se cargue la grilla inicialmente con los valores por defecto
 $(document).ready(function(){
 cargar_xml();

 });

    </script>
    ');


end;

procedure informe_ventas_libro is




   BEGIN
      encabezado_cuadro (p_titulo_pagina => 'Envio de Boleta o Factura por DBnet');
      estilos;
      libreria_dhtmlx;
      HTP.p('
    <div id="response-container">
      <div class="form-horizontal">
        <form id="div_ficha">
                  <div class="form-group">
                                        <label class="'
            || v_ancho_label_lg
            || ' control-label obligatorio">Desde</label>
                                    <div class="'
            || v_ancho_columna3
            || '">
                                        <input type="text"  class="form-control" id="txt_fecha_desde" value="'
            || TO_CHAR (SYSDATE, g_mascara_fecha)
            || '">
                                        <script>
                                            var myCalendar;

                                                myCalendar = new dhtmlXCalendarObject("txt_fecha_desde");
                                                myCalendar.setDateFormat("%d/%m/%Y");
                                                myCalendar.hideTime();

                                        </script>
                                    </div>
                                    <label class="'
            || v_ancho_label_lg
            || ' control-label obligatorio">Hasta</label>
                                    <div class="'
            || v_ancho_columna3
            || '">
                                        <input type="text"  class="form-control" id="txt_fecha_hasta" value="'
            || TO_CHAR (SYSDATE, g_mascara_fecha)
            || '">
                                        <script>
                                            var myCalendar;

                                                myCalendar = new dhtmlXCalendarObject("txt_fecha_hasta");
                                                myCalendar.setDateFormat("%d/%m/%Y");
                                                myCalendar.hideTime();

                                        </script>
                                    </div>
                 </div><br><br>




                  <div class = "row">
                      <div class="col-lg-5 col-lg-offset-5">
                          <div class="form-group">
                              <button type="button" class="btn btn-outline btn-primary" onclick="cargar_xml();"> Consultar </button>
                          </div>
                      </div>

                  </div>
        </form>
     </div>
   </div>
   ');

      envio_bol_fact_dbnet;
      librerias_js;
      HTP.p('

<script>


function cargar_xml(){
    var v_fecha_desde = document.getElementById("txt_fecha_desde").value;
    var v_fecha_hasta = document.getElementById("txt_fecha_hasta").value;


    mygrid.clearAll();
    ');


    HTP.p('mygrid.loadXML("venta_online.envio_bol_factura_xml?p_fecha_desde="+v_fecha_desde+"&p_fecha_hasta="+v_fecha_hasta);

}

// este llamado es para que se cargue la grilla inicialmente con los valores por defecto
 $(document).ready(function(){
 cargar_xml();

 });

    </script>
    ');


end;


procedure envio_bol_fact_dbnet( dhxr VARCHAR2 DEFAULT NULL)
   IS

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_setImagePath varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';


v_campos varchar2(1000);


begin

     v_setImagePath:='http://inet.utalca.cl/dhtmlxsuite4.3/codebase/imgs/';
     v_titulos:='Codigo,Rut Empresa,Nombre Empresa,Giro o Industria,Orden de Compra,Valor,Especificaciónes del proveedor, Centro de Costo,Detalle,Prestación o Producto, Pais,Region,Ciudad,Dirección';
     v_attachHeader:='#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#select_filter,#select_filter,#text_filter,#text_filter,#text_filter,#text_filter';
     v_anchos:='0,100,200,200,110,80,220,80,200,200,100,100,100,100,260';
     v_alineaciones:='left,left,left,left,left,left,left,left,left,left,left,left,left,left,center';
     v_sorting:='str,str,str,str,str,str,str,str,str,str,str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ch';
     v_carga_xml:='';

     botonera_grilla;
     div_grilla_mantenedor(v_style);

     libreria_dhtmlx;

    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);


end;


procedure listado_envio_despacho( dhxr VARCHAR2 DEFAULT NULL)
   IS

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_setImagePath varchar2(1000);



v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 410px;cursor: default;';


v_campos varchar2(1000);


begin

    v_setImagePath:='http://inet.utalca.cl/dhtmlxsuite4.3/codebase/imgs/';
     v_titulos:='Ver detalle venta,Codigo venta detalle,Rut del Cliente, Destinatario, Fecha Venta, Email Cliente, Direccion de despacho, Telefono Contacto, Region, Ciudad, Retiro,Boleta,Enviado';
     v_attachHeader:='#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#select_filter,#select_filter,#select_filter';
     v_anchos:='70,0,70,220,120,160,250,70,150,140,100,100,80';
     v_alineaciones:='left,left,left,left,left,left,left,left,left,left,left,left,center';
     v_sorting:='str,str,str,str,str,str,str,str,str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ch';
     v_carga_xml:='';


     botonera_grilla;
     div_grilla_mantenedor(v_style);

     libreria_dhtmlx;

    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);
MOSTRAR_LISTADO_DESPACHO;





end;



procedure listado_ventas is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 360px;cursor: default;';

v_campos varchar2(1000);
begin



     v_titulos:='N° de ventas, Rut del cliente,Fecha Venta,Total';
     v_attachHeader:='#text_filter,#select_filter,#text_filter,#text_filter';
     v_anchos:='100,160,160,160';
     v_alineaciones:='left,left,left,left';
     v_sorting:='str,str,str,str';
     v_ctypes:='ro,ro,ro,price';
     v_carga_xml:='' ;
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_venta.vent_codigo,pove_venta.clie_rut, pove_venta.vent_fecha, pove_venta.vent_total&tablas=pove_venta&condicion=';


    encabezado_cuadro(p_titulo_pagina=>'Listado Ventas');
    botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);

    pie_cuadro_listado;
end;

procedure listado_envio_dbnet is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_setImagePath varchar2(1000);

v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 210px;cursor: default;';


v_campos varchar2(1000);


begin

     v_setImagePath:='http://inet.utalca.cl/dhtmlxsuite4.3/codebase/imgs/';
     v_titulos:='Rut Empresa,Nombre Empresa,Giro o Industria,Orden de Compra,Valor,Especificaciónes del proveedor, Centro de Costo,Detalle,Prestación o Producto, Pais,Region,Ciudad,Dirección';
     v_attachHeader:='#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#text_filter,#select_filter,#select_filter,#text_filter,#text_filter,#text_filter,#text_filter';
     v_anchos:='100,200,200,200,110,220,80,200,200,100,100,100,260';
     v_alineaciones:='left,left,left,left,left,left,left,left,left,left,left,left,left';
     v_sorting:='str,str,str,str,str,str,str,str,str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_datos_factura.dato_rut_empr, pove_datos_factura.dato_nombre_emp, pove_datos_factura.dato_giro, pove_datos_factura.dato_orden_compra, pove_datos_factura.dato_valor_total,pove_datos_factura.dato_espec_provee,pove_datos_factura.dato_centro_resp,pove_datos_factura.dato_detalle,pove_datos_factura.dato_prestac_prod, pove_pais.pais_descripcion, pove_region.regi_descripcion,pove_ciudad.ciud_descripcion, pove_datos_factura.dato_direccion&tablas=pove_datos_factura,pove_pais,POVE_REGION, POVE_CIUDAD&condicion=pove_datos_factura.dato_rut_empr is not  null AND    pove_datos_factura.pais_codigo = pove_pais.pais_CODIGO AND    pove_datos_factura.regi_codigo = pove_region.REGI_codigo AND    pove_datos_factura.ciud_codigo = pove_ciudad.ciud_codigo ';


    encabezado_cuadro(p_titulo_pagina=>'Listado de facturas para ingresar a DBnet');
    botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);

    pie_cuadro_listado;
end;



procedure listado_clientes is

v_titulos varchar2(1000);
v_anchos varchar2(1000);
v_alineaciones varchar2(1000);
v_carga_xml varchar2(1000);
v_sorting varchar2(1000);
v_ctypes varchar2(1000);
v_attachHeader varchar2(1000);
v_texto_id varchar2(1000);
v_style VARCHAR2(1000):='position:relative; width: 100%; height: 360px;cursor: default;';

v_campos varchar2(1000);
begin


     v_titulos:='Rut,Destinatario,Email, Direccióon,Telefono Contacto';
     v_attachHeader:='#text_filter,#select_filter,#text_filter,#text_filter,#text_filter';
     v_anchos:='80,220,180,270,120';
     v_alineaciones:='left,left,left,left,left';
     v_sorting:='str,str,str,str,str';
     v_ctypes:='ro,ro,ro,ro,ro';
     v_carga_xml:='VENTA_ONLINE.lista_xml?campos=pove_cliente.clie_rut||''-''||pove_cliente.clie_dv,pove_cliente.clie_destinatario,pove_cliente.clie_email,pove_cliente.clie_direccion,pove_cliente.clie_tel_contacto&tablas=pove_cliente&condicion=';

    encabezado_cuadro(p_titulo_pagina=>'Listado Clientes');
    botonera_grilla;
    div_grilla_mantenedor(v_style);

    libreria_dhtmlx;


    carga_grilla(v_titulos,v_anchos,v_alineaciones,v_sorting,v_ctypes,v_attachHeader,v_carga_xml);

    pie_cuadro_listado;
end;



procedure numero_siguiente(v_id_tabla in varchar2, v_tabla in varchar2, v_condicion in varchar2 default null) is

v_json varchar2(32000);
v_maximo number;
v_sql varchar2(1000);
  condicion1 varchar2(2000);
begin
  owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;

 IF v_condicion IS NULL THEN
    condicion1:='';
 ELSE
    condicion1:=' where '||v_condicion;
 END IF;



  v_sql:='select nvl(max(to_number('||v_id_tabla||')),0)+1 as valor from '||v_tabla||condicion1;

  EXECUTE IMMEDIATE v_sql INTO v_maximo;

  v_json:='{"max":"'||v_maximo||'"}';

  htp.p(v_json);



end;

procedure ficha_tipo_producto is





begin

     encabezado_cuadro(p_titulo_pagina=>'Ficha Tipo Producto');


    htp.p('

              <div class="form-horizontal">

                            <br>
                                <div class="form-group">
                                 <form id="div_ficha">


                                    <label class="col-lg-3 control-label">Tipo de Categoria:</label>
                                    <div class="col-lg-9">
                                        ');
                                       -- VENTA_ONLINE.get_list_tipo_categoria(p_id_sel=>'txt_cat_id',p_obligatorio=>1);
                                        HTP.P('
                                    </div>
                                    <label class="col-lg-3 control-label">Codigo</label>
                                    <div class="col-lg-5">
                                            <input disabled placeholder="INGRESE CODIGO" class="form-control obligatorio" name="txt_pro_id" id="txt_pro_id">

                                    </div>
                                    <div class="col-lg-4">
                                    <span class="input-group-btn">
                                                <button id="btn_buscar"  type="button" class="btn btn-primary">Buscar</button>
                                    </span>
                                   </div>
                                    <label class="col-lg-3 control-label">Nombre del producto</label>
                                    <div class="col-lg-9">
                                            <input  placeholder="INGRESE NOMBRE DEL PRODUCTO" class="form-control "  name="txt_pro_nombre" id="txt_pro_nombre">
                                    </div>
                                 </form>
                                </div>

            </div>
            <br>
            ');

            lista_tipo_producto;
            pie_cuadro_ingresos;

end;

function lee_json(p_json json , p_campo varchar2) return varchar2
is
v_return varchar2(32000);
begin
     begin
        v_return:= substr(p_json.get(p_campo).get_string, 1 ,32000);
    if trim(v_return) is null then
        v_return:= trim(substr(p_json.get(p_campo).get_number, 1 ,32000));
    end if;
    exception
    when SELF_IS_NULL then
        v_return := 'No Existe dato '''||p_campo||''' En el JSON';
    when others then
        v_return := 'Error:'||sqlerrm;
    end;
    return v_return;
end lee_json;

function call_url_p( p_url in varchar2 ,p_json varchar2) return long
is
    v_url varchar2(500) ;
    v_req   UTL_HTTP.REQ;
    v_resp  UTL_HTTP.RESP;
    v_line   VARCHAR2(32766);
    v_count  number := 0;
    v_return_pg long :='';

    g_clave_sap_pipo     VARCHAR2 (100) := 'c2FwcGl1dGFsY2E6cGl1dGFsY2EyMDE2'; --user:password base64 coded

begin
    --v_url := trim(decode_base_64(p_url));
    v_url := p_url;
    --htp.p(v_url);



    v_req := utl_http.begin_request(v_url,  method => 'POST' );
      utl_http.set_header(v_req, 'user-agent', 'mozilla/4.0');
      utl_http.set_header(v_req, 'content-type', 'application/json');
      utl_http.set_header(v_req, 'Content-Length', length(p_json));
     UTL_HTTP.SET_HEADER (v_req,
                           'Authorization',
                           'Basic ' || g_clave_sap_pipo);

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
END call_url_p;


PROCEDURE  CREA_CLIE_EDIT_SAP(p_codigo_sap in varchar2)  IS



    v_regi_codigo               varchar2(100):='07';-- codigo tiene que venir de SAP. POVE_CLIENTE.REGI_CODIGO%TYPE;
    v_ciud_codigo               varchar2(100):='04';--codigo tiene que venir de SAP. POVE_CLIENTE.CIUD_CODIGO%TYPE;
    v_clie_e_mail               POVE_CLIENTE.CLIE_EMAIL%TYPE;
    v_clie_tel_contacto         POVE_CLIENTE.CLIE_TEL_CONTACTO%TYPE;
    v_clie_direccion            POVE_CLIENTE.CLIE_DIRECCION%TYPE;
    v_clie_interlocutor         POVE_CLIENTE.CLIE_INTERLOCUTOR%TYPE;
    v_clie_nombre_pila          POVE_CLIENTE.clie_nombre_pila%TYPE;
    v_clie_apellido_paterno     POVE_CLIENTE.CLIE_APELLIDO_PATERNO%TYPE;
    v_clie_apellido_materno     POVE_CLIENTE.CLIE_APELLIDO_MATERNO%TYPE;
    v_clie_num_direccion        POVE_CLIENTE.CLIE_NUM_DIRECCION%TYPE;
    v_clie_canal_distribucion   POVE_CLIENTE.clie_canal_distribucion%TYPE;
    v_cli_cod_carrera           varchar2(100):='';
    v_cli_sexo                  varchar2(5):='1';
    v_cli_tratamiento           varchar2(100):='';-- PERSONA 0001 - EMPRESA 0003
    v_cli_agrupacion            varchar2(100):='ZC01';
    v_cli_cod_giro              varchar2(100):='';
    v_cli_rubro                 varchar2(100):='';
    v_rut varchar2 (1000);
    v_clie_matricula varchar2(100) := v_rut;
    v_ret varchar2(1);
    v_msg varchar2(5000);
    v_json varchar2(1500);
    v_respuesta clob ;
    v_token  varchar2(500);
    l_cli_json json;
    l_cli_json_data json_list;



begin



            SELECT clie_rut||'-'||clie_dv as clie_rut,
                   regi_codigo,
                   ciud_codigo,
                   clie_email,
                   clie_tel_contacto,
                   clie_direccion,
                   clie_interlocutor,
                   clie_nombre_pila,
                   clie_apellido_paterno,
                   clie_apellido_materno,
                   clie_num_direccion,
                   clie_canal_distribucion
            INTO   v_rut,
                   v_regi_codigo  ,
                   v_ciud_codigo ,
                   v_clie_e_mail ,
                   v_clie_tel_contacto  ,
                   v_clie_direccion ,
                   v_clie_interlocutor  ,
                   v_clie_nombre_pila  ,
                   v_clie_apellido_paterno  ,
                   v_clie_apellido_materno  ,
                   v_clie_num_direccion   ,
                   v_clie_canal_distribucion
            FROM pove_cliente
            WHERE CLIE_CODIGO = p_codigo_sap
          ;

  begin
     null;

            IF v_clie_interlocutor = '1' THEN

                    v_cli_tratamiento:='0001';
               ELSE

                    v_cli_tratamiento:='0003';

            END IF;

  -- **********  LLAMADA AL JSON DE LA FUNCION EN SAP PARA CREAR EL CLIENTE ************************************
 --  l_cli_json := utsap001.pkg_integra_utal.int_leg04_json(v_clie_interlocutor,v_rut,v_clie_matricula,v_cli_cod_carrera,v_cli_agrupacion,v_cli_tratamiento,v_clie_nombre_pila,v_clie_apellido_paterno,v_cli_cod_giro,v_cli_sexo,v_cli_rubro,v_clie_direccion,v_clie_num_direccion,v_ciud_codigo,v_regi_codigo,v_clie_tel_contacto ,v_clie_e_mail,v_clie_canal_distribucion,v_ret,v_msg);

    exception when others then
    htp.p(SQLERRM||DBMS_UTILITY.format_error_backtrace);
    end;
 --  v_respuesta:=l_cli_json.to_char(false);





 insert into log_editorial_pove (item_type,item_key  ,msg_sap,fecha_msg)
 values (v_rut,'Creacion de Cliente', v_respuesta,sysdate);

 commit;

END CREA_CLIE_EDIT_SAP;




procedure ficha_libros (codigo in varchar2)is


    v_prod_codigo       pove_producto_tl.PROD_CODIGO%TYPE;
    v_prod_descripcion  pove_producto_tl.PROD_DESCRIPCION%TYPE;
    v_prod_nombre       pove_producto_tl.PROD_NOMBRE%TYPE;
    v_prod_precio       pove_producto_tl.PROD_PRECIO%TYPE;
    v_pove_libr_num_paginas pove_libros.libr_num_paginas%TYPE;
    v_pove_libr_isbn pove_libros.libr_isbn%TYPE;
    v_pove_libr_agno pove_libros.libr_agno%TYPE;
    v_prod_codigo_sap        pove_producto_tl.prod_codigo_sap%type;
    v_pove_codigo_libros     pove_libros.libr_codigo%type;
    v_prod_imagen            pove_producto_tl.prod_imagen%TYPE;

    v_auto_nombre            pove_autor.auto_nombre%TYPE;

    v_tipo_codigo   pove_categoria_producto.tipo_codigo%type;
    v_cate_codigo   pove_categorias.cate_codigo%type;
    v_cate_descripcion   pove_categorias.cate_descripcion%type;
     v_prod_estado      pove_producto_tl.PROD_ESTADO%TYPE;

begin


   BEGIN

       select a.prod_nombre,
                a.prod_descripcion,
                b.libr_isbn,
                b.libr_agno,
                b.libr_num_paginas,
                a.prod_precio,
                a.prod_estado,
                d.cate_descripcion
         into   v_prod_nombre,
                v_prod_descripcion,
                v_pove_libr_isbn,
                v_pove_libr_agno,
                v_pove_libr_num_paginas,
                v_prod_precio,
                v_cate_descripcion,
                v_prod_estado
         from   pove_producto_tl a left join pove_libros b on a.prod_codigo=b.prod_codigo,
                pove_categoria_producto c,
                pove_categorias d
         where  a.prod_codigo=codigo--43
         and    c.cate_codigo=d.cate_codigo
         and    c.prod_codigo=a.prod_codigo
         and    a.prod_estado > 0;
         --and    a.prod_precio > 0;




/*select   a.prod_nombre,
         a.prod_descripcion,
         a.prod_precio,
         b.libr_isbn,
         b.libr_agno,
         b.libr_num_paginas
         ,(SELECT wm_concat(au.auto_nombre)
           -- into v_auto_nombre
          FROM  pove_libros_autores la,
                pove_autor au
          where la.auto_codigo=au.auto_codigo
          and   prod_codigo=a.prod_codigo) as autores
                ,(SELECT wm_concat(d.cate_descripcion)
          FROM  pove_categoria_producto c,pove_categorias d
          where c.tipo_codigo=d.tipo_codigo
          and   c.cate_codigo=d.cate_codigo
          and   c.prod_codigo=a.prod_codigo
          group by c.prod_codigo) as coleccion
  into   v_prod_nombre,
         v_prod_descripcion,
         v_pove_libr_isbn,
         v_pove_libr_agno,
         v_pove_libr_num_paginas,
         v_prod_precio,
         V_AUTO_NOMBRE,
         v_cate_descripcion
  from  pove_producto_tl a left join pove_libros b on a.prod_codigo=b.prod_codigo
  where a.prod_codigo=codigo;*/


   exception
      when no_data_found then
         v_prod_nombre:='0';
      when others then
         v_prod_nombre:='0';

   END;




 encabezado_cuadro(p_titulo_pagina=>'Ingreso de Libros');


htp.p('
<div id="response-container"></div>
      <div class="form-horizontal">

        <form id="div_ficha">
                  <div class="form-group">

                                <div style="display:none">
                                    <tr >
                                        <th>conteo select multiple:</th>
                                        <th>&nbsp;<span  id=''conteo''></span></th>
                                    </tr>
                                </div>

                                    <label class="'||v_ancho_label_lg||' control-label">Coleccion</label>
                                    <div class="'||v_ancho_columna2||'">
                                    <select class="chosen form-control m-b" name="txt_cate_codigo" id="txt_cate_codigo"  >
                                              <option value="-1" >'||v_cate_descripcion||'</option>
                                              ');
                                           get_combos('tipo_codigo||''/''|| cate_codigo', ' cate_descripcion', 'vec_cob03.pove_categorias', '');
                                         -- get_combos(codigo);
                               htp.p(' </select>');
                        HTP.P('
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Titulo</label>
                                    <div class="'||v_ancho_columna2||'">
                                                <input  placeholder="INGRESE NOMBRE DEL LIBRO" class="form-control obligatorio" value="'||v_prod_nombre||'" name="txt_prod_nombre" id="txt_prod_nombre" >
                                                <input  class="form-control " type="hidden" value="" name="txt_libr_codigo" id="txt_libr_codigo">
                                                <input  class="form-control " type="hidden" value="0" name="txt_prod_codigo" id="txt_prod_codigo">
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Codigo SAP</label>
                                    <div class="'||v_ancho_columna2||'">
                                                <input  placeholder="INGRESE CODIGO SAP" class="form-control obligatorio" value="'||v_prod_codigo_sap||'" name="txt_prod_codigo_sap" id="txt_prod_codigo_sap" >
                                                <input  class="form-control " type="hidden" value="" name="txt_libr_codigo" id="txt_libr_codigo">
                                                <input  class="form-control " type="hidden" value="0" name="txt_prod_codigo" id="txt_prod_codigo">
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Autor</label>
                                    <div class="'||v_ancho_columna2||' obligatorio">
                                            <select name="txt_auto_codigo" id="txt_auto_codigo" cname="miselect[]" class="chosen form-control m-b" data-placeholder="Seleccione Autores"  multiple>');
                                                 get_combos('auto_codigo', ' auto_nombre', 'vec_cob03.pove_autor', '');
                                            htp.p(''||v_auto_nombre||' </select>
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Descripcion</label>
                                    <div class="'||v_ancho_columna2||'">
                                                <textarea  placeholder="INGRESE DESCRIPCION DEL LIBRO" class="form-control obligatorio" value="" name="txt_prod_descripcion" id="txt_prod_descripcion" >'||v_prod_descripcion||'</textarea>
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Año</label>
                                    <div class="'||v_ancho_columna3||'">
                                            <input  placeholder="INGRESE AÑO DEL LIBRO" class="form-control  obligatorio solonumero" value="'||v_pove_libr_agno||'" name="txt_pove_libr_agno" id="txt_pove_libr_agno" maxlength="4"  >  <!-readonly="readonly" -->
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">N° de pag</label>
                                    <div class="'||v_ancho_columna3||'">
                                                <input  placeholder="INGRESE N° DE PAGINAS " class="form-control obligatorio solonumero" value="'||v_pove_libr_num_paginas||'" name="txt_pove_libr_num_paginas" id="txt_pove_libr_num_paginas" >
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Isbn</label>
                                    <div class="'||v_ancho_columna3||'">
                                                <input  placeholder="INGRESE ISBN " class="form-control obligatorio" value="'||v_pove_libr_isbn||'" name="txt_pove_libr_isbn" id="txt_pove_libr_isbn" >
                                    </div>
                                    <label class="'||v_ancho_label_lg||' control-label">Precio Ref.</label>
                                    <div class="'||v_ancho_columna3||'">
                                                <input  placeholder="INGRESE  PRECIO REFERENCIA" class="form-control  obligatorio solonumero" value="'||v_prod_precio||'" name="txt_prod_precio" id="txt_prod_precio" >
                                    </div>
                                </div>
                            </form>
                             <form enctype="multipart/form-data" method="post" id="form_subir_archivos"  class="form-horizontal">
                                    <div class="form-group" >
                                        <label class="'||v_ancho_label_lg||' control-label">Imagen del libro.</label>
                                        <div class="'||v_ancho_columna4||'">
                                                    <input type="file" id="archivos1" name="archivos1" onchange="validate_fileupload_imagen(this);" />
                                                    <input type="submit" name="Submit" value="Subir archivos" /> <!--disabled="true" -->
                                              <div class="messages">
                                                      </div>
                                        </div>
                                    </div>

                            </form>
                            ');
        pie_cuadro_ingresos;


        htp.p('
    </div>


        <script type="text/javascript">

        $(function() {
            $(''#txt_auto_codigo'').change(function(e) {
                var opts = e.target.options;
                var len = opts.length;

                var selected = [];

                document.getElementById("conteo").innerHTML = selected;



                for (var i = 0; i < len; i++) {
                  var texto;

                  var indice = document.getElementById("txt_auto_codigo").value
                    if (opts[i].selected) {



                     document.getElementById("conteo").innerHTML = selected.push(opts[i].length);
                     texto = "Codigo de opciones del select: " + indice

                    }

                }


                console.dir(selected);
                console.dir(texto);

            });
        });

        </script>

<script>

    var fileExtension = "";
    var extension_arr = [ "png" , "jpg"];

    function validate_fileupload_imagen(fileName )
    {
        v_file_name = fileName.value;
        file_extension = v_file_name.split(''.'').pop();
        $fileupload = $(''#archivos1'');

        if(  $.inArray( file_extension.toLowerCase() , extension_arr) >=0 ){

            return true;
        }else{

            $fileupload.replaceWith($fileupload.clone(true));
            toastr.warning("La imagen adjuntada no es de un tipo permitido , se recomienda adjuntar imagen con extension en PNG, JPG.")
            return false;
        }
    }

</script>
<script>

        $(".messages").hide();

             $(function(){
                    $("#form_subir_archivos").on("submit", function(e){
                        e.preventDefault();
                        var f = $(this);
                        var formData = new FormData(document.getElementById("form_subir_archivos"));

                        var largo_archivo1 = document.getElementById("archivos1").files.length;



                            var file1 = $("#archivos1")[0].files[0];
                            var fileName1 = file1.name;
                            $("#archivo1").val(fileName1);
                           alert(''hhh''+fileName1);

                formData.append("dato", "valor");
                var message = "";
                $.ajax({
                        url: "http://inet.utalca.cl/inspinia/img/editorial/SubirArchivo.php",
                        type: "post",
                        dataType: "html",
                        data: formData,
                        cache: false,
                        contentType: false,
                        processData: false,
                        beforeSend:function(){
                        message = $("<span class=''before''>Subiendo Archivos, por favor espere...</span>");
                        showMessage(message)},
                        success:function(data){
                        message = $("<span class=''success''>Los archivos se han subido correctamente.</span>");
                        showMessage(message)},
                        error: function(){
                        message = $("<span class=''error''>Archivos Cargados Correctamente.</span>");
                        showMessage(message)}
                    }).done(function(res){
                        alert(res);
                        $("#mensaje").html("Respuesta: " + res);
                        });
                    });
                });

                function showMessage(message){
                    $(".messages").html("").show();
                    $(".messages").html(message);
                }

                </script>

    ');

end;

procedure prueba is
BEGIN
 htp.p('
 <head>

          <link href="'||path_inspinia||'css/plugins/chosen/chosen.css" rel="stylesheet">

    <script src="'||path_inspinia||'js/jquery-2.1.1.js"></script>

    <script>
        $(document).ready(function(){
            $(".chosen").chosen();
       });
    </script>

    <select name="miselect" class="chosen" data-placeholder="Elige un color">
    <option value=""></option>
    <option value="azul">Azul</option>
    <option value="amarillo">Amarillo</option>
    <option value="blanco">Blanco</option>
    <option value="gris">Gris</option>
    <option value="marron">Marron</option>
    <option value="naranja">Naranja</option>
    <option value="negro">Negro</option>
    <option value="rojo">Rojo</option>
    <option value="verde">Verde</option>
    <option value="violeta">Violeta</option>
</select>
  <script src="'||path_inspinia||'js/plugins/chosen/chosen.jquery.js"></script>

</head>
 ');
end;

procedure contacto_tecnico is

begin

    estilos;

    htp.p('
    <br><br><br><br><br><br>
    <div class="col-lg-offset-4 col-lg-6">
    <div class="contact-box">
        <a href="profile.html">
            <div class="col-sm-4">
                <div class="text-center">
                    <img alt="image" class="img-circle m-t-xs img-responsive" src="'||ruta_imagen||'perfil_ale.png">
                    <div class="m-t-xs font-bold">Gestor de Aplicaciones</div>
                </div>
            </div>
            <div class="col-sm-8">
                 <strong>Universidad de Talca</strong>
                <p><i class="fa fa-map-marker"></i> #2 Norte</p>
                <address>

                    <h3><strong>Se informa que la pagina se encontrara disponible para compras a partir del 25 de Febrero.</strong></h3><br>
                    <br>
                    <abbr title="Telefono">P:</abbr> Anexo 1907
                </address>
            </div>
            <div class="clearfix"></div>
        </a>
    </div>
</div>


    <script>
        $(document).ready(function(){
            $(''.contact-box'').each(function() {
                animationHover(this, ''pulse'');
            });
        });
    </script>');

end;

procedure json_libros_carrito (v_lista_libros varchar2  default null)
 is
  l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
  v_sql varchar2(2000);
  v_autores varchar2(2000);
  v_coleccion varchar2(2000);
v_final varchar2(2000);
BEGIN

  owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;
v_final:=substr(v_lista_libros,2);
v_final:=replace(v_final,'@',''',''');

  v_sql:='select a.prod_codigo,a.prod_nombre,a.prod_descripcion,a.prod_precio,a.prod_imagen,a.prod_estado from pove_producto_tl a  where a.prod_codigo in ('''||v_final||''')  order by 2';

--htp.p(v_sql);
 l_jobs_json := json_list();
 l_jobs_json := json_dyn.executeList(v_sql);

 l_json := json();
 l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure json_libros (p_prod_codigo number  default null)
 is

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
  v_sql varchar2(2000);
  v_autores varchar2(2000);
  v_coleccion varchar2(2000);

BEGIN

  owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;
  v_autores:='(SELECT listagg(auto_nombre, chr(44)) within group (order by auto_nombre) FROM  pove_libros_autores, pove_autor where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo) as autores ';
  v_coleccion:='(SELECT listagg(d.cate_descripcion, chr(44)) within group (order by d.cate_descripcion)  FROM pove_categoria_producto c,pove_categorias d  where  c.tipo_codigo=d.tipo_codigo and c.cate_codigo=d.cate_codigo and c.prod_codigo=a.prod_codigo group by c.prod_codigo) as coleccion ';
  v_sql:='select a.prod_codigo,a.prod_nombre,a.prod_descripcion,a.prod_precio,a.prod_imagen,a.prod_estado,b.libr_isbn,b.libr_agno,b.libr_num_paginas,'||v_autores||','||v_coleccion||' from pove_producto_tl a left join pove_libros b on a.prod_codigo=b.prod_codigo where a.prod_codigo='''||p_prod_codigo||''' and a.prod_estado > 0 order by b.libr_agno desc';


 l_jobs_json := json_list();
 l_jobs_json := json_dyn.executeList(v_sql);

 l_json := json();
 l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;


procedure json_libros_modificar (p_prod_codigo number  default null,
                                 p_prod_nombre varchar2  default null)
 is

   l_json_clob clob;
   l_json      json;
   l_employee_json  json;
   l_jobs_json      json_list;
  v_sql varchar2(2000);
  v_autores varchar2(2000);
  v_coleccion varchar2(2000);

BEGIN

  owa_util.mime_header('application/json',false, g_charset);
  OWA_UTIL.http_header_close;
  v_autores:='(SELECT wm_concat(auto_nombre) FROM  pove_libros_autores, pove_autor where pove_libros_autores.auto_codigo=pove_autor.auto_codigo and prod_codigo=a.prod_codigo) as autores ';
 v_coleccion:='(SELECT wm_concat(d.cate_descripcion)  FROM pove_categoria_producto c,pove_categorias d  where  c.tipo_codigo=d.tipo_codigo and c.cate_codigo=d.cate_codigo and c.prod_codigo=a.prod_codigo group by c.prod_codigo) as coleccion ';

  v_sql:='select a.prod_codigo,a.prod_nombre,a.prod_descripcion,a.prod_precio,a.prod_imagen,a.prod_estado,b.libr_isbn,b.libr_agno,b.libr_num_paginas,'||v_autores||','||v_coleccion||' from pove_producto_tl a left join pove_libros b on a.prod_codigo=b.prod_codigo where a.prod_codigo='''||p_prod_codigo||''' and a.prod_estado !=0 order by b.libr_agno desc';


 l_jobs_json := json_list();
 l_jobs_json := json_dyn.executeList(v_sql);

 l_json := json();
 l_json.put('data', l_jobs_json.to_json_value);
 l_json.htp();


END;




procedure portal_ventas ( m in NUMBER default 0, s in varchar2 default null) is

begin


if 1=0 then
 htp.p('SITIO DISPONIBLE DESDE LAS 01:00HRS DEL 03.08.2024');--- ALEXIS ROJAS 29.07.2024 POR INSCRIPCION
else

htp.p('<html>');
    htp.p('<head>');
    htp.p('<title>'||g_nombre_sistema||'</title>');
--estilos_editorial;
    htp.p('
    <link href="'||path_inspinia||'css/bootstrap.min.css" rel="stylesheet">
    <link href="'||path_awesome||'css/font-awesome.min.css" rel="stylesheet">
    <link href="'||path_inspinia||'css/plugins/jasny/jasny-bootstrap.min.css" rel="stylesheet">
    <!-- Toastr style -->
    <link href="'||path_inspinia||'css/animate.css" rel="stylesheet">
 <link href="'||path_inspinia||'css/style1.css" rel="stylesheet">
 <style>
   body {
       background-color: #ffffff;
   }
 </style>
    ');



    htp.p('</head>');

    htp.p('<body>


    ');

        htp.p('
         <div id="" class="white-bg dashbard-1">


        ');
        --menu_ubicacion(m);
        htp.p('<div class="row">');
            htp.p('<div class="col-lg-12">');

          --    if m=132 then
                     --inicio;
          --           ingreso_libro;
           --   end if;
               htp.p('

    <script src="'||path_inspinia||'js/jquery-latest.js"></script>
  <script>
        $(document).ready(function(){
            $(".chosen").chosen();
       });

    </script>

  ');
  g_m:=m;
  g_s:=s;

   funcion_json;


         CASE m

            When 133 Then
                ficha_libros(s);
            When 180 Then
                mantenedor_tipo_producto;
            When 181 Then
                mantenedor_tipo_categoria;
            When 182 Then
                listado_productos;
            When 183 then
                mantenedor_autores;
            When 1001 then
                 listado_productos;
            When 1003 then
                 listado_autores;
            Else
               tab_panel(g_m,g_s);


         END CASE;


        htp.p('</div>');
            htp.p('</div>
        </div>');


 librerias_js;
 htp.p('
     <script>
           $(''#data_3 .input-group.date'').datepicker
            ({
                startView: 2,
                todayBtn: "linked",
                keyboardNavigation: false,
                forceParse: false,
                autoclose: true
            });
      </script>



 ');

 funciones_js;


    htp.p('</body>');
htp.p('</html>');
end if;

end;


PROCEDURE login
   IS


 rut_in varchar2(12);

   BEGIN

HTP.p ('
<html>');

    htp.p('<head>');
    htp.p('<title>'||g_nombre_sistema||'</title>');
          estilos;
    htp.p('</head>');

htp.p('

<body class="gray-bg">

    <div class="middle-box text-center loginscreen">
        <div>
            <div>
                <!--<img  src="http://www.adhocsystem.cl/dtt/Logo DTT.jpg">-->
            </div>
            <h3>Bienvenido Sistema Portal de ventas Editorial</h3>

            </p>
            <p>Iniciar Sesion.</p>
            <form id="div_ficha">
                <div class="form-group">
                    <input id="txt_usua_rut" maxlength="10" name="txt_usua_rut" value="" type="text" class=" form-control obligatorio" placeholder="Rut" required>
                    <span class="help-block m-b-none">&nbsp;</span>
                </div>
                <div class="form-group">
                    <input id="txt_usua_password" name="txt_usua_password" type="password" class="form-control obligatorio" placeholder="Password" required>
                </div>
                <button id="btn_validar" class="btn btn-primary">Ingresar</button>
            </form>
        </div>
    </div>');

 librerias_js;
 --funcion_json;
 funciones_js;

htp.p('
<script>



$(document).ready(function(){

      $(".solonumeros").keypress(function( event ) {
           var charCode = (event.which) ? event.which : event.keyCode;
               if (charCode > 31 && (charCode < 48 || charCode > 57))
               {
                    event.preventDefault();
               }
      });


$("#btn_validar").click(function(e){

if ( validar("div_ficha") )
{
    e.preventDefault();

    variables="v_rut="+$(''#txt_usua_rut'').val()+"&v_password="+$(''#txt_usua_password'').val();


                $.ajax({

                            url:''venta_online.procesar_login'',
                            type:''GET'',
                            data:variables,
                            dataType: "json",
                            success:function(response){

                                 response = $.trim(response.toString());
                                 //mostrar_toastr(response,1);
                                 if (response==0) {
                                     //createCookie( "SESSION_RUT" , $(''#txt_usua_rut'').val() , 1 );
                                     document.location.href="venta_online.principal?rut_in="+$("#txt_usua_rut").val()+"&m=0";
                                                                                //p_rut="+$("#txt_usua_rut").val()+"&p_sesion=0";
                                                                                 // p_rut="+$("#txt_usua_rut").val()+"&p_sesion=0
                                 }else{
                                     alert("Acceso Denegado,Verifique Rut y Password")
                                     $("#txt_usua_rut").focus()
                                 }
                            }
                });

    }
});

});
</script>

<script>

   function validar(nombre_div)
{


    var sAux="";

    var frm = document.getElementById(nombre_div);

    for (i=0;i<frm.elements.length;i++)
    {


    if ( frm.elements[i].classList.contains(''obligatorio'') )
        {


            if ( (frm.elements[i].type==''text'' || frm.elements[i].type==''password'') && frm.elements[i].value=='''')
            {


                        mostrar_toastr( ''"''+ frm.elements[i].placeholder +  ''" CAMPO REQUERIDO'',2);
                        frm.elements[i].focus();
                        return false;

                        break;
            }
            if (frm.elements[i].type==''select-one'' &&  $(''#''+frm.elements[i].name).val()==''-1'')
            {
                        mostrar_toastr(''"''+ $(''#''+frm.elements[i].name+'' option:selected'').text() + ''" CAMPO REQUERIDO'',2);
                        frm.elements[i].focus();
                        return false;

                        break;
            }
        }
    }
    return true;

}


</script>





</body>


</html>
');

   END login;

   PROCEDURE procesar_login (v_rut IN VARCHAR2, v_password IN VARCHAR2)


   IS
    --  jsondata    t_array;
      elmensaje   VARCHAR2 (100) := '';
      valida      NUMBER (10)    := 1;

      CURSOR c_cursor
      IS
         SELECT usua_nombre
           FROM gene_usuario
          WHERE usua_rut = UPPER (v_rut)
          AND  usua_password = UPPER(v_password);


   BEGIN
      /*recibir_variables();*/
      FOR m_cursor IN c_cursor
      LOOP
         elmensaje := m_cursor.usua_nombre;



       --  htp.p(elmensaje);
         valida := 0;
      END LOOP;

      HTP.p (valida);

   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (   'Error:'
                || SQLERRM
                || ' procedure procesar_login, favor contactar al Administrador'
               );
   END procesar_login;


procedure validar_acceso(p_rut in varchar2, p_sesion in varchar2) is

rut_in    rem_ficha.rol_emp%type;
n         number;

begin

--Verificar que el asistente exista
--HTP.P(p_rut);
  select count(*) into n
  from rem_ficha
  where rol_emp = p_rut;

  if n <> 0  then
  --  HTP.P(p_rut);


     --asistente_acceso.paso (rut,n);

               select rol_emp into rut_in
               from rem_ficha
               where rol_emp = p_rut
               and rownum = 1;

               if n = 1 then
                 htp.p('<script>
                            window.location.href='||chr(39)||'VENTA_ONLINE.principal?m=0'||chr(39)||';
                       </script>');
               else
                  htp.p('<script>
                             window.location.href='||chr(39)||'VENTA_ONLINE.login'||chr(39)||';
                  </script>');
               end if;
               owa_util.http_header_close;

  else
     htp.p('<script>
        alert("Problemas al intentar Ingresar al SISTEMA. Verifique su Rut y su clave, si aún asi tiene problemas converse con el Administrador.");
        history.go(-1);
        </script>');
  end if;

end;

procedure principal (m in NUMBER default 0,
                     s in varchar2 default null--,
                     --rut_in     IN   VARCHAR2 DEFAULT NULL
                     ) is




BEGIN
htp.p('<html>');
    htp.p('<head>');
    htp.p('<title>'||g_nombre_sistema||'</title>');

          estilos;
    htp.p('</head>');

    htp.p('<body>');

          htp.p('<div id="wrapper">
        <nav class="navbar-default navbar-static-side" role="navigation">
            <div class="sidebar-collapse">
                <ul class="nav" id="side-menu">



                    ');

                    perfil; --(rut_in);
                    menu(m);



               htp.p(' </ul>

            </div>
        </nav>
        </div>
          ');

        htp.p('
         <div id="page-wrapper" class="gray-bg dashbard-1">
        <div class="row border-bottom">
        <nav class="navbar navbar-static-top" role="navigation" style="margin-bottom: 0">
        <div class="navbar-header">
            <a class="navbar-minimalize minimalize-styl-2 btn btn-primary " href="#"><i class="fa fa-bars"></i> </a>
            <form role="search" class="navbar-form-custom" action="">
                <div class="form-group">
                    <input type="text" placeholder="Minimizar Menu" class="form-control" name="top-search" id="top-search">
                </div>
            </form>
        </div>
            <ul class="nav navbar-top-links navbar-right">
                <li>
                    <span class="m-r-sm text-muted welcome-message">Sistema de Editorial.</span>
                </li>


              <!- mensajes.php;
               alertas.php;-->



                <li>
                    <a href="venta_online.login">
                        <i class="fa fa-sign-out"></i> Salir
                    </a>
                </li>
                <li>
                    <a class="right-sidebar-toggle">
                        <i class="fa fa-tasks"></i>
                    </a>
                </li>
            </ul>

        </nav>
        </div>


        ');
        menu_ubicacion (m);
        htp.p('<div class="row">');
            htp.p('<div class="col-lg-12">');

          --    if m=132 then
                     --inicio;
          --           ingreso_libro;
           --   end if;
               htp.p('

  <script src="'||path_inspinia||'js/jquery-latest.js"></script>
  <script>
        $(document).ready(function(){
            $(".chosen").chosen();
       });

    </script>

  ');
  g_m:=m;
   funcion_json;


         CASE m

            When 133 Then

                ficha_libros(s);
            When 180 Then
                mantenedor_tipo_producto;
            When 181 Then
                mantenedor_tipo_categoria;
            When 182 Then
               -- listado_productos;
               listado_productos_prueb;
            When 183 then
                mantenedor_autores;
            When 192 then
                mantenedor_valores_despacho;
            When 184 then
                mantenedor_paises;
            When 185 then
                mantenedor_regiones;
               -- When 186 then
               -- mantenedor_ciudades;
            When 187 then
                mantenedor_estado_despacho;
            When 220 then
                listado_clientes;
            When 221 then
                listado_envio_dbnet;
           -- When 222 then
            --    informe_ventas_libro;
            When 223 then
                informe_envio_despacho;
            When 1001 then
                 listado_productos;
            When 1003 then
                 listado_autores;
            When 10 then
                 contacto_tecnico;
            Else
                inicio;

         END CASE;


        htp.p('</div>');
            htp.p('</div>
        </div>');

 footer(p_titulo_footer=>'Sistema portal de ventas 2016');
 librerias_js;
 htp.p('
     <script>
           $(''#data_3 .input-group.date'').datepicker
            ({
                startView: 2,
                todayBtn: "linked",
                keyboardNavigation: false,
                forceParse: false,
                autoclose: true
            });
      </script>

 ');
 funciones_js;


    htp.p('</body>');
htp.p('</html>');
end;

procedure envio_correo_ingresar(p_id_vta_subprod   number ,
                       p_orden_compra     number )

is

cursor c_registros is

        SELECT POVE_VENTA_TRANSACCIONES.VETR_CODIGO ,
               POVE_CLIENTE.CLIE_RUT,
               POVE_CLIENTE.CLIE_DESTINATARIO,
               POVE_CLIENTE.CLIE_EMAIL,
               POVE_CLIENTE.CLIE_TEL_CONTACTO,
               POVE_REGION.REGI_DESCRIPCION,
               POVE_CIUDAD.CIUD_DESCRIPCION,
               POVE_CLIENTE.CLIE_DIRECCION,
               POVE_CLIENTE.CLIE_NUM_DIRECCION,
               DECODE(CLIE_RETIRO,'S','TIENDA','N','DESPACHO A DOMICILIO',CLIE_RETIRO) AS CLIE_RETIRO,
               POVE_VENTA.VENT_FECHA,
               POVE_VENTA_TRANSACCIONES.VETR_MONTO_PAGAR,
               POVE_PRODUCTO_TL.PROD_NOMBRE,
               POVE_VENTA_DETALLE.VEDE_CANTIDAD
        FROM   VEC_COB03.POVE_VENTA_DETALLE,VEC_COB03.POVE_ESTADO_DESPACHO,VEC_COB03.POVE_VENTA,VEC_COB03.POVE_CLIENTE,
        VEC_COB03.POVE_REGION, VEC_COB03.POVE_CIUDAD, VEC_COB03.POVE_VENTA_TRANSACCIONES , VEC_COB03.POVE_PRODUCTO_TL
        WHERE  POVE_VENTA_DETALLE.ESDE_CODIGO=POVE_ESTADO_DESPACHO.ESDE_CODIGO
        AND    POVE_VENTA_DETALLE.VENT_CODIGO=POVE_VENTA.VENT_CODIGO
        AND    POVE_CLIENTE.CLIE_CODIGO = POVE_VENTA.CLIE_CODIGO
        AND    POVE_CLIENTE.REGI_CODIGO = POVE_REGION.REGI_CODIGO
        AND    POVE_CLIENTE.CIUD_CODIGO = POVE_CIUDAD.CIUD_CODIGO
        AND    POVE_VENTA_TRANSACCIONES.VENT_CODIGO = POVE_VENTA.VENT_CODIGO
        AND    POVE_PRODUCTO_TL.PROD_CODIGO = POVE_VENTA_DETALLE.PROD_CODIGO
        AND    POVE_VENTA_TRANSACCIONES.VETR_CODIGO = p_id_vta_subprod
        ORDER BY VENT_FECHA DESC;



v_mail_id number;
--variable para el estado
v_estado_envio VARCHAR2(20) :='X';
v_ret_msg   varchar2(20000) :='';
v_ret_code  varchar2(5) :='S';




v_texto_largo varchar2(12000); --long
v_texto_largo2 long (12000);

--variable para el estado

v_reply_to varchar2(100) := 'no.responder.editorial@utalca.cl';
v_mail_from varchar2(100):= 'no.responder.editorial@utalca.cl';
v_mail_to   varchar2(100);
v_header    varchar2(1000);


v_resp varchar2(32000);
--call_url VARCHAR2(32000);

begin


    begin
        select editorial_envio_mail_seq.nextval
        into v_mail_id
        from dual   ;
    exception when others then
        v_mail_id := 0;
    end ;


    if nvl(v_mail_id,0) <> 0 then





 v_texto_largo:=v_texto_largo||'<!DOCTYPE html>
<html>
<head>

    <meta charset="ISO-8859-1">
<style>


#contenedor {
    border: 1px solid #1AB394;
    background-color: #F2F2F2;


}

p{
    color:#888 ;
}

table {

 border-color: #1AB394 #1AB394 #1AB394 #1AB394;
  border-collapse: collapse;

}

th{
 border : 0px;

}
td{
 border : 0px;
}


</style>
</head>
<body>

    <p><strong>Estimados:</strong></br></p>
        <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Se ha realizado la siguiente compra.'||p_orden_compra||'</br></br></br>
            Adjuntamos detalle de la venta realizada y durante el transcurso del día le enviaremos su boleta.</p>

       <caption><h2 bgcolor="#1AB394"><strong>Datos del Cliente</strong></h2></caption>
            <table cellpadding="20" bgcolor="#FAFAFA" align="center" border="0"  >';

    for i in c_registros loop
      --  v_mail_to := i.clie_email;
        v_texto_largo:=v_texto_largo||'

                <tr>
                    <th align="left">Rut Cliente:</th>
                    <td>'||i.clie_rut||'</td>
                    <td></td>
                    <th align="left">Fecha Compra</th>
                    <td>'||i.VENT_FECHA||'</td>
                    <td></td>
                </tr>
                <tr>
                    <th align="left">Nombre Completo:</th>
                    <td colspan="4">'||i.clie_destinatario||'</td>
                <tr>
                    <th align="left">Telefono Contacto:</th>
                    <td colspan="4">'||i.CLIE_TEL_CONTACTO||'</td>

                </tr>
                <tr>
                    <th align="left">mail :</th>
                    <td colspan="4">'||i.CLIE_EMAIL||'</td>

                </tr>
                <tr>
                    <th align="left">Total Cancelado:</th>
                    <td colspan="4">'||i.VETR_MONTO_PAGAR||'</td>
                </tr>
                <tr>
                    <th align="left">Tipo de envio:</th>
                    <td colspan="4">'||i.CLIE_RETIRO||'</td>

                </tr>
                <tr>
                    <th align="left">Region:</th>
                    <td colspan="4">'||i.REGI_DESCRIPCION||'</td>

                </tr>
                <tr>
                    <th align="left">Ciudad:</th>
                    <td colspan="4">'||i.CIUD_DESCRIPCION||'</td>

                </tr>
                <tr>
                    <th align="left">Direccion:</th>
                    <td colspan="4">'||i.CLIE_DIRECCION||'</td>

                </tr>
                <tr>
                    <th align="left">Numero de direccion:</th>
                    <td colspan="4">'||i.CLIE_NUM_DIRECCION||'</td>

                </tr>
                <tr>
                    <th align="left">Nombre del libre:</th>
                    <td colspan="4">'||i.PROD_NOMBRE||'</td>

                </tr>
                <tr>
                    <th align="left">Cantidad:</th>
                    <td colspan="4">'||i.VEDE_CANTIDAD||'</td>

                </tr>
                ';

          v_texto_largo:=v_texto_largo||'

    </table>';
    end loop;

    v_texto_largo:=v_texto_largo||'
    </body>
</html>';
        if v_estado_envio = 'X'  then

           begin

                  select vgea001.vgea_envio_mail_seq.nextval
                      into v_mail_id
                       from dual ;

                v_texto_largo2:=vgea001.web_util.codificar_html(v_texto_largo);

                insert into vgea001.vgea_envio_mail (mail_id ,
                                                     mail_estado ,
                                                     mail_to ,
                                                     mail_from ,
                                                     mail_reply_to ,
                                                     mail_subject ,
                                                     mail_message ,
                                                     mail_header)
                             values(v_mail_id ,
                                     'P' ,
                                    nvl(g_mail_to,v_mail_to)  ,
                                    v_mail_from ,
                                    v_reply_to ,
                                    'Venta de libros ' ,
                                    --vgea001.web_util.codificar_html(v_texto_largo)  ,
                                    v_texto_largo2  ,
                                    '*') ;

                         commit;

                       v_resp := vgea001.WEB_UTIL.call_url_n('http://inet.utalca.cl/consolidado_utal/envio_mail.php?p_id='||v_mail_id);



             exception when others then

                   v_estado_envio :='E';
                   v_ret_msg := sqlerrm;
            end;
        end if;

    commit;
   end if;

    begin
         --  v1 := vec_cob03.web_util.call_url(web_util.encode_base_64('http://inet.utalca.cl/consolidado_utal/envio_mail_editotial.php?p_id='||v_mail_id));
        null;
    exception when others then

      v_estado_envio :='E';
      v_ret_msg := sqlerrm;
    end;
dbms_output.put_line(v_ret_msg);

end envio_correo_ingresar;


procedure banner_editorial is
begin

      HTP.p('
            <div class="col-lg-offset-1 col-lg-10">
                       <div class="navbar-header ">
                         <tr>
                           <td width="967" height="119"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                             <tr>
                               <td><img src="'
            || ruta_imagen
            || 'utalca_01.png" width="33" height="119" alt=""></td>
                               <td><img src="'
            || ruta_imagen
            || 'utalca_02.png" width="264" height="119" alt=""></td>
                               <td><img src="'
            || ruta_imagen
            || 'utalca_03.png" width="299" height="119" alt=""></td>
                               <td><img src="'
            || ruta_imagen
            || 'utalca_04.png" alt="" width="404" height="119" usemap="#Map" border="0">
                                 <map name="Map">
                                   <area shape="rect" coords="126,31,352,54" href="http://www.utalca.cl" target="_blank">
                                   <area shape="rect" coords="217,78,239,101" href="https://www.facebook.com/utalca" target="_blank">
                                   <area shape="rect" coords="244,77,267,101" href="https://twitter.com/utalca" target="_blank">
                                   <area shape="rect" coords="270,77,292,101" href="https://www.instagram.com/utalca/" target="_blank">
                                   <area shape="rect" coords="297,77,319,101" href="https://www.youtube.com/user/canalUtalca" target="_blank">
                                   <area shape="rect" coords="323,77,347,101" href="https://www.linkedin.com/in/utalca?trk=nav_responsive_tab_profile_pic" target="_blank">
                               </map></td>
                             </tr>
                           </table></td>
                       </tr>
                    </div>
                </div>
          ');

end;

procedure tab_panel ( m in NUMBER default 0, s in varchar2 default null)  is

cursor cur_panel is

select a.tipo_codigo, a.tipo_descripcion, a.tipo_imagen, a.tipo_link,
       a.tipo_activo
FROM pove_tipo_producto a
          WHERE tipo_activo = 1
          and tipo_codigo = 1;

v_activo varchar2(50);

begin
     --estilos;
   --  estilos_editorial;
    htp.p('<div style="height:100%;">
            <div class="col-lg-12">
                    <div class="panel blank-panel">

                        <div class="panel-heading">
                            <div class="panel-options">
                                 <ul class="nav nav-tabs">');
                                    v_activo:='';
                                    FOR fila IN cur_panel LOOP
                                        if g_s=fila.tipo_codigo then
                                             v_activo:='active';
                                        else
                                             v_activo:='';
                                        end if;
                                      htp.p('
                                           <li class="'||v_activo||'"><a data-toggle="tab" href="#tab-'||fila.tipo_codigo||'" aria-expanded="true"><i class="fa '||fila.tipo_imagen||'"></i> '||fila.tipo_descripcion||'</a></li>');
                                    end loop;
                                    htp.p('
                                </ul>
                            </div>
                        </div>
                        <div class="panel-body"> <!--INICIO DEL PANEL-->
                            <div class="tab-content">');
                                v_activo:='';
                             FOR fila IN cur_panel LOOP

                                 if g_s=fila.tipo_codigo then
                                     v_activo:='active';
                                   else
                                      v_activo:='';
                                 end if;

                             htp.p('<div id="tab-'||fila.tipo_codigo||'" class="tab-pane '||v_activo||'" style="height:100%;">');

                                  CASE fila.tipo_codigo

                                        When 1 Then
                                          --venta_lista_libros;
                                           venta_online.servicio_muestra_libros;
                                         --htp.p('<iframe src="http://127.0.0.1:8888/ventas%20online/servicio_muestra_libros.php"></iframe>');

                                           --htp.p('*');
                                        When 2 Then
                                            htp.p('**');

                                        When 3 Then
                                            htp.p('
                                                 <div>
                                                        --<object type="text/html" data="http://condor2.utalca.cl/pls/ractit_desa/inicio.login" width="100%" height="100%">
                                                        <object type="text/html" data="http://condor2-19testing.utalca.cl/pls/ractit_desa/inicio.login" width="100%" height="100%">
                                                        </object>
                                                 </div>

                                            ');
                                            --http://condor2.utalca.cl/pls/ractit_desa/inicio.login
                                        when 4 then
                                           --  htp.p('****');
                                          --utsap001.pkg_portal_pagos.portal_estudiantes(m,s); principal('125462681111')
                                        --  vec_cob01.portaldepagos.login_portal('17949294');
                                        -- ant 24866909 .. 23840487...16164776 .. 6794367 ..23840487
                                            /*
                                            alumnos con 4 matriculas y 10 aranceles cargados
                                            14389450-9
                                            16997605-8
                                            16456381-2
                                            9137333-5
                                            15766966
                                            */

                            htp.p('
                                                 <div>
                                                        <object type="text/html" data="http://condor2.utalca.cl/pls/cob/portaldepagos.login_portal?p_rut=24676442" width="100%" height="100%">
                                                        </object>
                                                 </div>

                                            ');

                                        When 5 Then
                                            htp.p('
                                                 <div>
                                                        --<object type="text/html" data="http://condor2.utalca.cl/pls/raccer_desa/certificado.login" width="100%" height="100%">
                                                        <object type="text/html" data="http://condor2-19testing.utalca.cl/pls/raccer_desa/certificado.login" width="100%" height="100%">
                                                        </object>
                                                 </div>

                                            ');
                                           -- venta_lista_libros;

                                        Else
                                            htp.p('noooooo');

                                     END CASE;

                             htp.p('</div>');

                            end loop;
                    htp.p('

                    </div>
                </div>
             </div>

                           <!--        <div id="tab-1" class="tab-pane">
                                    <div class="row">
                                        <div class="col-lg-12">
                                        ');
                                      --  libros;
                                        htp.p('

                                        </div>
                                    </div>
                                </div>
                                <div id="tab-2" class="tab-pane">
                                     <div class="row">
                                        <div class="col-lg-12">
                                        **

                                         </div>
                                     </div>
                                </div>    -->


    ');


librerias_js;

end;




procedure footer(p_titulo_footer in varchar2 default null) is

begin

htp.p('<div class="footer" style="z-index:0;">
            <div class="pull-right">
                .<strong>.</strong>
            </div>
            <div>
                <strong>Copyright</strong> '||p_titulo_footer||'
            </div>
        </div>');


end;
procedure librerias_js is
begin

   htp.p('

     <!-- Mainly scripts -->
    <script src="'||path_inspinia||'js/jquery-2.1.1.js"></script>
    <script src="'||path_inspinia||'js/bootstrap.min.js"></script>

    <!-- Custom and plugin javascript -->
    <script src="'||path_inspinia||'js/inspinia.js"></script>
    <script src="'||path_inspinia||'js/plugins/pace/pace.min.js"></script>
    <script src="'||path_inspinia||'js/plugins/slimscroll/jquery.slimscroll.min.js"></script>

    <!-- Chosen -->
    <script src="'||path_inspinia||'js/plugins/chosen/chosen.jquery.js"></script>
   <!-- Input Mask-->
    <script src="'||path_inspinia||'js/plugins/jasny/jasny-bootstrap.min.js"></script>

   <!-- Data picker -->
   <script src="'||path_inspinia||'js/plugins/datapicker/bootstrap-datepicker.js"></script>


    <!-- iCheck -->
    <script src="'||path_inspinia||'js/plugins/iCheck/icheck.min.js"></script>


    <!-- MENU -->
    <script src="'||path_inspinia||'js/plugins/metisMenu/jquery.metisMenu.js"></script>

    <!-- Toastr script ***********-->
    <script src="'||path_inspinia||'js/plugins/toastr/toastr.min.js"></script>
    <!-- Toastr script ***********-->
    <script src="'||path_inspinia||'js/bootbox.min.js"></script>

    <script>

$("body").removeClass(''boxed-layout'');
$(".footer").addClass(''fixed'');


</script>
   ');
end;

END;