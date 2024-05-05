import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import {
  ClaveAccountCreated,
  ClaveAccountDeployed,
  DeployerChanged,
  ImplementationChanged,
  OwnershipTransferred,
  RegistryChanged
} from "../generated/AccountFactory/AccountFactory"

export function createClaveAccountCreatedEvent(
  accountAddress: Address
): ClaveAccountCreated {
  let claveAccountCreatedEvent = changetype<ClaveAccountCreated>(newMockEvent())

  claveAccountCreatedEvent.parameters = new Array()

  claveAccountCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "accountAddress",
      ethereum.Value.fromAddress(accountAddress)
    )
  )

  return claveAccountCreatedEvent
}

export function createClaveAccountDeployedEvent(
  accountAddress: Address
): ClaveAccountDeployed {
  let claveAccountDeployedEvent = changetype<ClaveAccountDeployed>(
    newMockEvent()
  )

  claveAccountDeployedEvent.parameters = new Array()

  claveAccountDeployedEvent.parameters.push(
    new ethereum.EventParam(
      "accountAddress",
      ethereum.Value.fromAddress(accountAddress)
    )
  )

  return claveAccountDeployedEvent
}

export function createDeployerChangedEvent(
  newDeployer: Address
): DeployerChanged {
  let deployerChangedEvent = changetype<DeployerChanged>(newMockEvent())

  deployerChangedEvent.parameters = new Array()

  deployerChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newDeployer",
      ethereum.Value.fromAddress(newDeployer)
    )
  )

  return deployerChangedEvent
}

export function createImplementationChangedEvent(
  newImplementation: Address
): ImplementationChanged {
  let implementationChangedEvent = changetype<ImplementationChanged>(
    newMockEvent()
  )

  implementationChangedEvent.parameters = new Array()

  implementationChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newImplementation",
      ethereum.Value.fromAddress(newImplementation)
    )
  )

  return implementationChangedEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createRegistryChangedEvent(
  newRegistry: Address
): RegistryChanged {
  let registryChangedEvent = changetype<RegistryChanged>(newMockEvent())

  registryChangedEvent.parameters = new Array()

  registryChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newRegistry",
      ethereum.Value.fromAddress(newRegistry)
    )
  )

  return registryChangedEvent
}
