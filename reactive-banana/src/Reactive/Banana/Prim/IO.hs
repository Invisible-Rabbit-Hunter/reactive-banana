{-----------------------------------------------------------------------------
    reactive-banana
------------------------------------------------------------------------------}
module Reactive.Banana.Prim.IO where

import           Data.Unique.Really
import qualified Data.Vault.Strict  as Strict
import           System.IO.Unsafe             (unsafePerformIO)

import Reactive.Banana.Prim.Combinators (mapP)
import Reactive.Banana.Prim.Evaluation  (step)
import Reactive.Banana.Prim.Plumbing
import Reactive.Banana.Prim.Types

debug s = id

{-----------------------------------------------------------------------------
    Primitives connecting to the outside world
------------------------------------------------------------------------------}
-- | Create a new pulse in the network and a function to trigger it.
--
-- Together with 'addHandler', this function can be used to operate with
-- pulses as with standard callback-based events.
newInput :: Strict.Key a -> Build (Pulse a, a -> Step)
newInput key = debug "newInput" $ unsafePerformIO $ do
    uid <- newUnique
    let pulse = Pulse
            { evaluateP = return ()
            , getValueP = Strict.lookup key
            , uidP      = uid
            }
    let inputs a = (Strict.insert key a Strict.empty, [P pulse])
    return $ return (pulse, step . inputs)

-- | Register a handler to be executed whenever a pulse occurs.
addHandler :: Pulse a -> (a -> IO ()) -> Build ()
addHandler p1 f = do
    p2 <- mapP f p1
    addOutput p2

-- | Read the value of a 'Latch' at a particular moment in time.
readLatch :: Latch a -> Build a
readLatch = readLatchB