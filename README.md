# Seguro Vehicular Fleet

Este repositorio contiene el contrato inteligente `SeguroVehicularFleet`, diseñado para gestionar pólizas de seguro de vehículos para flotas de manera programática en la blockchain. Utiliza tokens ERC-20 (como stablecoins) para pagos de primas y desembolsos de reclamos, y se integra con un oráculo externo para determinar el estado de los siniestros de forma paramétrica.

## Tabla de Contenidos

- [Seguro Vehicular Fleet](#seguro-vehicular-fleet)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Descripción del Contrato](#descripción-del-contrato)
  - [Características Principales](#características-principales)
  - [Tecnologías Usadas](#tecnologías-usadas)
  - [Despliegue](#despliegue)
    - [Prerequisitos](#prerequisitos)
    - [Instalación](#instalación)
    - [Configuración](#configuración)
    - [Despliegue en Redes Locales/Testnets](#despliegue-en-redes-localestestnets)
  - [Funcionalidades del Contrato](#funcionalidades-del-contrato)
    - [Constructor](#constructor)
    - [Funciones del Propietario](#funciones-del-propietario)
    - [Funciones para Empresas Aseguradas](#funciones-para-empresas-aseguradas)
    - [Funciones de Utilidad](#funciones-de-utilidad)
  - [Eventos](#eventos)
  - [Consideraciones de Seguridad](#consideraciones-de-seguridad)
  - [Auditorías](#auditorías)
  - [Licencia](#licencia)
  - [Contacto](#contacto)

## Descripción del Contrato

`SeguroVehicularFleet` es un contrato inteligente que permite a las empresas de flotas asegurar sus vehículos de manera descentralizada. El contrato automatiza la emisión de pólizas, el pago de primas y el procesamiento de reclamos por siniestro total, basándose en la información proporcionada por un oráculo externo de siniestros. La lógica está diseñada para ser paramétrica, lo que significa que los pagos de reclamos se disparan automáticamente una vez que el oráculo confirma un siniestro total.

## Características Principales

*   **Gestión de Pólizas:** Emisión y seguimiento de pólizas para vehículos individuales dentro de una flota.
*   **Pagos de Prima en Stablecoin:** Las primas se pagan utilizando un token ERC-20 configurable (e.g., USDC).
*   **Oráculo de Siniestros Paramétrico:** Se integra con un contrato `ISiniestroOracle` externo para determinar si un vehículo ha sufrido un siniestro total.
*   **Procesamiento Automatizado de Reclamos:** Los pagos por siniestro total se desembolsan automáticamente a la flota asegurada una vez que el oráculo confirma el evento y la póliza es válida.
*   **Control de Acceso (Ownable):** Ciertas funciones administrativas (como establecer el oráculo o emitir pólizas) están restringidas al propietario del contrato.
*   **Seguridad:** Utiliza librerías de OpenZeppelin para operaciones matemáticas seguras y gestión de propiedad.

## Tecnologías Usadas

*   **Solidity:** Lenguaje de programación para contratos inteligentes.
*   **Hardhat/Foundry (Asumido):** Entorno de desarrollo, compilación y despliegue para Ethereum. (El script está preparado para Foundry).
*   **OpenZeppelin Contracts:** Librerías estándar y auditadas para componentes comunes de contratos inteligentes (ERC-20, Ownable, Math).

## Despliegue

### Prerequisitos

Antes de desplegar, asegúrate de tener instalado:

*   **Node.js** y **npm** (si usas Hardhat) o **Rust** y **cargo** (si usas Foundry).
*   **Foundry:** Si estás usando Foundry, sigue las instrucciones de instalación en su [documentación oficial](https://book.getfoundry.sh/getting-started/installation).

### Instalación

Clona el repositorio y navega al directorio del proyecto:

```bash
git clone <URL_DEL_REPOSITORIO>
cd SeguroVehicularFleet
