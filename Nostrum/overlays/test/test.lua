print('hello from test overlay')

events:register('name change', print)
events:register('mp change', print)
events:register('mpp change', print)
