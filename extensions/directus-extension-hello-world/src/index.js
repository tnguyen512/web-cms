export default {
	id: 'hello-world',
	handler: (router) => {
		// GET /hello-world
		router.get('/', (req, res) => {
			res.json({
				message: 'Hello World!',
				timestamp: new Date().toISOString(),
				method: 'GET'
			});
		});

		// GET /hello-world/greet/:name
		router.get('/greet/:name', (req, res) => {
			const { name } = req.params;
			res.json({
				message: `Hello, ${name}!`,
				timestamp: new Date().toISOString()
			});
		});

		// GET /hello-world/info
		router.get('/info', (req, res) => {
			res.json({
				extension: 'directus-extension-hello-world',
				version: '1.0.0',
				description: 'Demo custom API endpoint',
				endpoints: [
					'GET /hello-world',
					'GET /hello-world/greet/:name',
					'GET /hello-world/info'
				]
			});
		});
	}
};
