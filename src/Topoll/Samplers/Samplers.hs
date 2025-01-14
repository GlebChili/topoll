module Topoll.Samplers.Samplers
    (sampleSphereUniformlyAtParametrization,
     sampleTorusUniformlyAtParametrization,
     sampleSphereUniformly) where

import qualified Data.Vector as V
import Data.Vector (Vector)
import System.Random
import Data.Functor ( (<&>) )
import Topoll.DistanceMatrix.DistanceMatrix (Point)
import Named

nextTriple :: (Float, Float) -> (Float, Float) -> (Float, Float, StdGen) -> (Float, Float, StdGen)
nextTriple firstRange secondRange (_, _, rnd) = (firstC, fst nextPair, snd nextPair) where
    (firstC, rnd') = uniformR firstRange rnd
    nextPair = uniformR secondRange rnd'

getUniformPointsOfRectangle :: (Float, Float) -> (Float, Float) -> Int -> IO (Vector (Float, Float))
getUniformPointsOfRectangle _ _ ((<0) -> True) = fail "Can't sample negative number of points"
getUniformPointsOfRectangle firstRange secondRange numberOfPointsToSample = do
    rndGen <- newStdGen
    let (frst, rndGen') = uniformR firstRange rndGen
    let (scnd, rndGen'') = uniformR secondRange rndGen'
    let firstTriple = (frst, scnd, rndGen'')
    let preResult = V.iterateN numberOfPointsToSample (nextTriple firstRange secondRange) firstTriple
    return $ preResult <&> (\(ft, nd, _) -> (ft, nd))

sampleSphereUniformlyAtParametrization :: "r" :! Float -> "n" :! Int -> IO (Vector Point)
sampleSphereUniformlyAtParametrization (Arg sphereRadius) (Arg numberOfPointsToSample)
  | numberOfPointsToSample < 0 = fail "The sample length can't be negative"
  | sphereRadius < 0 = fail "Can't sample points from the sphere of the negative radius"
  | numberOfPointsToSample == 0 = return V.empty
  | otherwise = do
      preResult' <- getUniformPointsOfRectangle (0 :: Float, 2 * pi) (0 :: Float, pi) numberOfPointsToSample
      return $ preResult' <&> (\(x, y) ->
          V.fromList [sphereRadius * cos x * sin y, sphereRadius * sin x * sin y, sphereRadius * cos y])

{- First argumant is bigR, the distance from the center of the tube to the center of the torus. -}
{- The second one -- r, the radius of the tube. -}
sampleTorusUniformlyAtParametrization :: "R" :! Float -> "r" :! Float -> "n" :! Int -> IO (Vector Point)
sampleTorusUniformlyAtParametrization (Arg bigR) (Arg r) (Arg numberOfPointsToSample)
    | bigR < 0 = fail "Can't sample points from the torus with negative R"
    | r < 0 = fail "Can't sample points from the torus with negative r"
    | numberOfPointsToSample < 0 = fail "The sample length can't be negative"
    | otherwise = do
        preRusult' <- getUniformPointsOfRectangle (0 :: Float, 2 * pi) (0 :: Float, 2 * pi) numberOfPointsToSample
        return $ preRusult' <&> (\(x, y) ->
            V.fromList [(bigR + r * cos x) * cos y, (bigR + r * cos x) * sin y, r * sin x])

sampleSphereUniformly :: "r" :! Float -> "n" :! Int -> IO (Vector Point)
sampleSphereUniformly (Arg sphereRadius) (Arg numberOfPointsToSample)
  | sphereRadius < 0 = fail "Can't sample points from the sphere of the negative radius"
  | numberOfPointsToSample < 0  = fail "The sample length can't be negative"
  | otherwise = do
    randomPoints <- getUniformPointsOfRectangle (0, 1) (0, 1) numberOfPointsToSample
    let tweakedPoints = randomPoints <&> (\(x, y) -> (2*pi*x, acos (1 - 2*y)))
    return $ tweakedPoints <&> (\(x, y) ->
        V.fromList [sphereRadius * cos x * sin y, sphereRadius * sin x * sin y, sphereRadius * cos y])

{-
>>> sampleSphereUniformly 3 3
[[1.9207355,1.4409856,1.7984262],[-0.1334068,-1.567291,-2.554565],[-2.0708957,-1.768318,1.2587464]]
-}
