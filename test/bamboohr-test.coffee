chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
bamboo = require 'node-bamboohr'
expect = chai.expect

describe 'bamboohr', ->
  before ->
    @employeesStub = sinon.stub(bamboo.prototype, 'employees')

  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/bamboohr')(@robot)

  afterEach ->
    @employeesStub.reset()

  it 'registers a respond listener for "bamboo"', ->
    expect(@robot.respond).to.have.been.calledWith(/bamboo\s([\w\s]+)$/i)

  it "when there's no fields for the employee it doesn't send undefined", ->
    [regex, fn] = @robot.respond.args[0]
    send = sinon.spy()

    @employeesStub.yields(null, [{
      fields: {
        displayName: 'Farid'
      }
    }])

    fn({
      match: 'Bamboo Farid'.match(regex)
      send
    })

    expect(send.calledWith(undefined)).to.be.false

  it 'registers a respond listener for "whosoff"', ->
    expect(@robot.respond).to.have.been.calledWith(/whos(out|off)(\stoday|\stomorrow|\sthis\sweek|\sthis\smonth|\snext\sweek|\snext\smonth)?$/i)