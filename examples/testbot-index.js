// Minimal test bot — logs in and prints "Online as <name>". Proves the host works.
const { Client, GatewayIntentBits } = require('discord.js')
const client = new Client({ intents: [GatewayIntentBits.Guilds] })
client.once('ready', c => console.log(`Online as ${c.user.tag}`))
client.login(process.env.DISCORD_TOKEN)
