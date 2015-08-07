chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'bamboohr', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/bamboohr')(@robot)

  it 'registers a respond listener for "bamboo"', ->
    expect(@robot.respond).to.have.been.calledWith(/bamboo\s([\w\s]+)$/i)

  it 'registers a respond listener for "whosoff"', ->
    expect(@robot.respond).to.have.been.calledWith(/whos(out|off)$/i)