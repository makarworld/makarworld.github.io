const contractAddress = "0xdE07D525d4d059F55FBFD28350a9E8A3e2eaC0dE";
const contractABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			}
		],
		"name": "OwnershipTransferRequested",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			}
		],
		"name": "OwnershipTransferred",
		"type": "event"
	},
	{
		"inputs": [],
		"name": "acceptOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			}
		],
		"name": "transferOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]

const provider = new ethers.providers.Web3Provider(window.ethereum, 97)//ChainID 97 BNBtestnet
let signer;
let contract;


const event = "PlayGame";

provider.send("eth_requestAccounts", []).then(()=>{
    provider.listAccounts().then( (accounts) => {
        signer = provider.getSigner(accounts[0]); //account in metamask
        
        contract = new ethers.Contract(
            contractAddress,
            contractABI,
            signer
        )
     
    }
    )
}
)

async function playGame(_option, random_type){
    let amountInEth = document.getElementById("amountInEth").value;
    let amountInWei = ethers.utils.parseEther(amountInEth.toString())
    console.log(amountInWei);
    
	if (random_type == "pseudo") {
    	resultOfCoinFlip = await contract.play_bot_pseudo_bnb(_option, {value: amountInWei});
	} else {
    	resultOfCoinFlip = await contract.play_bot_real_bnb(_option, {value: amountInWei});
	}
    const res = await resultOfCoinFlip.wait();
    console.log(res);
    //console.log( await res.events[0].args.player.toString());

    let queryResult =  await contract.queryFilter('PlayGame', await provider.getBlockNumber() - 10000, await provider.getBlockNumber());
    let queryResultRecent = queryResult[queryResult.length-1]
    //console.log(queryResult[queryResult.length-1].args);

    let amount = await queryResultRecent.args.amount.toString();
    let player = await queryResultRecent.args.player.toString();
    let option = await queryResultRecent.args.option.toString();
    let result = await queryResultRecent.args.result.toString();

    let resultLogs = `
    stake amount: ${ethers.utils.formatEther(amount.toString())} BNB, 
    player: ${player}, 
    player chose: ${option == 0 ? "ROCK": option == 1 ? "PAPER": "SCISSORS"}, 
    result: ${result == 0 ? "WIN 🎉": result == 1 ? "LOSE 😥": "DRAW 🤝"}`;
    console.log(resultLogs);

    let resultLog = document.getElementById("resultLog");
    resultLog.innerText = resultLogs;

    handleEvent();
}

async function handleEvent(){

    let queryResult =  await contract.queryFilter('CoinFlipped', await provider.getBlockNumber() - 10000, await provider.getBlockNumber());
    let queryResultRecent = queryResult[queryResult.length-1]
    let amount = await queryResultRecent.args.amount.toString();
    let player = await queryResultRecent.args.player.toString();
    let option = await queryResultRecent.args.option.toString();
    let result = await queryResultRecent.args.result.toString();

    let resultLogs = `
    stake amount: ${ethers.utils.formatEther(amount.toString())} BNB, 
    player: ${player}, 
    player chose: ${option == 0 ? "ROCK": option == 1 ? "PAPER": "SCISSORS"}, 
    result: ${result == 0 ? "WIN 🎉": result == 1 ? "LOSE 😥": "DRAW 🤝"}`;
    console.log(resultLogs);

    let resultLog = document.getElementById("resultLog");
    resultLog.innerText = resultLogs;
}
