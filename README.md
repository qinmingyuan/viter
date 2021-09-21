# RailsVite

Rails Frontend Develop suit Make you so happy
Use [Vite](https://github.com/vitejs/vite),
Inspired by [webpacker](https://github.com/rails/webpacker), But more powerful:

* for Engine develop: you can import assets files under `app/assets`
* You can put js or css files under `app/views`, same name as action, which will load automatically.


## How to Use

* Install
  * Add `gem 'rails_vite'` to you gemfile, then bundle it;
  * Run `yarn add https://github.com/qinmingyuan/rails_vite` add `rails_vite` to package.json
* In Production
  * 编译 Asset：`env RAILS_ENV=production rake rails_vite:compile`

3. Enjoy it;



## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
