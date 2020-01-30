pragma solidity >=0.4.0 <0.6.0;

// - Participantes
// - escolhidos via votacao

// Rodada

// - Seleciona um lider (via jogo)
// - Lider
// -- indica alguem para o paredao
// -- imune ao paredao
// - Outros
// -- votam em quem vai ao paredao
// -- mais votado vai para o paredao
// -- se empatado, o voto de minerva e do lider?

contract BBB {
    address payable public dono = msg.sender;

    mapping (address => bytes32) ids;
    mapping (bytes32 => string) nomes;
    mapping (address => address) votos_fora;
    mapping (address => uint8) votos_fora_contados;
    address[] votantes;
    uint total_de_votos = 0;
    uint maior_contagem_de_votos = 0;
    address mais_votado;

    address public lider;
    address[] public paredao;
    address[] eliminados;

    enum Estado { Fechada, EmAndamento, Finalizada }
    
    uint8 rodada_atual;
    Estado rodada_estado;

    bool lider_emparedou_alguem;
    address[] public vencedores;

    modifier rodada_em_andamento { require (rodada_estado == Estado.EmAndamento, "A rodada ainda está fechada."); _; }
    modifier rodada_fechada      { require (rodada_estado != Estado.EmAndamento, "A rodada está aberta."); _; }

    modifier apenas_dono  { require(msg.sender == dono, "Apenas o dono do contrato pode fazer isso"); _; }
    modifier apenas_lider { require(lider == dono,      "Apenas o lider pode fazer isso!"); _; }
    modifier exceto_lider { require(lider != dono,      "O lider não pode fazer isso!"); _; }


    function cadastrar (string memory _nome) public {
        bytes32 id = keccak256(abi.encodePacked(_nome));
        ids[msg.sender] = id;
        nomes[id] = _nome;
    }
    
    function identificar (address _addresss) view public returns(string memory _nome, bytes32 _id) {
        bytes32 id = ids[_addresss];
        return (nomes[id], id);
    }

    function abre_nova_rodada () public apenas_dono() rodada_fechada() returns(uint8 _rodada_atual) {
        require (vencedores.length == rodada_atual, "Não existe vencedor da rodada atual");
        // limpar valores transientes
        lider_emparedou_alguem = false;
        rodada_estado = Estado.EmAndamento;
        rodada_atual = rodada_atual + 1;
        delete votantes;
        for(uint8 i=0; i <= total_de_votos; i++){
            address votante = votantes[i];
            votos_fora[votante] = address(0x0);            
        }
        total_de_votos = 0;
        maior_contagem_de_votos = 0;
        return rodada_atual;
    }

    function finaliza_rodada () public apenas_dono() rodada_em_andamento() returns(uint8 _rodada_atual) {
        // ve quem foi mais votado
        paredao.push(mais_votado);

        // calcular vencedores e perdedores
        rodada_estado = Estado.Finalizada;
        // vencedor?
        return rodada_atual;
    }

    function designa_lider (address _novo_lider) public apenas_dono() {
        require (_novo_lider != dono, "O dono não pode participar");
        lider = _novo_lider;
        // TODO recompensa lider
    }

    function manda_ao_paredao (address _emparedado) public apenas_lider() {
        require (_emparedado != lider, "O lider não pode ser emparedado!");
        require (!lider_emparedou_alguem);
        lider_emparedou_alguem = true;
        paredao.push(_emparedado);
    }

    function manda_outro_ao_paredao (address _emparedado) public apenas_dono() {
        require (_emparedado != lider, "O lider não pode ser emparedado!");
        require (lider_emparedou_alguem);
        paredao.push(_emparedado);        
    }

    function vota_fora (address _emparedado) public exceto_lider() {
        require (_emparedado != msg.sender, "Você não pode votar em si próprio!");
        require (lider_emparedou_alguem);
        require (votos_fora[msg.sender] == address(0x0), "Você já votou nessa rodada!");
        require (ids[msg.sender] != bytes32(0x0), "Você não está cadastrado!");
        
        votos_fora[msg.sender] = _emparedado;
        votos_fora_contados[_emparedado] += 1;
        if (votos_fora_contados[_emparedado] > maior_contagem_de_votos) {
            mais_votado = _emparedado;
            maior_contagem_de_votos = votos_fora_contados[_emparedado];
        }
        total_de_votos += 1;
        votantes.push(msg.sender);
    }
}
