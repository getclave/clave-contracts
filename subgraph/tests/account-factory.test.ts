/**
 * Copyright Clave - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 */
import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address } from "@graphprotocol/graph-ts"
import { NewClaveAccount } from "../generated/schema"
import { NewClaveAccount as NewClaveAccountEvent } from "../generated/AccountFactory/AccountFactory"
import { handleNewClaveAccount } from "../src/account-factory"
import { createNewClaveAccountEvent } from "./account-factory-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let accountAddress = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newNewClaveAccountEvent = createNewClaveAccountEvent(accountAddress)
    handleNewClaveAccount(newNewClaveAccountEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("NewClaveAccount created and stored", () => {
    assert.entityCount("NewClaveAccount", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "NewClaveAccount",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "accountAddress",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
