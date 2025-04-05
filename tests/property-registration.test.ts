import { describe, it, expect, beforeEach } from "vitest"

// Mock the Clarity contract environment
const mockTxSender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockBlockHeight = 100
const mockBlockTime = 1625097600 // Some Unix timestamp

// Mock contract state
let lastPropertyId = 0
const properties = new Map()
const ownerProperties = new Map()

// Mock contract functions
function registerProperty(location, size, structureType) {
  const newId = lastPropertyId + 1
  lastPropertyId = newId
  
  properties.set(newId, {
    owner: mockTxSender,
    location,
    size,
    structureType,
    registrationDate: mockBlockTime,
  })
  
  const ownerProps = ownerProperties.get(mockTxSender) || { propertyIds: [] }
  ownerProps.propertyIds.push(newId)
  ownerProperties.set(mockTxSender, ownerProps)
  
  return { type: "ok", value: newId }
}

function updateProperty(propertyId, location, size, structureType) {
  if (!properties.has(propertyId)) {
    return { type: "err", value: 1 }
  }
  
  const property = properties.get(propertyId)
  if (property.owner !== mockTxSender) {
    return { type: "err", value: 2 }
  }
  
  properties.set(propertyId, {
    ...property,
    location,
    size,
    structureType,
  })
  
  return { type: "ok", value: true }
}

function getProperty(propertyId) {
  return properties.get(propertyId) || null
}

function getOwnerProperties(owner) {
  return ownerProperties.get(owner) || null
}

// Tests
describe("Property Registration Contract", () => {
  beforeEach(() => {
    // Reset state before each test
    lastPropertyId = 0
    properties.clear()
    ownerProperties.clear()
  })
  
  it("should register a new property", () => {
    const result = registerProperty("123 Forest Lane", 2500, "Residential")
    
    expect(result.type).toBe("ok")
    expect(result.value).toBe(1)
    expect(properties.size).toBe(1)
    expect(properties.get(1).location).toBe("123 Forest Lane")
  })
  
  it("should update an existing property", () => {
    registerProperty("123 Forest Lane", 2500, "Residential")
    const updateResult = updateProperty(1, "123 Forest Lane", 3000, "Residential")
    
    expect(updateResult.type).toBe("ok")
    expect(properties.get(1).size).toBe(3000)
  })
  
  it("should fail to update a non-existent property", () => {
    const result = updateProperty(999, "123 Forest Lane", 2500, "Residential")
    
    expect(result.type).toBe("err")
    expect(result.value).toBe(1)
  })
  
  it("should retrieve property details", () => {
    registerProperty("123 Forest Lane", 2500, "Residential")
    const property = getProperty(1)
    
    expect(property).not.toBeNull()
    expect(property.location).toBe("123 Forest Lane")
    expect(property.size).toBe(2500)
    expect(property.structureType).toBe("Residential")
  })
  
  it("should retrieve properties owned by a principal", () => {
    registerProperty("123 Forest Lane", 2500, "Residential")
    registerProperty("456 Mountain Road", 1800, "Cabin")
    
    const ownerProps = getOwnerProperties(mockTxSender)
    
    expect(ownerProps).not.toBeNull()
    expect(ownerProps.propertyIds.length).toBe(2)
    expect(ownerProps.propertyIds).toContain(1)
    expect(ownerProps.propertyIds).toContain(2)
  })
})

