/// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.15;

import "./ds-test.sol";

//
// @title ds-test/assert
// @notice Extends ds-test with additional generic assertions + revert checks
// @custom:version 2022.05
// @custom:contributors Michael Pouy, Vincenzo Palazzo, Daniel Cousens, Gerasimos Maropoulos
//
contract DSAssert is DSTest {
    //
    // @custom:function assertErrorWithMessage
    // @notice Calls function and checks for matching revert message
    // @param erroringFunction to call
    // @param message to check against revert error string
    //
    function assertErrorWithMessage(function() external erroringFunction, string memory message) internal {
        try erroringFunction() {
            fail();
        } catch Error(string memory error) {
            // Assert revert error matches expected message
            assertEq(error, message);
        }
    }

    //
    // @custom:function assertErrorWithMessageParams
    // @notice Calls function and checks for matching revert message
    // @param erroringFunction to call
    // @param param to pass to function
    // @param message to check against revert error string
    //
    function assertErrorWithMessageParams(
        function(uint256) external erroringFunction,
        uint256 param,
        string memory message
    ) internal {
        try erroringFunction(param) {
            fail();
        } catch Error(string memory error) {
            // Assert revert error matches expected message
            assertEq(error, message);
        }
    }

    //
    // @custom:function assertErrorWithMessageMulti
    // @notice Calls function and checks for matching revert message
    // @param erroringFunction to call
    // @param params to pass to function
    // @param message to check against revert error string
    //
    function assertErrorWithMessageMulti(
        function(uint256[] memory) external erroringFunction,
        uint256[] memory params,
        string memory message
    ) internal {
        try erroringFunction(params) {
            fail();
        } catch Error(string memory error) {
            // Assert revert error matches expected message
            assertEq(error, message);
        }
    }

    //
    // @custom:function assertErrorWithMessagePayable
    // @notice Calls function and checks for matching revert message (with value)
    // @param erroringFunction to call
    // @param param to pass to function
    // @param value to pass with function call
    // @param message to check against revert error string
    //
    function assertErrorWithMessagePayable(
        function(uint256) payable external erroringFunction,
        uint256 param,
        uint256 value,
        string memory message
    ) internal {
        try erroringFunction{value: value}(param) {
            fail();
        } catch Error(string memory error) {
            // Assert revert error matches expected message
            assertEq(error, message);
        }
    }

    // @custom:function assertEqApprox
    // @param uint256
    // @param _a
    // @param uint256
    // @param _b
    // @param uint256
    // @param _tolerance
    function assertEqApprox(uint256 _a, uint256 _b, uint256 _tolerance) internal {
        uint256 a = _a;
        uint256 b = _b;
        if (a < b) {
            uint256 tmp = a;
            a = b;
            b = tmp;
        }
        if (a - b > _tolerance) {
            emit log_bytes32("Error: Wrong `uint' value");
            emit log_named_uint("  Expected", _b);
            emit log_named_uint("    Actual", _a);
            fail();
        }
    }
}
