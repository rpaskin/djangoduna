pragma solidity >=0.4.0 <0.6.0;

// A unique bid auction is a type of strategy game related to traditional auctions where the
// winner is usually the individual with the lowest unique bid, although less commonly the
// auction rules may specify that the highest unique bid is the winner. Unique bid auctions
// are often used as a form of competition and strategy game where bidders pay a fee to make
// a bid, or may have to pay a subscription fee in order to be able to participate.

// Deployed Ropsten: 0x0e289dddd43d844ea0ea750679f9418d2505c897

contract PennyAuctionSimple {
    address payable public owner;
    uint256 public start;
    uint256 public end;
    address public winner;

    uint256 lowestBid = ~uint256(0); // max possible integer
    mapping(uint256 => address) bidders;
    uint256[] bids;

    modifier onlyOwner   { require(msg.sender == owner,    "Only owner can do this."); _; }
    modifier notOwner    { require(msg.sender != owner,    "Owner cannot do this."); _; }
    modifier started     { require(start > 0,              "Auction not started!"); _; }
    modifier ended       { require(end == 0,               "Auction already ended!"); _; }
    modifier notStarted  { require(start == 0,             "Auction already started!"); _; }
    modifier notEnded    { require(end == 0,               "Auction already ended!"); _; }

    event AuctionEnded(address winner, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    function startAuction() public onlyOwner notStarted {
        start = now;
    }

    function endAuction() public onlyOwner started notEnded {
        end = now;
        winner = bidders[lowestBid];
        emit AuctionEnded(winner, lowestBid);
        owner.transfer(address(this).balance);
    }

    function bidIsUnique() internal view returns(bool) {
        return (bidders[msg.value] == address(0x0));
    }

    function saveBid() internal {
        bidders[msg.value] = msg.sender;     // save bidder
        bids.push(msg.value);                // save bid

        if (msg.value < lowestBid){            // save current lowest bid, if that's the case
            lowestBid = msg.value;
        }
    }

    function markLosingBid() internal {
        bidders[msg.value] = owner;              // mark it by setting it to the contract owner

        // If this bid was the lowest, figure out the next lowest
        if (msg.value == lowestBid) {
            for (uint i=0; i<bids.length; i++) {
                if (bids[i] < lowestBid){
                    lowestBid = bids[i];
                }
            }
        }
    }

    function bid() public payable started notEnded notOwner {
        require(bidders[msg.value] != msg.sender, "You've already placed this bid!");
        require(msg.value > 0, "Must send Ether!");

        if (bidIsUnique()){
            saveBid();
        }
        else {      // bid already exists
            markLosingBid();
        }
    }
}