module AWSTests.RDSTests.DBParameterGroupTests
    ( runDBParameterGroupTests
    )
    where

import Control.Applicative ((<$>))
import qualified Control.Concurrent as CC
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)
import Test.Hspec

import AWS.RDS
import AWS.RDS.Types
import AWSTests.Util
import AWSTests.RDSTests.Util

region :: Text
region = "ap-northeast-1"

runDBParameterGroupTests :: IO ()
runDBParameterGroupTests = hspec $ do
    describeDBParameterGroupsTest
    createAndDeleteDBParameterGroupTest
    describeDBParametersTest
    modifyAndResetDBParameterGroupTest

describeDBParameterGroupsTest :: Spec
describeDBParameterGroupsTest = do
    describe "describeDBParameterGroups doesn't fail" $ do
        it "describeDBParameterGroups doesn't throw any exception" $ do
            testRDS region (describeDBParameterGroups Nothing Nothing Nothing)
                `miss` anyConnectionException

createAndDeleteDBParameterGroupTest :: Spec
createAndDeleteDBParameterGroupTest = do
    describe "{create,delete}DBParameterGroup doesn't fail" $ do
        it "{create,delete}DBParameterGroup doesn't throw any exception" $ do
            testRDS region (do
                name <- liftIO $ getRandomText "hspec-test-parameter-group-"
                withDBParameterGroup name $ const $ return ()
                ) `miss` anyConnectionException

describeDBParametersTest :: Spec
describeDBParametersTest = do
    describe "describeDBParameters doesn't fail" $ do
        it "describeDBParameters doesn't throw any exception" $ do
            testRDS region (do
                name <- dbParameterGroupName . head <$>
                     describeDBParameterGroups Nothing Nothing Nothing
                loop name Nothing
                ) `miss` anyConnectionException
  where
    loop name marker = do
        (marker', _) <- describeDBParameters name marker (Just 100) Nothing
        maybe (return ()) (\m -> loop name (Just m)) marker'

modifyAndResetDBParameterGroupTest :: Spec
modifyAndResetDBParameterGroupTest = do
    describe "{modify,reset}DBParameterGroup doesn't fail" $ do
        it "{modify,reset}DBParameterGroup doesn't throw any exception" $ do
            testRDS region (do
                name <- liftIO $ getRandomText "hspec-test-parameter-group-"
                withDBParameterGroup name $ \_ -> do
                    modifyDBParameterGroup name modifyParams
                    liftIO $ CC.threadDelay 10000000
                    resetDBParameterGroup name resetParams
                    resetDBParameterGroup name ResetAllParameters
                ) `miss` anyConnectionException
  where
    modifyParams =
        [ ModifyParameter "auto_increment_increment" "2" ApplyMethodImmediate
        ]
    resetParams = ResetParameters
        [ ResetParameter "auto_increment_increment" ApplyMethodImmediate
        ]
