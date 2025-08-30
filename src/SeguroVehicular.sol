// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Para manejar stablecoins como USDC
import "@openzeppelin/contracts/access/Ownable.sol"; // Para gestión de propiedad del contrato
import "@openzeppelin/contracts/utils/math/Math.sol"; // Para operaciones matemáticas seguras

// Definimos la interfaz para un Oráculo de Siniestros.
// Este oráculo es un contrato externo que nos dirá si un siniestro ocurrió o no.
interface ISiniestroOracle {
    function getSiniestroStatus(uint256 _vehicleId) external view returns (bool, uint256); // (isTotalLoss, valueInUSD)
}

contract SeguroVehicular is Ownable {
    using Math for uint256;

    // --- Variables de Estado ---

    // Mapeo de IDs de vehículos a sus pólizas.
    struct Policy {
        address insuredFleet;      // La dirección de la empresa asegurada
        uint256 vehicleId;         // Identificador único del vehículo
        uint256 insuredValueUSD;   // Valor asegurado del vehículo en USD (ej. 10000 para $10,000)
        uint256 premiumAmountUSD;  // Cantidad de la prima anual en USD
        uint256 startDate;         // Fecha de inicio de la póliza (timestamp)
        uint256 endDate;           // Fecha de fin de la póliza (timestamp)
        bool isActive;             // ¿La póliza está activa?
        bool claimProcessed;       // ¿Ya se ha procesado un reclamo para esta póliza?
    }

    mapping(uint256 => Policy) public policies; // vehicleId => Policy
    uint256 public nextPolicyId = 1; // Para generar IDs únicos de pólizas, aunque usamos vehicleId como clave aquí

    // Dirección del token stablecoin (ej. USDC) que usaremos para pagos.
    IERC20 public stablecoin;

    // Dirección del contrato del Oráculo de Siniestros.
    ISiniestroOracle public siniestroOracle;

    // --- Eventos (para que otras aplicaciones puedan saber qué está pasando) ---
    event PolicyIssued(uint256 indexed vehicleId, address indexed insuredFleet, uint256 insuredValue);
    event PremiumPaid(uint256 indexed vehicleId, address indexed payer, uint256 amount);
    event ClaimProcessed(uint256 indexed vehicleId, address indexed beneficiary, uint256 payoutAmount);
    event OracleSet(address indexed newOracle);

    // --- Constructor ---
    // Se ejecuta una vez cuando el contrato se despliega.
    constructor(address _stablecoinAddress, address _siniestroOracleAddress) Ownable(msg.sender) {
    stablecoin = IERC20(_stablecoinAddress);
    siniestroOracle = ISiniestroOracle(_siniestroOracleAddress);
}


    // --- Funciones para la Gestión del Contrato (solo para el propietario/administrador) ---

    // Permitir al propietario cambiar la dirección del oráculo si es necesario.
    function setSiniestroOracle(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "Direccion del oraculo no puede ser cero.");
        siniestroOracle = ISiniestroOracle(_newOracleAddress);
        emit OracleSet(_newOracleAddress);
    }

    // --- Funciones para Empresas Aseguradas ---

    // Función para emitir una nueva póliza para un vehículo.
    // Solo el propietario del contrato o un rol autorizado (no implementado aquí) debería poder hacer esto.
    // En un sistema real, esto implicaría un proceso de cotización y aceptación.
    function issuePolicy(
        uint256 _vehicleId,
        uint256 _insuredValueUSD,
        uint256 _premiumAmountUSD,
        uint256 _policyDurationDays // Duración de la póliza en días
    ) public onlyOwner { // por ahora, solo el propietario puede emitir pólizas.
        require(policies[_vehicleId].isActive == false, "Ya existe una poliza activa para este vehiculo.");
        require(_insuredValueUSD > 0, "Valor asegurado debe ser mayor que cero.");
        require(_premiumAmountUSD > 0, "Monto de la prima debe ser mayor que cero.");
        require(_policyDurationDays > 0, "Duracion de la poliza debe ser mayor que cero.");

        policies[_vehicleId] = Policy({
            insuredFleet: msg.sender, // La empresa que lo solicita (simplificado, en real sería un parámetro)
            vehicleId: _vehicleId,
            insuredValueUSD: _insuredValueUSD,
            premiumAmountUSD: _premiumAmountUSD,
            startDate: block.timestamp,
            endDate: block.timestamp + (_policyDurationDays * 1 days), // 1 day = 24 * 60 * 60 seconds
            isActive: true,
            claimProcessed: false
        });

        emit PolicyIssued(_vehicleId, msg.sender, _insuredValueUSD);
    }

    // Función para que la empresa pague la prima.
    // Asume que la empresa ya ha aprobado el token stablecoin para que este contrato lo gaste.
    function payPremium(uint256 _vehicleId) public {
        Policy storage policy = policies[_vehicleId];
        require(policy.isActive, "La poliza no esta activa.");
        require(block.timestamp <= policy.endDate, "La poliza ha expirado.");

        // Transferir la prima desde la empresa al contrato del seguro.
        // stablecoin.transferFrom(msg.sender, address(this), policy.premiumAmountUSD);
        // NOTA: En un caso real, el monto aquí debe ser el valor REAL de la prima,
        // y el msg.sender debe ser la dirección de la cuenta que está pagando, no necesariamente la flota.
        // Aquí simplificamos que la flota paga su propia prima, y se espera un 'approve' previo.
        // Para que esto funcione, msg.sender debe haber llamado antes a stablecoin.approve(address(this), amount);
        stablecoin.transferFrom(msg.sender, address(this), policy.premiumAmountUSD);

        emit PremiumPaid(_vehicleId, msg.sender, policy.premiumAmountUSD);
    }


    // Función clave: procesar un reclamo por siniestro total.
    // Esto es "paramétrico": se basa en datos externos del oráculo, no en una evaluación manual.
    function processTotalLossClaim(uint256 _vehicleId) public {
    Policy storage policy = policies[_vehicleId];
    require(policy.isActive, "La poliza no esta activa o no existe.");
    require(block.timestamp <= policy.endDate, "La poliza ha expirado.");
    require(!policy.claimProcessed, "El reclamo ya fue procesado.");

    // Solo recuperar "isTotalLoss" (ignorar "lossValueUSD" si no se utiliza).
    (bool isTotalLoss, ) = siniestroOracle.getSiniestroStatus(_vehicleId);
    require(isTotalLoss, "No se detecto perdida total.");

    uint256 payoutAmount = policy.insuredValueUSD;
    policy.claimProcessed = true;
    policy.isActive = false;

    stablecoin.transfer(policy.insuredFleet, payoutAmount);
    emit ClaimProcessed(_vehicleId, policy.insuredFleet, payoutAmount);
}

    // --- Funciones de Utilidad (para obtener información) ---

    // Obtener el saldo de stablecoins del contrato (para propósitos de auditoría/solvencia).
    function getContractStablecoinBalance() public view returns (uint256) {
        return stablecoin.balanceOf(address(this));
    }

    // Obtener información de una póliza específica.
    function getPolicyDetails(uint256 _vehicleId) public view returns (
        address insuredFleet,
        uint256 vehicleId,
        uint256 insuredValueUSD,
        uint256 premiumAmountUSD,
        uint256 startDate,
        uint256 endDate,
        bool isActive,
        bool claimProcessed
    ) {
        Policy storage policy = policies[_vehicleId];
        return (
            policy.insuredFleet,
            policy.vehicleId,
            policy.insuredValueUSD,
            policy.premiumAmountUSD,
            policy.startDate,
            policy.endDate,
            policy.isActive,
            policy.claimProcessed
        );
    }

    // Función de emergencia para recuperar fondos atrapados (solo el propietario).
    function withdrawStuckTokens(address _tokenAddress) public onlyOwner {
        IERC20 stuckToken = IERC20(_tokenAddress);
        stuckToken.transfer(owner(), stuckToken.balanceOf(address(this)));
    }
}
