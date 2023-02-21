// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./imports/VRFCoordinatorV2Interface.sol";
import "./imports/VRFConsumerBaseV2.sol";
import "./imports/ConfirmedOwner.sol";


contract RockPaperScissorsV1 is VRFConsumerBaseV2, ConfirmedOwner  {
    
    // -===============> Part 1 <===============-
    // # Init main vars and structs

    // enums for Game
    enum GameResult { Win, Lose, Draw }
    enum GameType { 
        BNBBotPseudo, BNBBotReal, BNBP2P, 
        ERC20BotPseudo, ERC20BotReal, ERC20P2P
    }
    enum GameOption { Rock, Paper, Scissors }

    // event to track result of games
    event PlayGame(
        address player,            // first player and game creator
        address opponent,          // address of second player (if game with bot -> contact address)
        GameType gametype,         // type
        uint256 amount,            // bet
        GameOption option,         // creator option
        GameOption option2,        // second player option
        GameResult result          // result of game
    ); 

    // Game struct for play with real random
    struct UserGame {
        address player; // address of user, which requested random
        GameType gametype; // option of user
        GameOption option; // option of user
        uint256 bet; // User bet (in BNB or in ERC20)
        address tokenAddress; // Token address for bet (only if type ERC20)
    }

    // -===============> END Part 1 <===============-





    // -===============> Part 2 <===============-
    // # Owner feature



    // Function to withdraw all Ether from this contract.
    function withdraw() public onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // -===============> Part 2.1 <=================-
    // # deposit BNB and ERC20 tokens

    // deposit BNB func
    function deposit_bnb() public payable {}

    // deposit erc20 token not need a function.
    // just send it with .transfer() func in needed contract.


    // -===============> END Part 2 <===============-





    // -===============> Part 3 <===============-
    // # Init a VRF contract, create vars

    // mapping for a storage game with real random (for use it in fallback)
    mapping(uint256 => UserGame) public user_requests; 
    /* requestId --> userAdress */

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;


    // Constructor with initialize VRF and owner
    // FOR BSC TESTNET ONLY

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x6A2AAd07396B36Fe02a22b33cf443582f682c82f)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x6A2AAd07396B36Fe02a22b33cf443582f682c82f
        );
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        internal
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    // ! Callback function used by VRF Coordinator (replaced to game part)

    // -===============> END Part 3 <===============-





    // -===============> Part 4 <===============-
    // # Main game part


    // GAME

    // bets:
    // 1 - stone
    // 2 - paper
    // 3 - scissors
    // ... -> 2 -> 1 -> 0 -> 2 -> ...

    function toOption(uint8 value) private pure returns (GameOption) {
        if (value == 1) {
            return GameOption.Rock;
        } else if (value == 2) {
            return GameOption.Paper;
        } else if (value == 3) {
            return GameOption.Scissors; }
        
        // impossible case
        else {
            // error
            return GameOption.Rock;
        }
    }

    function play(GameOption player1, GameOption player2) private pure returns (GameResult) {
        // if first user used Paper
        if (player1 == GameOption.Paper && player2 == GameOption.Rock) {
            return GameResult.Win;
        } else if (player1 == GameOption.Paper && player2 == GameOption.Paper) {
            return GameResult.Draw;
        } else if (player1 == GameOption.Paper && player2 == GameOption.Scissors) {
            return GameResult.Lose;
        

        // if first user used Rock
        } else if (player1 == GameOption.Rock && player2 == GameOption.Rock) {
            return GameResult.Draw;
        } else if (player1 == GameOption.Rock && player2 == GameOption.Paper) {
            return GameResult.Lose;
        } else if (player1 == GameOption.Rock && player2 == GameOption.Scissors) {
            return GameResult.Win;

        // if first user used Scissors
        } else if (player1 == GameOption.Scissors && player2 == GameOption.Rock) {
            return GameResult.Lose;
        } else if (player1 == GameOption.Scissors && player2 == GameOption.Paper) {
            return GameResult.Win;
        } else if (player1 == GameOption.Scissors && player2 == GameOption.Scissors) {
            return GameResult.Draw;

        // impossible case
        } else { 
            return GameResult.Lose; 
        }

    }

    function pseudo_random() private view returns (uint8) {
        return uint8(block.timestamp * block.gaslimit % 3);
    }

    function play_bot_pseudo_bnb(uint8 _option) public payable returns (GameResult) {
        require(_option < 3, "Please select option");
        require(msg.value > 0, "Please add your bet");
        require(msg.value*2 <= address(this).balance, "Contract balance is insuffieient ");


        GameOption user_option = toOption(_option);
        GameOption bot_option = toOption(pseudo_random());

        GameResult result = play(user_option, bot_option);

        //If user wins he doubles his stake
        if (result == GameResult.Win) {
            payable(msg.sender).transfer(msg.value*2);
        } else if (result == GameResult.Draw) {
            payable(msg.sender).transfer(msg.value);
        }

        //Emiting event
        emit PlayGame(msg.sender, address(this), GameType.BNBBotPseudo, msg.value, user_option, bot_option, result);

        return result;
    }

    function play_bot_real_bnb(uint8 _option) public payable {
        // check requirements
        require(_option < 3, "Please select option");
        require(msg.value > 0, "Please add your bet");
        require(msg.value*2 <= address(this).balance, "Contract balance is insuffieient ");

        // create request for real random number
        uint256 requestId = requestRandomWords();

        // fill map with created request.
        user_requests[requestId] = UserGame(
            msg.sender,          // userAddress
            GameType.BNBBotReal, // gametype
            toOption(_option),   // option
            msg.value,           // bet
            address(0)           // token address (zero becourse it's not ERC20 game)
        );

        // next game implementation in fallback function .fulfillRandomness()
    }

    // Callback function used by VRF Coordinator (replaced to game part)
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        // get random result 1-3
        uint8 randomResult = uint8((_randomWords[0] % 3) + 1);

        UserGame storage game = user_requests[_requestId];
        GameOption bot_option = toOption(randomResult);        
        GameResult result = play(game.option, bot_option);

        //Emiting event
        emit PlayGame(game.player, address(this), game.gametype, game.bet, game.option, bot_option, result);


        if (game.gametype == GameType.BNBBotReal) {       
            if (result == GameResult.Win) {
                (bool success, ) = payable(game.player).call{value: game.bet*2}("");
                require(success, "Failed to send Ether");
            } else if (result == GameResult.Draw) {
                (bool success, ) = payable(game.player).call{value: game.bet}("");
                require(success, "Failed to send Ether");
            } else { /* nothing */ }

        } else if (game.gametype == GameType.ERC20BotReal) {
            // send erc20 tokens
            require(0 == 1, "Not Implemented Yet");
        }

    }

    // -===============> END Part 4 <===============-

}

