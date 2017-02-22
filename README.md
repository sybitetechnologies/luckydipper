# Luckydipper
Luckydipper is a Ruby script that checks the stocks of the Drop Dead lucky dip and updates on twitter accounts (separate for guys and girls) if there is any new stock available.

## Installation
Installation is as simple as configuring your local `.env` file with your Twitter auth tokens/keys and running
```
ruby ./app.rb
```

You can also use the included Dockerfile if you prefer to use Docker.
```
docker build -t luckydipper .
docker run -d luckydipper
```

## License and Credit
Uses Drop Dead's data feeds so thank you Drop Dead!

Released under Creative Commons Attribution-ShareAlike v4.

http://creativecommons.org/licenses/by-sa/4.0/
