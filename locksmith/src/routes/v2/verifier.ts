import express from 'express'
import VerifierController from '../../controllers/v2/verifierController'
import { authenticatedMiddleware } from '../../utils/middlewares/auth'
import { lockManagerMiddleware } from '../../utils/middlewares/lockManager'
import { isEventVerifierOrManagerMiddleware } from '../../utils/middlewares/isVerifierMiddleware'

const router: express.Router = express.Router({ mergeParams: true })

const verifierController = new VerifierController()

router.use('/', authenticatedMiddleware)

router.get('/list/:network/:lockAddress', lockManagerMiddleware, (req, res) =>
  verifierController.list(req, res)
)

router.put(
  '/:network/:lockAddress/:verifierAddress',
  lockManagerMiddleware,
  (req, res) => verifierController.addVerifier(req, res)
)

router.delete(
  '/:network/:lockAddress/:verifierAddress',
  lockManagerMiddleware,
  (req, res) => verifierController.removeVerifier(req, res)
)

router.get(
  '/:network/lock/:lockAddress/address/:verifierAddress',
  isEventVerifierOrManagerMiddleware,
  (req, res) => verifierController.isVerifierEnabled(req, res)
)

export default router
