// Import and register all your controllers from the importmap under controllers/*

import { application } from "./application"

// Import and register all your controllers from the importmap
import ResizableColumnsController from "./resizable_columns_controller"
application.register("resizable-columns", ResizableColumnsController)

// Your controllers will be registered here
