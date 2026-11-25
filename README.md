# GlucoControl

**Tu glucosa bajo control, todos los días.**

Aplicación Android gratuita, sin anuncios, sin suscripciones y **100% sin conexión a internet**, diseñada para ayudar a personas con diabetes y a sus familias (especialmente adultos mayores) a registrar, consultar y compartir sus mediciones de glucosa de forma sencilla y segura.

---

## Características principales

- **Perfil del paciente:** nombre, fecha de nacimiento opcional, unidad preferida (`mg/dL` o `mmol/L`) y rangos de referencia personalizados indicados por su médico.
- **Panel principal:** saludo personalizado, última medición con indicador visual de rango, contador diario, gráfica semanal y accesos rápidos grandes.
- **Registro de glucosa:** formulario claro con validaciones, 9 tipos de medición, observaciones y aviso informativo si un valor queda fuera del rango configurado.
- **Historial completo:** orden cronológico, búsqueda por texto, filtro por rango de fechas y por tipo de medición, edición y eliminación con confirmación.
- **Gráficas y estadísticas (`fl_chart`):** evolución diaria, semanal, mensual y total, promedio, mínimo, máximo y distribución respecto al rango configurado.
- **Recordatorios locales:** notificaciones sin internet para medir la glucosa (diarias o por días de la semana) y citas médicas.
- **Informes PDF:** documento profesional con logotipo, resumen estadístico, gráfica de evolución e historial completo listo para guardar, compartir o imprimir.
- **Copias de seguridad locales (JSON):** exportación e importación validada con confirmación antes de sobrescribir datos.

> **Aviso de responsabilidad médica:** GlucoControl es únicamente una herramienta de registro y organización personal. No diagnostica diabetes, no recomienda dosis de insulina ni cambios de medicamentos y no sustituye la consulta médica.

---

## Guía paso a paso para compilar el APK con GitHub Actions (sin Android Studio)

No necesita instalar Android Studio ni Flutter en su computador. GitHub Actions compilará automáticamente el archivo **`GlucoControl.apk`** en la nube de forma gratuita.

### 1. Crear un repositorio en GitHub

1. Inicie sesión en [github.com](https://github.com) (o cree una cuenta gratuita si aún no tiene una).
2. Haga clic en el botón **`+`** (arriba a la derecha) y seleccione **New repository**.
3. En **Repository name**, escriba `GlucoControl`.
4. Puede dejarlo **Private** (privado) o **Public** (público).
5. **No** marque "Add a README file" ni ".gitignore" (este proyecto ya los incluye).
6. Haga clic en **Create repository**.

### 2. Subir el proyecto

Descomprima el archivo `GlucoControl.zip` en una carpeta de su computador y abra una terminal (CMD, PowerShell o Terminal) dentro de la carpeta `glucocontrol`.

Ejecute estos comandos uno por uno (reemplazando `TU_USUARIO` por su usuario de GitHub):

```bash
git init
git add .
git commit -m "Versión inicial completa de GlucoControl"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/GlucoControl.git
git push -u origin main
```

### 3. Configurar la rama `main`

El comando `git branch -M main` anterior ya configura `main` como rama principal. Si en GitHub aparece otra rama por defecto:

1. Vaya a **Settings → Branches** dentro de su repositorio.
2. En **Default branch**, verifique que esté seleccionada **`main`**.

### 4. Ejecutar GitHub Actions

Al hacer `push` a `main`, la compilación comenzará automáticamente. También puede ejecutarla manualmente cuando desee:

1. Abra su repositorio en GitHub y entre a la pestaña **Actions**.
2. En el menú izquierdo, seleccione **Compilar GlucoControl APK**.
3. Haga clic en **Run workflow → Run workflow** (rama `main`).

*(Opcional)* Si desea APKs más livianos separados por arquitectura (`arm64-v8a`, `armeabi-v7a`, `x86_64`), seleccione el workflow **Compilar GlucoControl APK por arquitectura (Split ABI)** y ejecútelo manualmente.

### 5. Revisar el resultado de la compilación

1. Dentro de la pestaña **Actions**, haga clic sobre la ejecución más reciente.
2. Verá el progreso de cada paso: `flutter doctor`, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release` y publicación del Artifact.
3. Cuando todos los pasos aparezcan con un **check verde (✓)**, el APK está listo (suele tardar entre 4 y 7 minutos).

### 6. Descargar `GlucoControl.apk` desde Artifacts

1. En la parte inferior de la página de la ejecución completada, busque la sección **Artifacts**.
2. Haga clic en **`GlucoControl-APK`** para descargar un archivo `.zip`.
3. Descomprima ese `.zip` y encontrará el archivo **`GlucoControl.apk`**.

### 7. Instalar la aplicación en un teléfono Android

1. Copie **`GlucoControl.apk`** a su teléfono Android (por cable USB, WhatsApp, Google Drive o correo).
2. Abra el archivo desde el gestor de archivos del teléfono.
3. Si Android muestra un aviso de seguridad, toque **Configuración** y active **Permitir desde esta fuente** (instalar aplicaciones desconocidas).
4. Toque **Instalar** y luego **Abrir**.
5. Al crear su primer recordatorio, acepte el permiso de **Notificaciones** para que los avisos funcionen correctamente.

> **Nota sobre la firma del APK:** Si no ha configurado los GitHub Secrets de firma (paso 9), el workflow genera una APK release totalmente instalable utilizando la configuración de firma de desarrollo predeterminada (sin firma de distribución propia). Es completamente funcional para uso familiar, aunque Android puede mostrar un aviso de Play Protect indicando que el desarrollador no está verificado; basta con elegir **Instalar de todas formas**.

### 8. Actualizar la aplicación en el futuro

1. Realice los cambios deseados en el código y aumente el número de versión en `pubspec.yaml` (por ejemplo, de `1.0.0+1` a `1.0.1+2`).
2. Suba los cambios a `main`:
   ```bash
   git add .
   git commit -m "Actualización de GlucoControl"
   git push origin main
   ```
3. Descargue el nuevo `GlucoControl.apk` desde **Actions → Artifacts** e instálelo sobre la versión anterior (si usa la misma firma, conservará todos los datos locales; de todas formas, se recomienda hacer una copia de seguridad JSON antes de actualizar).

### 9. Configurar la firma de producción (opcional, recomendado para actualizaciones)

Para firmar el APK con su propio certificado privado **sin subir nunca contraseñas ni archivos `.jks` al repositorio**:

1. Genere su archivo de firma (`upload-keystore.jks`) en su computador con Java (`keytool`):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias glucocontrol
   ```
2. Convierta el archivo `.jks` a texto Base64:
   - **Linux / macOS:** `base64 -w 0 upload-keystore.jks` (en macOS: `base64 -i upload-keystore.jks`)
   - **Windows (PowerShell):** `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))`
3. En GitHub, vaya a su repositorio → **Settings → Secrets and variables → Actions → New repository secret** y cree exactamente estos 4 secretos:
   - `KEYSTORE_BASE64`: el texto Base64 generado en el paso anterior.
   - `KEYSTORE_PASSWORD`: la contraseña del keystore.
   - `KEY_ALIAS`: el alias elegido (por ejemplo `glucocontrol`).
   - `KEY_PASSWORD`: la contraseña de la clave.
4. Guarde una copia segura de `upload-keystore.jks` y sus contraseñas fuera del repositorio. A partir de la siguiente ejecución, GitHub Actions firmará automáticamente `GlucoControl.apk` con su certificado de producción.
