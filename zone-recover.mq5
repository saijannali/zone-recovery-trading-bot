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
input int entrytToProfitPips = 150;
//input int zoneRecoveryPips = 100;
int zoneRecoveryPips = 50;

double buyLotsArray[7] = {1,1,1.9,4,5,6,1};
double sellLotsArray[7] = {1.4,1.4,2.5,1,1,1,1};
int currentBuyIdx = 0;
int currentSellIdx = 0;

input int slippage = 5;           // MAX Slippage in points
input int magicNumber = 99999;      // Unique identifier for the EA
input int OP_BUY = 0;
input int OP_SELL = 1;
input int OP_BUYSTOP = 4;
input int OP_SELLSTOP = 5;

bool didSetBuyStop = false;
bool didSetSellStop = false;

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

     }

   /* --------  Invalidations Crossed ---------- */




  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
  {
   long dealReason=0;
// Check if the transaction type is DEAL_ADD which means a deal has been executed
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      // Select the deal using its deal ID
      if(HistoryDealSelect(trans.deal))
        {
         // Create a deal object to retrieve information
         CDealInfo deal_info;
         deal_info.Ticket(trans.deal);
         

         deal_info.InfoInteger(DEAL_REASON, dealReason);
         Print(dealReason);
         
         if((ENUM_DEAL_REASON)dealReason == DEAL_REASON_TP || (ENUM_DEAL_REASON)dealReason == DEAL_REASON_SL)
         {
             CloseAllTrades();
             Print("TPTPTPTPTPTPTPTPTPT");
             return;
         }
         if((ENUM_DEAL_REASON)dealReason == DEAL_REASON_EXPERT)
           {
            if(deal_info.DealType() == DEAL_TYPE_BUY) // Perform action for buy_stop order fill
              {
                     enterSellPendingTrade();
              }
            if(deal_info.DealType() == DEAL_TYPE_SELL) // Perform action for sell_stop order fill
              {
                     enterBuyPendingTrade();
              }
           }

        }
     }
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
void enterSellPendingTrade()
{
   didSetBuyStop = false;
  
   
   // Get bid price
   //double currentAsk = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   //buyLinePrice - zoneRecoveryPips
   if (didSetSellStop == false) {
          double lotSize = sellLotsArray[currentSellIdx];
   				trade.SellStop(lotSize, buyLinePrice-(zoneRecoveryPips*_Point),NULL,profitLine,stopLine,ORDER_TIME_GTC,0,NULL);
      		didSetSellStop = true;
     			currentBuyIdx = currentBuyIdx + 1;
		}

}



   // 50 pip zone, 150 pip tp
   // ArrayBuyLots[1,1,1.9]
   // ArraySellots[1.4, 1.4, 2.5]
void enterBuyPendingTrade()
{
  	didSetSellStop = false;
    // Get bid price
    //double currentAsk = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
    //buyLinePrice - zoneRecoveryPips
  	if (didSetBuyStop == false) {
          double lotSize = buyLotsArray[currentBuyIdx];
    			trade.BuyStop(lotSize, buyLinePrice,NULL,stopLine,profitLine,ORDER_TIME_GTC,0,NULL);
      		didSetBuyStop = true;
      		currentSellIdx = currentSellIdx + 1;
		}

}

void CloseAllTrades()
{
   COrderInfo order;
   CPositionInfo position;

   // Loop through all orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
       if(order.SelectByIndex(i)) // Select an order
       {
           trade.OrderDelete(order.Ticket()); // Delete the order
           Sleep(100); // Wait for a while
       }
   }

   // Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
       if(position.SelectByIndex(i)) // Select a position
       {
           trade.PositionClose(position.Ticket()); // Close the position
           Sleep(100); // Wait for a while
       }
   }
   
   currentSellIdx = 0;
   currentBuyIdx = 0;
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
