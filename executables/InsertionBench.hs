
import BasePrelude
import Criterion.Main
import qualified Data.HashTable.IO as Hashtables
import qualified Data.HashMap.Strict as UnorderedContainers
import qualified Data.Map as Containers
import qualified STM.Containers.Map as STM.Containers
import qualified Focus.Impure as Focus
import qualified System.Random.MWC.Monad as MWC
import qualified Data.Char as Char
import qualified Data.Text as Text

main = do
  keys <- MWC.runWithCreate $ replicateM rows keyGenerator
  defaultMain
    [
      bgroup "STM Containers"
      [
        bench "focus-based" $ nfIO $
          do
            t <- atomically $ STM.Containers.new :: IO (STM.Containers.Map Text.Text ())
            forM_ keys $ \k -> atomically $ STM.Containers.focus (Focus.insert ()) k t
        ,
        bench "specialized" $ nfIO $
          do
            t <- atomically $ STM.Containers.new :: IO (STM.Containers.Map Text.Text ())
            forM_ keys $ \k -> atomically $ STM.Containers.insert () k t
      ]
      ,
      bench "Unordered Containers" $
        nf (foldr (\k -> UnorderedContainers.insert k ()) UnorderedContainers.empty) keys
      ,
      bench "Containers" $
        nf (foldr (\k -> Containers.insert k ()) Containers.empty) keys
      ,
      bench "Hashtables" $ nfIO $
        do
          t <- Hashtables.new :: IO (Hashtables.BasicHashTable Text.Text ())
          forM_ keys $ \k -> Hashtables.insert t k ()
    ]

rows :: Int = 100000

keyGenerator :: MWC.Rand IO Text.Text
keyGenerator = do
  l <- length
  s <- replicateM l char
  return $! Text.pack s
  where
    length = MWC.uniformR (7, 20)
    char = Char.chr <$> MWC.uniformR (Char.ord 'a', Char.ord 'z')

