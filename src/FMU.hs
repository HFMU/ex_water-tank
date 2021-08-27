{-# LANGUAGE ScopedTypeVariables #-}
module FMU where

import Data.Tuple.Sequence (sequenceT)
import HMOperations
import qualified HaskellFMU as H
import qualified Data.HashMap.Strict as HM
import Debug.Trace
import qualified Data.HaskellFMU.Types as T
import qualified SVs
import qualified Control.Monad.Writer as W
--import qualified Control.Monad.Trans.Writer.Strict as W

foreign export ccall setup :: IO ()
setup :: IO ()
--setup = HFMU.setup doStep inputs outputs
setup = H.setup T.Setup {T.sSVs = HM.union SVs.inputs (HM.union SVs.outputs SVs.parameters),
                       T.sDoStepFunc = FMU.doStep,
                       T.sPeriod=0.1,
                       T.sUserState = T.UserState mFMUState}

newtype MFMUState = MFMUState {mmax :: Int}

mFMUState :: MFMUState
mFMUState = MFMUState {mmax = 1}

-- TODO: SWITCH TO LOGGING T
doStep :: T.SVs -> T.UserState MFMUState -> IO (W.Writer [T.LogEntry] (T.DoStepResult MFMUState))
doStep svs us@(T.UserState (MFMUState {mmax=m}))  =
  let 
    valve :: Maybe T.SVTypeVal =
        do
          trace (show m) (Just ())
          mM <- retrieveMinAndMaxLevel svs
          level <- getPortVal svs "level"
          calcValve level mM $ getPortVal svs "valve"
    doStepResult :: T.DoStepResult MFMUState = 
      case valve of 
        Just v -> T.DoStepResult {T.dsrStatus = T.OK, T.dsrSvs = adjustPortVal svs "valve" v,
                                T.dsrState = T.UserState (MFMUState {mmax = 2})}
        Nothing -> T.DoStepResult {T.dsrStatus = T.Fatal, T.dsrSvs = svs, T.dsrState = us}
  in
    do
      a :: W.Writer [T.LogEntry] () <- output "doStep completed" 
      b :: W.Writer [T.LogEntry] (T.DoStepResult MFMUState) <- W.writer (a, doStepResult)
      return b

-- TODO: SWITCH TO LOGGINGT
output :: String -> IO (W.Writer [T.LogEntry] ())
output x = return $ W.tell [T.LogEntry T.LogInfo x]
    

retrieveMinAndMaxLevel :: T.SVs -> Maybe (T.SVTypeVal, T.SVTypeVal)
retrieveMinAndMaxLevel par =
    sequenceT (getPortVal par "minLevel",  getPortVal par "maxLevel")

calcValve :: T.SVTypeVal -> (T.SVTypeVal,T.SVTypeVal) -> Maybe T.SVTypeVal -> Maybe T.SVTypeVal
calcValve level@(T.RealVal lvl) minMaxLevel@(T.RealVal min, T.RealVal max) prevValve
  | lvl <= min = Just $ T.BooleanVal False
  | lvl >= max = Just $ T.BooleanVal True
  | otherwise = prevValve
calcValve _ _ _ = Nothing
