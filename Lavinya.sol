// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 1 ETH = 500 LAVYA
// 1 LAVYA = 0.002 ETH

contract LavinyaToken {
    
    string public name = "Lavinya";
    string public symbol = "LAVYA";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000 * 10 ** uint256(decimals);

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TokensBought(address indexed buyer, uint256 amount, uint256 ethSpent);
    event TokensSold(address indexed seller, uint256 amount, uint256 ethReceived);

    constructor() payable {
        // Dividir o total entre o contrato e o deployer
        uint256 contractTokens = totalSupply / 2;
        uint256 ownerTokens = totalSupply - contractTokens;

        balanceOf[address(this)] = contractTokens;
        balanceOf[msg.sender] = ownerTokens;

        emit Transfer(address(0), address(this), contractTokens);
        emit Transfer(address(0), msg.sender, ownerTokens);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Saldo insuficiente");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Envie ETH para comprar tokens");

        uint256 tokensToBuy = (msg.value * 500 * (10 ** uint256(decimals))) / 1 ether;
        require(tokensToBuy > 0, "Valor muito pequeno para gerar tokens");
        require(balanceOf[address(this)] >= tokensToBuy, "Contrato sem tokens suficientes");

        balanceOf[address(this)] -= tokensToBuy;
        balanceOf[msg.sender] += tokensToBuy;

        emit Transfer(address(this), msg.sender, tokensToBuy);
        emit TokensBought(msg.sender, tokensToBuy, msg.value);
    }

    function sellTokens(uint256 _amount) public {
        require(_amount > 0, "Valor deve ser maior que zero");
        require(balanceOf[msg.sender] >= _amount, "Sem tokens suficientes");

        uint256 ethToReturn = (_amount * 1 ether) / (500 * (10 ** uint256(decimals)));
        require(ethToReturn > 0, "Valor muito pequeno para gerar retorno em ETH");
        require(address(this).balance >= ethToReturn, "Contrato sem ETH suficiente");

        balanceOf[msg.sender] -= _amount;
        balanceOf[address(this)] += _amount;

        emit Transfer(msg.sender, address(this), _amount);
        emit TokensSold(msg.sender, _amount, ethToReturn);

        // Enviar ETH
        (bool sent, ) = payable(msg.sender).call{value: ethToReturn}("");
        require(sent, "Falha ao enviar ETH");
    }

    // Permite que o contrato receba ETH
    receive() external payable {}

    // Fallback para evitar travamentos caso chamem uma função inexistente com dados
    fallback() external payable {}
}
