//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;

//static variables
input int startingLotSize = 1.0;
input int entrytToProfitPips = 150.0;
input int zoneRecoveryPips = 50.0;

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

//new trade cycle starter
void enterInitialBuyTrade()
  {
//Enter at current market price - buy
   double currentAsk = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);

// Buy order
   stopLine = currentAsk - (entrytToProfitPips + zoneRecoveryPips) * _Point;
   profitLine = (currentAsk + entrytToProfitPips * _Point);
   bool buyTradeSuccess = trade.Buy(startingLotSize,NULL,currentAsk,stopLine,profitLine, _Digits);

//2nd trade for testing
//Sleep(10000);
//currentAsk = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
//bool buyTradeSuccess2 = trade.Buy(startingLotSize,NULL,currentAsk,0,(currentAsk + entrytToClosePips * _Point), _Digits);

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
