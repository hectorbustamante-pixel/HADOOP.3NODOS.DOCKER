# Laboratorio Hadoop 3 Nodos - Docker WSL

Cluster HDFS con NameNode + 3 DataNodes + YARN sobre Docker.
Tutorial original: UEES - Apache Hadoop con Docker en WSL Ubuntu.

---

## Arquitectura

```
┌──────────────────────────────────────────────────────┐
│                    Docker Network                     │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │DataNode 1│  │DataNode 2│  │DataNode 3│           │
│  │ :9864    │  │ :9865    │  │ :9866    │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │              │              │                 │
│       └──────────────┼──────────────┘                 │
│                      │                                │
│               ┌──────┴──────┐                         │
│               │  NameNode   │                         │
│               │   :9870     │                         │
│               └──────┬──────┘                         │
│                      │                                │
│  ┌──────────────┐    │    ┌──────────────┐           │
│  │NodeManager 1 │    │    │NodeManager 2 │  ...      │
│  └──────┬───────┘    │    └──────┬───────┘           │
│         └────────────┼───────────┘                   │
│               ┌──────┴──────┐                         │
│               │ResourceMgr  │                         │
│               │   :8088     │                         │
│               └─────────────┘                         │
└──────────────────────────────────────────────────────┘
```

| Servicio         | Contenedor       | Puerto | Panel Web              |
|------------------|------------------|--------|------------------------|
| NameNode         | namenode         | 9870   | http://localhost:9870  |
| DataNode 1       | datanode1        | 9864   | —                      |
| DataNode 2       | datanode2        | 9865   | —                      |
| DataNode 3       | datanode3        | 9866   | —                      |
| ResourceManager  | resourcemanager  | 8088   | http://localhost:8088  |
| NodeManager 1    | nodemanager1     | —      | —                      |
| NodeManager 2    | nodemanager2     | —      | —                      |
| NodeManager 3    | nodemanager3     | —      | —                      |

---

## Requisitos previos

Antes de empezar, necesitas:

1. **Windows 10/11** con WSL2 instalado. Si no lo tienes, abre PowerShell como Administrador y ejecuta:
   ```powershell
   wsl --install -d Ubuntu
   ```
   Reinicia tu PC y abre Ubuntu desde el menú Inicio. Crea tu usuario y contraseña.

2. **Mínimo 6 GB de RAM disponible** en tu máquina (el cluster consume ~4-5 GB).

> **Nota:** Todo el resto de la instalacion se hace desde la terminal de Ubuntu (WSL). No necesitas nada en Windows.

---

## Paso a paso: Instalacion completa desde cero

### Paso 1: Actualizar el sistema

Abre tu terminal de Ubuntu (WSL) y ejecuta:

```bash
sudo apt-get update
```

Esto actualiza la lista de paquetes disponibles. No instala nada aun, solo refresca el indice.

---

### Paso 2: Instalar Docker Engine y Docker Compose

```bash
sudo apt-get install -y docker.io docker-compose-v2
```

Esto instala:
- `docker.io` → Docker Engine (el motor de contenedores)
- `docker-compose-v2` → Docker Compose (orquestador de multiples contenedores)

La instalacion toma 1-2 minutos. Veras muchas lineas de progreso, es normal.

**Verifica que quedo instalado:**

```bash
docker --version
docker compose version
```

Deberias ver algo como:
```
Docker version 29.1.3
Docker Compose version 2.40.3
```

---

### Paso 3: Dar permisos a tu usuario

Por defecto, solo root puede usar Docker. Para usar Docker sin `sudo`:

```bash
sudo usermod -aG docker $USER
```

Este comando agrega tu usuario al grupo `docker`.

**IMPORTANTE:** Cierra la terminal de Ubuntu y vuelve a abrirla para que el cambio tenga efecto. Si no lo haces, Docker te dara error de permisos.

Despues de reabrir la terminal, verifica que tienes acceso:

```bash
docker info
```

Si ves informacion del daemon (version, storage, etc.) sin errores, esta listo.

> **Si docker info falla con "permission denied":** Ejecuta `sudo chmod 666 /var/run/docker.sock` como solucion temporal y vuelve a intentar.

---

### Paso 4: Clonar este repositorio

```bash
cd ~
git clone https://github.com/PaulMoralesG/hadoop-3nodos-docker.git
cd hadoop-3nodos-docker
```

Esto descarga todo el proyecto a tu carpeta personal (`~`).

Verifica que tienes todos los archivos:

```bash
ls -la
```

Deberias ver: `README.md`, `compose.yaml`, `Dockerfile`, y una carpeta `config/`.

---

### Paso 5: Construir la imagen de Hadoop

```bash
docker compose build
```

Este comando:
1. Descarga la imagen base `apache/hadoop:3.5.0` (~800 MB, solo la primera vez)
2. Copia nuestras configuraciones personalizadas
3. Crea la imagen local `hadoop-lab:3.5.0`

La primera vez toma 3-5 minutos (depende de tu internet). Las siguientes veces es instantaneo.

---

### Paso 6: Levantar el cluster

```bash
docker compose up -d
```

La bandera `-d` significa "detached" (en segundo plano). Los contenedores se inician en este orden:

1. `namenode` — formatea HDFS si es primera vez, luego arranca
2. `datanode1`, `datanode2`, `datanode3` — esperan al NameNode y se registran
3. `resourcemanager` — arranca YARN
4. `nodemanager1`, `nodemanager2`, `nodemanager3` — se registran con el ResourceManager

Veras los nombres de los contenedores aparecer en verde. Eso significa que arrancaron.

---

### Paso 7: Esperar los heartbeats

Los DataNodes necesitan ~30 segundos para registrarse con el NameNode. Mientras esperas, puedes ver los logs:

```bash
docker compose logs -f namenode
```

Presiona `Ctrl+C` para salir de los logs cuando veas mensajes de registro de DataNodes.

---

### Paso 8: Verificar el cluster

```bash
docker compose exec namenode hdfs dfsadmin -report
```

**Resultado esperado:** `Live datanodes (3)` — los 3 DataNodes estan vivos.

```bash
docker compose exec resourcemanager yarn node -list
```

**Resultado esperado:** 3 nodos con estado `RUNNING`.

Tambien puedes abrir los paneles web en tu navegador:
- **NameNode:** http://localhost:9870 → pestaña "Datanodes" debe mostrar 3 nodos
- **ResourceManager:** http://localhost:8088 → pestaña "Nodes" debe mostrar 3 nodos

---

## Demostraciones del laboratorio

### Demo 1: Replicacion HDFS (factor 3)

El cluster esta configurado con factor de replicacion 3. Cada archivo que subas se copia automaticamente en los 3 DataNodes.

```bash
# Crear un archivo de prueba
docker compose exec namenode bash -lc "printf 'replicacion hdfs\n' > /tmp/replica.txt"

# Crear directorio en HDFS
docker compose exec namenode hdfs dfs -mkdir -p /curso/replicacion

# Subir el archivo a HDFS
docker compose exec namenode hdfs dfs -put -f /tmp/replica.txt /curso/replicacion/

# Verificar ubicacion de los bloques (debe mostrar 3 DataNodes)
docker compose exec namenode hdfs fsck /curso/replicacion/replica.txt -files -blocks -locations

# Ver factor de replicacion
docker compose exec namenode hdfs dfs -stat '%r %n' /curso/replicacion/replica.txt
```

**Resultado esperado:** `3 replica.txt` y ubicaciones en datanode1, datanode2, datanode3.

---

### Demo 2: Simular caida de un DataNode

```bash
# Detener datanode2
docker compose stop datanode2

# Esperar a que el NameNode lo detecte (heartbeat cada 1s + recheck 5s)
sleep 35

# Verificar estado (debe mostrar 1 DataNode muerto)
docker compose exec namenode hdfs dfsadmin -report

# Verificar replicacion (Live_repl debe bajar de 3 a 2)
docker compose exec namenode hdfs fsck /curso/replicacion/replica.txt -files -blocks -locations
```

**Resultado esperado:** 1 DataNode muerto, bloque subreplicado (`Live_repl=2`).

---

### Demo 3: Recuperar el DataNode

```bash
# Reiniciar datanode2
docker compose start datanode2

# Esperar reconexion
sleep 35

# Verificar que volvio (3 DataNodes vivos)
docker compose exec namenode hdfs dfsadmin -report

# Verificar replicacion restaurada (Live_repl=3)
docker compose exec namenode hdfs fsck /curso/replicacion/replica.txt -files -blocks -locations
```

**Resultado esperado:** 3 DataNodes vivos, `Live_repl=3`.

---

## Comandos utiles de administracion

| Comando | Que hace |
|---------|----------|
| `docker compose up -d` | Levantar el cluster |
| `docker compose ps` | Ver estado de los contenedores |
| `docker compose logs -f [servicio]` | Ver logs en tiempo real |
| `docker compose stop` | Detener sin borrar datos |
| `docker compose start` | Reanudar cluster detenido |
| `docker compose restart` | Reiniciar todo |
| `docker compose down` | Borrar contenedores y red (datos persisten) |
| `docker compose down -v` | **BORRAR TODO** incluyendo datos HDFS |

---

## Troubleshooting: Problemas comunes y soluciones

### "docker: command not found"
Docker no esta instalado. Vuelve al Paso 2.

### "permission denied" al ejecutar docker
Tu usuario no esta en el grupo docker. Cierra y reabre la terminal de Ubuntu. Si persiste, ejecuta:
```bash
sudo chmod 666 /var/run/docker.sock
```

### "Cannot connect to the Docker daemon"
El servicio de Docker no esta corriendo. En WSL ejecuta:
```bash
sudo service docker start
```

### Los DataNodes no aparecen en el report
Espera 30-40 segundos. Si aun no aparecen, revisa los logs:
```bash
docker compose logs datanode1
```
Busca errores de conexion al NameNode.

### El NameNode no arranca
Posiblemente el directorio de datos esta corrupto. Borra todo y vuelve a empezar:
```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

### "No space left on device"
Docker se quedo sin espacio en disco. Limpia imagenes y contenedores no usados:
```bash
docker system prune -a
```

---

## Paneles web

| Panel | URL | Que muestra |
|-------|-----|-------------|
| NameNode | http://localhost:9870 | Estado de HDFS, DataNodes, bloques |
| ResourceManager | http://localhost:8088 | Estado de YARN, aplicaciones, nodos |

---

Laboratorio academico — UEES. Entorno de aprendizaje sin seguridad de produccion.
