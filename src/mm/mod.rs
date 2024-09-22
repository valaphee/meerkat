// Copyright 2024 Kevin Ludwig
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

mod pm;
mod vm;

pub use pm::*;
pub use vm::*;

use spin::Mutex;

pub const GRANULARITY: usize = 4096;

pub static PHYS_MEM: Mutex<PhysicalMemory> = Mutex::new(PhysicalMemory::empty());

#[global_allocator]
pub static VIRT_MEM: VirtualMemoryScope = VirtualMemoryScope;
