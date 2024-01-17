//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;

//static variables
input int startingLotSize = 1;
input int entrytToProfitPips = 300;
input int zoneRecoveryPips = 100;

input int slippage = 5;           // MAX Slippage in points
input int magicNumber = 99999;      // Unique identifier for the EA
input int OP_BUY = 0;
input int OP_SELL = 1;
input int OP_BUYSTOP = 4;
input int OP_SELLSTOP = 5;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double buyLinePrice = 0.0;    // price of the buy line (top line of recovery zone)
double enteredLots = 0.0;     // running counter of lots entered
double profitLine = 0.0;      // Initial TP line
double stopLine = 0.0;        // Initial Stop Line

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   /* ------- Enter Initial Trade ------ */
   bool inTradeRes = isOpenTrade();
   if(inTradeRes)
     {
      //Print("There is at least one open trade");

     }
   else
     {
      //Print("No open trades found. Entering new trade...");
      enterInitialBuyTrade();
      enterIntialInvalidPendingTrade();

     }

   /* --------  Invalidations Crossed ---------- */




  }
  
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
{
    // Check if the transaction type is DEAL_ADD which means a deal has been executed
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        // Select the deal using its deal ID
        if(HistoryDealSelect(trans.deal))
        {
            // Create a deal object to retrieve information
            CDealInfo deal_info;
            deal_info.Ticket(trans.deal);

            // Check the deal type to confirm if it's a stop order (buy or sell)
            if(deal_info.Type() == DEAL_TYPE_BUY)
            {
                // Retrieve information about the deal
                double price = deal_info.Price();
                double volume = deal_info.Volume();
                string symbol = deal_info.Symbol();

                // Print out the deal information
                Print("Buy Order Filled - Symbol: ", symbol, ", Price: ", price, ", Volume: ", volume);
            }
          if(deal_info.Type() == DEAL_TYPE_SELL) {
                            // Retrieve information about the deal
                double price = deal_info.Price();
                double volume = deal_info.Volume();
                string symbol = deal_info.Symbol();

                // Print out the deal information
                Print("Sell Order Filled - Symbol: ", symbol, ", Price: ", price, ", Volume: ", volume);
          }
        }
    }
}
  
/*
void OnTrade() {
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
       //if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
     		if (OrderGetTicket(0))
           if(OrderSymbol() == Symbol()) {
               // This is a trade event for our symbol and magic number
               if(OrderType() == ORDER_TYPE_BUY_STOP) {
                 
                 // SET SELL STOP
                 Print("Set new sell stop")
                 
               } 
             		if (OrderType() == ORDER_TYPE_SELL_STOP) {
                  // SET BUY STOP
                  Print("Set new buy stop")
               }
           }
       }
   }
}
*/


//new trade cycle starter
void enterInitialBuyTrade()
  {
//Enter at current market price - buy
   double currentAsk = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);

// Buy order
   stopLine = currentAsk - (entrytToProfitPips + zoneRecoveryPips) * _Point;
   profitLine = (currentAsk + entrytToProfitPips * _Point);
   bool buyTradeSuccess = trade.Buy(startingLotSize,NULL,currentAsk,stopLine,profitLine, _Digits);
   
  
//error handling
   if(!buyTradeSuccess)
     {
      Print("Something went wrong enter Initial Trade");
     }
   else     //update info
     {

      ulong ticket = PositionGetTicket(0);



      if(PositionSelectByTicket(ticket))
        {
         enteredLots = startingLotSize; //update lots
         buyLinePrice = PositionGetDouble(POSITION_PRICE_OPEN);
        }
      else
        {
         Print("Failed to select position with ticket ", ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void enterIntialInvalidPendingTrade()
  {
   // Get bid price
   //double currentAsk = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   //buyLinePrice - zoneRecoveryPips

   trade.SellStop(1.0, buyLinePrice-(zoneRecoveryPips*_Point),NULL,profitLine,stopLine,ORDER_TIME_GTC,0,NULL);
   Print(zoneRecoveryPips); // ERROR! ZONE RECOVERY 50 WHY EVEN WHEN SET TO 100?
  }



// Check if there is at least one open trade
bool isOpenTrade()
  {
   bool haveOpenTrade = false;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         return true;
        }
     }

   if(!haveOpenTrade)
     {
      Print("No open trades");
     }
   else
     {
      Print("There is an open trade");
     }
   return haveOpenTrade;
  }
//+------------------------------------------------------------------+
