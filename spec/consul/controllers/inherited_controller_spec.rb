require 'spec_helper'

describe 'inherited controller' do

  def guards_of(controller)
    controller.send(:consul_guards).map { |g| g.send(:power_name, :index) }
  end

  it 'inherits the power checks of its parent' do
    class PiesController < CakesController
    end

    expect(PiesController.send(:consul_guards)).to eq CakesController.send(:consul_guards)
    expect(guards_of(PiesController)).to eq [:cakes]
  end

  it 'inherits the power checks of its ancestors' do
    class SmallCakesController < CakesController
      power :small
    end
    class MuffinsController < SmallCakesController
    end

    expect(guards_of(MuffinsController)).to eq [:cakes, :small]
  end

  it 'adds new power checks' do
    class ButtercakesController < CakesController
      power :butter
    end

    expect(guards_of(ButtercakesController)).to eq [:cakes, :butter]
  end

  it 'does not modify the power checks of its parent' do
    class CheesecakesController < CakesController
      power :cheese
    end

    expect(guards_of(CakesController)).to eq [:cakes]
    expect(CheesecakesController.send(:consul_guards).object_id).not_to eq CakesController.send(:consul_guards).object_id
  end

end
