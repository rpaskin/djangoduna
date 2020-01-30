pragma solidity >=0.4.0 <0.6.0;

contract BBBSimple {
    address public dono = msg.sender;

    mapping (address => uint8) voto;
    mapping (address => bool) votou;
    mapping (uint8 => uint8) contagem;

    bool rodada_aberta = false;
    uint8 mais_votado = 0;
    uint8 maior_contagem_de_votos = 0;

    uint8 total_de_votos = 0;

    modifier rodada_esta_aberta { require (rodada_aberta, "A rodada ainda está fechada."); _; }
    modifier rodada_esta_fechada { require (!rodada_aberta, "A rodada está aberta."); _; }

    modifier apenas_dono  { require(msg.sender == dono, "Apenas o dono do contrato pode fazer isso"); _; }

    function abre_rodada () public apenas_dono() {
        rodada_aberta = true;        
    }

    function finaliza_rodada () public apenas_dono() rodada_esta_aberta() {
        rodada_aberta = false;        
    }

    function vota_fora (uint8 _para_sair) public rodada_esta_aberta() {
        require (!votou[msg.sender], "Você já votou");
        require (_para_sair > 0, "Tem que ser maior que zero");

        voto[msg.sender] = _para_sair;
        votou[msg.sender] = true;

        contagem[_para_sair] += 1;
        if (contagem[_para_sair] > maior_contagem_de_votos) {
            mais_votado = _para_sair;
            maior_contagem_de_votos = contagem[_para_sair];
        }
        total_de_votos += 1;
    }
}
